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
//| ���������, ������������ ����������� MACD                         |
//| 1) ������ MACD                                                   |
//| 2) ������ ������� ����������� �� MACD � �� ������� ����          |
//| 3) ������ ����������� ������ ������������� �������               |
//| 4) �������� ���������� �����������                               |
//+------------------------------------------------------------------+

// ���������� ���������� 
#include <Lib CisNewBar.mqh>                       // ��� �������� ������������ ������ ����
#include <Divergence/divergenceMACD.mqh>           // ���������� ���������� ��� ������ ����������� MACD
#include <ChartObjects/ChartObjectsLines.mqh>      // ��� ��������� ����� �����������
#include <CompareDoubles.mqh>                      // ��� �������� �����������  ���

// ������� ���������������� ��������� ����������
sinput string             macd_params        = "";           // ��������� ���������� MACD
input  int                fast_ema_period    = 12;           // ������ ������� ������� MACD
input  int                slow_ema_period    = 26;           // ������ ��������� ������� MACD
input  ENUM_APPLIED_PRICE priceType          = PRICE_CLOSE;  // ��� ���, �� ������� ����������� MACD

sinput string             stat_params        = "";           // ��������� ���������� ����������
input  int                actualBars         = 10;           // ���������� ����� ��� �������� ������������
input  string             fileName           = "MACD_STAT_"; // ��� ����� ����������
input  datetime           start_time         = 0;            // ����, � ������� ������ ��������� ����������
input  datetime           finish_time        = 0;            // ����, �� ������� ��������� ����������
input  double             ZoneLossBuy        = 0;            // ������� ������ ���������� ����������� �� BUY
input  double             ZoneProfitBuy      = 0;            // ������� ������� ���������� ����������� �� BUY
input  double             ZoneLossSell       = 0;            // ������� ������ ���������� ����������� �� SELL 
input  double             ZoneProfitSell     = 0;            // ������� ������� ���������� ����������� �� SELL


// ��������� ������������ ������� 
#property indicator_buffers 2                      // ������������� 2 ������������ ������
#property indicator_plots   1                      // 1 ����� ������������ �� ��������

// ��������� �������

// ��������� 1-�� ������ (MACD)
#property indicator_type1 DRAW_HISTOGRAM           // �����������
#property indicator_color1  clrWhite               // ���� �����������
#property indicator_width1  1                      // ������� �����������
#property indicator_label1  "MACD"                 // ������������ ������


// ���������� ���������� ����������
int                handleMACD;                     // ����� MACD
int                lastBarIndex;                   // ������ ���������� ���� 
int                retCode;                        // ��� ������ ���������� ����������  �����������  
long               countDiv;                       // ������� ����� ����� (��� ��������� ����� �����������) 

PointDivMACD       divergencePoints;               // ����� ����������� MACD �� ������� ������� � �� ������� MACD
CChartObjectTrend  trendLine;                      // ������ ������ ��������� ����� (��� ����������� �����������)
CChartObjectVLine  vertLine;                       // ������ ������ ������������ �����
CisNewBar          isNewBar;                       // ��� �������� ������������ ������ ����

// ������ ���������� 
double bufferMACD[];                               // ����� ������� MACD
double bufferDiv[];                                // ����� �������� �����������

// ����� ����� ����������
int    fileHandle;

// ���������� ��� �������� ����������� ����������

double averActualProfitDivBuy      = 0;    // ������� ������������� ������� �� ����������� ����������� �� �������
double averActualLossDivBuy        = 0;    // ������� ������������� ������ ��� ���������� ����������� �� �������
double averActualProfitDivSell     = 0;    // ������� ������������� ������� �� ����������� ����������� �� �������
double averActualLossDivSell       = 0;    // ������� ������������� ������ ��� ���������� ����������� �� �������    

double averNotActualProfitDivBuy   = 0;    // ������� ������������� ������� �� �� ����������� ����������� �� �������
double averNotActualLossDivBuy     = 0;    // ������� ������������� ������ ��� �� ���������� ����������� �� �������
double averNotActualProfitDivSell  = 0;    // ������� ������������� ������� �� �� ����������� ����������� �� �������
double averNotActualLossDivSell    = 0;    // ������� ������������� ������ ��� �� ���������� ����������� �� �������                     

// �������� �����������
int    countActualDivBuy           = 0;    // ���������� ���������� ����������� �� �������
int    countDivBuy                 = 0;    // ����� ���������� ����������� �� �������     
int    countActualDivSell          = 0;    // ��������� ���������� ����������� �� �������
int    countDivSell                = 0;    // ����� ���������� ����������� �� �������     

int    countDivZoneLossBuy         = 0;    // ���������� ����������� � ������� ���� ������ �� BUY
int    countDivZoneProfitBuy       = 0;    // ���������� ����������� � �������� ���� ������ �� BUY

int    countDivZoneLossSell        = 0;    // ���������� ���������� � ������� ���� ������ �� SELL
int    countDivZoneProfitSell      = 0;    // ���������� ����������� � �������� ���� ������ �� SELL
                                                  

// �������������� ������� ������ ����������
void DrawIndicator(datetime vertLineTime); // ���������� ����� ����������. � ������� ���������� ����� ������������ �����
   
// ������������� ����������
int OnInit()
  {
   // ������� ���� ���������� �� ������
   fileHandle = FileOpen(fileName+_Symbol+"_"+PeriodToString(_Period)+".txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
   if (fileHandle == INVALID_HANDLE) //�� ������� ������� ����
    {
     Print("������ ���������� ShowMeYourDivMACD. �� ������� ������� ���� ����������");
     return (INIT_FAILED);
    }  
   ArraySetAsSeries(bufferDiv,true);
   // ��������� ����� ���������� MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,9,PRICE_CLOSE);
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
   SetIndexBuffer(1,bufferDiv ,INDICATOR_CALCULATIONS); // ����� ����������� (�������� ������������� ��������)
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
   ArrayFree(bufferMACD);
   ArrayFree(bufferDiv);
   // ����������� ����� MACD
   IndicatorRelease(handleMACD);
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
 // �������� ����� MACD
  if (CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0  )
  {
  // ���� �� ������� ��������� ������ MACD
   Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ����� MACD");
   return (0); 
  }                
  // ������� ���������� ������ �������� ��� � ���������
  if (!ArraySetAsSeries (time,true) || 
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
  for (lastBarIndex = rates_total-DEPTH_MACD-1; lastBarIndex > 0; lastBarIndex--)
  {
  // �������� ����� �������� ����������� MACD
   bufferDiv[lastBarIndex] = 0;
   retCode = divergenceMACD(handleMACD, _Symbol, _Period, divergencePoints, lastBarIndex);  // �������� ������ �� �����������
  // ���� �� ������� ��������� ������ MACD
   if (retCode == -2)
   {
    Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
    return (0);
   }
   if (retCode)
   {                                          
    DrawIndicator(time[lastBarIndex]);    // ���������� ����������� �������� ����������     
    bufferDiv[lastBarIndex] = retCode;    // ��������� � ����� ��������    
           
   // ��������� �������������� ������ �� ������� �����������
    if (time[lastBarIndex] >= start_time  && time[lastBarIndex] <= finish_time)   // ���� ������� ����� �������� � ���� ���������� ����������
    {
    // ��������� �������� �� ������� ���������� ������������
     maxPrice =  high[ArrayMaximum(high,lastBarIndex-actualBars,actualBars)];  // ������� �������� �� high
     minPrice =  low[ArrayMinimum(low,lastBarIndex -actualBars,actualBars)];   // ������� ������� �� low

    // ��������� ������������ �����������
     if (retCode == 1)      // ���� ����������� �� SELL
     { 
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
       
       if (minPrice > ZoneProfitSell)
         {
           countDivZoneProfitSell++;  
         }
       if (maxPrice < ZoneLossSell)
         {
           countDivZoneLossSell++;  
         }         
                            
      }
      else
      {
       averNotActualProfitDivSell = averNotActualProfitDivSell + minPrice; // ����������� ����� ��� ������� �������
       averNotActualLossDivSell   = averNotActualLossDivSell   + maxPrice; // ����������� ����� ��� �������� ������
                           
      }
     }
     if (retCode == -1)     // ���� ����������� �� BUY
     {              
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
       
       if (maxPrice > ZoneProfitBuy)
         {
           countDivZoneProfitBuy++;  
         }
       if (minPrice < ZoneLossBuy)
         {
           countDivZoneLossBuy++;  
         }         
 
      }
      else
      {
       averNotActualProfitDivBuy = averNotActualProfitDivBuy + maxPrice;  // ����������� ����� ��� ������� �������
       averNotActualLossDivBuy   = averNotActualLossDivBuy   + minPrice;  // ����������� ����� ��� �������� ������                 
  
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
   if (!ArraySetAsSeries (time,true) || 
       !ArraySetAsSeries (open,true) || 
       !ArraySetAsSeries (high,true) ||
       !ArraySetAsSeries (low,true)  || 
       !ArraySetAsSeries (close,true) )
   {
   // ���� �� ������� ����������� ���������� ��� � ��������� ��� ���� �������� ��� � �������
    Print("������ ���������� ShowMeYourDivMACD. �� ������� ���������� ���������� �������� ��� � ���������");
    return (rates_total);
   }
   // �������� ����� ������� �����������
   bufferDiv[0] = 0;
   if (CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0  )
   {
   // ���� �� ������� ��������� ������ MACD
    Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
    return (rates_total);
   }   
   retCode = divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,0);  // �������� ������ �� �����������
   // ���� �� ������� ��������� ������ MACD
   if (retCode == -2)
   {
    Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
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
 
//---------------------------------------------------------  
// ������� ����������� ����������� ��������� ����������
//----------------------------------------------------------
void DrawIndicator (datetime vertLineTime)
 {
   trendLine.Color(clrYellow);
   // ������� ����� ���������\�����������                    
   trendLine.Create(0,"MacdPriceLine_"+IntegerToString(countDiv),0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);           
   trendLine.Color(clrYellow);         
   // ������� ����� ���������\����������� �� MACD
   trendLine.Create(0,"MACDLine_"+IntegerToString(countDiv),1,divergencePoints.timeExtrMACD1,divergencePoints.valueExtrMACD1,divergencePoints.timeExtrMACD2,divergencePoints.valueExtrMACD2);            
   vertLine.Color(clrRed);
   // ������� ������������ �����, ������������ ������ ��������� ����������� MACD
   vertLine.Create(0,"MACDVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // ����������� ���������� ������������ ���������
 }