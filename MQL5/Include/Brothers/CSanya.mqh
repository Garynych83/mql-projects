//+------------------------------------------------------------------+
//|                                                       CSanya.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include "CBrothers.mqh"
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CSanya: public CBrothers
{
protected:
 double _high;
 double _low;
 double _average;
 int _countSteps;
 
 MqlTick tick;
public:
//--- ������������
 //void CSanya();
 void CSanya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep, int countSteps
             , ENUM_ORDER_TYPE type ,int volume, double factor, int percentage, int fastPeriod, int slowPeriod);      // ����������� CSanya
             
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
void CSanya::CSanya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep, int countSteps,
                     ENUM_ORDER_TYPE type, int volume, double factor, int percentage, int fastPeriod, int slowPeriod)
  {
   _deltaFastBase=deltaFast;
   _deltaSlowBase=deltaSlow;
   _fastDeltaStep=fastDeltaStep;
   _slowDeltaStep=slowDeltaStep;
   _dayStep=dayStep;
   _monthStep=monthStep;
   _countSteps=countSteps;
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
void CSanya::InitDayTrade()
{
 if (timeToUpdateFastDelta()) // ���� �������� ����� ����
 {
  PrintFormat("%s ����� ���� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(m_last_day_number));
  _deltaFast = _deltaFastBase;
  _isDayInit = true;
  _average = 0;
  _high = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _low = SymbolInfoDouble(_symbol, SYMBOL_LAST);
  _startDayPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
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
void CSanya::InitMonthTrade()
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
void CSanya::RecountDelta()
{
// ������� ����
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 double priceAB, priceHL;
 SymbolInfoTick(_symbol, tick);

// ���� ���� ����� �����...
 if (currentPrice > _high + 2*_dayStep*Point()) // ���� ������� ���� ���������� �� ���
 {
  Print("���� ����������� �� 2 ����, �������� ������ ��������");
  _average = currentPrice - (currentPrice - _startDayPrice)/2;   // �������� ������� �������� ����� ������� ����� � ����� ������ ������
  _high = currentPrice;                                          // �������� ���
 }
 if (_average > _startDayPrice + _countSteps*_dayStep*Point()/2)
 {
  PrintFormat("���� ���� ����� �� %d �����, ��������� ���� ������ ��������", _countSteps);
  _startDayPrice = _high;
  _low = _high - _dayStep*Point();
  _average = 0;
  if (_type == ORDER_TYPE_SELL) // ���� ������, � �������� ����������� - ����, ���� "�����������"
  {
   Print("���� ������, � �������� ����������� - ����, ���� \"�����������\". ����������� ��. ������");
   _deltaFast = _deltaFast + _fastDeltaStep;    // �������� ������� ������
  }
 }
 
// ���� ���� ����� ����...
 if (currentPrice < _low - _dayStep*Point()) // ���� ������� ���� ���������� �� ���
 {
  Print("���� ����������� �� ���");
  _average = currentPrice + (_startDayPrice - currentPrice)/2;   // �������� ������� �������� ����� ������� ����� � ����� ������ ������
  _low = currentPrice;                                           // �������� ���
 }
 if (_average > 0 && _average < _startDayPrice - _countSteps*_dayStep*Point()/2) // ���� ���� ����� ������� ������
 {
  PrintFormat("���� ���� ���� �� %d ����� , ��������� ���� ������ ��������.", _countSteps);
  _startDayPrice = _low;
  _high = _low + _dayStep*Point();
  _average = 0;
  if (_type == ORDER_TYPE_BUY) // ���� ������, � �������� ����������� - �����, ���� "�����������"
  {
   Print("���� ������, � �������� ����������� - �����, ���� \"�����������\". ����������� ��. ������");
   _deltaFast = _deltaFast + _fastDeltaStep;    // �������� ������� ������
  }
 }
 
 priceAB = (_direction == 1) ? tick.ask : tick.bid;
 if ( _average > 0 &&
      _direction*(_average - _startDayPrice) > 0 && // ���� ������� ��� ��������� �� ������ ����(����) ���������
      _direction*(priceAB - _average) < 0 &&        // ���� ������ ����� ������� ����(�����)
      _deltaFast < 100)                             // �� ��� �� "����������"
 {
  PrintFormat("���� ���� � ���� �������, ������������ � ������ ����� ������� - ����������� ��. ������");
  _deltaFast = _deltaFast + _fastDeltaStep;   // �������� ������� ������ (���� ���� ������ ���������� ����������� - ��������)
 }

 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 if (_direction*(_average - _startDayPrice) < 0 &&  // ���� ������� ��� ��������� �� ������ ����(����) ���������
     _direction*(priceAB - _average) > 0 &&         // ���� ������ ����� ������� �����(����)
     _deltaFast > 0)                                // �� ����������
 {
  PrintFormat("�� ���������, ���� ���� ������ ���, ������������ � ������ ������� - ��������� ��. ������.");
  _deltaFast = _deltaFast - _fastDeltaStep;   // �������� ������� ������ (���� ����� � ���� ������� - ���������� ����)
 }
 
 priceHL = (_direction == 1) ? _high : _low;               // ���� ����� �� ������� - ������� High, ���� �� ������� - Low 
 priceAB = (_direction == 1) ? tick.bid : tick.ask;        // ���� ����� �� ������� - ������� bid, ���� �� ������� - ask
 if (_deltaFast > 0 && _direction*(priceAB - priceHL) > 0) // �������: Bid>High , �������: Ask<Low
 {
  PrintFormat("�� ���������, �� ���� ����� ����� � ���� ������� - ��������� ��. ������");
  _deltaFast = _deltaFast - _fastDeltaStep;   // �������� ������� ������ (���� ����� � ���� ������� - ���������� ����)
 }
 
 // ��������� ������� ������
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
double CSanya::RecountVolume()
{
 _slowVol = NormalizeDouble(_volume * _factor * _deltaSlow, 2);
 _fastVol = NormalizeDouble(_slowVol * _deltaFast * _factor * _percentage * _factor, 2);
 //PrintFormat("%s ������� ����� %.02f, _deltaSlow=%d", MakeFunctionPrefix(__FUNCTION__),  _slowVol, _deltaSlow);
 //PrintFormat("%s ����� ����� %.02f, _deltaFast=%d", MakeFunctionPrefix(__FUNCTION__), _fastVol, _deltaFast);
 return (_slowVol - _fastVol); 
}
