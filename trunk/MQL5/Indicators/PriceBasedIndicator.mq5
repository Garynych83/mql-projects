//+------------------------------------------------------------------+
//|                                          PriceBasedIndicator.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property description "ColoredTrend"
//---- ����� ������ ����������
#property version   "1.00"
//+----------------------------------------------+
//|  ��������� ��������� ����������              |
//+----------------------------------------------+
//---- ��������� ���������� � ������� ����
#property indicator_chart_window 
//---- ��� ������� � ��������� ���������� ������������ ���� �������
#property indicator_buffers 7
//---- ������������ ��� ����������� ����������
#property indicator_plots   3
//---- � �������� ���������� ������������ ������� �����
#property indicator_type1   DRAW_COLOR_CANDLES
//---- � �������� ���������� ������������ �������
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
//---- � �������� ������ ������ ����������� ����� ������
#property indicator_color1 clrNONE,clrBlue,clrPurple,clrRed,clrSaddleBrown,clrSalmon,clrMediumSlateBlue,clrYellow
//---- ����������� ����� ����� ����������
#property indicator_label1  "ColoredTrend"

//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <Arrays/ArrayObj.mqh>
#include <CompareDoubles.mqh>
#include <CIsNewBar.mqh>
#include <ColoredTrend/ColoredTrend.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>

//+----------------------------------------------------------------+
//|  ���������� ������������ ��������-������������ �������         |
//+----------------------------------------------------------------+
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
double ExtColorsBuffer[];
double ExtUpArrowBuffer[];
double ExtDownArrowBuffer[];
//+----------------------------------------------+
//| ������� ��������� ����������                 |
//+----------------------------------------------+
input int historyDepth = 40;     // ������� ������� ��� �������
input int bars=30;         // ������� ������ ����������
input bool messages=false;   // ����� ��������� � ��� "��������"

//+----------------------------------------------+
//| ���������� ���������� ����������             |
//+----------------------------------------------+
static CIsNewBar isNewBar;

CColoredTrend *trend, *topTrend;
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int digits;
int startBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Init Started");
//---- ������������� ���������� ����������  
  symbol = Symbol();
  current_timeframe = Period();
  digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  trend = new CColoredTrend(symbol, current_timeframe, bars, historyDepth);
  topTrend = new CColoredTrend(symbol, GetTopTimeframe(current_timeframe), bars, historyDepth);
  
//---- ����������� ������������ �������� � ������������ ������
   SetIndexBuffer(0, ExtOpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ExtLowBuffer,  INDICATOR_DATA);
   SetIndexBuffer(3, ExtCloseBuffer, INDICATOR_DATA);
   
   bool AsSeries = false;
   ArraySetAsSeries(ExtOpenBuffer, AsSeries);
   ArraySetAsSeries(ExtHighBuffer, AsSeries);
   ArraySetAsSeries(ExtLowBuffer, AsSeries);
   ArraySetAsSeries(ExtCloseBuffer, AsSeries);
//---- ����������� ������������� ������� � ��������, ��������� �����   
   SetIndexBuffer(4, ExtColorsBuffer, INDICATOR_COLOR_INDEX);
//---- ������������� ������ ������ ������� ��������� ����������
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, bars + 1);
//---- ����������� ������������� ������� � ��������� �����   
   SetIndexBuffer(5, ExtUpArrowBuffer, INDICATOR_DATA);
   SetIndexBuffer(6, ExtDownArrowBuffer, INDICATOR_DATA);
//---- ��� ��������� ���������� ���������� ������� ����(218)
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
//---- ��� ��������� ��������� ���������� ������� �����(217)
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
//---- ��������� ������� �������� ����������� ����������
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//---- ��� ��� ���� ������ � ����� ��� ����
   string short_name="ColoredTrend";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
/*
   //--- �������������� ������ ������� ����������
   ArrayInitialize(ExtOpenBuffer, 0.0);
   ArrayInitialize(ExtHighBuffer, 0.0);
   ArrayInitialize(ExtLowBuffer, 0.0);
   ArrayInitialize(ExtCloseBuffer, 0.0);
   ArrayInitialize(ExtUpArrowBuffer, 0.0);
   ArrayInitialize(ExtDownArrowBuffer, 0.0);
   ArrayInitialize(ExtColorsBuffer, clrNONE);
*/  
   Print("Init succesful");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,     // ���������� ������� � ����� �� ������� ����
                const int prev_calculated, // ���������� �����, ������������ �� ���������� ����
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],     // close[rates_total - 2] - ��������� ������������� close
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- �������� ���������� ����� �� ������������� ��� �������
   if(rates_total < bars + historyDepth) return(0);
   
//---- ���������� ������������� ����������
   int first, bar;
   if(prev_calculated > rates_total || prev_calculated <= 0) // �������� �� ������ ����� ������� ����������
   {
    first = rates_total - bars - historyDepth;           // ��������� ����� ��� ������� ���� �����
    startBars =  rates_total - 1;
   }
   else first = prev_calculated - 1;        // ��������� ����� ��� ������� ����� �����
   
//---- �������� �� ������ ������ ����
   if(isNewBar.isNewBar(symbol, GetBottomTimeframe(current_timeframe)))
   {
  //  Print("init trend, rates_total = ", rates_total);
    
    //--- �������� ���� � ������
    for(int bar = first; bar < rates_total - 1  && !IsStopped(); bar++) // ��������� ������ �������� ���������� �����, ����� ��������������
    {
   //--- �������� ��������������� ������ ��� ����������� �������
     PrintFormat("bar=%d, startBars=%d",bar,startBars);
     int buffer_index = bar - startBars + bars + historyDepth + 1;
     topTrend.CountMoveType(buffer_index);
     //trend.CountMoveType(bars, historyDepth, topTrend.GetMoveType(topTFBarsDepth - 1));
     trend.CountMoveType(buffer_index, topTrend.GetMoveType(buffer_index));
     
     //--- ���������� ���� � ������
     ExtOpenBuffer[bar] = open[bar];
     ExtHighBuffer[bar] = high[bar];
     ExtLowBuffer[bar] = low[bar];
     ExtCloseBuffer[bar] = close[bar];
     
   //--- ������� ���� �����
     ExtColorsBuffer[bar] = trend.GetMoveType(buffer_index); 
     //PrintFormat("bar = %d, buf_index = %d, MoveType = %s", bar, buffer_index, MoveTypeToString(trend.GetMoveType(buffer_index)));
     //PrintFormat("open_buf = %.05f, high_buf = %.05f, low_buf = %.05f, close_buf = %.05f, open = %.05f, high = %.05f, low = %.05f, close = %.05f"
     //           , ExtOpenBuffer[bar], ExtHighBuffer[bar], ExtLowBuffer[bar], ExtCloseBuffer[bar]
     //           , open[bar], high[bar], low[bar], close[bar]);
           
   //--- ������� ��� ������� �� ������ Wingdings ��� ��������� � PLOT_ARROW
     if (trend.GetExtremumDirection(buffer_index) > 0)
     {
      ExtUpArrowBuffer[bar] = trend.GetExtremum(buffer_index);
      //Print("��������");
     }
     else
     {
      ExtUpArrowBuffer[bar] = 0;
     }
     if (trend.GetExtremumDirection(buffer_index) < 0)
     {
      ExtDownArrowBuffer[bar] = trend.GetExtremum(buffer_index);
      //Print("�������");
     }
     else
     {
      ExtDownArrowBuffer[bar] = 0;
     }
    }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+



