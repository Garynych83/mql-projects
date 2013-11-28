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
  CArrayLong aReplayingPositionsDT;          // ������ ������� ��� �������� ��������� �������
  
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
  CPosition* CreatePositionToReplay(string symbol, ENUM_TM_POSITION_TYPE type, double volume, double priceOpen, double priceClose, double profit);
};
//+------------------------------------------------------------------+
//| �����������                                                      |
//+------------------------------------------------------------------+
void ReplayPosition::ReplayPosition(string symbol, ENUM_TIMEFRAMES period, int ATRforReplay, int ATRforTrailing)
                    : _ATRforReplay(ATRforReplay/100), _ATRforTrailing(ATRforTrailing/100)
{
 if (period < PERIOD_H1) period = PERIOD_H1;
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
 //PrintFormat("%s, total=%d, totalOnRep=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total());
 ctm.OnTrade();
 CPositionArray *array;
 CPosition *posFromHistory, *posToReplay;
 double profitToReplay, profitFromHistory;
 int index;
 
 if (prevDate != TimeCurrent())
 {
  array = ctm.GetPositionHistory(prevDate);
  prevDate = TimeCurrent() + 1;
 }
 else
 {
  return;
 }
   
 int totalReplayed = array.Total();
 int totalOnReplaying = aReplayingPositionsDT.Total();
 if (totalReplayed > 0) PrintFormat("%s ������� %d ������� �������� ��� ��������", MakeFunctionPrefix(__FUNCTION__), totalReplayed);
 
 for (int i = 0; i < totalReplayed; i++)
 {
  posFromHistory = new CPosition(array.At(i));
  index = 0;
  while (index < totalOnReplaying && posFromHistory.getOpenPosDT() != aReplayingPositionsDT[index])
  {
   index++;
   PrintFormat("%s �� ��������� ������� �������� ���������: total=%d, totalOnRep=%d, index = %d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), totalOnReplaying, index);
  }
  
  posToReplay = aPositionsToReplay.At(index);
  profitToReplay = posToReplay.getPosProfit();
  profitFromHistory = posFromHistory.getPosProfit();
  
  if (profitFromHistory > 0)
  {
   if (profitFromHistory >= profitToReplay)
   {
    PrintFormat("%s ������� �� ������� �������� ������: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index);
    aPositionsToReplay.Delete(index);
    aReplayingPositionsDT.Delete(index);
   } 
   else
   {
    PrintFormat("%s ������� �� ������� �� �������� ������: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index);
    posToReplay.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
    aReplayingPositionsDT.Update(index, 0);
   }
  }
   
  if (posFromHistory.getPosProfit() < 0)
  {
   PrintFormat("%s ������� �� ������� ������� � �������: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index);
   aPositionsToReplay.Add(
       CreatePositionToReplay(
                    posToReplay.getSymbol()
                  , posToReplay.getType()
                  , posToReplay.getVolume()
                  , profitFromHistory + profitToReplay
                  , posToReplay.getPriceOpen()
                  , posFromHistory.getPriceClose()));
                  
   aReplayingPositionsDT.Add(0);
   PrintFormat("%s �������� ����� �������: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index);
   aPositionsToReplay.Delete(index);
   aReplayingPositionsDT.Delete(index);
   PrintFormat("%s ������� ������ �������: total=%d, totalOnRep=%d, index=%d", MakeFunctionPrefix(__FUNCTION__), aPositionsToReplay.Total(), aReplayingPositionsDT.Total(), index);
  }
  delete posFromHistory;
 }
 
}
//+------------------------------------------------------------------+
//| ��������� ������ ��� �������� �� �������� �������                |
//+------------------------------------------------------------------+
void ReplayPosition::setArrayToReplay(CPositionArray *array)
{
 //Print("��������� ������ �� ������� total=", array.Total());
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
   PrintFormat("%s �������� ������� closePrice=%.05f, Profit=%.05f, status=%s, total=%d, totalOnRep=%d"
              , MakeFunctionPrefix(__FUNCTION__), pos.getPriceClose(), pos.getPosProfit()
              , PositionStatusToStr(pos.getPositionStatus()), aPositionsToReplay.Total(), aReplayingPositionsDT.Total());
  }
  else
  {
   delete pos;
  }
 }
 //delete array;
}

//+------------------------------------------------------------------+
//| ��������� �� ������� ������� � ���������\������ �������          |
//+------------------------------------------------------------------+
CPosition* ReplayPosition::CreatePositionToReplay(string symbol, ENUM_TM_POSITION_TYPE type, double volume, double priceOpen, double priceClose, double profit)
{
 CPosition *posToAdd;
 posToAdd = new CPosition(symbol, type, volume, priceOpen, priceClose, profit);
 posToAdd.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
 return posToAdd;
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
    PrintFormat("������� %d ���������� � ����� ���������� � ��������, type=%s, direction=%d, profit=%.05f, close=%.05f, current=%.05f, ATR=%.05f"
                , index, GetNameOP(pos.getType()), direction, profit, closePrice, curPrice, ATR_buf[0]*_ATRforReplay);
                
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
    
    if (ctm.OpenMultiPosition(symbol, pos.getType(), pos.getVolume(), sl, tp, trailParam, trailParam, trailParam)) //��������� �������
    {
     PrintFormat("������� ������� ��� �������� type=%s, profit=%.05f, sl=%d, tp=%d", GetNameOP(pos.getType()), NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)), sl, tp);
     pos.setPositionStatus(POSITION_STATUS_ON_REPLAY);
     aReplayingPositionsDT.Update(index, TimeCurrent());
    }
    else
    {
     PrintFormat("�� ������� ������� ������� ��� �������� profit=%.05f, sl=%d, tp=%d",NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)), sl, tp);
    }
   }      
  }
 }
 ctm.DoUsualTrailing();
}
