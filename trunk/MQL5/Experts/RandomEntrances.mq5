//+------------------------------------------------------------------+
//|                                              RandomEntrances.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <TradeManager\TradeManager.mqh> //���������� ���������� ��� ���������� �������� ��������

#define ADD_TO_STOPPLOSS 50

input int step = 100;
input int countSteps = 4;
input int volume = 5;
input double ko = 2;        // ko=0-���� �����, ko=1-������ ����, ko>1-������.����, k0<1-������.���� 

input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
//input bool stepbypart = false; // 
input double   percentage_ATR_cur = 2;   
input double   difToTrend_cur = 1.5;
input int      ATR_ma_period_cur = 12;
input int      trStop                               = 100;                // Trailing Stop
input int      trStep                               = 100;                // Trailing Step
input int      minProfit                            = 250;                // ����������� �������

string symbol;
ENUM_TIMEFRAMES timeframe;
int count;
double lot;
double rnd;
ENUM_TM_POSITION_TYPE opBuy, opSell;
double aDeg[], aKo[];
int profit;
CTradeManager ctm();

int handle_PBI;
datetime history_start;

int historyDepth;

int handlePBIcur;                                                        // ����� PriceBasedIndicator

int stop_loss=0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   timeframe = Period();
   MathSrand((int)TimeLocal());
   count = 0;
   history_start=TimeCurrent();     //--- �������� ����� ������� �������� ��� ��������� �������� �������
   historyDepth = 1000;
   if (trailingType == TRAILING_TYPE_PBI)
   {
    handlePBIcur = iCustom(symbol, timeframe, "PriceBasedIndicator", historyDepth, percentage_ATR_cur, difToTrend_cur);
    if(handlePBIcur == INVALID_HANDLE)                                //��������� ������� ������ ����������
    {
     Print("�� ������� �������� ����� Price Based Indicator");      //���� ����� �� �������, �� ������� ��������� � ��� �� ������
    }
   }
   ArrayResize(aDeg, countSteps);
   ArrayResize(aKo, countSteps);
   
   double k = 0, sum = 0;
   for (int i = 0; i < countSteps; i++)
   {
    k = k + MathPow(ko, i);
   }
   aKo[0] = 100 / k;
   for (int i = 1; i < countSteps - 1; i++)
   {
    aKo[i] = aKo[i - 1] * ko;
    sum = sum + aKo[i];
   }
   aKo[countSteps - 1] = 100 - sum;
      
   for (int i = 0; i < countSteps; i++)
   {
    aDeg[i] = NormalizeDouble(volume * aKo[i] * 0.01, 2);
   }
        
   for (int i = 0; i < countSteps; i++)
   {
    PrintFormat("aDeg[%d] = %.02f", i, aDeg[i]);
   }
         
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // ������� ����� ���������� PBI
   IndicatorRelease(handlePBIcur);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
 {
  ctm.OnTick();
  ctm.DoTrailing();
  // ���� ������� ���
  if (ctm.GetPositionCount() == 0)
  {
   lot = aDeg[0];
   count = 1;
   rnd = (double)MathRand()/32767;
   ENUM_TM_POSITION_TYPE operation;
   if ( GreatDoubles(rnd,0.5,5) )
    {
     operation = OP_SELL;
     stop_loss = CountStoploss(-1);
    } 
   else
    {
     operation = OP_BUY;
     stop_loss = CountStoploss(1);
    }
   
   ctm.OpenUniquePosition(symbol, timeframe, operation, lot, stop_loss, 0, trailingType,minProfit, trStop, trStep, handlePBIcur);

  }
  // ���� ���� �������� �������
  if (ctm.GetPositionCount() > 0)
  {
   profit = ctm.GetPositionPointsProfit(symbol);
   if (profit > step && count < countSteps) 
   {
    lot = aDeg[count];
    if (lot > 0) ctm.PositionChangeSize(symbol, lot);
    count++;
   }
  }
 }

//+------------------------------------------------------------------+
void OnTrade()
  {
   ctm.OnTrade(history_start);
  }


// ������� ��������� ���� ����
int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, historyDepth);
 
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
  copiedPBI = CopyBuffer(handlePBIcur, extrBufferNumber, 0,historyDepth, bufferStopLoss);
 }
 if (copiedPBI < historyDepth)
 {
  PrintFormat("%s �� ������� ����������� ����� bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(copiedPBI);
 }
 
 for(int i = 0; i < historyDepth; i++)
 {
  
  if (bufferStopLoss[i] > 0)
  {
   if (LessDoubles(direction*bufferStopLoss[i], direction*priceAB))
   {
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
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}

