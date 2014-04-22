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
//| ���������, ������������ ����������� ����������                   |
//| 1) ������ ����� ����������                                       |
//| 2) ������ ������� ����������� �� ���������� � �� ������� ����    |
//| 3) ������ ����������� ������ ������������� �������               |
//+------------------------------------------------------------------+

// ���������� ���������� 
#include <Lib CisNewBar.mqh>                          // ��� �������� ������������ ������ ����
#include <Divergence/divergenceStochastic.mqh>        // ���������� ���������� ��� ������ ����������� MACD
#include <ChartObjects/ChartObjectsLines.mqh>         // ��� ��������� ����� �����������
#include <CompareDoubles.mqh>                         // ��� �������� �����������  ���

// ������� ���������������� ��������� ����������
sinput string macd_params              = "";          // ��������� ���������� MACD
input ENUM_MA_METHOD      ma_method    = MODE_SMA;    // ��� �����������
input ENUM_STO_PRICE      price_field  = STO_LOWHIGH; // ������ ������� ����������           
input int                 top_level    = 80;          // ������� ������� 
input int                 bottom_level = 20;          // ������ ������� 

// ��������� ������������ ������� 
#property indicator_buffers 3                         // ������������� 3 ������������ ������
#property indicator_plots   2                         // 2 ������ ������������ �� ��������

// ��������� �������

// top level �����
#property indicator_type1 DRAW_LINE                 // �����
#property indicator_color1  clrWhite                // ���� �����
#property indicator_width1  1                       // ������� �����
#property indicator_style1 STYLE_SOLID              // ����� �����
#property indicator_label1  "StochasticTopLevel"    // ������������ ������
// bottom level �����
#property indicator_type2 DRAW_LINE                 // �����
#property indicator_color2  clrRed                  // ���� �����
#property indicator_width2  1                       // ������� �����
#property indicator_style2 STYLE_SOLID              // ����� �����
#property indicator_label2  "StochasticBottomLevel" // ������������ ������


// ���������� ���������� ����������
int                handleSTOC;                      // ����� ����������
int                lastBarIndex;                    // ������ ���������� ���� 
int                retCode;                         // ��� ������ ���������� ����������  �����������  
long               countDiv;                        // ������� ����� ����� (��� ��������� ����� �����������) 

PointDivSTOC       divergencePoints;                // ����� ����������� ���������� �� ������� ������� � �� ������� ����������
CChartObjectTrend  trendLine;                       // ������ ������ ��������� ����� (��� ����������� �����������)
CChartObjectVLine  vertLine;                        // ������ ������ ������������ �����
CisNewBar          isNewBar;                        // ��� �������� ������������ ������ ����

// ������ ���������� 
double bufferTopLevel[];                            // ����� ������� top level
double bufferBottomLevel[];                         // ����� ������� bottom level
double bufferDiv[];                                 // ����� �������� �����������

// ����� ��� �������� ������� ����������� ����   

datetime onePointBuy  = 0;  
datetime twoPointBuy  = 0;

datetime onePointSell = 0;
datetime twoPointSell = 0;

// �������������� ������� ������ ����������
void    DrawIndicator (datetime vertLineTime);     // ���������� ����� ����������. � ������� ���������� ����� ������������ �����
   
// ������������� ����������
int OnInit()
  {  
   ArraySetAsSeries(bufferDiv,true);
   // ��������� ����� ���������� ����������
   handleSTOC = iStochastic(_Symbol,_Period,5,3,3,ma_method,price_field);
   if ( handleSTOC == INVALID_HANDLE)  // ���� �� ������� ��������� ����� ����������
    {
     return(INIT_FAILED);  // �� ������������� ����������� �� �������
    }  
   // ������� ��� ����������� ������� (����� �����������, � ����� ����� ��������� �������� �����������)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // ��� ��������� ����� � �������� ������� 
   ObjectsDeleteAll(0,1,OBJ_TREND); // ��� ��������� ����� � ��������� �������
   ObjectsDeleteAll(0,0,OBJ_VLINE); // ��� ������������ �����, ������������ ������ ������������� �����������
   // ��������� ���������� � �������� 
   SetIndexBuffer(0,bufferTopLevel,INDICATOR_DATA);     // ����� top level ����������
   SetIndexBuffer(1,bufferBottomLevel,INDICATOR_DATA);  // ����� bottom level ����������
   SetIndexBuffer(2,bufferDiv ,INDICATOR_CALCULATIONS); // ����� ����������� (�������� ������������� ��������)
   // ������������� ����������  ����������
   countDiv = 0;                                        // ���������� ��������� ���������� �����������
   return(INIT_SUCCEEDED); // �������� ���������� ������������� ����������
  }

// ��������������� ����������
void OnDeinit(const int reason)
 {
   // ������� ��� ����������� ������� (����� �����������, � ����� ����� ��������� �������� �����������)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // ��� ��������� ����� � �������� ������� 
   ObjectsDeleteAll(0,1,OBJ_TREND); // ��� ��������� ����� � ��������� �������
   ObjectsDeleteAll(0,0,OBJ_VLINE); // ��� ������������ �����, ������������ ������ ������������� �����������
   // ������� ������������ ������
   ArrayFree(bufferTopLevel);
   ArrayFree(bufferBottomLevel);
   ArrayFree(bufferDiv);
   // ����������� ����� ����������
   IndicatorRelease(handleSTOC);
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
      // �������� ����� ����������
      if ( CopyBuffer(handleSTOC,0,0,rates_total,bufferTopLevel)    < 0 ||
           CopyBuffer(handleSTOC,1,0,rates_total,bufferBottomLevel) < 0 )
           {
             // ���� �� ������� ��������� ������ ����������
             Print("������ ���������� ShowMeYourDivSTOC. �� ������� ��������� ������ ����������");
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
            Print("������ ���������� ShowMeYourDivSTOC. �� ������� ���������� ���������� �������� ��� � ���������");
            return (0);
          }
       // �������� �� ���� ����� ������� � ���� ����������� ����������
       for (lastBarIndex = rates_total-101;lastBarIndex > 0; lastBarIndex--)
        {
          // �������� ����� �������� ����������� ����������
          bufferDiv[lastBarIndex] = 0;
          retCode = divergenceSTOC(handleSTOC, _Symbol, _Period, top_level, bottom_level, divergencePoints, lastBarIndex);
          // ���� �� ������� ��������� ������ ����������
          if (retCode == -2)
           {
             Print("������ ���������� ShowMeYourDivSTOC. �� ������� ��������� ������ ����������");
             return (0);
           }
          // ���� BUY � ����� ����������� ���� �� ��������� � ���������� ������������ 
          if (retCode == 1 && divergencePoints.timeExtrPrice1 != onePointBuy
                           && divergencePoints.timeExtrPrice2 != onePointBuy
                           && divergencePoints.timeExtrPrice1 != twoPointBuy
                           && divergencePoints.timeExtrPrice2 != twoPointBuy
                              
                 )
           {             
                                        
             DrawIndicator (time[lastBarIndex]);   // ���������� ����������� �������� ����������     
             bufferDiv[lastBarIndex] = retCode;    // ��������� � ����� ��������      
             // ��������� ����� ����������� ���
             onePointBuy =  divergencePoints.timeExtrPrice1;
             twoPointBuy =  divergencePoints.timeExtrPrice2;
           }
          // ���� SELL � ����� ����������� ���� �� ��������� � ���������� ������������ 
          if (retCode == -1 && divergencePoints.timeExtrPrice1 != onePointSell
                           && divergencePoints.timeExtrPrice2 != onePointSell
                           && divergencePoints.timeExtrPrice1 != twoPointSell
                           && divergencePoints.timeExtrPrice2 != twoPointSell
                              
                 )
           {             
                                        
             DrawIndicator (time[lastBarIndex]);   // ���������� ����������� �������� ����������     
             bufferDiv[lastBarIndex] = retCode;    // ��������� � ����� ��������      
             // ��������� ����� ����������� ���
             onePointSell =  divergencePoints.timeExtrPrice1;
             twoPointSell =  divergencePoints.timeExtrPrice2;
           }           
        }
    }
    else    // ���� ��� �� ������ ����� ���������� 
     {
       // ���� ������������� ����� ���
       if (isNewBar.isNewBar() > 0 )
        {
              // ������� ���������� ������ �������� ��� � ���������
          if ( !ArraySetAsSeries (time,true) || 
               !ArraySetAsSeries (open,true) || 
               !ArraySetAsSeries (high,true) ||
               !ArraySetAsSeries (low,true)  || 
               !ArraySetAsSeries (close,true) )
              {
               // ���� �� ������� ����������� ���������� ��� � ��������� ��� ���� �������� ��� � �������
               Print("������ ���������� ShowMeYourDivSTOC. �� ������� ���������� ���������� �������� ��� � ���������");
               return (rates_total);
              }
          // �������� ����� ������� �����������
          bufferDiv[0] = 0;
          if ( CopyBuffer(handleSTOC,0,0,rates_total,bufferTopLevel)    < 0 ||
               CopyBuffer(handleSTOC,1,0,rates_total,bufferBottomLevel) < 0 )
           {
             // ���� �� ������� ��������� ������ ����������
             Print("������ ���������� ShowMeYourDivSTOC. �� ������� ��������� ������ STOC");
             return (rates_total);
           }   
          retCode = divergenceSTOC(handleSTOC, _Symbol, _Period, top_level, bottom_level, divergencePoints, 0);  // �������� ������ �� �����������
          // ���� �� ������� ��������� ������ ����������
          if (retCode == -2)
           {
             Print("������ ���������� ShowMeYourDivSTOC. �� ������� ��������� ������ ����������");
             return (0);
           }
          if (retCode)
           {                                        
             DrawIndicator (time[0]);       // ���������� ����������� �������� ����������    
             bufferDiv[0] = retCode;        // ��������� ������� ������
           }        
            
        }
     }
   return(rates_total);
  }
  
// ������� ����������� ����������� ��������� ����������
void DrawIndicator (datetime vertLineTime)
 {
   trendLine.Color(clrYellow);
   // ������� ����� ���������\�����������                    
   trendLine.Create(0,"STOCPriceLine_"+IntegerToString(countDiv),0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
   trendLine.Color(clrYellow);         
   // ������� ����� ���������\����������� �� ����������
   trendLine.Create(0,"STOCLine_"+IntegerToString(countDiv),1,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);            
   vertLine.Color(clrRed);
   // ������� ������������ �����, ������������ ������ ��������� ����������� ����������
   vertLine.Create(0,"STOCVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // ����������� ���������� ������������ ���������
 }