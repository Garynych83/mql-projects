//+------------------------------------------------------------------+
//|                                                     IsNewBar.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <Lib CisNewBarDD.mqh>  // ��� �������� �� ����� ���
#include <CEventBase.mqh>  // ��� ��������� �������
//+------------------------------------------------------------------+
//| ���������, ������������ ������� ���������� ������ ����           |
//+------------------------------------------------------------------+
CisNewBar *isNewBar;
CEventBase *event;

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
   // ���� ������ ����� ���
   if (isNewBar.isNewBar())
    {
     // �� ��������� ��������� �������
     event = new CEventBase();
     if(CheckPointer(event)==POINTER_DYNAMIC)
       {
        SEventData data;
        // �������� �� ���� �������� �������� � ������� �������� � �� � ���������� ��� ��� �������
        long z = ChartFirst();
        while (z>=0)
         {
          if (ChartSymbol(z) == _Symbol && ChartPeriod(z)==_Period)  // ���� ������ ������ � ������� �������� � �������� 
            {
            // ������� ������� ��� �������� �������
            event.Generate(z,1,data); 
            }
         z = ChartNext(z);
        
        }   
      }  
    }
   return(rates_total);
  }