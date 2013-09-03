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
 datetime m_last_day_number;   // ����� ���������� ������������� ���
 datetime m_last_month_number; // ����� ���������� ������������� ������
 
 string _symbol;                 // ��� �����������
 ENUM_TIMEFRAMES _period;        // ������ �������
      
 string m_comment;        // ����������� ����������
 
 ENUM_ORDER_TYPE _type; // �������� ����������� ��������
 int _direction;         // ��������� �������� 1 ��� -1 � ���������� �� _type
 int _volume;      // ������ ����� ������   
 double _factor;   // ��������� ��� ���������� �������� ������ ������ �� ������
 int _percentage;  // ������� ��������� ����� ������� �������� ����� ����������� �� ��������
 int _startHour;   // ��� ������ ��������
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
 
 int _dayStep;          // ��� ������� ���� � ������� ��� ������� ��������
 int _monthStep;        // ��� ������� ���� � ������� ��� �������� ��������
 double _startDayPrice;   // ���� ������ ������ �������� ���
 double _prevDayPrice;   // ������� ������� ���� ���
 double _prevMonthPrice; // ������� ������� ���� ������
 
 bool _isMonthInit; // ���� ������������� ������� ��� ������
 bool _isDayInit;   // ���� ������������� ������� ��� ���
public:
//--- ������������
 void CBrothers(void);      // ����������� CBrothers
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
/*
//+------------------------------------------------------------------+
//| ����������� CBrothers.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CBrothers::CBrothers(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep, ENUM_ORDER_TYPE type, int volume, double factor, int percentage, int fastPeriod, int slowPeriod):
                      _deltaFastBase(deltaFast), _deltaSlowBase(deltaSlow),
                      _fastDeltaStep(fastDeltaStep), _slowDeltaStep(slowDeltaStep),
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
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;
  }
*/
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
int CBrothers::isNewDay()
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
bool CBrothers::isNewMonth()
{
 datetime current_time = TimeCurrent();

 //--- ��������� ��������� ������ ������: 
 if (m_last_month_number < current_time - _slowPeriod*24*60*60)  // ������ _slowPeriod ����
 {
  if (GetHours(current_time) >= _startHour) // ����� ����� ���������� � _startHour �����
  { 
   m_last_month_number = current_time; // ���������� ������� ����
   return(true);
  }
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
