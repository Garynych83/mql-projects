//+------------------------------------------------------------------+
//|                                              desepticonTrend.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//EMPTY
#include <Lib CisNewBar.mqh>
#include <TradeManager/TradeManager.mqh>
//------------------INPUT---------------------------------------
//��������� desepticonTrend
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;

input bool   useLimitOrders = false;    // ������������ Limit ������
input int    limitPriceDifference = 50; // ������� ��� Limit �������
input bool   useStopOrders = false;     // ������������ Stop ������
input int    stopPriceDifference = 50;  // ������� ��� Stop �������
input bool   useTrailing = false;       // ������������ ��������
//��������� PriceBased indicator
input int    historyDepth = 40;    // ������� ������� ��� �������
input int    bars=30;              // ������� ������ ����������

//------------------GLOBAL--------------------------------------
int handleTrend;
double bufferTrend[];

ENUM_TM_POSITION_TYPE opBuy, 
                      opSell;
int priceDifference = 10;    // Price Difference

CisNewBar eldNewBar(eldTF);
CTradeManager tradeManager;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s �����������.", MakeFunctionPrefix(__FUNCTION__)));
 handleTrend =  iCustom(NULL, 0, "PriceBasedIndicator", historyDepth, bars);
 
 if (handleTrend == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(INIT_FAILED);
 }
 
 if (useLimitOrders)
 {
  opBuy = OP_BUYLIMIT;
  opSell = OP_SELLLIMIT;
  priceDifference = limitPriceDifference;
 }
 else if (useStopOrders)
      {
       opBuy = OP_BUYSTOP;
       opSell = OP_SELLSTOP;
       priceDifference = stopPriceDifference;
      }
      else
      {
       opBuy = OP_BUY;
       opSell = OP_SELL;
       priceDifference = 0;
      }
  
 ArraySetAsSeries(bufferTrend, true);
 ArrayResize(bufferTrend, 1, 3);
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 IndicatorRelease(handleTrend);
 ArrayFree(bufferTrend);
 log_file.Write(LOG_DEBUG, StringFormat("%s �������������.", MakeFunctionPrefix(__FUNCTION__)));
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 int totalPositions = PositionsTotal();
 int positionType = -1;
 static bool isProfit = false;
 static int  wait = 0;
 int order_direction = 0;
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 isProfit = tradeManager.isMinProfit(_Symbol);
 
 if (eldNewBar.isNewBar() > 0)   //�� ������ ����� ���� �������� TF
 {
 }
 
 if (useTrailing)
 {
  tradeManager.DoTrailing();
 }
}
//+------------------------------------------------------------------+
