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

input int periodEMAfastEld = 26;        // ������ EMA fast �������� ����������
input int periodEMAfastJr  = 26;        // ������ EMA fast �������� ����������
input int periodEMAslowJr  = 12;         // ������ EMA slow �������� ����������

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
input bool   useJrEMAExit = false;      // ����� �� �������� �� ���
input int    posLifeTime = 10;          // ����� �������� ������ � �����
input int    waitAfterBreakdown = 4;    // �������� ������ ����� ������ (� �����)
input int    deltaPriceToEMA = 7;       // ���������� ������� ����� ����� � EMA ��� �����������
input int    deltaEMAtoEMA = 5;         // ����������� ������� ��� ��������� EMA
//��������� PriceBased indicator
input int    historyDepth = 40;    // ������� ������� ��� �������
input int    bars=30;              // ������� ������ ����������

//------------------GLOBAL--------------------------------------
int handleTrend;            // ����� PriceBased indicator
int handleEMA3Day;          // ����� EMA 3 �������� TF
int handleEMAfastEld;       // ����� EMA fast �������� ����������
int handleEMAfastJr;        // ����� EMA fast �������� ����������
int handleEMAslowJr;        // ����� EMA slow �������� ����������
double bufferTrend[];       // ����� ��� PriceBased indicator  
double bufferHighEld[];     // ����� ��� ���� high �� ������� ����������
double bufferLowEld[];      // ����� ��� ���� low �� ������� ����������
double bufferEMA3Day[];     // ����� ��� EMA 3
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
 handleEMA3Day = iMA(Symbol(), PERIOD_D1, 3, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAfastEld = iMA(Symbol(), eldTF, periodEMAfastEld, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAfastJr  = iMA(Symbol(),  jrTF,  periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAslowJr  = iMA(Symbol(),  jrTF,  periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);
 
 if (     handleTrend == INVALID_HANDLE ||   handleEMA3Day == INVALID_HANDLE || 
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
 ArraySetAsSeries(   bufferHighEld, true);
 ArraySetAsSeries(    bufferLowEld, true);
 ArraySetAsSeries(bufferEMAfastEld, true);
 ArraySetAsSeries( bufferEMAfastJr, true);
 ArraySetAsSeries( bufferEMAslowJr, true);
 ArraySetAsSeries(   bufferEMA3Day, true);
 ArrayResize(     bufferTrend, 1);
 ArrayResize(   bufferHighEld, 2);
 ArrayResize(    bufferLowEld, 2); 
 ArrayResize(bufferEMAfastEld, 2);
 ArrayResize( bufferEMAfastJr, 2);
 ArrayResize( bufferEMAslowJr, 2);
 ArrayResize(   bufferEMA3Day, 1);
 
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
 IndicatorRelease(handleEMA3Day);
 ArrayFree(bufferTrend);
 ArrayFree(bufferHighEld);
 ArrayFree(bufferLowEld);
 ArrayFree(bufferEMAfastEld);
 ArrayFree(bufferEMAfastJr);
 ArrayFree(bufferEMAslowJr);
 ArrayFree(bufferEMA3Day); 
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
 int copiedHighEld    = -1;
 int copiedLowEld     = -1;
 
 for (int attempts = 0; attempts < 25 && copiedTrend      < 0
                                      && copiedEMA3       < 0
                                      && copiedEMAfastEld < 0
                                      && copiedEMAfastJr  < 0
                                      && copiedEMAslowJr  < 0
                                      && copiedHighEld    < 0
                                      && copiedLowEld     < 0; attempts++) //�������� ������ �����������
 {
  copiedTrend      = CopyBuffer(     handleTrend, 4, 1, 1,      bufferTrend);
  copiedEMAfastEld = CopyBuffer(handleEMAfastEld, 0, 1, 2, bufferEMAfastEld);
  copiedEMAfastJr  = CopyBuffer( handleEMAfastJr, 0, 1, 2,  bufferEMAfastJr);
  copiedEMAslowJr  = CopyBuffer( handleEMAslowJr, 0, 1, 2,  bufferEMAslowJr);
  copiedEMA3       = CopyBuffer(   handleEMA3Day, 0, 0, 1,    bufferEMA3Day);
  copiedHighEld = CopyHigh(Symbol(), eldTF, 1, 2, bufferHighEld);
  copiedLowEld  =  CopyLow(Symbol(), eldTF, 1, 2,  bufferLowEld);   
 }
 
 if (copiedTrend != 1 || copiedEMAfastEld != 2 || copiedEMAfastJr != 2 || copiedEMAslowJr != 2 ||
      copiedEMA3 != 1 ||    copiedHighEld != 2 ||    copiedLowEld != 2)    //��������� ������������� ������ �����������
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ������.Error(%d) = %s" 
                                         , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return;
 } 
 
 if (eldNewBar.isNewBar() > 0)                          //�� ������ ����� ���� �������� TF
 {
  isProfit = tradeManager.isMinProfit(_Symbol);         // ��������� �� �������� �� ������� �� ������ ������� ������������ �������
  if (isProfit && TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF))
  { //���� �� �������� minProfit �� ������ �����
   log_file.Write(LOG_DEBUG, StringFormat("%s ������� ����� �������� ����������.��������� �������.", MakeFunctionPrefix(__FUNCTION__))); 
   tradeManager.ClosePosition(Symbol());
  }
  
  if (useJrEMAExit && isProfit) //����� �� ������� EMA ��� ���������� MinProfit
  {
   switch(tradeManager.GetPositionType(Symbol()))
   {
    case OP_BUY:
    //case OP_BUYLIMIT:
    //case OP_BUYSTOP:
    {
     if (GreatDoubles(bufferEMAfastJr[0], bufferEMAslowJr[0] + deltaEMAtoEMA*point))
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s ������� �������� ������������ �������. ����� �� ������� EMA.", MakeFunctionPrefix(__FUNCTION__)));
      tradeManager.ClosePosition(Symbol());
     }
     break;
    }
    case OP_SELL:
    //case OP_SELLLIMIT:
    //case OP_SELLSTOP:
    {
     if (LessDoubles(bufferEMAfastJr[0], bufferEMAslowJr[0] - deltaEMAtoEMA*point))
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s ������� �������� ������������ �������. ����� �� ������� EMA.", MakeFunctionPrefix(__FUNCTION__)));
      tradeManager.ClosePosition(Symbol());
     }
     break;
    }
    case OP_UNKNOWN:
    break;
   }
  } //end useJrEMAExit
    
  wait++; 
  if (order_direction != 0)       // ���� ���� ������ � ����������� ������ 
  {
   if (wait > waitAfterBreakdown) // ��������� �� ���������� ����� �������� ����� �����������
   {
    wait = 0;                     // ���� �� ��������� �������� ������� �������� � ����������� ������
    order_direction = 0;
   }
  }
 } //end isNewBar  
  
 if (bufferTrend[0] == 1)               //���� ����������� ������ TREND_UP  
 {
  //log_file.Write(LOG_DEBUG, StringFormat("%s TREND UP.", MakeFunctionPrefix(__FUNCTION__)));
  if (GreatOrEqualDoubles(bufferEMA3Day[0] + deltaPriceToEMA*point, bid))
  {
   //log_file.Write(LOG_DEBUG, StringFormat("%s ������� ���� ������ EMA3.", MakeFunctionPrefix(__FUNCTION__)));
   if (GreatDoubles(bufferEMAfastEld[0] + deltaPriceToEMA*point, bufferLowEld[0]) || 
       GreatDoubles(bufferEMAfastEld[1] + deltaPriceToEMA*point, bufferLowEld[1]))
   {
    //log_file.Write(LOG_DEBUG, StringFormat("%s EMAfast ���� �� ����� �� ��������� 2� �����.", MakeFunctionPrefix(__FUNCTION__)));
    if (GreatDoubles(bufferEMAslowJr[1], bufferEMAfastJr[1]) && LessDoubles(bufferEMAslowJr[0], bufferEMAfastJr[0]))
    {
     //log_file.Write(LOG_DEBUG, StringFormat("%s ����������� EMA �� ������� TF.", MakeFunctionPrefix(__FUNCTION__)));
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� BUY.", MakeFunctionPrefix(__FUNCTION__)));
     tradeManager.OpenUniquePosition(Symbol(), opBuy, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
     order_direction = 1;
    }
   }
  }
 } //end TREND_UP
 else if (bufferTrend[0] == 3)               //���� ����������� ������ TREND_DOWN  
 {
  //log_file.Write(LOG_DEBUG, StringFormat("%s TREND DOWN.", MakeFunctionPrefix(__FUNCTION__)));
  if (GreatOrEqualDoubles(ask, bufferEMA3Day[0] - deltaPriceToEMA*point))
  {
   //log_file.Write(LOG_DEBUG, StringFormat("%s ������� ���� ������ EMA3.", MakeFunctionPrefix(__FUNCTION__)));
   if (GreatDoubles(bufferHighEld[0], bufferEMAfastEld[0] - deltaPriceToEMA*point) || 
       GreatDoubles(bufferHighEld[1], bufferEMAfastEld[1] - deltaPriceToEMA*point))
   {
    //log_file.Write(LOG_DEBUG, StringFormat("%s EMAfast ���� �� ����� �� ��������� 2� �����.", MakeFunctionPrefix(__FUNCTION__)));
    if (GreatDoubles(bufferEMAfastJr[1], bufferEMAslowJr[1]) && LessDoubles(bufferEMAfastJr[0], bufferEMAslowJr[0]))
    {
     //log_file.Write(LOG_DEBUG, StringFormat("%s ����������� EMA �� ������� TF.", MakeFunctionPrefix(__FUNCTION__)));
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� SELL.", MakeFunctionPrefix(__FUNCTION__)));
     tradeManager.OpenUniquePosition(Symbol(), opSell, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
     order_direction = -1;
    }
   }
  }
 } //end TREND_DOWN
 
 if (useTrailing)
 {
  tradeManager.DoTrailing();
 }
}
//+------------------------------------------------------------------+
