//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#include <Lib CisNewBar.mqh>                   // ��� �������� ������������ ������ ����
#include <Divergence/divergenceStochastic.mqh> // ���������� ���������� ��� ������ ��������� � ����������� ����������
#include <ChartObjects\ChartObjectsLines.mqh>  // ��� ��������� ����� ���������\�����������
#include <CompareDoubles.mqh>                  // ��� �������� �����������  ���

 // ��������� ����������
 
//---- ����� ������������� 2 ������
#property indicator_buffers 3
//---- ������������ 2 ����������� ����������
#property indicator_plots   3

//---- � �������� ���������� �������  ������������ �����
#property indicator_type1 DRAW_LINE
//---- ���� ����������
#property indicator_color1  clrWhite
//---- ������� ����� ����������
#property indicator_width1  1
//---- ����� �����
#property indicator_style1 STYLE_SOLID
//---- ����������� ����� ����� ����������
#property indicator_label1  "StochasticTopLevel"

//---- � �������� ���������� �������  ������������ �����
#property indicator_type2 DRAW_LINE
//---- ���� ����������
#property indicator_color2  clrRed
//---- ������� ����� ����������
#property indicator_width2  1
//---- ����� �����
#property indicator_style2  STYLE_DASHDOT
//---- ����������� ����� ����� ����������
#property indicator_label2  "StochasticBottomLevel"

//---- � �������� ���������� �������  ������������ 
#property indicator_type3 DRAW_ARROW
//---- ����������� ����� ����� ����������

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
input BARS_MODE           bars_mode=ALL_HISTORY;        // ����� �������� �������
input short               bars=20000;                   // ��������� ���������� ����� ������� (K-������)
input ENUM_MA_METHOD      ma_method=MODE_SMA;           // ��� �����������
input ENUM_STO_PRICE      price_field=STO_LOWHIGH;      // ������ ������� ����������           
input int                 top_level=80;                 // ������� ������� 
input int                 bottom_level=20;              // ������ ������� 


//+------------------------------------------------------------------+
//| ���������� ����������                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // ���� ������� ������ OnCalculate
int                handleStoc;             // ����� ����������
int                lastBarIndex;           // ������ ���������� ����   
long               countTrend;             // ������� ����� �����

PointDivSTOC       divergencePoints;       // ��������� � ����������� ����������
CChartObjectTrend  trendLine;              // ������ ������ ��������� �����
CChartObjectVLine  vertLine;               // ������ ������ ������������ �����
CisNewBar          isNewBar;               // ��� �������� ������������ ������ ����

double             bufferStoc[];           // ����� ���������� 1
double             bufferStoc2[];          // ����� ���������� 2
double             bufferArrow[];          // ����� ���������
 
// ��������� ���������� ��� �������� ��������� ��������� � ����������
 double localMax;
 double localMin;

// ������� � ����� �� ������� ���������� ���������\�����������

int count;


//+------------------------------------------------------------------+
//| ������� ������� ����������                                       |
//+------------------------------------------------------------------+

int OnInit()
  { 
   // ������� ��� ����������� �������     
   ObjectsDeleteAll(0,0,OBJ_TREND);
   ObjectsDeleteAll(0,1,OBJ_TREND);   
   ObjectsDeleteAll(0,0,OBJ_VLINE);
   // ��������� ��������� � �������
   SetIndexBuffer(0,bufferStoc,INDICATOR_DATA);
   SetIndexBuffer(1,bufferStoc2,INDICATOR_DATA);   
   SetIndexBuffer(2,bufferArrow,INDICATOR_DATA);
     
   //--- ������� ��� ������� ��� ��������� � PLOT_ARROW
   PlotIndexSetInteger(2,PLOT_ARROW,159);
   //--- ������� c������� ������� �� ��������� � �������� 
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,0);
   //--- ��������� � �������� ������� �������� 0
   PlotIndexSetDouble (2,PLOT_EMPTY_VALUE,0);

   
   // ������������� ����������  ����������
   first_calculate = true;
   countTrend = 1;
   // ��������� ����� ���������� ����������
   handleStoc = iStochastic(_Symbol,_Period,5,3,3,ma_method,price_field);
   return(INIT_SUCCEEDED);
  }

void OnDeinit ()
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
       // �������� ������ ����������
       if ( CopyBuffer(handleStoc,0,0,bars,bufferStoc) < 0 ||
            CopyBuffer(handleStoc,1,0,bars,bufferStoc2) < 0 )
           {
             // ���� �� ������� ��������� ������ ����������
             return (0);
           }    
       for (;lastBarIndex > 0; lastBarIndex--)
        {
          bufferArrow[rates_total-lastBarIndex-1] = 0;
          // ��������� ������� �� ������ �� ������� �����������\��������� 
          retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,divergencePoints,lastBarIndex);
          // ���� �� ������� ��������� �����
          if (retCode == -2)
           return (0);
          // ���� ���������\����������� ����������
          if (retCode)
           {                                     
            //������� ����� ���������\�����������                    
            trendLine.Create(0,"StoPriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
            //������� ������������ ����� 
            vertLine.Create(0,"VertLine_"+countTrend,0,time[rates_total-lastBarIndex-1]);    

            
           if (retCode == 1)
            bufferArrow[rates_total-lastBarIndex-1] = 1;
           if (retCode == -1)
            bufferArrow[rates_total-lastBarIndex-1] = -1;      
            
            //������� ����� ���������\����������� �� ����������
            trendLine.Create(0,"StocLine_"+countTrend,4,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);            
            
            //����������� ���������� ����� �����
            countTrend++;
             
            localMax = high[rates_total-1-lastBarIndex];
            localMin = low[rates_total-1-lastBarIndex];

             
  
                 }
                 }
                  
            
       first_calculate = false;
     }
    else  // ���� ������� �� ������
     { 
       // �������� ����� ����������
       if ( CopyBuffer(handleStoc,0,0,rates_total,bufferStoc) < 0 ||
            CopyBuffer(handleStoc,1,0,rates_total,bufferStoc2) < 0 )
           {
             // ���� �� ������� ��������� ������ ����������
             return (0);
           }                 
       // ���� ����������� ����� ���
       if (isNewBar.isNewBar() > 0)
        {        
         bufferArrow[rates_total-1] = 0;
         // ���������� ���������\����������� ����������
         retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,divergencePoints,0);         
         // ���� ���������\����������� ����������
         if (retCode)
          {   
          // trendLine.Color(lineColors[countTrend % 5] );     
           // ������� ����� ���������\�����������              
           trendLine.Create(0,"StoPriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2); 
          // trendLine.Color(lineColors[countTrend % 5] );
           //������� ������������ ����� 
           vertLine.Create(0,"VertLine_"+countTrend,0,time[rates_total-1]);  
           if (retCode == 1)
            bufferArrow[rates_total] = 1;
           if (retCode == -1)
            bufferArrow[rates_total] = -1;                            
           //������� ����� ���������\����������� �� MACD
           trendLine.Create(0,"StocLine_"+countTrend,4,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);    

           // ����������� ���������� ����� �����
           countTrend++;
          }      
        }
     } 
       
    return(rates_total);
  }
