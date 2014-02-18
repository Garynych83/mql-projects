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
#include <Brothers\CSanya.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 4577;
input ENUM_ORDER_TYPE type = ORDER_TYPE_BUY; // �������� ����������� ��������
input int fastDelta = 40;    //  ��������� ������� ������
input int dayStep = 100;     // ��� ������� ���� � ������� ��� ������� ��������
input int stepsFromStartToExtremum = 4;    // ������������ ���������� ����� �� ����� ������ �� ����������
input int stepsFromStartToExit = 2;        // ����� ������� ����� ��������� ����� ������� ������ �� � ���� �������
input int stepsFromExtremumToExtremum = 2; // ������� ����� ����� ������������

input int firstAdd = 30;    //  ������� ������ �������
input int secondAdd = 20;   //  ������� ������ �������
input int thirdAdd = 10;    //  ������� ������� �������

string symbol;
datetime startTime;
double openPrice;
double currentVolume;

int volume = 10;      // ������ ����� ������
int slowDelta = 60;   // ������� ������

double factor = 0.01; // ��������� ��� ���������� �������� ������ ������ �� ������
int trailingDeltaStep = 30;
int percentage = 100;  // ������� ��������� ����� ������� �������� ����� ����������� �� �������
int fastPeriod = 24;  // ������ ���������� ������� ������ � �����
int slowPeriod = 30;  // ������ ���������� ������� ������ � ����

int monthStep = 400;   // ��� ������� ���� � ������� ��� �������� ������� 
   
DELTA_STEP fastDeltaStep = FIFTY;  // ��� ��������� ������� ������
DELTA_STEP slowDeltaStep = TEN;  // ��� ��������� ������� ������

CSanya san(fastDelta, slowDelta, dayStep, monthStep, stepsFromStartToExtremum, stepsFromStartToExit, stepsFromExtremumToExtremum
          , type, volume, firstAdd, secondAdd, thirdAdd, fastDeltaStep, slowDeltaStep, percentage
          , fastPeriod, slowPeriod, trailingDeltaStep);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (fastDelta + firstAdd + secondAdd + thirdAdd != 100)
   {
    PrintFormat("����� ������� � ���������� ����� ������ ���� ����� 100");
    return(INIT_FAILED);
   }
   if (type != ORDER_TYPE_BUY && type != ORDER_TYPE_SELL)
   {
    PrintFormat("%s �������� ���������� �������� ������ ���� ORDER_TYPE_BUY ��� ORDER_TYPE_SELL");
    return(INIT_FAILED);
   }
   if (slowDelta % slowDeltaStep != 0)
   {
    PrintFormat("%s ������� ������ ������ �������� �� ���");
    return(INIT_FAILED);
   }
   
   symbol = Symbol();
   startTime = TimeCurrent();
   san.SetSymbol(symbol);
   san.SetPeriod(Period());
   san.SetStartHour(startTime);
   
   currentVolume = 0;
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
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {
  //san.InitMonthTrade();
  //if (san.isMonthInit())
  san.RecountFastDelta();
  
  if(san.isFastDeltaChanged() || san.isSlowDeltaChanged())
  {
   double vol = san.RecountVolume();
   if (currentVolume != vol)
   {
    PrintFormat ("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol);
    if (san.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
    }
   }
  }
 }
//+------------------------------------------------------------------+
