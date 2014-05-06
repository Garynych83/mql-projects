//+------------------------------------------------------------------+
//|                                                 ColoredTrend.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//#include <CLog.mqh>
#include <CompareDoubles.mqh>
#include "ColoredTrendUtilities.mqh"
#include <StringUtilities.mqh>

#define AMOUNT_OF_PRICE 2
#define AMOUNT_BARS_FOR_HUGE 100

#define ATR_PERIOD 30
#define ATR_TIMEFRAME PERIOD_H4

#define FACTOR_OF_SUPERIORITY 2
//CLog log_output(OUT_COMMENT, LOG_NONE, 50, "PBI", 30);

//+------------------------------------------------------------------+
//| ��������������� ����� ��� ���������� ColoredTrend                |
//+------------------------------------------------------------------+
class CColoredTrend
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  ENUM_MOVE_TYPE enumMoveType[];
  ENUM_MOVE_TYPE previous_move_type;
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
  datetime time_buffer[];
  
  int FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[]);
  int FillTimeSeries(ENUM_TF tfType, int count, datetime start_pos, MqlRates &array[]);
  int FillATRBuf(int count, int start_pos);
  
  bool isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, int start_pos);
  int isLastBarHuge(int start_pos);
  int isNewTrend();
  int isEndTrend();
  
public:
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR, double dif);
  SExtremum isExtremum(int start_index);
  bool FindExtremumInHistory(int depth);
  bool CountMoveType(int bar, int start_pos, SExtremum &extremum, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);
  ENUM_MOVE_TYPE GetMoveType(int i);
  int TrendDirection();
  void Zeros();
};

//+-----------------------------------------+
//| �����������                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int depth, double percentage_ATR, double dif) : 
                   _symbol(symbol),
                   _period(period),
                   _depth(depth),
                   _percentage_ATR(percentage_ATR),
                   previous_move_type(MOVE_TYPE_UNKNOWN),
                   difToTrend(dif)
{
 num0.direction = 0;
 num1.direction = 0;
 num2.direction = 0;
 num0.price = -1;
 num1.price = -1;
 num2.price = -1;
 
 MqlRates buffer[1];
 CopyRates(_symbol, _period, _depth, 1, buffer);
 CopyTime(_symbol, _period, _depth, 1, time_buffer);
 _startDayPrice = buffer[0].close;
 ATR_handle = iATR(_symbol, ATR_TIMEFRAME, ATR_PERIOD);
 digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 ArrayResize(enumMoveType, depth);
 Zeros();
 //log_output.Write(LOG_DEBUG, StringFormat("%s ����������� ������ CColoredTrend", EnumToString(_period)));
}

//+--------------------------------------+
//| ������� ��������� ��� �������� ����� |
//+--------------------------------------+
bool CColoredTrend::CountMoveType(int bar, int start_pos, SExtremum &extremum, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 if(bar == 0) //�� "�������" ���� ������ ����������� �� ����� � ������ ������� ������� ��� �� ������ �������� � ����������
  return (true); 

 if(bar == ArraySize(enumMoveType))  // ������� ������ ��� ������ �����������
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  
 if(FillTimeSeries(CURRENT_TF, AMOUNT_OF_PRICE, start_pos, buffer_Rates) < 0) // ������� ������ ������������ �������
  return (false); 
 if(FillATRBuf(1, GetNumberOfTopBarsInCurrentBars(_period, ATR_TIMEFRAME, start_pos)) < 0) // �������� ������ ������� ���������� ATR
  return (false);  
 
 CopyTime(_symbol, _period, start_pos, 1, time_buffer);  
 enumMoveType[bar] = previous_move_type;
 difToNewExtremum = buffer_ATR[0] * _percentage_ATR;
 SExtremum current_bar = {0, -1};
 
 int newTrend = 0;  
 current_bar = isExtremum(start_pos); 
 if (current_bar.direction != 0)
 {
  extremum = current_bar;
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
  newTrend = isNewTrend();       
 }
 
 // �������� �� ������� 3� �����������. ����� ���� ��� ���� �����������
 if (num2.direction == 0 && num2.price == -1) //���������� (num0 > 0 && num1 > 0 && num2 > 0) �.�. num2 �� ����������� ���� �� ����������� num0 � num1
 {
  return (true); 
 } 
  
 if (newTrend == -1 && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN)
 {// ���� ������� ����� ��������� (0) � ������������� (1) ����������� � "difToTrend" ��� ������ ������ ��������
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  previous_move_type = enumMoveType[bar];
  //PrintFormat("������ ������ TREND DOWN");
  return (true);
 }
 else if (newTrend == 1 && enumMoveType[bar] != MOVE_TYPE_TREND_UP_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_UP) // ���� ������� �������� ���� ���������� ���������� 
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  previous_move_type = enumMoveType[bar];
  //PrintFormat("������ ������ TREND UP");
  return (true);
 }
 else 
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   previous_move_type = enumMoveType[bar];
   return (true);
  }
 }
 
 //������ ��������� ���� ���� ���� �������� ������ ���� ����������� �������� 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP || enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN)
 {
  if(LessDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;
   //PrintFormat("CORRECTION DOWN: ���� �������� ������ ���� ��������");
   if (num0.direction > 0) 
    lastOnTrend = num0; 
   else 
    lastOnTrend = num1;
  
   previous_move_type = enumMoveType[bar];
  }
  return (true);
 }
 //������ ��������� ����� ���� ���� �������� ������ �������� ����������� ����
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
 {
  if(GreatDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, digits))
  {
   enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
   //PrintFormat("CORRECTION UP: ���� �������� ������ �������� ����������� ����");
   if (num0.direction < 0) 
    lastOnTrend = num0; 
   else 
    lastOnTrend = num1;
    
   previous_move_type = enumMoveType[bar];
  }
  return(true);
 }
 
 //��������� �������� �� ����� �����/���� ��� ����������� ������� isCorrectionEnds
 //���� ��������� ���� ������/������ ���������� ��������� ��� �� ������� �� "�������" ���
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[AMOUNT_OF_PRICE-1].close, enumMoveType[bar], start_pos))                       
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  //PrintFormat("����� �����!!!CORRECTIONEND bar = %d", bar);
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[AMOUNT_OF_PRICE-1].close, enumMoveType[bar], start_pos))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  //PrintFormat("����� ������!!!CORRECTIONEND bar = %d", bar);
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 
 if (((previous_move_type == MOVE_TYPE_TREND_DOWN || previous_move_type == MOVE_TYPE_CORRECTION_DOWN) && isEndTrend() ==  1) || 
     ((previous_move_type == MOVE_TYPE_TREND_UP   || previous_move_type == MOVE_TYPE_CORRECTION_UP  ) && isEndTrend() == -1))   
 {
  //PrintFormat("isEndTrend = %d: FLAT", isEndTrend());
  enumMoveType[bar] = MOVE_TYPE_FLAT;
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
//+--------------------------------------------------------------------+
//| ������� ���������� ����������� � �������� ���������� � ������ �����|
//+--------------------------------------------------------------------+
SExtremum CColoredTrend::isExtremum(int start_index)
{
 SExtremum result = {0,0};
 MqlRates buffer[1];
 CopyRates(_symbol, _period, start_index, 1, buffer);
 double high = 0, low = 0;
 
 if (start_index == 0)
 {
  high = buffer[0].close;
  low = buffer[0].close;
 }
 else
 {
  high = buffer[0].high;
  low = buffer[0].low;
 }
 
 if (((num0.direction == 0) && (GreatDoubles(high, _startDayPrice + 2*difToNewExtremum, digits))) // ���� ����������� ��� ��� � ���� 2 ���� �� ��������� ����
   || (num0.direction > 0 && (GreatDoubles(high, num0.price, digits)))
   || (num0.direction < 0 && (GreatDoubles(high, num0.price + difToNewExtremum, digits))))
 {
  //PrintFormat("%s ����� ���������! high = %.05f > %.05f(num0) + %.05f(difToNewExtremum)", MakeFunctionPrefix(__FUNCTION__), high, num0.price, difToNewExtremum);
  result.direction = 1;
  result.price = high;
 }
 
 if (((num0.direction == 0) && (LessDoubles(low, _startDayPrice - 2*difToNewExtremum, digits))) // ���� ����������� ��� ��� � ���� 2 ���� �� ��������� ����
   || (num0.direction < 0 && (LessDoubles(low, num0.price, digits)))
   || (num0.direction > 0 && (LessDoubles(low, num0.price - difToNewExtremum, digits))))
 {
  //PrintFormat("%s ����� ���������! low = %.05f < %.05f(num0) - %.05f(difToNewExtremum)", MakeFunctionPrefix(__FUNCTION__), low, num0.price, difToNewExtremum);
  result.direction = -1;
  result.price = low;
 }
 
 return(result);
}


//+-------------------------------------------------+
//| ������� ��������� ������ ��� �� �������         |
//+-------------------------------------------------+
int CColoredTrend::FillTimeSeries(ENUM_TF tfType, int count, int start_pos, MqlRates &array[])
{
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
 
 copied = CopyRates(_symbol, period, start_pos, count, array); // ������ ������ �� 0 �� count-1, ����� count ���������
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied < count)
 {
  string comm = StringFormat("%s ��� ������� %s �������� %d ����� �� %d ������������� Rates. Period = %s. Error = %d | start = %d count = %d",
                             MakeFunctionPrefix(__FUNCTION__),
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

//+-------------------------------------------------+
//| ������� ��������� ������ ��� �� �������         |
//+-------------------------------------------------+
int CColoredTrend::FillTimeSeries(ENUM_TF tfType, int count, datetime start_pos, MqlRates &array[])
{
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
 
 copied = CopyRates(_symbol, period, start_pos, count, array); // ������ ������ �� 0 �� count-1, ����� count ���������
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied < count)
 {
  string comm = StringFormat("%s ��� ������� %s �������� %d ����� �� %d ������������� Rates. Period = %s. Error = %d | start = %d count = %d",
                             MakeFunctionPrefix(__FUNCTION__),
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
 
//--- ������� �����������
 int copied = CopyBuffer(ATR_handle, 0, start_pos, count, buffer_ATR);

//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied < count)
 {
  string comm = StringFormat("%s ��� ������� %s �������� %d ����� �� %d ������������� ATR. Period = %s.  Error = %d | start = %d count = %d bars_calculated = %d",
                             MakeFunctionPrefix(__FUNCTION__),
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
//| ������� ��������� ������� ������ �� ���������      |
//+----------------------------------------------------+
bool CColoredTrend::isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, int start_pos)
{
 bool extremum_condition = false, 
      bottomTF_condition = false,
      newTrend_condition = false;
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  extremum_condition = LessDoubles(price, lastOnTrend.price, digits);
  if(isLastBarHuge(start_pos) > 0) bottomTF_condition = true;
  if(num2.price == lastOnTrend.price && isNewTrend() == -1) 
  {
   //PrintFormat("newTrend : ��������� ����� ������������� ������� ����");
   newTrend_condition = true;
  }
 }
 if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  extremum_condition = GreatDoubles(price, lastOnTrend.price, digits);
  //if(extremum_condition) PrintFormat("IS_CORRECTION_ENDS : GreatDouble price = %.05f > %.05f = lastOnTrend.price", price, lastOnTrend.price);
  if(isLastBarHuge(start_pos) < 0) 
  {
   //PrintFormat("IS_CORRECTION_ENDS : LAST BAR HUGE");
   bottomTF_condition = true;
  }
  if(num2.price == lastOnTrend.price && isNewTrend() == 1) 
  {
   //PrintFormat("newTrend : ��������� ���� ������������� ������� �����"); 
   newTrend_condition = true;
  }
 }
 
 return ((extremum_condition) || (bottomTF_condition) || (newTrend_condition));
}

//+----------------------------------------------------------------+
//| ������� ���������� �������� �� ��� "�������" � ��� ����������� |
//+----------------------------------------------------------------+
int CColoredTrend::isLastBarHuge(int start_pos)
{
 double sum = 0;
 MqlRates rates[];
 datetime buffer_date[1];
 CopyTime(_symbol, _period, start_pos, 1, buffer_date);
 FillTimeSeries(BOTTOM_TF, AMOUNT_BARS_FOR_HUGE, buffer_date[0]-PeriodSeconds(GetBottomTimeframe(_period)), rates);
 //PrintFormat("������ %s; ���� �������� � %s", TimeToString(buffer_date[0]), TimeToString(buffer_date[0]-PeriodSeconds(GetBottomTimeframe(_period))));
 int size = ArraySize(rates);
 for(int i = 0; i < size - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / size;
 double lastBar = MathAbs(rates[size-1].open - rates[size-1].close);
    
 if(GreatDoubles(lastBar, avgBar*FACTOR_OF_SUPERIORITY))
 {
  if(GreatDoubles(rates[size-1].open, rates[size-1].close, digits))
  {
   //PrintFormat("� ������������ ���! -1 %s : %.05f %.05f; Open = %.05f; close = %.05f", TimeToString(buffer_date[0]), lastBar, avgBar*FACTOR_OF_SUPERIORITY, rates[size-1].open, rates[size-1].close);
   return(1);
  }
  if(LessDoubles(rates[size-1].open, rates[size-1].close, digits))
  {
   //PrintFormat("� ������������ ���! -1 %s : %.05f %.05f; Open = %.05f; close = %.05f", TimeToString(buffer_date[0]), lastBar, avgBar*FACTOR_OF_SUPERIORITY, rates[size-1].open, rates[size-1].close);
   return(-1);
  }
 }
 //PrintFormat("� ������������ ���! 0 %s : %.05f %.05f; Open = %.05f; close = %.05f", TimeToString(buffer_date[0]), lastBar, avgBar*FACTOR_OF_SUPERIORITY, rates[size-1].open, rates[size-1].close);
 return(0);
}

//+----------------------------------------------------+
//| ������� ���������� ������ ������                   |
//+----------------------------------------------------+
int CColoredTrend::isNewTrend()
{
 if (num1.direction < 0 && LessDoubles((num2.price - num1.price)*difToTrend ,(num0.price - num1.price), digits))
 {
  //PrintFormat("ISNEWTREND MAX: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num2-num1)*k = %.05f < (num0-num1) = %.05f, difToTrend = %.02f", num0.price, num1.price, num2.price, (num2.price - num1.price)*difToTrend, (num0.price - num1.price), difToTrend);
  return(1);
 }
 if (num1.direction > 0 && LessDoubles((num1.price - num2.price)*difToTrend ,(num1.price - num0.price), digits))
 {
  //PrintFormat("ISNEWTREND MIN: num0 = %.05f, num1 = %.05f, num2 = %.05f, (num1-num2)*k = %.05f < (num1-num0) = %.05f, difToTrend = %.02f", num0.price, num1.price, num2.price, (num1.price - num2.price)*difToTrend, (num1.price - num0.price), difToTrend);
  return(-1);
 }
 return(0);
}

//+----------------------------------------------------------+
//| ������� ���������� ����� ������/��������� (������ �����) |
//+----------------------------------------------------------+
int CColoredTrend::isEndTrend()
{
 if (num1.direction < 0 && GreatDoubles((num2.price - num1.price)*difToTrend ,(num0.price - num1.price), digits))
  return(1);
 if (num1.direction > 0 && GreatDoubles((num1.price - num2.price)*difToTrend ,(num1.price - num0.price), digits))
  return(-1);
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


int GetNumberOfTopBarsInCurrentBars(ENUM_TIMEFRAMES timeframe_curr, ENUM_TIMEFRAMES timeframe_top, int current_bars)
{
  return ((current_bars*PeriodSeconds(timeframe_curr))/PeriodSeconds(timeframe_top));
}