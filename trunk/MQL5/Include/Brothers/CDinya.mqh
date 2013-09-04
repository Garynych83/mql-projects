//+------------------------------------------------------------------+
//|                                                       CDinya.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include "CBrothers.mqh"
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CDinya: public CBrothers
{
public:
//--- ������������
 //void CDinya();
 void CDinya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep
             , ENUM_ORDER_TYPE type ,int volume, double factor, int percentage, int fastPeriod, int slowPeriod);      // ����������� CDinya
             
 void InitDayTrade();
 void InitMonthTrade();
 double RecountVolume();
 void RecountDelta();
};

//+------------------------------------------------------------------+
//| ����������� CDinya.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDinya::CDinya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep
                     ,ENUM_ORDER_TYPE type, int volume, double factor, int percentage, int fastPeriod, int slowPeriod)
  {
   _deltaFastBase=deltaFast;
   _deltaSlowBase=deltaSlow;
   _fastDeltaStep=fastDeltaStep;
   _slowDeltaStep=slowDeltaStep;
   _dayStep=dayStep;
   _monthStep=monthStep;
   _fastPeriod=fastPeriod;
   _slowPeriod=slowPeriod;
   _type=type;
   _volume=volume;
   _factor=factor;
   _percentage=percentage;
  
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

//+------------------------------------------------------------------+
//| ������������� ���������� ��� �������� � ������� ���              |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDinya::InitDayTrade()
{
 if (timeToUpdateFastDelta()) // ���� �������� ����� ����
 {
  PrintFormat("%s ����� ���� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_day_number));
  if (_direction * _startDayPrice > _direction * SymbolInfoDouble(_symbol, SYMBOL_LAST))
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
void CDinya::InitMonthTrade()
{
 if(isNewMonth())
 {
  PrintFormat("%s ����� ����� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_month_number));
  _deltaSlow = _deltaSlowBase;
  _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
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
void CDinya::RecountDelta()
{
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 if (_direction*(_deltaFast - 50) < 50 && GreatDoubles(currentPrice, _prevDayPrice + _dayStep*Point())) // _dir = 1 : delta < 100; _dir = -1 : delta > 0
 {
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast + _direction*_fastDeltaStep;
  //PrintFormat("%s ����� ������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 if ((_direction*_deltaFast + 50) > (_direction*50) && LessDoubles(currentPrice, _prevDayPrice - _dayStep*Point())) // _dir = 1 : delta > 0; _dir = -1 : delta < 100
 {
  _prevDayPrice = currentPrice;
  _deltaFast = _deltaFast - _direction*_fastDeltaStep;
  //PrintFormat("%s ����� ������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaFast);
 }
 
 if (_direction*(_deltaSlow - 50) < 50 && GreatDoubles(currentPrice, _prevMonthPrice + _monthStep*Point()))
 {
   _prevMonthPrice = currentPrice;

  if (_direction < 0 && _deltaSlow < _deltaSlowBase)
  {
   _deltaSlow = _deltaSlowBase;
  }
  else
  {
   _deltaSlow = _deltaSlow + _direction*_slowDeltaStep;
  }
  //PrintFormat("%s ����� �������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
 }
 if ((_direction*_deltaSlow + 50) > (_direction*50) && LessDoubles(currentPrice, _prevMonthPrice - _monthStep*Point()))
 {
  _prevMonthPrice = currentPrice;
  
  if (_direction > 0 && _deltaSlow > _deltaSlowBase)
  {
   _deltaSlow = _deltaSlowBase;
  }
  else
  {
   _deltaSlow = _deltaSlow - _direction*_slowDeltaStep;
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
double CDinya::RecountVolume()
{
 _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 //PrintFormat("%s ������� ����� %.02f, _deltaSlow=%d", MakeFunctionPrefix(__FUNCTION__),  _slowVol, _deltaSlow);
 //PrintFormat("%s ����� ����� %.02f, _deltaFast=%d", MakeFunctionPrefix(__FUNCTION__), _fastVol, _deltaFast);
 return (_slowVol - _fastVol); 
}
