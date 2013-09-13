//+------------------------------------------------------------------+
//|                                                    uniexpert.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManager.mqh>
#include <TradeBlocks/CrossEMA.mq5>
#include<Trigger64/PositionSys.mqh>     //���������� ���������� ��� ������ � ���������
#include<Trigger64/SymbolSys.mqh>       //���������� ���������� ��� ������ � ��������
#include<Trigger64/Graph.mqh>           //���������� ���������� ����������� ������
//+------------------------------------------------------------------+
//| ������������� �������                                            |
//+------------------------------------------------------------------+
input ENUM_MA_METHOD MA_METHOD=MODE_EMA;
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;
input int      TakeProfit=100;//take profit
input int      StopLoss=100; //stop loss
input double   orderVolume = 1;
input ulong    magic = 111222;
input uint SlowPer=26;
input uint FastPer=12;
string sym = _Symbol;
ENUM_TIMEFRAMES timeFrame = _Period; 
int takeProfit;
int stopLoss;

CTradeManager new_trade; //����� �������
CrossEMA  crossEMA;  //��������� ������ ������ CrossEMA

int OnInit()
  {
   new_trade.Initialization(); //������������� ��������� ���������
   stopLoss = StopLoss;
   takeProfit = TakeProfit;      
   return crossEMA.InitTradeBlock(sym,timeFrame,FastPer,SlowPer,MA_METHOD,applied_price);
  }

void OnDeinit(const int reason)
  {
   crossEMA.DeinitTradeBlock();
  }

void OnTick()
  {
   ENUM_TM_POSITION_TYPE signal;
   signal = crossEMA.GetSignal(); //�������� �������� ������
   if (signal != OP_UNKNOWN)      //���� ������ ������� �������
    new_trade.OpenPosition(sym,signal,orderVolume,stopLoss,takeProfit,0,0,0); //�� ��������� �������
  }

