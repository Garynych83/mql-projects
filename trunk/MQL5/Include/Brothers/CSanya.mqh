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

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CSanya: public CBrothers
{
protected:
 double _average;      // ���������� �� _averageMax � _averageMin ������� � ����� ������� �� ������ ������� ����
 double _averageMax;   // ������� ����� ���������� � �������
 double _averageMin;   // ������� ����� ��������� � �������
 int _minStepsFromStartToExtremum;
 int _maxStepsFromStartToExtremum;
 int _stepsFromStartToExit;
 double currentPrice, priceAB, priceHL;
 ENUM_LEVELS _currentEnterLevel; // ������� ������� �����
 ENUM_LEVELS _currentExitLevel;  // ������� ������� ������
 
 SExtremum num0, num1, num2, num3;
 double dealStartPrice;
 
 bool first, second, third;
 int _firstAdd, _secondAdd, _thirdAdd;
 
 CTradeLine startLine;
 CTradeLine lowLine;
 CTradeLine highLine;
 CTradeLine averageMaxLine;
 CTradeLine averageMinLine;

 SExtremum isExtremum();
public:
//--- ������������
 void CSanya(){};
 void CSanya(int deltaFast, int deltaSlow, int dayStep, int monthStep
             , int minStepsFromStartToExtremum, int maxStepsFromStartToExtremum, int stepsFromStartToExit
             , ENUM_ORDER_TYPE type ,int volume
             , int firstAdd, int secondAdd, int thirdAdd
             , int fastDeltaStep = 100, int slowDeltaStep = 10
             , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30);  // ����������� ����
             
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
void CSanya::CSanya(int deltaFast, int deltaSlow,  int dayStep, int monthStep
                    , int minStepsFromStartToExtremum, int maxStepsFromStartToExtremum, int stepsFromStartToExit
                    , ENUM_ORDER_TYPE type ,int volume
                    , int firstAdd, int secondAdd, int thirdAdd
                    , int fastDeltaStep = 100, int slowDeltaStep = 10
                    , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30)  // ����������� ����
  {
   _factor = 0.01;
   _deltaFastBase = deltaFast;
   _deltaSlowBase = deltaSlow;
   
   _deltaFast = 100 - _deltaFastBase;
   _deltaSlow = _deltaSlowBase;
   _slowDeltaChanged = true;

   _fastDeltaStep = fastDeltaStep;
   _slowDeltaStep = slowDeltaStep;
   _firstAdd = firstAdd; _secondAdd = secondAdd; _thirdAdd = thirdAdd;
   
   _dayStep = dayStep*Point();
   _monthStep = monthStep;
   _minStepsFromStartToExtremum = minStepsFromStartToExtremum;
   _maxStepsFromStartToExtremum = maxStepsFromStartToExtremum;
   _stepsFromStartToExit = stepsFromStartToExit;
   _fastPeriod = fastPeriod;
   _slowPeriod = slowPeriod;
   _type = type;
   _volume = volume;
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
   first = true; second = true; third = true;
   
   _startDayPrice = currentPrice; 
   _average = 0;
   _averageMax = _startDayPrice + _dayStep;
   _averageMin = _startDayPrice - _dayStep;
   
   num0.direction = 0;
   num0.price = currentPrice;
   num1.direction = 0;
   num1.price = currentPrice;
   num2.direction = 0;
   num2.price = currentPrice;
   num3.direction = 0;
   num3.price = currentPrice;
   
   dealStartPrice = _startDayPrice;
   
   if (_type == ORDER_TYPE_BUY)
   {
    _currentEnterLevel = LEVEL_START;
    _currentExitLevel = LEVEL_MINIMUM;
   }
   else
   {
    _currentEnterLevel = LEVEL_START;
    _currentExitLevel = LEVEL_MAXIMUM;
   }
   startLine.Create(_startDayPrice, "startLine", clrBlue);
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
 currentPrice = SymbolInfoDouble(_symbol, SYMBOL_BID);
 SExtremum extr = isExtremum();
 RecountLevels(extr);
 
 //------------------------------
 // ������� �������
 //------------------------------
 priceAB = (_direction == 1) ? tick.ask : tick.bid; 
 if (_deltaFast < 100) // �� ��� �� "����������"
 {
  bool flag = false;
  if (num0.direction == 0)
  {
   if (LessDoubles(_direction*currentPrice, _direction*_startDayPrice - _stepsFromStartToExit*_dayStep)) // ���� ���� ������� ������ ��� _stepsFromStartToExit �����
   {
    PrintFormat("��� ������ %s, ���� ���� ������ ��� �� ������ � ������ %d �����", OrderTypeToString(_type), _stepsFromStartToExit);
    flag = true;
   }
  }
  if (num0.direction != 0)
  {
   double currentExitPrice;
   switch (_currentExitLevel)
   {
    case LEVEL_MAXIMUM:
     currentExitPrice = (num0.direction < 0) ? num1.price : num0.price;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("���� ������� ������� ������ %s(%.05f), ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentEnterLevel = LEVEL_AVEMAX;
      flag = true;
     }
     break;
    case LEVEL_AVEMAX:
     currentExitPrice = _averageMax;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("���� ������� ������� ������ %s(%.05f), ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentEnterLevel = (_direction == 1) ? LEVEL_MAXIMUM : LEVEL_START;
      flag = true;
     }
     break;
    case LEVEL_START:
     currentExitPrice = _startDayPrice;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("���� ������� ������� ������ %s(%.05f), ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentEnterLevel = (_direction == 1) ? LEVEL_AVEMAX : LEVEL_AVEMIN;
      flag = true;
     }
     break;
    case LEVEL_AVEMIN:
     currentExitPrice = _averageMin;
     //PrintFormat("������� ������� ������ %s, ���� ������=%.05f, ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("���� ������� ������� ������ %s(%.05f), ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentEnterLevel = (_direction == 1) ? LEVEL_START : LEVEL_MINIMUM;
      flag = true;
     }
     break;
    case LEVEL_MINIMUM:
     currentExitPrice = (num0.direction > 0) ? num1.price : num0.price;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("���� ������� ������� ������ %s(%.05f), ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
      _currentEnterLevel = LEVEL_AVEMIN;
      flag = true;
     }
     break;
   }
  }
  
  if (flag)
  {
   Print("����������� ������� ������ - ��������");
   _deltaFast = 100;   // �������� ������� ������ (���� ���� ������ ���������� ����������� - ��������)
   _fastDeltaChanged = true;
   first = true; second = true; third = true;
   
   //extremumStart = (num0.direction == _direction) ? num0 : num1;  ///ToDo ��������� � ��� ��������!!!
   //PrintFormat("direction =%d, price=%.05f",extremumStart.direction, extremumStart.price);
  }
 }
 
 //------------------------------
 // ������� ������
 //------------------------------ 
 SymbolInfoTick(_symbol, tick);
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 if (_deltaFast == 100)  // �� ����������
 {
  bool flag = false;
  if (num0.direction == 0 && GreatDoubles(priceAB, _startDayPrice, 5))
  { 
   Print("���� �� ������ ���� ������ ���, ����� ������������ � ������ �����");
   flag = true;
   _currentExitLevel = (_type == ORDER_TYPE_BUY) ? LEVEL_AVEMAX : LEVEL_AVEMIN;
  }
  
  if (num0.direction != 0)
  {
   double currentEnterPrice;
   switch (_currentEnterLevel)
   {
    case LEVEL_MAXIMUM:
     currentEnterPrice = (num0.direction > 0) ? num0.price : num1.price;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // ���� ������� ������� �����
     {
      PrintFormat("���� ������� ������� ����� %s=%.05f, ����=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = LEVEL_AVEMAX;
      flag = true;
     }
     break;
    case LEVEL_AVEMAX:
     currentEnterPrice = _averageMax;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // ���� ������� ������� �����
     {
      PrintFormat("���� ������� ������� ����� %s=%.05f, ����=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = (_direction == 1) ? LEVEL_START : LEVEL_MAXIMUM;
      flag = true;
     }
     break;
    case LEVEL_START:
     currentEnterPrice = _startDayPrice;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // ���� ������� ������� �����
     {
      PrintFormat("���� ������� ������� ����� %s=%.05f, ����=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = (_direction == 1) ? LEVEL_AVEMIN : LEVEL_AVEMAX;
      flag = true;
     }
     break;
    case LEVEL_AVEMIN:
     currentEnterPrice = _averageMin;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // ���� ������� ������� �����
     {
      PrintFormat("���� ������� ������� ����� %s=%.05f, ����=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = (_direction == 1) ? LEVEL_MINIMUM : LEVEL_START;
      flag = true;
     }
     break;
    case LEVEL_MINIMUM:
     currentEnterPrice = (num0.direction < 0) ? num0.price : num1.price;
     if (_direction*(priceAB - currentEnterPrice) >= 0) // ���� ������� ������� �����
     {
      PrintFormat("���� ������� ������� ����� %s=%.05f, ����=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice, priceAB);
      _currentExitLevel = LEVEL_AVEMIN;
      flag = true;
     }
     break;
   }
  }
  if (flag)
  {
   Print("��������� ������� ������ - ���������� ��������� ");
   dealStartPrice = priceAB;
   _deltaFast = 100 - _deltaFastBase;   // �������� ������� ������ (���� ����� � ���� ������� - ���������� ����)
   _fastDeltaChanged = true;
  }
 }
 
  //-------------------------
  // �������� �� �������
  //-------------------------
 if (_deltaFast > 0 && _deltaFast < 100)
 { 
  if (LessDoubles(_direction*dealStartPrice + _minStepsFromStartToExtremum*_dayStep, _direction*priceAB) && first)
  {
   PrintFormat("������ �������");
   first = false;
   _deltaFast = _deltaFast - _firstAdd;
   _fastDeltaChanged = true;
  }
  if (LessDoubles(_direction*dealStartPrice + 2*_minStepsFromStartToExtremum*_dayStep, _direction*priceAB) && second)
  {
   PrintFormat("������ �������");
   second = false;
   _deltaFast = _deltaFast - _secondAdd;
   _fastDeltaChanged = true;
  }
  if (LessDoubles(_direction*dealStartPrice + 4*_minStepsFromStartToExtremum*_dayStep, _direction*priceAB) && third)
  {
   PrintFormat("������ �������");
   third = false;
   _deltaFast = _deltaFast - _thirdAdd;
   _fastDeltaChanged = true;
  }
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
   //Print("num0.price",num0.price);
   num0.price = extr.price;
  }
  else
  {
   num3 = num2;
   num2 = num1;
   num1 = num0;
   num0 = extr;
   Print("����� ���������");
   if (num1.direction == 0)
   {
    num1.direction = -num0.direction;
    num1.price = _startDayPrice + num1.direction*_minStepsFromStartToExtremum*_dayStep;
   }
  }
  
 //-------------------------------------------------
 // ���������� ����� ������
 //-------------------------------------------------
  // ���� ��������� ������ �� ����� ������ ������ ��� �� _minStepsFromStartToExtremum �����, �� ����� ����� ������
  if (num0.direction*(num0.price - (_startDayPrice + num0.direction*_maxStepsFromStartToExtremum*_dayStep)) > 0)
  {
   _startDayPrice = num0.price - num0.direction*_maxStepsFromStartToExtremum*_dayStep;
   startLine.Price(0, _startDayPrice);
   //Print("��������� ����� ������ - ��������� ����� StartPrice=",_startDayPrice);
  }
 
 //-------------------------------------------------
 // ��������� ������� ��������
 //-------------------------------------------------
  if (extr.direction > 0)
  {
   _average = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // �������� ������� �������� ����� ������� ����� � ����� ������ ������
   if (GreatDoubles (_average, _startDayPrice + _dayStep, 5))
   {
    _averageMax = _average; 
    averageMaxLine.Price(0, _averageMax);
   }
   if (_type == ORDER_TYPE_BUY)
   {
    _currentEnterLevel = LEVEL_MAXIMUM;
    _currentExitLevel = LEVEL_AVEMAX;
    //PrintFormat("����� ������� ����� %s � ������ %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
   }
   else
   {
    _currentEnterLevel = LEVEL_AVEMAX;
    _currentExitLevel = LEVEL_MAXIMUM;
    //PrintFormat("����� ������� ����� %s � ������ %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
   }
  }
  if (extr.direction < 0)
  {
   _average = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // �������� ������� �������� ����� ������� ����� � ����� ������ ������
   if (LessDoubles (_average, _startDayPrice - _dayStep, 5))
   {
    _averageMin = _average; 
    averageMinLine.Price(0, _averageMin);
   }
   if (_type == ORDER_TYPE_BUY)
   {
    _currentEnterLevel = LEVEL_AVEMIN;
    _currentExitLevel = LEVEL_MINIMUM;
    //PrintFormat("����� ������� ����� %s � ������ %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
   }
   else
   {
    _currentEnterLevel = LEVEL_MINIMUM;
    _currentExitLevel = LEVEL_AVEMIN;
    //PrintFormat("����� ������� ����� %s � ������ %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
   } 
  }  
 }
 //-------------------------------------------------
 //-------------------------------------------------
 
 if(num0.direction != 0)
 {     
 //-------------------------------------------------
 // ��������� ������ �����
 //-------------------------------------------------
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 switch (_currentEnterLevel)
 {
  case LEVEL_MAXIMUM:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_startDayPrice, priceAB, 5))  // ���� ������ ����(����) ������
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_AVEMAX;
    PrintFormat("���� (%.05f) ������ ���� ������(%.05f) ����� ������� ����� %s",priceAB, _startDayPrice, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_averageMin, priceAB, 5))  // ���� ������ ����(����) ������� ��������
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_START;
    PrintFormat("���� (%.05f) ������ ���� ������� ��������(%.05f) ����� ������� ����� %s",priceAB, _averageMin, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB, _averageMax)) // ���� ������ ����(����) ������ �� 1/3 ����
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_START;
    PrintFormat("���� (%.05f) ������ ���� �������� ��������(%.05f) ����� ������� ����� %s",priceAB, _averageMax, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB, _startDayPrice))  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_AVEMIN;
    PrintFormat("���� (%.05f) ������ ���� ������(%.05f) ����� ������� ����� %s",priceAB, _startDayPrice, LevelToString(_currentEnterLevel));
   }
   break;
 }
 //-------------------------------------------------
 //-------------------------------------------------
 
 //-------------------------------------------------
 // ��������� ������ ������
 //-------------------------------------------------
 switch (_currentExitLevel)
 {
  case LEVEL_MAXIMUM:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(_startDayPrice, priceAB, 5))  // ���� ������ ���� ������
   {
    _currentExitLevel = LEVEL_AVEMAX;
    //_currentEnterLevel = LEVEL_START;
    PrintFormat("���� (%.05f) ������ ���� ������(%.05f) ����� ������� ������ %s", priceAB, _startDayPrice,  LevelToString(_currentExitLevel));
   }
   //Print("������� ������ ", LevelToString(_currentExitLevel));
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(_averageMin, priceAB, 5))  // ���� ������ ���� ������� ��������
   {
    _currentExitLevel = LEVEL_START;
    //_currentEnterLevel = LEVEL_AVEMIN;
    PrintFormat("���� (%.05f) ������ ���� ������� ��������(%.05f) ����� ������� ������ %s", priceAB, _averageMin, LevelToString(_currentExitLevel));
   }
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_BUY && LessDoubles(_averageMax, priceAB, 5))  // ���� ������ ���� �������� ��������
   {
    _currentExitLevel = LEVEL_START;
    //_currentEnterLevel = LEVEL_AVEMAX;
    PrintFormat("���� (%.05f) ������ ���� �������� ��������(%.05f) ����� ������� ������ %s", priceAB, _averageMax, LevelToString(_currentExitLevel));
   }
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(priceAB, _startDayPrice, 5))  // ���� ������ ���� ������
   {
    _currentExitLevel = LEVEL_AVEMIN;
    //_currentEnterLevel = LEVEL_START;
    PrintFormat("���� (%.05f) ������ ���� ����� ������(%.05f) ����� ������� ������ %s", priceAB, _startDayPrice, LevelToString(_currentExitLevel));
   }
   //PrintFormat("������� ������ %s _averageMin=%.05f, priceAB=%.05f, ", LevelToString(_currentExitLevel), _averageMin + _trailingDeltaStep*_dayStep, priceAB);
  break;
 }
 }
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
 || (num0.direction < 0 && (GreatDoubles(bid, _startDayPrice + _minStepsFromStartToExtremum*_dayStep, 5))))
 {
  result.direction = 1;
  result.price = bid;
 }
 
 if (((num0.direction == 0) && (LessDoubles(ask, _startDayPrice - 2*_dayStep, 5))) // ���� ����������� ��� ��� � ���� 2 ���� �� ��������� ����
 || (num0.direction < 0 && (LessDoubles(ask, num0.price, 5)))
 || (num0.direction > 0 && (LessDoubles(ask, _startDayPrice - _minStepsFromStartToExtremum*_dayStep, 5))))
 {
  result.direction = -1;
  result.price = ask;
 }

 return(result);
}