//+------------------------------------------------------------------+
//|                                                      CondomA.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ������ ����������� ������� ��������� �                           |
//+------------------------------------------------------------------+

// ����������� ����������� ���������
#include <SystemLib/IndicatorManager.mqh>   // ���������� �� ������ � ������������
#include <CLog.mqh>                         // ��� ����
#include <Hvost/HvostBrain.mqh>
//#include <ChartObjects/ChartObjectsLines.mqh>      // ��� ��������� ����� �����������
#include <Chicken/ContainerBuffers.mqh>     // ��������� ������� ������

struct STradeTF
{
 bool used;
 ENUM_TIMEFRAMES period;
 STrailing trailing;
 CHvostBrain *hvostBrain;
};
STradeTF    tradeM5;
STradeTF    tradeM15;
STradeTF    tradeH1;
// ������� ��������� ������  
input double lot           = 1.0;    // ���   - ���������� �����, ����� �����������   
input bool   useTF_M5      = true;
input bool   useTF_M15     = true;
input bool   useTF_H1      = true;
int const    skipLastBar   = true; // ���������� ��������� ��� ��� ������� ������
// ����������
bool is_flat_now;            // ����, ������������, ���� �� ������ �� ������� ��� ��� 
int countBars;
int countTFs = 0;
int tradeSignal = 0;
// ���������� ��� �������� ������� �������� ����
datetime signal_time;        // ����� ��������� ������� �������� ����� ������ �� ���������� H
datetime open_pos_time;      // ����� �������� �������   
// ������� �������
CTradeManager *ctm;          // ������ ��������� ������
CContainerBuffers *conbuf;   // ��������� �������
// ��������� ������� � ���������
SPositionInfo pos_info;      // ��������� ���������� � �������
STrailing     trailing;      // ��������� ���������� � ���������
STradeTF tradeTF[3];         // ������ ��������� ��� �������� �� ������ �����������
int OnInit()
  {
   ENUM_TIMEFRAMES TFs[] = {PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4};
   conbuf = new CContainerBuffers(TFs);
   log_file.Write(LOG_DEBUG, "������� ��� �������");
   if(!useTF_M5 && !useTF_M15 && !useTF_H1)
   {
    PrintFormat("useTF_M5 = %b, useTF_M15 = %b, useTF_H1 = %b", useTF_M5, useTF_M15, useTF_H1);
    return(INIT_FAILED);
   }
   tradeM5.used    = useTF_M5;
   tradeM5.period  = PERIOD_M5;
   tradeM15.used   = useTF_M15;
   tradeM15.period = PERIOD_M15;
   tradeH1.used    = useTF_H1;
   tradeH1.period  = PERIOD_H1;
   tradeTF[0] = tradeM5;  // 0 - ������ ���������� �5
   tradeTF[1] = tradeM15; // 1 - ������ ���������� �15
   tradeTF[2] = tradeH1;  // 2 - ������ ���������� H1
   
   // ������� ������ ��������� ������ ��� �������� � �������� �������
   ctm = new CTradeManager();
   if (ctm == NULL)
   {
    log_file.Write(LOG_DEBUG, "�� ������� ������� ������ ������ CTradeManager");
    //Print("�� ������� ������� ������ ������ CTradeManager");
    return (INIT_FAILED);
   }  
   
   for(int i = 0; i < 3; i++)
   {
    if(tradeTF[i].used == true)
    {
     tradeTF[i].hvostBrain = new CHvostBrain( _Symbol, tradeTF[i].period, conbuf);
     if(tradeTF[i].hvostBrain == NULL)
     { 
      log_file.Write(LOG_DEBUG, "�� ������� ������� ������ ������ CHvostBrain");
      //Print("�� ������� ������� ������ ������ CHvostBrain");
      return (INIT_FAILED);
     } 
     tradeTF[i].trailing.trailingType = TRAILING_TYPE_NONE;
     //countTFs++;
    }
   } 
               
   // ��������� ���� �������
   pos_info.volume = lot;
   pos_info.expiration = 0;

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   Print("��� ������ = ",reason);
   // ������� �������
   for(int i = 0; i < 3 && tradeTF[i].used ; i++)
   {
    delete tradeTF[i].hvostBrain;
   }
   delete ctm;
  }

void OnTick()
  { 
   ctm.OnTick();
   if(conbuf.Update())
   {
    for(int i = 0; i < 3 && tradeTF[i].used; i++)
    {
     //PrintFormat("%s ��������� ��������� �� = %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(tradeTF[i].period));
     // ���� ������ ����� ��� �� ������� ��
     tradeSignal = tradeTF[i].hvostBrain.GetSignal();
     if(tradeSignal == SELL)
     {
      log_file.Write(LOG_DEBUG, "������� ������ SELL");
      Print(__FUNCTION__,"������� ������ SELL");
      // ��������� ���� ����, ���� ������ � ��������� ������� �� SELL
      pos_info.type = OP_SELL;
      pos_info.sl = CountStopLoss(-1, tradeTF[i].hvostBrain, tradeTF[i].period);       
      pos_info.tp = CountTakeProfit(-1, tradeTF[i].hvostBrain);
      pos_info.priceDifference = 0;     
      ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing);  
     
      // ��������� ����� �������� �������
      open_pos_time = TimeCurrent();  
     }
     if(tradeSignal == BUY)
     { 
      log_file.Write(LOG_DEBUG, "������� ������ BUY");
      Print(__FUNCTION__,"������� ������ BUY");
      // ��������� ���� ����, ���� ������ � ��������� ������� �� BUY
      pos_info.type = OP_BUY;
      pos_info.sl = CountStopLoss(1, tradeTF[i].hvostBrain, tradeTF[i].period);       
      pos_info.tp = CountTakeProfit(1, tradeTF[i].hvostBrain);           
      pos_info.priceDifference = 0;       
      ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
      // ��������� ����� �������� �������
      open_pos_time = TimeCurrent();   
     }  
     // ���� ��� �������� ������� �� ���������� ��� ������� �� ����
     if (ctm.GetPositionCount() == 0)
     {
      tradeTF[i].hvostBrain.SetOpenedPosition(0);   
     }
    }
   }
  }

   // ��������� ���� ����
int  CountStopLoss (int type, CHvostBrain *hvostBrain, ENUM_TIMEFRAMES period)
{
 int copied;
 double prices[];
 double price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
 double price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
 if (type == 1)
 {
  copied = CopyLow(_Symbol, period, 1, 2, prices);
  if (copied < 2)
  {
   log_file.Write(LOG_DEBUG, "�� ������� ����������� ����");
   Print("�� ������� ����������� ����");
   return (0);
  } 
  // ������ ���� ���� �� ������ ��������
  return ( int( (price_bid-prices[ArrayMinimum(prices)])/_Point) + 50 );   
 }
 if (type == -1)
 {
  copied = CopyHigh(_Symbol, period, 1, 2, prices);
  if (copied < 2)
  {
   log_file.Write(LOG_DEBUG, "�� ������� ����������� ����");
   Print("�� ������� ����������� ����");
   return (0);
  }
  // ������ ���� ���� �� ������ ���������
  return ( int( (prices[ArrayMaximum(prices)] - price_ask)/_Point) + 50 );
 }
 return (0);
}
  
// ��������� ���� ������
int CountTakeProfit (int type, CHvostBrain *hvostBrain)
{
 double price_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 double price_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 if (type == 1)
 {
  return ( int ( MathAbs(price_ask - hvostBrain.GetMaxChannelPrice())/_Point ) );  
 }
 if (type == -1)
 {
  return ( int ( MathAbs(price_bid - hvostBrain.GetMinChannelPrice())/_Point ) );    
 }
 return (0);
}
  
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---
   
}
//+------------------------------------------------------------------+
