//+------------------------------------------------------------------+
//|                                                 DRAW_FILLING.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
 
#property description "��������� ��� ������������ DRAW_FILLING"

//#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
//--- plot Intersection
#property indicator_label1  "Intersection"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrRed
#property indicator_width1  1

#property indicator_label2  "Intersection"
#property indicator_type2   DRAW_FILLING
#property indicator_color2  clrBlue
#property indicator_width2  1
//--- input ���������
input int      shift=1;          // ����� ������� � ������� (�������������)
//--- ������������ ������
double         IntersectionBuffer1[];
double         IntersectionBuffer2[];
double         IntersectionBuffer3[];
double         IntersectionBuffer4[];
//--- ������ ��� �������� ������
color colors[]={clrRed,clrBlue,clrGreen,clrAquamarine,clrBlanchedAlmond,clrBrown,clrCoral,clrDarkSlateGray};
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,IntersectionBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,IntersectionBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,IntersectionBuffer3,INDICATOR_DATA);
   SetIndexBuffer(3,IntersectionBuffer4,INDICATOR_DATA);
//---
   PlotIndexSetInteger(0,PLOT_SHIFT,shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,shift);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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

//--- ������ ������ ������ ���������� ��� ������ ���������� � ��������� ������ ����������
      for(int i = 0; i <= rates_total; i++)
      {
       IntersectionBuffer1[i] = 1.36100;
       IntersectionBuffer2[i] = 1.36000;
       IntersectionBuffer3[i] = 1.36050;
       IntersectionBuffer4[i] = 1.35950;
      }
//--- return value of prev_calculated for next call
   return(rates_total);
  }