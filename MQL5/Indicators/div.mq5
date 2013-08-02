//+------------------------------------------------------------------+
//|                                                          div.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "div"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#include <Lib CisNewBar.mqh>
#include <divSignals.mqh>


input ENUM_MA_METHOD Method = MODE_SMA; // ����� �����������

input int    kPeriod = 5;       // �-������
input int    dPeriod = 3;       // D-������
input int    slov  = 3;         // ����������� �������. ��������� �������� �� 1 �� 3.
input int    deep = 12;         // �������������� ������, ���������� �����.
input int    delta = 2;         // ������ � ����� ����� ������� ������������ ���� � ����������
input double highLine = 80;     // ������� �������� ������� ����������
input double lowLine = 20;      // ������ �������� ������� ����������
input int    firstBarsCount = 3;// ���������� ������ ����� �� ������� ������ ���������� �������� ��� ������� ����

int    stoHandle;               // ��������� �� ���������.
int    firstBar;                // ������ ����, � ������� ���������� ����������.
int    t;                       // ���� ��� ������� ��������� �� ��������� ������ ����.
double mainLine[];              // ������ �������� ����� ����������.
double divBufferRight[];        // ������ ����������
double signalsMode[];

enum ENUM_SIGNALS_MODE
{
 DIVERGENCE = 0,
 CONVERGENCE = 1,
 NONE = 2
};



divSignals ds;                  // ������� ������ divSignals
CisNewBar nb;                   // ������� ������ CisNewBar

int OnInit()
  {
   stoHandle = iStochastic(NULL, 0, kPeriod, dPeriod, slov, Method, STO_LOWHIGH); // ������������� ���������.
   if (stoHandle < 0)
   {
    Print("Error: ����� (���������) �� ���������������!", GetLastError());
    return(-1);
   }
   else Print("������������� ������ (���������) ������ �������!");
   
   SetIndexBuffer(0,divBufferRight,INDICATOR_DATA);
   SetIndexBuffer(1,signalsMode,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, deep - 1);
   
   ArraySetAsSeries(mainLine, true);
   ArraySetAsSeries(divBufferRight, true);
   ArraySetAsSeries(signalsMode, true);
   
   t = 0;
   
   ds.SetDelta(delta);
   ds.SetHighLineOfStochastic(highLine);
   ds.SetLowLineOfStochastic(lowLine);
   ds.SetFirstBarsCount(firstBarsCount);

   return(INIT_SUCCEEDED);
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   
   if((nb.isNewBar() > 0) || (t == 0))
   {
        
    ArraySetAsSeries(price, true);
    
    if (rates_total < deep - 1)
    {
     return(0);
    }
    
    if (CopyBuffer(stoHandle, MAIN_LINE, 0, rates_total, mainLine) < 0) // ���������� � �������� ������� �������� �����.
    {
    Print("������ ���������� ������� main");
    return(false);
    }
    if (t == 0)
    {
    t = rates_total;
    }
    else
    {
     t = deep;
    }
    
    for (firstBar = deep - 1; firstBar < t; firstBar++)
    {
     if (ds.Divergence(price, mainLine, firstBar, deep))
     {
      signalsMode[ds.GetRightIndexOfPrice()] = DIVERGENCE;
      divBufferRight[ds.GetRightIndexOfPrice()] = ds.GetRightPointOfPrice();
     }
     else if (ds.Convergence(price, mainLine, firstBar, deep))
     {
      signalsMode[ds.GetRightIndexOfPrice()] = CONVERGENCE;
      divBufferRight[ds.GetRightIndexOfPrice()] = ds.GetRightPointOfPrice();
     }
     else 
     {
      signalsMode[ds.GetRightIndexOfPrice()] = NONE;
     }    
    }
    }
    
   return(rates_total);
  }