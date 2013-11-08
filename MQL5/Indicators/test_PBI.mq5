//+------------------------------------------------------------------+
//|                                           DRAW_COLOR_CANDLES.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
 
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   3
//--- plot ColorCandles
#property indicator_label1  "ColoredTrend"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrNONE,clrBlue,clrPurple,clrRed,clrSaddleBrown,clrSalmon,clrMediumSlateBlue,clrYellow

#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW

//----------------------------------------------------------------
#include <Arrays/ArrayObj.mqh>
#include <CompareDoubles.mqh>
#include <Lib CisNewBar.mqh>
#include <ColoredTrend/ColoredTrend.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>
//----------------------------------------------------------------
 
//--- input ���������
input int      bars = 50;         // ������� ������ ����������
//--- ������������ ������
double         ColorCandlesBuffer1[];
double         ColorCandlesBuffer2[];
double         ColorCandlesBuffer3[];
double         ColorCandlesBuffer4[];
double         ColorCandlesColors[];
double         ExtUpArrowBuffer[];
double         ExtDownArrowBuffer[];

static CisNewBar NewBarBottom;

CColoredTrend *trend, 
              *topTrend;
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int digits;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol = Symbol();
   current_timeframe = Period();
   NewBarBottom.SetPeriod(GetBottomTimeframe(current_timeframe));
   digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   trend    = new CColoredTrend(symbol, current_timeframe, bars);
   topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), bars);
//--- indicator buffers mapping
   SetIndexBuffer(0,ColorCandlesBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ColorCandlesBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,ColorCandlesBuffer3,INDICATOR_DATA);
   SetIndexBuffer(3,ColorCandlesBuffer4,INDICATOR_DATA);
   SetIndexBuffer(4,ColorCandlesColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5, ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(6, ExtDownArrowBuffer, INDICATOR_DATA);
   
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
   
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
   static int start_index = 0;
   static int start_iteration = 0;
   static int buffer_index = 0;

   if(prev_calculated == 0) 
   {
    start_index = rates_total - bars;
    start_iteration = rates_total - bars;
   }
   else 
   { 
    buffer_index = prev_calculated - start_index;
    start_iteration = prev_calculated-1;
   }
   
   if(NewBarBottom.isNewBar() > 0 || prev_calculated == 0) //isNewBar bottom_tf
   {
    //PrintFormat("NEW BAR %d | %d - %d", buffer_index, start_iteration, rates_total-1);
    for(int i = start_iteration; i < rates_total; i++)
    {
     topTrend.CountMoveType(buffer_index);//???
     trend.CountMoveType(buffer_index, (rates_total-1) - i, topTrend.GetMoveType(buffer_index));
     
     ColorCandlesBuffer1[i] = open[i];
     ColorCandlesBuffer2[i] = high[i];
     ColorCandlesBuffer3[i] = low[i];
     ColorCandlesBuffer4[i] = close[i];
     ColorCandlesColors[i]  = trend.GetMoveType(buffer_index);
     
     if (trend.GetExtremumDirection(buffer_index) > 0)
     {
      ExtUpArrowBuffer[i-2] = trend.GetExtremum(buffer_index);
      //PrintFormat("�������� %d __ %d", i, buffer_index);
     }
     if (trend.GetExtremumDirection(buffer_index) < 0)
     {
      ExtDownArrowBuffer[i-2] = trend.GetExtremum(buffer_index);
      //PrintFormat("������� %d __ %d", i, buffer_index);
     }
     if(buffer_index < bars) buffer_index++;
    }
   }//END isNewBar bottom_tf
        
   return(rates_total);
  }