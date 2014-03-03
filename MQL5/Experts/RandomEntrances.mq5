//+------------------------------------------------------------------+
//|                                              RandomEntrances.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <TradeManager\TradeManager.mqh> //���������� ���������� ��� ���������� �������� ��������

input int step = 100;
input int countSteps = 4;

input bool allatonce = false;  // ����������� ����� 5 �����
input bool stepbystep = true;  // ����� ������� ������
input bool degradelot = false; // ����� ������. ������ 
input bool upgradelot = false; // ����� ������. ������
//input bool stepbypart = false; // 

string symbol;
int count;
double rnd;
ENUM_TM_POSITION_TYPE opBuy, opSell;
double lot;
int profit;
CTradeManager ctm();
double aDeg[4] = {0.7, 0.5, 0.3, 0.1};
double aUpg[4] = {0.1, 0.3, 0.5, 0.7};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   MathSrand(TimeLocal());
   count = 0;
   //history_start=TimeCurrent();     //--- �������� ����� ������� �������� ��� ��������� �������� �������
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ctm.OnTick();
   if (ctm.GetPositionCount() == 0)
   {
    if (allatonce) lot = 5;
    if (stepbystep || degradelot) lot = 1;
    if (upgradelot) lot = 0.1;
    count = 0;
    rnd = (double)MathRand()/32767;
    ENUM_TM_POSITION_TYPE operation = GreatDoubles(rnd, 0.5, 5) ? 1 : 0;
    ctm.OpenUniquePosition(symbol, operation, lot, step, 0, step, step, step);
   }
   
   if (ctm.GetPositionCount() > 0)
   {
    profit = ctm.GetPositionPointsProfit(symbol);
    if (stepbystep)
    {
     if (profit > step && count < countSteps) 
     {
      ctm.PositionChangeSize(symbol, 1);
      count++;
     }
    }
    if (degradelot) 
    {
     if (profit > step && count < countSteps) 
     {
      ctm.PositionChangeSize(symbol, aDeg[count]);
      count++;
     }
    }
    if (upgradelot) 
    {
     if (profit > step && count < countSteps) 
     {
      ctm.PositionChangeSize(symbol, aUpg[count]);
      count++;
     }
    }
    ctm.DoUsualTrailing();
   }
  }
//+------------------------------------------------------------------+
