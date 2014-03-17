//+------------------------------------------------------------------+
//|                                                        Sanya.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <Brothers\CSanyaRotate.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ENUM_ORDER_TYPE type = ORDER_TYPE_BUY; // ��������� ����������� ��������

input int volume = 10;      // ������ ����� ������
input int slowDelta = 60;   // ������� ������ (������� �� ������� ������)
input double ko = 2;        // ����������� �������

input int dayStep = 100;     // ��� ������� ���� � ������� ��� ������� ��������
input int minStepsFromStartToExtremum = 2;    // ����������� ���������� ����� �� ����� ������ �� ����������
input int maxStepsFromStartToExtremum = 4;    // ������������ ���������� ����� �� ����� ������ �� ����������
input int stepsFromStartToExit = 2;           // ����� ������� ����� ��������� ����� ������� ������ �� � ���� �������

input int maxSpread = 30;

string symbol;
datetime startTime;
double openPrice;
double currentVolume;
ENUM_ORDER_TYPE currentType;

int fastPeriod = 24;  // ������ ���������� ������� ������ � �����
int slowPeriod = 30;  // ������ ���������� ������� ������ � ����
int percentage = 100;  // ������� ��������� ����� ������� �������� ����� ����������� �� ��������
double factor = 0.01; // ��������� ��� ���������� �������� ������ ������ �� ������

int monthStep = 400;   // ��� ������� ���� � ������� ��� �������� ������� 
   
DELTA_STEP fastDeltaStep = FIFTY;  // ��� ��������� ������� ������
DELTA_STEP slowDeltaStep = TEN;  // ��� ��������� ������� ������

CGlobalVariable hand_control;
CSanyaRotate *san;
double vol = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   int fastDelta, firstAdd, secondAdd, thirdAdd;
   
   fastDelta = 100 / (1 + ko + ko*ko + ko*ko*ko);
   firstAdd = fastDelta * ko;
   secondAdd = firstAdd * ko;
   thirdAdd = 100 - secondAdd - firstAdd - fastDelta;
   
   hand_control.Name("FAST DELTA SANYSA");
   hand_control.IntValue(fastDelta);
   
   if (type != ORDER_TYPE_BUY && type != ORDER_TYPE_SELL)
   {
    Print("�������� ���������� �������� ������ ���� ORDER_TYPE_BUY ��� ORDER_TYPE_SELL");
    return(INIT_FAILED);
   }
   if (slowDelta % slowDeltaStep != 0)
   {
    Print("������� ������ ������ �������� �� ���");
    return(INIT_FAILED);
   }
   if (minStepsFromStartToExtremum > maxStepsFromStartToExtremum)
   {
    Print("����������� ���������� ����� �� ������ ���� ������ �������������");
    return(INIT_FAILED);
   }
   
   san = new CSanyaRotate(fastDelta, slowDelta, dayStep, monthStep, minStepsFromStartToExtremum, maxStepsFromStartToExtremum, stepsFromStartToExit
                , type, volume, firstAdd, secondAdd, thirdAdd, fastDeltaStep, slowDeltaStep, percentage
                , fastPeriod, slowPeriod);
                
   symbol = Symbol();
   startTime = TimeCurrent();
   san.SetSymbol(symbol);
   san.SetPeriod(Period());
   san.SetStartHour(startTime);
   
   currentVolume = 0;
   currentType = type;
   //san.InitMonthTrade();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   delete san;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {
  san.RecountFastDelta();
  //hand_control.IntValue();   ����������� fast_delta
  
  int spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
  
  if(san.isFastDeltaChanged() || san.isSlowDeltaChanged())
  {
   vol = san.RecountVolume();
  }
  
  if (spread < maxSpread)
  {
   if (currentType != san.GetType())
   {
    if (san.CorrectOrder(-vol - currentVolume))
    {
     currentVolume = vol;
     currentType = san.GetType();
     PrintFormat("%s currentType = %s, san.GetType() = %s", MakeFunctionPrefix(__FUNCTION__), OrderTypeToString(currentType), OrderTypeToString(san.GetType()));
    }
   }
   
   if (currentVolume != vol)
   {
    if (san.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
     PrintFormat ("%s currentVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume);
    }
   }
  } 
 }
//+------------------------------------------------------------------+
