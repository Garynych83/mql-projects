//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#include <Lib CisNewBar.mqh>                  // ��� �������� ������������ ������ ����
#include <Divergence/divergenceMACD.mqh>      // ���������� ���������� ��� ������ ��������� � ����������� ����������
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ���������\�����������
#include <CompareDoubles.mqh>                 // ��� �������� �����������  ���

// ��������� ����������
 
//---- ����� ������������� 2 ������
#property indicator_buffers 2
//---- ������������ 2 ����������� ����������
#property indicator_plots   2

//---- � �������� ���������� ������� MACD ������������ �����������
#property indicator_type1 DRAW_HISTOGRAM
//---- ���� ����������
#property indicator_color1  clrWhite
//---- ������� ����� ����������
#property indicator_width1  1
//---- ����������� ����� ����� ����������
#property indicator_label1  ""

//---- � �������� ���������� ������� MACD ������������ �����
#property indicator_type2 DRAW_LINE
//---- ���� ����������
#property indicator_color2  clrRed
//---- ����� ����� ����������
#property indicator_style2  STYLE_DOT
//---- ������� ����� ����������
#property indicator_width2  1
//---- ����������� ����� ����� ����������
#property indicator_label2  "SIGNAL"

 // ������������ ������ �������� ����� �������
 enum BARS_MODE
 {
  ALL_HISTORY=0, // ��� �������
  INPUT_BARS     // �������� ���������� ����� ������������
 };
 // ������ ������ ����� �����
 color lineColors[5]=
  {
   clrRed,
   clrBlue,
   clrYellow,
   clrGreen,
   clrGray
  };
//+------------------------------------------------------------------+
//| �������� ��������� ����������                                    |
//+------------------------------------------------------------------+
input BARS_MODE           bars_mode=ALL_HISTORY;     // ����� �������� �������
input short               bars=20000;                // ��������� ���������� ����� �������
input int                 fast_ema_period=12;        // ������ ������� ������� MACD
input int                 slow_ema_period=26;        // ������ ��������� ������� MACD
input int                 signal_period=9;           // ������ ���������� �������� MACD
input int                 depth=10;                  // ������� �������� ������������


//+------------------------------------------------------------------+
//| ���������� ����������                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // ���� ������� ������ OnCalculate
int                handleMACD;             // ����� MACD
int                lastBarIndex;           // ������ ���������� ����   
long               countTrend;             // ������� ����� �����

PointDivMACD       divergencePoints;       // ��������� � ����������� MACD
CChartObjectTrend  trendLine;              // ������ ������ ��������� �����
CisNewBar          isNewBar;               // ��� �������� ������������ ������ ����

//+------------------------------------------------------------------+
//| ������ �����������                                               |
//+------------------------------------------------------------------+

double bufferMACD[];   // ����� ������� MACD
double signalMACD[];   // ���������� ����� MACD

int countConvPos = 0;       // ���������� ������������� �������� ���������
int countConvNeg = 0;       // ���������� ���������� �������� ���������
int countDivPos  = 0;       // ���������� ������������� �������� �����������
int countDivNeg  = 0;       // ���������� ���������� �������� ����������� 

double averConvPos = 0;      // ������� ���������� ���������
double averConvNeg = 0;      // ������� �� ���������� ���������
double averDivPos  = 0;      // ������� ���������� �����������
double averDivNeg  = 0;      // ������� �� ���������� �����������
double averPos     = 0;      // ������� ���������� ������
double averNeg     = 0;      // ������� �� ���������� ������      
 
// ��������� ���������� ��� �������� ��������� ��������� � ����������
 double localMax;
 double localMin;

 
//+------------------------------------------------------------------+
//| ������� ������� ����������                                       |
//+------------------------------------------------------------------+

int OnInit()
  {     
   // ������� ��� ����������� �������     
   ObjectsDeleteAll(0,0,OBJ_TREND);
   ObjectsDeleteAll(0,1,OBJ_TREND);     
   // ��������� ���������� � �������� 
   SetIndexBuffer(0,bufferMACD,INDICATOR_DATA);
   SetIndexBuffer(1,signalMACD,INDICATOR_DATA);   
   // ������������� ����������  ����������
   first_calculate = true;
   countTrend = 1;
   // ��������� ����� ���������� MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
   return(INIT_SUCCEEDED);
  }

void OnDeinit()
 {

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
    int count;    // ������ ����� ��� ������ ��������� � ��������
    // ���� ��� ������ ������ ������ ��������� ����������
    if (first_calculate)
     {
      if (bars_mode == ALL_HISTORY)
       {
        lastBarIndex = rates_total - 101;
       }
      else
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
       }
       // �������� ����� MACD
       if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0 ||
            CopyBuffer(handleMACD,1,0,rates_total,signalMACD) < 0 )
           {
             // ���� �� ������� ��������� ������ MACD
             return (0);
           }                
       for (;lastBarIndex > depth; lastBarIndex--)
        {
       // int handleMACD, const string symbol, ENUM_TIMEFRAMES timeframe, PointDivMACD& div_point, int startIndex = 0
          // ��������� ������� �� ������ �� ������� �����������\��������� 
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,lastBarIndex);
          // ���� �� ������� ��������� ������ MACD)
          if (retCode == -2)
           return (0);
          // ���� ���������\����������� ����������
          if (retCode)
           {                                          
            trendLine.Color(lineColors[countTrend % 5] );
            //������� ����� ���������\�����������                    
            trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
            trendLine.Color(lineColors[countTrend % 5] );         
            //������� ����� ���������\����������� �� MACD
            trendLine.Create(0,"MACDLine_"+countTrend,1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);            
            //����������� ���������� ����� �����
            countTrend++;
            
            localMax = high[rates_total-2-lastBarIndex];
            localMin = low[rates_total-2-lastBarIndex];
            
            for (count=1;count<=depth;count++)
             {
              if (GreatDoubles (high[rates_total-2-lastBarIndex+count],localMax) )
               localMax = high[rates_total-2-lastBarIndex+count];
              if (LessDoubles (low[rates_total-2-lastBarIndex+count],localMin) )
               localMin = low[rates_total-2-lastBarIndex+count];
             } 
            if (retCode == 1)
             {                    
          
               if ( LessDoubles ( (localMax - close[rates_total-3-lastBarIndex]), (close[rates_total-3-lastBarIndex] - localMin) ) )
                 {
                   averDivPos  = averDivPos + close[rates_total-3-lastBarIndex+count] - localMin;
                   averPos     = averPos + close[rates_total-3-lastBarIndex+count] - localMin;
                   countDivPos ++; // ����������� ������� ������������� ���������
                 }
               else
                 {
                   averDivNeg = averDivNeg + close[rates_total-3-lastBarIndex] - localMax;  
                   averNeg     = averNeg + close[rates_total-3-lastBarIndex] - localMax;                 
                   countDivNeg ++; // ����� ����������� ������� ������������� ���������
                 }
             }
            if (retCode == -1)
             {
                        
               if (GreatDoubles ( (localMax - close[rates_total-3-lastBarIndex]), (close[rates_total-3-lastBarIndex] - localMin) ) )
                 {
                  averConvPos = averConvPos + localMax - close[rates_total-3-lastBarIndex];
                  averPos     = averPos + localMax - close[rates_total-3-lastBarIndex];
                  countConvPos ++; // ����������� ������� ������������� �����������
                 }
               else
                 {
                  averConvNeg = averConvNeg + localMin - close[rates_total-3-lastBarIndex];  
                  averNeg     = averNeg + localMin - close[rates_total-3-lastBarIndex];
                  countConvNeg ++; // ����� ����������� ������� ������������� �����������
                 }   
             }
        
           }
        }
     
    // ���������� ������� ��������
   if (countConvNeg > 0)
    averConvNeg = averConvNeg / countConvNeg;
   if (countConvPos > 0) 
    averConvPos = averConvPos / countConvPos;
   if (countDivNeg > 0)
    averDivNeg  = averDivNeg  / countDivNeg;
   if (countDivPos > 0)
    averDivPos  = averDivPos  / countDivPos;
   if (countConvNeg > 0 || countDivNeg > 0)
    averNeg     = averNeg     / (countConvNeg + countDivNeg);
   if (countConvPos > 0 || countDivPos > 0)
    averPos     = averPos     / (countConvPos + countDivPos);    
            
    
        
       first_calculate = false;
     }
    else  // ���� ������� �� ������
     { 
       // �������� ����� MACD
       if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0 ||
            CopyBuffer(handleMACD,1,0,rates_total,signalMACD) < 0 )
           {
             // ���� �� ������� ��������� ������ MACD
             Alert("����� ����");
             return (0);
           }                 
       // ���� ����������� ����� ���
       if (isNewBar.isNewBar() > 0)
        {        
         // ���������� ���������\�����������
         retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,1);
         // ���� ���������\����������� ����������
         if (retCode)
          {   
           trendLine.Color(lineColors[countTrend % 5] );     
           // ������� ����� ���������\�����������              
           trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2); 
           //������� ����� ���������\����������� �� MACD
           trendLine.Create(0,"MACDLine_"+countTrend,1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);    
           // ����������� ���������� ����� �����
           countTrend++;     
          
          }        
        }
     } 
    
    return(rates_total);
  }
