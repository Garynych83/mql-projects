//+------------------------------------------------------------------+
//|                                                         TEST.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <DrawExtremums\CExtrContainer.mqh>
#include <TradeManager\TradeManager.mqh>             // �������� ����������
#include <Chicken\ChickensBrain.mqh>                 // ������ �� ���������� �������� ��� ��������
#include <SystemLib/IndicatorManager.mqh>            // ���������� �� ������ � ������������


// ������: �������� ������, ��������� ������� �� ����� ����� [auto trading disabled by client]
//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input double volume = 0.1;
input int    spread = 30;         // ����������� ���������� ������ ������ � ������� �� �������� � ������� �������
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
input bool use_tp = false;
input double tp_ko = 2;

int handle_pbi;
bool closePosition;
CTradeManager ctm;       //�������� �����
CisNewBar *newBar;
SPositionInfo pos_info;
STrailing trailing;
CChickensBrain *chicken;
double buffer_high[];
double buffer_low[];
double closePrice[];

int OnInit()
{
 newBar = new CisNewBar();
 newBar.isNewBar();
 handle_pbi = DoesIndicatorExist(_Symbol,_Period,"PriceBasedIndicator");
 if (handle_pbi == INVALID_HANDLE)
 {
  handle_pbi = iCustom(_Symbol, _Period, "PriceBasedIndicator");
  if (handle_pbi == INVALID_HANDLE)
  {
   Print("�� ������� ������� ����� ���������� PriceBasedIndicator");
   return (INIT_FAILED);
  }
  SetIndicatorByHandle(_Symbol,_Period,handle_pbi);
 }  
 chicken = new CChickensBrain(_Symbol,_Period,handle_pbi, use_tp);
 pos_info.volume = volume;
 pos_info.expiration = 0;
 trailing.trailingType = trailingType;
 trailing.handleForTrailing = handle_pbi;
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete chicken;
 ArrayFree(buffer_high);
 ArrayFree(buffer_low);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{ 
 ctm.OnTick();
 ctm.DoTrailing();
 MqlDateTime timeCurrent;
 double slPrice;
 double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 ArraySetAsSeries(buffer_high, false);
 ArraySetAsSeries(buffer_low, false);
 closePosition = true;
  switch(chicken.GetSignal())
  {
  case SELL:
   Print("�������� ������ �� ������� SELL");
   pos_info.type = OP_SELLSTOP;
   pos_info.sl = chicken.diff_high;
   pos_info.tp = chicken.tp;
   pos_info.priceDifference = chicken.priceDifference;
   pos_info.expiration = MathMax(DEPTH - chicken.index_max, DEPTH - chicken.index_min);
   trailing.minProfit = 2*chicken.diff_high;
   trailing.trailingStop = chicken.diff_high;
   trailing.trailingStep = 5;
   if (pos_info.tp == 0 || pos_info.tp > pos_info.sl*tp_ko)
   {
    PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
   }
  break;
  case BUY:
   Print("�������� ������ �� ������� BUY");
   pos_info.type = OP_BUYSTOP;
   pos_info.sl   = chicken.diff_low;
   pos_info.tp   = chicken.tp;
   pos_info.priceDifference = chicken.priceDifference;
   pos_info.expiration = MathMax(DEPTH - chicken.index_max, DEPTH - chicken.index_min);
   trailing.minProfit = 2 * chicken.diff_low;
   trailing.trailingStop = chicken.diff_low;
   trailing.trailingStep = 5;
   if (pos_info.tp == 0 || pos_info.tp > pos_info.sl * tp_ko)
   {
    PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
   }
  break;
  case NO_POSITION:
   Print("�������� ������ NO_POSITION");
   ctm.ClosePendingPosition(_Symbol);
   closePosition = false;
  break;
  case NO_ENTER:
   closePosition = false;
  break;
 }
 if(closePosition && ctm.GetPositionCount() != 0)
 {
  ENUM_TM_POSITION_TYPE type = ctm.GetPositionType(_Symbol);
  if(type == OP_SELLSTOP && ctm.GetPositionStopLoss(_Symbol) < curAsk) 
  {
   slPrice = curAsk;
   ctm.ModifyPosition(_Symbol, slPrice, 0);  
  }
  if(type == OP_BUYSTOP  && ctm.GetPositionStopLoss(_Symbol) > curBid) 
  {
   slPrice = curBid;
   ctm.ModifyPosition(_Symbol, slPrice, 0); 
  }
  if((type == OP_BUYSTOP || type == OP_SELLSTOP) && (pos_info.tp >0 && pos_info.tp <= pos_info.sl*tp_ko))
  {
   ctm.ClosePendingPosition(_Symbol);
  } 
 } 
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
/*void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{

}*/
//+------------------------------------------------------------------+
