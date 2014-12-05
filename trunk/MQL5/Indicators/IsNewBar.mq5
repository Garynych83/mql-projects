//+------------------------------------------------------------------+
//|                                                     IsNewBar.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <CIsNewBarEvent.mqh>  // ��� �������� �� ����� ���
//+------------------------------------------------------------------+
//| ���������, ������������ ������� ���������� ������ ����           |
//+------------------------------------------------------------------+
CisNewBar *isNewBar;

int OnInit()
  {
   isNewBar = new CisNewBar(_Symbol,_Period);
   //event = new CEventBase();
   return(INIT_SUCCEEDED);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   // ���������� �������, ��� ������ ����� ���
   isNewBar.isNewBar();
   return(rates_total);
  }