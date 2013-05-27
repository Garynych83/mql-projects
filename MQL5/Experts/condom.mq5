//+------------------------------------------------------------------+
//|                                                       condom.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh> //���������� ���������� ��� ���������� �������� ��������
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ulong _magic = 1122;
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
input int fastMACDPeriod = 12;
input int slowMACDPeriod = 26;
input int signalPeriod = 9;
input double levelMACD = 0.02;

string my_symbol;                               //���������� ��� �������� �������
ENUM_TIMEFRAMES my_timeframe;                   //���������� ��� �������� ����������
datetime history_start;

CTradeManager order(_magic);
MqlTick tick;

int handleMACD;
double MACD_buf[1], high_buf[], low_buf[], close_buf[2];

double globalMax;
double globalMin;
bool waitForSell;
bool waitForBuy;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   my_symbol=Symbol();                 //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   history_start=TimeCurrent();        //--- �������� ����� ������� �������� ��� ��������� �������� �������
      
   if (tradeOnTrend)
   {
    handleMACD = iMACD(my_symbol, my_timeframe, fastMACDPeriod, slowMACDPeriod, signalPeriod, PRICE_CLOSE);  //���������� ��������� � �������� ��� �����
    if(handleMACD == INVALID_HANDLE)                                  //��������� ������� ������ ����������
    {
     Print("�� ������� �������� ����� MACD");               //���� ����� �� �������, �� ������� ��������� � ��� �� ������
     return(-1);                                                  //��������� ������ � �������
    }
   }

   //������������� ���������� ��� �������� ���_buf
   ArraySetAsSeries(MACD_buf, false);
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);
   ArraySetAsSeries(close_buf, false);

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
   //���������� ��� �������� ����������� ������ � ������� ��������
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errMACD = 0;
   
   static CIsNewBar isNewBar;
   
   if(isNewBar.isNewBar(my_symbol, my_timeframe))
   {
    if (tradeOnTrend)
    {
     //�������� ������ �� ������������� ������� � ������������ ������ MACD_buf ��� ���������� ������ � ����
     errMACD=CopyBuffer(handleMACD, 0, 1, 1, MACD_buf);
     if(errMACD < 0)
     {
      Alert("�� ������� ����������� ������ �� ������������� ������"); 
      return; 
     }
    } 
    //�������� ������ �������� ������� � ������������ ������� ��� ���������� ������ � ����
    errLow=CopyLow(my_symbol, my_timeframe, 2, historyDepth, low_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
    errHigh=CopyHigh(my_symbol, my_timeframe, 2, historyDepth, high_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
    errClose=CopyClose(my_symbol, my_timeframe, 1, 2, close_buf); // (0 - ���. ���, �������� 2 �����. ����)
             
    if(errLow < 0 || errHigh < 0 || errClose < 0)                         //���� ���� ������
    {
     Alert("�� ������� ����������� ������ �� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
     return;                                                                  //� ������� �� �������
    }

    globalMax = high_buf[ArrayMaximum(high_buf)];
    globalMin = low_buf[ArrayMinimum(low_buf)];
    
    if(LessDoubles(close_buf[1], globalMin)) // ��������� Close(0 - ������, 1 - ������) ���� ����������� ��������
    {
     waitForSell = false;
     waitForBuy = true;
    }
    
    if(GreatDoubles(close_buf[1], globalMax)) // ��������� Close(0 - ������, 1 - ������) ���� ����������� ���������
    {
     waitForBuy = false;
     waitForSell = true;
    }
   }
   
   if (tradeOnTrend)
   {
    if (GreatDoubles(MACD_buf[0], levelMACD) || LessDoubles (MACD_buf[0], -levelMACD))
    {
     if (trailing)
     {
      order.DoTrailing();
     }
     return;
    }
   }
      
   if(!SymbolInfoTick(Symbol(),tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
   }
   else
   {
    //Alert(tick.time,": Bid = ",tick.bid," Ask = ",tick.ask,"  Volume = ",tick.volume);
   }
      
   if (waitForBuy)
   { 
    if (GreatDoubles(tick.ask, close_buf[0]) && GreatDoubles(tick.ask, close_buf[1]))
    {
     if (order.OpenPosition(my_symbol, POSITION_TYPE_BUY, _lot, SL, TP, minProfit, trailingStop, trailingStep))
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
     if (order.OpenPosition(my_symbol, POSITION_TYPE_SELL, _lot, SL, TP, minProfit, trailingStop, trailingStep))
     {
      waitForBuy = false;
      waitForSell = false;
     }
    }
   }
   
   if (trailing)
   {
    order.DoTrailing();
   }
   return;   
  }
//+------------------------------------------------------------------+

void OnTrade()
  {
   order.OnTrade(history_start);
  }

