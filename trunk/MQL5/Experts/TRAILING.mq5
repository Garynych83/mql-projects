//+------------------------------------------------------------------+
//|                                                     TRAILING.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ����� ��� ������������ ���������                                 |
//+------------------------------------------------------------------+
// ����������� ����������� ���������
#include <Lib CisNewBarDD.mqh>             // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>              // ��� ��������� ������������ �����
#include <TradeManager\TradeManager.mqh>   // �������� ����������
#include <BlowInfoFromExtremums.mqh>       // ����� �� ������ � ������������ ���������� DrawExtremums
#include <SIMPLE_TREND\SimpleTrendLib.mqh> // ���������� ������ Simple Trend
// ��������� ���������� 
double curPrice;          // ������� ����
double prevPrice;         // ���������� ����
int    stopLoss;          // ���� ����
bool   openedPos = false; // ���� �������� �������

// ������� ������� 
CBlowInfoFromExtremums *blowInfo;               // ������ �������� ������ ��������� ���������� �� ����������� ���������� DrawExtremums 
CTradeManager *ctm;                             // �������� ����������

// ������ ��� �������� �������� �����������
Extr             lastExtrHigh;                  // ����� ��������� ����������� �� HIGH
Extr             lastExtrLow;                   // ����� ��������� ����������� �� LOW
Extr             currentExtrHigh;               // ����� ������� ����������� �� HIGH
Extr             currentExtrLow;                // ����� ������� ����������� �� LOW
bool             extrHighBeaten=false;          // ����� ������ �������� ����������� HIGH
bool             extrLowBeaten=false;           // ����� ������ �������� ����������� LOW

int OnInit()
  {
   ctm = new CTradeManager();
   blowInfo = new CBlowInfoFromExtremums(_Symbol,_Period,1000,30,30,217);
   if (!blowInfo.IsInitFine())
        return (INIT_FAILED);
   // �������� ��������� ����������
   if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )
        {
         // �������� ������ ����������
         lastExtrHigh   =  blowInfo.GetExtrByIndex(EXTR_HIGH,0);  // �������� �������� ���������� ���������� HIGH
         lastExtrLow    =  blowInfo.GetExtrByIndex(EXTR_LOW,0);   // �������� �������� ���������� ���������� LOW
       }
   else
     return (INIT_FAILED);   
   curPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   iCustom(_Symbol,_Period,"DrawExtremums",_Period,1000,30,30,217);
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   delete ctm;
   delete blowInfo;
  }
void OnTick()
  {
    ctm.OnTick();
    ctm.UpdateData();
    ctm.DoTrailing(blowInfo);   
    prevPrice = curPrice;                                // �������� ���������� ����
    curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // �������� ������� ����     
    if (ctm.GetPositionCount() <= 0)
     {
      blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000);      
      // ��������� ���� ���� �� ���������� ������� ����������, ��������� � ������
      stopLoss = int(MathAbs(curPrice - blowInfo.GetExtrByIndex(EXTR_LOW,0).price)/_Point); 
      ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0,stopLoss,0,TRAILING_TYPE_EXTREMUMS);
      openedPos = true;
     }
  } 