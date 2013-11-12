//+------------------------------------------------------------------+
//|                                            FollowWhiteRabbit.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

enum USE_PENDING_ORDERS //����� ���������� priceDifference
 { 
  USE_LIMIT_ORDERS=0, //������������ ����� ������
  USE_STOP_ORDERS,    //������������ ���� ������
  USE_NO_ORDERS       //�� ������������ �����������
 };
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <Trade\PositionInfo.mqh> //���������� ���������� ��� ��������� ���������� � ��������
#include <CompareDoubles.mqh>
#include <CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh>
#include <TradeManager\ReplayPosition.mqh>  
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input int SL = 150;
input double _lot = 1;
input int historyDepth = 40;
input double supremacyPercent = 0.2;
input double profitPercent = 0.5; 
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;
input bool trailing = false;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
input USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;           //��� ����������� ������                    
input int priceDifference = 50;                       // Price Difference
input bool replayPositions = true;
input int percentATRforReadyToReplay = 10;
input int percentATRforTrailing = 50;

string symbol;                                       //���������� ��� �������� �������
datetime history_start;

CTradeManager ctm;  //�������� �����
ReplayPosition *rp;        //����� �������� ��������� �������
MqlTick tick;

double takeProfit, stopLoss;
double high_buf[], low_buf[], close_buf[1], open_buf[1];
ENUM_TM_POSITION_TYPE opBuy, opSell, pos_type;
CPosition *pos;   //��������� �� �������

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   history_start=TimeCurrent();        //--- �������� ����� ������� �������� ��� ��������� �������� �������
   
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
   
   rp = new ReplayPosition(symbol, timeframe, percentATRforReadyToReplay, percentATRforTrailing);     
   //������������� ���������� ��� �������� ���_buf
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);
   ArraySetAsSeries(close_buf, false);
   ArraySetAsSeries(open_buf, false);
 
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete rp;
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
   if (replayPositions)
     rp.CustomPosition();
   //���������� ��� �������� ����������� ������ � ������� ��������
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errOpen = 0;

   
   double sum = 0;
   double avgBar = 0;
   double lastBar = 0;
   int i = 0;   // �������
   long positionType;

   static CIsNewBar isNewBar;
   
   if(isNewBar.isNewBar(symbol, timeframe))
   {
    //�������� ������ �������� ������� � ������������ ������� ��� ���������� ������ � ����
    errLow = CopyLow(symbol, timeframe, 1, historyDepth, low_buf);
    errHigh = CopyHigh(symbol, timeframe, 1, historyDepth, high_buf);
    errClose = CopyClose(symbol, timeframe, 1, 1, close_buf);          
    errOpen = CopyOpen(symbol, timeframe, 1, 1, open_buf);
    
    if(errLow < 0 || errHigh < 0 || errClose < 0 || errOpen < 0)         //���� ���� ������
    {
     Alert("�� ������� ����������� ������ �� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
     return;                                                                                      //� ������� �� �������
    }
    
    for(i = 0; i < historyDepth; i++)
    {
     sum = sum + high_buf[i] - low_buf[i];  
    }
    avgBar = sum / historyDepth;
    //lastBar = high_buf[i-1] - low_buf[i-1];
    lastBar = MathAbs(open_buf[0] - close_buf[0]);
    
    if(GreatDoubles(lastBar, avgBar*(1 + supremacyPercent)))
    {
     double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
     int digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
     double vol=MathPow(10.0, digits); 
     if(LessDoubles(close_buf[0], open_buf[0])) // �� ��������� ���� close < open (��� ����)
     {
      pos_type = opSell;
     }
     if(GreatDoubles(close_buf[0], open_buf[0]))
     {
      pos_type = opBuy;
     }
     takeProfit = NormalizeDouble(MathAbs(open_buf[0] - close_buf[0])*vol*(1 + profitPercent),0);
    
     ctm.OpenUniquePosition(symbol, pos_type, _lot, SL, takeProfit, minProfit, trailingStop, trailingStep, priceDifference);
    }
   }
   
   if (trailing)
   {
    ctm.DoTrailing();
   }
   return;   
  }
//+------------------------------------------------------------------+

void OnTrade()
  {
   ctm.OnTrade();
   rp.OnTrade();
   if (history_start != TimeCurrent())
   {
    rp.setArrayToReplay(ctm.GetPositionHistory(history_start));
    history_start = TimeCurrent() + 1;
   }
  }
