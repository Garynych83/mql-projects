//+------------------------------------------------------------------+
//|                                                CCalcExtremums.mqh |
//|                        Copyright 2014, Dmitry Onodera            |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""
#property version   "1.01"
// ����� ��� ���������� �����������

// ����������� ����������� ���������
#include <CompareDoubles.mqh> // ��� ��������� �������������� �����
#include "SExtremum.mqh"      // ��������� �����������
#include <StringUtilities.mqh>
#include <CLog.mqh>           // ��� ����
#include <DrawExtremums\CExtremum.mqh>


#define DEFAULT_PERCENTAGE_ATR 1.0   // �� ��������� ����� ��������� ���������� ����� ������� ������ �������� ����

// ������������ ��� ���� ���������� ����������
enum ENUM_CAME_EXTR
 {
  CAME_HIGH = 0,
  CAME_LOW = 1,
  CAME_BOTH = 2,
  CAME_NOTHING = 3
 };

// ����� ��� ���������� �������� �����������
class CCalcExtremums 
  {
   protected:
    string _symbol;             // ������
    ENUM_TIMEFRAMES _tf_period; // ������
    int    _handle_ATR;         // ����� ATR
    double _averageATR;         // ������� �������� ����
    double _percentage_ATR;     // ���������� ���������� �� �� �� ������� ��� �������� ���� ������ ��������� ������� ��� ��� �� �������� ����� ���������  
    
   public:
    CCalcExtremums(string symbol, ENUM_TIMEFRAMES period, int handle_atr);  // ����������� ������
    // �������� ������ ������
    ENUM_CAME_EXTR isExtremum(SExtremum &extrHigh,SExtremum &extrLow, datetime start_pos_time = __DATETIME__,  bool now = true);  // ���� �� ��������� �� ������ ����   
    double AverageBar (datetime start_pos); // ���������� ������� ������ ����   
  };
  
// ����������� ������� ������ ��������� �����������

// ����������� ������
CCalcExtremums::CCalcExtremums(string symbol, ENUM_TIMEFRAMES period, int handle_atr)
 {
  // ��������� ���� ������
  _symbol = symbol;
  _tf_period = period;
  _handle_ATR = handle_atr;
  // �������� ���������� � ����������� �� �� 
  switch(_tf_period)
  {
   case(PERIOD_M1):
      _percentage_ATR = 3.0;
      break;
   case(PERIOD_M5):
      _percentage_ATR = 3.0;
      break;
   case(PERIOD_M15):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_H1):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_H4):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_D1):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_W1):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_MN1):
      _percentage_ATR = 2.2;
      break;
   default:
      _percentage_ATR = DEFAULT_PERCENTAGE_ATR;
      break;
  }  
  // ���������� �������� �������� ����
  _averageATR = AverageBar(TimeCurrent());
 }
 
// ����� ���������� ���������� �� ������� ����
ENUM_CAME_EXTR CCalcExtremums::isExtremum(SExtremum &extrHigh,SExtremum &extrLow,datetime start_pos_time=__DATETIME__,bool now=true)
 {
 double high = 0, low = 0;                     // ��������� ���������� � ������� ����� �������� ���� ��� ������� max � min ��������������
 double averageBarNow;                         // ��� �������� �������� ������� ����
 double difToNewExtremum;                      // ��� �������� ������������ ���������� ����� ������������
 datetime extrHighTime = 0;                    // ����� ������� �������� ���������� 
 datetime extrLowTime = 0;                     // ����� ������� ������� ����������
 MqlRates bufferRates[2];                      // ���������
 ENUM_CAME_EXTR came_extr = CAME_NOTHING;      // ��� ���������� ���������� (������������ ��������)
 // �������� ����������� ��� ���� 
 if(CopyRates(_symbol, _tf_period, start_pos_time, 2, bufferRates) < 2)
  {
   log_file.Write(LOG_CRITICAL, StringFormat("%s �� ������� ����������� ���������. symbol = %s, Period = %s, time = %s"
                                            ,MakeFunctionPrefix(__FUNCTION__), _symbol, PeriodToString(_tf_period), TimeToString(start_pos_time)));
   return(came_extr); 
  }
 // ��������� ������� ������ ����
 averageBarNow = AverageBar(start_pos_time);
 // ���� ������� ��������� ������� �������� �
 if (averageBarNow > 0) _averageATR = averageBarNow; 
 // ��������� ����������� ���������� ����� ������������
 difToNewExtremum = _averageATR * _percentage_ATR;  
 
 if (extrHigh.time > extrLow.time && bufferRates[1].time < extrHigh.time && !now) return (came_extr); 
 if (extrHigh.time < extrLow.time && bufferRates[1].time < extrLow.time && !now) return (came_extr); 
 
 if (now) // �� ����� ����� ���� ���� close �������� ��� ��� �������� �� low �� high
 {        // ������������ ���� �� ������ ���� ���� ������� ��������� �� �� ����� ��������� ����� close ����� max  � �������� � low
  high = bufferRates[1].close;
  low = bufferRates[1].close;
 }
 else    // �� ����� ������ �� ������� �� ������� �� ��� ���� ��� ������������� ��� ����� ����� ������ ��� �������� � �������
 {
  high = bufferRates[1].high;
  low = bufferRates[1].low;
 }
 
 if ( (extrHigh.direction == 0  && extrLow.direction == 0)                         // ���� ����������� ��� ��� �� ������� ��� ������ ���������
   || ((extrHigh.time > extrLow.time) && (GreatDoubles(high, extrHigh.price) ))    // ���� ��������� ��������� - High, � ���� ������� ��������� � �� �� ������� 
   || ((extrHigh.time < extrLow.time) && (GreatDoubles(high,extrLow.price + difToNewExtremum) && GreatDoubles(high,bufferRates[0].high) )  )  ) // ���� ��������� ��������� - Low, � ���� ������ �� ���������� �� ���. ���������� � �������� �������  
 {
  // ��������� ����� ������� �������� ����������
  if (now) // ���� ���������� ����������� � �������� �������
   extrHighTime = TimeCurrent();
  else  // ���� ���������� ����������� �� �������
   extrHighTime = bufferRates[1].time;
  came_extr = CAME_HIGH;  // ���� ������ ������� ���������   
 }
 
 if ( ( extrLow.direction == 0 && extrHigh.direction == 0)                      // ���� ����������� ��� ��� �� ������� ��� ������ ���������
   || ((extrLow.time > extrHigh.time) && (LessDoubles(low,extrLow.price)))    // ���� ��������� ��������� - Low, � ���� ������� ��������� � �� �� �������
   || ((extrLow.time < extrHigh.time) && (LessDoubles(low,extrHigh.price - difToNewExtremum) && LessDoubles(low,bufferRates[0].low) ) ) )  // ���� ��������� ��������� - High, � ���� ������ �� ���������� �� ���. ���������� � �������� �������
 {
  // ���� �� ���� ���� ������ ������� ���������
  if (extrHighTime > 0)
   {
    // ���� close ���� open, �� �������, ��� ������� ��������� ������ ������ �������
    if(bufferRates[1].close <= bufferRates[1].open) 
     {
      extrLowTime = bufferRates[1].time + datetime(100);
     }
    else // ����� ��������, ��� ������ ������ ������ ��������
     {
      extrHighTime = bufferRates[1].time + datetime(100);
      extrLowTime  = bufferRates[1].time;
     }
    came_extr = CAME_BOTH;   // ���� ������ ��� ����������     
   }
  else // ����� ������ ��������� ����� ������� ������� ����������
   {
    if (now) // ���� ���������� ����������� � �������� �������
     extrLowTime = TimeCurrent();
    else // ���� ���������� ����������� �� �������
     extrLowTime = bufferRates[1].time;
    came_extr = CAME_LOW; // ���� ������ ������ ���������     
   }
 }
 
 // ��������� ���� �������� �����������
 
 // ���� ������ ����� ������� ���������
 if (extrHighTime > 0)
  {
   // ��������� ���� ����������
   extrHigh.direction = 1;
   extrHigh.price = high;
   extrHigh.time = extrHighTime;
  }
 // ���� ������ ����� ������ ���������
 if (extrLowTime > 0)
  {
   // ��������� ���� ����������
   extrLow.direction = -1;
   extrLow.price = low;
   extrLow.time = extrLowTime;
  }  

   return (came_extr);
 }
 
// ����� ���������� �������� ������� ����
double CCalcExtremums::AverageBar(datetime start_pos)
 {
  int copied = 0;
  double buffer_atr[1];
  if (_handle_ATR == INVALID_HANDLE)
   {
    log_file.Write(LOG_CRITICAL, StringFormat("%s ERROR %d. INVALID HANDLE ATR %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), EnumToString((ENUM_TIMEFRAMES)_tf_period)));
    return (-1);
   }
  copied = CopyBuffer(_handle_ATR, 0, start_pos, 1, buffer_atr);
  if (copied < 1) 
   {
    log_file.Write(LOG_CRITICAL, StringFormat("%s ERROR %d. Period = %s. copied = %d, calculated = %d, start time = %s"
                                             , MakeFunctionPrefix(__FUNCTION__)
                                             , GetLastError()
                                             , EnumToString((ENUM_TIMEFRAMES)_tf_period), copied
                                             , BarsCalculated(_handle_ATR), TimeToString(start_pos)));
    return(-1);
   }
  return (buffer_atr[0]);
 }