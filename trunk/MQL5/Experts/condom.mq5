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
#include <Trade\Trade.mqh> //���������� ���������� ��� ���������� �������� ��������
#include <Trade\PositionInfo.mqh> //���������� ���������� ��� ��������� ���������� � ��������
#include <CompareDoubles.mqh>
#include <CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh>
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

CTradeManager order(_magic, timeframe, minProfit, trailingStop, trailingStep);
//CTradingManager order();
MqlTick tick;

int handleMACD;
double MACD_buf[1], high_buf[], low_buf[], close_buf[2];

double globalMax;
double globalMin;
bool waitForSell;
bool waitForBuy;
long positionType;
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
   positionType = -1;
   
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
     //Print("MACD_buf[0] = ", MACD_buf[0]); 
     if(errMACD < 0)
     {
      Alert("�� ������� ����������� ������ �� ������������� ������"); 
      return; 
     }
    } 
    //�������� ������ �������� ������� � ������������ ������� ��� ���������� ������ � ����
    errLow=CopyLow(my_symbol, my_timeframe, 2, historyDepth, low_buf);
    errHigh=CopyHigh(my_symbol, my_timeframe, 2, historyDepth, high_buf);
    errClose=CopyClose(my_symbol, my_timeframe, 1, 2, close_buf);
             
    if(errLow < 0 || errHigh < 0 || errClose < 0)                                            //���� ���� ������
    {
     Alert("�� ������� ����������� ������ �� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
     return;                                                                                      //� ������� �� �������
    }
    
    globalMax = high_buf[ArrayMaximum(high_buf)];
    globalMin = low_buf[ArrayMinimum(low_buf)];
    //Alert("max = ", globalMax, " min= ", globalMin, " close_buf[0] = ", close_buf[0], " close_buf[1]= ", close_buf[1]);
    
    if(close_buf[1] < globalMin)
    {
     waitForSell = false;
     waitForBuy = true;
     Alert("WTB. close_buf=",close_buf[1]," < globalMin=",globalMin);
    }
    
    if(close_buf[1] > globalMax)
    {
     waitForBuy = false;
     waitForSell = true;
     Alert("WTS. close_buf=",close_buf[1]," > globalMax=",globalMax);
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
   
   if(PositionSelect(my_symbol))
   {
    positionType = PositionGetInteger(POSITION_TYPE);
   }
   else
   {
    positionType = -1;
   }
   
   if (waitForBuy)
   { 
    if (tick.ask > close_buf[0] && tick.ask > close_buf[1])
    {
     order.OpenPosition(my_symbol, POSITION_TYPE_BUY, _lot, SL, TP, minProfit, trailingStop, trailingStep);
     waitForBuy = false;
     waitForSell = false;
    }
   } 

   if (waitForSell)
   { 
    if (tick.bid < close_buf[0] && tick.bid < close_buf[1])
    {
     order.OpenPosition(my_symbol, POSITION_TYPE_SELL, _lot, SL, TP, minProfit, trailingStop, trailingStep);
     waitForBuy = false;
     waitForSell = false;
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

