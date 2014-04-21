//+------------------------------------------------------------------+
//|                                                      ONODERA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// ������������ ��������� 
#include <TradeManager\TradeManager.mqh>        // ����������� �������� ����������
#include <Lib CisNewBar.mqh>                    // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>                   // ��� �������� �����������  ���


//+------------------------------------------------------------------+
//| �������, ���������� �� ����������� MACD                          |
//+------------------------------------------------------------------+

// ������� ���������

sinput string base_param                           = "";            // ������� ��������� ��������
input  int    StopLoss                             = 0;             // ���� ����
input  int    TakeProfit                           = 0;             // ���� ������
input  double Lot                                  = 1;             // ���
input  ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS; // ��� ����������� ������                    
input  int    priceDifference                      = 50;            // Price Difference

sinput string macd_string                          = "";            // ��������� MACD

// �������
CTradeManager * ctm;                                                // ��������� �� ������ �������� ����������
static CisNewBar isNewBar(_Symbol, _Period);                        // ��� �������� ������������ ������ ����

// ������ ����������� 
int handleMACD;                                                     // ����� MACD

// ���������� ��������
int divSignal;                                                      // ������ �� �����������
double currentPrice;                                                // ������� ����
ENUM_TM_POSITION_TYPE opBuy,opSell;                                 // ���� ������� 

double tmpBuffer[];

int OnInit()
{
 // �������� ������ ��� ������ ��������� ����������
 ctm = new CTradeManager(); 
 // ������� ����� ���������� MACD
 handleMACD = iCustom (_Symbol,_Period,"smydMACD");   
   
 if ( handleMACD == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� ONODERA. �� ������� ������� ����� MACD");
  return(INIT_FAILED);
 }
 // ���������� ����� �������
 switch (pending_orders_type)  
 {
  case USE_LIMIT_ORDERS: 
   opBuy  = OP_BUYLIMIT;
   opSell = OP_SELLLIMIT;
   break;
  case USE_STOP_ORDERS:
   opBuy  = OP_BUYSTOP;
   opSell = OP_SELLSTOP;
   break;
  case USE_NO_ORDERS:
   opBuy  = OP_BUY;
   opSell = OP_SELL;      
   break;
 }          
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // ������� ������ ������ TradeManager
 delete ctm;
 // ������� ��������� 
 IndicatorRelease(handleMACD);
}

void OnTick()
{
 int copiedMACD = -1;
 // ���� ����������� ����� ���
 if (isNewBar.isNewBar() > 0)
  {
 
   //divSignal = divergenceSTOC(handleStochastic,_Symbol,_Period,top_level,bottom_level);  // �������� ������ �����������
   copiedMACD = CopyBuffer(handleMACD,1,0,1,tmpBuffer);
   if (copiedMACD < 1)
    {
     PrintFormat("�� ������� ���������� ��� ������ Error=%d",GetLastError());
     return;
    }    
   if ( EqualDoubles(tmpBuffer[0],1.0))  // �������� ����������� �� �������
     { 
      currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      ctm.OpenUniquePosition(_Symbol,_Period,opSell,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);
     }
   if ( EqualDoubles(tmpBuffer[0],-1.0)) // �������� ����������� �� �������
     {
      currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);       
      ctm.OpenUniquePosition(_Symbol,_Period,opBuy,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);                 
     }
   }  
}