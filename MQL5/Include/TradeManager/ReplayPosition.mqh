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

//+------------------------------------------------------------------+
//| �����-��������� ��� �������� � ������ � ���������                |
//+------------------------------------------------------------------+
class ReplayPosition
{ 
 private:
  CTradeManager ctm;  //�������� ����� 
  CPositionArray _posToReplay;   //������������ ������ ��� ��������� ������� �� �������
  /*
  int ATR_handle;
  double ATR_buf[];
  */
  datetime prevDate;  // ���� ���������� ��������� �������
 public: 
  void ReplayPosition();
  void ~ReplayPosition();
  
  void setArrayToReplay(CPositionArray *array);
  void CustomPosition ();   //��������� �� ������� � �������� ������� ������� ���������� ������ �������    
};
//+------------------------------------------------------------------+
//| �����������                                                      |
//+------------------------------------------------------------------+
void ReplayPosition::ReplayPosition(void)
{
/*
 ATR_handle = iATR(_symbol, _period, 100);
 if(handleMACD == INVALID_HANDLE)                                  //��������� ������� ������ ����������
 {
  Print("�� ������� �������� ����� ATR");               //���� ����� �� �������, �� ������� ��������� � ��� �� ������
 }
 */
}

//+------------------------------------------------------------------+
//| ����������                                                       |
//+------------------------------------------------------------------+
void ReplayPosition::~ReplayPosition(void)
{
 
}

//+------------------------------------------------------------------+
//| ��������� ������ ��� �������� �� �������� �������                |
//+------------------------------------------------------------------+
void ReplayPosition::setArrayToReplay(CPositionArray *array)
{
 int total = array.Total();
 CPosition *pos;
 for(int i = 0; i < total; i++)
 {
  pos = array.At(i);
  if (pos.getPosProfit() < 0)
  {
   pos.setPositionStatus(POSITION_STATUS_MUST_BE_REPLAYED);
   Alert("[������� ��������]",
           " ����� ��������  = ",TimeToString(pos.getOpenPosDT()),
           " ����� �������� = ",TimeToString(pos.getClosePosDT())
   );
   _posToReplay.Add(pos);
  }
 }
}
//+------------------------------------------------------------------+
//| ��������� �� ������� ������� � ���������\������ �������          |
//+------------------------------------------------------------------+
void ReplayPosition::CustomPosition()
{
 int direction = 0;
 uint index;
 uint total = _posToReplay.Total();        //������� ����� �������
 string symbol;
 double curPrice, profit, openPrice, closePrice;
 int sl, tp;
 CPosition *pos;                           //��������� �� ������� 

 for (index=0; index < total; index++)     //��������� �� ������� �������
 {

  pos = _posToReplay.At(index);

  symbol = pos.getSymbol();
  profit = pos.getPosProfit();
  openPrice = pos.getPriceOpen();
  closePrice = pos.getPriceClose();
  
  if (pos.Type() == OP_BUY)
  {
   direction = 1;
   curPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
  }
  if (pos.Type() == OP_SELL)
  {
   direction = -1;
   curPrice = SymbolInfoDouble(symbol, SYMBOL_BID);         
  }
  if (pos.getPositionStatus() == POSITION_STATUS_MUST_BE_REPLAYED)  //���� ������� ������� �������� �� ����� � Loss
  {
  
   //���� ���� ���������� �� Loss
   if (direction*(curPrice - closePrice) < profit)
   {
    pos.setPositionStatus(POSITION_STATUS_READY_TO_REPLAY);  //��������� ������� � ����� ���������� � ��������
       /*Comment(
           "[������� ������ � ��������] ",
           "��� = ", GetNameOP(pos.getType()), 
           "; ���� �������� = ", openPrice, 
           " ���� �������� = ", closePrice,
           " ������ ������� = ",profit,
           " ���� � ����� = ", TimeToString(TimeCurrent())
          );*/
   } 
  }
  else
  {
   if ((pos.getPositionStatus() == POSITION_STATUS_READY_TO_REPLAY)
      && (direction*curPrice >= closePrice))//���� ������� ������ � �������� � ���� ���������� �� ���� ���� �������� �������
   {
    tp = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL),
                 NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
    sl = MathMax(SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL),
                 NormalizeDouble((profit/_Point), SymbolInfoInteger(symbol, SYMBOL_DIGITS)));              
   ctm.OpenMultiPosition(symbol, pos.getType(), pos.getVolume(), sl, tp, 0, 0, 0); //��������� �������
   pos.setPositionStatus(POSITION_STATUS_OPEN);
         /* Comment(
           "[������� ������� �� �������] ",
           "��� = ", GetNameOP(pos.getType()), 
           "; ���� �������� = ", openPrice, 
           " ���� �������� = ", closePrice,
           " ������ ������� = ",profit,
           " ���� � ����� = ", TimeToString(TimeCurrent())
          );*/
   
   // _posToReplay.Delete(index); //� ������� � �� �������  

   }      
  }
 }
 
 setArrayToReplay(ctm.GetPositionHistory(prevDate));
 prevDate = TimeCurrent();  
}
