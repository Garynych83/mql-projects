//+------------------------------------------------------------------+
//|                                                       condom.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include  <CompareDoubles.mqh>
#include  <Lib CisNewBar.mqh>
#include  <TradeManager\TradeManager.mqh>            // ���������� ���������� ��� ���������� �������� ��������
#include  <CLog.mqh> 
//#include  <Graph\Graph.mqh>                        // ���������� ����������� ����������
#include  <ColoredTrend\ColoredTrendUtilities.mqh>   // ��������� ����������� ������



//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
//input ulong _magic = 1122;
input int SL = 150;
input int TP = 500;
input double _lot = 1;
input int historyDepth = 40;
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input bool trailing = false;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
input bool tradeOnTrend = false;

input bool useLimitOrders = false;
input int limitPriceDifference = 20;
input bool useStopOrders = false;
input int stopPriceDifference = 20;

string symbol;                               //���������� ��� �������� �������
datetime history_start;

CTradeManager ctm();
MqlTick tick;

//int handleMACD;
int handle_PBI;                              //����� ���������� Price Based Indicator
double  high_buf[], low_buf[], close_buf[2],PBI_buf[1]; //������
ENUM_TM_POSITION_TYPE opBuy, opSell;
int priceDifference;

double globalMax;
double globalMin;
bool waitForSell;
bool waitForBuy;

ENUM_TRAILING_TYPE  trailingType;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                    //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   history_start=TimeCurrent();        //--- �������� ����� ������� �������� ��� ��������� �������� �������
 
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
   
   if (tradeOnTrend)
   {    
    handle_PBI = iCustom(symbol, timeframe, "PriceBasedIndicator"); //��������� ����� ���������� PriceBasedIndicator  
    
    if(handle_PBI == INVALID_HANDLE)                                  //��������� ������� ������ ����������
    {
     Print("�� ������� �������� ����� Price Based Indicator");               //���� ����� �� �������, �� ������� ��������� � ��� �� ������
     return(-1);                                                  //��������� ������ � �������
    }
   }
   
   if (trailing)
    trailingType = TRAILING_TYPE_USUAL;
   else
    trailingType = TRAILING_TYPE_NONE;
   
   //������������� ���������� ��� �������� ���_buf
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);

   globalMax = 0;
   globalMin = 0;
   waitForSell = false;
   waitForBuy = false;
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // ����������� ������������ ������� �� ������
   ArrayFree(low_buf);
   ArrayFree(high_buf);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ctm.OnTick();
   //���������� ��� �������� ����������� ������ � ������� ��������
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errPBI = 0;
   
   static CisNewBar isNewBar(symbol, timeframe);
   
   if(isNewBar.isNewBar() > 0)
   {
    if (tradeOnTrend)
    {
     //�������� ������ �� ������������� ������� � ������������ ������ PBI_buf ��� ���������� ������ � ����
     errPBI = CopyBuffer(handle_PBI, 4, 0, 1, PBI_buf); //�������� ����� Price Based Indicator
     if(errPBI < 0)
     {
      Alert("�� ������� ����������� ������ �� ������������� ������"); 
      return; 
     }
    } 
    //�������� ������ �������� ������� � ������������ ������� ��� ���������� ������ � ����
    errLow   = CopyLow(symbol, timeframe, 2, historyDepth, low_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
    errHigh  = CopyHigh(symbol, timeframe, 2, historyDepth, high_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
    errClose = CopyClose(symbol, timeframe, 1, 2, close_buf); // (0 - ���. ���, �������� 2 �����. ����)
    if(errLow < 0 || errHigh < 0 || errClose < 0)                         //���� ���� ������
    {
     Alert("�� ������� ����������� ������ �� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
     return;                                                             //� ������� �� �������
    }  

    globalMax = high_buf[ArrayMaximum(high_buf)];
    globalMin = low_buf[ArrayMinimum(low_buf)];

    if(LessDoubles(close_buf[1], globalMin)) // ��������� Close(0 - ������, 1 - ������, �.� �� ��� � ���������) ���� ����������� ��������
    {
     waitForSell = false;
     waitForBuy = true;
    }
    
    if(GreatDoubles(close_buf[1], globalMax)) // ��������� Close(0 - ������, 1 - ������, �.� �� ��� � ���������) ���� ����������� ���������
    {
     waitForBuy = false;
     waitForSell = true;
    }
   }
   
 if (!tradeOnTrend || (PBI_buf[0] != MOVE_TYPE_TREND_DOWN && PBI_buf[0] != MOVE_TYPE_TREND_UP))
  {         
   if(!SymbolInfoTick(Symbol(),tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
    return;
   }
      
   if (waitForBuy)
   { 
    if (GreatDoubles(tick.ask, close_buf[0]) && GreatDoubles(tick.ask, close_buf[1]))
    {
     if (ctm.OpenUniquePosition(symbol, opBuy, _lot, SL, TP,trailingType, minProfit, trailingStop, trailingStep, priceDifference))
     {
      waitForBuy = false;
      waitForSell = false;
     }
    }
   } 

   if (waitForSell)
   { 
    if (LessDoubles(tick.bid, close_buf[0]) && LessDoubles(tick.bid, close_buf[1]))
    {
     if (ctm.OpenUniquePosition(symbol, opSell, _lot, SL, TP,trailingType, minProfit, trailingStop, trailingStep, priceDifference))
     {
      waitForBuy = false;
      waitForSell = false;
     }
    }
   }
  }
   

   return;   
  }


