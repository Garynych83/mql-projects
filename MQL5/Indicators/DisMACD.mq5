//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <Lib CisNewBar.mqh>                  // ��� �������� ������������ ������ ����
#include <divergenceMACD.mqh>                 // ���������� ���������� ��� ������ ��������� � ����������� MACD
#include <ChartObjects\ChartObjectsLines.mqh> 

//+------------------------------------------------------------------+
//| ��������� ����������                                             |
//+------------------------------------------------------------------+

#property indicator_buffers 1
//---- ������������ 1 ����������� ����������
#property indicator_plots   1
//---- � �������� ���������� ������������ �������
#property indicator_type1 DRAW_SECTION
//---- ���� ����������
#property indicator_color1  clrBlue
//---- ����� ����� ����������
#property indicator_style1  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width1  1
//---- ����������� ����� ����� ����������
#property indicator_label1  "Divergence MACD"

//+------------------------------------------------------------------+
//| �������� ��������� ����������                                    |
//+------------------------------------------------------------------+

input short               bars=2000;                  // ��������� ���������� ����� �������
input int                 fast_ema_period=9;         // ������ ������� �������
input int                 slow_ema_period=12;        // ������ ��������� �������
input int                 signal_period=6;           // ������ ���������� ��������
input uint                priceDifference=0;         // ������� ��� ��� ������ ����������   

//+------------------------------------------------------------------+
//| ���������� ����������                                            |
//+------------------------------------------------------------------+

int             handleMACD;            // ����� MACD
//string          symbol = _Symbol;          // ������� ������
//ENUM_TIMEFRAMES timeFrame = _Period;       // ������� ���������

double          line_buffer[];             // ����� ����� ����� 

bool            first_calculate = true;    // ���� ������� ������ OnCalculate

PointDiv        divergencePoints;          // ��������� � ����������� MACD

int             lastBarIndex;              // ������ ���������� ����    

CChartObjectTrend  trendLine;            // ������ ������ ��������� �����

//int countTrend = 0;                        // ���������� ����� ����� 

//+------------------------------------------------------------------+
//| ������� ������� ����������                                       |
//+------------------------------------------------------------------+

int OnInit()
  {
   // ��������� ����� ���������� MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE); 
   // ��������� ����� �����
   SetIndexBuffer(0,line_buffer,    INDICATOR_DATA);     
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
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
    int indexBar; // ������ ������� �� ����� 
    int retCode;  // ��������� ���������� ��������� � �����������
    // ���� ��� ������ ������ ������ ��������� ����������
    if (first_calculate)
     {
       if (bars > (rates_total-1) )
        {
         lastBarIndex = 0;
        }
       else
        {
         lastBarIndex = rates_total - bars - 1;
        }
       for (indexBar=lastBarIndex;indexBar < (rates_total-100-1); indexBar++)
        {
        //  Alert("indexBar = ",indexBar," ");
          // ��������� ������� �� ������ �� ������� �����������\��������� 
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,indexBar,divergencePoints);
          // ���� ���������\����������� ����������
          if (retCode)
           {
           // Alert("���� = ",time[indexBar]);

        //    ArrayResize(trendLine,ArraySize(trendLine)+1);
            
            divergencePoints.extrMACD1 = time[indexBar];
            divergencePoints.valuePrice1 = high[indexBar];
            divergencePoints.extrPrice2 = time[indexBar-2];
            divergencePoints.valuePrice2 = high[indexBar-2];
            trendLine.Create(0,"TrendLine_"+indexBar,0,divergencePoints.extrMACD1,divergencePoints.valuePrice1,divergencePoints.extrPrice2,divergencePoints.valuePrice2);
        //    first_calculate = false;
          //  return(rates_total);
           }
        }
       first_calculate = false;
     }
    
    return(rates_total);
  }
