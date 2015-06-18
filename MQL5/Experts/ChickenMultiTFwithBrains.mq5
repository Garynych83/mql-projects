//+------------------------------------------------------------------+
//|                                     ChickenMultiTFwithBrains.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <TradeManager/TradeManager.mqh>
#include <Chicken/ChickensBrain.mqh>                 // ������ �� ���������� �������� ��� ��������
#include <CLog.mqh>                                  // ��� ����
#include <ContainerBuffers.mqh>

//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input double  volume  = 0.1;        // ������ ����
input int     spread  = 30;         // ����������� ���������� ������ ������ � ������� �� �������� � ������� �������
input bool    use_tp  = false;      // ������������� takeProfit
input double   tp_ko  = 2;          // 
//input bool tradeTFM5  = true;       // ������������� �������� ��  �5
//input bool tradeTFM15 = true;       // ������������� �������� ��  M15
//input bool tradeTFH1  = true;       // ������������� �������� �� �1
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
/*
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
*/

CChickensBrain *chicken;   // chicken - �����, ������������ �������� �������� 
                           // � ������������ ������ �� �������� (SELL/BUY)
SPositionInfo pos_info;    // ��������� �������
STrailing     trailing;    // ��������� ���������

CArrayObj     *chickens;   // ������ �������� ��� ������� ��
CTradeManager *ctm;
CContainerBuffers *conbuf; // ����� ����������� �� ��������� ��, ����������� �� OnTick()
                           // highPrice[], lowPrice[], closePrice[] � �.�;
            
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 log_file.Write(LOG_DEBUG,"ChickenMultiTFwithBrains �������");
 ENUM_TIMEFRAMES TFs[] = {PERIOD_M5, PERIOD_M15, PERIOD_H1};
 conbuf = new CContainerBuffers(TFs);
 chickens = new CArrayObj();
 chickens.Add(new CChickensBrain(_Symbol, PERIOD_M5, conbuf));
 chickens.Add(new CChickensBrain(_Symbol, PERIOD_M15, conbuf));
 chickens.Add(new CChickensBrain(_Symbol, PERIOD_H1, conbuf));
 ctm = new CTradeManager();
     
   /*   
   tradeTF[i].trailing.trailingType = trailingType; //��������� ��� ��������� ��� i-��� ��
   tradeTF[i].trailing.handleForTrailing = handle;
   
   trailing.minProfit    = minProfit;
   trailing.trailingStop = trailingStop;
   trailing.trailingStep = trailingStep;*/
   
 //recountInterval = false;
 trailing.trailingType = TRAILING_TYPE_NONE;
 pos_info.volume = volume;
 pos_info.expiration = 0;

 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 chickens.Clear();
 delete chickens;
 delete ctm;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 int chickenSignal;
 double slPrice;
 double curAsk;
 double curBid;
 ctm.OnTick();
 ctm.DoTrailing();
 if(conbuf.Update()) // ���� ������� ���������� ������ �� ���� ����������� ��������� � ���������(BarsCalculated(handle)>0 )
 {
  for(int i = 0; i < chickens.Total(); i++)
  { 
   // ���� i-�� ��������� ������������, � �� �������, ��� �� ��-������ ������������
    chicken = chickens.At(i);
    long magic = ctm.MakeMagic(_Symbol, chicken.GetPeriod());// ������� ���������� ����� ��� ������� �� ��
    curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    chickenSignal = chicken.GetSignal();        // �������� ������ � ChickensBrain
    if(chickenSignal == SELL || chickenSignal == BUY)
    {
     if(chickenSignal == SELL)
     {// �������� ������� �� SELL
      log_file.Write(LOG_DEBUG, StringFormat("%s%s �������� ������ �� ������� SELL", SymbolInfoString(_Symbol,SYMBOL_DESCRIPTION),PeriodToString(chicken.GetPeriod())));
      pos_info.type = OP_SELLSTOP; 
      pos_info.sl =            chicken.GetDiffHigh();
      //trailing.minProfit = 2 * chicken.GetDiffHigh();
      //trailing.trailingStop =  chicken.GetDiffHigh();
     }
     if(chickenSignal == BUY)
     {// �������� ������� �� BUY
      log_file.Write(LOG_DEBUG, StringFormat("%s%s �������� ������ �� ������� BUY", SymbolInfoString(_Symbol,SYMBOL_DESCRIPTION),PeriodToString(chicken.GetPeriod())));
      pos_info.type = OP_BUYSTOP;
      pos_info.sl   =          chicken.GetDiffLow();
      //trailing.minProfit = 2 * chicken.GetDiffLow();
      //trailing.trailingStop =  chicken.GetDiffLow();
     }
     //stoplevel = MathMax(chicken.sl_min, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();   
     pos_info.tp = (use_tp) ? (int)MathCeil((chicken.GetHighBorder() - chicken.GetLowBorder())*0.75/Point()) : 0; // ����� �������� � ����������
     pos_info.magic = magic;
     pos_info.priceDifference = chicken.GetPriceDifference();
     pos_info.expiration = MathMax(DEPTH - chicken.GetIndexMax(), DEPTH - chicken.GetIndexMin());
     //trailing.trailingStep = 5;
     if (pos_info.tp == 0 || pos_info.tp > pos_info.sl * tp_ko) //���� tp �������� ����� ��������� �������
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s, tp = %d, sl = %d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl));
      ctm.OpenMultiPosition(_Symbol, _Period, pos_info, trailing, spread);
     }
    }
    if(chickenSignal == DISCORD) // ���� ������ ������ DISCORD ��������� ������� �������
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s%s �������� ������ DISCORD", SymbolInfoString(_Symbol,SYMBOL_DESCRIPTION), PeriodToString(chicken.GetPeriod())));
     ctm.ClosePendingPosition(_Symbol, magic);
    }
    else if(ctm.GetPositionCount() != 0) //���� ������� DISCORD �� ����, ������ �������� � ��������� ������� �� �������
    {
     ENUM_TM_POSITION_TYPE type = ctm.GetPositionType(_Symbol, magic);
     if(type == OP_SELLSTOP && ctm.GetPositionStopLoss(_Symbol, magic) < curAsk) 
     {
      slPrice = curAsk;
      ctm.ModifyPosition(_Symbol, magic, slPrice, 0);  
     }
     if(type == OP_BUYSTOP  && ctm.GetPositionStopLoss(_Symbol, magic) > curBid) 
     {
      slPrice = curBid;
      ctm.ModifyPosition(_Symbol, magic, slPrice, 0); 
     }
     if((type == OP_BUYSTOP || type == OP_SELLSTOP) && (pos_info.tp > 0 && pos_info.tp <= pos_info.sl * tp_ko))
     {
      log_file.Write(LOG_DEBUG, StringFormat("TP = %0.5f", pos_info.tp));
      log_file.Write(LOG_DEBUG, "pos_info.tp > 0 && pos_info.tp <= pos_info.sl * tp_ko");
      ctm.ClosePendingPosition(_Symbol, magic);
     } 
    } 
  }   
 } 
 else
 log_file.Write(LOG_DEBUG, StringFormat("%s conbuf.Update() �� ������� ", MakeFunctionPrefix(__FUNCTION__)));
} 
 //+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{

   
}
//+------------------------------------------------------------------+
