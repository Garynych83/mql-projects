//+------------------------------------------------------------------+
//|                                                       Dynamo.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <Dinya\CDynamo.mqh>
#include <TradeManager\TradeManager.mqh> //���������� ���������� ��� ���������� �������� ��������

enum DELTA_STEP
{
 ONE = 1,
 TWO = 2,
 FOUR = 4,
 FIVE = 5,
 TEN = 10,
 TWENTY = 20,
 TWENTY_FIVE = 25,
 FIFTY = 50,
 HUNDRED = 100
};
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 4577;
input int volume = 10;  // ������ ����� ������
input double factor = 0.01; // ��������� ��� ���������� �������� ������ ������ �� ������
input int percentage = 70;  // ������� ��������� ����� ������� �������� ����� ����������� �� �������
input int slowPeriod = 30;  // ������ ���������� ������� ������ � ����
input int fastPeriod = 24;  // ������ ���������� ������� ������ � �����
input int slowDelta = 30;   // ������� ������
input int fastDelta = 50;   // ������� ������
input DELTA_STEP fastDeltaStep = TEN;  // �������� ���� ��������� ������
input DELTA_STEP slowDeltaStep = TEN;  // �������� ���� ��������� ������
input int dayStep = 40;     // ��� ������� ���� � ������� ��� ������� ��������
input int monthStep = 400;  // ��� ������� ���� � ������� ��� �������� ������� 


string symbol;
ENUM_TIMEFRAMES period;
datetime startTime;
double openPrice;
double currentVolume;

CDynamo dyn(fastDelta, slowDelta, fastDeltaStep, slowDeltaStep, dayStep, monthStep, volume, factor, percentage, fastPeriod, slowPeriod);
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if (fastDelta % fastDeltaStep != 0)
   {
    PrintFormat("%s ������� ������ ������ �������� �� ���");
    return(INIT_FAILED);
   }
   if (slowDelta % slowDeltaStep != 0)
   {
    PrintFormat("%s ������� ������ ������ �������� �� ���");
    return(INIT_FAILED);
   }
   
   symbol = Symbol();
   period = Period();
   startTime = TimeCurrent();
   
   dyn.SetStartHour(startTime);
   
   currentVolume = 0;
   dyn.InitDayTrade();
   dyn.InitMonthTrade();
   
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
  dyn.InitDayTrade();
  dyn.InitMonthTrade();
  if (dyn.isInit())
  {
   dyn.RecountDelta();
   double vol = dyn.RecountVolume();
   if (currentVolume != vol)
   {
    PrintFormat ("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol);
    if (dyn.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
    }
   }
  } 
 }
//+------------------------------------------------------------------+

