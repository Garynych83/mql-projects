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
#include <divergenceStochastic.mqh>           // ���������� ���������� ��� ������ ��������� � ����������� ����������
#include <ChartObjects\ChartObjectsLines.mqh> // ��� ��������� ����� ���������\�����������

 // ��������� ����������
 
//---- ����� ������������� 2 ������
#property indicator_buffers 2
//---- ������������ 2 ����������� ����������
#property indicator_plots   2

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
input int                 DEPTH_STOC=10;                // ������� ����� ������ 
input int                 ALLOW_DEPTH_FOR_PRICE_EXTR=3; // ����� ����� ������


//+------------------------------------------------------------------+
//| ���������� ����������                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // ���� ������� ������ OnCalculate
int                handleStoc;             // ����� ����������
int                lastBarIndex;           // ������ ���������� ����   
long               countTrend;             // ������� ����� �����

PointDiv           divergencePoints;       // ��������� � ����������� ����������
CChartObjectTrend  trendLine;              // ������ ������ ��������� �����
CisNewBar          isNewBar;               // ��� �������� ������������ ������ ����

double bufferStoc[];    // ����� ���������� 1
double bufferStoc2[];   // ����� ���������� 2
 
//+------------------------------------------------------------------+
//| ������� ������� ����������                                       |
//+------------------------------------------------------------------+

int OnInit()
  {
   // ������� ��� ����������� �������     
   ObjectsDeleteAll(0,0,OBJ_TREND);
   ObjectsDeleteAll(0,1,OBJ_TREND);   
   // ��������� ��������� � �������
   SetIndexBuffer(0,bufferStoc,INDICATOR_DATA);
   SetIndexBuffer(1,bufferStoc2,INDICATOR_DATA);   
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
          // ��������� ������� �� ������ �� ������� �����������\��������� 
          retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,DEPTH_STOC,ALLOW_DEPTH_FOR_PRICE_EXTR,divergencePoints,lastBarIndex);
          // ���� ���������\����������� ����������
          if (retCode)
           {                                     
          //  trendLine.Color(lineColors[countTrend % 5] );
            //������� ����� ���������\�����������                    
            trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
            
          //  trendLine.Color(lineColors[countTrend % 5] );         
            //������� ����� ���������\����������� �� ����������
            trendLine.Create(0,"StocLine_"+countTrend,1,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);            
            //����������� ���������� ����� �����
            countTrend++;
           }
           else
           {
            return (0);
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
         // ���������� ���������\����������� ����������
         retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,DEPTH_STOC,ALLOW_DEPTH_FOR_PRICE_EXTR,divergencePoints,1);         
         // ���� ���������\����������� ����������
         if (retCode)
          {   
          // trendLine.Color(lineColors[countTrend % 5] );     
           // ������� ����� ���������\�����������              
           trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2); 
          // trendLine.Color(lineColors[countTrend % 5] );           
           //������� ����� ���������\����������� �� MACD
           trendLine.Create(0,"StocLine_"+countTrend,1,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);    
           // ����������� ���������� ����� �����
           countTrend++;
          }      
        }
     } 
       
    return(rates_total);
  }
