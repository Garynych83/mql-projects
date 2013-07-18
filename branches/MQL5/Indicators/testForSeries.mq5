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
#property indicator_buffers 5
//---- ������������ ����� ���� ����������� ����������
#property indicator_plots   1
//---- � �������� ���������� ������������ ������� �����
#property indicator_type1   DRAW_COLOR_CANDLES
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
#include <ColoredTrend.mqh>

//+----------------------------------------------------------------+
//|  ���������� ������������ ��������-������������ �������         |
//+----------------------------------------------------------------+
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
double ExtColorsBuffer[];

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

CColoredTrend trend(Symbol(), bars, historyDepth);
string symbol;
ENUM_TIMEFRAMES current_timeframe;
int digits;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- ������������� ���������� ����������  
  symbol = Symbol();
  current_timeframe = Period();
  digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
//---- ����������� ������������ �������� � ������������ ������
   SetIndexBuffer(0, ExtOpenBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ExtLowBuffer, INDICATOR_DATA);
   //SetIndexBuffer(3, ExtCloseBuffer, INDICATOR_DATA);
   
   Print("������������ ����� �������� ���������� = ",ArrayGetAsSeries(ExtCloseBuffer));
   SetIndexBuffer(0,ExtCloseBuffer,INDICATOR_DATA);
   Print("������������ ����� ����� SetIndexBuffer() �������� ���������� = ",
         ArrayGetAsSeries(ExtCloseBuffer));
   
//---- ����������� ������������� ������� � ��������, ��������� �����   
   SetIndexBuffer(4, ExtColorsBuffer, INDICATOR_COLOR_INDEX);
//---- ������������� ������ ������ ������� ��������� ����������
   PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, bars + 1);
//--- ��������� ���������� ������ 11 ��� ��������� ������
// PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,11);
//---- ��������� ������� �������� ����������� ����������
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//---- ��� ��� ���� ������ � ����� ��� ����
   string short_name="ColoredTrend";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,     // ���������� ������� � ����� �� ������� ����
                const int prev_calculated, // ���������� �����, ������������ �� ���������� ����
                const datetime &time[],
                const double &open[],      // ������� �� ���������
                const double &high[],
                const double &low[],
                const double &close[],     // close[rates_total - 2] - ��������� ������������� close
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {//--- ��������� �������� ���������� ������� � ����� MABuffer
   
   Print("������������ ����� �������� ���������� = ",ArrayGetAsSeries(close));
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
