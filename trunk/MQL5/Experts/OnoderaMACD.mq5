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
#include <Constants.mqh>                        // ���������� ��������

//+------------------------------------------------------------------+
//| �������, ���������� �� ����������� MACD                          |
//+------------------------------------------------------------------+

// ������� ���������

sinput string base_param                           = "";                 // ������� ��������� ��������
input  int    StopLoss                             = 0;                  // ���� ����
input  int    TakeProfit                           = 0;                  // ���� ������
input  double Lot                                  = 1;                  // ���
input  ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS;      // ��� ����������� ������                    
input  int    priceDifference                      = 50;                 // Price Difference

sinput string trailingStr                          = "";                 // ��������� ���������
input         ENUM_TRAILING_TYPE trailingType      = TRAILING_TYPE_PBI;  // ��� ���������
input int     trStop                               = 100;                // Trailing Stop
input int     trStep                               = 100;                // Trailing Step
input int     minProfit                            = 250;                // ����������� �������

// �������
CTradeManager * ctm;                                                     // ��������� �� ������ �������� ����������
static CisNewBar isNewBar(_Symbol, _Period);                             // ��� �������� ������������ ������ ����

// ������ ����������� 
int handleSmydMACD;                                                      // ����� ���������� ShowMeYourDivMACD

// ���������� ��������
int divSignal;                                                           // ������ �� �����������
double currentPrice;                                                     // ������� ����
ENUM_TM_POSITION_TYPE opBuy,opSell;                                      // ���� ������� 

double signalBuffer[];                                                   // ����� ��� ��������� ������� �� ����������

int    stopLoss;                                                         // ���������� ��� �������� ��������������� ���� �����

int    copiedSmydMACD;                                                   // ���������� ��� �������� ����������� ������ �������� �����������

int OnInit()
{
 // �������� ������ ��� ������ ��������� ����������
 ctm = new CTradeManager(); 
 // ������� ����� ���������� ShowMeYourDivMACD
 handleSmydMACD = iCustom (_Symbol,_Period,"smydMACD");   
   
 if ( handleSmydMACD == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� ONODERA. �� ������� ������� ����� ShowMeYourDivMACD");
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
 IndicatorRelease(handleSmydMACD);
}

int countSell=0;
int countBuy =0;

void OnTick()
{
 ctm.OnTick();
 // ���������� ���������� �������� ����������� ������ �������� � ��������� ��������
 copiedSmydMACD = -1;
 // ���� ����������� ����� ���
 if (isNewBar.isNewBar() > 0)
  {
   copiedSmydMACD = CopyBuffer(handleSmydMACD,1,0,1,signalBuffer);

   if (copiedSmydMACD < 1)
    {
     PrintFormat("�� ������� ���������� ��� ������ Error=%d",GetLastError());
     return;
    }   
   if (signalBuffer[0] == _Buy)
     countBuy++;
   if (signalBuffer[0] == _Sell)
     countSell++;

    //  Comment("������ SELL = ",countSell," \n ������ BUY = ",countBuy);
 
   if ( signalBuffer[0] == _Buy)  // �������� ����������� �� �������
     { 
      currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      ctm.OpenUniquePosition(_Symbol,_Period,opBuy,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);
     }
   if ( signalBuffer[0] == _Sell) // �������� ����������� �� �������
     {
      currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);       
      ctm.OpenUniquePosition(_Symbol,_Period,opSell,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);                 
     }
   }  
}