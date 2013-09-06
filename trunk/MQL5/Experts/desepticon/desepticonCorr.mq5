//+------------------------------------------------------------------+
//|                                               desepticonCorr.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBar.mqh>
#include <TradeManager/TradeManager.mqh>
#include <divergenceStochastic.mqh>
#include <divergenceMACD.mqh>
//------------------INPUT---------------------------------------
//��������� desepticonCorrection
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;

//��������� ��� EMA
input int    periodEMAfastJr = 15;
input int    periodEMAslowJr = 9;
//��������� ��� MACD
input int    fast_EMA_period = 12;    //������� ������ EMA ��� MACD
input int    slow_EMA_period = 26;    //��������� ������ EMA ��� MACD
input int    signal_period = 9;       //������ ���������� ����� ��� MACD
//��������� ��� Stochastic
input int    kPeriod = 5;          // �-������ ����������
input int    dPeriod = 3;          // D-������ ����������
input int    slow  = 3;            // ����������� ����������. ��������� �������� �� 1 �� 3.
input int    top_level = 80;       // Top-level ���������
input int    bottom_level = 20;    // Bottom-level ����������

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
input int    deltaEMAtoEMA = 5;         // ����������� ������� ��� ��������� EMA
//��������� PriceBased indicator
input int    historyDepth = 40;    // ������� ������� ��� �������
input int    bars=30;              // ������� ������ ����������

//------------------GLOBAL--------------------------------------
int handleTrend;            // ����� PriceBased indicator
int handleMACDEld;          // ����� MACD �� ������� ����������
int handleSTOCEld;          // ����� Stochastic �� ������� ����������
int handleMACDJr;           // ����� MACD �� ������� ����������
int handleSTOCJr;           // ����� Stochastic �� ������� ����������
int handleEMAfastJr;        // ����� ������� EMA �� ������� ����������
int handleEMAslowJr;        // ����� ��������� EMA �� ������� ����������
double bufferTrend[];       // ����� ��� PriceBased indicator
double bufferSTOCEld[];     // ����� ��� Stohastic �������� ����������
double bufferEMAfastJr[];   // ����� ������� EMA �� ������� ����������
double bufferEMAslowJr[];   // ����� ��������� EMA �� ������� ���������� 

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
 tradeManager.Initialization();
 log_file.Write(LOG_DEBUG, StringFormat("%s �����������.", MakeFunctionPrefix(__FUNCTION__)));
 handleTrend = iCustom(Symbol(), Period(), "PriceBasedIndicator", historyDepth, bars);
 handleMACDEld = iMACD(Symbol(), eldTF, fast_EMA_period, slow_EMA_period, signal_period, PRICE_CLOSE);
 handleMACDJr  = iMACD(Symbol(),  jrTF, fast_EMA_period, slow_EMA_period, signal_period, PRICE_CLOSE);
 handleSTOCEld = iStochastic(NULL, eldTF, kPeriod, dPeriod, slow, MODE_SMA, STO_CLOSECLOSE);
 handleSTOCJr  = iStochastic(NULL,  jrTF, kPeriod, dPeriod, slow, MODE_SMA, STO_CLOSECLOSE);
 handleEMAfastJr = iMA(Symbol(), jrTF, periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 handleEMAslowJr = iMA(Symbol(), jrTF, periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);

 if (    handleTrend == INVALID_HANDLE || handleMACDEld == INVALID_HANDLE ||    handleMACDJr == INVALID_HANDLE ||
       handleSTOCEld == INVALID_HANDLE ||  handleSTOCJr == INVALID_HANDLE || handleEMAfastJr == INVALID_HANDLE ||
     handleEMAslowJr == INVALID_HANDLE )
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
  
 ArraySetAsSeries(    bufferTrend, true);
 ArraySetAsSeries(  bufferSTOCEld, true);
 ArraySetAsSeries(bufferEMAfastJr, true);
 ArraySetAsSeries(bufferEMAslowJr, true);
 ArrayResize(    bufferTrend, 1);
 ArrayResize(  bufferSTOCEld, 1);
 ArrayResize(bufferEMAfastJr, 2);
 ArrayResize(bufferEMAslowJr, 2);
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 tradeManager.Deinitialization();
 IndicatorRelease(handleTrend);
 IndicatorRelease(handleMACDEld);
 IndicatorRelease(handleMACDJr);
 IndicatorRelease(handleSTOCEld);
 IndicatorRelease(handleSTOCJr);
 IndicatorRelease(handleEMAfastJr);
 IndicatorRelease(handleEMAslowJr); 
 ArrayFree(bufferTrend);
 ArrayFree(bufferSTOCEld);
 ArrayFree(bufferEMAfastJr);
 ArrayFree(bufferEMAslowJr);
 log_file.Write(LOG_DEBUG, StringFormat("%s �������������.", MakeFunctionPrefix(__FUNCTION__)));
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 static bool isProfit = false;
 static int  wait = 0;
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 int copiedTrend = -1;
 
 if (eldNewBar.isNewBar() > 0)                          //�� ������ ����� ���� �������� TF
 {
  for (int attempts = 0; attempts < 25 && copiedTrend < 0; attempts++) //�������� ������ �����������
  {
   copiedTrend = CopyBuffer(handleTrend, 4, 1, 1, bufferTrend);
  }
  
  if (copiedTrend != 1)   //�������� ������ �����������
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ������.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return;
  }
  
  isProfit = tradeManager.isMinProfit(_Symbol);         // ��������� �� �������� �� ������� �� ������ ������� ������������ �������
  if (isProfit && TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF))
  { //���� �� �������� minProfit �� ������ �����
   log_file.Write(LOG_DEBUG, StringFormat("%s ������� ����� �������� ����������.��������� �������.", MakeFunctionPrefix(__FUNCTION__))); 
   tradeManager.ClosePosition(Symbol()); 
  }
  
  if (useJrEMAExit && isProfit)  //����� �� ������� EMA ��� ���������� MinProfit
  {
   switch(tradeManager.GetPositionType(Symbol()))
   {
    case OP_BUY:
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
    {
     if (GreatDoubles(bufferEMAfastJr[0], bufferEMAslowJr[0] + deltaEMAtoEMA*point))
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s ������� �������� ������������ �������. ����� �� ������� EMA.", MakeFunctionPrefix(__FUNCTION__)));
      tradeManager.ClosePosition(Symbol());
     }
     break;
    }
    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
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
 } //end isNewBar  
 
 if (bufferTrend[0] == 5 || bufferTrend[0] == 6)   // ����������� ������ CORRECTION_UP ��� CORRECTION_DOWN
 {
  if (ConditionForBuy() > ConditionForSell())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� BUY.", MakeFunctionPrefix(__FUNCTION__)));
   tradeManager.OpenPosition(Symbol(), opBuy, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
  }
  if (ConditionForSell() > ConditionForBuy())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� SELL.", MakeFunctionPrefix(__FUNCTION__)));
   tradeManager.OpenPosition(Symbol(), opSell, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, priceDifference);
  }
 }

 if (useTrailing)
 {
  tradeManager.DoTrailing();
 }  
}
//+------------------------------------------------------------------+
int ConditionForBuy()
{
 if(divergenceMACD(handleMACDEld, Symbol(), eldTF) == 1) return(100);
 if(divergenceMACD( handleMACDJr, Symbol(),  jrTF) == 1) return(50);
 if(divergenceSTOC(handleSTOCEld, Symbol(), eldTF, top_level, bottom_level) == 1) return(100);
 if(divergenceSTOC( handleSTOCJr, Symbol(),  jrTF, top_level, bottom_level) == 1) return(50);
 
 int copiedSTOC = -1;
 int copiedEMAfastJr = -1;
 int copiedEMAslowJr = -1;
 for (int attempts = 0; attempts < 25 && copiedSTOC      < 0
                                      && copiedEMAfastJr < 0
                                      && copiedEMAslowJr < 0; attempts++)
 {
  copiedSTOC = CopyBuffer(handleSTOCEld, 0, 1, 1, bufferSTOCEld);
  copiedEMAfastJr  = CopyBuffer( handleEMAfastJr, 0, 1, 2,  bufferEMAfastJr);
  copiedEMAslowJr  = CopyBuffer( handleEMAslowJr, 0, 1, 2,  bufferEMAslowJr);
 }
 if (copiedSTOC != 1 || copiedEMAfastJr != 2 || copiedEMAslowJr != 2)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ������.Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(0);
 } 
 if(GreatDoubles(bufferEMAslowJr[1], bufferEMAfastJr[1]) && GreatDoubles (bufferEMAfastJr[0], bufferEMAslowJr[0]) 
    && bufferSTOCEld[0] < bottom_level) //��������� �����; ����������� ������� EMA ����� �����
    return(100); 
 return(0);
}
///
//
///
int ConditionForSell()
{
 if(divergenceMACD(handleMACDEld, Symbol(), eldTF) == -1) return(100);
 if(divergenceMACD( handleMACDJr, Symbol(),  jrTF) == -1) return(50);
 if(divergenceSTOC(handleSTOCEld, Symbol(), eldTF, top_level, bottom_level) == -1) return(100);
 if(divergenceSTOC( handleSTOCJr, Symbol(),  jrTF, top_level, bottom_level) == -1) return(50);
 
 int copiedSTOC = -1;
 int copiedEMAfastJr = -1;
 int copiedEMAslowJr = -1;
 for (int attempts = 0; attempts < 25 && copiedSTOC      < 0
                                      && copiedEMAfastJr < 0
                                      && copiedEMAslowJr < 0; attempts++)
 {
  copiedSTOC = CopyBuffer(handleSTOCEld, 0, 1, 1, bufferSTOCEld);
  copiedEMAfastJr  = CopyBuffer( handleEMAfastJr, 0, 1, 2,  bufferEMAfastJr);
  copiedEMAslowJr  = CopyBuffer( handleEMAslowJr, 0, 1, 2,  bufferEMAslowJr);
 }
 if (copiedSTOC != 1 || copiedEMAfastJr != 2 || copiedEMAslowJr != 2)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ������.Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(0);
 } 
 if(GreatDoubles(bufferEMAfastJr[1], bufferEMAslowJr[1]) && GreatDoubles (bufferEMAslowJr[0], bufferEMAfastJr[0]) 
    && bufferSTOCEld[0] > top_level) //��������� ������; ����������� ������� EMA ������ ����
    return(100); 
 return(0);
}