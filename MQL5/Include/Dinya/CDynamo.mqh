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
      
 string m_comment;        // ����������� ����������
 
 const ENUM_ORDER_TYPE _type; // �������� ����������� ��������
 const int _direction;         // ��������� �������� 1 ��� -1 � ���������� �� _type
 const int _volume;      // ������ ����� ������   
 const double _factor;   // ��������� ��� ���������� �������� ������ ������ �� ������
 const int _percentage;  // ������� ��������� ����� ������� �������� ����� ����������� �� ��������
 int _startHour;   // ��� ������ ��������
 const int _fastPeriod;  // ������ ������������� ������� ������ � �����
 const int _slowPeriod;  // ������ ������������� ������� ������ � ����
 const int _fastDeltaStep;   // �������� ���� ��������� ������
 const int _slowDeltaStep;   // �������� ���� ��������� ������
 
 int _deltaFast;     // ������ ��� ������� ������ "�������" ��������
 int _deltaFastBase; // ��������� �������� "�������" ������
 int _deltaSlow;     // ������ ��� ������� ������ "��������" ��������
 int _deltaSlowBase; // ��������� �������� "��������" ������
 double _fastVol;   // ����� ��� ������� ��������
 double _slowVol;   // ����� ��� �������� ��������
 
 const int _dayStep;          // ��� ������� ���� � ������� ��� ������� ��������
 const int _monthStep;        // ��� ������� ���� � ������� ��� �������� ��������
 double _startDayPrice;   // ���� ������ ������ �������� ���
 double _prevDayPrice;   // ������� ������� ���� ���
 double _prevMonthPrice; // ������� ������� ���� ������
 
 bool _isMonthInit; // ���� ������������� ������� ��� ������
 bool _isDayInit;   // ���� ������������� ������� ��� ���
public:
//--- ������������
 void CDynamo(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep
             , ENUM_ORDER_TYPE type ,int volume, double factor, int percentage, int fastPeriod, int slowPeriod);      // ����������� CDynamo
 
//--- ������ ������� � ���������� ������:
 datetime GetLastDay() const {return(m_last_day_number);}      // 18:00 ���������� ���
 datetime GetLastMonth() const {return(m_last_month_number);}  // ���� � ����� ���������� ���������� ������
 string GetComment() const {return(m_comment);}      // ����������� ����������
 string GetSymbol() const {return(_symbol);}         // ��� �����������
 ENUM_TIMEFRAMES GetPeriod() const {return(_period);}          // ������ �������
 
//--- ������ ������������� ���������� ������:  
 void SetSymbol(string symbol) {_symbol = (symbol==NULL || symbol=="") ? Symbol() : symbol; }
 void SetPeriod(ENUM_TIMEFRAMES period) {_period = (period==PERIOD_CURRENT) ? Period() : period; }
 void SetStartHour(int startHour) {_startHour = startHour;}
 void SetStartHour(datetime startHour) {_startHour = (GetHours(startHour) + 1) % 24; Print("_startHour=",_startHour);}
 
//--- ������� ������ ������
 bool isInit() {return(_isMonthInit && _isDayInit);}  // ������������� ��������
 bool timeToUpdateFastDelta();
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
void CDynamo::CDynamo(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep, ENUM_ORDER_TYPE type, int volume, double factor, int percentage, int fastPeriod, int slowPeriod):
                      _deltaFastBase(deltaFast), _deltaSlowBase(deltaSlow), _fastDeltaStep(fastDeltaStep), _slowDeltaStep(slowDeltaStep),
                       _dayStep(dayStep), _monthStep(monthStep), _fastPeriod(fastPeriod), _slowPeriod(slowPeriod),
                      _type(type), _volume(volume), _factor(factor), _percentage(percentage)
  {
   m_last_day_number = TimeCurrent() - _fastPeriod*60*60;       // �������������� ���� ������� ����
   m_last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // �������������� ����� ������� �������
   m_comment = "";        // ����������� ����������
   _isDayInit = false;
   _isMonthInit = false;
   _symbol = Symbol();   // ��� �����������, �� ��������� ������ �������� �������
   _period = Period();   // ������ �������, �� ��������� ������ �������� �������
  _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  }

//+------------------------------------------------------------------+
//| �������� �� ����� ���������� ������� ������                      |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - ���� ������ �����                               |
//|         false  - ���� ����� �� ������ ��� �������� ������        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::timeToUpdateFastDelta()
{
 datetime current_time = TimeCurrent();
 
 //--- ��������� ��������� ������ ������: 
 if (m_last_day_number < current_time - _fastPeriod*60*60)  // ������ _fastPeriod �����
 {
  if (GetHours(current_time) >= _startHour) // ����� ����� ���������� � 18 �����
  { 
   m_last_day_number = current_time; // ���������� ������� ����
   return(true);
  }
 }

 //--- ����� �� ����� ����� - ������ ���� �� �����
 return(false);
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
 
 if(GetHours(current_time) < _startHour)
 {
  m_last_day_number = current_time;
  return(-1);
 }
  
 if (GetHours(m_last_day_number) < _startHour && GetHours(current_time) >= _startHour) 
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
 if (m_last_month_number < current_time - _slowPeriod*24*60*60)  // ������ _slowPeriod ����
 {
  if (GetHours(current_time) >= _startHour) // ����� ����� ���������� � _startHour �����
  { 
   _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
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
 if (timeToUpdateFastDelta()) // ���� �������� ����� ����
 {
  PrintFormat("%s ����� ���� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_day_number));
  if (_startDayPrice > SymbolInfoDouble(_symbol, SYMBOL_LAST))
  {
   _deltaFast = 0;
   _isDayInit = false;
  }
  else
  {
   _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
   _deltaFast = _deltaFastBase;
   _isDayInit = true;
  } 
  
  _prevDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
  _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
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
  PrintFormat("%s ����� ����� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_month_number));
  _deltaSlow = _deltaSlowBase;
  _prevMonthPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _slowVol = NormalizeDouble(_volume * _deltaSlow * _factor, 2);
  _isMonthInit = true;
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
 if (_deltaFast < 100 && GreatDoubles(currentPrice, _prevDayPrice + _dayStep*Point()))
 {
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast + _fastDeltaStep;
  //PrintFormat("%s ����� ������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 if (_deltaFast > 0 && LessDoubles(currentPrice, _prevDayPrice - _dayStep*Point()))
 {
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast - _fastDeltaStep;
  //PrintFormat("%s ����� ������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 
 if (_deltaSlow < 100 && GreatDoubles(currentPrice, _prevMonthPrice + _monthStep*Point()))
 {
  _deltaSlow = _deltaSlow + _slowDeltaStep;
  _prevMonthPrice = currentPrice;
  //PrintFormat("%s ����� �������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
 }
 if (_deltaSlow > 0 && LessDoubles(currentPrice, _prevMonthPrice - _monthStep*Point()))
 {
  _prevMonthPrice = currentPrice;
  
  if (_deltaSlow > _deltaSlowBase)
  {
   _deltaSlow = _deltaSlowBase;
  }
  else
  {
   _deltaSlow = _deltaSlow - _slowDeltaStep;
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
 _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 //PrintFormat("%s ������� ����� %.02f, _deltaSlow=%d", MakeFunctionPrefix(__FUNCTION__),  _slowVol, _deltaSlow);
 //PrintFormat("%s ����� ����� %.02f, _deltaFast=%d", MakeFunctionPrefix(__FUNCTION__), _fastVol, _deltaFast);
 return (_slowVol - _fastVol); 
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
  type = _type;
  price = SymbolInfoDouble(_symbol, SYMBOL_ASK);
 }
 else
 {
  type = (ENUM_ORDER_TYPE)(_type + MathPow(-1, _type)); // ���� _type= 0, �� type =1, ����  _type= 1, �� type =0
  price = SymbolInfoDouble(_symbol, SYMBOL_BID);
 }
 
 request.action = TRADE_ACTION_DEAL;
 request.symbol = _symbol;
 request.volume = MathAbs(volume);
 log_file.Write(LOG_DEBUG, StringFormat("%s operation=%s, volume=%f", MakeFunctionPrefix(__FUNCTION__), EnumToString(type), MathAbs(volume)));
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
