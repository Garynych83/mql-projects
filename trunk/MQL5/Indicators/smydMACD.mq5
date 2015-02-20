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

#define _Buy 1
#define _Sell -1

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
#property indicator_buffers 2                      // ������������� 2 ������������ ������
#property indicator_plots   1                      // 1 ����� ������������ �� ��������

// ���������  ������ (MACD)
#property indicator_type1 DRAW_HISTOGRAM           // �����������
#property indicator_color1  clrWhite               // ���� �����������
#property indicator_width1  1                      // ������� �����������
#property indicator_label1  "MACD"                 // ������������ ������

// ���������� ���������� ����������
int                handleMACD;                     // ����� MACD
int                lastBarIndex;                   // ������ ���������� ���� 
int                retCode;                        // ��� ������ ���������� ����������  �����������  
long               countDiv;                       // ������� ����� ����� (��� ��������� ����� �����������) 

CChartObjectTrend  trendLine;                      // ������ ������ ��������� ����� (��� ����������� �����������)
CChartObjectVLine  vertLine;                       // ������ ������ ������������ �����
CisNewBar          *isNewBar;                      // ��� �������� ������������ ������ ����
CDivergenceMACD    *divMACD;
// ������ ���������� 
double bufferMACD[];                               // ����� ������� MACD
double bufferDiv[];                                // ����� �������� �����������

// ���������� ��� �������� ������� ��������� ������������� � ������������� �������� MACD
datetime  lastExtrMinMACD    = 0;                    // ����� ���������� �������������� MACD
datetime  lastExtrMaxMACD    = 0;                    // ����� ���������� �������������� MACD

// ���������� ��� �������� ������� �������� ����� ���� ��� ����������� MACD
datetime  lastMaxWithDiv = 0;                    // ����� ���������� ������ ����������� �� SELL
datetime  lastMinWithDiv   = 0;                    // ����� ���������� ����� ����������� �� BUY

// �������������� ������� ������ ����������
void    DrawIndicator (datetime vertLineTime);     // ���������� ����� ����������. � ������� ���������� ����� ������������ ����� (������� �����������)
   
// ������������� ����������
int OnInit()
{  
 // ����� �������� ����������� ������������� ��� � ���������
 ArraySetAsSeries(bufferDiv,true);
 // ����� MACD ������������� ��� � ���������
 ArraySetAsSeries(bufferMACD,true);
 // ��������� ����� ���������� MACD
 handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE);
 if ( handleMACD == INVALID_HANDLE)  // ���� �� ������� ��������� ����� MACD
 {
  return(INIT_FAILED);  // �� ������������� ����������� �� �������
 }  
     
 int bars = Bars(_Symbol, _Period);
 divMACD = new CDivergenceMACD(_Symbol, _Period, handleMACD, bars - DEPTH_MACD, DEPTH_MACD);  
 isNewBar = new CisNewBar(_Symbol, _Period);
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
 delete divMACD;
 delete isNewBar;
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
 ArraySetAsSeries (time, true); 
 ArraySetAsSeries (open, true); 
 ArraySetAsSeries (high, true);
 ArraySetAsSeries (low,  true); 
 ArraySetAsSeries (close,true);
 
 if (prev_calculated == 0) // ���� �� ����. ������ ���� ���������� 0 �����, ������ ���� ����� ������
 {
  bool fillTheExtremums = true;
  // ������� ���������� ������ �������� ��� � ���������
  // �������� �� ���� ����� ������� � ���� ����������� MACD
  for (lastBarIndex = rates_total - 1; lastBarIndex >= 1; lastBarIndex--)
  {
   // �������� ����� �������� ����������� MACD
   bufferDiv[lastBarIndex] = 0;  
   // ���� �� ����� �� ����, � �������� ����� ������ ��������� �����������
   if (lastBarIndex <= (rates_total - DEPTH_MACD - 1) )
   {        
    //�������� ������ ����������� MACD
    if(!divMACD.RecountExtremums(lastBarIndex, fillTheExtremums)) 
    {
     Print("�������� ����������� ��������� lastBarIndex = ",lastBarIndex);
     return(0);
    }
    fillTheExtremums = false;
            
    retCode = divMACD.countDivergence(lastBarIndex-1);  // �������� ������ �� �����������
    if (retCode == -2)
    {
     Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
     return (0);
    }
    lastExtrMinMACD = divMACD.getLastExtrMinTime();           //  ��������� ����� ���������� ������� ���������� MACD     
    lastExtrMaxMACD = divMACD.getLastExtrMaxTime();           //  ��������� ����� ���������� �������� ���������� MACD 

        
   // if (retCode == _Sell)
   //  Print(time[lastBarIndex-1]);
    // ���� ����������� �� SELL � ����� ���������� ����������� ���������� �� ������� ���������� ���������
    if (retCode == _Sell && lastMaxWithDiv != lastExtrMaxMACD)
    {       
     DrawIndicator (time[lastBarIndex-1]);               // ���������� ����������� �������� ����������    
     bufferDiv[lastBarIndex] = _Sell;                    // ��������� � ����� ��������       
     lastMaxWithDiv = lastExtrMaxMACD;          // ��������� ����� ���������� ������ MACD 
    }
    // ���� ����������� �� BUY � ����� ���������� ����������� ���������� �� ������� ���������� ��������
    if (retCode == _Buy && lastMinWithDiv != lastExtrMinMACD)
    {   
     DrawIndicator (time[lastBarIndex-1]);        // ���������� ����������� �������� ����������     
     bufferDiv[lastBarIndex] = _Buy;            // ��������� � ����� �������� 
     lastMinWithDiv = lastExtrMinMACD;             // ��������� ����� ���������� ����� MACD
    }         
   }
  }
 }
 else    // ���� ��� �� ������ ����� ���������� 
 {
  if(isNewBar.isNewBar())  
  {
   if(!divMACD.RecountExtremums(1)) 
   {
    Print("�������� ����������� ��������� lastBarIndex = ",0);
    return(0);
   }
  }
  
  bufferDiv[0] = 0;
  if ( CopyBuffer(handleMACD,0,0,rates_total,bufferMACD) < 0  )
  {
   // ���� �� ������� ��������� ������ MACD
   Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
   return (rates_total);
  }     // ��������� ��������� ������� MACD
 
  retCode = divMACD.countDivergence(0);  // �������� ������ �� �����������
  lastExtrMinMACD = divMACD.getLastExtrMinTime();           //  ��������� ����� ���������� ������� ���������� MACD     
  lastExtrMaxMACD = divMACD.getLastExtrMaxTime();           //  ��������� ����� ���������� �������� ���������� MACD     

  if (retCode == _Sell || retCode == _Buy)
  Print("time=",time[0]);
  // ���� �� ������� ��������� ������ MACD
  if (retCode == -2)
  {
   Print("������ ���������� ShowMeYourDivMACD. �� ������� ��������� ������ MACD");
   return (0);
  }
  // ���� ����������� �� SELL � ����� ����������� ����������� ���������� �� ���������� ��������� MACD
  if (retCode == _Sell && lastMaxWithDiv != lastExtrMaxMACD )
  {                                      
   DrawIndicator (time[0]);                  // ���������� ����������� �������� ����������    
   bufferDiv[0] = _Sell;                     // ��������� ������� ������
 //  lastMaxExtrMACD = divMACD.timeExtrMACD2;    // ��������� ����� ���������� ������������ ����������         
   lastMaxWithDiv = lastExtrMaxMACD;         // ��������� ����� ���������� ������������� ����������
  }    
  // ���� ����������� �� BUY � ����� ����������� ����������� ���������� �� ���������� �������� MACD
  if (retCode == _Buy && lastMinWithDiv != lastExtrMinMACD)
  {                                        
   DrawIndicator (time[0]);               // ���������� ����������� �������� ����������    
   bufferDiv[0] = _Buy;                   // ��������� ������� ������
//   lastMinExtrMACD = divMACD.timeExtrMACD2;  // ��������� ����� ���������� �����
   lastMinWithDiv = lastExtrMinMACD;         // ��������� ����� ���������� �����
  }                  
 }
 return(rates_total);
}

  
// ������� ����������� ����������� ��������� ����������
void DrawIndicator (datetime vertLineTime)
 {
   trendLine.Color(clrYellow);
   // ������� ����� ���������\�����������                    
   trendLine.Create(0,"PriceLine_"+IntegerToString(countDiv)+" "+TimeToString(divMACD.timeExtrPrice2),0,divMACD.timeExtrPrice1,divMACD.valueExtrPrice1,divMACD.timeExtrPrice2,divMACD.valueExtrPrice2);           
   trendLine.Color(clrYellow);         
   // ������� ����� ���������\����������� �� MACD
   trendLine.Create(0,"MACDLine_"+IntegerToString(countDiv),1,divMACD.timeExtrMACD1,divMACD.valueExtrMACD1,divMACD.timeExtrMACD2,divMACD.valueExtrMACD2);            
   vertLine.Color(clrRed);
   // ������� ������������ �����, ������������ ������ ��������� ����������� MACD
   vertLine.Create(0,"MACDVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // ����������� ���������� ������������ ���������
 }