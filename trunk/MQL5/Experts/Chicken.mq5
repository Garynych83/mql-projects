//+------------------------------------------------------------------+
//|                                                      Chicken.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBarDD.mqh>
#include <TradeManager\TradeManager.mqh>

#define DEPTH 20
#define ALLOW_INTERVAL 16

// ��������� ��������
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0
//+------------------------------------------------------------------+
//| Expert parametrs                                                 |
//+------------------------------------------------------------------+
input double volume = 0.1;
input int    spread = 30;         // ����������� ���������� ������ ������ � ������� �� �������� � ������� �������
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
input bool use_tp = false;
input double tp_ko = 2;
/*
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
*/

CTradeManager ctm;       //�������� �����
CisNewBar *isNewBar;
SPositionInfo pos_info;
STrailing trailing;

int handle_pbi;
double buffer_pbi[];
double buffer_high[];
double buffer_low[];

double highPrice[], lowPrice[], closePrice[];
bool recountInterval;
int  tmpLastBar;
int  lastTrend = 0;            // ��� ���������� ������ �� PBI 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 isNewBar = new CisNewBar(_Symbol, _Period);
 handle_pbi = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 if ( handle_pbi == INVALID_HANDLE )
 {
  Print("������ ��� ����������� ��������. �� ������� ������� ����� ���������� PriceBasedIndicator");
  return (INIT_FAILED);
 } 
 recountInterval = false;
 
 pos_info.volume = volume;
 pos_info.expiration = 0;
 
 trailing.trailingType = trailingType;
 /*
 trailing.minProfit    = minProfit;
 trailing.trailingStop = trailingStop;
 trailing.trailingStep = trailingStep;
 */
 trailing.handleForTrailing = handle_pbi;
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 IndicatorRelease(handle_pbi);
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
 int diff_high, diff_low, sl_min, tp;
 double slPrice;
 double highBorder, lowBorder;
 double stoplevel;
 static int index_max = -1;
 static int index_min = -1;
 double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 if(isNewBar.isNewBar() || recountInterval)
 {
  ArraySetAsSeries(buffer_high, false);
  ArraySetAsSeries(buffer_low, false);
  if(CopyClose(_Symbol, _Period, 1, 1, closePrice)     < 1 ||      // ���� �������� ���������� ��������������� ����
     CopyHigh(_Symbol, _Period, 1, DEPTH, buffer_high) < DEPTH ||  // ����� ������������ ��� ���� �������������� ����� �� ������� �������
     CopyLow(_Symbol, _Period, 1, DEPTH, buffer_low)   < DEPTH ||  // ����� ����������� ��� ���� �������������� ����� �� ������� �������
     CopyBuffer(handle_pbi, 4, 0, 1, buffer_pbi)       < 1)        // ��������� ���������� ��������
  {
   index_max = -1;
   index_min = -1;  // ���� �� ���������� ��������� ��������� �� ����� ��������� ������
   recountInterval = true;
  }
  index_max = ArrayMaximum(buffer_high, 0, DEPTH - 1);
  index_min = ArrayMinimum(buffer_low, 0, DEPTH - 1);
  recountInterval = false;
  
  tmpLastBar = GetLastMoveType(handle_pbi);
  if (tmpLastBar != 0)
  {
   lastTrend = tmpLastBar;
  }
  
  if (buffer_pbi[0] == MOVE_TYPE_FLAT && index_max != -1 && index_min != -1)
  {
   highBorder = buffer_high[index_max];
   lowBorder = buffer_low[index_min];
   sl_min = MathMax((int)MathCeil((highBorder - lowBorder)*0.10/Point()), 50);
   tp = (use_tp) ? (int)MathCeil((highBorder - lowBorder)*0.75/Point()) : 0;
   diff_high = (buffer_high[DEPTH - 1] - highBorder)/Point();
   diff_low = (lowBorder - buffer_low[DEPTH - 1])/Point();
   stoplevel = MathMax(sl_min, SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
 
   pos_info.tp = 0;
   
   if(index_max < ALLOW_INTERVAL && GreatDoubles(closePrice[0], highBorder) && diff_high > sl_min && lastTrend == SELL)
   { 
    PrintFormat("���� �������� ������� ���� �������� = %s, ����� = %s, ���� = %.05f, sl_min = %d, diff_high = %d",
          DoubleToString(highBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          sl_min, diff_high);
    pos_info.type = OP_SELLSTOP;
    pos_info.sl = diff_high;
    pos_info.tp = tp;
    pos_info.priceDifference = (closePrice[0] - highBorder)/Point();
    pos_info.expiration = MathMax(DEPTH - index_max, DEPTH - index_min);
    trailing.minProfit = 2*diff_high;
    trailing.trailingStop = diff_high;
    trailing.trailingStep = 5;
    if (pos_info.tp == 0 || pos_info.tp > pos_info.sl*tp_ko)
    {
     PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
     ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
    }
   }
    
   if(index_min < ALLOW_INTERVAL && LessDoubles(closePrice[0], lowBorder) && diff_low > sl_min && lastTrend == BUY)
   {
    PrintFormat("���� �������� ������� ���� ������� = %s, ����� = %s, ���� = %.05f, sl_min = %d, diff_low = %d",
          DoubleToString(lowBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          sl_min, diff_low);
             
    pos_info.type = OP_BUYSTOP;
    pos_info.sl = diff_low;
    pos_info.tp = tp;
    pos_info.priceDifference = (lowBorder - closePrice[0])/Point();
    pos_info.expiration = MathMax(DEPTH - index_max, DEPTH - index_min);
    trailing.minProfit = 2*diff_low;
    trailing.trailingStop = diff_low;
    trailing.trailingStep = 5;
    if (pos_info.tp == 0 || pos_info.tp > pos_info.sl*tp_ko)
    {
     PrintFormat("%s, tp=%d, sl=%d", MakeFunctionPrefix(__FUNCTION__), pos_info.tp, pos_info.sl);
     ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
    }
   }
   
   if(ctm.GetPositionCount() != 0)
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
  else
  {
   ctm.ClosePendingPosition(_Symbol);
  }
 }
}
//+------------------------------------------------------------------+

int GetLastTrendDirection (int handle, ENUM_TIMEFRAMES period)   // ���������� true, ���� ��������� �� ������������ ���������� ������ �� ������� ����������
{
 int copiedPBI=-1;     // ���������� ������������� ������ PriceBasedIndicator
 int signTrend=-1;     // ���������� ��� �������� ����� ���������� ������
 int index=1;          // ������ ����
 int nBars;            // ���������� �����
 
 ArraySetAsSeries(buffer_pbi, true);
 
 nBars = Bars(_Symbol,period);
 
 for (int attempts = 0; attempts < 5; attempts++)
 {
  copiedPBI = CopyBuffer(handle, 4, 1, nBars - 1, buffer_pbi);
  Sleep(100);
 }
 if (copiedPBI < (nBars-1))
 {
 // Comment("�� ������� ����������� ��� ����");
  return (0);
 }
 
 for (index = 0; index < nBars - 1; index++)
 {
  signTrend = int(buffer_pbi[index]);
  // ���� ������ ��������� ����� �����
  if (signTrend == 1 || signTrend == 2)
   return (1);
  // ���� ������ ��������� ����� ����
  if (signTrend == 3 || signTrend == 4)
   return (-1);
 }
 return (0);
}

int  GetLastMoveType (int handle) // �������� ��������� �������� PriceBasedIndicator
{
 int copiedPBI;
 int signTrend;
 copiedPBI = CopyBuffer(handle, 4, 1, 1, buffer_pbi);
 if (copiedPBI < 1)
  return (0);
 signTrend = int(buffer_pbi[0]);
 // ���� ����� �����
 if (signTrend == 1 || signTrend == 2)
  return (1);
 // ���� ����� ����
 if (signTrend == 3 || signTrend == 4)
  return (-1);
 return (0);
}