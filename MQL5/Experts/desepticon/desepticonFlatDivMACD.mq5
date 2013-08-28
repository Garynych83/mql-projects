//+------------------------------------------------------------------+
//|                                         desepticonFlatDivSto.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
 
#include <Lib CisNewBar.mqh>
#include <TradeManager/TradeManager.mqh>
#include <divergenceMACD.mqh>

input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;
//��������� MACD
input int fast_EMA_period = 12;    //������� ������ EMA ��� MACD
input int slow_EMA_period = 26;    //��������� ������ EMA ��� MACD
input int signal_period = 9;       //������ ���������� ����� ��� MACD

//��������� ������  
input double orderVolume = 0.1;         // ����� ������
input int    slOrder = 100;             // Stop Loss
input int    tpOrder = 100;             // Take Profit
input int    trStop = 100;              // Trailing Stop
input int    trStep = 100;              // Trailing Step
input int    minProfit = 250;           // Minimal Profit 
input bool   useLimitOrders = false;    // ������������ Limit ������
input int    limitPriceDifference = 50; // ������� ��� Limit �������
input bool   useStopOrders = false;     // ������������ Stop ������
input int    stopPriceDifference = 50;  // ������� ��� Stop �������

input bool   useTrailing = false;  // ������������ ��������
input bool   useJrEMAExit = false; // ����� �� �������� �� ���
input int    posLifeTime = 10;     // ����� �������� ������ � �����
input int    deltaPriceToEMA = 7;  // ���������� ������� ����� ����� � EMA ��� �����������
input int    deltaEMAToEMA = 5;    // ����������� ������� ����� EMA ��� �����������
input int    periodEMA = 3;        // ������ EMA
input int    waitAfterDiv = 4;     // �������� ������ ����� ����������� (� �����)
//��������� PriceBased indicator
input int    historyDepth = 40;    // ������� ������� ��� �������
input int    bars=30;              // ������� ������ ����������

int    handleTrend;
int    handleEMA;
int    handleMACD;
double bufferTrend[];
double bufferEMA[];

datetime history_start;
ENUM_TM_POSITION_TYPE opBuy,       // ���������� ��� ����������� ���� ������ Order / Limit / Stop
                      opSell;      // ���������� ��� ����������� ���� ������ Order / Limit / Stop
int priceDifference = 10;          // ������� ��� ��� Limit / Stop �������

CisNewBar eldNewBar(eldTF);        // ���������� ��� ����������� ������ ���� �� eldTF
CTradeManager tradeManager;        // �������� �������

int OnInit()
{
 tradeManager.Initialization();
 log_file.Write(LOG_DEBUG, StringFormat("%s �����������.", MakeFunctionPrefix(__FUNCTION__)));
 history_start = TimeCurrent();        // �������� ����� ������� �������� ��� ��������� �������� �������
 handleTrend = iCustom(Symbol(), eldTF, "PriceBasedIndicator", historyDepth, bars);
 handleMACD = iMACD(Symbol(), eldTF, fast_EMA_period, slow_EMA_period, signal_period, PRICE_CLOSE);
 handleEMA = iMA(Symbol(), eldTF, periodEMA, 0, MODE_EMA, PRICE_CLOSE); 
   
 if (handleTrend == INVALID_HANDLE || handleEMA == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE. Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(INIT_FAILED);
 }
 
 if (useLimitOrders)                   // ����� ���� ������ Order / Limit / Stop
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
 ArraySetAsSeries(bufferEMA, true);
 ArrayResize(bufferTrend, 1);
 ArrayResize(bufferEMA, 2);
   
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 tradeManager.Deinitialization();
 IndicatorRelease(handleTrend);
 IndicatorRelease(handleMACD); 
 IndicatorRelease(handleEMA);
 ArrayFree(bufferTrend);
 ArrayFree(bufferEMA);
 log_file.Write(LOG_DEBUG, StringFormat("%s �������������.", MakeFunctionPrefix(__FUNCTION__)));
}

void OnTick()
{
 static bool isProfit = false;
 static int  wait = 0;
 int order_direction = 0;
 double point = Point();
 double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
 double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
 
 int copiedTrend = -1;
 int copiedEMA   = -1;
 
 //TO DO: ����� �� EMA
   
 if (eldNewBar.isNewBar() > 0)                       //�� ������ ����� ���� �������� TF
 {
  for (int attempts = 0; attempts < 25 && copiedTrend < 0
                                       && copiedEMA   < 0; attempts++) //�������� ������ �����������
  {
   copiedTrend = CopyBuffer( handleTrend, 4, 1, 1,  bufferTrend) < 0;
   copiedEMA   = CopyBuffer(   handleEMA, 0, 0, 2,    bufferEMA) < 0;
  }
  if (copiedTrend != 1 || copiedEMA != 2)   
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ������.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return;
  }
 
  isProfit = tradeManager.isMinProfit(Symbol());     // ��������� �� �������� �� ������� �� ������ ������� ������������ �������
  if (isProfit && TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF))
  { //���� �� �������� minProfit �� ������������ �����
   log_file.Write(LOG_DEBUG, StringFormat("%s ������� ����� �������� ����������.��������� �������.", MakeFunctionPrefix(__FUNCTION__))); 
   //close position 
  }
 
  wait++; 
  if (order_direction != 0)   // ���� ���� ������ � ����������� ������ 
  {
   if (wait > waitAfterDiv)   // ��������� �� ���������� ����� �������� ����� �����������
   {
    wait = 0;                 // ���� �� ��������� �������� ������� �������� � ����������� ������
    order_direction = 0;
   }
  }
  
  order_direction = divergenceMACD(handleMACD, Symbol(), eldTF); 
  
  if (bufferTrend[0] == 7)               //���� ����������� ������ FLAT  
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ����", MakeFunctionPrefix(__FUNCTION__)));   
   if (order_direction == 1)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ����������� MACD 1", MakeFunctionPrefix(__FUNCTION__)));
    if(LessDoubles(bid, bufferEMA[0] + deltaPriceToEMA*point))
    {
     tradeManager.OpenPosition(Symbol(), opBuy, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� BUY.", MakeFunctionPrefix(__FUNCTION__)));
     wait = 0;
    }
   }
   if (order_direction == -1)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ����������� MACD -1", MakeFunctionPrefix(__FUNCTION__)));
    if(GreatDoubles(ask, bufferEMA[0] - deltaPriceToEMA*point))
    {
     tradeManager.OpenPosition(Symbol(), opSell, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� SELL.", MakeFunctionPrefix(__FUNCTION__)));
     wait = 0;
    }
   }
  } // close trend == FLAT
 } // close newBar
 
 if (useTrailing)
 {
  tradeManager.DoTrailing();
 }
} // close OnTick

void OnTrade()
{
 tradeManager.OnTrade(history_start);
}