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
input ulong _magic = 4577;
input ENUM_ORDER_TYPE type = ORDER_TYPE_BUY; // �������� ����������� ��������
input int fastDelta = 12;    //  ��������� ������� ������
input int dayStep = 100;     // ��� ������� ���� � ������� ��� ������� ��������
input int minStepsFromStartToExtremum = 2;    // ����������� ���������� ����� �� ����� ������ �� ����������
input int maxStepsFromStartToExtremum = 4;    // ������������ ���������� ����� �� ����� ������ �� ����������
input int stepsFromStartToExit = 2;           // ����� ������� ����� ��������� ����� ������� ������ �� � ���� �������

input int firstAdd = 20;    //  ������� ������ �������
input int secondAdd = 28;   //  ������� ������ �������
input int thirdAdd = 40;    //  ������� ������� �������

input int volume = 10;      // ������ ����� ������
input int slowDelta = 60;   // ������� ������

input int percentage = 100;  // ������� ��������� ����� ������� �������� ����� ����������� �� �������

string symbol;
datetime startTime;
double openPrice;
double currentVolume;
ENUM_ORDER_TYPE currentType;

double factor = 0.01; // ��������� ��� ���������� �������� ������ ������ �� ������
int fastPeriod = 24;  // ������ ���������� ������� ������ � �����
int slowPeriod = 30;  // ������ ���������� ������� ������ � ����

int monthStep = 400;   // ��� ������� ���� � ������� ��� �������� ������� 
   
DELTA_STEP fastDeltaStep = FIFTY;  // ��� ��������� ������� ������
DELTA_STEP slowDeltaStep = TEN;  // ��� ��������� ������� ������

CSanyaRotate san(fastDelta, slowDelta, dayStep, monthStep, minStepsFromStartToExtremum, maxStepsFromStartToExtremum, stepsFromStartToExit
                , type, volume, firstAdd, secondAdd, thirdAdd, fastDeltaStep, slowDeltaStep, percentage
                , fastPeriod, slowPeriod);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (fastDelta + firstAdd + secondAdd + thirdAdd != 100)
   {
    Print("����� ������� � ���������� ����� ������ ���� ����� 100");
    return(INIT_FAILED);
   }
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
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {
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
     PrintFormat ("%s currentVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume);
    }
   }
  }
  
  if (currentType != san.GetType())
  {
   double vol = san.RecountVolume();
   PrintFormat ("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol);
   if (san.CorrectOrder(vol + currentVolume))
   {
    currentVolume = vol;
    currentType = san.GetType();
   }
  }
 }
//+------------------------------------------------------------------+
