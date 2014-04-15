//+------------------------------------------------------------------+
//|                                                     smydMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window   // ����� ������������� �������� ���� ����������

//+------------------------------------------------------------------+
//| ���������, ������������ ����������� MACD                         |
//| 1) ������ MACD                                                   |
//| 2) ������ ������� ����������� �� MACD � �� ������� ����          |
//| 3) ������ ����������� ������ ������������� �������               |
//+------------------------------------------------------------------+

// ���������� ���������� 
#include <Lib CisNewBar.mqh>                       // ��� �������� ������������ ������ ����
#include <Divergence/divergenceMACD.mqh>           // ���������� ���������� ��� ������ ����������� MACD
#include <ChartObjects/ChartObjectsLines.mqh>      // ��� ��������� ����� �����������
#include <CompareDoubles.mqh>                      // ��� �������� �����������  ���

// ������� ���������������� ��������� ����������
sinput string macd_params     = "";                // ��������� ���������� MACD
input  int    fast_ema_period = 12;                // ������ ������� ������� MACD
input  int    slow_ema_period = 26;                // ������ ��������� ������� MACD
input  int    signal_period   = 9;                 // ������ ���������� �������� MACD
input  ENUM_APPLIED_PRICE priceType = PRICE_CLOSE; // ��� ���, �� ������� ����������� MACD

// ��������� ������������ ������� 
#property indicator_buffers 3                      // ������������� 3 ������������ ������
#property indicator_plots   2                      // 2 ������ ������������ �� ��������

// ��������� �������

// ��������� 1-�� ������ (MACD)
#property indicator_type1 DRAW_HISTOGRAM           // �����������
#property indicator_color1  clrWhite               // ���� �����������
#property indicator_width1  1                      // ������� �����������
#property indicator_label1  "MACD"                 // ������������ ������

// ��������� 2-�� ������ (���������� ����� MACD)
#property indicator_type2 DRAW_LINE                // �����
#property indicator_color2  clrRed                 // ���� �����
#property indicator_width2  1                      // ������� �����
#property indicator_style2  STYLE_DASHDOT          // ����� �����
#property indicator_label2  "SIGNAL"               // ������������ ������

// ���������� ���������� ����������
int                handleMACD;                     // ����� MACD
int                lastBarIndex;                   // ������ ���������� ���� 
int                retCode;                        // ��� ������ ���������� ����������  �����������  
long               countDiv;                       // ������� ����� ����� (��� ��������� ����� �����������) 

PointDivMACD       divergencePoints;               // ����� ����������� MACD �� ������� ������� � �� ������� MACD
CChartObjectTrend  trendLine;                      // ������ ������ ��������� ����� (��� ����������� �����������)
CisNewBar          isNewBar;                       // ��� �������� ������������ ������ ����

// ������ ���������� 
double bufferMACD[];                               // ����� ������� MACD
double signalMACD[];                               // ���������� ����� MACD
double bufferDiv[];                                // ����� �������� �����������

   
// ������������� ����������
int OnInit()
  {
   // ��������� ����� ���������� MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   if ( handleMACD == INVALID_HANDLE)  // ���� �� ������� ��������� ����� MACD
    {
     return(INIT_FAILED);  // �� ������������� ����������� �� �������
    }  
   // ������� ��� ����������� ������� (����� �����������, � ����� ����� ��������� �������� �����������)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // ��� ��������� ����� � �������� ������� 
   ObjectsDeleteAll(0,1,OBJ_TREND); // ��� ��������� ����� � ��������� �������
   ObjectsDeleteAll(0,0,OBJ_VLINE); // ��� ������������ �����, ������������ ������ ������������� �����������
   // ��������� ���������� � �������� 
   SetIndexBuffer(0,bufferMACD,INDICATOR_DATA);         // ����� MACD
   SetIndexBuffer(1,signalMACD,INDICATOR_DATA);         // ����� ���������� �����
   SetIndexBuffer(2,bufferDiv ,INDICATOR_CALCULATIONS); // ����� ����������� (�������� ������������� ��������)
   // ������������� ����������  ����������
   countDiv = 0;                                        // ���������� ��������� ���������� �����������
   return(INIT_SUCCEEDED); // �������� ���������� ������������� ����������
  }

// ��������������� ����������
void OnDeinit()
 {
   // ������� ��� ����������� ������� (����� �����������, � ����� ����� ��������� �������� �����������)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // ��� ��������� ����� � �������� ������� 
   ObjectsDeleteAll(0,1,OBJ_TREND); // ��� ��������� ����� � ��������� �������
   ObjectsDeleteAll(0,0,OBJ_VLINE); // ��� ������������ �����, ������������ ������ ������������� �����������
   // ������� ������������ ������
   ArrayFree(bufferMACD);
   ArrayFree(signalMACD);
   ArrayFree(bufferDiv);
   // ����������� ����� MACD
   IndicatorRelease(handleMACD);
 }

// ������� ������� ������� ����������
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
   if (prev_calculated == 0) // ���� �� ����. ������ ���� ���������� 0 �����, ������ ���� ����� ������
    {
      // �������� ����� MACD
      if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0 ||
           CopyBuffer(handleMACD,1,0,rates_total,signalMACD) < 0 )
           {
             // ���� �� ������� ��������� ������ MACD
             Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
             return (0); 
           }                
      // ������� ���������� ������ �������� ��� � ���������
      if ( !ArraySetAsSeries (time,true) || 
           !ArraySetAsSeries (open,true) || 
           !ArraySetAsSeries (high,true) ||
           !ArraySetAsSeries (low,true)  || 
           !ArraySetAsSeries (close,true) )
          {
            // ���� �� ������� ����������� ���������� ��� � ��������� ��� ���� �������� ��� � �������
            Print("������ ���������� ShowMeYourDivMACD. �� ������� ���������� ���������� �������� ��� � ���������");
            return (0);
          }
       // �������� �� ���� ����� ������� � ���� ����������� MACD
       for (lastBarIndex = rates_total-101;lastBarIndex > 0; lastBarIndex--)
        {
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,lastBarIndex);  // �������� ������ �� �����������
          // ���� �� ������� ��������� ������ MACD
          if (retCode == -2)
           {
             Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
             return (0);
           }
          if (retCode)
           {                                          
            trendLine.Color(clrYellow);
            //������� ����� ���������\�����������                    
            trendLine.Create(0,"MacdPriceLine_"+countDiv,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
            trendLine.Color(clrYellow);         
            //������� ����� ���������\����������� �� MACD
            trendLine.Create(0,"MACDLine_"+countDiv,1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);            
            countDiv++; // ����������� ���������� ������������ ���������
           }
        }
          
      // Salnikova    
                             
    }
   return(rates_total);
  }