//+------------------------------------------------------------------+
//|                                                 ColoredTrend.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.01"

#include <CLog.mqh>
#include <CompareDoubles.mqh>
#include <CExtremum.mqh>
#include "ColoredTrendUtilities.mqh"
#include <StringUtilities.mqh>

#define AMOUNT_OF_PRICE 2           // ���������� ����� � ������� ��� ����� ����� ����. ��� ���������� ���� �������� ��� ��������� ���� � �������� � ���������� ����.
#define AMOUNT_BARS_FOR_HUGE 100    // ���������� ����� �� ������� ��������� ������� ��� �� ������� ����������
#define DEFAULT_DIFF_TO_TREND 1.5   // �������� ���������� ����� �������� �� ���������
#define FACTOR_OF_SUPERIORITY 2     // �� ������� ��� ��� ������ ���� ������ �������� ����� ���� �������
//CLog log_output(OUT_COMMENT, LOG_NONE, 50, "PBI", 30);

//------------------------------------------------------------------
// ����� ������������ �������� ���� �������� �� �����
//------------------------------------------------------------------
class CColoredTrend
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  ENUM_MOVE_TYPE enumMoveType[];
  ENUM_MOVE_TYPE previous_move_type;
  int _digits;
  CExtremum *extremums;
  SExtremum lastOnTrend;       // ��������� ��������� �������� ������
  SExtremum firstOnTrend;      // ���� ������ ������ � ��� �����������  
  double _difToTrend;          // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.
  int _depth;                  // ���������� ����� ��� ������� ���������� 
  double buffer_ATR[];
  MqlRates buffer_Rates[];
  datetime time_buffer[];
  
  int FillTimeSeries(ENUM_TF tfType, int count, datetime start_time, MqlRates &array[]);
  
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, datetime start_time);
  bool isCorrectionWrong(int i);
  int isLastBarHuge(datetime start_time);
  int isNewTrend();
  int isEndTrend();
  void SetDiffToTrend();
  
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period,  int handle_atr, int depth);
  //SExtremum isExtremum(datetime start_index, bool now);
  bool FindExtremumInHistory(int depth);
  bool CountMoveType(int bar, datetime start_time, bool now, SExtremum &extremum[], ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  void Zeros();
  void PrintExtr();
  void PrintEvent(ENUM_MOVE_TYPE mt, ENUM_MOVE_TYPE mt_old, double price, string opinion);
};

//+-----------------------------------------+
//| �����������                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int handle_atr, int depth) : 
                   _symbol(symbol),
                   _period(period),
                   _depth(depth),
                   previous_move_type(MOVE_TYPE_UNKNOWN)
{
 _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 
 extremums = new CExtremum(_symbol, _period, handle_atr);
 
 firstOnTrend.direction = 0;
 firstOnTrend.price = -1;
 lastOnTrend.direction = 0;
 lastOnTrend.price = -1;
 SetDiffToTrend();
 
 PrintFormat("%s %s; precentage ATR = %.02f, diff to trend = %.02f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), extremums.getPercentageATR(), _difToTrend);
 ArrayResize(enumMoveType, depth);
 Zeros();
 //log_output.Write(LOG_DEBUG, StringFormat("%s ����������� ������ CColoredTrend", EnumToString(_period)));
}

//+--------------------------------------+
//| ������� ��������� ��� �������� ����� |
//+--------------------------------------+
bool CColoredTrend::CountMoveType(int bar, datetime start_time, bool now, SExtremum &ret_extremums[], ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 if(bar == 0) //�� "�������" ���� ������ ����������� �� ����� � ������ ������� ������� ��� �� ������ �������� � ����������
  return (true); 

 if(bar == ArraySize(enumMoveType))  // ���� ������ �������� �������� �������� ��� � ��� ����
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  
 if(FillTimeSeries(CURRENT_TF, AMOUNT_OF_PRICE, start_time, buffer_Rates) < 0) // ������� ������ ������������ �������
  return (false);
 
 CopyTime(_symbol, _period, start_time, 1, time_buffer);  
 enumMoveType[bar] = previous_move_type;             // ������� �������� ����� ����������� ��������
 
 int newTrend = 0;
 int count_new_extrs = extremums.RecountExtremum(start_time, now);
 
 if (extremums.ExtrCount() < 3) // �������� �� ������� 3� �����������. ���� ��� ���� ����������� �� �� ������ ���������� �� ���� �� ��������� ��������
  return (true);

 if (count_new_extrs > 0)
 {                          // � ������� ������������ ����������� �� 0 ����� ����� max, �� ����� 1 ����� min  (*)
  if(count_new_extrs == 1)  // ���� �������� ������ ���� ����� ���������
  {
   if(extremums.getExtr(0).direction == 1)       ret_extremums[0] = extremums.getExtr(0);
   else if(extremums.getExtr(0).direction == -1) ret_extremums[1] = extremums.getExtr(0); 
  }
  
  if(count_new_extrs == 2)  // ���� ��������� ��� ����� �����������. ���������� � ������ (*)
  {
   if(extremums.getExtr(0).direction == 1)       { ret_extremums[0] = extremums.getExtr(0); ret_extremums[1] = extremums.getExtr(1); }
   else if(extremums.getExtr(0).direction == -1) { ret_extremums[0] = extremums.getExtr(1); ret_extremums[1] = extremums.getExtr(0); }
  }
  
  newTrend = isNewTrend();  // ���� ��������� ����� ���������� ��������� �� �������� �� ����� �����     
 }
 
 //��������� ����� �� ������������� ������ ���, ��� ��� �������� �� ������� ���������� �������� ��� �� � ������� ���� 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN   && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP; 
 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP   && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN; 
 
 // ���������� ������ ������ ������ ��� ��� ����� �� ������ �� ������ �� �������� �� ��������� ���� ��������
 if (newTrend == -1 && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  //PrintEvent(enumMoveType[bar], previous_move_type, 0, "newTrend = -1");
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else if (newTrend == 1 && enumMoveType[bar] != MOVE_TYPE_TREND_UP_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_UP)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  //PrintEvent(enumMoveType[bar], previous_move_type, 0, "newTrend = 1");
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else // ��������� ����� ���������� ������ � ������ ��� ����� (������ ������ ��� ��������� ��� ������ �� ������)
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   //PrintEvent(enumMoveType[bar], previous_move_type, 0, "MOVE_TYPE_UNKNOWN");
   previous_move_type = enumMoveType[bar];
   return (true);
  }
 }
 
 //���� ���������� "���������" ����� �� ��� ������������ �� ����
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN || enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionWrong(bar))
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, StringFormat("Corr ���������� ���� ���� first on trend (%.05f;%s)", firstOnTrend.price, TimeToString(firstOnTrend.time)));
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //������ ��������� ���� ���� � ����������� ���� ���� �������� ������ ���� �������� � ��� ���� ����� ������������ � ����������� ���� 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_UP || enumMoveType[bar-1] == MOVE_TYPE_TREND_UP_FORBIDEN) && // �������� �� ���������� ����
     (enumMoveType[bar]   == MOVE_TYPE_TREND_UP || enumMoveType[bar]   == MOVE_TYPE_TREND_UP_FORBIDEN) && // ������� ��������
     (previous_move_type  != MOVE_TYPE_FLAT)                                                              // ���������� �������� (����� ���� ���������� ��������� �������� ����)
      &&
     (LessDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))  // ���������� ��� ������ ������ ������
      &&
     ((now) || (buffer_Rates[0].high < buffer_Rates[1].high)))                                            // ��������� high ������ ��������������
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[AMOUNT_OF_PRICE-1].close, StringFormat("enumMoveType[bar-1] = %s;���� �������� ������ ���� ����������� �������� %f", MoveTypeToString(enumMoveType[bar-1]), buffer_Rates[AMOUNT_OF_PRICE-1].open));
  if (extremums.getExtr(0).direction > 0) 
   lastOnTrend = extremums.getExtr(0); 
  else 
   lastOnTrend = extremums.getExtr(1);
  
  previous_move_type = enumMoveType[bar];
  return (true);
 }
//������ ��������� ����� ���� � ����������� ���� ���� �������� ������ ���� �������� � ��� ���� ����� ������������ � ����������� ���� 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // �������� �� ���������� ����
     (enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN || enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // ������� ��������
     (previous_move_type != MOVE_TYPE_FLAT)                                                                   // ���������� �������� (����� ���� ���������� ��������� �������� ����)
      &&
     (GreatDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))     // ���������� ��� ������ ������ ������
      &&
     ((now) || (buffer_Rates[0].low > buffer_Rates[1].low)))                                                  // ��������� low ������ ��������������
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[AMOUNT_OF_PRICE-1].close, StringFormat("enumMoveType[bar-1] = %s;���� �������� ������ �������� ����������� ���� %f", MoveTypeToString(enumMoveType[bar-1]), buffer_Rates[AMOUNT_OF_PRICE-1].open));
  if (extremums.getExtr(0).direction < 0) 
   lastOnTrend = extremums.getExtr(0); 
  else 
   lastOnTrend = extremums.getExtr(1);
   
  previous_move_type = enumMoveType[bar];
  return(true);
 }
 
 //��������� �������� �� ����� ���� ��� ����������� ������� isCorrectionEnds
 //���� ��������� ���� ������ ���������� ��������� ��� �� ������� �� "�������" ���
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))                       
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, "isCorrectionEnds");
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //��������� �������� �� ����� ����� ��� ����������� ������� isCorrectionEnds
 //���� ��������� ���� ������ ���������� ��������� ��� �� ������� �� "�������" ���
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, "isCorrectionEnds");
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 // ������� ����� ������ � ������ ����������� ������ ������� ����� ������ � �������*��������� ������
 if (((previous_move_type == MOVE_TYPE_TREND_DOWN || previous_move_type == MOVE_TYPE_TREND_DOWN_FORBIDEN || previous_move_type == MOVE_TYPE_CORRECTION_DOWN) && isEndTrend() ==  1) || 
     ((previous_move_type == MOVE_TYPE_TREND_UP   || previous_move_type == MOVE_TYPE_TREND_UP_FORBIDEN   || previous_move_type == MOVE_TYPE_CORRECTION_UP  ) && isEndTrend() == -1))   
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  //PrintEvent(enumMoveType[bar], previous_move_type, buffer_Rates[0].close, "isEndTrend");
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 return (true);
}
 
//+----------------------------------------------------+
//| ������� �������� ������� �� ������� ����� �������� |
//+----------------------------------------------------+
ENUM_MOVE_TYPE CColoredTrend::GetMoveType(int i)
{
 if(i < 0 || i >= ArraySize(enumMoveType))
 {
  Alert(StringFormat("%s i = %d; period = %s; ArraySize = %d", MakeFunctionPrefix(__FUNCTION__), i, EnumToString((ENUM_TIMEFRAMES)_period), ArraySize(enumMoveType)));
 }
 return(enumMoveType[i]);
}

//+-------------------------------------------------+
//| ������� ��������� ������ ��� �� �������         |
//+-------------------------------------------------+
int CColoredTrend::FillTimeSeries(ENUM_TF tfType, int count, datetime start_time, MqlRates &array[])
{
 if(count > _depth) count = _depth;
//--- ������� �����������
 int copied = 0;
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
 
 copied = CopyRates(_symbol, period, start_time, count, array); // ������ ������ �� 0 �� count-1, ����� count ���������
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied < count)
 {
  //--- ������� ���-�� ������������ �������� ����������
  //calculated_values=BarsCalculated(symbol_handles[s]);
  //--- ������� ������ ���� ������ �������� ������� � ���������
  datetime firstdate_terminal=(datetime)SeriesInfoInteger(_symbol ,Period(), SERIES_TERMINAL_FIRSTDATE);
  //--- ������� ���������� ��������� ����� �� ��������� ����
  int available_bars=Bars(_symbol,Period(),firstdate_terminal,TimeCurrent());
  string comm = StringFormat("%s ��� ������� %s �������� %d ����� �� %d ������������� Rates. Period = %s. Error = %d | first date = %s, available = %d, start = %s, count = %d",
                             MakeFunctionPrefix(__FUNCTION__),
                             _symbol,
                             copied,
                             count,
                             EnumToString((ENUM_TIMEFRAMES)period),
                             GetLastError(),
                             TimeToString(firstdate_terminal, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                             available_bars,
                             TimeToString(start_time, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                             count
                            );
  //--- ������� ��������� � ����������� �� ������� ���� �������
  log_file.Write(LOG_DEBUG, comm);
 }
 ArraySetAsSeries(array, true);
 return(copied);
}

//+------------------------------------------------------------------------+
//| ������� ��������� ������� ������ �� ��������� � ����������� ������     |
//+------------------------------------------------------------------------+
bool CColoredTrend::isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, datetime start_time)
{
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  if(LessDoubles(price, lastOnTrend.price, _digits))  // ���� ���� ���� ���������� ���������� �� ������
  {
   //if(extremum_condition) log_file.Write(LOG_DEBUG, StringFormat("IS_CORRECTION_ENDS : GreatDouble price = %.05f > %.05f = lastOnTrend.price", price, lastOnTrend.price));
   return(true);
  }
  if(isLastBarHuge(start_time) > 0)                    // ��������� �������� ���� �� ������� ��. ������� ��� - ����� ��� �� ��������� ������ �������� ���� �� ��������� ���������� �������
  {
   //PrintFormat("%s IS_CORRECTION_ENDS : LAST BAR HUGE", EnumToString((ENUM_TIMEFRAMES)_period));
   return(true);
  }
 }
 else if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  if(GreatDoubles(price, lastOnTrend.price, _digits)) // ���� ���� ���� ���������� ���������� �� �����
  {
   //if(extremum_condition) PrintFormat("IS_CORRECTION_ENDS : GreatDouble price = %.05f > %.05f = lastOnTrend.price", price, lastOnTrend.price);
   return(true);
  }
  if(isLastBarHuge(start_time) < 0)                   // ��������� �������� ���� �� ������� ��. ������� ��� - ����� ��� �� ��������� ������ �������� ���� �� ��������� ���������� �������
  {
   //PrintFormat("%s IS_CORRECTION_ENDS : LAST BAR HUGE", EnumToString((ENUM_TIMEFRAMES)_period));
   return(true);
  }
 }
 else
  PrintFormat("%s %s �������� ��� ��������!", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period));
 
 return (false);
}

//+----------------------------------------------------------+
//| ������� ��������� ������� ������ �� ��������� �� ����.   |
//+----------------------------------------------------------+
bool CColoredTrend::isCorrectionWrong(int i)
{
 //PrintFormat("%s: price = %.05f @ firstOnTrend = %.05f [%d; %s]", __FUNCTION__,price, firstOnTrend.price, firstOnTrend.direction, TimeToString(firstOnTrend.time));
 if (enumMoveType[i] == MOVE_TYPE_CORRECTION_UP)
 {
  if(buffer_Rates[0].close > firstOnTrend.price && firstOnTrend.direction == -1) 
  {
   return(true);
   //PrintFormat("CORR_UP : %.05f > %.05f", price, firstOnTrend.price);
  }
 }
 if (enumMoveType[i] == MOVE_TYPE_CORRECTION_DOWN)
 {
  if(buffer_Rates[0].close < firstOnTrend.price && firstOnTrend.direction == 1) 
  {
   return(true);
   //PrintFormat("CORR_DOWN : %.05f < %.05f", price, firstOnTrend.price);
  }
 }
 
 return(false);
}

//+----------------------------------------------------------------+
//| ������� ���������� �������� �� ��� "�������" � ��� ����������� |
//+----------------------------------------------------------------+
int CColoredTrend::isLastBarHuge(datetime start_time)
{
 double sum = 0;
 MqlRates rates[];
 datetime buffer_date[];
 CopyTime(_symbol, GetBottomTimeframe(_period),  start_time-PeriodSeconds(GetBottomTimeframe(_period)), AMOUNT_BARS_FOR_HUGE, buffer_date);
 if(FillTimeSeries(BOTTOM_TF, AMOUNT_BARS_FOR_HUGE, start_time-PeriodSeconds(GetBottomTimeframe(_period)), rates) < AMOUNT_BARS_FOR_HUGE) return(0);

 for(int i = 0; i < AMOUNT_BARS_FOR_HUGE - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / AMOUNT_BARS_FOR_HUGE;
 double lastBar = MathAbs(rates[0].open - rates[0].close);
    
 if(GreatDoubles(lastBar, avgBar*FACTOR_OF_SUPERIORITY))
 {
  if(GreatDoubles(rates[0].open, rates[0].close, _digits))
   return(1);
  if(LessDoubles(rates[0].open, rates[0].close, _digits))
   return(-1);
 }
 return(0);
}

//+----------------------------------------------------+
//| ������� ���������� ������ ������                   |
//+----------------------------------------------------+
int CColoredTrend::isNewTrend()
{
 if (extremums.getExtr(1).direction < 0 && 
     LessDoubles((extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend,
                 (extremums.getExtr(0).price - extremums.getExtr(1).price), 
                 _digits))
 {
  //PrintFormat("IS_NEW_TREND %s MAX: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num2-num1)*k = %.05f < (num0-num1) = %.05f, _difToTrend = %.02f", EnumToString((ENUM_TIMEFRAMES)_period), extremums.getExtr(0).price, extremums.getExtr(1).price, extremums.getExtr(2).price, (extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend, (extremums.getExtr(0).price - extremums.getExtr(1).price), _difToTrend);
  return(1);
 }
 if (extremums.getExtr(1).direction > 0 && 
     LessDoubles((extremums.getExtr(1).price - extremums.getExtr(2).price)*_difToTrend, 
                 (extremums.getExtr(1).price - extremums.getExtr(0).price), 
                 _digits))
 {
  //PrintFormat("IS_NEW_TREND %s MIN: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num1-num2)*k = %.05f < (num1-num0) = %.05f, _difToTrend = %.02f", EnumToString((ENUM_TIMEFRAMES)_period), extremums.getExtr(0).price, extremums.getExtr(1).price, extremums.getExtr(2).price, (extremums.getExtr(1).price - extremums.getExtr(2).price)*_difToTrend, (extremums.getExtr(1).price - extremums.getExtr(0).price), _difToTrend);
  return(-1);
 }
 return(0);
}

//+----------------------------------------------------------+
//| ������� ���������� ����� ������/��������� (������ �����) |
//+----------------------------------------------------------+
int CColoredTrend::isEndTrend()
{
 if (extremums.getExtr(1).direction < 0 && GreatDoubles((extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend ,(extremums.getExtr(0).price - extremums.getExtr(1).price), _digits))
 {
  //PrintFormat("IS_END_TREND %s MAX: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num2-num1)*k = %.05f > (num0-num1) = %.05f, _difToTrend = %.02f", EnumToString((ENUM_TIMEFRAMES)_period), extremums.getExtr(0).price, extremums.getExtr(1).price, extremums.getExtr(2).price, (extremums.getExtr(2).price - extremums.getExtr(1).price)*_difToTrend, (extremums.getExtr(0).price - extremums.getExtr(1).price), _difToTrend);
  return(1);
 }
 if (extremums.getExtr(1).direction > 0 && GreatDoubles((extremums.getExtr(1).price - extremums.getExtr(2).price)*_difToTrend ,(extremums.getExtr(1).price - extremums.getExtr(0).price), _digits))
 {
  //PrintFormat("IS_END_TREND %s MIN: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num1-num2)*k = %.05f > (num1-num0) = %.05f, _difToTrend = %.02f", EnumToString((ENUM_TIMEFRAMES)_period), extremums.getExtr(0).price, extremums.getExtr(1).price, extremums.getExtr(2).price, (extremums.getExtr(1).price - extremums.getExtr(2).price)*_difToTrend, (extremums.getExtr(1).price - extremums.getExtr(0).price), _difToTrend);
  return(-1);
 }
 return(0);
}

//+-------------------------------------------------------------+
//| ������� ��������� ������ ����� �������� ��������� ��������� |
//+-------------------------------------------------------------+
void CColoredTrend::Zeros()
{
  SExtremum zero = {0, 0};
 
  for(int i = 0; i < ArraySize(enumMoveType); i++)
  {
   enumMoveType[i] = MOVE_TYPE_UNKNOWN;
  }
}

void CColoredTrend::SetDiffToTrend()
{
 switch(_period)
 {
   case(PERIOD_M5):
      _difToTrend = 1.5;
      break;
   case(PERIOD_M15):
      _difToTrend = 1.3;
      break;
   case(PERIOD_H1):
      _difToTrend = 1.3;
      break;
   case(PERIOD_H4):
      _difToTrend = 1.3;
      break;
   case(PERIOD_D1):
      _difToTrend = 0.8;
      break;
   case(PERIOD_W1):
      _difToTrend = 0.8;
      break;
   case(PERIOD_MN1):
      _difToTrend = 0.8;
      break;
   default:
      _difToTrend = DEFAULT_DIFF_TO_TREND;
      break;
 }
}
 
void CColoredTrend::PrintExtr(void)
{
 extremums.PrintExtremums();
}

void CColoredTrend::PrintEvent(ENUM_MOVE_TYPE mt, ENUM_MOVE_TYPE mt_old, double price, string opinion)
{
 PrintFormat("%s ��������� �������� %s. ���������� �������� %s. ���� - %.05f. ��������� %s", EnumToString((ENUM_TIMEFRAMES)_period), MoveTypeToString(mt), MoveTypeToString(mt_old), price, opinion);
 extremums.PrintExtremums();
}