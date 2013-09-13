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
  int _depth;
  ENUM_MOVE_TYPE enumMoveType[];
  SExtremum aExtremums[];
  int digits;
  int num0, num1, num2;  // ������ ��������� �����������
  int lastOnTrend;       // ��������� ��������� �������� ������
  double difToNewExtremum;
  double difToTrend;     // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.
  int ATR_handle;
  double ATR_buf[];
  int _count;            // ���������� ����� ��� ������� ���������� 
  int _shift;            // ���������� ����� � �������
  
  int FillTimeSeries(MqlRates &_rates[], int count, int start_pos, ENUM_TF tfType = CURRENT_TF);
  int FillATRBuf(int count, int start_pos);
  bool isCorrectionEnds(MqlRates &cur_rates[], MqlRates &bot_rates[], int bar, ENUM_MOVE_TYPE move_type);
  bool isLastBarHuge(MqlRates &rates[]);
  
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int count, int shift = 3);
  SExtremum isExtremum(double vol1, double vol2, double vol3, int bar = 0);
  void CountMoveType(ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  double GetExtremum(int i);
  int GetExtremumDirection(int i);
  int TrendDirection();
};

//+-----------------------------------------+
//| �����������                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int count, int shift = 3) : _count(count), _shift(shift)
{
 ArraySetAsSeries(enumMoveType, true);
 ArraySetAsSeries(ATR_buf, true);
 if (shift < 3) shift = 3;
 _symbol = symbol;
 _period = period;
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 //difToNewExtremum = 70;
 difToTrend = 2;  // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.
 
 //���������� ��������� � �������� ��� ����� 
 ATR_handle = iATR(_symbol, _period, 100);
 if(ATR_handle == INVALID_HANDLE)                      //��������� ������� ������ ����������
 {
  Print("�� ������� �������� ����� ATR");             //���� ����� �� �������, �� ������� ��������� � ��� �� ������
  //return(-1);                                          //��������� ������ � �������
 }
 // �������� ������ ������ � ������
 FillATRBuf(shift, count - 1);
 
 ArrayResize(aExtremums, shift);
 // �������� ������ � ����������� � ����������
 MqlRates rates[];
 int rates_total = FillTimeSeries(rates, shift, count - 1); // ������� ������ ������������ ������� 
 //Print("rates_total= ", rates_total);
 
 for(int bar = 1; bar < shift - 1 && !IsStopped(); bar++) // ��������� ���������� �� ������� � �������
 { 
  difToNewExtremum = ATR_buf[bar] / 2;
  //Print("Constructor: ATR/2 = ", difToNewExtremum);
  aExtremums[bar] =  isExtremum(rates[bar - 1].close, rates[bar].close, rates[bar + 1].close);
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
 }
}

//+------------------------------------------+
//| ������� ��������� ��� �������� �����     |
//+------------------------------------------+
void CColoredTrend::CountMoveType(ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 // �������� ������ � ����������� � ����������
 MqlRates rates[];
 MqlRates bottomTF_rates[];
 int rates_total = FillTimeSeries(rates, _count + _shift); // ������� ������ ������������ �������
 FillTimeSeries(bottomTF_rates, _count + _shift, 0, BOTTOM_TF);
 FillATRBuf(_count + _shift);                              // �������� ������ ������� ���������� ATR
 // ������� ������ ��� ������� ������ � �����������
 ArrayResize(enumMoveType, rates_total);
 ArrayResize(aExtremums, rates_total);
 
 for(int bar = _shift; bar < _count + _shift - 1 && !IsStopped(); bar++) // ��������� ������ �������� ���������� �����, ����� ��������������
 {
  enumMoveType[bar] = enumMoveType[bar - 1];
  difToNewExtremum = ATR_buf[bar] / 2;
  //Print("ATR/2 = ", difToNewExtremum);
  /*
  PrintFormat("bar = %d, ���������� num0=%.05f, num1=%.05f, num2=%.05f, num0 - num1 =%.05f, num0 - close=%.05f"
             , bar, aExtremums[num0].price, aExtremums[num1].price, aExtremums[num2].price
             , MathAbs(aExtremums[num0].price - aExtremums[num1].price)*difToTrend, MathAbs(aExtremums[num0].price - rates[bar].close));
  */ 
            
  if (LessDoubles(MathAbs(aExtremums[num0].price - aExtremums[num1].price)*difToTrend
                 ,MathAbs(aExtremums[num0].price - rates[bar].close), digits))
  {// ���� ������� ����� ��������� (0) � ������������� (1) ����������� � "difToTrend" ��� ������ ������ �������� 
   //PrintFormat("bar = %d, �������� ������ ��������� ������� �����������", bar);
   if (LessDoubles(rates[bar].close, aExtremums[num0].price, digits)) // ���� ������� �������� ���� ���������� ���������� 
   {
    if (topTF_Movement == MOVE_TYPE_FLAT)
    {
     enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN;
    }
    else
    {
     //PrintFormat("bar = %d, ������� ����� ����, ������� ��������=%.05f ������ ���������� ����������=%.05f", bar, rates[bar].close, aExtremums[num0].price);
     enumMoveType[bar] = MOVE_TYPE_TREND_DOWN;
     //continue;
    }
   }
   if (GreatDoubles(rates[bar].close, aExtremums[num0].price, digits)) // ���� ������� �������� ���� ���������� ���������� 
   {
    if (topTF_Movement == MOVE_TYPE_FLAT)
    {
     enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN;
    }
    else
    {
     //PrintFormat("bar = %d, ������� ����� ����, ������� ��������=%.05f ������ ���������� ����������=%.05f", bar, rates[bar].close, aExtremums[num0].price);
     enumMoveType[bar] = MOVE_TYPE_TREND_UP;
     //continue;
    }
   }
  }
  
  if ((enumMoveType[bar] == MOVE_TYPE_TREND_UP || enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN) && 
       LessDoubles(rates[bar].close, rates[bar - 1].open, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
   lastOnTrend = num0;
  }
  if ((enumMoveType[bar] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && 
       GreatDoubles(rates[bar].close, rates[bar - 1].open, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
   lastOnTrend = num0;
  }
  
  if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
       isCorrectionEnds(rates, bottomTF_rates, bar, MOVE_TYPE_CORRECTION_UP))
  {
   if (topTF_Movement == MOVE_TYPE_FLAT)
   {
    enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN;
   }
   else
   {
    enumMoveType[bar] = MOVE_TYPE_TREND_DOWN;
   }
  }
  
  if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
       isCorrectionEnds(rates, bottomTF_rates, bar, MOVE_TYPE_CORRECTION_DOWN))
  {
   if (topTF_Movement == MOVE_TYPE_FLAT)
   {
    enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN;
   }
   else
   {
    enumMoveType[bar] = MOVE_TYPE_TREND_UP;
   }
  }

  aExtremums[bar] =  isExtremum(rates[bar - 1].close, rates[bar].close, rates[bar + 1].close, num0);
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
   
   //PrintFormat("bar = %d, ���������� num0 =%.05f, num1=%.05f, num2=%.05f", bar, aExtremums[num0].price, aExtremums[num1].price, aExtremums[num2].price);
   if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_UP || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_DOWN)
     &&(aExtremums[bar].direction > 0)
     &&(
        LessDoubles(aExtremums[bar].price, aExtremums[num2].price, digits) // ���� ����� �������� ������ �����������
      ||GreatDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price) // ��� ������� ����� ������ � ������ ������ ������� ����� ������ � ������� 
                     ,MathAbs(aExtremums[num2].price - aExtremums[bar].price) // ������� ����� �����������(����������) ������ �������� (������� ����� ����������������)
                     ,digits)))   
   {
    //PrintFormat("bar = %d, ������� ����, ����� �������� ������ ����������� num0 =%.05f < num2=%.05f", bar, aExtremums[num0].price, aExtremums[num2].price);
    enumMoveType[bar] = MOVE_TYPE_FLAT;
   }
   
   if ((enumMoveType[bar - 1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar - 1] == MOVE_TYPE_CORRECTION_UP)
     &&(aExtremums[bar].direction < 0)
     &&(
        GreatDoubles(aExtremums[bar].price, aExtremums[num2].price, digits)
      ||GreatDoubles(MathAbs(aExtremums[num2].price - aExtremums[num1].price) // ��� ������� ����� ������ � ������ ������ ������� ����� ������ � ������� 
                     ,MathAbs(aExtremums[num2].price - aExtremums[bar].price) // ������� ����� �����������(����������) ������ �������� (������� ����� ����������������)
                     ,digits)))  // ��� ����� ������� - ������
   { 
    //PrintFormat("bar = %d, ������� ����, ����� ������� ������ ����������� num0 =%.05f < num2=%.05f", bar, aExtremums[num0].price, aExtremums[num2].price);
    enumMoveType[bar] = MOVE_TYPE_FLAT;
   }
  }
  //PrintFormat("bar = %d, ��� ���������, ���� ����������� ���� %s", bar, MoveTypeToColor(enumMoveType[bar - 1]));
  //if (enumMoveType[bar] == -1)
   //enumMoveType[bar] = enumMoveType[bar - 1];
  //else
   //PrintFormat("enumMoveType[%d]=%d",bar,enumMoveType[bar]);
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
  && LessDoubles(aExtremums[last].price, vol2 - difToNewExtremum*Point(), 5))
 {
  res.direction = 1;// �������� � ����� vol2
 } 
 return(res); // ��� ���������� � ����� vol2
}

//+-------------------------------------------------+
//| ������� ��������� ������ ����������� �� ������� |
//+-------------------------------------------------+
int CColoredTrend::FillTimeSeries(MqlRates &_rates[], int count, int start_pos = 0, ENUM_TF tfType = CURRENT_TF)
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
 while(attempts < 25 && (copied = CopyRates(_symbol, period, start_pos, count, _rates))<0) // ������ ������ �� 0 �� count, ����� count ���������
 {
  Sleep(100);
  attempts++;
 }
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied != count)
 {
  string comm = StringFormat("��� ������� %s ������� �������� ������ %d ����� �� %d �������������",
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
 //--- ������� �������
   int attempts = 0;
//--- ������� �����������
   int copied = 0;
//--- ������ 25 ������� �������� ��������� �� ������� �������
 while(attempts < 25 && (copied = CopyBuffer(ATR_handle, 0, start_pos, count, ATR_buf)) < 0) // ������ ������ �� 0 �� count, ����� count ���������
 {
  Sleep(100);
  attempts++;
 }
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied != count)
 {
  string comm = StringFormat("��� ������� %s ������� �������� ������ %d ����� �� %d �������������",
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
bool CColoredTrend::isCorrectionEnds(MqlRates &cur_rates[], MqlRates &bot_rates[], int bar, ENUM_MOVE_TYPE move_type)
{
 bool extremum_condition, bottomTF_condition;
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  extremum_condition = LessDoubles(cur_rates[bar].close, aExtremums[lastOnTrend].price, digits);
  bottomTF_condition = isLastBarHuge(bot_rates);
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(cur_rates[bar].close, aExtremums[lastOnTrend].price, digits);
  bottomTF_condition = isLastBarHuge(bot_rates);
 }
 return ((extremum_condition) || (bottomTF_condition));
}

bool CColoredTrend::isLastBarHuge(MqlRates &rates[])
{
 double sum;
 for(int i = _shift; i < _count + _shift - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / _shift;
 double lastBar = MathAbs(rates[0].open - rates[0].close);
    
 return(GreatDoubles(lastBar, avgBar*2));
}