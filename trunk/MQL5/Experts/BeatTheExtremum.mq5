//+------------------------------------------------------------------+
//|                                           TmpBeatTheExtremum.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager\TradeManager.mqh>    // �������� ����������
#include <BlowInfoFromExtremums.mqh>        // ���������� ��� ��������� ���������� �� ����������

// ��������� ����������
double currentPrice;                        // ���������� �������� ������� ����
double previewPrice;                        // ���������� �������� ���������� ����
Extr             lastExtrHigh;              // ��������� ��������� HIGH
Extr             lastExtrLow;               // ��������� ��������� LOW
Extr             currentExtrHigh;           // ������� ��������� HIGH
Extr             currentExtrLow;            // ������� ��������� LOW
bool             extrHighBeaten = false;    // ���� �������� �������� ����������
bool             extrLowBeaten  = false;    // ���� �������� ������� ����������

CTradeManager *ctm;                         // �������� ����������
CBlowInfoFromExtremums *blowInfo;           // ������ ������ ��� ��������� ���������� �� �����������
CChartObjectHLine  horLine;                 // ������ ������ �������������� �����
CChartObjectHLine  horLine2;               

int OnInit()
  {
   horLine.Color(clrRed);
   horLine2.Color(clrLightGreen);
   previewPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   ctm   = new CTradeManager();
   if (ctm == NULL)
    return (INIT_FAILED);
   blowInfo = new CBlowInfoFromExtremums(_Symbol,_Period);
   if (blowInfo == NULL)
    return (INIT_FAILED); 
   if (blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )
    {
      lastExtrHigh   = blowInfo.GetExtrByIndex(EXTR_HIGH,0);  // �������� �������� ���������� ���������� HIGH
      lastExtrLow    = blowInfo.GetExtrByIndex(EXTR_LOW,0);   // �������� �������� ���������� ���������� LOW
    }
    else
     return (INIT_FAILED);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // ������� �������
   delete ctm;
   delete blowInfo;
  }
 
 int count; 
  
void OnTick()
  {
   ctm.OnTick();
   if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )    // ���� ������� �������� ������ �� �����������
    {
     currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  // �������� ������� ����
     // �������� �������� ��������� �����������
     currentExtrHigh  = blowInfo.GetExtrByIndex(EXTR_LOW,0);
     currentExtrLow   = blowInfo.GetExtrByIndex(EXTR_HIGH,0);
     if (currentExtrHigh.time != lastExtrHigh.time)        // ���� ������ ����� HIGH ���������
      {
       lastExtrHigh = currentExtrHigh;
       extrHighBeaten = false;
       horLine.Create(0,"high"+count,0,currentExtrHigh.price);
       count++;       
      }
     if (currentExtrLow.time != lastExtrLow.time)          // ���� ������ ����� LOW ���������
      {
       lastExtrLow = currentExtrLow;
       extrLowBeaten = false;
       horLine2.Create(0,"low"+count,0,currentExtrLow.price);
       
       count++;        
      } 
      
     
      
     if (GreatDoubles(currentPrice,lastExtrHigh.price) && LessDoubles(previewPrice,lastExtrHigh.price) && !extrHighBeaten)
      {
      Print("����=",DoubleToString(currentPrice)," ����=",DoubleToString(previewPrice)," ���������=",DoubleToString(lastExtrHigh.price)," �����=",TimeToString(lastExtrHigh.time)); 
       extrHighBeaten = true;
       ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,1.0);
      }     
     if (LessDoubles(currentPrice,lastExtrLow.price)&& GreatDoubles(previewPrice,lastExtrLow.price) && !extrLowBeaten)
      {
      Print("����=",DoubleToString(currentPrice)," ����=",DoubleToString(previewPrice)," ���������=",DoubleToString(lastExtrLow.price)," �����=",TimeToString(lastExtrHigh.time));       
       extrLowBeaten = true;
       ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0);
      }       
    }   
    // ���������� ���������� ����
    previewPrice = currentPrice;
  }
  