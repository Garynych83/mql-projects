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
//| 4) ������ �������� ����������� � ����������� �� ����             |
//+------------------------------------------------------------------+


// ���������� ���������� 
#include <Lib CisNewBar.mqh>                          // ��� �������� ������������ ������ ����
#include <Divergence/divergenceStochastic.mqh>        // ���������� ���������� ��� ������ ����������� MACD
#include <ChartObjects/ChartObjectsLines.mqh>         // ��� ��������� ����� �����������
#include <CompareDoubles.mqh>                         // ��� �������� �����������  ���
#include <CEventBase.mqh>                             // ��� ��������� �������     


// ������� ���������������� ��������� ����������
sinput string             stoc_params  = "";          // ��������� ���������� STOC
input int                 Kperiod      = 5;           // K-������ (���������� ����� ��� ��������)
input int                 Dperiod      = 3;           // D-������ (������ ���������� �����������)
input int                 slowing      = 3;           // ������ ��� �������������� �����������
input ENUM_MA_METHOD      ma_method    = MODE_SMA;    // ��� �����������
input ENUM_STO_PRICE      price_field  = STO_LOWHIGH; // ������ ������� ����������           
input int                 top_level    = 80;          // ������� ������� 
input int                 bottom_level = 20;          // ������ ������� 

// ��������� ������������ ������� 
#property indicator_buffers 5                         // ������������� 3 ������������ ������
#property indicator_plots   2                         // 2 ������ ������������ �� ��������

// ��������� �������

// top level �����
#property indicator_type1   DRAW_LINE               // �����
#property indicator_color1  clrWhite                // ���� �����
#property indicator_width1  1                       // ������� �����
#property indicator_style1  STYLE_SOLID             // ����� �����
#property indicator_label1  "StochasticLine"        // ������������ ������ 
// bottom level �����
#property indicator_type2   DRAW_LINE               // �����
#property indicator_color2  clrRed                  // ���� �����
#property indicator_width2  1                       // ������� �����
#property indicator_style2  STYLE_SOLID             // ����� �����
#property indicator_label2  "SignalLine"            // ������������ ������ 


// ���������� ���������� ����������
int                handleSTOC;                      // ����� ����������
int                lastBarIndex;                    // ������ ���������� ���� 
int                retCode;                         // ��� ������ ���������� ����������  �����������  
long               countDiv;                        // ������� ����� ����� (��� ��������� ����� �����������) 

CChartObjectTrend  trendLine;                       // ������ ������ ��������� ����� (��� ����������� �����������)
CChartObjectVLine  vertLine;                        // ������ ������ ������������ �����
CDivergenceSTOC    *divSTOC;                        // ��� ������ ����� ����������� 

CEventBase         *event;                         // ��� ��������� ������� 
SEventData         eventData;                      // ��������� ����� �������

// ������ ���������� 
double bufferMainLine[];                            // ����� ������� StochasticLine
double bufferSignalLine[];                          // ����� ������� SignalLine
double bufferDiv[];                                 // ����� �������� �����������
double bufferExtrLeft[];                            // ����� ������� �����  �����������
double bufferExtrRight[];                           // ����� ������� ������ �����������


// ����� ��� �������� ������� ����������� ����   

datetime lastRightPriceBuy  = 0;  
datetime lastRightPriceSell = 0;

bool firstTimeUse = true;                          //����, �� �������� ���������� ���� ������ ���������� ������� ����������� ���������� 
                                                   //���� ���������� ������ ��������� ��� ��� ������� �� ������ ����� ����
// �������������� ������� ������ ����������
void    DrawIndicator (datetime vertLineTime);     // ���������� ����� ����������. � ������� ���������� ����� ������������ �����
   
// ������������� ����������
int OnInit()
{  
 ArraySetAsSeries(bufferDiv,true);
 ArraySetAsSeries(bufferExtrLeft,true);
 ArraySetAsSeries(bufferExtrRight,true);   
 // ��������� ����� ���������� ����������
 handleSTOC = iStochastic(_Symbol, _Period, Kperiod, Dperiod, slowing, ma_method, price_field);
 if (handleSTOC == INVALID_HANDLE)  // ���� �� ������� ��������� ����� ����������
 {
  return(INIT_FAILED);  // �� ������������� ����������� �� �������
 }  
 // ������� ��� ����������� ������� (����� �����������, � ����� ����� ��������� �������� �����������)  
 ObjectsDeleteAll(0, 0, OBJ_TREND); // ��� ��������� ����� � �������� ������� 
 ObjectsDeleteAll(0, 1, OBJ_TREND); // ��� ��������� ����� � ��������� �������
 ObjectsDeleteAll(0, 0, OBJ_VLINE); // ��� ������������ �����, ������������ ������ ������������� �����������
 // ��������� ���������� � �������� 
 SetIndexBuffer(0, bufferMainLine,     INDICATOR_DATA);           // ����� top level ����������
 SetIndexBuffer(1, bufferSignalLine,   INDICATOR_DATA);           // ����� bottom level ����������
 SetIndexBuffer(2, bufferDiv ,         INDICATOR_CALCULATIONS);   // ����� ����������� (�������� ������������� ��������)
 SetIndexBuffer(3, bufferExtrLeft,     INDICATOR_CALCULATIONS);   // ����� ������� ����� �����������
 SetIndexBuffer(4, bufferExtrRight,    INDICATOR_CALCULATIONS);   // ����� ������� ������ �����������
 
 event = new CEventBase(100);                            // �� �� ������� ����� 100                         
 if (event == NULL)
 {
  Print("������ ��� ������������� ���������� DrawExtremums. �� ������� ������� ������ ������ CEventBase");
  return (INIT_FAILED);
 }
 // ������� �������
 event.AddNewEvent(_Symbol, _Period, "SELL");
 event.AddNewEvent(_Symbol, _Period, "BUY");
 // ������������� ����������  ����������
 countDiv = 0;                                             // ���������� ��������� ���������� �����������
 int lastbars  = Bars(_Symbol, _Period) - DEPTH_STOC;
 divSTOC       = new CDivergenceSTOC(handleSTOC, _Symbol, _Period, top_level, bottom_level, lastbars);
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
 ArrayFree(bufferMainLine);
 ArrayFree(bufferSignalLine);
 ArrayFree(bufferDiv);
 ArrayFree(bufferExtrLeft);
 ArrayFree(bufferExtrRight);
 // ����������� ����� ����������
 IndicatorRelease(handleSTOC);
 delete divSTOC;
 delete event;
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
{// ������� ���������� ������ �������� ��� � ���������  
 ArraySetAsSeries (time, true); 
 ArraySetAsSeries (open, true); 
 ArraySetAsSeries (high, true);
 ArraySetAsSeries (low,  true); 
 ArraySetAsSeries (close,true);
 
 CopyBuffer(handleSTOC, 0, 0, rates_total, bufferMainLine);
 CopyBuffer(handleSTOC, 1, 0, rates_total, bufferSignalLine);

 if (prev_calculated == 0) // ���� �� ����. ������ ���� ���������� 0 �����, ������ ���� ����� ������
 {
  ArrayInitialize  (bufferDiv,0);
  ArrayInitialize  (bufferExtrLeft,0);
  ArrayInitialize  (bufferExtrRight,0);
  // �������� ����� ����������
  firstTimeUse = true;              
  // �������� �� ���� ����� ������� � ���� ����������� ����������  
  for (lastBarIndex = rates_total - DEPTH_STOC - 1; lastBarIndex > 0; lastBarIndex--) 
  {
   // �������� ������� �������� ������� ����������� ����������
   bufferDiv[lastBarIndex] = 0;
   // �������� ������� �������� �����������
   bufferExtrLeft[lastBarIndex]  = 0;
   bufferExtrRight[lastBarIndex] = 0;
   // ����� ����������� �� ������ ���� � �������� ������                      
   retCode = divSTOC.countDivergence(lastBarIndex, firstTimeUse);
   firstTimeUse = false;     
   // ���� �� ������� ��������� ������ ����������
   if (retCode == -2)
   {
    Print("������ ���������� ShowMeYourDivSTOC. �� ������� ��������� ������ ����������");
    return (0);
   }
   // ���� BUY � ����� ����������� ���� �� ��������� � ���������� ������������ 
   if (retCode == BUY && datetime(divSTOC.timeExtrPrice2) != lastRightPriceBuy)
   {             
    DrawIndicator(time[lastBarIndex]);                               // ���������� ����������� �������� ����������     
    bufferDiv[lastBarIndex] = retCode;                               // ��������� � ����� ��������  
    bufferExtrLeft[lastBarIndex]  = double(divSTOC.timeExtrPrice2);  // �������� ����� ������  ����������
    bufferExtrRight[lastBarIndex] = double(divSTOC.timeExtrPrice1);  // �������� ����� ������� ����������    
    lastRightPriceBuy =  divSTOC.timeExtrPrice2;                     // ��������� ����� ����������� ���
   }
   // ���� SELL � ����� ����������� ���� �� ��������� � ���������� ������������ 
   if (retCode == SELL && datetime(divSTOC.timeExtrPrice2) != lastRightPriceSell)
   {             
    DrawIndicator (time[lastBarIndex]);   // ���������� ����������� �������� ����������     
    bufferDiv[lastBarIndex] = retCode;    // ��������� � ����� �������� 
    bufferExtrLeft[lastBarIndex]  = double(divSTOC.timeExtrPrice2); // �������� ����� ������  ����������
    bufferExtrRight[lastBarIndex] = double(divSTOC.timeExtrPrice1); // �������� ����� ������� ����������      
    // ��������� ����� ����������� ���
    lastRightPriceSell =  divSTOC.timeExtrPrice2;
   }           
  }firstTimeUse = true;
 }
 else    // ���� ��� �� ������ ����� ���������� 
 {
  // �������� ������� �������� ������� ����������� ����������
  bufferDiv[0] = 0;
  // �������� ������� �������� �����������
  bufferExtrLeft[0]  = 0;
  bufferExtrRight[0] = 0; 
  
  //������� Print("bufferDiv[0] = ", bufferDiv[0]);       
  retCode = divSTOC.countDivergence(0, firstTimeUse);    // �������� ������ �� �����������
  firstTimeUse = false;
  // ���� �� ������� ��������� ������ ����������
  if (retCode == -2)
  {
   Print(__FUNCTION__,"������ ���������� ShowMeYourDivSTOC. �� ������� ��������� ������ ����������");
   return (0);
  }
  if (retCode == BUY && datetime(divSTOC.timeExtrPrice1) != lastRightPriceBuy)       
  {             
   DrawIndicator (time[0]);                              // ���������� ����������� �������� ����������     
   bufferDiv[0] = retCode;                               // ��������� � ����� ��������    
   bufferExtrLeft[0]  = double(divSTOC.timeExtrPrice2);  // �������� ����� ������  ����������
   bufferExtrRight[0] = double(divSTOC.timeExtrPrice1);  // �������� ����� ������� ����������  
   lastRightPriceBuy =  divSTOC.timeExtrPrice1;          // ��������� ����� ����������� ���
   
   eventData.dparam = divSTOC.valueExtrPrice2;           // ��������� ���� , �� ������� ���� ������� �����������
   Generate("BUY", eventData, true);
  }
  // ���� SELL � ����� ����������� ���� �� ��������� � ���������� ������������ 
  if (retCode == SELL && datetime(divSTOC.timeExtrPrice1) != lastRightPriceSell)
  {                               
   DrawIndicator (time[0]);                               // ���������� ����������� �������� ����������     
   bufferDiv[0] = retCode;                                // ��������� � ����� ��������
   bufferExtrLeft[0]  = double(divSTOC.timeExtrPrice2);   // �������� ����� ������  ����������
   bufferExtrRight[0] = double(divSTOC.timeExtrPrice1);   // �������� ����� ������� ����������      
   lastRightPriceSell =  divSTOC.timeExtrPrice1;          // ��������� ����� ����������� ���   
   
   eventData.dparam = divSTOC.valueExtrPrice2;            // ��������� ���� , �� ������� ���� ������� �����������
   Generate("SELL", eventData, true);
  }                    
 }
 return(rates_total);
}

  
// ������� ����������� ����������� ��������� ����������
void DrawIndicator (datetime vertLineTime)
 {
   trendLine.Color(clrYellow);
   // ������� ����� ���������\�����������                    
   trendLine.Create(0,"STOCPriceLine_" + IntegerToString(countDiv),0,divSTOC.timeExtrPrice1,divSTOC.valueExtrPrice1,divSTOC.timeExtrPrice2,divSTOC.valueExtrPrice2);           
   trendLine.Color(clrYellow);         
   // ������� ����� ���������\����������� �� ����������
   trendLine.Create(0,"STOCLine_" + IntegerToString(countDiv),1,divSTOC.timeExtrSTOC1,divSTOC.valueExtrSTOC1,divSTOC.timeExtrSTOC2,divSTOC.valueExtrSTOC2);            
   vertLine.Color(clrRed);
   // ������� ������������ �����, ������������ ������ ��������� ����������� ����������
   vertLine.Create(0,"STOCVERT_"+IntegerToString(countDiv),0,vertLineTime);
   countDiv++; // ����������� ���������� ������������ ���������
 }
 
 
void Generate(string id_nam, SEventData &_data, const bool _is_custom = true)
{
 // �������� �� ���� �������� �������� � ������� �������� � �� � ���������� ��� ��� �������
 long z = ChartFirst();
 while (z >= 0)
 {
  if (ChartSymbol(z) == _Symbol && ChartPeriod(z)==_Period)  // ���� ������ ������ � ������� �������� � �������� 
  {
   // ������� ������� ��� �������� �������
   event.Generate(z,id_nam,_data,_is_custom);
  }
  z = ChartNext(z);      
 }     
}