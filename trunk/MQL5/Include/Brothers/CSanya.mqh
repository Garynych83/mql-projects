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
#include "TradeLines.mqh"

struct SExtremum
{
 int direction;
 double price;
};

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CSanya: public CBrothers
{
protected:
 double _average;      // ���������� �� _averageMax � _averageMin ������� � ����� ������� �� ������ ������� ����
 double _averageMax;   // ������� ����� ���������� � �������
 double _averageMin;   // ������� ����� ��������� � �������
 double _averageRight; // ������� ����� ������ � ������ �����������
 double _averageLeft;  // ������� ����� ������ � ������� �����������
 int _stepsFromStartToExtremum;
 int _stepsFromStartToExit;
 int _stepsFromExtremumToExtremum;
 double currentPrice, priceAB, priceHL;
 
 SExtremum num0, num1, num2, num3;
 
 CTradeLine startLine;
 CTradeLine lowLine;
 CTradeLine highLine;
 CTradeLine averageMaxLine;
 CTradeLine averageMinLine;
 CTradeLine averageRightLine;
 CTradeLine averageLeftLine;

 SExtremum isExtremum();
public:
//--- ������������
 //void CSanya();
 void CSanya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep
             , int stepsFromStartToExtremum, int stepsFromStartToExit, int stepsFromExtremumToExtremum
             , ENUM_ORDER_TYPE type ,int volume, double factor, int percentage, int fastPeriod, int slowPeriod);      // ����������� CSanya
             
 void InitMonthTrade();
 void RecountFastDelta();
 void RecountSlowDelta();
 void RecountLevels(SExtremum &extr);
};

//+------------------------------------------------------------------+
//| ����������� CDinya.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::CSanya(int deltaFast, int deltaSlow, int fastDeltaStep, int slowDeltaStep, int dayStep, int monthStep
                    , int stepsFromStartToExtremum, int stepsFromStartToExit, int stepsFromExtremumToExtremum
                    , ENUM_ORDER_TYPE type ,int volume, double factor, int percentage, int fastPeriod, int slowPeriod)
  {
   _deltaFastBase = deltaFast;
   _deltaSlowBase = deltaSlow;
   _fastDeltaStep = fastDeltaStep;
   _slowDeltaStep = slowDeltaStep;
   _dayStep = dayStep*Point();
   _monthStep = monthStep;
   _stepsFromStartToExtremum = stepsFromStartToExtremum;
   _stepsFromStartToExit = stepsFromStartToExit;
   _stepsFromExtremumToExtremum = stepsFromExtremumToExtremum;
   _fastPeriod = fastPeriod;
   _slowPeriod = slowPeriod;
   _type = type;
   _volume = volume;
   _factor = factor;
   _percentage = percentage;
  
   _last_time = TimeCurrent() - _fastPeriod*60*60;       // �������������� ���� ������� ����
   _last_month_number = TimeCurrent() - _slowPeriod*24*60*60;    // �������������� ����� ������� �������
   _comment = "";        // ����������� ����������
   
   _isDayInit = false;
   _isMonthInit = false;
   _symbol = Symbol();   // ��� �����������, �� ��������� ������ �������� �������
   _period = Period();   // ������ �������, �� ��������� ������ �������� �������
   currentPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
   
   _direction = (_type == ORDER_TYPE_BUY) ? 1 : -1;

   num0.direction = 0;
   num0.price = currentPrice;
   num1.direction = 0;
   num1.price = currentPrice;
   num2.direction = 0;
   num2.price = currentPrice;
   num3.direction = 0;
   num3.price = currentPrice;
   
   _averageLeft = 0;
   _averageRight = 0;
   _average = 0;
   _averageMax = 0;
   _averageMin = 0;
   _startDayPrice = 0;
   
   startLine.Create(_startDayPrice, "startLine", clrBlue);
   //lowLine.Create(_low, "lowLine");
   //highLine.Create(_high, "highLine");
   averageRightLine.Create(_averageRight, "aveRightLine", clrRed);
   averageLeftLine.Create(_averageLeft, "aveLeftLine", clrRed);
   averageMaxLine.Create(_averageMax, "aveMaxLine", clrAqua);
   averageMinLine.Create(_averageMin, "aveMinLine", clrAqua);
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
  PrintFormat("%s ����� ����� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(_last_month_number));
  currentPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
  
  _deltaFast = _deltaFastBase;
  _fastDeltaChanged = true;
  _deltaSlow = _deltaSlowBase;
  _slowDeltaChanged = true;
  
  // ���� ������ �������
  if (_averageLeft > 0 && _averageRight > 0)
  {
   _startDayPrice = (_averageLeft + _averageRight)/2;
  }
  else
  {
   _startDayPrice = currentPrice; 
  }
  startLine.Price(0, _startDayPrice);
  //lowLine.Price(0, _low);
  //highLine.Price(0, _high);
  _isMonthInit = true;
 }
}

//+------------------------------------------------------------------+
//| �������� �������� ������                                         |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::RecountFastDelta()
{
 SymbolInfoTick(_symbol, tick);
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
 SExtremum extr = isExtremum();
 if (extr.direction != 0)
 {
  RecountLevels(extr);
 }
 
 //------------------------------
 // ������� �������
 //------------------------------
 priceAB = (_direction == 1) ? tick.ask : tick.bid; 
 if (_deltaFast < 100) // �� ��� �� "����������"
 {
  bool flag = false;
  if (num0.direction == 0)
  {
   if (_type == ORDER_TYPE_SELL && GreatDoubles(currentPrice, _startDayPrice + _stepsFromStartToExit*_dayStep)) // �� �������, � ���� ���� �����
   {
    PrintFormat("�� �������, � ���� ����� ����� �� ������ � ������ %d �����", _stepsFromStartToExit);
    flag = true;
   }
   if (_type == ORDER_TYPE_BUY && LessDoubles(currentPrice, _startDayPrice - _stepsFromStartToExit*_dayStep))  // ��� �� ��������, � ���� ���� ����
   {
    PrintFormat("�� ��������, � ���� ����� ���� �� ������ � ������ %d �����", _stepsFromStartToExit);
    flag = true;
   }
  }
  
  if (_type == ORDER_TYPE_SELL && GreatDoubles(currentPrice, _averageMax + _stepsFromStartToExit*_dayStep))
  {
   PrintFormat("�� �������, � ���� ���� ����� � ������ %d �����", _stepsFromStartToExit);
   flag = true;
  }
  if (_type == ORDER_TYPE_BUY && LessDoubles(currentPrice, _startDayPrice - _stepsFromStartToExit*_dayStep))  // ��� �� ��������, � ���� ���� ����
  {
   PrintFormat("�� ��������, � ���� ���� ���� � ������ %d �����", _stepsFromStartToExit);
   flag = true;
  }
  
  if (_average > 0 && _direction*(_average - _startDayPrice) > 0 &&                     // ���� ������� ��� ��������� �� ������ ����(����) ���������
      _direction*(priceAB - _average) < 0 && _direction*(priceAB - _startDayPrice) > 0) // ���� ������ ����� ������� ����(�����) ���� ����(����) ���������
  {
   PrintFormat("���� ���������� �������� � ������ ���� ����� �������");
   flag = true;
  }
  if (_average > 0 && _direction*(_startDayPrice - _average) > 0 && // ���� ������� ��� ��������� �� ������ ����(����) ���������
      _direction*(priceAB - _average) < 0 && _direction*(priceAB - num0.price) <= 0) // ���� ������ ����� ������� �����(����) 
  {
   PrintFormat("���� ������ ����� ����� ������ ������� � ��������� �� �������");
   flag = true;
  }    
  if (flag)
  {
   Print("����������� ������� ������ - ��������");
   _deltaFast = _deltaFast + _fastDeltaStep;   // �������� ������� ������ (���� ���� ������ ���������� ����������� - ��������)
   _fastDeltaChanged = true;
  }
 }
 
 //------------------------------
 // ������� ������
 //------------------------------ 
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 if (_deltaFast > 0)  // �� ����������
 {
  bool flag = false;
  if (num0.direction == 0 && GreatDoubles(priceAB, _startDayPrice, 5))
  { 
   Print("���� �� ������ ���� ������ ���, ����� ������������ � ������ �����");
   flag = true;
  }
  if ((_average > 0 && _direction*(_average - _startDayPrice) < 0 &&  // ���� ������� ��� ��������� �� ������ ����(����) ���������
      _direction*(priceAB - _average) > 0 && _direction*(priceAB - _startDayPrice) < 0)) // ���� ������ ����� ������� �����(����) ���� ���� ���������
  {
   Print("���� ���������� �������, ������������ � ������ ������ �������");
   flag = true;
  }    
  if (_average > 0 && _direction*(_average - _startDayPrice) > 0 &&    // ���� ������� ��� ��������� �� ������ ����(����) ���������
      _direction*(priceAB - _average) > 0 && _direction*(priceAB - num0.price) >= 0)
  {
   Print("�� ���������, ���� ���� ������ ���, ������������ � ������ ������� - ��������� ��. ������.");
   flag = true;
  }
  if (flag)
  {
   Print("��������� ������� ������ - ���������� ���������");
   _deltaFast = _deltaFast - _fastDeltaStep;   // �������� ������� ������ (���� ����� � ���� ������� - ���������� ����)
   _fastDeltaChanged = true;
  }
 }
}

//+------------------------------------------------------------------+
//| �������� �������� �������� ������                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::RecountSlowDelta()
{
 double currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);

 if (_direction*(_deltaSlow - 50) < 50 && GreatDoubles(currentPrice, _prevMonthPrice + _monthStep*Point()))
 {
   _prevMonthPrice = currentPrice;

  if (_direction < 0 && _deltaSlow < _deltaSlowBase) // ���� ������ ���� � ����� ����������� � ���������� ����� 
  {
   _deltaSlow = _deltaSlowBase;                      // - ��������� ����� �������
  }
  else
  {
   _deltaSlow = _deltaSlow + _direction*_slowDeltaStep;
  }
  _slowDeltaChanged = true;
  //PrintFormat("%s ����� �������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
 }
 
 if ((_direction*_deltaSlow + 50) > (_direction*50) && LessDoubles(currentPrice, _prevMonthPrice - _monthStep*Point()))
 {
  _prevMonthPrice = currentPrice;
  
  if (_direction > 0 && _deltaSlow > _deltaSlowBase) // ���� ������ ���� � ����� ����������� � ���������� ����� 
  {
   _deltaSlow = _deltaSlowBase;                      // - ��������� ����� �������
  }
  else
  {
   _deltaSlow = _deltaSlow - _direction*_slowDeltaStep;
  }
  //PrintFormat("%s ����� �������� ������ %d", MakeFunctionPrefix(__FUNCTION__), _deltaSlow);
  _slowDeltaChanged = true;
 }
}

//+------------------------------------------------------------------+
//| �������� ���� ������ �������                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSanya::RecountLevels(SExtremum &extr)
{
 // ��������� ������� ���������� 
 currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 if (extr.direction != 0)
 {
  if (extr.direction == num0.direction) // ���� ����� ��������� � ��� �� ����������, ��� ������
  {
   num0.price = extr.price;
  }
  else
  {
   num3 = num2;
   num2 = num1;
   num1 = num0;
   num0 = extr;
   PrintFormat("�������� ���������� num0={%d, %.05f}, num1={%d, %.05f}, num2={%d, %.05f}, num3={%d, %.05f}",
                                                                                           num0.direction, num0.price,
                                                                                           num1.direction, num1.price,
                                                                                           num2.direction, num2.price,
                                                                                           num3.direction, num3.price);
  }
  
  // ���� ��������� ������ �� ����� ������ ������ ��� �� _countStepsToExtremum �����, �� ����� ����� ������
  if (num0.direction*(num0.price - (_startDayPrice + num0.direction*_stepsFromStartToExtremum*_dayStep)) > 0)
  {
   _startDayPrice = num0.price - num0.direction*_stepsFromStartToExtremum*_dayStep;
   startLine.Price(0, _startDayPrice);
   //Print("��������� ����� ������ - ��������� ����� StartPrice=",_startDayPrice);
  }
  
  // ��������� ������� ����� ������ � ������ ������������
  if (num1.direction != 0)
  {
   _averageRight = NormalizeDouble((num0.price + num1.price)/2, 5);
   averageRightLine.Price(0, _averageRight);
  }
  
  // ��������� ������� ����� ������ � ������� ������������
  if (num2.direction != 0)
  {
   _averageLeft = NormalizeDouble((num1.price + num2.price)/2, 5);
   averageLeftLine.Price(0, _averageLeft);
  }
  
  // ���� ���� ��� �������, ��������� ����� ������ ����� ����
  if (_averageLeft > 0 && _averageRight > 0)
  {
   double _newStartDayPrice = NormalizeDouble((_averageLeft + _averageRight)/2, 5);
   // ���� ����� ����� ��������� ������ _countStepsToExtremum ����� �� ����������, �� ������ ��� �� ���������� _countStepsToExtremum
   if (GreatDoubles(num0.direction*(num0.price - _newStartDayPrice), _stepsFromStartToExtremum*_dayStep, 5))
   {
    _startDayPrice = num0.price - num0.direction*_stepsFromStartToExtremum*_dayStep;
   }
   // ���� ���������� ������, �� ������� �������; ��������� ������ ���� ������� ������ ����
   else
   {
    double dif = MathAbs(_newStartDayPrice - _startDayPrice);
    if (dif > _dayStep)
    {
     _startDayPrice = _newStartDayPrice;
     startLine.Price(0, _startDayPrice);
     //Print("��������� ��� ������� - ��������� ����� StartPrice=",_startDayPrice);
    }
   }
  }
    
  if (extr.direction > 0)
  {
   _averageMax = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // �������� ������� �������� ����� ������� ����� � ����� ������ ������
   if (LessDoubles (_averageMax, _startDayPrice + _dayStep, 5)) _averageMax = 0; 
   _averageMin = 0;
   averageMaxLine.Price(0, _averageMax);
   averageMinLine.Price(0, _averageMin);
  }
  if (extr.direction < 0)
  {
   _averageMin = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // �������� ������� �������� ����� ������� ����� � ����� ������ ������
   if (GreatDoubles (_averageMin, _startDayPrice - _dayStep, 5)) _averageMin = 0; 
   _averageMax = 0;
   averageMaxLine.Price(0, _averageMax);
   averageMinLine.Price(0, _averageMin);
  }
 }
 
 if (_averageMax > 0)  _average = _averageMax;
 else if (_averageMin > 0)  _average = _averageMin;
      else _average = 0;
}

//+--------------------------------------------------------------------+
//| ������� ���������� ����������� � �������� ���������� � ����� vol2  |
//+--------------------------------------------------------------------+
SExtremum CSanya::isExtremum()
{
 SExtremum result = {0,0};
 currentPrice = SymbolInfoDouble(_symbol, SYMBOL_LAST);
 SymbolInfoTick(_symbol, tick);
 double ask = tick.ask, bid = tick.bid;
 
 if (((num0.direction == 0) && (GreatDoubles(bid, _startDayPrice + 2*_dayStep, 5))) // ���� ����������� ��� ��� � ���� 2 ���� �� ��������� ����
 || (num0.direction > 0 && (GreatDoubles(bid, num0.price, 5)))
 || (num0.direction < 0 && (GreatDoubles(bid, num0.price + _stepsFromExtremumToExtremum*_dayStep, 5))))
 {
  result.direction = 1;
  result.price = bid;
 }
 
 if (((num0.direction == 0) && (LessDoubles(ask, _startDayPrice - 2*_dayStep, 5))) // ���� ����������� ��� ��� � ���� 2 ���� �� ��������� ����
 || (num0.direction < 0 && (LessDoubles(ask, num0.price, 5)))
 || (num0.direction > 0 && (LessDoubles(ask, num0.price - _stepsFromExtremumToExtremum*_dayStep, 5))))
 {
  result.direction = -1;
  result.price = ask;
 }

 return(result);
}