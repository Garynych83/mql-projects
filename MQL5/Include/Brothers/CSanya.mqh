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
 int _trailingDeltaStep; // �������� ������� �� ������, ����� �� ���� �����������
 
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
 void CSanya(int deltaFast, int deltaSlow, int dayStep, int monthStep
                    , int stepsFromStartToExtremum, int stepsFromStartToExit, int stepsFromExtremumToExtremum
                    , ENUM_ORDER_TYPE type ,int volume, int fastDeltaStep = 100, int slowDeltaStep = 10
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
                    , ENUM_ORDER_TYPE type ,int volume, int fastDeltaStep = 100, int slowDeltaStep = 10
                    , int percentage = 100, int fastPeriod = 24, int slowPeriod = 30, int trailingDeltaStep = 30)  // ����������� ����
  {
   _deltaFastBase = deltaFast;
   _deltaSlowBase = deltaSlow;
   _fastDeltaStep = fastDeltaStep;
   _slowDeltaStep = slowDeltaStep;
   _trailingDeltaStep = trailingDeltaStep;
   _dayStep = dayStep*Point();
   _monthStep = monthStep;
   _stepsFromStartToExtremum = stepsFromStartToExtremum;
   _stepsFromStartToExit = stepsFromStartToExit;
   _stepsFromExtremumToExtremum = stepsFromExtremumToExtremum;
   _fastPeriod = fastPeriod;
   _slowPeriod = slowPeriod;
   _type = type;
   _volume = volume;
   _factor = 0.01;
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
   
   _averageLeft = 0;
   _averageRight = 0;
   _average = 0;
   _averageMax = 0;
   _averageMin = 0;
   _startDayPrice = 0;
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
 RecountLevels(extr);
 //if (extr.direction != 0)
 //{
 //}
 
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
  /*
  if (_average > 0 && GreatDoubles(_direction*currentPrice, _direction*_average - _stepsFromStartToExit*_dayStep))
  {
   PrintFormat("��� ������ %s, ���� ���� ������ ��� � ������ %d ����� delta=%d", OrderTypeToString(_type), _stepsFromStartToExit, _deltaFast);
   flag = true;
  }
  */
   double currentExitPrice;
   switch (_currentExitLevel)
   {
    case LEVEL_MAXIMUM:
    case LEVEL_MINIMUM:
     currentExitPrice = num0.price;
     break;
    case LEVEL_AVEMAX:
    case LEVEL_AVEMIN:
     currentExitPrice = _average;
     break;
    case LEVEL_START:
     currentExitPrice = _startDayPrice;
     break;
   }
   if (_direction*(priceAB - currentExitPrice) <= 0)
   {
    PrintFormat("���� ������� ������� ������ %s, ����=%.05f", LevelToString(_currentExitLevel), currentExitPrice);
    flag = true;
   }
  }
  /*
  if (_average > 0 && 
      _direction*(_average - _startDayPrice) > 0 &&  // ���� ������� ��� ��������� �� ������ ����(����) ���������
      _direction*(priceAB - _average) < 0 && 
      _direction*(priceAB - _startDayPrice) > 0)     // ���� ������ ����� ������� ����(�����) ���� ����(����) ���������
  {
   PrintFormat("���� ���������� ���������, ����� ������ ������� ����� �������");
   flag = true;
  }
  
  if (_average > 0 && 
      _direction*(_startDayPrice - _average) > 0 &&  // ���� ������� ��� ��������� �� ������ ����(����) ���������
      _direction*(priceAB - _average) < 0 && 
      _direction*(priceAB - num0.price) <= 0)        // ���� ������ ����� ������� �����(����) 
  {
   PrintFormat("���� ������ ����� ����� ������ ������� � ��������� �� �������");
   flag = true;
  }
  */
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
   _currentExitLevel = (_type == ORDER_TYPE_BUY) ? LEVEL_AVEMAX : LEVEL_AVEMIN;
  }
  
  double currentEnterPrice;
  switch (_currentEnterLevel)
  {
   case LEVEL_MAXIMUM:
   case LEVEL_MINIMUM:
    currentEnterPrice = num0.price;
    break;
   case LEVEL_AVEMAX:
   case LEVEL_AVEMIN:
    currentEnterPrice = _average;
    break;
   case LEVEL_START:
    currentEnterPrice = _startDayPrice;
    break;
  }
  if (_direction*(priceAB - currentEnterPrice) >= 0) // ���� ������� ������� �����
  {
   PrintFormat("���� ������� ������� ����� %s, ����=%.05f", LevelToString(_currentEnterLevel), currentEnterPrice);
   flag = true;
  }
  /*
  if ((_average > 0 && _direction*(_average - _startDayPrice) < 0 &&  // ���� ������� ��� ��������� �� ������ ����(����) ���������
      _direction*(priceAB - _average) > 0 && _direction*(priceAB - _startDayPrice) < 0)) // ���� ������ ����� ������� �����(����) ���� ���� ���������
  {
   Print("���� ���������� �������, ������������ � ������ ������ �������");
   flag = true;
  }    
  
  if (_average > 0 && _direction*(_average - _startDayPrice) > 0 &&    // ���� ������� ��� ��������� �� ������ ����(����) ���������
      _direction*(priceAB - _average) > 0 && _direction*(priceAB - num0.price) >= 0)
  {
   Print("�� ���������, ���� ���� ������ ���, ������������ � �������� ����������");
   flag = true;
  }
  */
  
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
   //Print("num0.price",num0.price);
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
   _averageMax = NormalizeDouble((extr.price + _startDayPrice)/2, 5);   // �������� ������� �������� ����� ������� ����� � ����� ������ ������
   if (LessDoubles (_averageMax, _startDayPrice + _dayStep, 5)) _averageMax = 0; 
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
 
 if (_averageMax > 0)
 {
  _average = _averageMax;
  if (_type == ORDER_TYPE_BUY)
  {
   _currentEnterLevel = LEVEL_MAXIMUM;
   _currentExitLevel = LEVEL_AVEMAX;
  }
  else
  {
   _currentEnterLevel = LEVEL_AVEMAX;
   _currentExitLevel = LEVEL_MAXIMUM;
  }
 }
 else if (_averageMin > 0)
      {
       _average = _averageMin;
       if (_type == ORDER_TYPE_BUY)
       {
        _currentEnterLevel = LEVEL_AVEMIN;
        _currentExitLevel = LEVEL_MINIMUM;
       }
       else
       {
        _currentEnterLevel = LEVEL_MINIMUM;
        _currentExitLevel = LEVEL_AVEMIN;
       }
      }
      else _average = 0;
 //-------------------------------------------------
 //-------------------------------------------------
      
 //-------------------------------------------------
 // ��������� ������ �����/������
 //-------------------------------------------------
 priceAB = (_direction == 1) ? tick.bid : tick.ask;
 switch (_currentEnterLevel)
 {
  case LEVEL_MAXIMUM:
   if (_type == ORDER_TYPE_BUY && 
       _direction*(_averageMax - priceAB - _trailingDeltaStep*_dayStep) > 0)  // ���� ������ ����(����) �������� �� 1/3 ����
   {
    _currentEnterLevel = LEVEL_AVEMAX;
    Print("����� ������� ����� ", LevelToString(_currentEnterLevel));
   }
   //Print("������� ����� ", LevelToString(_currentEnterLevel));
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_BUY && 
       _direction*(_startDayPrice - priceAB - _trailingDeltaStep*_dayStep) > 0)  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    _currentEnterLevel = LEVEL_START;
    Print("����� ������� ����� ", LevelToString(_currentEnterLevel));
   }
   //Print("������� ����� ", LevelToString(_currentEnterLevel));
   break;
  case LEVEL_START:
   if (_type == ORDER_TYPE_BUY && 
       _direction*(_averageMin - priceAB - _trailingDeltaStep*_dayStep) > 0)  // ���� ������ ����(����) �������� �� 1/3 ����
   {
    _currentEnterLevel = LEVEL_AVEMIN;
    Print("����� ������� ����� ", LevelToString(_currentEnterLevel));
   }
   if (_type == ORDER_TYPE_SELL &&
       _direction*(_averageMax - priceAB - _trailingDeltaStep*_dayStep) > 0) 
   {
    _currentEnterLevel = LEVEL_AVEMAX;
    Print("����� ������� ����� ", LevelToString(_currentEnterLevel));
   }
   //Print("������� ����� ", LevelToString(_currentEnterLevel));
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_SELL && 
       _direction*(_startDayPrice - priceAB - _trailingDeltaStep*_dayStep) > 0)  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    _currentEnterLevel = LEVEL_START;
    Print("����� ������� ����� ", LevelToString(_currentEnterLevel));
   }
   //Print("������� ����� ", LevelToString(_currentEnterLevel));
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_SELL && 
       _direction*(_averageMin - priceAB - _trailingDeltaStep*_dayStep) > 0)  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    _currentEnterLevel = LEVEL_AVEMIN;
    Print("����� ������� ����� ", LevelToString(_currentEnterLevel));
   }
   //Print("������� ����� ", LevelToString(_currentEnterLevel));
   break;
 }
  
 switch (_currentExitLevel)
 {
  case LEVEL_MAXIMUM:
   if (_type == ORDER_TYPE_SELL && 
       GreatDoubles(_averageMax, priceAB + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ����(����) �������� �� 1/3 ����
   {
    _currentExitLevel = LEVEL_AVEMAX;
    Print("����� ������� ������ ", LevelToString(_currentExitLevel));
   }
   //Print("������� ������ ", LevelToString(_currentExitLevel));
   break;
  case LEVEL_AVEMAX:
   if (_type == ORDER_TYPE_SELL && 
       GreatDoubles(_startDayPrice, priceAB + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    _currentExitLevel = LEVEL_START;
    Print("����� ������� ������ ", LevelToString(_currentExitLevel));
   }
   //Print("������� ������ ", LevelToString(_currentExitLevel));
   break;
  case LEVEL_START:
   if (_type == ORDER_TYPE_SELL && 
       GreatDoubles(_averageMin, priceAB + _trailingDeltaStep*_dayStep, 5))  // ���� ������ ����(����) �������� �� 1/3 ����
   {
    _currentExitLevel = LEVEL_AVEMIN;
    Print("����� ������� ������ ", LevelToString(_currentExitLevel));
   }
   if (_type == ORDER_TYPE_BUY &&
       LessDoubles(_averageMax + _trailingDeltaStep*_dayStep, priceAB, 5)) 
   {
    _currentExitLevel = LEVEL_AVEMAX;
    Print("����� ������� ������ ", LevelToString(_currentExitLevel));
   }
   //Print("������� ������ ", LevelToString(_currentExitLevel));
   break;
  case LEVEL_AVEMIN:
   if (_type == ORDER_TYPE_BUY && 
       LessDoubles(_startDayPrice + _trailingDeltaStep*_dayStep, priceAB, 5))  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    _currentExitLevel = LEVEL_START;
    Print("����� ������� ������ ", LevelToString(_currentExitLevel));
   }
   //Print("������� ������ ", LevelToString(_currentExitLevel));
   break;
  case LEVEL_MINIMUM:
   if (_type == ORDER_TYPE_BUY && 
       LessDoubles(_averageMin + _trailingDeltaStep*_dayStep, priceAB, 5))  // ���� ������ ����(����) ������ �� 1/3 ����
   {
    _currentExitLevel = LEVEL_AVEMIN;
    Print("����� ������� ������ ", LevelToString(_currentExitLevel));
   }
   //Print("������� ������ ", LevelToString(_currentExitLevel));
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