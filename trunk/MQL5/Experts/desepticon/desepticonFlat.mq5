//+------------------------------------------------------------------+
//|                                               desepticonFlat.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBar.mqh>
#include <TradeManager/TradeManager.mqh>

//------------------INPUT---------------------------------------
//��������� desepticonFlat
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;

//��������� ��� EMA
input int    periodEMAfastJr = 15;
input int    periodEMAslowJr = 9;

//��������� PriceBased indicator
input int    historyDepth = 40;    // ������� ������� ��� �������
input int    bars=30;              // ������� ������ ����������
//------------------GLOBAL--------------------------------------
int handleTrend;            // ����� PriceBased indicator
int handleEMA3;             // ����� EMA 3 �������� TF
int handleEMAfastEld;       // ����� EMA fast �������� ����������
int handleEMAfastJr;        // ����� EMA fast �������� ����������
int handleSTOCEld;          // ����� Stochastic �������� ����������
double bufferTrend[];       // ����� ��� PriceBased indicator  
double bufferEldPrice[];    // ����� ��� ���� �������� ��
double bufferEldTFPrice[];  // ����� ��� ���� �� ������� ����������
double bufferEMA3[];        // ����� ��� EMA 3
double bufferEMAfastEld[];  // ����� ��� EMA fast �������� ���������� 
double bufferEMAfastJr[];   // ����� ��� EMA fast �������� ����������
double bufferEMAslowJr[];   // ����� ��� EMA slow �������� ����������


ENUM_TM_POSITION_TYPE opBuy, 
                      opSell;
int priceDifference = 10;    // Price Difference

CisNewBar eldNewBar(eldTF);        // ���������� ��� ����������� ������ ���� �� eldTF
CTradeManager tradeManager;        // �������� ������� 

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  log_file.Write(LOG_DEBUG, StringFormat("%s �����������.", MakeFunctionPrefix(__FUNCTION__)));
 handleTrend = iCustom(Symbol(), Period(), "PriceBasedIndicator", historyDepth, bars);
 handleEMAfastJr = iMA(Symbol(), jrTF, periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAslowJr = iMA(Symbol(), jrTF, periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);

 if (handleTrend == INVALID_HANDLE || handleEMAfastJr == INVALID_HANDLE || handleEMAslowJr == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(INIT_FAILED);
 }
 
 if (useLimitOrders)                           // ����� ���� ������ Order / Limit / Stop
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

}
//+------------------------------------------------------------------+
