//+------------------------------------------------------------------+
//|                                                      CDynamo.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>

enum ENUM_PERIOD
{
 Day,
 Month
};
//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CDynamo
{
protected:
 datetime m_last_day_number;   // ����� ���������� ������������� ���
 datetime m_last_month_number; // ����� ���������� ������������� ������
 
 string _symbol;                 // ��� �����������
 ENUM_TIMEFRAMES _period;        // ������ �������
      
 uint m_retcode;          // ��� ���������� ����������� ������ ��� 
 string m_comment;        // ����������� ����������
 
 const int _volume;      // ������ ����� ������   
 const double _factor;   // ��������� ��� ���������� �������� ������ ������ �� ������
 const int _percentage;  // ������� ��������� ����� ������� �������� ����� ����������� �� ��������
 const int _slowPeriod;  // ������ ������������� ������� ������
 const int _deltaStep;   // �������� ���� ��������� ������
 
 int _deltaFast;     // ������ ��� ������� ������ "�������" ��������
 int _deltaFastBase; // ��������� �������� "�������" ������
 int _deltaSlow;     // ������ ��� ������� ������ "��������" ��������
 int _deltaSlowBase; // ��������� �������� "��������" ������
 double fastVol;   // ����� ��� ������� ��������
 double slowVol;   // ����� ��� �������� ��������
 
 const int _dayStep;          // ��� ������� ���� � ������� ��� ������� ��������
 const int _monthStep;        // ��� ������� ���� � ������� ��� �������� ��������
 double prevDayPrice;   // ������� ������� ���� ���
 double prevMonthPrice; // ������� ������� ���� ������
 
 bool isMonthInit; // ���� ������������� ������� ��� ������
 bool isDayInit;   // ���� ������������� ������� ��� ���
public:
//--- ������������
 void CDynamo(int deltaFast, int deltaSlow, int deltaStep, int dayStep, int monthStep, int volume, double factor, int percentage, int slowPeriod);      // ����������� CDynamo
 
//--- ������ ������� � ���������� ������:
 uint GetRetCode() const {return(m_retcode);}    // ��� ���������� ����������� ������ ���� 
 datetime GetLastDay() const {return(m_last_day_number);}   // 18:00 ���������� ���
 datetime GetLastMonth() const {return(m_last_month_number);}  // ���� � ����� ���������� ���������� ������
 string GetComment() const {return(m_comment);}    // ����������� ����������
 string GetSymbol() const {return(_symbol);}     // ��� �����������
 ENUM_TIMEFRAMES GetPeriod() const {return(_period);}     // ������ �������
 bool isInit() const {return(isMonthInit && isDayInit);}  // ������������� ��������
//--- ������ ������������� ���������� ������:  
 void SetSymbol(string symbol) {_symbol = (symbol==NULL || symbol=="") ? Symbol() : symbol; }
 void SetPeriod(ENUM_TIMEFRAMES period) {_period = (period==PERIOD_CURRENT) ? Period() : period; }

//--- ������� ������ ������
 bool isNewMonth();
 int isNewDay();
 void InitDayTrade();
 void InitMonthTrade();
 void FillArrayWithPrices(ENUM_PERIOD period);
 double RecountVolume();
 void RecountDelta();
 bool CorrectOrder(double volume);
 int GetHours(datetime date);
 int GetDayOfWeek(datetime date);
};

//+------------------------------------------------------------------+
//| ����������� CDynamo.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo(int deltaFast, int deltaSlow, int deltaStep, int dayStep, int monthStep, int volume, double factor, int percentage, int slowPeriod):
                      _deltaFastBase(deltaFast), _deltaSlowBase(deltaSlow),
                      _deltaStep(deltaStep), _dayStep(dayStep), _monthStep(monthStep),
                      _volume(volume), _factor(factor), _percentage(percentage), _slowPeriod(slowPeriod)
  {
   m_retcode = 0;         // ��� ���������� ����������� ������ ���� 
   m_last_day_number = TimeCurrent();       // �������������� ���� ������� ����
   m_last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // �������������� ����� ������� �������
   m_comment = "";        // ����������� ����������
   isDayInit = false;
   isMonthInit = false;
   _symbol = Symbol();   // ��� �����������, �� ��������� ������ �������� �������
   _period = Period();   // ������ �������, �� ��������� ������ �������� �������
  }

//+------------------------------------------------------------------+
//| ������ �� 18:00 ������� ���.                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - ���� ������ �����                               |
//|         false  - ���� ����� �� ������ ��� �������� ������        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CDynamo::isNewDay()
{
 datetime current_time = TimeCurrent();
 
 if(GetHours(current_time) < 18)
 {
  m_last_day_number = current_time;
  return(-1);
 }
  
 if (GetHours(m_last_day_number) < 18 && GetHours(current_time) >= 18) 
 {
  m_last_day_number = current_time;
  return(GetDayOfWeek(m_last_day_number));
 }

 //--- ����� �� ����� ����� - ������ ���� �� �����
 return(-1);
}

//+------------------------------------------------------------------+
//| ������ �� ��������� ������ ������.                               |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - ���� ����� �����                                |
//|         false  - ���� �� ����� ����� ��� �������� ������         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::isNewMonth()
{
 datetime current_time = TimeCurrent();

 //--- ��������� ��������� ������ ������: 
 if (m_last_month_number < current_time - _slowPeriod*24*60*60)  // ������ 30 ����
 {
  if (GetHours(current_time) >= 18) // ����� ����� ���������� � 18 �����
  { 
   m_last_month_number = current_time; // ���������� ������� ����
   return(true);
  }
 }
 //--- ����� �� ����� ����� - ������ ����� �� �����
 return(false);
}

//+------------------------------------------------------------------+
//| ������������� ���������� ��� �������� � ������� ���              |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::InitDayTrade()
{
 if (isNewDay() > 0) // ���� �������� ����� ����
 {
  //PrintFormat("%s ����� ���� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_day_number));
  _deltaFast = _deltaFastBase;
  prevDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
  fastVol = NormalizeDouble(slowVol * _deltaFast * _factor * _percentage * _factor, 2);
  isDayInit = true;
 }
}

//+------------------------------------------------------------------+
//| ������������� ���������� ��� �������� � ������� ������           |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::InitMonthTrade()
{
 if(isNewMonth())
 {
  //PrintFormat("%s ����� ����� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_month_number));
  _deltaSlow = _deltaSlowBase;
  prevMonthPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  slowVol = NormalizeDouble(_volume * _deltaSlow * _factor, 2);
  isMonthInit = true;
 }
}

//+------------------------------------------------------------------+
//| �������� �������� ������                                         |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::RecountDelta()
{
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 if (_deltaFast < 100 && GreatDoubles(currentPrice, prevDayPrice + _dayStep*Point()))
 {
  prevDayPrice = currentPrice;
  _deltaFast = _deltaFast + _deltaStep;
  //PrintFormat("%s ����� ������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 if (_deltaFast > 0 && LessDoubles(currentPrice, prevDayPrice - _dayStep*Point()))
 {
  prevDayPrice = currentPrice;
  _deltaFast = _deltaFast - _deltaStep;
  //PrintFormat("%s ����� ������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 
 if (_deltaSlow < 100 && GreatDoubles(currentPrice, prevMonthPrice + _monthStep*Point()))
 {
  _deltaSlow = _deltaSlow + _deltaStep;
  prevMonthPrice = currentPrice;
  //PrintFormat("%s ����� �������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
 }
 if (_deltaSlow > 0 && LessDoubles(currentPrice, prevMonthPrice - _monthStep*Point()))
 {
  prevMonthPrice = currentPrice;
  
  if (_deltaSlow > _deltaSlowBase)
  {
   _deltaSlow = _deltaSlowBase;
  }
  else
  {
   _deltaSlow = _deltaSlow - _deltaStep;
   //PrintFormat("%s ����� �������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
  }
 }
}

//+------------------------------------------------------------------+
//| �������� ������� ����� �� ��������� ����� ������                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double CDynamo::RecountVolume()
{
 slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 fastVol = NormalizeDouble(slowVol * _deltaFast * _factor, 2);
 //PrintFormat("%s ������� ����� %.02f, _deltaSlow=%d", MakeFunctionPrefix(__FUNCTION__),  slowVol, _deltaSlow);
 //PrintFormat("%s ����� ����� %.02f, _deltaFast=%d", MakeFunctionPrefix(__FUNCTION__), fastVol, _deltaFast);
 return (slowVol - fastVol); 
}

//+------------------------------------------------------------------+
//| �������� ������� ����� �� ��������� ����� ������                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::CorrectOrder(double volume)
{
 if (volume == 0) return(false);
 
 MqlTradeRequest request = {0};
 MqlTradeResult result = {0};
 
 ENUM_ORDER_TYPE type;
 double price;
 
 if (volume > 0)
 {
  type = ORDER_TYPE_BUY;
  price = SymbolInfoDouble(_symbol, SYMBOL_ASK);
 }
 else
 {
  type = ORDER_TYPE_SELL;
  price = SymbolInfoDouble(_symbol, SYMBOL_BID);
 }
 
 request.action = TRADE_ACTION_DEAL;
 request.symbol = _symbol;
 request.volume = MathAbs(volume);
 request.price = price;
 request.sl = 0;
 request.tp = 0;
 request.deviation = SymbolInfoInteger(_symbol, SYMBOL_SPREAD); 
 request.type = type;
 request.type_filling = ORDER_FILLING_FOK;
 return (OrderSend(request, result));
}

int CDynamo::GetHours(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.hour);
}

int CDynamo::GetDayOfWeek(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.day_of_week);
}
