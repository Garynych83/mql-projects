//+------------------------------------------------------------------+
//|                                                    CBrothers.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include "BroUtilities.mqh"
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CBrothers
{
protected:
 MqlTick tick;

 datetime _last_time;          // ��������� ������������ ����� �������
 datetime _last_day_of_year;   // ����� ������ ���������� ������������� ��� 
 datetime _last_day_of_week;   // ����� ������ ���������� ������������� ��� ������
 datetime _last_month_number;  // ����� ���������� ������������� ������
 
 string _symbol;                 // ��� �����������
 ENUM_TIMEFRAMES _period;        // ������ �������
      
 string _comment;        // ����������� ����������
 
 ENUM_ORDER_TYPE _type; // �������� ����������� ��������
 int _direction;         // ��������� �������� 1 ��� -1 � ���������� �� _type
 int _volume;      // ������ ����� ������   
 double _factor;   // ��������� ��� ���������� �������� ������ ������ �� ������
 int _percentage;  // ������� ��������� ����� ������� �������� ����� ����������� �� ��������
 int _startHour;   // ��� ������ ��������
 int _startDayOfWeek; // ���� ������ ������ �������� 0 - �����������, 6 - �������
 int _fastPeriod;  // ������ ������������� ������� ������ � �����
 int _slowPeriod;  // ������ ������������� ������� ������ � ����
 int _fastDeltaStep;   // �������� ���� ��������� ������
 int _slowDeltaStep;   // �������� ���� ��������� ������
 
 int _deltaFast;     // ������ ��� ������� ������ "�������" ��������
 int _deltaFastBase; // ��������� �������� "�������" ������
 int _deltaSlow;     // ������ ��� ������� ������ "��������" ��������
 int _deltaSlowBase; // ��������� �������� "��������" ������
 double _fastVol;   // ����� ��� ������� ��������
 double _slowVol;   // ����� ��� �������� ��������
 
 double _dayStep;          // ��� ������� ���� � ������� ��� ������� ��������
 int _monthStep;        // ��� ������� ���� � ������� ��� �������� ��������
 double _startDayPrice;   // ���� ������ ������ �������� ���
 double _prevDayPrice;   // ������� ������� ���� ���
 double _prevMonthPrice; // ������� ������� ���� ������
 
 bool _isMonthInit; // ���� ������������� ������� ��� ������
 bool _isDayInit;   // ���� ������������� ������� ��� ���
 
 bool _fastDeltaChanged;
 bool _slowDeltaChanged;
public:
//--- ������������
 void CBrothers(void);      // ����������� CBrothers
//--- ������ ������� � ���������� ������:
 //datetime GetLastDay() const {return(_last_day_number);}      // 18:00 ���������� ���
 //datetime GetLastMonth() const {return(_last_month_number);}  // ���� � ����� ���������� ���������� ������
 string GetComment() const {return(_comment);}      // ����������� ����������
 string GetSymbol() const {return(_symbol);}         // ��� �����������
 ENUM_TIMEFRAMES GetPeriod() const {return(_period);}          // ������ �������
 
//--- ������ ������������� ���������� ������:  
 void SetSymbol(string symbol) {_symbol = (symbol==NULL || symbol=="") ? Symbol() : symbol; }
 void SetPeriod(ENUM_TIMEFRAMES period) {_period = period;}
 void SetStartHour(int startHour) {_startHour = startHour;}
 void SetStartHour(datetime startTime) {_startHour = (GetHours(startTime) + 1) % 24; Print("_startHour=",_startHour);}
 void SetStartDayOfWeek(datetime startTime) {_startDayOfWeek = GetDayOfWeek(startTime); Print("_startHour=",_startHour);}
//--- ������� ������ ������
 bool isInit() {return(_isMonthInit && _isDayInit);}  // ������������� ��������
 bool isMonthInit() {return(_isMonthInit);}
 bool isDayInit(){return(_isDayInit);}
 
 bool isFastDeltaChanged() {return _fastDeltaChanged;};
 bool isSlowDeltaChanged() {return _slowDeltaChanged;};

 bool timeToUpdateFastDelta();
 bool isNewMonth();
 bool isNewWeek();
 int isNewDay();
 void InitDayTrade();
 void InitMonthTrade();
 void FillArrayWithPrices(ENUM_PERIOD period);
 double RecountVolume();
 bool CorrectOrder(double volume);
 int GetHours(datetime date);
 int GetDayOfWeek(datetime date);
 int GetDayOfYear(datetime date);
 int GetYear(datetime date);
 /*
 virtual double RecountVolume();
 virtual void RecountFastDelta();
 virtual void RecountSlowDelta();
 */
};

//+------------------------------------------------------------------+
//| ����������� CBrothers.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CBrothers::CBrothers()
  {
   Print("����������� �������");
   _last_time = TimeCurrent() - _fastPeriod*60*60;       // �������������� ���� ������� ����
   _last_day_of_week = TimeCurrent();
   _last_day_of_year = TimeCurrent();
   _last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // �������������� ����� ������� �������
   _comment = "";        // ����������� ����������
   _isDayInit = false;
   _isMonthInit = false;
   _symbol = Symbol();   // ��� �����������, �� ��������� ������ �������� �������
   _period = Period();   // ������ �������, �� ��������� ������ �������� �������
   _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;
  }

//+------------------------------------------------------------------+
//| �������� �� ����� ���������� ������� ������                      |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - ���� ������ �����                               |
//|         false  - ���� ����� �� ������ ��� �������� ������        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBrothers::timeToUpdateFastDelta()
{
 datetime current_time = TimeCurrent();
 
 //--- ��������� ��������� ������ ������: 
 if (_last_time < current_time - _fastPeriod*60*60)  // ������ _fastPeriod �����
 {
  _last_time = current_time; // ���������� ������� ����
  return(true);
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
int CBrothers::isNewDay()
{
 datetime current_time = TimeCurrent();
 
 if(GetHours(current_time) < _startHour)
 {
  _last_day_of_year = current_time;
  return(-1);
 }
  
 if (GetHours(_last_day_of_year) < _startHour && GetHours(current_time) >= _startHour) 
 {
  _last_day_of_year = current_time;
  return(GetDayOfWeek(_last_day_of_year));
 }

 //--- ����� �� ����� ����� - ������ ���� �� �����
 return(-1);
}

//+------------------------------------------------------------------+
//| ������ �� ����� ���� ������.                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - ���� ������ �����                               |
//|         false  - ���� ����� �� ������ ��� �������� ������        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBrothers::isNewWeek()
{
 datetime current_time = TimeCurrent();
  
 if (((GetDayOfYear(current_time) > GetDayOfYear(_last_day_of_week)) || (GetYear(current_time) > GetYear(_last_day_of_week)))
    && GetDayOfWeek(current_time) == _startDayOfWeek && GetHours(current_time) >= _startHour) 
 {
  _last_day_of_week = current_time;
  return(true);
 }

 //--- ����� �� ����� ����� - ������ ���� �� �����
 return(false);
}

//+------------------------------------------------------------------+
//| ������ �� ��������� ������ ������.                               |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - ���� ����� �����                                |
//|         false  - ���� �� ����� ����� ��� �������� ������         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBrothers::isNewMonth()
{
 datetime current_time = TimeCurrent();

 //--- ��������� ��������� ������ ������: 
 if ((_last_month_number < current_time - _slowPeriod*24*60*60) && (GetHours(current_time) >= _startHour))  // ������ _slowPeriod ����
 {
  _last_month_number = current_time; // ���������� ������� ����
  return(true);
 }
 //--- ����� �� ����� ����� - ������ ����� �� �����
 return(false);
}

int CBrothers::GetHours(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.hour);
}

int CBrothers::GetDayOfWeek(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.day_of_week);
}

int CBrothers::GetDayOfYear(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.day_of_year);
}

int CBrothers::GetYear(datetime date)
{
 MqlDateTime _date;
 TimeToStruct(date, _date);
 return (_date.year);
}

//+------------------------------------------------------------------+
//| �������� ������� ����� �� ��������� ����� ������                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double CBrothers::RecountVolume()
{
 _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 //PrintFormat("%s _volume = %.05f, _factor = %.05f, _deltaSlow = %.05f", MakeFunctionPrefix(__FUNCTION__), _volume, _factor, _deltaSlow);
 //PrintFormat("%s slowVol = %.05f, fastVol = %.05f", MakeFunctionPrefix(__FUNCTION__), _slowVol, _fastVol);
 _slowDeltaChanged = false;
 _fastDeltaChanged = false;
 return (_slowVol - _fastVol); 
}

//+------------------------------------------------------------------+
//| �������� ������� ����� �� ��������� ����� ������                 |
//| INPUT:  double volume.                                           |
//| OUTPUT: result of correction - true or false                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CBrothers::CorrectOrder(double volume)
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