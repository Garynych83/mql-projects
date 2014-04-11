//+------------------------------------------------------------------+
//|                                                     MEGATRON.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ������� �������� - ������������ ����������                       |
//+------------------------------------------------------------------+

#define ADD_TO_STOPPLOSS 50

//-------- ����������� ���������
#include <Lib CisNewBar.mqh>                // ��� �������� ������������ ������ ����
#include <TradeManager/TradeManager.mqh>    // �������� ����������
#include <PointSystem/PointSystem.mqh>            // ����� ������� �������
#include <ColoredTrend/ColoredTrendUtilities.mqh>

//-------- ������� ��������� �����������
sinput string stoc_string="";                                           // ��������� Stochastic 
input int    kPeriod = 5;                                               // �-������ ����������
input int    dPeriod = 3;                                               // D-������ ����������
input int    slow  = 3;                                                 // ����������� ����������. ��������� �������� �� 1 �� 3.
input int    top_level = 80;                                            // Top-level ���������
input int    bottom_level = 20;                                         // Bottom-level ����������

sinput string macd_string="";                                           // ��������� MACD
input int fast_EMA_period = 12;                                         // ������� ������ EMA ��� MACD
input int slow_EMA_period = 26;                                         // ��������� ������ EMA ��� MACD
input int signal_period = 9;                                            // ������ ���������� ����� ��� MACD
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE; // ��� ����  

sinput string ema_string="";                                            // ��������� ��� EMA
input int    periodEMAfastEld = 26;                                     // ������ �������   EMA �� ������� ���������� 
input int    periodEMAfastJr = 9;                                       // ������ �������   EMA �� ������� ����������
input int    periodEMAslowJr = 15;                                      // ������ ��������� EMA �� ������� ����������

sinput string pbi_string ="";                                           // ��������� PriceBased indicator
input int    historyDepth = 1000;                                       // ������� ������� ��� �������
input double   percentage_ATR = 1;                                    // ������� ��� ��� ��������� ������ ����������
input double   difToTrend = 1.5;                                        // ������� ����� ������������ ��� ��������� ������

sinput string deal_string="";                                           // ��������� ������  
input double orderVolume = 0.1;                                         // ����� ������
input int    sl = 100;                                             // Stop Loss
input int    tp = 100;                                             // Take Profit
input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS;      // ��� ����������� ������                    
input int    priceDifference = 50;                                      // Price Difference

/*
sinput string base_string ="";                                          // ������� ��������� ������
input bool    useJrEMAExit = false;                                     // ����� �� �������� �� ���
input int     posLifeTime = 10;                                         // ����� �������� ������ � �����
input int     deltaPriceToEMA = 7;                                      // ���������� ������� ����� ����� � EMA ��� �����������
input int     deltaEMAtoEMA = 5;                                        // ����������� ������� ��� ��������� EMA
input int     waitAfterDiv = 4;                                         // �������� ������ ����� ����������� (� �����)
*/
input        ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;      // ��� ���������
input int    trStop = 100;                                              // Trailing Stop
input int    trStep = 100;                                              // Trailing Step
input int    minProfit = 250;                                           // Minimal Profit 

// ���������� �������� ������
sEmaParams    ema_params;          // ��������� EMA
sMacdParams   macd_params;         // ��������� MACD
sStocParams   stoc_params;         // ��������� ����������
sPbiParams    pbi_params;          // ��������� PriceBased indicator
sDealParams   deal_params;          // ��������� ������
sBaseParams   base_params;          // ������� ���������

int handlePBI, handleMACD, handleStochastic, handleEMA3, handleEMAfast, handleEMAfastJr, handleEMAslowJr;

// ���������� �������
CTradeManager  *ctm;                // ��������� �� ������ ������ TradeManager
CPointSys      *pointsys;           // ��������� �� ������ ������ ������� �������

// ���������� ��������� ����������
string symbol;                       // ���������� ��� �������� �������
ENUM_TIMEFRAMES curTF, jrTF, eldTF;              // ���������� ��� �������� ����������
ENUM_TM_POSITION_TYPE deal_type;     // ��� ���������� ������
ENUM_TM_POSITION_TYPE opBuy, opSell; // ������ �� ������� 

//+------------------------------------------------------------------+
//| ������� ���������������                                          |
//+------------------------------------------------------------------+
int OnInit()
{
  Print("������");
  // ��������� ������ � ������
  symbol = Symbol();
  curTF = Period();
  jrTF = GetBottomTimeframe(curTF);
  eldTF = GetTopTimeframe(curTF);
  
 ////// �������������� ����������
  handlePBI = iCustom(symbol, curTF, "PriceBasedIndicator", historyDepth, percentage_ATR, difToTrend);
  handleMACD = iMACD(symbol, curTF, fast_EMA_period,  slow_EMA_period, signal_period, applied_price);
  handleStochastic = iStochastic(symbol, curTF, kPeriod, dPeriod, slow, MODE_SMA, STO_LOWHIGH);
  handleEMA3 = iMA(symbol,  eldTF, 3, 0, MODE_EMA, PRICE_CLOSE);
  handleEMAfast = iMA(symbol,  curTF, periodEMAfastEld, 0, MODE_EMA, PRICE_CLOSE); 
  handleEMAfastJr = iMA(symbol,  jrTF, periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
  handleEMAslowJr = iMA(symbol,  jrTF, periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);    

 //////// ��������������� ����������
  int handleShowDivMACD = iCustom(symbol, curTF, "ShowMeYourDivMACD");
  int handleShowDivSto = iCustom(symbol, curTF, "ShowMeYourDivStachastic");
  
 /////// �������� �������� ������� 
  if (handlePBI == INVALID_HANDLE || 
      handleEMA3 == INVALID_HANDLE ||
      handleEMAfast == INVALID_HANDLE ||
      handleEMAfastJr == INVALID_HANDLE || 
      handleEMAslowJr == INVALID_HANDLE || 
      handleMACD == INVALID_HANDLE || 
      handleStochastic    == INVALID_HANDLE   )
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                         , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  }   
   
 //------- ��������� ��������� ������ 
 // ��������� �������� EMA
  ema_params.handleEMA3 = handleEMA3;
  ema_params.handleEMAfast = handleEMAfast;
  ema_params.handleEMAfastJr = handleEMAfastJr;
  ema_params.handleEMAslowJr = handleEMAslowJr;
  
  // ��������� ��������� MACD
  macd_params.handleMACD = handleMACD; 
  ///////////////////////////////////////////////////////////////
 
  // ��������� ��������� ����������
  stoc_params.handleStochastic = handleStochastic;
  stoc_params.bottom_level = bottom_level;
  stoc_params.top_level = top_level;
  //////////////////////////////////////////////////////////////
  
  // ��������� ��������� PBI
  pbi_params.handlePBI = handlePBI;
  pbi_params.historyDepth = historyDepth;
  //////////////////////////////////////////////////////////////
  
  // ��������� ��������� ������
  deal_params.minProfit    = minProfit;
  deal_params.orderVolume  = orderVolume;
  deal_params.sl           = sl;
  deal_params.tp           = tp;
  deal_params.trStep       = trStep;
  deal_params.trStop       = trStop;
  /////////////////////////////////////////////////////////////
  
  // ��������� ������� ���������
  base_params.eldTF                      = eldTF;
  base_params.curTF                      = curTF;
  base_params.jrTF                       = jrTF;
  /*
  base_params.deltaEMAtoEMA              = deltaEMAtoEMA;
  base_params.deltaPriceToEMA            = deltaPriceToEMA;
  base_params.posLifeTime                = posLifeTime;
  base_params.useJrEMAExit               = useJrEMAExit;
  base_params.waitAfterDiv               = waitAfterDiv;
  */
  //------- �������� ������ ��� ������������ �������
  ctm      = new CTradeManager(); // �������� ������ ��� ������ ������ TradeManager
  pointsys = new CPointSys(base_params,ema_params,macd_params,stoc_params,pbi_params);      // �������� ������ ��� ������ ������ ������� �������  
   
  switch (pending_orders_type)  //���������� priceDifference
  {
   case USE_LIMIT_ORDERS: //useLimitsOrders = true;
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
//+------------------------------------------------------------------+
//| ������� �����������������                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(handlePBI);
   IndicatorRelease(handleEMAfast);
   IndicatorRelease(handleEMAfastJr);
   IndicatorRelease(handleEMAslowJr);
   IndicatorRelease(stoc_params.handleStochastic);
   IndicatorRelease(handleMACD);
   // ������� ������, ���������� ��� ������������ �������
   delete ctm;      // ������� ������ ������ �������� ����������
   delete pointsys; // ������� ������ ������ �������� �������*/
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 int stopLoss = 0;
 ctm.OnTick();
 ctm.DoTrailing();  
 // ������� �������� ������
 int point = pointsys.GetFlatSignals();
 if (point >= 2)
 {
  if (ctm.GetPositionCount() == 0)
  {
   Print("point = ",point);
   stopLoss = CountStoploss(point);
   ctm.OpenUniquePosition(symbol,curTF, opBuy, orderVolume, stopLoss, 0, trailingType, minProfit, trStop, trStep, handlePBI, priceDifference);        
  }
  else
  {
   ctm.PositionChangeSize(symbol, orderVolume);
  }
 }
 if (point <= -2)
 {
  if (ctm.GetPositionCount() == 0)
  {
   Print("point = ",point);
   stopLoss = CountStoploss(point);
   ctm.OpenUniquePosition(symbol,curTF, opSell, orderVolume, stopLoss, 0, trailingType, minProfit, trStop, trStep, handlePBI, priceDifference);        
  }
  else
  {
   ctm.PositionChangeSize(symbol, orderVolume);
  }
 }
}

int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, pbi_params.historyDepth);
 
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6;
  priceAB = SymbolInfoDouble(symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; // ���� point > 0 ������� ����� � ����������, ����� � �����������
  priceAB = SymbolInfoDouble(symbol, SYMBOL_BID);
  direction = -1;
 }
 
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(pbi_params.handlePBI, extrBufferNumber, 0, pbi_params.historyDepth, bufferStopLoss);
 }
 if (copiedPBI < 0)
 {
  PrintFormat("%s �� ������� ����������� ����� bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(false);
 }
 
 for(int i = 0; i < pbi_params.historyDepth; i++)
 {
  if (bufferStopLoss[i] > 0)
  {
   Print("������ ���������");
   if (LessDoubles(direction*bufferStopLoss[i], direction*priceAB))
   {
    Print("��������� (%.05f) ������ ���� (%.05f)");
    stopLoss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point()) + ADD_TO_STOPPLOSS;
    break;
   }
  }
 }
 
 if (stopLoss <= 0)
 {
  PrintFormat("�� ��������� ���� �� ����������");
  stopLoss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}

/*
/////////////////////////////////////
/////////////////////////////////////
double iHigh(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   double high=0;
   ArraySetAsSeries(High,true);
   int copied=CopyHigh(symbol,timeframe,0,Bars(symbol,timeframe),High);
   if(copied>0 && index<copied) high=High[index];
   return(high);
  }


int iHighest(string symbol,ENUM_TIMEFRAMES tf,int count=WHOLE_ARRAY,int start=0)
  {
      double High[];
      ArraySetAsSeries(High,true);
      CopyHigh(symbol,tf,start,count,High);
      return(ArrayMaximum(High,0,count)+start);
     
     return(0);
}

double iLow(string symbol,ENUM_TIMEFRAMES timeframe,int index)
  {
   double low=0;
   ArraySetAsSeries(Low,true);
   int copied=CopyLow(symbol,timeframe,0,Bars(symbol,timeframe),Low);
   if(copied>0 && index<copied) low=Low[index];
   return(low);
  }


int iLowest(string symbol,ENUM_TIMEFRAMES tf,int count=WHOLE_ARRAY,int start=0)
  {
      double Low[];
      ArraySetAsSeries(Low,true);
      CopyLow(symbol,tf,start,count,Low);
      return(ArrayMinimum(Low,0,count)+start);
     
     return(0);
}*/