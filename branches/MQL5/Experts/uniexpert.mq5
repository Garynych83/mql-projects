//+------------------------------------------------------------------+
//|                                                    uniexpert.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManager.mqh>
#include<Trigger64/PositionSys.mqh>     //���������� ���������� ��� ������ � ���������
#include<Trigger64/SymbolSys.mqh>       //���������� ���������� ��� ������ � ��������
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

enum USE_PRICE_DIFFERENCE //����� ���������� priceDifference
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
input double supremacyPercent = 0.2;
input double profitPercent = 0.5;  
input ENUM_TIMEFRAMES timeframe = PERIOD_M1;          //���������
input bool trailing = false;                          //��������
input int minProfit = 250;                            //����������� ������
input int trailingStop = 150;                         //�������� ����
input int trailingStep = 5;                           //��� ���������
input USE_PRICE_DIFFERENCE pride_diff_type = USE_LIMIT_ORDERS;           //��� Price Difference                    
input int limitPriceDifference = 50;                  //Limit Price Difference
input int stopPriceDifference = 50;                   //Stop Price Difference

sinput string ema_param;                              //��������� CrossEMA

input ENUM_MA_METHOD MA_METHOD=MODE_EMA;              //����� EMA
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;   //����������� ����
input uint SlowPer=26;                                //������ ��������� EMA     
input uint FastPer=12;                                //������ ������� EMA

sinput string macd_param;                             //��������� Price Based Indicator

input bool tradeOnTrend = false;                      //�������� �� ������



string sym;
datetime history_start;
//int takeProfit;
int stopLoss;
ENUM_TM_POSITION_TYPE op_buy,op_sell; //�������� �������
ENUM_TM_POSITION_TYPE signal=OP_UNKNOWN; //�������� �������
int priceDifference; 
double take_profit;

CTradeManager ctm(false);    //����� �������� ��������

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
   
   switch (pride_diff_type)  //���������� priceDifference
    {
     case USE_LIMIT_ORDERS: //useLimitsOrders = true;
      op_buy  = OP_BUYLIMIT;
      op_sell = OP_SELLLIMIT;
      priceDifference = limitPriceDifference;
     break;
     case USE_STOP_ORDERS:
      op_buy  = OP_BUYSTOP;
      op_sell = OP_SELLSTOP;
      priceDifference = stopPriceDifference;     
     break;
     case USE_NO_ORDERS:
      op_buy  = OP_BUY;
      op_sell = OP_SELL;      
      priceDifference = 0;
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
    return 1;
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
     take_profit = cross_ema.GetTakeProfit();
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
    case OP_BUY:
     ctm.OpenPosition(sym,op_buy,_lot,stopLoss,take_profit,minProfit, trailingStop, trailingStep,priceDifference); //�� ��������� ������� �� �������
    break;
    case OP_SELL:   
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
  
