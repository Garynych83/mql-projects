//+------------------------------------------------------------------+
//|                                                     Piercing.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <TradeManager/TradeManager.mqh>
#include <StringUtilities.mqh>
#include <Lib CisNewBar.mqh>

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
//input ulong _magic = 1122;
input double volume = 1;      // ����� ������
input int historyDepth = 20;  // ������� �������
input int step = 50;          // ��� ���������� ���������� � �������
input ENUM_TIMEFRAMES timeframe = PERIOD_M1; // ������
input bool trailing = false;  // �������� ��������  
input int minProfit = 250;    // ������� ����������� ������� ��� ��������� ������ � �������
input int trailingStop = 150; // 
input int trailingStep = 5;   // ��� ������

CTradeManager trade;

string symbol;              // ���������� ��� �������� �������
datetime history_start;     // ����� ������� ��������

MqlTick tick;
MqlTradeRequest request;
MqlTradeResult result;

int indexMax;
int indexMin;
double globalMax;
double globalMin;
bool waitForSell;
bool waitForBuy;

double high_buf[], low_buf[];
double sl, tp;
bool first;

int OrdersPrev = 0;        // ������ ���������� ������� �� ������ ����������� ������ OnTrade()
int PositionsPrev = 0;     // ������ ���������� ������� �� ������ ����������� ������ OnTrade()
ulong LastOrderTicket = 0; // ���������� ������ ����� ���������� ������������ � ��������� ������

int _GetLastError=0;       // �������� ��� ������
long state=0;              // ��� �������� ������� ������
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   history_start=TimeCurrent();     //--- �������� ����� ������� �������� ��� ��������� �������� �������
   
   waitForSell = false;
   waitForBuy = false;
   first = true;
   //������������� ���������� ��� �������� ���_buf
   ArraySetAsSeries(low_buf, true);
   ArraySetAsSeries(high_buf, true);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ArrayFree(low_buf);
   ArrayFree(high_buf);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   trade.OnTick();
   static CisNewBar isNewBar();
   //���������� ��� �������� ����������� ������ � ������� ��������
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   
   //�������� ������ �������� ������� � ������������ ������� ��� ���������� ������ � ����
   errLow=CopyLow(symbol, timeframe, 0, historyDepth, low_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
   errHigh=CopyHigh(symbol, timeframe, 0, historyDepth, high_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
             
   if(errLow < 0 || errHigh < 0)
   {
    Alert("�� ������� ����������� ������ �� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
    return;                                                                  //� ������� �� �������
   }
    
   indexMax = ArrayMaximum(high_buf, 1); // �������� �� �������������� �����
   indexMin = ArrayMinimum(low_buf, 1);  // ������� �� �������������� �����
   globalMax = high_buf[indexMax];       // �������� ���������
   globalMin = low_buf[indexMin];        // �������� ��������
   
   /*
   if (isNewBar.isNewBar())
   {
    PrintFormat("%s indexMax = %d, globalMax = %.05f, indexMin = %d, globalMin = %.05f", 
                MakeFunctionPrefix(__FUNCTION__), indexMax, globalMax, indexMin, globalMin);
   }*/
   
   if(!SymbolInfoTick(Symbol(),tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
    return;
   }
   
   if (indexMax > 3 && tick.bid > globalMax)
   {
    first = waitForBuy;
    waitForSell = true;
    waitForBuy = false;
    if (first)
    {
     first = !first;
     //Print("waitForSell");
    }
   }
   
   if (indexMin > 3 && tick.ask < globalMin)
   {
    first = waitForSell;
    waitForSell = false;
    waitForBuy = true;
    if (first)
    {
     first = !first;
     //Print("waitForSell");
    }
   }
   
   if (waitForSell && tick.ask < globalMax)
   {
    sl = NormalizeDouble(MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         high_buf[ArrayMaximum(high_buf, 0)] - tick.ask) / _Point, SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    tp = 0; 
    
    PrintFormat("%s ask+stopLvl= %.05f, high= %.05f, sl=%f", MakeFunctionPrefix(__FUNCTION__), tick.ask + SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point, high_buf[ArrayMaximum(high_buf, 0)], sl);
    if (trade.OpenPosition(symbol, OP_SELL, volume, sl, tp, 0.0, 0.0, 0.0))
    {
     PrintFormat("������� ������� ����");
     waitForSell = false;
    }
   }
   
   if (waitForBuy && tick.bid > globalMin)
   {
    sl = NormalizeDouble(MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         tick.bid - low_buf[ArrayMinimum(low_buf, 0)]) / _Point, SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    tp = 0; 
    PrintFormat("%s bid+stopLvl= %.05f, low= %.05f, sl=%f", MakeFunctionPrefix(__FUNCTION__), tick.bid - SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point, low_buf[ArrayMinimum(low_buf, 0)], sl);
    if (trade.OpenPosition(symbol, OP_BUY, volume, sl, tp, 0.0, 0.0, 0.0))
    {
     PrintFormat("������� ������� ���");
     waitForBuy = false;
    }
   }
   /*
   if (trailing)
   {
    trade.DoTrailing();
   } */
   return;  
  }
//+------------------------------------------------------------------+

void OnTrade()
{/*
//---
 //Alert("��������� ������� Trade");
 HistorySelect(history_start,TimeCurrent()); 
 
 if (OrdersPrev < OrdersTotal())
 {
  OrderGetTicket(OrdersTotal()-1);// �������� ��������� ����� ��� ������
  _GetLastError=GetLastError();
  Print("Error #",_GetLastError);ResetLastError();
  //--
  if (OrderGetInteger(ORDER_STATE) == ORDER_STATE_STARTED)
  {
   Alert(OrderGetTicket(OrdersTotal()-1),"�������� ����� � ���������");
   LastOrderTicket = OrderGetTicket(OrdersTotal()-1);    // ��������� ����� ������ ��� ���������� ������
  }
 }
 else if(OrdersPrev > OrdersTotal())
 {
  state = HistoryOrderGetInteger(LastOrderTicket, ORDER_STATE);

  // ���� ����� �� ������ ������ ������
  _GetLastError=GetLastError();
  if (_GetLastError != 0){Alert("������ �",_GetLastError," ����� �� ������!");LastOrderTicket = 0;}
  Print("Error #",_GetLastError," state: ",state);ResetLastError();

  // ���� ����� �������� ���������
  if (state == ORDER_STATE_FILLED)
  {
   double sl = MathMax(globalMax, high_buf[0]);
   trade.PositionModify(symbol, sl, 0.0);
  }
 }*/
}
