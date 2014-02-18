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

enum ENUM_LEVELS
{
 LEVEL_MINIMUM,
 LEVEL_AVEMIN,
 LEVEL_START,
 LEVEL_AVEMAX,
 LEVEL_MAXIMUM
};

string LevelToString(ENUM_LEVELS level)
{
 string res;
 switch (level)
 {
  case LEVEL_MAXIMUM:
   res = "level maximum";
   break;
  case LEVEL_MINIMUM:
   res = "level minimum";
   break;
  case LEVEL_AVEMAX:
   res = "level ave_max";
   break;
  case LEVEL_AVEMIN:
   res = "level ave_min";
   break;
  case LEVEL_START:
   res = "level start";
   break;
 }
 return res;
}
//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CSanya: public CBrothers
{
protected:
 double _trailingDeltaStep; // �������� ������� �� ������, ����� �� ���� �����������
 
 double _average;      // ���������� �� _averageMax � _averageMin ������� � ����� ������� �� ������ ������� ����
 double _averageMax;   // ������� ����� ���������� � �������
 double _averageMin;   // ������� ����� ��������� � �������
 double _averageRight; // ������� ����� ������ � ������ �����������
 double _averageLeft;  // ������� ����� ������ � ������� �����������
 int _stepsFromStartToExtremum;
 int _stepsFromStartToExit;
 int _stepsFromExtremumToExtremum;
 double currentPrice, priceAB, priceHL;
 ENUM_LEVELS _currentEnterLevel; // ������� ������� �����
 ENUM_LEVELS _currentExitLevel;  // ������� ������� ������
 
 SExtremum num0, num1, num2, num3, extremumStart;
 bool first, second, third;
 int _firstAdd, _secondAdd, _thirdAdd;
 
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
 void CSanya(int deltaFast, int deltaSlow, int dayStep, int monthStep
             , int stepsFromStartToExtremum, int stepsFromStartToExit, int stepsFromExtremumToExtremum
             , ENUM_ORDER_TYPE type ,int volume
             , int firstAdd, int secondAdd, int thirdAdd
             , int fastDeltaStep = 100, int slowDeltaStep = 10
             , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30, int trailingDeltaStep = 30);  // ����������� ����
             
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
                    , int stepsFromStartToExtremum, int stepsFromStartToExit, int stepsFromExtremumToExtremum
                    , ENUM_ORDER_TYPE type ,int volume
                    , int firstAdd, int secondAdd, int thirdAdd
                    , int fastDeltaStep = 100, int slowDeltaStep = 10
                    , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30, int trailingDeltaStep = 30)  // ����������� ����
  {
   _factor = 0.01;
   _deltaFastBase = deltaFast;
   _deltaSlowBase = deltaSlow;
   
   _deltaFast = _deltaFastBase;
   _deltaSlow = _deltaSlowBase;
   _slowDeltaChanged = true;

   _fastDeltaStep = fastDeltaStep;
   _slowDeltaStep = slowDeltaStep;
   _firstAdd = firstAdd; _secondAdd = secondAdd; _thirdAdd = thirdAdd;
   
   _trailingDeltaStep = trailingDeltaStep*_factor;
   _dayStep = dayStep*Point();
   _monthStep = monthStep;
   _stepsFromStartToExtremum = stepsFromStartToExtremum;
   _stepsFromStartToExit = stepsFromStartToExit;
   _stepsFromExtremumToExtremum = stepsFromExtremumToExtremum;
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

   num0.direction = 0;
   num0.price = currentPrice;
   //Print("num0.price=",num0.price);
   num1.direction = 0;
   num1.price = currentPrice;
   num2.direction = 0;
   num2.price = currentPrice;
   num3.direction = 0;
   num3.price = currentPrice;
   
   first = true; second = true; third = true;
   
   _startDayPrice = currentPrice; 
   _averageLeft = 0;
   _averageRight = 0;
   _average = 0;
   _averageMax = _startDayPrice + _dayStep;
   _averageMin = _startDayPrice - _dayStep;
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
  /*
  // ���� ������ �������
  if (_averageLeft <= 0 && _averageRight <= 0)
  {
   _startDayPrice = currentPrice; 
   _deltaFast = 60;
   _fastDeltaChanged = true;
   Print("_startDayPrice=",_startDayPrice);
  }
  startLine.Price(0, _startDayPrice);
  //lowLine.Price(0, _low);
  //highLine.Price(0, _high);
  _isMonthInit = true;
  Print("_deltaFast=",_deltaFast);*/
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
    //_currentEnterLevel = LEVEL_START;
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
      PrintFormat("���� ������� ������� ������ %s, ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
      _currentEnterLevel = LEVEL_AVEMAX;
      flag = true;
     }
     break;
    case LEVEL_AVEMAX:
     currentExitPrice = _average;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("���� ������� ������� ������ %s, ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
      _currentEnterLevel = (_direction == 1) ? LEVEL_MAXIMUM : LEVEL_START;
      flag = true;
     }
     break;
    case LEVEL_START:
     currentExitPrice = _startDayPrice;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("���� ������� ������� ������ %s, ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
      _currentEnterLevel = (_direction == 1) ? LEVEL_AVEMAX : LEVEL_AVEMIN;
      flag = true;
     }
     break;
    case LEVEL_AVEMIN:
     currentExitPrice = _average;
     //PrintFormat("������� ������� ������ %s, ���� ������=%.05f, ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice, priceAB);
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("���� ������� ������� ������ %s, ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
      _currentEnterLevel = (_direction == 1) ? LEVEL_START : LEVEL_MINIMUM;
      flag = true;
     }
     break;
    case LEVEL_MINIMUM:
     currentExitPrice = (num0.direction > 0) ? num1.price : num0.price;
     if (_direction*(priceAB - currentExitPrice) <= 0)
     {
      PrintFormat("���� ������� ������� ������ %s, ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
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
   extremumStart = (num0.direction == _direction) ? num0 : num1;
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
    currentEnterPrice = _average;
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
    currentEnterPrice = _average;
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
  
  if (flag)
  {
   Print("��������� ������� ������ - ���������� ��������� ");
   _deltaFast = _deltaFastBase;   // �������� ������� ������ (���� ����� � ���� ������� - ���������� ����)
   _fastDeltaChanged = true;
  }
 }
 
  //-------------------------
  // �������� �� �������
  //-------------------------
 if (extremumStart.direction == _direction && _deltaFast > 0 && _deltaFast < 100)
 {
  if (LessDoubles(_direction*extremumStart.price + 0.33*_dayStep, _direction*priceAB) && first)
  {
   Print("������ �������");
   first = false;
   _deltaFast = _deltaFast - _firstAdd;
   _fastDeltaChanged = true;
  }
  if (LessDoubles(_direction*extremumStart.price + _stepsFromStartToExtremum*_dayStep/2, _direction*priceAB) && second)
  {
   Print("������ �������");
   second = false;
   _deltaFast = _deltaFast - _secondAdd;
   _fastDeltaChanged = true;
  }
  if (LessDoubles(_direction*extremumStart.price + _stepsFromStartToExtremum*_dayStep, _direction*priceAB) && third)
  {
   Print("������ �������");
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
   extremumStart = extr;
   PrintFormat("�������� ���������� num0={%d, %.05f}, num1={%d, %.05f}, num2={%d, %.05f}, num3={%d, %.05f}",
                                                                                           num0.direction, num0.price,
                                                                                           num1.direction, num1.price,
                                                                                           num2.direction, num2.price,
                                                                                           num3.direction, num3.price);
  }
  
 //-------------------------------------------------
 // ���������� ����� ������
 //-------------------------------------------------
 
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
    startLine.Price(0, _startDayPrice);
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
 //-------------------------------------------------
 //-------------------------------------------------
 
 //-------------------------------------------------
 // ��������� ������� ��������
 //-------------------------------------------------
  if (extr.direction > 0)
  {
   _average = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // �������� ������� �������� ����� ������� ����� � ����� ������ ������
   if (GreatDoubles (_averageMax, _startDayPrice + _dayStep, 5)) _averageMax = _average; 
  }
  if (extr.direction < 0)
  {
   _average = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // �������� ������� �������� ����� ������� ����� � ����� ������ ������
   if (LessDoubles (_averageMin, _startDayPrice - _dayStep, 5)) _averageMin = _average; 
   //PrintFormat("����� ��������� ���� = %.05f, ����������� ������� aveMin=%.05f", extr.price, _averageMin);
  }
 }
 
 if (_averageMax > 0 && _average != _averageMax)
 {
  _average = _averageMax;
  averageMaxLine.Price(0, _averageMax);
  //PrintFormat("����� ������� aveMax=%.05f", _averageMax);
  _averageMin = 0; _averageMax = 0;
  averageMinLine.Price(0, _averageMin);
  if (_type == ORDER_TYPE_BUY)
  {
   _currentEnterLevel = LEVEL_MAXIMUM;
   _currentExitLevel = LEVEL_AVEMAX;
   PrintFormat("����� ������� ����� %s � ������ %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
  }
  else
  {
   _currentEnterLevel = LEVEL_AVEMAX;
   _currentExitLevel = LEVEL_MAXIMUM;
   PrintFormat("����� ������� ����� %s � ������ %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
  }
 }
 else if (_averageMin > 0)
      {
       _average = _averageMin;
       averageMinLine.Price(0, _averageMin);
       //PrintFormat("����� ������� aveMin=%.05f", _average);
       _averageMin = 0; _averageMax = 0;
       averageMaxLine.Price(0, _averageMax);
       if (_type == ORDER_TYPE_BUY)
       {
        _currentEnterLevel = LEVEL_AVEMIN;
        _currentExitLevel = LEVEL_MINIMUM;
        PrintFormat("����� ������� ����� %s � ������ %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
       }
       else
       {
        _currentEnterLevel = LEVEL_MINIMUM;
        _currentExitLevel = LEVEL_AVEMIN;
        PrintFormat("����� ������� ����� %s � ������ %s", LevelToString(_currentEnterLevel), LevelToString(_currentExitLevel));
       }
      }
      //else _average = 0;
 //-------------------------------------------------
 //-------------------------------------------------
      
 //-------------------------------------------------
 // ��������� ������ �����
 //-------------------------------------------------
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 switch (_currentEnterLevel)
 {
  case LEVEL_MAXIMUM:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_averageMax, priceAB + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ����(����) �������� �������� �� 1/3 ����
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_AVEMAX;
    PrintFormat("���� (%.05f) ������ ���� �������� ��������(%.05f) �� 1/3 ����(%.05f) ����� ������� ����� ",priceAB, _average, _trailingDeltaStep*_dayStep, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_startDayPrice, priceAB + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_START;
    PrintFormat("���� (%.05f) ������ ���� ����� ������(%.05f) �� 1/3 ����(%.05f) ����� ������� ����� ",priceAB, _startDayPrice, _trailingDeltaStep*_dayStep, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_START:
   if (_type == ORDER_TYPE_BUY && GreatDoubles(_average, priceAB + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ����(����) �������� �� 1/3 ����
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_AVEMIN;
    PrintFormat("���� (%.05f) ������ ���� ������� ��������(%.05f) �� 1/3 ����(%.05f) ����� ������� ����� ",priceAB, _average, _trailingDeltaStep*_dayStep, LevelToString(_currentEnterLevel));
   }
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB - _trailingDeltaStep*_dayStep, _average)) 
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_AVEMAX;
    PrintFormat("���� (%.05f) ������ ���� �������� ��������(%.05f) �� 1/3 ����(%.05f) ����� ������� ����� ",priceAB, _average, _trailingDeltaStep*_dayStep, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB - _trailingDeltaStep*_dayStep, _startDayPrice)) // ���� ������ ����(����) ������ �� 1/3 ����
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_START;
    PrintFormat("���� (%.05f) ������ ���� ����� ������(%.05f) �� 1/3 ����(%.05f) ����� ������� ����� ",priceAB, _startDayPrice, _trailingDeltaStep*_dayStep, LevelToString(_currentEnterLevel));
   }
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(priceAB - _trailingDeltaStep*_dayStep, _average))  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    PrintFormat("���. ������� ����� %s", LevelToString(_currentEnterLevel));
    _currentEnterLevel = LEVEL_AVEMIN;
    PrintFormat("���� (%.05f) ������ ���� ������� ��������(%.05f) �� 1/3 ����(%.05f) ����� ������� ����� ",priceAB, _average, _trailingDeltaStep*_dayStep, LevelToString(_currentEnterLevel));
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
   if (_type == ORDER_TYPE_SELL && 
       GreatDoubles(_average, priceAB + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ����(����) �������� �� 1/3 ����
   {
    _currentExitLevel = LEVEL_AVEMAX;
    _currentEnterLevel = LEVEL_START;
    PrintFormat("���� (%.05f) ������ ���� �������� ��������(%.05f) �� 1/3 ����(%.05f) ����� ������� ������ %s", priceAB, _average, _trailingDeltaStep*_dayStep, LevelToString(_currentExitLevel));
   }
   //Print("������� ������ ", LevelToString(_currentExitLevel));
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(_startDayPrice, priceAB + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    _currentExitLevel = LEVEL_START;
    _currentEnterLevel = LEVEL_AVEMIN;
    PrintFormat("���� (%.05f) ������ ���� ����� ������(%.05f) �� 1/3 ����(%.05f) ����� ������� ������ %s", priceAB, _startDayPrice, _trailingDeltaStep*_dayStep, LevelToString(_currentExitLevel));
   }
   break;
  case LEVEL_START:
   if (_type == ORDER_TYPE_SELL && GreatDoubles(_average, priceAB + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ����(����) �������� �� 1/3 ����
   {
    _currentExitLevel = LEVEL_AVEMIN;
    _currentEnterLevel = LEVEL_MINIMUM;
    PrintFormat("���� (%.05f) ������ ���� ������� ��������(%.05f) �� 1/3 ����(%.05f) ����� ������� ������ %s", priceAB, _average, _trailingDeltaStep*_dayStep, LevelToString(_currentExitLevel));
   }
   if (_type == ORDER_TYPE_BUY && LessDoubles(_average + _trailingDeltaStep*_dayStep, priceAB, 5)) 
   {
    _currentExitLevel = LEVEL_AVEMAX;
    _currentEnterLevel = LEVEL_MAXIMUM;
    PrintFormat("���� (%.05f) ������ ���� �������� ��������(%.05f) �� 1/3 ����(%.05f) ����� ������� ������ %s", priceAB, _average, _trailingDeltaStep*_dayStep, LevelToString(_currentExitLevel));
   }
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_BUY && LessDoubles(_startDayPrice + _trailingDeltaStep*_dayStep, priceAB, 5))  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    _currentExitLevel = LEVEL_START;
    _currentEnterLevel = LEVEL_AVEMAX;
    PrintFormat("���� (%.05f) ������ ���� ����� ������(%.05f) �� 1/3 ����(%.05f) ����� ������� ������ %s", priceAB, _startDayPrice, _trailingDeltaStep*_dayStep, LevelToString(_currentExitLevel));
   }
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_BUY && 
       GreatDoubles(priceAB, _average + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ���� ������� �������� �� 1/3 ����
   {
    _currentExitLevel = LEVEL_AVEMIN;
    _currentEnterLevel = LEVEL_START;
    PrintFormat("���� (%.05f) ������ ���� ������� ��������(%.05f) �� 1/3 ����(%.05f) ����� ������� ������ %s", priceAB, _average, _trailingDeltaStep*_dayStep, LevelToString(_currentExitLevel));
   }
   //PrintFormat("������� ������ %s _averageMin=%.05f, priceAB=%.05f, ", LevelToString(_currentExitLevel), _averageMin + _trailingDeltaStep*_dayStep, priceAB);
  break;
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