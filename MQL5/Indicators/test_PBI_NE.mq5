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
#include <ColoredTrend/ColoredTrendNE.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>
//----------------------------------------------------------------
 
//--- input ���������
input int      depth = 1000;         // ������� ������ ����������
input bool     show_top = false;
input double   percentage_ATR_cur = 2;   
input double   difToTrend_cur = 1.5;
input int      ATR_ma_period_cur = 12;
input double   percentage_ATR_top = 2;   
input double   difToTrend_top = 1.5;
input int      ATR_ma_period_top = 12; 
//--- ������������ ������
double         ColorCandlesBuffer1[];
double         ColorCandlesBuffer2[];
double         ColorCandlesBuffer3[];
double         ColorCandlesBuffer4[];
double         ColorCandlesColors[];
double         ExtUpArrowBuffer[];
double         ExtDownArrowBuffer[];


CisNewBar NewBarBottom,
          NewBarCurrent, 
          NewBarTop;

CColoredTrend *trend, 
              *topTrend;
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int digits;
//int buffer_index = 0;
//int top_buffer_index = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Init");
   symbol = Symbol();
   current_timeframe = Period();
   NewBarBottom.SetPeriod(GetBottomTimeframe(current_timeframe));
   NewBarCurrent.SetLastBarTime(current_timeframe);
   NewBarTop.SetPeriod(GetTopTimeframe(current_timeframe));
   //PrintFormat("TOP = %s, BOTTOM = %s", EnumToString((ENUM_TIMEFRAMES)NewBarTop.GetPeriod()), EnumToString((ENUM_TIMEFRAMES)NewBarBottom.GetPeriod()));
   digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), depth, percentage_ATR_top, difToTrend_top, ATR_ma_period_top);
   trend    = new CColoredTrend(symbol,                  current_timeframe, depth, percentage_ATR_cur, difToTrend_cur, ATR_ma_period_cur);
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
   
   ArraySetAsSeries(ColorCandlesBuffer1, false);
   ArraySetAsSeries(ColorCandlesBuffer2, false);
   ArraySetAsSeries(ColorCandlesBuffer3, false);
   ArraySetAsSeries(ColorCandlesBuffer4, false);

   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
{
 //--- ������ ������ �������� ��� ������� ���������������
   Print(__FUNCTION__,"_��� ������� ��������������� = ",reason);
   ArrayInitialize(ExtUpArrowBuffer, 0);
   ArrayInitialize(ExtDownArrowBuffer, 0); 
   ArrayInitialize(ColorCandlesBuffer1, 0);
   ArrayInitialize(ColorCandlesBuffer2, 0);
   ArrayInitialize(ColorCandlesBuffer3, 0);
   ArrayInitialize(ColorCandlesBuffer4, 0);
   topTrend.Zeros();
   trend.Zeros();
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
   static datetime start_time;
   static int buffer_index = 0;
   static int top_buffer_index = 0;
   SExtremum extr_cur = {0, -1};
   SExtremum extr_top = {0, -1};
   
   int seconds_current = PeriodSeconds(current_timeframe);
   int seconds_top = PeriodSeconds(GetTopTimeframe(current_timeframe));

   if(prev_calculated == 0) 
   {
    Print("������ ������ ����������");
    buffer_index = 0;
    top_buffer_index = 0;
    start_index = rates_total - depth;
    start_time = TimeCurrent() - depth*seconds_current;
    start_iteration = rates_total - depth;
    topTrend.Zeros();
    trend.Zeros();
    ArrayInitialize(ColorCandlesBuffer1, 0);
    ArrayInitialize(ColorCandlesBuffer2, 0);
    ArrayInitialize(ColorCandlesBuffer3, 0);
    ArrayInitialize(ColorCandlesBuffer4, 0);
   }
   else 
   { 
    //buffer_index = prev_calculated - start_index;
    start_iteration = start_index + buffer_index - 1;//prev_calculated-1;
   }
   
   bool error = true;
   
   for(int i = 0; i < (rates_total-start_iteration)/(seconds_top/seconds_current);i++)
   {
     error = topTrend.CountMoveType(i, (int)((rates_total-start_iteration)/(seconds_top/seconds_current)-i), extr_top);
     //PrintFormat("top_buffer_index = %d, start_pos_top = %d, extr_top = {%d;%.05f}", top_buffer_index, start_pos_top, extr_top.direction, extr_top.price);
     if(!error)
     {
      Print("YOU NEED TO WAIT FOR THE NEXT BAR ON TOP TIMEFRAME");
      return(0);
     }
   }
   
    for(int i =  start_iteration; i < rates_total;  i++)    
    {
     //PrintFormat("start_iteration = %d; rates_total = %d, bi = %d, tbi = %d", start_iteration, rates_total, buffer_index, top_buffer_index);
     int start_pos_top = GetNumberOfTopBarsInCurrentBars(current_timeframe, depth) - top_buffer_index;
     int start_pos_cur = (buffer_index < depth) ? (rates_total-1) - i : 0; 
     if(start_pos_top < 0) start_pos_top = 0;
     
     
     error = trend.CountMoveType(buffer_index, start_pos_cur, extr_cur, topTrend.GetMoveType(top_buffer_index));
     if(!error) 
     {
      Print("YOU NEED TO WAIT FOR THE NEXT BAR ON CURRENT TIMEFRAME");
      return(0);
     } 
      
     ColorCandlesBuffer1[i] = open[i];
     ColorCandlesBuffer2[i] = high[i];
     ColorCandlesBuffer3[i] = low[i];
     ColorCandlesBuffer4[i] = close[i]; 
     
     //PrintFormat("%s current:%d %s; top: %d %s", TimeToString(time[i]), buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)), top_buffer_index, MoveTypeToString(topTrend.GetMoveType(top_buffer_index)));
     if(!show_top)
     { 
      ColorCandlesColors [i] = trend.GetMoveType(buffer_index);
     }
     else
     {
      ColorCandlesColors [i + 2] = topTrend.GetMoveType(top_buffer_index);
     }

     if (extr_cur.direction > 0)
     {
      ExtUpArrowBuffer[i] = extr_cur.price;// + 50*_Point;
      extr_cur.direction = 0;
     }
     else if (extr_cur.direction < 0)
     {
      ExtDownArrowBuffer[i] = extr_cur.price;// - 50*_Point;
      extr_cur.direction = 0;
     }
     
     if(buffer_index < depth)
     {
      buffer_index++;
      top_buffer_index = (start_time + seconds_current*buffer_index)/seconds_top - start_time/seconds_top;
     }
    }
   
   if(NewBarCurrent.isNewBar() > 0 && prev_calculated != 0)
   {
    buffer_index++;
   }
   
   if(NewBarTop.isNewBar() > 0 && prev_calculated != 0)
   {
    top_buffer_index++;
   }
   
   return(rates_total);
  }
  
  int GetNumberOfTopBarsInCurrentBars(ENUM_TIMEFRAMES timeframe, int current_bars)
  {
   return ((current_bars*PeriodSeconds(timeframe))/PeriodSeconds(GetTopTimeframe(timeframe)));
  }
