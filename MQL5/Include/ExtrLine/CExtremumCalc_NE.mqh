//+------------------------------------------------------------------+
//|                                                CExtremumCalc.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""

#include <CompareDoubles.mqh>

#define ATR_PERIOD 30

struct SExtremum
{
 int direction;
 double price;
 double channel;
};

class CExtremumCalc
{
 private:
 string _symbol;
 ENUM_TIMEFRAMES _period;
 ENUM_TIMEFRAMES _period_ATR;
 int digits;
 double _startDayPrice;
 double difToNewExtremum;
 SExtremum  num0,
            num1,
            num2,
            num3;
 int _depth;
 double _percentageATR_price;
 double _percentageATR_channel;
 int handleATR_channel;
 int handleATR_price;
 
 public:
 CExtremumCalc(string symbol, ENUM_TIMEFRAMES period, ENUM_TIMEFRAMES period_ATR, double percentageATR_price, int ATRperiod_channel, double percentageATR_channel);
~CExtremumCalc();

 bool isExtremum(SExtremum& extr_array[], bool now = true, datetime start_index_time = __DATETIME__);
 void RecountExtremum(bool now = true, datetime start_index_time = __DATETIME__);
 SExtremum getExtr(int i);
 ENUM_TIMEFRAMES getPeriod() { return(_period); } 
 void SetPeriod(ENUM_TIMEFRAMES tf) { _period = tf; }
 void SetStartDayPrice(double price) { _startDayPrice = price; }
 bool isFourExtrExist();
 bool isATRCalculated(int size_channel, int size_price);
};

CExtremumCalc::CExtremumCalc(string symbol, ENUM_TIMEFRAMES period, ENUM_TIMEFRAMES period_ATR, double percentageATR_price, int ATRperiod_channel, double percentageATR_channel):
               _symbol (symbol),
               _period (period),
               _period_ATR (period_ATR),
               _percentageATR_price (percentageATR_price),
               _percentageATR_channel (percentageATR_channel)
               {
                digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
                _startDayPrice = -1;
                handleATR_channel = iATR(_symbol, _period, ATRperiod_channel);
                handleATR_price = iATR(_symbol, _period_ATR, ATR_PERIOD);              
                if(handleATR_channel == INVALID_HANDLE || handleATR_price == INVALID_HANDLE) Alert("Invalid handle ATR.");
               }
CExtremumCalc::~CExtremumCalc()
                {
                 IndicatorRelease(handleATR_channel);
                 IndicatorRelease(handleATR_price);
                }             

//-----------------------------------------------------------------

bool CExtremumCalc::isExtremum(SExtremum& extr_array [], bool now = true, datetime start_pos_time = __DATETIME__)
{
 SExtremum result1 = {0, -1, -1};
 SExtremum result2 = {0, -1, -1};
 if(_startDayPrice == -1) { Alert(StringFormat("�� ������ ���������� startDayPrice �� %s ����������!", EnumToString((ENUM_TIMEFRAMES)_period))); }
 MqlRates buffer[1];
 double ATR_channel[1];
 double ATR_price[1];

 
 if(CopyRates(_symbol, _period, start_pos_time, 1, buffer) < 1)
  PrintFormat("%s Rates buffer: error = %d, calculated = %d, start_index = %s", EnumToString((ENUM_TIMEFRAMES)_period), GetLastError(), Bars(_symbol, _period), TimeToString(start_pos_time));
 //if(now) PrintFormat("�������� ��� %s", TimeToString(buffer[0].time));
  //return(result);
 if(CopyBuffer(handleATR_channel, 0, start_pos_time, 1, ATR_channel) < 1)
  PrintFormat("%s ATR channel: error = %d, calculated = %d, start_index = %s", EnumToString((ENUM_TIMEFRAMES)_period),GetLastError(), BarsCalculated(handleATR_channel), TimeToString(start_pos_time));
  //return(result);
 if(CopyBuffer(handleATR_price, 0, start_pos_time, 1, ATR_price) < 1)
  PrintFormat("%s ATR price: error = %d, calculated = %d, start_index = %s", EnumToString((ENUM_TIMEFRAMES)_period),GetLastError(), BarsCalculated(handleATR_price), TimeToString(start_pos_time)); 
  //return(result);
 difToNewExtremum = ATR_price[0]*_percentageATR_price;
 double high = 0, low = 0;
 
 if (now)
 {
  high = buffer[0].close;
  low = buffer[0].close;
 }
 else
 {
  high = buffer[0].high;
  low = buffer[0].low;
 }
 
 if ((num0.direction == 0 && (GreatDoubles(high, _startDayPrice + 2*difToNewExtremum, digits))) // ���� ����������� ��� ��� � ���� 2 ���� �� ��������� ����
   ||(num0.direction >  0 && (GreatDoubles(high, num0.price, digits)))
   ||(num0.direction <  0 && (GreatDoubles(high, num0.price + difToNewExtremum, digits))))
 {
  result1.direction = 1;
  result1.price = high;
  result1.channel = (ATR_channel[0]*_percentageATR_channel)/2;
  //PrintFormat("%s %s start_pos_time = %s; max %0.5f", __FUNCTION__,  EnumToString((ENUM_TIMEFRAMES)_period), TimeToString(start_pos_time), high);
 }
 
 if ((num0.direction == 0 && (LessDoubles(low, _startDayPrice - 2*difToNewExtremum, digits))) // ���� ����������� ��� ��� � ���� 2 ���� �� ��������� ����
   ||(num0.direction <  0 && (LessDoubles(low, num0.price, digits)))
   ||(num0.direction >  0 && (LessDoubles(low, num0.price - difToNewExtremum, digits))))
 {
  result2.direction = -1;
  result2.price = low;
  result2.channel = (ATR_channel[0]*_percentageATR_channel)/2;
  //PrintFormat("%s %s start_pos_time = %s; min  %0.5f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), TimeToString(start_pos_time), low);
 }
 
 extr_array[0] = result1;
 extr_array[1] = result2;
  
 if(result1.price != 0 || result2.price != 0) return(true);
 return(false);
}


void CExtremumCalc::RecountExtremum(bool now = true, datetime start_index_time = __DATETIME__)
{
 SExtremum new_extr[2] = {{0, -1, -1}, {0, -1, -1}};
 SExtremum current_bar = {0, -1, -1};
 
 if(isExtremum(new_extr, now, start_index_time))
 {
  for(int i = 0; i < 2; i++)
  {
   current_bar = new_extr[i];
   if (current_bar.direction != 0)
   {
    if (current_bar.direction == num0.direction) // ���� ����� ��������� � ��� �� ����������, ��� ������
    {
     num0.price = current_bar.price;
    }
    else
    {
     num3 = num2;
     num2 = num1;
     num1 = num0;
     num0 = current_bar;
    }       
   }
  }
 }
}

bool CExtremumCalc::isFourExtrExist()
{
 if(num0.direction != 0 && num1.direction != 0 && num2.direction != 0 && num3.direction != 0)
  return(true);
 return(false);
}

bool CExtremumCalc::isATRCalculated(int size_channel, int size_price)
{
 if(size_channel < 0 || size_price < 0)
 {
  PrintFormat("%s ������������ ������: size_channel=%d; size_price=%d", __FUNCTION__, size_channel, size_price);
  return(false);
 }
 if(BarsCalculated(handleATR_channel) >= size_channel &&
    BarsCalculated(handleATR_price  ) >= size_price)
 {
  PrintFormat("%s channel = %d; price =  %d  %d/%d", __FUNCTION__, BarsCalculated(handleATR_channel), BarsCalculated(handleATR_price  ), size_channel, size_price);
  return(true);
 }
 PrintFormat("%s %s . ��� channel ��������� %d, � ���� %d, ��� price ��������� %d, � ���� %d", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period), BarsCalculated(handleATR_channel), size_channel, BarsCalculated(handleATR_price), size_price);
 return(false);
}

SExtremum CExtremumCalc::getExtr(int i)
{
 SExtremum zero = {0, 0, 0};
 switch(i)
 {
 case(0):
  return num0;
 case(1):
  return num1;
 case(2):
  return num2;
 case(3):
  return num3;
 default:
  return zero;
 }
}