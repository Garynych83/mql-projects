//+------------------------------------------------------------------+
//|                                                    uniexpert.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManager.mqh>
//����������� �������� ������
#include <TradeBlocks/CrossEMA.mq5>
#include <TradeBlocks/FollowWhiteRabbit.mq5>  
#include <TradeBlocks/Condom.mq5>
//���������� ������������ �������� ������
#include <TradeBlocks/TradeBlocksEnums.mqh>
//+------------------------------------------------------------------+
//| ������������� �������                                            |
//+------------------------------------------------------------------+
//�������� ��������� �����

enum USE_PENDING_ORDERS //����� ���������� priceDifference
 { 
  USE_LIMIT_ORDERS=0, //useLimitOrders = true
  USE_STOP_ORDERS,    //useStopOrders = true
  USE_NO_ORDERS       //��� ����� false
 };

input TRADE_BLOCKS_TYPE TRADE_BLOCK = TB_RABBIT;    //�������� ���������
//����� ���������
sinput string main;                                   //������� ���������

input int      TakeProfit=500;                        //take profit
input int      StopLoss=150;                          //stop loss
input double   _lot = 1;                              //������ ����
input int historyDepth = 40;                          //������� �������
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;          //���������
input bool trailing = false;                          //��������
input int minProfit = 250;                            //����������� ������
input int trailingStop = 150;                         //�������� ����
input int trailingStep = 5;                           //��� ���������
input USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;           //��� Price Difference                    
input int priceDifference = 50;                       // Price Difference

sinput string ema_param;                              //��������� CrossEMA

input ENUM_MA_METHOD MA_METHOD=MODE_EMA;              //����� EMA
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;   //����������� ����
input uint SlowPer=26;                                //������ ��������� EMA     
input uint FastPer=12;                                //������ ������� EMA

sinput string rabbit_param;                           //��������� �������

input double supremacyPercent = 0.2;                  // �� ������� ��� ����� ��� ������ �������� 
input double profitPercent = 0.5;                     // ������� ��������� �� �������� ����� ��������

sinput string condom_param;                           //��������� Condom

input bool tradeOnTrend = false;                      //�������� �� ������

string sym;
datetime history_start;
//int takeProfit;
int stopLoss;
ENUM_TM_POSITION_TYPE op_buy,op_sell; //�������� �������
ENUM_TM_POSITION_TYPE signal=OP_UNKNOWN; //�������� �������
double take_profit;

CTradeManager ctm();    //����� �������� ��������

CrossEMA  cross_ema;  //��������� ������ ������ CrossEMA
FWRabbit  rabbit;     //��������� ������ ������ FWRabbit
Condom    condom;     //��������� ������ ������ Condom

int OnInit()
  {
   sym=Symbol();                 //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   history_start=TimeCurrent();        //--- �������� ����� ������� �������� ��� ��������� �������� �������
   ctm.Initialization();  //�������������� �������� ����������
   stopLoss = StopLoss;
 //  takeProfit = TakeProfit;   
   
   switch (pending_orders_type)  //���������� priceDifference
    {
     case USE_LIMIT_ORDERS: //useLimitsOrders = true;
      op_buy  = OP_BUYLIMIT;
      op_sell = OP_SELLLIMIT;
     break;
     case USE_STOP_ORDERS:
      op_buy  = OP_BUYSTOP;
      op_sell = OP_SELLSTOP;
     break;
     case USE_NO_ORDERS:
      op_buy  = OP_BUY;
      op_sell = OP_SELL;      
     break;
    }
             
   switch (TRADE_BLOCK)  //����� 
   {
     case TB_CROSSEMA:
      return cross_ema.InitTradeBlock(sym,
                                      timeframe,
                                      FastPer,
                                      SlowPer,
                                      MA_METHOD,
                                      applied_price);  //�������������� �������� ���� CrossEMA
     break;
     case TB_RABBIT:
      return rabbit.InitTradeBlock(sym,
                                   timeframe,
                                   supremacyPercent,
                                   profitPercent,
                                   historyDepth);  //�������������� �������� ���� �������
     break;
     case TB_CONDOM:     
      return condom.InitTradeBlock(sym,
                                   timeframe,
                                   tradeOnTrend,
                                   historyDepth); //�������������� �������� ���� �������
                                   
     break;
   }                           
    return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ctm.Deinitialization();
   cross_ema.DeinitTradeBlock();
   rabbit.DeinitTradeBlock();   
   condom.DeinitTradeBlock();
  }

void OnTick()
 {   
  ctm.OnTick();
   
  switch (TRADE_BLOCK)
  {
   //����� �������� ���������
   case TB_CROSSEMA: //����������� EMA
    signal = cross_ema.GetSignal(false);//�������� �������� ������
    take_profit = TakeProfit;
   break;
   case TB_CONDOM:   //������
    signal = condom.GetSignal(false); //�������� �������� ������ 
    take_profit = condom.GetTakeProfit();         
   break;
   case TB_RABBIT:   //������
    signal = rabbit.GetSignal(false); //�������� �������� ������   
    take_profit = rabbit.GetTakeProfit();      
   break; 
  }
  
  switch (signal)
  {
   case 1: //������ buy
    ctm.OpenPosition(sym,op_buy,_lot,stopLoss,take_profit,minProfit, trailingStop, trailingStep,priceDifference); //�� ��������� ������� �� �������
   break;
   case 2://������ sell
    ctm.OpenPosition(sym,op_sell,_lot,stopLoss,take_profit,minProfit, trailingStop, trailingStep,priceDifference); //�� ��������� ������� �� �������
   break;
  }
       
  if (trailing)
   {
    ctm.DoTrailing();
   } 
  }

void OnTrade()
  {
   ctm.OnTrade(history_start);
  }
  
