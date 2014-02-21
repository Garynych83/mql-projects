//+------------------------------------------------------------------+
//|                                                 ColoredTrend.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>
#include "ColoredTrendUtilities.mqh"

//+------------------------------------------------------------------+
//| ��������� ��� �������� ���������� �� ����������                  |
//+------------------------------------------------------------------+
struct SExtremum
{
 int direction;
 double price;
};

//+------------------------------------------------------------------+
//| ��������������� ����� ��� ���������� ColoredTrend                |
//+------------------------------------------------------------------+
class CColoredTrend
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  ENUM_MOVE_TYPE enumMoveType[];
  int digits;
  SExtremum num0, 
            num1, 
            num2;  // ������ ��������� �����������
  SExtremum lastOnTrend;       // ��������� ��������� �������� ������  
  double _percentage_ATR;
  double _startDayPrice;
  double difToNewExtremum;
  double difToTrend;     // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.
  int _depth;            // ���������� ����� ��� ������� ���������� 
  int ATR_handle;
  double buffer_ATR[];
  MqlRates buffer_Rates[];
  
  int FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[]);
  int FillATRBuf(int count, int start_pos);
  
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, int start_pos);
  bool isLastBarHuge(int start_pos);
  int isNewTrend();
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR);
  SExtremum isExtremum(int start_index);
  bool FindExtremumInHistory(int depth);
  bool CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  int TrendDirection();
  void Zeros();
};

//+-----------------------------------------+
//| �����������                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR) : 
                   _symbol(symbol),
                   _period(period),
                   _depth(depth),
                   _percentage_ATR(percentage_ATR)
{
 num0.direction = 0;
 num1.direction = 0;
 num2.direction = 0;
 num0.price = -1;
 num1.price = -1;
 num2.price = -1;
 
 MqlRates buffer[1];
 CopyRates(_symbol, _period, _depth, 1, buffer);
 _startDayPrice = buffer[0].close;
 ATR_handle = iATR(_symbol, _period, 100);
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 ArrayResize(enumMoveType, depth);
 ArrayInitialize(enumMoveType, 0);
 difToTrend = 2;  // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.
}

//+-----------------------------------------------------+
//| ������� ��������� ��� �������� ����� �� �������     |
//+-----------------------------------------------------+
bool CColoredTrend::CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 //PrintFormat("����� ������� CountMoveType. i = %d, start_pos = %d", bar, start_pos);
 if(bar == 0) //�� "�������" ���� ������ ����������� �� ����� � ������ ������� ������� ��� �� ������ �������� � ����������
  return true; 

 if(bar == ArraySize(enumMoveType))  // ������� ������ ��� ������ �����������
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  
 if(FillTimeSeries(CURRENT_TF, 3, start_pos, buffer_Rates) < 0) // ������� ������ ������������ �������
  return false; 
 if(FillATRBuf(2, start_pos) < 0) // �������� ������ ������� ���������� ATR
  return false;  
  
 enumMoveType[bar] = enumMoveType[bar - 1];
 difToNewExtremum = buffer_ATR[0] * _percentage_ATR;
 SExtremum current_bar = {0, -1};
 
 //if (num0.direction != current_bar.direction || num0.price != current_bar.price)
 //{
  current_bar = isExtremum(start_pos);   
  if (current_bar.direction != 0)
  {
   if (current_bar.direction == num0.direction) // ���� ����� ��������� � ��� �� ����������, ��� ������
   {
    num0.price = current_bar.price;
   }
   else
   {
    num2 = num1;
    num1 = num0;
    num0 = current_bar;
   }
  }
 //}
 
 if (num2.direction == 0 && num2.price == -1) //���������� (num0 > 0 && num1 > 0 && num2 > 0) �.�. num2 �� ����������� ���� �� ����������� num0 � num1
 {
  //PrintFormat("�� ��������� 3 ����������. i = %d; start_pos = %d; num0 = {%d, %f}; num1 = {%d, %f}; num2 = {%d, %f};", bar, start_pos, num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
  return true; 
 } 
  
 int newTrend = isNewTrend();        
 if (newTrend == -1)
 {// ���� ������� ����� ��������� (0) � ������������� (1) ����������� � "difToTrend" ��� ������ ������ ��������
  PrintFormat("��������� ������� isNewTrend DOWN �� %d ����", bar); 
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  return true;
 }
 else if (newTrend == 1) // ���� ������� �������� ���� ���������� ���������� 
 {
  PrintFormat("��������� ������� isNewTrend UP �� %d ����", bar);
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  return true;
 }
 else 
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   return true;
  }
 }
 
 //������ ��������� ���� ���� ���� �������� ������ �������� ����������� ����
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_UP || enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN) && 
      LessDoubles(buffer_Rates[1].close, buffer_Rates[0].open, digits))
 {
  PrintFormat("bar = %d, ���������� ����� �����(�������� ��������� ����), ������� ��������=%.05f ������ ����������� ��������=%.05f", bar, buffer_Rates[1].close, buffer_Rates[0].open);
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
  lastOnTrend = num0;
  return true;
 }
 //������ ��������� ����� ���� ���� �������� ������ �������� ����������� ����
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && 
      GreatDoubles(buffer_Rates[1].close, buffer_Rates[0].open, digits))
 {
  PrintFormat("bar = %d, ���������� ����� ����(�������� ��������� �����), ������� ��������=%.05f ������ ����������� ��������=%.05f", bar, buffer_Rates[1].close, buffer_Rates[0].open);
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  lastOnTrend = num0;
  return true;
 }
 
 //��������� �������� �� ����� �����/���� ��� ����������� ������� isCorrectionEnds
 //���� ��������� ���� ������/������ ���������� ��������� ��� �� ������� �� "�������" ���
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[1].close, MOVE_TYPE_CORRECTION_UP, start_pos))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  PrintFormat("bar = %d, ����������� ��������� �����(������� ����� ����), ��������� ����=%.05f ������ ���������� ����������=%.05f", bar, buffer_Rates[1].close, lastOnTrend.price);
  return true;
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[1].close, MOVE_TYPE_CORRECTION_DOWN, start_pos))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  PrintFormat("bar = %d, ����������� ��������� ����(������� ����� �����), ��������� ����=%.05f ������ ���������� ����������=%.05f", bar, buffer_Rates[1].close, lastOnTrend.price);
  return true;
 }

 if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_UP || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_DOWN)
   &&(current_bar.direction > 0)
   &&(LessDoubles(current_bar.price, num2.price, digits) // ���� ����� �������� ������ �����������
    ||GreatDoubles( MathAbs(num2.price - num1.price) // ��� ������� ����� ������ � ������ ������ ������� ����� ������ � ������� 
                   ,MathAbs(num2.price - current_bar.price) // ������� ����� �����������(����������) ������ �������� (������� ����� ����������������)
                   ,digits)))   
 {
  PrintFormat("bar = %d, ������� ����, ����� �������� ������ ����������� num0 =%.05f < num2=%.05f ��� num2-num1=%.05f > num2-num0=%.05f", bar, current_bar.price, num2.price, (num2.price-num1.price), (num2.price-current_bar.price));
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  return true;
 }
 
 if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_UP)
   &&(current_bar.direction < 0)
   &&(GreatDoubles(current_bar.price, num2.price, digits)    // ���� ����� ������� ������ �����������
    ||GreatDoubles( MathAbs(num2.price - num1.price) // ��� ������� ����� ������ � ������ ������ ������� ����� ������ � ������� 
                   ,MathAbs(num2.price - current_bar.price) // ������� ����� �����������(����������) ������ �������� (������� ����� ����������������)
                   ,digits)))  // ��� ����� ������� - ������
 { 
  PrintFormat("bar = %d, ������� ����, ����� ������� ������ ����������� num0 =%.05f > num2=%.05f ��� num2-num1=%.05f > num2-num0=%.05f", bar, current_bar.price, num2.price, (num2.price-num1.price), (num2.price-current_bar.price));
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  return true;
 }
 
 return true;
}

//+------------------------------------------+
//| ������� �������� ������� �� �������      |
//+------------------------------------------+
ENUM_MOVE_TYPE CColoredTrend::GetMoveType(int i)
{
 return (enumMoveType[i]);
}
//+--------------------------------------------------------------------+
//| ������� ���������� ����������� � �������� ���������� � ����� vol2  |
//+--------------------------------------------------------------------+
SExtremum CColoredTrend::isExtremum(int start_index)
{
 SExtremum result = {0,0};
 MqlRates buffer[1];
 CopyRates(_symbol, _period, start_index, 1, buffer);
 
 if (((num0.direction == 0) && (GreatDoubles(buffer[0].close, _startDayPrice + 2*difToNewExtremum, digits))) // ���� ����������� ��� ��� � ���� 2 ���� �� ��������� ����
   || (num0.direction > 0 && (GreatDoubles(buffer[0].close, num0.price, digits)))
   || (num0.direction < 0 && (GreatDoubles(buffer[0].close, num0.price + difToNewExtremum, digits))))
 {
  result.direction = 1;
  result.price = buffer[0].close;
 }
 
 if (((num0.direction == 0) && (LessDoubles(buffer[0].close, _startDayPrice - 2*difToNewExtremum, digits))) // ���� ����������� ��� ��� � ���� 2 ���� �� ��������� ����
   || (num0.direction < 0 && (LessDoubles(buffer[0].close, num0.price, digits)))
   || (num0.direction > 0 && (LessDoubles(buffer[0].close, num0.price - difToNewExtremum, digits))))
 {
  result.direction = -1;
  result.price = buffer[0].close;
 }
 
 //PrintFormat("start_pos = %d; num0 = {%d, %.05f}; num1 = {%d, %.05f}; num2 = {%d, %.05f};", start_index, num0.direction, num0.price, num1.direction, num1.price, num2.direction, num2.price);
 return(result);
}


//+-------------------------------------------------+
//| ������� ��������� ������ ����������� �� ������� |
//+-------------------------------------------------+
int CColoredTrend::FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[])
{
 //--- ������� �������
 int attempts = 0;
//--- ������� �����������
 int copied = 0;
//--- ������ 25 ������� �������� ��������� �� ������� �������
 ENUM_TIMEFRAMES period;
 switch (tfType)
 {
  case BOTTOM_TF: 
   period = GetBottomTimeframe(_period);
   break;
  case CURRENT_TF:
   period = _period;
   break;
  case TOP_TF:
   period = GetTopTimeframe(_period);
   break;
 }
 
 while(attempts < 25 && (copied = CopyRates(_symbol, period, start_pos, count, array))<0) // ������ ������ �� 0 �� count-1, ����� count ���������
 {
  Sleep(100);
  attempts++;
 }
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied != count)
 {
  string comm = StringFormat("��� ������� %s �������� %d ����� �� %d ������������� Rates. Period = %s. Error = %d | start = %d count = %d",
                             _symbol,
                             copied,
                             count,
                             EnumToString((ENUM_TIMEFRAMES)period),
                             GetLastError(),
                             start_pos,
                             count
                            );
  //--- ������� ��������� � ����������� �� ������� ���� �������
  Print(comm);
 }
 return(copied);
}

//+----------------------------------------------------+
//| ������� ��������� ������ ���������� ATR �� ������� |
//+----------------------------------------------------+
int CColoredTrend::FillATRBuf(int count, int start_pos = 0)
{
 if(ATR_handle == INVALID_HANDLE)                      //��������� ������� ������ ����������
 {
  Print("�� ������� �������� ����� ATR");             //���� ����� �� �������, �� ������� ��������� � ��� �� ������
 }
 //--- ������� �������
   int attempts = 0;
//--- ������� �����������
   int copied = 0;
//--- ������ 25 ������� �������� ��������� �� ������� �������
 while(attempts < 250 && (copied = CopyBuffer(ATR_handle, 0, start_pos, count, buffer_ATR)) < 0) // ������ ������ �� 0 �� count, ����� count ���������
 {
  Sleep(100);
  attempts++;
 }
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied != count)
 {
  string comm = StringFormat("��� ������� %s �������� %d ����� �� %d ������������� ATR. Period = %s.  Error = %d | start = %d count = %d bars_calculated = %d",
                             _symbol,
                             copied,
                             count,
                             EnumToString((ENUM_TIMEFRAMES)_period),
                             GetLastError(),
                             start_pos,
                             count,
                             BarsCalculated(ATR_handle)
                            );
  //--- ������� ��������� � ����������� �� ������� ���� �������
  Print(comm);
 }
 return(copied);
}

//+----------------------------------------------------+
//| ������� ��������� ������ ���������� ATR �� ������� |
//+----------------------------------------------------+
bool CColoredTrend::isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, int start_pos)
{
 bool extremum_condition, 
      bottomTF_condition;
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  extremum_condition = LessDoubles(price, lastOnTrend.price, digits);
  bottomTF_condition = isLastBarHuge(start_pos);
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(price, lastOnTrend.price, digits);
  bottomTF_condition = isLastBarHuge(start_pos);
 }
 return ((extremum_condition) || (bottomTF_condition));
}

bool CColoredTrend::isLastBarHuge(int start_pos)
{
 double sum;
 MqlRates rates[];
 FillTimeSeries(BOTTOM_TF, _depth, start_pos, rates);
 for(int i = 0; i < _depth - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / _depth;
 double lastBar = MathAbs(rates[_depth-1].open - rates[_depth-1].close);
    
 return(GreatDoubles(lastBar, avgBar*2));
}

int CColoredTrend::isNewTrend()
{
 if (num1.direction < 0 && LessDoubles((num2.price - num1.price)*difToTrend ,(num0.price - num1.price), digits))
  return(1);
 if (num1.direction > 0 && LessDoubles((num1.price - num2.price)*difToTrend ,(num1.price - num0.price), digits))
  return(-1);
  
 return(0);
}

void CColoredTrend::Zeros()
{
  SExtremum zero = {0, 0};
 
  for(int i = 0; i < ArraySize(enumMoveType); i++)
  {
   enumMoveType[i] = MOVE_TYPE_UNKNOWN;
  }
}
