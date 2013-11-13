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

double buffer_ATR[];
MqlRates buffer_Rates[];
MqlRates buffer_TopRates[];
MqlRates buffer_BottomRates[];

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
  double difToNewExtremum;
  double difToTrend;     // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.
  int _depth;            // ���������� ����� ��� ������� ���������� 
  int _shift;            // ���������� ����� � �������
  
  int FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[]);
  int FillATRBuf(int count, int start_pos);
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type);
  bool isLastBarHuge();
  bool isNewTrend(double price);
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int count);
  SExtremum isExtremum(double vol1, double vol2, double vol3, int bar = 0);
  void CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  double GetExtremum(int i);
  int GetExtremumDirection(int i);
  int TrendDirection();
};

//+-----------------------------------------+
//| �����������                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth) : 
                   _depth(depth), 
                   _shift(40)
{

 _symbol = symbol;
 _period = period;
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 ArrayResize(enumMoveType, 1024);
 ArrayResize(  aExtremums, 1024);
 ArrayInitialize(enumMoveType, 0);
 SExtremum zero = {0, 0};
 for(int i = 0; i < 1024; i++)
 {
  aExtremums[i] = zero;
 }
 difToTrend = 2;  // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.
/*
 // �������� ������ ������ � ������
 FillATRBuf(_depth + _shift);
 FillTimeSeries(CURRENT_TF, _depth + _shift, 0, buffer_Rates); // ������� ������ ������������ �������
 ArrayResize(aExtremums, _depth + _shift);
 
 for(int bar = 1; bar < _shift-2 && !IsStopped(); bar++) // ��������� ���������� �� ������� � �������
 { 
  difToNewExtremum = buffer_ATR[bar] / 2;  //���������� difToNewExtremum ������������ � ������� isExtremum
  aExtremums[bar] =  isExtremum(buffer_Rates[bar - 1].close, buffer_Rates[bar].close, buffer_Rates[bar + 1].close);
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
  }
 }*/
}

//+------------------------------------------+
//| ������� ��������� ��� �������� �����     |
//+------------------------------------------+
void CColoredTrend::CountMoveType(int bar, int start_pos = 0, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 //PrintFormat("bar = %d && start_pos = %d", bar, start_pos);
 FillTimeSeries(CURRENT_TF, 4, start_pos, buffer_Rates); // ������� ������ ������������ �������
 FillTimeSeries(BOTTOM_TF, 4, start_pos, buffer_BottomRates);
 FillATRBuf(4, start_pos);                              // �������� ������ ������� ���������� ATR
 // ������� ������ ��� ������� ������ � �����������
 
 difToNewExtremum = buffer_ATR[1] / 2;
 if (bar != 0) 
 {
  enumMoveType[bar] = enumMoveType[bar - 1];
  PrintFormat("enumMoveType[%d] = %s, enumMoveType[%d] = %s", bar, MoveTypeToString(enumMoveType[bar]), bar - 1, MoveTypeToString(enumMoveType[bar - 1]));
 }
 
 bool newTrend = isNewTrend(buffer_Rates[3].close);
           
 if (newTrend)
 {// ���� ������� ����� ��������� (0) � ������������� (1) ����������� � "difToTrend" ��� ������ ������ �������� 
  if (LessDoubles(buffer_Rates[3].close, aExtremums[num0].price, digits)) // ���� ������� �������� ���� ���������� ���������� 
  {
   enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
   PrintFormat("bar = %d, ������� ����� ����, ������� ��������=%.05f ������ ���������� ����������=%.05f", bar, buffer_Rates[3].close, aExtremums[num0].price);
  }
  if (GreatDoubles(buffer_Rates[3].close, aExtremums[num0].price, digits)) // ���� ������� �������� ���� ���������� ���������� 
  {
   enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
   PrintFormat("bar = %d, ������� ����� ����, ������� ��������=%.05f ������ ���������� ����������=%.05f", bar, buffer_Rates[3].close, aExtremums[num0].price);
  }
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_UP || enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN) && 
      LessDoubles(buffer_Rates[3].close, buffer_Rates[2].open, digits))
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
  lastOnTrend = num0;
 }
 if ((enumMoveType[bar] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && 
      GreatDoubles(buffer_Rates[3].close, buffer_Rates[2].open, digits))
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  lastOnTrend = num0;
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[3].close, MOVE_TYPE_CORRECTION_UP))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[3].close, MOVE_TYPE_CORRECTION_DOWN))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
 }
 // ��������� ������� ���������� �� ������� ����
 aExtremums[bar] =  isExtremum(buffer_Rates[0].close, buffer_Rates[1].close, buffer_Rates[2].close, num0);
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
  PrintFormat("bar = %d, ���������� num0=%d=%.05f, num1=%d=%.05f, num2=%d=%.05f", bar, num0, aExtremums[num0].price, num1, aExtremums[num1].price, num2, aExtremums[num2].price);
  if ( bar != 0
    &&(enumMoveType[bar - 1] == MOVE_TYPE_TREND_UP || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_DOWN)
    &&(aExtremums[bar].direction > 0)
    &&(
       LessDoubles(aExtremums[bar].price, aExtremums[num2].price, digits) // ���� ����� �������� ������ �����������
     ||GreatDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price) // ��� ������� ����� ������ � ������ ������ ������� ����� ������ � ������� 
                    ,MathAbs(aExtremums[num2].price - aExtremums[bar].price) // ������� ����� �����������(����������) ������ �������� (������� ����� ����������������)
                    ,digits)))   
  {
   PrintFormat("bar = %d, ������� ����, ����� �������� ������ ����������� num0 =%.05f < num2=%.05f", bar, aExtremums[num0].price, aExtremums[num2].price);
   enumMoveType[bar] = MOVE_TYPE_FLAT;
  }
  
  if ( bar != 0
    &&(enumMoveType[bar - 1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_UP)
    &&(aExtremums[bar].direction < 0)
    &&(
       GreatDoubles(aExtremums[bar].price, aExtremums[num2].price, digits)
     ||GreatDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price) // ��� ������� ����� ������ � ������ ������ ������� ����� ������ � ������� 
                    ,MathAbs(aExtremums[num2].price - aExtremums[bar].price) // ������� ����� �����������(����������) ������ �������� (������� ����� ����������������)
                    ,digits)))  // ��� ����� ������� - ������
  { 
   PrintFormat("bar = %d, ������� ����, ����� ������� ������ ����������� num0 =%.05f < num2=%.05f", bar, aExtremums[num0].price, aExtremums[num2].price);
   enumMoveType[bar] = MOVE_TYPE_FLAT;
  }
 }
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
  res.direction = -1;// ������� � ����� vol2
 }
 
 if (LessDoubles(vol1, vol2, digits)
  && GreatDoubles(vol2, vol3, digits)
  && LessDoubles(aExtremums[last].price, vol2 - difToNewExtremum, 5))
 {
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
 while(attempts < 25 && (copied = CopyRates(_symbol, period, start_pos, count, array))<0) // ������ ������ �� 0 �� count, ����� count ���������
 {
  Sleep(100);
  attempts++;
 }
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied != count)
 {
  string comm = StringFormat("��� ������� %s ������� �������� ������ %d ����� �� %d ������������� Rates",
                             _symbol,
                             copied,
                             count
                            );
  //--- ������� ��������� � ����������� �� ������� ���� �������
  Comment(comm);
 }
 return(copied);
}

//+----------------------------------------------------+
//| ������� ��������� ������ ���������� ATR �� ������� |
//+----------------------------------------------------+
int CColoredTrend::FillATRBuf(int count, int start_pos = 0)
{
 int ATR_handle = iATR(_symbol, _period, 100);
 if(ATR_handle == INVALID_HANDLE)                      //��������� ������� ������ ����������
 {
  Print("�� ������� �������� ����� ATR");             //���� ����� �� �������, �� ������� ��������� � ��� �� ������
 }
 //--- ������� �������
   int attempts = 0;
//--- ������� �����������
   int copied = 0;
//--- ������ 25 ������� �������� ��������� �� ������� �������
 while(attempts < 25 && (copied = CopyBuffer(ATR_handle, 0, start_pos, count, buffer_ATR)) < 0) // ������ ������ �� 0 �� count, ����� count ���������
 {
  Sleep(100);
  attempts++;
 }
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied != count)
 {
  string comm = StringFormat("��� ������� %s ������� �������� ������ %d ����� �� %d ������������� ATR",
                             _symbol,
                             copied,
                             count
                            );
  //--- ������� ��������� � ����������� �� ������� ���� �������
  Comment(comm);
 }
 return(copied);
}

//+----------------------------------------------------+
//| ������� ��������� ������ ���������� ATR �� ������� |
//+----------------------------------------------------+
bool CColoredTrend::isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type)
{
 bool extremum_condition, 
      bottomTF_condition;
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  extremum_condition = LessDoubles(price, aExtremums[lastOnTrend].price, digits);
  bottomTF_condition = isLastBarHuge();
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(price, aExtremums[lastOnTrend].price, digits);
  bottomTF_condition = isLastBarHuge();
 }
 return ((extremum_condition) || (bottomTF_condition));
}

bool CColoredTrend::isLastBarHuge()
{
 double sum;
 MqlRates rates[];
 FillTimeSeries(BOTTOM_TF, _depth, 0, rates);
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
 if(newTrend) Print("NewTrend true");
 else Print("NewTrend false");
 return(newTrend);
}
