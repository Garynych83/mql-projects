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
//| ���������, ������������ ����������� BlauMtm                      |
//| 1) ������ ����� BlauMtm                                          |
//| 2) ������ ������� ����������� �� BlauMtm � �� ������� ����       |
//| 3) ������ ����������� ������ ������������� �������               |
//| 4) ������ �������� ����������� � ����������� �� ����             |
//+------------------------------------------------------------------+

// ��������� ��������
#define BUY   1    
#define SELL -1

// ���������� ���������� 
#include <Lib CisNewBar.mqh>                          // ��� �������� ������������ ������ ����
#include <Divergence/divergenceBlauMtm.mqh>           // ���������� ���������� ��� ������ ����������� BlauMtm
#include <ChartObjects/ChartObjectsLines.mqh>         // ��� ��������� ����� �����������
#include <CompareDoubles.mqh>                         // ��� �������� �����������  ���
#include <CLog.mqh>

// ������� ���������������� ��������� ����������
sinput string              blau_params   = "";        // ��������� ���������� 
input int                  q=2;                       // q - ������, �� �������� ����������� ��������
input int                  r=20;                      // r - ������ 1-� EMA, ������������� � ���������
input int                  s=5;                       // s - ������ 2-� EMA, ������������� � ���������� ������� �����������
input int                  u=3;                       // u - ������ 3-� EMA, ������������� � ���������� ������� �����������

// ��������� ������������ ������� 
#property indicator_buffers 4                         // ������������� 4 ������������ ������
#property indicator_plots   1                         // 1 ����� ������������ �� ��������

// ��������� �������

// ����� ���������� Blau
#property indicator_type1 DRAW_LINE                   // �����
#property indicator_color1  clrWhite                  // ���� �����
#property indicator_width1  1                         // ������� �����
#property indicator_style1 STYLE_SOLID                // ����� �����
#property indicator_label1  "BLAU"                    // ������������ ������

// ���������� ���������� ����������
int                handleBlau;                        // ����� Blau
int                lastBarIndex;                      // ������ ���������� ���� 
int                retCode;                           // ��� ������ ���������� ����������  �����������  
long               countDiv;                          // ������� ����� ����� (��� ��������� ����� �����������) 

PointDivBlau       divergencePoints;                  // ����� ����������� Blau �� ������� ������� � �� ������� Blau
CChartObjectTrend  trendLine;                         // ������ ������ ��������� ����� (��� ����������� �����������)
CChartObjectVLine  vertLine;                          // ������ ������ ������������ �����
CisNewBar          isNewBar;                          // ��� �������� ������������ ������ ����
 
// ������ ���������� 
double bufferBlau[];                                  // ����� ������� Blau
double bufferDiv[];                                   // ����� �������� �����������
double bufferExtrLeft[];                              // ����� ������� �����  �����������
double bufferExtrRight[];                             // ����� ������� ������ �����������

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
   ArraySetAsSeries(bufferExtrLeft,true);
   ArraySetAsSeries(bufferExtrRight,true);   
   // ��������� ����� ���������� Blau
   handleBlau = iCustom(_Symbol,_Period,"Blau_Mtm",q,r,s,u);
   if ( handleBlau == INVALID_HANDLE)  // ���� �� ������� ��������� ����� ����������
    {
     return(INIT_FAILED);  // �� ������������� ����������� �� �������
    }  
   // ������� ��� ����������� ������� (����� �����������, � ����� ����� ��������� �������� �����������)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // ��� ��������� ����� � �������� ������� 
   ObjectsDeleteAll(0,1,OBJ_TREND); // ��� ��������� ����� � ��������� �������
   ObjectsDeleteAll(0,0,OBJ_VLINE); // ��� ������������ �����, ������������ ������ ������������� �����������
   // ��������� ���������� � �������� 
   SetIndexBuffer(0,bufferBlau,INDICATOR_DATA);              // ����� Blau
   SetIndexBuffer(1,bufferDiv ,INDICATOR_CALCULATIONS);      // ����� ����������� (�������� ������������� ��������)
   SetIndexBuffer(2,bufferExtrLeft,INDICATOR_CALCULATIONS);  // ����� ������� ����� �����������
   SetIndexBuffer(3,bufferExtrRight,INDICATOR_CALCULATIONS); // ����� ������� ������ �����������
   // ������������� ����������  ����������
   countDiv = 0;                                             // ���������� ��������� ���������� �����������
   return(INIT_SUCCEEDED);                                   // �������� ���������� ������������� ����������
  }

// ��������������� ����������
void OnDeinit(const int reason)
 {
   // ������� ��� ����������� ������� (����� �����������, � ����� ����� ��������� �������� �����������)  
   ObjectsDeleteAll(0,0,OBJ_TREND); // ��� ��������� ����� � �������� ������� 
   ObjectsDeleteAll(0,1,OBJ_TREND); // ��� ��������� ����� � ��������� �������
   ObjectsDeleteAll(0,0,OBJ_VLINE); // ��� ������������ �����, ������������ ������ ������������� �����������
   // ������� ������������ ������
   ArrayFree(bufferBlau);
   ArrayFree(bufferDiv);
   ArrayFree(bufferExtrLeft);
   ArrayFree(bufferExtrRight);
   // ����������� ����� ����������
   IndicatorRelease(handleBlau);
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
      if ( CopyBuffer(handleBlau,0,0,rates_total,bufferBlau) < 0 )
           {
             // ���� �� ������� ��������� ������ Blau
             Print("������ ���������� smydBLAU. �� ������� ��������� ����� ���������� Blau");
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
            Print("������ ���������� smydBLAU. �� ������� ���������� ���������� �������� ��� � ���������");
            return (0);
          }
       // �������� �� ���� ����� ������� � ���� ����������� ����������
       for (lastBarIndex = rates_total-101;lastBarIndex > 0; lastBarIndex--)
        {
          // �������� ����� �������� ����������� ����������
          bufferDiv[lastBarIndex] = 0;
          // �������� ������ �����������
          bufferExtrLeft[lastBarIndex]  = 0;
          bufferExtrRight[lastBarIndex] = 0;
          retCode = divergenceBlau(handleBlau, _Symbol, _Period,/* top_level, bottom_level,*/ divergencePoints, 0,lastBarIndex);
          // ���� �� ������� ��������� ������ ����������
          if (retCode == -2)
           {
             Print("������ ���������� smydBlau. �� ������� ��������� ������ Blau");
             return (0);
           }
          // ���� BUY � ����� ����������� ���� �� ��������� � ���������� ������������ 
          if (retCode == BUY && datetime(divergencePoints.timeExtrPrice1) != onePointBuy
                             && datetime(divergencePoints.timeExtrPrice2) != onePointBuy
                             && datetime(divergencePoints.timeExtrPrice1) != twoPointBuy
                             && datetime(divergencePoints.timeExtrPrice2) != twoPointBuy
                              
                 )
           {             
                                        
             DrawIndicator (time[lastBarIndex]);   // ���������� ����������� �������� ����������     
             bufferDiv[lastBarIndex] = retCode;    // ��������� � ����� ��������  
             bufferExtrLeft[lastBarIndex]  = double(divergencePoints.timeExtrPrice2);  // �������� ����� ������  ����������
             bufferExtrRight[lastBarIndex] = double(divergencePoints.timeExtrPrice1);  // �������� ����� ������� ����������    
             // ��������� ����� ����������� ���
             onePointBuy =  divergencePoints.timeExtrPrice1;
             twoPointBuy =  divergencePoints.timeExtrPrice2;
           }
          // ���� SELL � ����� ����������� ���� �� ��������� � ���������� ������������ 
          if (retCode == SELL && datetime(divergencePoints.timeExtrPrice1) != onePointSell
                            && datetime(divergencePoints.timeExtrPrice2) != onePointSell
                            && datetime(divergencePoints.timeExtrPrice1) != twoPointSell
                            && datetime(divergencePoints.timeExtrPrice2) != twoPointSell
                              
                 )
           {             
                                        
             DrawIndicator (time[lastBarIndex]);   // ���������� ����������� �������� ����������     
             bufferDiv[lastBarIndex] = retCode;    // ��������� � ����� �������� 
             bufferExtrLeft[lastBarIndex]  = double(divergencePoints.timeExtrPrice2); // �������� ����� ������  ����������
             bufferExtrRight[lastBarIndex] = double(divergencePoints.timeExtrPrice1); // �������� ����� ������� ����������      
      
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
         // �������� ������ �����������
          bufferExtrLeft[0]  = 0;
          bufferExtrRight[0] = 0;          
          if ( CopyBuffer(handleBlau,0,0,rates_total,bufferBlau)    < 0  )
           {
             // ���� �� ������� ��������� ������ Blau
             Print("������ ���������� ShowMeYourDivSTOC. �� ������� ��������� ������ STOC");
             return (rates_total);
           }   
          //Print(); 
      //    Print("����� �� OnCalculate = ",TimeToString(time[0]) );
           
           retCode = divergenceBlau(handleBlau, _Symbol, _Period,/* top_level, bottom_level, */divergencePoints,time[0], 0);  // �������� ������ �� �����������
           //log_file.Write(LOG_DEBUG, StringFormat("����� �� OnCalculate = %s retCode = %i",TimeToString(time[0]),retCode) );
          // ���� �� ������� ��������� ������ Blau
          if (retCode == -2)
           {
             Print("������ ���������� smyBlau. �� ������� ��������� ������ Blau");
             return (0);
           }

          // ���� BUY � ����� ����������� ���� �� ��������� � ���������� ������������ 
          if (retCode == BUY && datetime(divergencePoints.timeExtrPrice1) != onePointBuy
                             && datetime(divergencePoints.timeExtrPrice2) != onePointBuy
                             && datetime(divergencePoints.timeExtrPrice1) != twoPointBuy
                             && datetime(divergencePoints.timeExtrPrice2) != twoPointBuy
                              
                 )
           {             
                                        
             DrawIndicator (time[0]);   // ���������� ����������� �������� ����������     
             bufferDiv[0] = retCode;                               // ��������� � ����� ��������    
             bufferExtrLeft[0]  = double(divergencePoints.timeExtrPrice2); // �������� ����� ������  ����������
             bufferExtrRight[0] = double(divergencePoints.timeExtrPrice1); // �������� ����� ������� ����������  
      
             // ��������� ����� ����������� ���
             onePointBuy =  divergencePoints.timeExtrPrice1;
             twoPointBuy =  divergencePoints.timeExtrPrice2;
           }
          // ���� SELL � ����� ����������� ���� �� ��������� � ���������� ������������ 
          if (retCode == SELL && datetime(divergencePoints.timeExtrPrice1) != onePointSell
                            && datetime(divergencePoints.timeExtrPrice2) != onePointSell
                            && datetime(divergencePoints.timeExtrPrice1) != twoPointSell
                            && datetime(divergencePoints.timeExtrPrice2) != twoPointSell
                              
                 )
           {             
                                        
             DrawIndicator (time[0]);   // ���������� ����������� �������� ����������     
             bufferDiv[0] = retCode;    // ��������� � ����� ��������
             bufferExtrLeft[0]  = double(divergencePoints.timeExtrPrice2); // �������� ����� ������  ����������
             bufferExtrRight[0] = double(divergencePoints.timeExtrPrice1); // �������� ����� ������� ����������      
       //lastBarIndex
             // ��������� ����� ����������� ���
             onePointSell =  divergencePoints.timeExtrPrice1;
             twoPointSell =  divergencePoints.timeExtrPrice2;
         
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
   trendLine.Create(0,"STOCLine_"+IntegerToString(countDiv),1,divergencePoints.timeExtrBlau1,divergencePoints.valueExtrBlau1,divergencePoints.timeExtrBlau2,divergencePoints.valueExtrBlau2);            
   vertLine.Color(clrRed);
   // ������� ������������ �����, ������������ ������ ��������� ����������� ����������
   vertLine.Create(0,"STOCVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // ����������� ���������� ������������ ���������
 }