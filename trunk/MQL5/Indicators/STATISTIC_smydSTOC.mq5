//+------------------------------------------------------------------+
//|                                                     smydMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window   // ����� ������������� �������� ���� ����������

#include <StringUtilities.mqh>

//+------------------------------------------------------------------+
//| ���������, ������������ ����������� ����������                   |
//| 1) ������ ����� ����������                                       |
//| 2) ������ ������� ����������� �� ���������� � �� ������� ����    |
//| 3) ������ ����������� ������ ������������� �������               |
//| 4) �������� ���������� �����������                               |
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

sinput string stat_params     = "";                // ��������� ���������� ����������
input  int    actualBars      = 3;                // ���������� ����� ��� �������� ������������
input  string fileName        = "STOC_STAT_";   // ��� ����� ����������
input  datetime  start_time   = 1325361600;                 // ����, � ������� ������ ��������� ����������
input  datetime  finish_time  = 1397838300;                 // ����, �� ������� ��������� ����������
input  bool      useZoneAverage  = false;           // ������������ ������� �������� ��� ��������� ���������� �����������
input  double    ZoneLossBuy    = 0;               // ������� ������ ���������� ����������� �� BUY
input double ZoneProfitBuy      = 0;               // ������� ������� ���������� ����������� �� BUY
input double ZoneLossSell       = 0;               // ������� ������ ���������� ����������� �� SELL 
input double ZoneProfitSell     = 0;               // ������� ������� ���������� ����������� �� SELL

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

// ����� ����� ����������
int    fileHandle;

// ���������� ��� �������� ����������� ����������

double averActualProfitDivBuy   = 0;       // ������� ������������� ������� �� ����������� ����������� �� �������
double averActualLossDivBuy     = 0;       // ������� ������������� ������ ��� ���������� ����������� �� �������
double averActualProfitDivSell  = 0;       // ������� ������������� ������� �� ����������� ����������� �� �������
double averActualLossDivSell    = 0;       // ������� ������������� ������ ��� ���������� ����������� �� �������    

double averNotActualProfitDivBuy   = 0;    // ������� ������������� ������� �� �� ����������� ����������� �� �������
double averNotActualLossDivBuy     = 0;    // ������� ������������� ������ ��� �� ���������� ����������� �� �������
double averNotActualProfitDivSell  = 0;    // ������� ������������� ������� �� �� ����������� ����������� �� �������
double averNotActualLossDivSell    = 0;    // ������� ������������� ������ ��� �� ���������� ����������� �� �������                     

// �������� �����������
int    countActualDivBuy        = 0;       // ���������� ���������� ����������� �� �������
int    countDivBuy              = 0;       // ����� ���������� ����������� �� �������     
int    countActualDivSell       = 0;       // ��������� ���������� ����������� �� �������
int    countDivSell             = 0;       // ����� ���������� ����������� �� �������   

double zoneLossBuy = 0 ;                   // ������� ������ ���������� ����������� �� BUY
double zoneProfitBuy = 0;                  // ������� ������� ���������� ����������� �� BUY

double zoneLossSell = 0;                   // ������� ������ ���������� ����������� �� SELL 
double zoneProfitSell = 0;                 // ������� ������� ���������� ����������� �� SELL

int    countDivZoneLossBuy = 0;            // ���������� ����������� � ������� ���� ������ �� BUY
int    countDivZoneProfitBuy = 0;          // ���������� ����������� � �������� ���� ������ �� BUY

int    countDivZoneLossSell = 0;           // ���������� ���������� � ������� ���� ������ �� SELL
int    countDivZoneProfitSell = 0;         // ���������� ����������� � �������� ���� ������ �� SELL
                                                   
int    iterate;                            // ���������� ��������     

// �������������� ������� ������ ����������
void    DrawIndicator (datetime vertLineTime);     // ���������� ����� ����������. � ������� ���������� ����� ������������ �����
   
// ������������� ����������
int OnInit()
  {  
   // ������ ������ �����������, ���� �� ������ ������� ������� �������� 
   if (useZoneAverage)
     {
      zoneLossBuy = ZoneLossBuy;
      zoneLossSell = ZoneLossSell;
      zoneProfitBuy = ZoneProfitBuy;
      zoneProfitSell = ZoneProfitSell;
      iterate = 1;   // ������ ���� ������ �� �����
 
     }   
   else
     {
      iterate = 2;  // ��� ������� �� ����� ��� �������� ������� ��������
     }
   // ������� ���� ���������� �� ������
   fileHandle = FileOpen(fileName+_Symbol+"_"+PeriodToString(_Period)+".txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
   if (fileHandle == INVALID_HANDLE) //�� ������� ������� ����
    {
     Print("������ ���������� ShowMeYourDivSTOC. �� ������� ������� ���� ����������");
     return (INIT_FAILED);
    }    
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
   // ��������� ���� ���������� 
   if (fileHandle != INVALID_HANDLE)
   FileClose(fileHandle); 
     
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
   // ��������� ����������
   double maxPrice;          // ��������� �������� ���
   double minPrice;          // ��������� ������� ���
     
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
     // �������� � ����� 2 ���� (��� ���������� ��������
     for (int index=0;index<iterate;index++)
      {
       countDivZoneLossBuy    = 0;
       countDivZoneLossSell   = 0;
       countDivZoneProfitBuy  = 0;
       countDivZoneProfitSell = 0;          
       // �������� �� ���� ����� ������� � ���� ����������� ����������
       for (lastBarIndex = rates_total-DEPTH_STOC-1;lastBarIndex > 0; lastBarIndex--)
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
          if (retCode)
           {                                          
             DrawIndicator (time[lastBarIndex]);   // ���������� ����������� �������� ����������     
             bufferDiv[lastBarIndex] = retCode;    // ��������� � ����� ��������       
           
         // ��������� �������������� ������ �� ������� �����������
             if (time[lastBarIndex] >= start_time  && time[lastBarIndex] <= finish_time)   // ���� ������� ����� �������� � ���� ���������� ����������
              {
             // ��������� �������� �� ������� ���������� ������������
             maxPrice =  high[ArrayMaximum(high,lastBarIndex-actualBars,actualBars)];      // ������� �������� �� high
             minPrice =  low[ArrayMinimum(low,lastBarIndex -actualBars,actualBars)];       // ������� ������� �� low

             // ��������� ������������ �����������
             
             if (retCode == 1)      // ���� ����������� �� SELL
              {
               FileWriteString(fileHandle,""+TimeToString(time[lastBarIndex])+" (����������� �� SELL): \n { \n" );   
                countDivSell ++;    // ����������� ���������� ����������� �� SELL
                
                maxPrice = maxPrice - close[lastBarIndex];   // ���������, ��������� ���� ���� ����� �� ���� ��������
                minPrice = close[lastBarIndex] - minPrice;   // ���������, ��������� ���� ���� ���� �� ���� ��������
                
                if (maxPrice < 0)
                  maxPrice = 0;
                if (minPrice < 0)
                  minPrice = 0;
                
                if (minPrice > maxPrice)  // ������ ����������� �������� ����������
                 {
                   countActualDivSell ++;   // ����������� ���������� ���������� ����������� �� SELL
                   
                   averActualProfitDivSell = averActualProfitDivSell + minPrice; // ����������� ����� ��� ������� �������
                   averActualLossDivSell   = averActualLossDivSell   + maxPrice; // ����������� ����� ��� �������� ������
                   FileWriteString(fileHandle,"\n ������: ����������");
                   FileWriteString(fileHandle,"\n ������������� �������: "+DoubleToString(minPrice));
                   FileWriteString(fileHandle,"\n ������������� ������: "+DoubleToString(maxPrice));
                   FileWriteString(fileHandle,"\n}\n");                     
                 }
                else
                 {
                   averNotActualProfitDivSell = averNotActualProfitDivSell + minPrice; // ����������� ����� ��� ������� �������
                   averNotActualLossDivSell   = averNotActualLossDivSell   + maxPrice; // ����������� ����� ��� �������� ������
                   FileWriteString(fileHandle,"\n ������: �� ����������");
                   FileWriteString(fileHandle,"\n ������������� �������: "+DoubleToString(minPrice));
                   FileWriteString(fileHandle,"\n ������������� ������: "+DoubleToString(maxPrice));
                   FileWriteString(fileHandle,"\n}\n");                            
                 }
              }
             if (retCode == -1)     // ���� ����������� �� BUY
              {
               FileWriteString(fileHandle,""+TimeToString(time[lastBarIndex])+" (����������� �� BUY): \n { \n" );                 
                countDivBuy ++;     // ����������� ���������� ����������� �� BUY
                
                maxPrice = maxPrice - close[lastBarIndex];   // ���������, ��������� ���� ���� ����� �� ���� ��������
                minPrice = close[lastBarIndex] - minPrice;   // ���������, ��������� ���� ���� ���� �� ���� ��������  
                
                if (maxPrice < 0)
                  maxPrice = 0;
                if (minPrice < 0)
                  minPrice = 0;     
                
                if (maxPrice > minPrice)  // ������ ����������� �������� ����������
                 {
                   countActualDivBuy ++;    // ����������� ���������� ���������� ����������� �� BUY
                   
                   averActualProfitDivBuy = averActualProfitDivBuy + maxPrice;  // ����������� ����� ��� ������� �������
                   averActualLossDivBuy   = averActualLossDivBuy   + minPrice;  // ����������� ����� ��� �������� ������
                   FileWriteString(fileHandle,"\n ������: ����������");
                   FileWriteString(fileHandle,"\n ������������� �������: "+DoubleToString(maxPrice,5));
                   FileWriteString(fileHandle,"\n ������������� ������: "+DoubleToString(minPrice,5));
                   FileWriteString(fileHandle,"\n}\n");   
                 }
                else
                 {
                   averNotActualProfitDivBuy = averNotActualProfitDivBuy + maxPrice;  // ����������� ����� ��� ������� �������
                   averNotActualLossDivBuy   = averNotActualLossDivBuy   + minPrice;  // ����������� ����� ��� �������� ������                 
                   FileWriteString(fileHandle,"\n ������: �� ����������");
                   FileWriteString(fileHandle,"\n ������������� �������: "+DoubleToString(maxPrice));
                   FileWriteString(fileHandle,"\n ������������� ������: "+DoubleToString(minPrice));
                   FileWriteString(fileHandle,"\n}\n");  
                 }
                          
              }
              
             } // end �������� �� ����              
             
           }
        }
            
 // ������ � ���� ����� ����������
          if (countActualDivSell > 0)
              {
               averActualLossDivSell   = averActualLossDivSell   / countActualDivSell;
               averActualProfitDivSell = averActualProfitDivSell / countActualDivSell; 
              }
          if (countActualDivBuy > 0)
              {
               averActualLossDivBuy    = averActualLossDivBuy    / countActualDivBuy;
               averActualProfitDivBuy  = averActualProfitDivBuy  / countActualDivBuy;
              }
          if (countActualDivSell != countDivSell)
              {
               averNotActualLossDivSell   = averNotActualLossDivSell   / (countDivSell-countActualDivSell);
               averNotActualProfitDivSell = averNotActualProfitDivSell / (countDivSell-countActualDivSell); 
              }
          if (countActualDivBuy != countDivBuy)
              {
               averNotActualLossDivBuy    = averNotActualLossDivBuy    / (countDivBuy-countActualDivBuy);
               averNotActualProfitDivBuy  = averNotActualProfitDivBuy  / (countDivBuy-countActualDivBuy);
              }              
              
          FileWriteString(fileHandle,"\n\n ���������� ����������� SELL: "+IntegerToString(countDivSell));
          FileWriteString(fileHandle,"\n �� ��� ����������: "+IntegerToString(countActualDivSell));
          FileWriteString(fileHandle,"\n �� ��� �� ����������: "+IntegerToString(countDivSell - countActualDivSell));          
          
          FileWriteString(fileHandle,"\n ������� ������� ����������: "+DoubleToString(averActualProfitDivSell,5));
          FileWriteString(fileHandle,"\n ������� ������������� ������ ����������: "+DoubleToString(averActualLossDivSell,5));  
          
          FileWriteString(fileHandle,"\n ������� ������� �� ����������: "+DoubleToString(averNotActualProfitDivSell,5));
          FileWriteString(fileHandle,"\n ������� ������������� ������ �� ����������: "+DoubleToString(averNotActualLossDivSell,5));                
          
          FileWriteString(fileHandle,"\n\n ���������� ����������� BUY: "+IntegerToString(countDivBuy));
          FileWriteString(fileHandle,"\n �� ��� ����������: "+IntegerToString(countActualDivBuy));
          FileWriteString(fileHandle,"\n �� ��� �� ����������: "+IntegerToString(countDivBuy - countActualDivBuy));          
           
          FileWriteString(fileHandle,"\n ������� ������� ����������: "+DoubleToString(averActualProfitDivBuy,5));
          FileWriteString(fileHandle,"\n ������� ������������� ������ ����������: "+DoubleToString(averActualLossDivBuy,5));  
          
          FileWriteString(fileHandle,"\n ������� ������� �� ����������: "+DoubleToString(averNotActualProfitDivBuy,5));
          FileWriteString(fileHandle,"\n ������� ������������� ������ �� ����������: "+DoubleToString(averNotActualLossDivBuy,5));          
        
          FileWriteString(fileHandle,"\n\n ���������� ���������� ����������� �� SELL � �������� ���� ������: "+IntegerToString(countDivZoneProfitSell));        
          FileWriteString(fileHandle,"\n ���������� ���������� ����������� �� SELL � ������� ���� ������: "+IntegerToString(countDivZoneLossSell));  
  
          FileWriteString(fileHandle,"\n ���������� ���������� ����������� �� BUY � �������� ���� ������: "+IntegerToString(countDivZoneProfitBuy));        
          FileWriteString(fileHandle,"\n ���������� ���������� ����������� �� BUY � ������� ���� ������: "+IntegerToString(countDivZoneLossBuy));        
    
   }
   
  // ���� �� ���������� � �������� ������� ������� ��������
  if (useZoneAverage)
   {
     zoneLossBuy     =  averActualLossDivBuy;
     zoneLossSell    =  averActualLossDivSell;
     zoneProfitBuy   =  averActualProfitDivBuy;
     zoneProfitSell  =  averActualProfitDivSell;
   }   
          
        // ��������� ���� ����������
        
        FileClose(fileHandle);                       
        fileHandle = INVALID_HANDLE;                 
                             
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