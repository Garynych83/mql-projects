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
#include <divergenceMACD.mqh>                 // ���������� ���������� ��� ������ ��������� � ����������� ����������
#include <ChartObjects\ChartObjectsLines.mqh> // ��� ��������� ����� ���������\�����������
#include <CompareDoubles.mqh>                 // ��� �������� �����������  ���
#include <kernel32.mqh>                       // ���������� kernel32

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
input string              file_url;                  // url ����� ����� ���������� 


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
//| ������ �����������                                               |
//+------------------------------------------------------------------+

double bufferMACD[];   // ����� ������� MACD
double signalMACD[];   // ���������� ����� MACD

 int countConvPos = 0;       // ���������� ������������� �������� ���������
 int countConvNeg = 0;       // ���������� ���������� �������� ���������
 int countDivPos  = 0;       // ���������� ������������� �������� �����������
 int countDivNeg  = 0;       // ���������� ���������� �������� ����������� 
 
// ��������� ���������� ��� �������� ��������� ��������� � ����������
 double localMax;
 double localMin;

// ����� ����� ���������� ��������� \ ����������� 
 int file_handle;   
 
//+------------------------------------------------------------------+
//| ������� ������� ����������                                       |
//+------------------------------------------------------------------+

int OnInit()
  {     
   // ������� ���� ���������� 
   file_handle = CreateFileW(file_url, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL); 
   if(file_handle <= 0 )
    {
     Alert("�� �������� ������� ���� ����������� ��������");
     return(INIT_FAILED);
    }
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
          // ��������� ������� �� ������ �� ������� �����������\��������� 
          retCode = divergenceMACD (handleMACD,_Symbol,_Period,lastBarIndex,divergencePoints);
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
            
            localMax = high[lastBarIndex];
            localMin = low[lastBarIndex];
            for (count=1;count<=depth;count++)
             {
              if (high[lastBarIndex-count] > localMax)
               localMax = high[lastBarIndex-count];
              if (low[lastBarIndex-count] < localMin)
               localMin = low[lastBarIndex-count];
             } 
             
            if (retCode == 1)
             {
               if ( GreatDoubles ( (localMax - close[lastBarIndex]), (close[lastBarIndex] - localMin) ) )
                 {
                   countDivPos ++; // ����������� ������� ������������� ���������
                 }
               else
                 {
                   countDivNeg ++; // ����� ����������� ������� ������������� ���������
                 }
             }
            if (retCode == -1)
             {
               if (LessDoubles ( (localMax - close[lastBarIndex]), (close[lastBarIndex] - localMin) ) )
                 {
                  countConvPos ++; // ����������� ������� ������������� �����������
                 }
               else
                 {
                  countConvNeg ++; // ����� ����������� ������� ������������� �����������
                 }   
             }
        
           }
        }
        
    Alert("________________________________________");
    Alert("�� ���������� �����������: ",countDivNeg);
    Alert("���������� �����������: ",countDivPos);
    Alert("����� �����������: ",countDivPos+countDivNeg);
    Alert("�� ���������� ���������: ",countConvNeg);
    Alert("���������� ���������: ",countConvPos);
    Alert("����� ���������: ",countConvPos+countConvNeg);
    Alert("���������� ������ ���������\�����������:");
        
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
         retCode = divergenceMACD (handleMACD,_Symbol,_Period,1,divergencePoints);
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
