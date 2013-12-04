//+------------------------------------------------------------------+
//|                                                        Dinya.mq4 |
//|                                                              GIA |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "GIA"

//------- ����������� ������� ������� -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
extern int _magic = 4577;
extern int useOrder = 0;
extern int volume = 10;  // ������ ����� ������
extern double factor = 0.01; // ��������� ��� ���������� �������� ������ ������ �� ������
extern int percentage = 70;  // ������� ��������� ����� ������� �������� ����� ����������� �� �������
extern int slowPeriod = 30;  // ������ ���������� ������� ������ � ����
extern int fastPeriod = 24;  // ������ ���������� ������� ������ � �����
extern int slowDelta = 30;   // ������� ������
extern int fastDelta = 50;   // ������� ������
extern int slowDeltaStep = 10;  // ��� ��������� ������� ������
extern int fastDeltaStep = 10;  // ��� ��������� ������� ������
extern int dayStep = 40;     // ��� ������� ���� � ������� ��� ������� ��������
extern int monthStep = 400;  // ��� ������� ���� � ������� ��� �������� ������� 

bool inited = true;

bool gbDisabled = false;
string symbol;
datetime startTime, startHour;
double openPrice;
double currentVolume;
bool isDayInit = false;
bool isMonthInit = false; // ����� ������������� �������� ��� ��� � ������
bool dayDeltaChanged;
bool monthDeltaChanged;
static double prevDayPrice;
static double prevMonthPrice;
static datetime m_last_day_number;
static datetime m_last_month_number;

int direction;

#include <isNewBar.mqh>
#include <CDinya.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----
   if ((useOrder != 0) && (useOrder != 1))
   {
    Print("%s ������ ���� ������� �������� ���������� �������� 0 - �� �������, 1 - �� �������");
    inited = false;
   }
   if (fastDelta % fastDeltaStep != 0)
   {
    Print("%s ������� ������ ������ �������� �� ���");
    inited = false;
   }
   if (slowDelta % slowDeltaStep != 0)
   {
    Print("%s ������� ������ ������ �������� �� ���");
    inited = false;
   }
   
   symbol = Symbol();
   startTime = TimeCurrent();
   startHour = TimeHour(TimeCurrent()) + 1; // �������� � ������� ������ ����
   Print("startHour=", startHour);
   direction = iif(useOrder == OP_BUY, 1, -1);
   m_last_day_number = TimeCurrent() - fastPeriod*60*60;
   m_last_month_number = TimeCurrent() - slowPeriod*24*60*60;   

   currentVolume = 0;
   InitDayTrade();
   InitMonthTrade();
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
 {
  if (!gbDisabled)
  {
   InitDayTrade();
   InitMonthTrade();
   if (isMonthInit)
   {
    RecountMonthDelta();
   }
   if (isDayInit)
   {
    RecountDayDelta();
   }
   if(dayDeltaChanged || monthDeltaChanged)
   {
    double vol = RecountVolume();
    Print("curVol=", currentVolume, " vol=", vol);
    if (currentVolume != vol)
    {
     if (CorrectOrder(vol - currentVolume))
     {
      Print(" currentVol=", currentVolume, " recountVol=",  vol);
      currentVolume = vol;
     }
    }
   }
  }  
  return(0);
 }
//+------------------------------------------------------------------+

