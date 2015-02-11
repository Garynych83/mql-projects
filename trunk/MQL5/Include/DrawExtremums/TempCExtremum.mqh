//+------------------------------------------------------------------+
//|                                                CExtremum.mqh     |
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

#define DEFAULT_PERCENTAGE_ATR 1.0   // �� ��������� ����� ��������� ���������� ����� ������� ������ �������� ����

// ����� ��� ���������� �������� �����������
class CExtremum
  {
   protected:
    string _symbol;             // ������
    int    _digits;             // ���������� ������ ����� ������� ��� ��������� �������������� �����
    ENUM_TIMEFRAMES _tf_period; // ������
    int    _handle_ATR;         // ����� ATR
    double _averageATR;         // ������� �������� ����
    double _percentage_ATR;     // ���������� ���������� �� �� �� ������� ��� �������� ���� ������ ��������� ������� ��� ��� �� �������� ����� ���������  
   public:
    CExtremum(string symbol, ENUM_TIMEFRAMES period, int handle_atr);  // ����������� ������
   // �������� ������ ������
   bool isExtremum(SExtremum &extrHigh,SExtremum &extrLow, datetime start_pos_time = __DATETIME__,  bool now = true);  // ���� �� ��������� �� ������ ����   
   double AverageBar (datetime start_pos); // ���������� ������� ������ ����   
  };
  
// ����������� ������� ������ ��������� �����������


// ����������� ������
CExtremum::CExtremum(string symbol, ENUM_TIMEFRAMES period, int handle_atr)
 {
  // ��������� ���� ������
  _symbol = symbol;
  _tf_period = period;
  _handle_ATR = handle_atr;
  _digits = 8;
  // ��������� ������� �������� ATR �� 
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
bool CExtremum::isExtremum(SExtremum &extrHigh,SExtremum &extrLow,datetime start_pos_time=__DATETIME__,bool now=true)
 {
 double high = 0, low = 0;       // ��������� ���������� � ������� ����� �������� ���� ��� ������� max � min ��������������
 double averageBarNow;           // ��� �������� �������� ������� ����
 double difToNewExtremum;        // ��� �������� ������������ ���������� ����� ������������
 datetime extrHighTime = 0;      // ����� ������� �������� ���������� 
 datetime extrLowTime = 0;       // ����� ������� ������� ����������
 MqlRates bufferRates[1];
 //Comment("����� = ",TimeToString(start_pos_time) );
 if(CopyRates(_symbol, _tf_period, start_pos_time, 1, bufferRates) < 1)
 {
  Print("������ CExtremum::isExtremum. �� ������� ����������� ���������");
  return(false); 
 }
 // ��������� ������� ������ ����
 averageBarNow = AverageBar(start_pos_time);
 // ���� ������� ��������� ������� �������� �
 if (averageBarNow > 0)
  _averageATR = averageBarNow; 
 // ��������� ����������� ���������� ����� ������������
 difToNewExtremum = _averageATR * _percentage_ATR;  
 
 if (extrHigh.time > extrLow.time && bufferRates[0].time < extrHigh.time && !now) return (false); 
 if (extrHigh.time < extrLow.time && bufferRates[0].time < extrLow.time && !now) return (false); 
 
 if (now) // �� ����� ����� ���� ���� close �������� ��� ��� �������� �� low �� high
 {        // ������������ ���� �� ������ ���� ���� ������� ��������� �� �� ����� ��������� ����� close ����� max  � �������� � low
  high = bufferRates[0].close;
  low  = bufferRates[0].close;
 }
 else    // �� ����� ������ �� ������� �� ������� �� ��� ���� ��� ������������� ��� ����� ����� ������ ��� �������� � �������
 {
  high = bufferRates[0].high;
  low = bufferRates[0].low;
 }
 
 if ( (extrHigh.direction == 0  && extrLow.direction == 0)                                                  // ���� ����������� ��� ��� �� ������� ��� ������ ���������
   || ((extrHigh.time > extrLow.time) && (GreatDoubles(high, extrHigh.price,_digits) ) )                    // ���� ��������� ��������� - High, � ���� ������� ��������� � �� �� ������� 
   || ((extrHigh.time < extrLow.time) && (GreatDoubles(high,extrLow.price + difToNewExtremum,_digits) ) ) ) // ���� ��������� ��������� - Low, � ���� ������ �� ���������� �� ���. ���������� � �������� �������   
 {
  // ��������� ����� ������� �������� ����������
  if (now) // ���� ���������� ����������� � �������� �������
   extrHighTime = TimeCurrent();
  else  // ���� ���������� ����������� �� �������
   extrHighTime = bufferRates[0].time;
 }
 
 if ( ( extrLow.direction == 0 && extrHigh.direction == 0)                                                  // ���� ����������� ��� ��� �� ������� ��� ������ ���������
   || ((extrLow.time > extrHigh.time) && (LessDoubles(low,extrLow.price,_digits) ) )                        // ���� ��������� ��������� - Low, � ���� ������� ��������� � �� �� �������
   || ((extrLow.time < extrHigh.time) && (LessDoubles(low,extrHigh.price - difToNewExtremum,_digits) ) ) )  // ���� ��������� ��������� - High, � ���� ������ �� ���������� �� ���. ���������� � �������� �������
 {
  // ���� �� ���� ���� ������ ������� ���������
  if (extrHighTime > 0)
   {
    // ���� close ���� open, �� �������, ��� ������� ��������� ������ ������ �������
    if(bufferRates[0].close <= bufferRates[0].open) 
     {
      extrLowTime = bufferRates[0].time + datetime(100);
     }
    else // ����� ��������, ��� ������ ������ ������ ��������
     {
      extrHighTime = bufferRates[0].time + datetime(100);
      extrLowTime  = bufferRates[0].time;
     }
   }
  else // ����� ������ ��������� ����� ������� ������� ����������
   {
    if (now) // ���� ���������� ����������� � �������� �������
     extrLowTime = TimeCurrent();
    else // ���� ���������� ����������� �� �������
     extrLowTime = bufferRates[0].time;
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
  /*if ( now)
   Print("����� High = ",TimeToString(extrHighTime)," ����� Low = ",TimeToString(extrLowTime) );*/
   return (true);
 }
 
// ����� ���������� �������� ������� ����
double CExtremum::AverageBar(datetime start_pos)
 {
  int copied = 0;
  double buffer_average_atr[1];
  if (_handle_ATR == INVALID_HANDLE)
   {
    PrintFormat("%s ERROR. I have INVALID HANDLE = %d, %s", __FUNCTION__, GetLastError(), EnumToString((ENUM_TIMEFRAMES)_tf_period));
    return (-1);
   }
  copied = CopyBuffer(_handle_ATR, 0, start_pos, 1, buffer_average_atr);
  if (copied < 1) 
   {
    PrintFormat("%s ERROR. I have this error = %d, %s. copied = %d, calculated = %d, buf_num = %d start_pos = %s", __FUNCTION__, GetLastError(), EnumToString((ENUM_TIMEFRAMES)_tf_period), copied, BarsCalculated(_handle_ATR), _handle_ATR,TimeToString(start_pos));
    return(0);
   }
  return (buffer_average_atr[0]);
 }