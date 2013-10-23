//+------------------------------------------------------------------+
//|                                               ReplayPosition.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "TradeManagerEnums.mqh"
#include "PositionOnPendingOrders.mqh"
#include "PositionArray.mqh"
#include "TradeManager.mqh"
#include <Arrays/ArrayLong.mqh>

//+------------------------------------------------------------------+
//| �����-��������� ��� �������� � ������ � ���������                |
//+------------------------------------------------------------------+
class ReplayPosition
{ 
 private:
  CTradeManager ctm;  //�������� ����� 
  CPositionArray aPositionsToReplay;         // ������ ��������� ������� �� �������
  CArrayLong aReplayingPositionsDT;  // ������ ������� ��� �������� ��������� �������
  
  int ATR_handle, errATR;
  double ATR_buf[];
  double _ATRforReplay, _ATRforTrailing;
  
  datetime prevDate;  // ���� ���������� ��������� �������
 public: 
  void ReplayPosition(string symbol, ENUM_TIMEFRAMES period, int ATRforReplay, int ATRforTrailing);
  void ~ReplayPosition();
  
  void OnTrade();
  void setArrayToReplay(CPositionArray *array);
  void CustomPosition ();   //��������� �� ������� � �������� ������� ������� ���������� ������ �������    
};
//+------------------------------------------------------------------+
//| �����������                                                      |
//+------------------------------------------------------------------+
void ReplayPosition::ReplayPosition(string symbol, ENUM_TIMEFRAMES period, int ATRforReplay, int ATRforTrailing)
                    : _ATRforReplay(ATRforReplay/100), _ATRforTrailing(ATRforTrailing/100)
{
 ATR_handle = iATR(symbol, period, 100);
 if(ATR_handle == INVALID_HANDLE)                                  //��������� ������� ������ ����������
 {
  Print("�� ������� �������� ����� ATR");               //���� ����� �� �������, �� ������� ��������� � ��� �� ������
 }
}

//+------------------------------------------------------------------+
//| ����������                                                       |
//+------------------------------------------------------------------+
void ReplayPosition::~ReplayPosition(void)
{
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReplayPosition::OnTrade()
{
 Print("total=", aPositionsToReplay.Total());
 ctm.OnTrade();
 CPositionArray *array;
 CPosition *posFromHistory, *posToReplay;
 array = ctm.GetPositionHistory(prevDate);
 prevDate = TimeCurrent();
 
 setArrayToReplay(array);
 int totalReplayed = array.Total();
 int totalOnReplaying = aReplayingPositionsDT.Total();
 int index;
 
 for (int i = 0; i < totalReplayed; i++)
 {
  posFromHistory = new CPosition(array.At(i));
  index = 0;
  while (index < totalOnReplaying && posFromHistory.getOpenPosDT() != aReplayingPositionsDT[index])
  {
   index++;
  }
  
  if (posFromHistory.getPosProfit() > 0)
  {
   aPositionsToReplay.Delete(index);
   aReplayingPositionsDT.Delete(index);
  } 

  if (posFromHistory.getPosProfit() < 0)
  {
   posToReplay = aPositionsToReplay.At(index);
   posToReplay.setPositionStatus(POSITION_STATUS_READY_TO_REPLAY);
   aReplayingPositionsDT.Update(index, 0);
  }
 }
}
//+------------------------------------------------------------------+
//| ��������� ������ ��� �������� �� �������� �������                |
//+------------------------------------------------------------------+
void ReplayPosition::setArrayToReplay(CPositionArray *array)
{
 Print("��������� ������ �� ������� total=", array.Total());
 int total, size;
 int n = array.Total();
 CPosition *pos;
 for(int i = 0; i < n; i++)
 {
  pos = new CPosition(array.At(i));
  if (pos.getPosProfit() < 0)
  {
   pos.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
   aPositionsToReplay.Add(pos);
   aReplayingPositionsDT.Add(0);
  }
 }
}
//+------------------------------------------------------------------+
//| ��������� �� ������� ������� � ���������\������ �������          |
//+------------------------------------------------------------------+
void ReplayPosition::CustomPosition()
{
 ctm.OnTick();
 int direction = 0;
 int index;
 uint total = aPositionsToReplay.Total();        //������� ����� �������
 string symbol;
 double curPrice, profit, openPrice, closePrice;
 int sl, tp;
 CPosition *pos;                                 //��������� �� ������� 

 errATR = CopyBuffer(ATR_handle, 0, 1, 1, ATR_buf);
 if(errATR < 0)
 {
  Alert("�� ������� ����������� ������ �� ������������� ������"); 
  return; 
 }

 for (index = total - 1; index >= 0; index--)    //��������� �� ������� �������
 {
  pos = aPositionsToReplay.At(index);

  symbol = pos.getSymbol();
  profit = MathAbs(pos.getPosProfit());
  openPrice = pos.getPriceOpen();
  closePrice = pos.getPriceClose();
  
  if (pos.getType() == OP_BUY)
  {
   direction = 1;
   curPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
  }
  if (pos.getType() == OP_SELL)
  {
   direction = -1;
   curPrice = SymbolInfoDouble(symbol, SYMBOL_BID);         
  }
  if (pos.getPositionStatus() == POSITION_STATUS_MUST_BE_REPLAYED)  //���� ������� ������� �������� �� ����� � Loss
  {
   //���� ���� ���������� �� Loss
   if (direction*(closePrice - curPrice) > profit || direction*(closePrice - curPrice) > ATR_buf[0]*_ATRforReplay)
   {
    PrintFormat("������� %d ���������� � ����� ���������� � ��������, type=%s, direction=%d, profit=%.05f, close=%.05f, current=%.05f"
                , index, GetNameOP(pos.getType()), direction, profit, closePrice, curPrice);
    pos.setPositionStatus(POSITION_STATUS_READY_TO_REPLAY);  //��������� ������� � ����� ���������� � ��������
   } 
  }
  else
  {
   if ((pos.getPositionStatus() == POSITION_STATUS_READY_TO_REPLAY)
      && (direction*(curPrice - closePrice) >= 0))//���� ������� ������ � �������� � ���� ���������� �� ���� ���� �������� �������
   {
    tp = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL), (profit/_Point));
    sl = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL), (profit/_Point));
    int trailParam = ATR_buf[0]*_ATRforTrailing/_Point;
    ctm.OpenMultiPosition(symbol, pos.getType(), pos.getVolume(), sl, tp, trailParam, trailParam, trailParam); //��������� �������
    PrintFormat("������� ������� ��� �������� profit=%.05f, sl=%d, tp=%d",NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)), sl, tp);
    pos.setPositionStatus(POSITION_STATUS_ON_REPLAY);
    aReplayingPositionsDT.Update(index, TimeCurrent());
   }      
  }
 }
}