//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//#property indicator_chart_window
#property indicator_separate_window
#include <Lib CisNewBar.mqh>                  // ��� �������� ������������ ������ ����
#include <divergenceMACD.mqh>                 // ���������� ���������� ��� ������ ��������� � ����������� MACD
#include <ChartObjects\ChartObjectsLines.mqh> // ��� ��������� ����� ���������\�����������

//+------------------------------------------------------------------+
//| �������� ����������                                              |
//+------------------------------------------------------------------+

//---- ����� ������������� 2 ������
#property indicator_buffers 2
//---- ������������ 1 ����������� ��� �������
#property indicator_plots   2

//---- � �������� ���������� ������������ �����
#property indicator_type1 DRAW_LINE
//---- ���� ����������
#property indicator_color1  clrBlue
//---- ����� ����� ����������
#property indicator_style1  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width1  1
//---- ����������� ����� ����� ����������
#property indicator_label1  "MACD"

//---- � �������� ���������� ������������ �����
#property indicator_type2 DRAW_LINE
//---- ���� ����������
#property indicator_color2  clrRed
//---- ����� ����� ����������
#property indicator_style2  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width2  1
//---- ����������� ����� ����� ����������
#property indicator_label2  "Signal"

//+------------------------------------------------------------------+
//| �������� ��������� ����������                                    |
//+------------------------------------------------------------------+

input short               bars=20000;                // ��������� ���������� ����� �������
input int                 fast_ema_period=12;        // ������ ������� ������� MACD
input int                 slow_ema_period=26;        // ������ ��������� ������� MACD
input int                 signal_period=9;           // ������ ���������� �������� MACD

//+------------------------------------------------------------------+
//| ������ ����������                                                |
//+------------------------------------------------------------------+

double bufferMACD[];   // �������� ����� MACD
double signalMACD[];   // ����� ���������� ����� MACD

//+------------------------------------------------------------------+
//| ���������� ����������                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // ���� ������� ������ OnCalculate
int                handleMACD;             // ����� MACD
int                lastBarIndex;           // ������ ���������� ����   
long               countTrend;             // ������� ����� �����

PointDiv           divergencePoints;       // ��������� � ����������� MACD
CChartObjectTrend  trendLine;              // ������ ������ ��������� �����
CisNewBar          isNewBar;               // ��� �������� ������������ ������ ����
 
//+------------------------------------------------------------------+
//| ������� ������� ����������                                       |
//+------------------------------------------------------------------+

int OnInit()
  {
   SetIndexBuffer(0,bufferMACD,INDICATOR_DATA);  
   SetIndexBuffer(1,signalMACD,INDICATOR_DATA);       
   // ������������� ����������  ����������
   first_calculate = true;
   countTrend = 0;
   // ��������� ����� ���������� MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   //IndicatorAdd(1,handleMACD);
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
    int retCode;  // ��������� ���������� ��������� � �����������
    // ���� ��� ������ ������ ������ ��������� ����������
    if (first_calculate)
     {
       if (bars < 100)
        {
         lastBarIndex = 1;
        }
       else if (bars > rates_total)
        {
         lastBarIndex = rates_total-101;
        }
       else
        {
         lastBarIndex = bars-101;
        }
       for (;lastBarIndex > 0; lastBarIndex--)
        {
          bufferMACD[lastBarIndex] = 0; 
          signalMACD[lastBarIndex] = 1;
          // ��������� ������� �� ������ �� ������� �����������\��������� 
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,lastBarIndex,divergencePoints);
          // ���� ���������\����������� ����������
          if (retCode)
           {    
            //������� ����� ���������\�����������                    
            trendLine.Create(0,"TrendLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);
            
            trendLine.Create(1,"MACDLine_"+countTrend,1,divergencePoints.timeExtrMACD1,0.5,divergencePoints.timeExtrMACD2,0.5);            
            //����������� ���������� ����� �����
            countTrend++;
           }
        }
       first_calculate = false;
     }
    else  // ���� ������� �� ������
     {
       // ���� ����������� ����� ���
       if (isNewBar.isNewBar() > 0)
        {
         bufferMACD[lastBarIndex] = 0;
         signalMACD[lastBarIndex] = 1;
         // ���������� ���������\�����������
         retCode = divergenceMACD (handleMACD,_Symbol,_Period,1,divergencePoints);
         // ���� ���������\����������� ����������
         if (retCode)
          {          
           // ������� ����� ���������\�����������              
           trendLine.Create(0,"TrendLine_"+countTrend,0,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);
           // ������� ����� ����� ������������ MACD
           
           // ����������� ���������� ����� �����
           countTrend++;
          }        
        }
     } 
    
    return(rates_total);
  }
