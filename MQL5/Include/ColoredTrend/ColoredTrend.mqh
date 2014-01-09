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
  SExtremum aExtremums[];
  int digits;
  int num0, num1, num2;  // ������ ��������� �����������
  int lastOnTrend;       // ��������� ��������� �������� ������  
  double _percentage_ATR;
  double difToNewExtremum;
  double difToTrend;     // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.
  int _depth;            // ���������� ����� ��� ������� ���������� 
  int _shift;            // ���������� ����� � �������
  int ATR_handle;
  double buffer_ATR[];
  MqlRates buffer_Rates[];
  MqlRates buffer_TopRates[];
  MqlRates buffer_BottomRates[];
  
  int FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[]);
  int FillATRBuf(int count, int start_pos);
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, int start_pos);
  bool isLastBarHuge(int start_pos);
  bool isNewTrend(double price);
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR);
  SExtremum isExtremum(double vol1, double vol2, double vol3, int bar = 0);
  int CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  double GetExtremum(int i);
  int GetExtremumDirection(int i);
  int TrendDirection();
  void Zeros();
};

//+-----------------------------------------+
//| �����������                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR) : 
                   _depth(depth), 
                   _shift(40)
{

 _symbol = symbol;
 _period = period;
 ATR_handle = iATR(_symbol, _period, 100);
 //PrintFormat("PERIOD ATR: %s", EnumToString((ENUM_TIMEFRAMES)_period));
 _percentage_ATR = percentage_ATR;
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 ArrayResize(enumMoveType, depth);
 ArrayResize(  aExtremums, depth);
 ArrayInitialize(enumMoveType, 0);
 SExtremum zero = {0, 0};
 ArraySetAsSeries(buffer_Rates, false);
 ArraySetAsSeries(buffer_TopRates, false);
 ArraySetAsSeries(buffer_BottomRates, false);
 for(int i = 0; i < depth; i++)
 {
  aExtremums[i] = zero;
 }
 difToTrend = 2;  // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.
}

//+------------------------------------------+
//| ������� ��������� ��� �������� �����     |
//+------------------------------------------+
int CColoredTrend::CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
  if(bar == ArraySize(enumMoveType)) 
 {
  PrintFormat("BEFORE_MOVETYPE: %d", ArraySize(enumMoveType));
  ArrayResize (enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  PrintFormat("AFTER_MOVETYPE: %d", ArraySize(enumMoveType));
 }
 if(bar == ArraySize(aExtremums)  ) 
 {
  PrintFormat("BEFORE_EXTREMUMS: %d", ArraySize(aExtremums));
  ArrayResize (  aExtremums, ArraySize(  aExtremums)*2, ArraySize(  aExtremums)*2);
  PrintFormat("AFTER_EXTREMUMS: %d", ArraySize(aExtremums));
 }
 if (bar != 0) //������ ��� ����� � ������ ����� �� ��������� ���������� ������ ��� ����� ����������!
 {
  enumMoveType[bar] = enumMoveType[bar - 1];
  PrintFormat("B: enumMoveType[%d] = %s, enumMoveType[%d] = %s", bar, MoveTypeToString(enumMoveType[bar]), bar - 1, MoveTypeToString(enumMoveType[bar - 1]));
 }
 if(FillTimeSeries(TOP_TF, 4, start_pos, buffer_Rates) < 0) return (11); // ������� ������ ������������ �������
 if(FillTimeSeries(BOTTOM_TF, 4, start_pos, buffer_Rates) < 0) return (12); // ������� ������ ������������ �������
 if(FillTimeSeries(CURRENT_TF, 4, start_pos, buffer_Rates) < 0) return (13); // ������� ������ ������������ �������
 if(FillATRBuf(4, start_pos) < 0) return (2);  // �������� ������ ������� ���������� ATR
 // ������� ������ ��� ������� ������ � �����������
 difToNewExtremum =  buffer_ATR[1] * _percentage_ATR;
 
 
  // ��������� ������� ���������� �� ������� ����
 if (num0 != bar)
 {
  aExtremums[bar] = isExtremum(buffer_Rates[0].close, buffer_Rates[1].close, buffer_Rates[2].close, num0);
  if (aExtremums[bar].direction != 0)
  {
   if (aExtremums[bar].direction == aExtremums[num0].direction) // ���� ����� ��������� � ��� �� ����������, ��� ������
   {
    aExtremums[num0].direction = 0;
    num0 = bar;
   }
  else
    {
    num2 = num1;
    num1 = num0;
    num0 = bar;
   }
   //PrintFormat("bar = %d, ���������� num0=%d=%.05f, num1=%d=%.05f, num2=%d=%.05f", bar, num0, aExtremums[num0].price, num1, aExtremums[num1].price, num2, aExtremums[num2].price);
  }
 }

 
 bool newTrend = isNewTrend(buffer_Rates[2].close);
           
 if (newTrend)
 {// ���� ������� ����� ��������� (0) � ������������� (1) ����������� � "difToTrend" ��� ������ ������ �������� 
  if (LessDoubles(buffer_Rates[2].close, aExtremums[num0].price, digits)) // ���� ������� �������� ���� ���������� ���������� 
  {
   enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
   //PrintFormat("bar = %d, ������� ����� ����, ������� ��������=%.05f ������ ���������� ����������=%.05f", bar, buffer_Rates[2].close, aExtremums[num0].price);
  }
  if (GreatDoubles(buffer_Rates[2].close, aExtremums[num0].price, digits)) // ���� ������� �������� ���� ���������� ���������� 
  {
   enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
   //PrintFormat("bar = %d, ������� ����� �����, ������� ��������=%.05f ������ ���������� ����������=%.05f", bar, buffer_Rates[2].close, aExtremums[num0].price);
  }
 }
 
 //������ ��������� ���� ���� ���� �������� ������ �������� ���������� ����
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_UP || enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN) && 
      LessDoubles(buffer_Rates[2].close, buffer_Rates[1].open, digits))
 {
  //PrintFormat("bar = %d, ���������� ����� �����(�������� ��������� ����), ������� ��������=%.05f ������ ����������� ��������=%.05f", bar, buffer_Rates[2].close, buffer_Rates[1].open);
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
  lastOnTrend = num0;
 }
 //������ ��������� ����� ���� ���� �������� ������ �������� ���������� ����
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && 
      GreatDoubles(buffer_Rates[2].close, buffer_Rates[1].open, digits))
 {
  //PrintFormat("bar = %d, ���������� ����� ����(�������� ��������� �����), ������� ��������=%.05f ������ ����������� ��������=%.05f", bar, buffer_Rates[2].close, buffer_Rates[1].open);
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  lastOnTrend = num0;
 }
 
 //��������� �������� �� ����� �����/���� ��� ����������� ������� isCorrectionEnds
 //���� ��������� ���� ������/������ ���������� ���������� ��� �� ������� �� "�������" ���
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[2].close, MOVE_TYPE_CORRECTION_UP, start_pos))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  //PrintFormat("bar = %d, ����������� ��������� �����(������� ����� ����), ��������� ����=%.05f ������ ���������� ����������=%.05f", bar, buffer_Rates[2].close, aExtremums[lastOnTrend].price);
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[2].close, MOVE_TYPE_CORRECTION_DOWN, start_pos))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  //PrintFormat("bar = %d, ����������� ��������� ����(������� ����� �����), ��������� ����=%.05f ������ ���������� ����������=%.05f", bar, buffer_Rates[2].close, aExtremums[lastOnTrend].price);
 }

 if ( bar != 0
   &&(enumMoveType[bar - 1] == MOVE_TYPE_TREND_UP || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_DOWN)
   &&(aExtremums[bar].direction > 0)
   &&(
      LessDoubles(aExtremums[bar].price, aExtremums[num2].price, digits) // ���� ����� �������� ������ �����������
    ||GreatDoubles( MathAbs(aExtremums[num2].price - aExtremums[num1].price) // ��� ������� ����� ������ � ������ ������ ������� ����� ������ � ������� 
                   ,MathAbs(aExtremums[num2].price -  aExtremums[bar].price) // ������� ����� �����������(����������) ������ �������� (������� ����� ����������������)
                   ,digits)))   
 {
  //PrintFormat("bar = %d, ������� ����, ����� �������� ������ ����������� num0 =%.05f < num2=%.05f ��� num2-num1=%.05f > num2-num0=%.05f", bar, aExtremums[bar].price, aExtremums[num2].price, (aExtremums[num2].price-aExtremums[num1].price), (aExtremums[num2].price-aExtremums[bar].price));
  enumMoveType[bar] = MOVE_TYPE_FLAT;
 }
 
 if ( bar != 0
   &&(enumMoveType[bar - 1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_UP)
   &&(aExtremums[bar].direction < 0)
   &&(
      GreatDoubles(aExtremums[bar].price, aExtremums[num2].price, digits)
    ||GreatDoubles( MathAbs(aExtremums[num2].price - aExtremums[num1].price) // ��� ������� ����� ������ � ������ ������ ������� ����� ������ � ������� 
                   ,MathAbs(aExtremums[num2].price -  aExtremums[bar].price) // ������� ����� �����������(����������) ������ �������� (������� ����� ����������������)
                   ,digits)))  // ��� ����� ������� - ������
 { 
  //PrintFormat("bar = %d, ������� ����, ����� ������� ������ ����������� num0 =%.05f > num2=%.05f ��� num2-num1=%.05f > num2-num0=%.05f", bar, aExtremums[bar].price, aExtremums[num2].price, (aExtremums[num2].price-aExtremums[num1].price), (aExtremums[num2].price-aExtremums[bar].price));
  enumMoveType[bar] = MOVE_TYPE_FLAT;
 }

 return 0;
}

//+------------------------------------------+
//| ������� �������� ������� �� �������      |
//+------------------------------------------+
ENUM_MOVE_TYPE CColoredTrend::GetMoveType(int i)
{
 return (enumMoveType[i]);
}

//+------------------------------------------+
//| ������� �������� ������� �� �������      |
//+------------------------------------------+
double CColoredTrend::GetExtremum(int i)
{
 if (aExtremums[i].direction > 0)
 {
  return (aExtremums[i].price + 50*Point());
 }
 if (aExtremums[i].direction < 0)
 {
  return (aExtremums[i].price - 50*Point());
 }
 return (0.0);
}

//+------------------------------------------+
//| ������� �������� ������� �� �������      |
//+------------------------------------------+
int CColoredTrend::GetExtremumDirection(int i)
{
 return (aExtremums[i].direction);
}
//+--------------------------------------------------------------------+
//| ������� ���������� ����������� � �������� ���������� � ����� vol2  |
//+--------------------------------------------------------------------+
SExtremum CColoredTrend::isExtremum(double vol1, double vol2, double vol3, int last = 0)
{
 //PrintFormat("%f %f %f", vol1, vol2, vol3);
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 SExtremum res;
 res.direction = 0;
 res.price = vol2;
 if (GreatDoubles(vol1, vol2, digits)
  && LessDoubles (vol2, vol3, digits)
  && GreatDoubles(aExtremums[last].price, vol2 + difToNewExtremum, 5))
 {
  //PrintFormat("%s : %s MINIMUM %f; %f; %f; ATR = %f", TimeToString(TimeCurrent()), EnumToString((ENUM_TIMEFRAMES)_period), vol1, vol2, vol3, difToNewExtremum/_percentage_ATR);
  res.direction = -1;// ������� � ����� vol2
 }
 
 if (LessDoubles(vol1, vol2, digits)
  && GreatDoubles(vol2, vol3, digits)
  && LessDoubles(aExtremums[last].price, vol2 - difToNewExtremum, 5))
 {
  //PrintFormat("%s : %s MAXIMUM %f; %f; %f; ATR = %f", TimeToString(TimeCurrent()), EnumToString((ENUM_TIMEFRAMES)_period), vol1, vol2, vol3, difToNewExtremum/_percentage_ATR);
  res.direction = 1;// �������� � ����� vol2
 } 
 return(res); // ��� ���������� � ����� vol2
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
  Alert("�� ������� �������� ����� ATR");             //���� ����� �� �������, �� ������� ��������� � ��� �� ������
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
  extremum_condition = LessDoubles(price, aExtremums[lastOnTrend].price, digits);
  bottomTF_condition = isLastBarHuge(start_pos);
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(price, aExtremums[lastOnTrend].price, digits);
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

bool CColoredTrend::isNewTrend(double price)
{
 // ����� ����������� ������ ������ ������ ������. ��� ��������, ����� ���� ����� � ������� �������������� ���������� � ����� ���� ����� � ������� ���������� ����������
 bool newTrend = false;
 if ((aExtremums[num1].price < aExtremums[num0].price && aExtremums[num0].price < price) ||
     (aExtremums[num1].price > aExtremums[num0].price && aExtremums[num0].price > price))
 {
  if (LessDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price)*difToTrend
                 ,MathAbs(aExtremums[num1].price - price), digits))
  {
   newTrend = true;
  }
 }
 else
 {
  if (LessDoubles(MathAbs(aExtremums[num0].price - aExtremums[num1].price)*difToTrend
                 ,MathAbs(aExtremums[num0].price - price), digits))
  {
   newTrend = true;
  }
 }
 return(newTrend);
}

void CColoredTrend::Zeros()
{
  SExtremum zero = {0, 0};
 
  for(int i = 0; i < ArraySize(aExtremums); i++)
  {
   aExtremums[i] = zero;
  }
  for(int i = 0; i < ArraySize(enumMoveType); i++)
  {
   enumMoveType[i] = MOVE_TYPE_UNKNOWN;
  }
}
