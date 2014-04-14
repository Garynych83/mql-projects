//+------------------------------------------------------------------+
//|                                                      ONODERA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// ������������ ���������
#include <Divergence\divergenceMACD.mqh>  // ����������� ����������� 
#include <TradeManager\TradeManager.mqh>  // ����������� �������� ����������
#include <Lib CisNewBar.mqh>              // ��� �������� ������������ ������ ����


//+------------------------------------------------------------------+
//| �������, ���������� �� ����������� MACD                          |
//+------------------------------------------------------------------+

// ������� ���������

sinput string base_param                           = "";            // ������� ��������� ��������
input  int    StopLoss                             = 150;           // ���� ����
input  int    TakeProfit                           = 150;           // ���� ������
input  double Lot                                  = 1;             // ���
input  ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS; // ��� ����������� ������                    
input  int    priceDifference                      = 50;            // Price Difference

sinput string macd_param                           = "";            // ��������� MACD
input  int fast_EMA_period                         = 12;            // ������� ������ EMA ��� MACD
input  int slow_EMA_period                         = 26;            // ��������� ������ EMA ��� MACD
input  int signal_period                           = 9;             // ������ ���������� ����� ��� MACD
input  ENUM_APPLIED_PRICE applied_price            = PRICE_CLOSE;   // ��� ����  


// �������
CTradeManager * ctm;                                     // ��������� �� ������ �������� ����������
static CisNewBar isNewBar(_Symbol, _Period);             // ��� �������� ������������ ������ ����

// ������ ����������� 
int handleMACD;                                          // ����� MACD
      
// ���������� ��������
int divSignal;                                           // ������ �� �����������
double currentPrice;                                     // ������� ����
ENUM_TM_POSITION_TYPE opBuy,opSell;                      // ���� ������� 

int OnInit()
  {
   // �������� ������ ��� ������ ��������� ����������
   ctm = new CTradeManager(); 
   // ������� ����� ���������� MACD
   handleMACD = iMACD(_Symbol,_Period,fast_EMA_period,slow_EMA_period,signal_period,applied_price);
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
   // ������� ��������� MACD
   IndicatorRelease(handleMACD);
  }

void OnTick()
  {
    
    // ���� ����������� ����� ���
    if(isNewBar.isNewBar() > 0)
     {
       divSignal = divergenceMACD(handleMACD,_Symbol,_Period);   // �������� ������ �����������
        if (divSignal == 1)  // �������� ����������� �� �������
         { 
            currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            ctm.OpenUniquePosition(_Symbol,_Period,opBuy,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);
         }
        if (divSignal == -1) // �������� ����������� �� �������
         {
            currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);       
            ctm.OpenUniquePosition(_Symbol,_Period,opBuy,Lot,StopLoss,TakeProfit,0,0,0,0,0,priceDifference);                 
         }
        
     }     
  }