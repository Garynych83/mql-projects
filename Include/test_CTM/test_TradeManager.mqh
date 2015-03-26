//+------------------------------------------------------------------+
//|                                                test_CTradeManager.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include <TradeManager\TradeManagerEnums.mqh>
#include "test_Position.mqh"
#include "test_PositionArray.mqh"
#include "test_CTMTradeFunctions.mqh"
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class test_CTradeManager
{
protected:
  test_CPosition *position;
  test_CTMTradeFunctions trade;
  ulong _magic;
  bool _useSound;
  string _nameFileSound;   // ������������ ��������� �����
  
  test_CPositionArray _positionsToReProcessing;
  test_CPositionArray _openPositions; ///< Array of open virtual orders for this VOM instance, also persisted as a file
  //CPositionArray _positionsHistory; ///< Array of closed virtual orders, also persisted as a file
  
public:
  void test_CTradeManager(ulong magic): _magic(magic), _useSound(true), _nameFileSound("expert.wav"){};
  
  bool OpenPosition(string symbol, ENUM_TM_POSITION_TYPE type,double volume
                   ,int sl, int tp, int minProfit, int trailingStop, int trailingStep, int priceDifference = 0);
  void ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action);
  bool ClosePosition(long ticket, color Color=CLR_NONE); // �������� ������� �� ������
  bool ClosePosition(int i,color Color=CLR_NONE);  // �������� ������� �� ������� � ������� �������
  bool CloseReProcessingPosition(int i,color Color=CLR_NONE); 
  void DoTrailing();
  void OnTick();
  void OnTrade(datetime history_start);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool test_CTradeManager::OpenPosition(string symbol, ENUM_TM_POSITION_TYPE type, double volume
                                ,int sl, int tp, int minProfit, int trailingStop, int trailingStep, int priceDifferense = 0)
{
 //Print("=> ",__FUNCTION__," at ",TimeToString(TimeCurrent(),TIME_SECONDS));
 if (_positionsToReProcessing.Total() > 0) 
 {
  //PrintFormat ("���������� ������� ������� ��� ��� �� ��� ���������� ������ �������.");
  return false;
 }
 else
 {
  //PrintFormat("positionsToReProcessing ����, ����� ��������� �������");
 }
 int i = 0;
 int total = _openPositions.Total();
 PrintFormat("��������� ������� %s. �������� ������� %d",GetNameOP(type), total);
 switch(type)
 {
  case OP_BUY:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // ��������� ��� ������ ��� ������� �� �������
    {
     //PrintFormat("������� %d-� �������", i);
     test_CPosition *pos = _openPositions.At(i);
     //PrintFormat("������� %d-� ������� ������=%s, �����=%d", i, pos.getSymbol(), pos.getMagic());
     if ((pos.getSymbol() == symbol) && (pos.getMagic() == _magic))
     {
      if (pos.getType() == OP_SELL || pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP)
      {
       //Print("���� ������� ����");
       if (ClosePosition(i))
       {
        Print("������� ������� ����");
       }
       else
       {
        Print("������ ��� �������� ������� ����");
       }
      }
     }
    }
   }
   break;
  case OP_SELL:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // ��������� ��� ������ ��� ������� �� �������
    {
     //PrintFormat("������� %d-� �������", i);
     test_CPosition *pos = _openPositions.At(i);
     if ((pos.getSymbol() == symbol) && (pos.getMagic() == _magic))
     {
      if (pos.getType() == OP_BUY || pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP)
      {
       //Print("���� ������� ���");
       if (ClosePosition(i))
       {
        Print("������� ������� ���");
       }
       else
       {
        Print("������ ��� �������� ������� ���");
       }
      }
     }
    }
   }
   break;
  default:
   //LogFile.Log(LOG_PRINT,__FUNCTION__," error: Invalid ENUM_VIRTUAL_ORDER_TYPE");
   break;
 }
 
 total = _openPositions.Total() + _positionsToReProcessing.Total();
 if (total <= 0)
 {
  Print("�������� ������� ��� - ��������� �����");
  position = new test_CPosition(_magic, symbol, type, volume, sl, tp, minProfit, trailingStop, trailingStep, priceDifferense);
  ENUM_POSITION_STATUS openingResult = position.OpenPosition();
  if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // ������� ���������� �������� �������
  {
   PrintFormat("%s, magic=%d, symb=%s, type=%s, vol=%.02f, sl=%.06f, tp=%.06f", MakeFunctionPrefix(__FUNCTION__),position.getMagic(), position.getSymbol(), GetNameOP(position.getType()), position.getVolume(), position.getStopLossPrice(), position.getTakeProfitPrice());
   _openPositions.Add(position);
   return(true); // ���� ������ ������� �������
  }
  else
  {
   return(false); // ���� ������� ������� �� �������
  }
 }
 PrintFormat("�������� �������� ������� %d", total);
 return(true); // ���� �������� �������� �������, ������ �� ���� ����������� 
}
//+------------------------------------------------------------------+ 
// ������� ���������� ���������� ���������
//+------------------------------------------------------------------+
void test_CTradeManager::DoTrailing()
{
 int total = _openPositions.Total();
 ulong ticket = 0, slTicket = 0;
 long type = -1;
 double newSL = 0;

//--- ������� � ����� �� ���� �������
 for(int i = 0; i < total; i++)
 {
  test_CPosition *pos = _openPositions.At(i);
  pos.DoTrailing();
 } 
};
//+------------------------------------------------------------------+ 
// ������� ����������� �������
//+------------------------------------------------------------------+
void test_CTradeManager::ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action)
{
};

//+------------------------------------------------------------------+
/// Called from EA OnTrade().
/// Actions virtual stoplosses, takeprofits \n
/// Include the following in each EA that uses TradeManager
//+------------------------------------------------------------------+
void test_CTradeManager::OnTrade(datetime history_start)
  {
//--- ����������� ����� ��� �������� ��������� ��������� �����
   static int prev_positions = 0, prev_orders = 0, prev_deals = 0, prev_history_orders = 0;
   static double prev_volume = 0;
   int index = 0;
//--- �������� �������� �������
   bool update=HistorySelect(history_start, TimeCurrent());

   double curr_volume = PositionGetDouble(POSITION_VOLUME);
   int curr_positions = PositionsTotal();
   int curr_orders = OrdersTotal();
   int curr_deals = HistoryOrdersTotal();
   int curr_history_orders = HistoryDealsTotal();
//--- ������� ������� ��������� � ����������   
   if ((curr_positions-prev_positions) != 0 || (curr_volume - prev_volume) != 0) // ���� ���������� ���������� ��� ����� �������
   {
    Print("������� OnTrade, ���������� ���������� ��� ����� ������� �������");
    for(int i = _positionsToReProcessing.Total()-1; i>=0; i--)
    {
     position = _positionsToReProcessing.At(i);
     if((!OrderSelect(position.getTakeProfitTicket()) && position.getTakeProfitStatus() == STOPLEVEL_STATUS_NOT_DELETED)
      ||(!OrderSelect(position.getStopLossTicket()) && position.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED))
     {
      CloseReProcessingPosition(i);
     }
    }
    
    for(int i = _openPositions.Total()-1; i>=0; i--) // �� ������� ����� �������
    {
     position = _openPositions.At(i); // ������� ������� �� �� �������
     if (!OrderSelect(position.getStopLossTicket())) // ���� �� �� ����� ������� ���� �� ��� ������, ������ �� ��������
     {
      PrintFormat("%s ��� ������-���������, ��������� ���������� TakeProfitTicket=%d", MakeFunctionPrefix(__FUNCTION__), OrderGetTicket(OrderGetInteger(ORDER_POSITION_ID)));
      if (position.RemoveTakeProfit() == STOPLEVEL_STATUS_DELETED)  // �������� ��������, ���� ������� �����-����������...
      {
       _openPositions.Delete(i);                         // ... � ������� ������� �� ������� ������� 
      }
      else
      {
       _positionsToReProcessing.Add(_openPositions.Detach(i));
      }
      break;                                                // ��������� ��� �����
     }
     if (!OrderSelect(position.getTakeProfitTicket())) // ���� �� �� ����� ������� ���� �� ��� ������, ������ �� ��������
     {
      PrintFormat("%s ��� ������-�����������, ��������� �������� StopLossTicket=%d", MakeFunctionPrefix(__FUNCTION__), OrderGetTicket(OrderGetInteger(ORDER_POSITION_ID)));
      if (position.RemoveStopLoss() == STOPLEVEL_STATUS_DELETED)  // �������� ����������, ���� ������� �����-��������...
      {
       _openPositions.Delete(i);                        // ... � ������� ������� �� ������� ������� 
      }
      else
      {
       _positionsToReProcessing.Add(_openPositions.Detach(i));
      }
      break;                                                // ��������� ��� �����
     }
     
     if (position.getPositionStatus() == POSITION_STATUS_PENDING) // ���� ��� ������� ���������� �������...
     { 
      if (!OrderSelect(position.getPositionTicket())) // ... � �� �� ����� �� ������� �� �� ������, ������ ��� ���������
      {
       if (position.setStopLoss() == STOPLEVEL_STATUS_NOT_PLACED
        || position.setTakeProfit() == STOPLEVEL_STATUS_NOT_PLACED )  // ��������� ���������� �������� � ����������
       {                  
        position.setPositionStatus(POSITION_STATUS_NOT_COMPLETE);  // ���� �� ����������, ��������, ����� ��������� �������
        _positionsToReProcessing.Add(position); 
        break;
       }
       position.setPositionStatus(POSITION_STATUS_OPEN); // ������� ���������, ���� � ���� �����������
       _openPositions.Add(position);
      }
     }
    }
   }
//--- �������� ��������� �����
   prev_volume = curr_volume;
   prev_positions = curr_positions;
   prev_orders = curr_orders;
   prev_deals = curr_deals;
   prev_history_orders = curr_history_orders;
  }

//+------------------------------------------------------------------+
/// Called from EA OnTick().
/// Actions virtual stoplosses, takeprofits \n
/// Include the following in each EA that uses TradeManager
/// \code
/// // EA code
/// void OnTick()
///  {
///   // action virtual stoplosses, takeprofits
///   tm.OnTick();
///   //
///   // continue with other tick event handling in this EA
///   // ....
/// \endcode
//+------------------------------------------------------------------+
void test_CTradeManager::OnTick()
{
 //PrintFormat("����������� OnTick");
 for(int i = _positionsToReProcessing.Total()-1; i>=0; i--) // �� ������� ������� �� ���������
 {
  test_CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� ������
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_DELETED)
  {
   if (pos.RemovePendingPosition() == POSITION_STATUS_DELETED)
   {
    _positionsToReProcessing.Delete(i);
    break;
   }
  }
  
  if (pos.getTakeProfitStatus() == STOPLEVEL_STATUS_NOT_DELETED || pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED)
  {
   if (pos.RemoveTakeProfit() == STOPLEVEL_STATUS_DELETED && pos.RemoveStopLoss() == STOPLEVEL_STATUS_DELETED)
   {
    _positionsToReProcessing.Delete(i);
    break;
   }
  }
  
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_COMPLETE)
  {
   if (pos.setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && pos.setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
   {
    pos.setPositionStatus(POSITION_STATUS_OPEN);
    _openPositions.Add(_positionsToReProcessing.Detach(i));
   }
  }
 }
}  
//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] ticket			Open virtual order ticket
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool test_CTradeManager::ClosePosition(long ticket, color Color=CLR_NONE)
{
 int index = _openPositions.TicketToIndex(ticket);
 return ClosePosition(index);
}

//+------------------------------------------------------------------+
/// Close a virtual position.
/// \param [in] i			      position index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool test_CTradeManager::ClosePosition(int i,color Color=CLR_NONE)
{
 test_CPosition *pos = _openPositions.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 if (pos.ClosePosition())
 {
  _openPositions.Delete(i);  // ������� ������� �� �������
  return(true);
 }
 else
 {
  _positionsToReProcessing.Add(_openPositions.Detach(i));
 }
 return(false);
}

//+------------------------------------------------------------------+
/// Delete a virtual position from "not_deleted".
/// \param [in] i			      position index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool test_CTradeManager::CloseReProcessingPosition(int i,color Color=CLR_NONE)
{
 test_CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 switch(pos.getType())
 {
  case OP_BUY:
  case OP_BUYLIMIT:
  case OP_BUYSTOP:
   if (trade.PositionOpen(pos.getSymbol(), POSITION_TYPE_BUY, pos.getVolume(), pos.pricetype(POSITION_TYPE_BUY)))
   {
    _positionsToReProcessing.Delete(i);  // ������� ������� �� �������
    return(true);
   }
   break;
  case OP_SELL:
  case OP_SELLLIMIT:
  case OP_SELLSTOP:
   if(trade.PositionOpen(pos.getSymbol(), POSITION_TYPE_SELL, pos.getVolume(), pos.pricetype(POSITION_TYPE_SELL)))
   {
    _positionsToReProcessing.Delete(i);  // ������� ������� �� �������
    return(true);
   }
   break;
 }
 return(false);
}