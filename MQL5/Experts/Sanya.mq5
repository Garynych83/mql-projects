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
#include <Dinya\CDynamo.mqh>
#include <TradeManager\TradeManager.mqh> //���������� ���������� ��� ���������� �������� ��������
#include <CLog.mqh>

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
input ENUM_ORDER_TYPE type = ORDER_TYPE_BUY; // �������� ����������� ��������
input int volume = 10;  // ������ ����� ������
input double factor = 0.01; // ��������� ��� ���������� �������� ������ ������ �� ������
input int percentage = 70;  // ������� ��������� ����� ������� �������� ����� ����������� �� �������
input int slowPeriod = 30;  // ������ ���������� ������� ������ � ����
input int fastPeriod = 24;  // ������ ���������� ������� ������ � �����
input int slowDelta = 30;   // ������� ������
input DELTA_STEP slowDeltaStep = TEN;  // ��� ��������� ������� ������
input int dayStep = 100;     // ��� ������� ���� � ������� ��� ������� ��������
input int monthStep = 400;  // ��� ������� ���� � ������� ��� �������� ������� 

string symbol;
datetime startTime;
double openPrice;
double currentVolume;

int fastDelta = 0;   // ������� ������
DELTA_STEP fastDeltaStep = HUNDRED;  // ��� ��������� ������� ������
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
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
   
   currentVolume = 0;
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
 
  //dyn.InitDayTrade();
  //dyn.InitMonthTrade();
  if (dyn.isInit())
  {
   dyn.RecountDelta();
   double vol = dyn.RecountVolume();
   if (currentVolume != vol)
   {
    PrintFormat ("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol);
    log_file.Write(LOG_DEBUG, StringFormat("%s currentVol=%f, recountVol=%f", MakeFunctionPrefix(__FUNCTION__), currentVolume, vol));
    if (dyn.CorrectOrder(vol - currentVolume))
    {
     currentVolume = vol;
    }
   }
  } 
   
 }
//+------------------------------------------------------------------+
