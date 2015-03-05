//+------------------------------------------------------------------+
//|                                                    PBI_SHARP.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.01"
 
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   3
//--- plot ColorCandles
#property indicator_label1  "ColoredTrend"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrNONE,clrBlue,clrPurple,clrRed,clrSaddleBrown,clrSalmon,clrMediumSlateBlue,clrYellow

#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
#property indicator_type4   DRAW_ARROW
#property indicator_type5   DRAW_ARROW

//----------------------------------------------------------------
#include <CompareDoubles.mqh>
#include <Lib CisNewBarDD.mqh>
#include <ColoredTrend/ColoredTrend.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <CEventBase.mqh>                         // ��� ��������� �������   
#include <CLog.mqh>
//----------------------------------------------------------------
 
//--- input ���������
input int history_depth = 1000; // ������� ������ ����������
input bool show_top = false;    // ���������� ������� ��������� ��� �������
input bool is_it_top = true;    // ���� true ����������� ������ ������� ���������; false ����������� �������������� ��������� ��� �������� ����������

//--- ������������ ������
double ColorCandlesBuffer1[];
double ColorCandlesBuffer2[];
double ColorCandlesBuffer3[];
double ColorCandlesBuffer4[];
double ColorCandlesColors[];
double ColorCandlesColorsTop[];
double ExtUpArrowBuffer[];
double ExtDownArrowBuffer[];

CisNewBar NewBarCurrent, 
          NewBarTop;

CColoredTrend *trend;      // ������ �������� ������
CEventBase    *event;      // ��� ��������� ������� 
SEventData eventData;      // ��������� ����� �������
              
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int  digits;
int handle_top_trend;
int depth = history_depth;
bool series_order = true;
double last_move;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   PrintFormat("%s Init", MakeFunctionPrefix(__FUNCTION__));
   symbol = Symbol();
   current_timeframe = Period();
   digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   // ������� ������ ��������� ������� 
   event = new CEventBase(300);
   if (event == NULL)
    {
     Print("������ ��� ������������� ���������� PriceBasedIndicator. �� ������� ������� ������ ������ CEventBase");
     return (INIT_FAILED);
    } 
   // ������� �������
   event.AddNewEvent(_Symbol,_Period,"����� ��������");      
   
   if(Bars(symbol, current_timeframe) < depth) depth = Bars(symbol, current_timeframe)-1;
   PrintFormat("������� ������ �����: %d", depth);
   
   NewBarCurrent.SetPeriod(current_timeframe);
   int handle_atr = iMA(symbol,  current_timeframe, 100, 0, MODE_EMA, iATR(symbol,  current_timeframe, 30));
   trend = new CColoredTrend(symbol, current_timeframe, handle_atr, depth);
   if(!is_it_top) handle_top_trend = iCustom(Symbol(), GetTopTimeframe(current_timeframe), "PriceBasedIndicator", depth, false, true);
   //--- indicator buffers mapping
   
   SetIndexBuffer(0, ColorCandlesBuffer1, INDICATOR_DATA);
   SetIndexBuffer(1, ColorCandlesBuffer2, INDICATOR_DATA);
   SetIndexBuffer(2, ColorCandlesBuffer3, INDICATOR_DATA);
   SetIndexBuffer(3, ColorCandlesBuffer4, INDICATOR_DATA);
   if(show_top)    //����� ��������� � ������ ���������� �� ����������: current ��� top
   {
    SetIndexBuffer(4, ColorCandlesColorsTop, INDICATOR_DATA);
    SetIndexBuffer(7,    ColorCandlesColors, INDICATOR_CALCULATIONS);
   }
   else
   {
    SetIndexBuffer(4,    ColorCandlesColors, INDICATOR_DATA);
    SetIndexBuffer(7, ColorCandlesColorsTop, INDICATOR_CALCULATIONS);
   }
   SetIndexBuffer(5,    ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(6,  ExtDownArrowBuffer, INDICATOR_DATA);

   InitializeIndicatorBuffers();
   
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
   PlotIndexSetInteger(3, PLOT_ARROW, 234);
   PlotIndexSetInteger(4, PLOT_ARROW, 233);
   
   ArraySetAsSeries(ColorCandlesBuffer1, series_order);
   ArraySetAsSeries(ColorCandlesBuffer2, series_order);
   ArraySetAsSeries(ColorCandlesBuffer3, series_order);
   ArraySetAsSeries(ColorCandlesBuffer4, series_order);
   ArraySetAsSeries( ColorCandlesColors, series_order);
   ArraySetAsSeries(ColorCandlesColorsTop, series_order);
   ArraySetAsSeries(   ExtUpArrowBuffer, series_order);   
   ArraySetAsSeries( ExtDownArrowBuffer, series_order);

   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
{
 //--- ������ ������ �������� ��� ������� ���������������
   Print(__FUNCTION__,"_��� ������� ��������������� = ",reason);
   ArrayFree(ExtUpArrowBuffer);
   ArrayFree(ExtDownArrowBuffer);
   ArrayFree(ColorCandlesBuffer1);
   ArrayFree(ColorCandlesBuffer2);
   ArrayFree(ColorCandlesBuffer3);
   ArrayFree(ColorCandlesBuffer4);
   ArrayFree(ColorCandlesColors);
   ArrayFree(ColorCandlesColorsTop);
   if(!is_it_top) IndicatorRelease(handle_top_trend);
   delete trend;
   delete event;
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
   static int buffer_index = 0;
   double buffer_top_trend[1] = {MOVE_TYPE_UNKNOWN};  // ������� ��� �������� ���� �������� �� ������� ���������
   SExtremum extr_cur[2] = {{0, -1}, {0, -1}};        // ��������������� ������� ��� ��������� ����������� �� ColoredTrend. [0] - ��������, [1] - �������
   
   ArraySetAsSeries(open , series_order);
   ArraySetAsSeries(high , series_order);
   ArraySetAsSeries(low  , series_order);
   ArraySetAsSeries(close, series_order);
   ArraySetAsSeries(time , series_order);
   
   if(prev_calculated == 0) // ������ ��������� �� �������
   {
    PrintFormat("%s ������ ������ ����������", MakeFunctionPrefix(__FUNCTION__));
    buffer_index = 0;
    trend.Zeros();
    depth = rates_total;
    InitializeIndicatorBuffers();
    NewBarCurrent.isNewBar(time[depth-1]);
    
    for(int i = depth-1; i >= 0;  i--)    
    {
     if(!is_it_top) 
      if(CopyBuffer(handle_top_trend, 4, time[i], 1, buffer_top_trend) < 1)
      {
       PrintFormat("%s �� ������� ���������� �������� TOP TREND. %d", EnumToString((ENUM_TIMEFRAMES)current_timeframe), GetLastError());
       return(0);
      }
     trend.CountMoveType(buffer_index, time[i], false, extr_cur, (ENUM_MOVE_TYPE)buffer_top_trend[0]);
      
     ColorCandlesBuffer1[i] = open[i];
     ColorCandlesBuffer2[i] = high[i];
     ColorCandlesBuffer3[i] = low[i];
     ColorCandlesBuffer4[i] = close[i]; 
     ColorCandlesColors[i] = trend.GetMoveType(buffer_index);
     ColorCandlesColorsTop[i] = buffer_top_trend[0];
    
     if (extr_cur[0].direction > 0) // ���� � ������� ������ ���� ��������
     {
      ExtUpArrowBuffer[i] = extr_cur[0].price;// + 50*_Point;
      extr_cur[0].direction = 0;
     }
     if (extr_cur[1].direction < 0) // ���� � ������� ������ ���� �������
     {
      ExtDownArrowBuffer[i] = extr_cur[1].price;// - 50*_Point;
      extr_cur[1].direction = 0;
     }      
    
     if(NewBarCurrent.isNewBar(time[i])) 
     {
      //trend.PrintExtr();
      //PrintFormat("HISTORY %s %s current:%d %s; top: %d %s", EnumToString((ENUM_TIMEFRAMES)current_timeframe), TimeToString(time[i]), buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)), top_buffer_index, MoveTypeToString(topTrend.GetMoveType(top_buffer_index)));
      buffer_index++;     //��� ���� ��� �� ������� �� �������
     }
    }
    last_move = ColorCandlesColors[0];
    PrintFormat("%s ������ ������ ���������� �������", MakeFunctionPrefix(__FUNCTION__));
    trend.PrintExtr();
   }
   
   // ���������� ���� �������� � ������� ������
   if(!is_it_top && CopyBuffer(handle_top_trend, 4, time[0], 1, buffer_top_trend) < 1)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s/%s �� ������� ���������� �������� TOP TREND. %d", EnumToString((ENUM_TIMEFRAMES)current_timeframe), EnumToString((ENUM_TIMEFRAMES)GetTopTimeframe(current_timeframe)), GetLastError()));
   }
   
   trend.CountMoveType(buffer_index, time[0], true, extr_cur, (ENUM_MOVE_TYPE)buffer_top_trend[0]);
   
   ColorCandlesBuffer1[0]   = open[0];
   ColorCandlesBuffer2[0]   = high[0];
   ColorCandlesBuffer3[0]   = low [0];
   ColorCandlesBuffer4[0]   = close[0]; 
   ColorCandlesColors[0]    = trend.GetMoveType(buffer_index);
   ColorCandlesColorsTop[0] = buffer_top_trend[0];

   // ���� ���������� ��������
   if (ColorCandlesColors[0] != last_move)
    {
     // ��������� ��������
     last_move = ColorCandlesColors[0];
     // ��������� ���� ��������� �������
     eventData.dparam = last_move;
     // � ������� ������� ���������� ��������
     Generate("����� ��������",eventData,true);
    }

   if (extr_cur[0].direction > 0)
   {
    ExtUpArrowBuffer[0] = extr_cur[0].price;// + 50*_Point;
    extr_cur[0].direction = 0;
   }
   if (extr_cur[1].direction < 0)
   {
    ExtDownArrowBuffer[0] = extr_cur[1].price;// - 50*_Point;
    extr_cur[1].direction = 0;
   }
   
   if(NewBarCurrent.isNewBar() && prev_calculated != 0)
   {
    //trend.PrintExtr();
    //PrintFormat("REAL %s %s current:%d %s; top: %d %s", EnumToString((ENUM_TIMEFRAMES)current_timeframe), TimeToString(time[0]), buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)), top_buffer_index, MoveTypeToString(topTrend.GetMoveType(top_buffer_index)));
    buffer_index++; 
   }
   
   return(rates_total);
  }

void InitializeIndicatorBuffers()
{
 ArrayInitialize(ColorCandlesBuffer1, 0);
 ArrayInitialize(ColorCandlesBuffer2, 0);
 ArrayInitialize(ColorCandlesBuffer3, 0);
 ArrayInitialize(ColorCandlesBuffer4, 0);
 ArrayInitialize(ColorCandlesColors , 0);
 ArrayInitialize(ExtUpArrowBuffer   , 0);
 ArrayInitialize(ExtDownArrowBuffer , 0);
 ArrayInitialize(ColorCandlesColorsTop, 0);
}

// �������������� ������� ���������� 

// �������� �� ���� �������� � ������� ������� ��� ���
void Generate(string id_nam,SEventData &_data,const bool _is_custom=true)
  {
   // �������� �� ���� �������� �������� � ������� �������� � �� � ���������� ��� ��� �������
   long z = ChartFirst();
   while (z>=0)
     {
      if (ChartSymbol(z) == _Symbol && ChartPeriod(z)==_Period)  // ���� ������ ������ � ������� �������� � �������� 
        {
         // ������� ������� ��� �������� �������
         event.Generate(z,id_nam,_data,_is_custom);
        }
      z = ChartNext(z);      
     }     
  }