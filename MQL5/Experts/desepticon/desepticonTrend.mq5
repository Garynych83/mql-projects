//+------------------------------------------------------------------+
//|                                              desepticonTrend.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


#include <Lib CisNewBar.mqh>
#include <TradeManager/TradeManager.mqh>
//------------------INPUT---------------------------------------
//��������� desepticonTrend
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;

input int periodEMAfastEld = 15;        // ������ EMA fast �������� ����������
input int periodEMAfastJr  = 15;        // ������ EMA fast �������� ����������
input int periodEMAslowJr  = 9;         // ������ EMA slow �������� ����������

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
input bool   useTrailing = false;       // ������������ ��������
input int    posLifeTime = 10;          // ����� �������� ������ � �����
input int    waitAfterBreakdown = 4;    // �������� ������ ����� ������ (� �����)
input int    deltaPriceToEMA = 7;       // ���������� ������� ����� ����� � EMA ��� �����������
//��������� PriceBased indicator
input int    historyDepth = 40;    // ������� ������� ��� �������
input int    bars=30;              // ������� ������ ����������

//------------------GLOBAL--------------------------------------
int handleTrend;            // ����� PriceBased indicator
int handleEMA3;             // ����� EMA 3 �������� TF
int handleEMAfastEld;       // ����� EMA fast �������� ����������
int handleEMAfastJr;        // ����� EMA fast �������� ����������
int handleEMAslowJr;        // ����� EMA slow �������� ����������
double bufferTrend[];       // ����� ��� PriceBased indicator  
double bufferDayPrice[];    // ����� ��� ���� �� ��������
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
 handleEMA3 = iMA(Symbol(), PERIOD_D1, 3, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAfastEld = iMA(Symbol(), eldTF, periodEMAfastEld, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAfastJr  = iMA(Symbol(),  jrTF,  periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAslowJr  = iMA(Symbol(),  jrTF,  periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);
 
 if (     handleTrend == INVALID_HANDLE ||      handleEMA3 == INVALID_HANDLE || 
      handleEMAfastJr == INVALID_HANDLE || handleEMAslowJr == INVALID_HANDLE ||
     handleEMAfastEld == INVALID_HANDLE )
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE. Error(%d) = %s" 
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
  
 ArraySetAsSeries(     bufferTrend, true);
 ArraySetAsSeries(  bufferDayPrice, true);
 ArraySetAsSeries(bufferEldTFPrice, true);
 ArraySetAsSeries(bufferEMAfastEld, true);
 ArraySetAsSeries( bufferEMAfastJr, true);
 ArraySetAsSeries( bufferEMAslowJr, true);
 ArraySetAsSeries(      bufferEMA3, true);
 ArrayResize(     bufferTrend, 1);
 ArrayResize(  bufferDayPrice, 1);
 ArrayResize(bufferEldTFPrice, 2);
 ArrayResize(bufferEMAfastEld, 2);
 ArrayResize( bufferEMAfastJr, 2);
 ArrayResize( bufferEMAslowJr, 2);
 ArrayResize(      bufferEMA3, 1);
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 IndicatorRelease(handleTrend);
 IndicatorRelease(handleEMAfastEld);
 IndicatorRelease(handleEMAfastJr);
 IndicatorRelease(handleEMAslowJr);
 IndicatorRelease(handleEMA3);
 ArrayFree(bufferTrend);
 ArrayFree(bufferDayPrice);
 ArrayFree(bufferEldTFPrice);
 ArrayFree(bufferEMAfastEld);
 ArrayFree(bufferEMAfastJr);
 ArrayFree(bufferEMAslowJr);
 ArrayFree(bufferEMA3); 
 log_file.Write(LOG_DEBUG, StringFormat("%s �������������.", MakeFunctionPrefix(__FUNCTION__)));
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 static bool isProfit = false;
 static int  wait = 0;
 int order_direction = 0;
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 int copiedTrend      = -1;
 int copiedEMA3       = -1;
 int copiedEMAfastEld = -1;
 int copiedEMAfastJr  = -1;
 int copiedEMAslowJr  = -1;
 int copiedDayPrice   = -1;
 int copiedEldPrice   = -1;
 
 //TO DO: ����� �� EMA
 
 if (eldNewBar.isNewBar() > 0)                          //�� ������ ����� ���� �������� TF
 {
  for (int attempts = 0; attempts < 25 && copiedTrend      < 0
                                       && copiedEMA3       < 0
                                       && copiedEMAfastEld < 0
                                       && copiedEMAfastJr  < 0
                                       && copiedEMAslowJr  < 0
                                       && copiedDayPrice   < 0
                                       && copiedEldPrice   < 0; attempts++) //�������� ������ �����������
  {
   copiedTrend      = CopyBuffer(     handleTrend, 4, 1, 1,      bufferTrend);
   copiedEMAfastEld = CopyBuffer(handleEMAfastEld, 0, 1, 2, bufferEMAfastEld);
   copiedEMAfastJr  = CopyBuffer( handleEMAfastJr, 0, 1, 2,  bufferEMAfastJr);
   copiedEMAslowJr  = CopyBuffer( handleEMAslowJr, 0, 1, 2,  bufferEMAslowJr);
   copiedEMA3       = CopyBuffer(      handleEMA3, 0, 1, 1,       bufferEMA3);
   copiedDayPrice = CopyClose(Symbol(), PERIOD_D1, 0, 1,   bufferDayPrice);
   copiedEldPrice = CopyClose(Symbol(),     eldTF, 1, 2, bufferEldTFPrice);
  }
  
  if (copiedTrend != 1 || copiedEMAfastEld != 2 || copiedEMAfastJr != 2 || copiedEMAslowJr != 2 ||
       copiedEMA3 != 1 ||   copiedDayPrice != 1 ||  copiedEldPrice != 2 )   //�������� ������ �����������
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ������.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return;
  }
  
  isProfit = tradeManager.isMinProfit(_Symbol);         // ��������� �� �������� �� ������� �� ������ ������� ������������ �������
  if (!isProfit && TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF))
  { //���� �� �������� minProfit �� ������ �����
     //close position 
  }
    
  wait++; 
  if (order_direction != 0)       // ���� ���� ������ � ����������� ������ 
  {
   if (wait > waitAfterBreakdown) // ��������� �� ���������� ����� �������� ����� �����������
   {
    wait = 0;                     // ���� �� ��������� �������� ������� �������� � ����������� ������
    order_direction = 0;
   }
  }
  
  if (bufferTrend[0] == 1)               //���� ����������� ������ TREND_UP  
  {
   if (GreatOrEqualDoubles(bufferEMA3[0] + deltaPriceToEMA*point, bufferDayPrice[0]))
   {
    if (GreatDoubles(bufferEMAfastEld[0], bufferEldTFPrice[0]) || GreatDoubles(bufferEMAfastEld[1], bufferEldTFPrice[1]))
    {
     if(GreatDoubles(bufferEMAslowJr[1], bufferEMAfastJr[1]) && LessDoubles(bufferEMAslowJr[0], bufferEMAfastJr[0]))
     {
      //OpenPosition
       order_direction = 1;
     }
    }
   }
  }
  
  if (bufferTrend[0] == 3)               //���� ����������� ������ TREND_DOWN  
  {
   if (GreatOrEqualDoubles(bufferDayPrice[0], bufferEMA3[0] + deltaPriceToEMA*point))
   {
    if (GreatDoubles(bufferEldTFPrice[0], bufferEMAfastEld[0]) || GreatDoubles(bufferEldTFPrice[1], bufferEMAfastEld[1]))
    {
     if(GreatDoubles(bufferEMAfastJr[1], bufferEMAslowJr[1]) && LessDoubles(bufferEMAfastJr[0], bufferEMAslowJr[0]))
     {
      //OpenPosition
      order_direction = -1;
     }
    }
   }
  }
 }
 
 if (useTrailing)
 {
  tradeManager.DoTrailing();
 }
}
//+------------------------------------------------------------------+
