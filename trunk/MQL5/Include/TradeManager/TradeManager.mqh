//+------------------------------------------------------------------+
//|                                                CTradeManager.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include "TradeManagerEnums.mqh"
#include "PositionOnPendingOrders.mqh"
#include "PositionArray.mqh"
#include "CTMTradeFunctions.mqh"
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>
#include <CLog.mqh>

int error = 0;
//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CTradeManager
{
protected:
  CPosition *position;
  ulong _magic;
  bool _useSound;
  string _nameFileSound;   // ������������ ��������� �����
  
  CPositionArray _positionsToReProcessing;
  CPositionArray _openPositions; ///< Array of open virtual orders for this VOM instance, also persisted as a file
  //CPositionArray _positionsHistory; ///< Array of closed virtual orders, also persisted as a file
  
public:
  void CTradeManager(ulong magic): _magic(magic), _useSound(true), _nameFileSound("expert.wav") { log_file.Write(LOG_DEBUG, "�������� ������� CTradeManager"); };
  
  bool OpenPosition(string symbol, ENUM_TM_POSITION_TYPE type,double volume ,int sl, int tp, 
                    int minProfit, int trailingStop, int trailingStep, int priceDifference = 0);
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
bool CTradeManager::OpenPosition(string symbol, ENUM_TM_POSITION_TYPE type, double volume,int sl, int tp, 
                                 int minProfit, int trailingStop, int trailingStep, int priceDifferense = 0)
{
 if (_positionsToReProcessing.Total() > 0) 
 {
  log_file.Write(LOG_DEBUG, "���������� ������� ������� ��� ��� ��� ���� ������� � positionsToReProcessing.");
  return false;
 }

 int i = 0;
 int total = _openPositions.Total();
 log_file.Write(LOG_DEBUG
               ,StringFormat("%s, ��������� ������� %s. �������� ������� �� ������ ������: %d"
                            , MakeFunctionPrefix(__FUNCTION__), GetNameOP(type), total));
 log_file.Write(LOG_DEBUG, _openPositions.PrintToString());
 switch(type)
 {
  case OP_BUY:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // ��������� ��� ������ ��� ������� �� �������
    {
     CPosition *pos = _openPositions.At(i);
     //PrintFormat("������� %d-� ������� ������=%s, �����=%d", i, pos.getSymbol(), pos.getMagic());
     if ((pos.getSymbol() == symbol) && (pos.getMagic() == _magic))
     {
      if (pos.getType() == OP_SELL || pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP)
      {
       ClosePosition(i);
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
     CPosition *pos = _openPositions.At(i);
     if ((pos.getSymbol() == symbol) && (pos.getMagic() == _magic))
     {
      if (pos.getType() == OP_BUY || pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP)
      {
       ClosePosition(i);
      }
     }
    }
   }
   break;
  default:
   log_file.Write(LOG_DEBUG, StringFormat("%s Error: Invalid ENUM_VIRTUAL_ORDER_TYPE", MakeFunctionPrefix(__FUNCTION__)));
   break;
 }
 
 total = _openPositions.Total() + _positionsToReProcessing.Total();
 if (total <= 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s openPositions � positionsToReProcessing ����� - ��������� ����� �������", MakeFunctionPrefix(__FUNCTION__)));
  position = new CPosition(_magic, symbol, type, volume, sl, tp, minProfit, trailingStop, trailingStep, priceDifferense);
  ENUM_POSITION_STATUS openingResult = position.OpenPosition();
  if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // ������� ���������� �������� �������
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s, magic=%d, symb=%s, type=%s, vol=%.02f, sl=%.06f, tp=%.06f", MakeFunctionPrefix(__FUNCTION__),position.getMagic(), position.getSymbol(), GetNameOP(position.getType()), position.getVolume(), position.getStopLossPrice(), position.getTakeProfitPrice()));
   _openPositions.Add(position);
   return(true); // ���� ������ ������� �������
  }
  else
  {
   error = GetLastError();
   log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� �������.Error{%d} = %s", MakeFunctionPrefix(__FUNCTION__), error, ErrorDescription(error)));
   return(false); // ���� ������� ������� �� �������
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("%s �������� �������� ������� %d", MakeFunctionPrefix(__FUNCTION__), total));
 return(true); // ���� �������� �������� �������, ������ �� ���� ����������� 
}
//+------------------------------------------------------------------+ 
// ������� ���������� ���������� ���������
//+------------------------------------------------------------------+
void CTradeManager::DoTrailing()  //TO DO LIST : �������� ������������
{
 int total = _openPositions.Total();
 ulong ticket = 0, slTicket = 0;
 long type = -1;
 double newSL = 0;

//--- ������� � ����� �� ���� �������
 for(int i = 0; i < total; i++)
 {
  CPosition *pos = _openPositions.At(i);
  pos.DoTrailing();
 } 
};
//+------------------------------------------------------------------+ 
// ������� ����������� �������
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action)
{
};

//+------------------------------------------------------------------+
/// Called from EA OnTrade().
/// Actions virtual stoplosses, takeprofits \n
/// Include the following in each EA that uses TradeManager
//+------------------------------------------------------------------+
void CTradeManager::OnTrade(datetime history_start)
  {
//--- ����������� ����� ��� �������� ��������� ��������� �����
   static int prev_positions = 0, prev_orders = 0, prev_deals = 0, prev_history_orders = 0, prev_type = -1;
   static double prev_volume = 0;
   int index = 0;
//--- �������� �������� �������
   bool update=HistorySelect(history_start, TimeCurrent());

   double curr_volume = PositionGetDouble(POSITION_VOLUME);
   int curr_type = PositionGetInteger(POSITION_TYPE);
   int curr_positions = PositionsTotal();
   int curr_orders = OrdersTotal();
   int curr_deals = HistoryOrdersTotal();
   int curr_history_orders = HistoryDealsTotal();
//--- ������� ������� ��������� � ����������   
   if ((curr_positions-prev_positions) != 0 || (curr_volume - prev_volume) != 0 || (curr_type - prev_type) != 0) // ���� ���������� ���������� ��� ����� �������
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� OnTrade, ���������� ���������� (%d/%d), �����(%.02f/%.02f) ��� ��� �������(%s/%s). (����/�����)"
                                          , MakeFunctionPrefix(__FUNCTION__), prev_positions, curr_positions, prev_volume, curr_volume, PositionTypeToStr((ENUM_POSITION_TYPE)prev_type), PositionTypeToStr((ENUM_POSITION_TYPE)curr_type)));
    /*
    for(int i = _positionsToReProcessing.Total()-1; i>=0; i--)
    {
     position = _positionsToReProcessing.At(i);
     if((!OrderSelect(position.getTakeProfitTicket()) && position.getTakeProfitStatus() == STOPLEVEL_STATUS_NOT_DELETED)
      ||(!OrderSelect(position.getStopLossTicket()) && position.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED))
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s �������� ���� �� ���������� ������� ������� �� ����� ���������. ��������� �������.", MakeFunctionPrefix(__FUNCTION__)));
      CloseReProcessingPosition(i);
     }
    }
    */
    for(int i = _openPositions.Total()-1; i>=0; i--) // �� ������� ����� �������
    {
     position = _openPositions.At(i); // ������� ������� �� �� �������
     if (!OrderSelect(position.getStopLossTicket())) // ���� �� �� ����� ������� ���� �� ��� ������, ������ �� ��������
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s ��� ������-StopLoss, ��������� TakeProfit : TakeProfitTicket=%d", MakeFunctionPrefix(__FUNCTION__), OrderGetTicket(OrderGetInteger(ORDER_POSITION_ID))));
      if (position.RemoveTakeProfit() == STOPLEVEL_STATUS_DELETED)  // �������� ��������, ���� ������� �����-����������...
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s, ������� TakeProfit, ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
       _openPositions.Delete(i);                         // ... � ������� ������� �� ������� ������� 
      }
      else
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� TakeProfit. ���������� ������� [%d] � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__), i));
       _positionsToReProcessing.Add(_openPositions.Detach(i));
      }
      break;                                                // ��������� ��� �����
     }
     if (!OrderSelect(position.getTakeProfitTicket())) // ���� �� �� ����� ������� ���� �� ��� ������, ������ �� ��������
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s ��� ������-TakeProfit, ��������� StopLoss StopLossTicket=%d", MakeFunctionPrefix(__FUNCTION__), OrderGetTicket(OrderGetInteger(ORDER_POSITION_ID))));
      if (position.RemoveStopLoss() == STOPLEVEL_STATUS_DELETED)  // �������� ����������, ���� ������� �����-��������...
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ������� StopLoss, ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
       _openPositions.Delete(i);                        // ... � ������� ������� �� ������� ������� 
      }
      else
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ������� StopLoss. ���������� ������� [%d] � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__), i));
       _positionsToReProcessing.Add(_openPositions.Detach(i));
      }
      break;                                                // ��������� ��� �����
     }
     
     if (position.getPositionStatus() == POSITION_STATUS_PENDING) // ���� ��� ������� ���������� �������...
     { 
      if (!OrderSelect(position.getPositionTicket())) // ... � �� �� ����� �� ������� �� �� ������, ������ ��� ���������
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ��������� ������� ���������� ���������� �������.�������� ���������� StopLoss � TakeProfit.", MakeFunctionPrefix(__FUNCTION__)));
       if (position.setStopLoss() == STOPLEVEL_STATUS_NOT_PLACED
        || position.setTakeProfit() == STOPLEVEL_STATUS_NOT_PLACED )  // ��������� ���������� �������� � ����������
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ���������� StopLoss �/��� TakeProfit. ���������� ������� [%d] � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));                  
        position.setPositionStatus(POSITION_STATUS_NOT_COMPLETE);  // ���� �� ����������, ��������, ����� ��������� �������
        _positionsToReProcessing.Add(position); 
        break;
       }
       log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ���������� StopLoss �/��� TakeProfit. ���������� ������� [%d] � openPositions.", MakeFunctionPrefix(__FUNCTION__)));
       position.setPositionStatus(POSITION_STATUS_OPEN); // ������� ���������, ���� � ���� �����������
       _openPositions.Add(position);
      }
     }
    }
   }
//--- �������� ��������� �����
   prev_volume = curr_volume;
   prev_type = curr_type;
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
void CTradeManager::OnTick()
{
 for(int i = _positionsToReProcessing.Total()-1; i>=0; i--) // �� ������� ������� �� ���������
 {
  CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� ������
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_DELETED)
  {
   if (pos.RemovePendingPosition() == POSITION_STATUS_DELETED)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ������� ������� [%d].������� � �� positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__), i));
    _positionsToReProcessing.Delete(i);
    break;
   }
  }
  
  if (pos.getTakeProfitStatus() == STOPLEVEL_STATUS_NOT_DELETED || pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ������� StopLoss � TakeProfit", MakeFunctionPrefix(__FUNCTION__)));    
   CloseReProcessingPosition(i);
   break;
  }
  
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_COMPLETE)
  {
   if (pos.setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && pos.setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ���������� StopLoss � TakeProfit � ������� [%d].���������� � �� positionsToReProcessing � openPositions.", MakeFunctionPrefix(__FUNCTION__), i));    
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
bool CTradeManager::ClosePosition(long ticket, color Color=CLR_NONE)
{
 int index = _openPositions.TicketToIndex(ticket);
 return ClosePosition(index);
}

//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] i			      position index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _openPositions.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 if (pos.ClosePosition())
 {
  _openPositions.Delete(i);  // ������� ������� �� �������
  log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
  return(true);
 }
 else
 {
  error = GetLastError();
  _positionsToReProcessing.Add(_openPositions.Detach(i));
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� ������� [%d]. ������� ���������� � ������ positionsToReProcessing.Error{%d} = %s"
                                        , MakeFunctionPrefix(__FUNCTION__), i, error, ErrorDescription(error)));
 }
 return(false);
}

//+------------------------------------------------------------------+
/// Delete a virtual position from "not_deleted".
/// \param [in] i			      position index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::CloseReProcessingPosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 if (pos.RemoveStopLoss() == STOPLEVEL_STATUS_DELETED && pos.RemoveTakeProfit() == STOPLEVEL_STATUS_DELETED)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������� ����������� ����-�����", MakeFunctionPrefix(__FUNCTION__)));
  _positionsToReProcessing.Delete(i);  // ������� ������� �� �������
  return(true);
 }
 return(false);
}

