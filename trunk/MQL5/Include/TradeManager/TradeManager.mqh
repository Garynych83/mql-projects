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
private:
  double _current_balance;    // ������� ������� ��������� � �������
  double _current_drawdown;   // ������� �������� �������
  double _max_drawdown;       // ����������� ���������� ��������
  double _max_balance;        // ������������ ������
  
  int    _historyChanged;     // ����� ��������� ������� (0-�� ��������, 1-�����������, 2-�����������)

  bool   CloseReProcessingPosition(int i,color Color=CLR_NONE);
  string CreateFilename(ENUM_FILENAME filename);
  long   MakeMagic(string strSymbol = "");
  bool   LoadArrayFromFile(string file_url,CPositionArray *array);
  bool   SaveArrayToFile(string file_url,CPositionArray *array);  
protected:
  ulong _magic;
  bool _useSound;
  string _nameFileSound;   // ������������ ��������� �����
  string rescueDataFileName, historyDataFileName;
  datetime _historyStart;
  CPositionArray *_positionsToReProcessing; ///������ �������, ����������� � ��������
  CPositionArray *_openPositions;           ///������ ������� �������� �������
  CPositionArray *_positionsHistory;        ///������ ������� ����������� �������
    
public:
  void CTradeManager();
  void ~CTradeManager(void);
  
  void OnTick();
  void OnTrade(datetime history_start);
  
  // GET
  double GetCurrentDrawdown() {return(_current_drawdown); };  // ����������  ������� �������� �� �������  
  double GetCurrentProfit()   {return(_current_balance);};    // ���������� ������� �������
  long   GetHistoryDepth();                                   //���������� ������� �������
  double GetMaxDrawdown()     {return(_max_drawdown); };      // ����������  ������� �������� �� �������
  double GetMaxProfit()       {return(_max_balance);};        // ���������� ������� �������
  int    GetPositionCount()   {return (_openPositions.Total() + _positionsToReProcessing.Total());};  
  CPositionArray* GetPositionHistory(datetime fromDate, datetime toDate = 0); //���������� ������ ������� �� ������� 
  int    GetPositionPointsProfit(int i, ENUM_SELECT_TYPE type);
  int    GetPositionPointsProfit(string symbol);
  ENUM_TM_POSITION_TYPE GetPositionType(string symbol);

  bool ClosePosition(string symbol, color Color=CLR_NONE);    // �������� ������� �� �������
  bool ClosePosition(long ticket, color Color = CLR_NONE);    // �������� ������� �� ������
  bool ClosePosition(int i, color Color = CLR_NONE);          // �������� ������� �� ������� � ������� �������
  void DoUsualTrailing();
  void DoLosslessTrailing();
  bool isMinProfit(string symbol);
  bool IsHistoryChanged ();                                   // ���������� ������ ��������� ������� 
  void ModifyPosition(long ticket, int sl, int tp);
  bool OpenUniquePosition(string symbol, ENUM_TM_POSITION_TYPE type,double volume ,int sl = 0, int tp = 0, 
                          int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int priceDifference = 0);
  bool OpenMultiPosition(string symbol, ENUM_TM_POSITION_TYPE type,double volume ,int sl, int tp, 
                          int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int priceDifference = 0);
  bool PositionChangeSize(string strSymbol, double additionalVolume);
  void UpdateData(CPositionArray *positionsHistory);
  
};

//+---------------------------------
// �����������
//+---------------------------------
void CTradeManager::CTradeManager(): 
                    _useSound(true), 
                    _nameFileSound("expert.wav") 
{
 _positionsToReProcessing = new CPositionArray();
 _openPositions           = new CPositionArray();
 _positionsHistory        = new CPositionArray();
 
 _magic = MakeMagic();
 _historyStart = TimeCurrent(); 
 
 _historyChanged = 0;  
 
 rescueDataFileName  = CreateFilename(FILENAME_RESCUE);
 historyDataFileName = CreateFilename(FILENAME_HISTORY);
 LoadArrayFromFile(rescueDataFileName ,_openPositions);
 LoadArrayFromFile(historyDataFileName,_positionsHistory);
};

//+---------------------------------
// ����������
//+---------------------------------
void CTradeManager::~CTradeManager(void)
{
 log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� ���������������.", MakeFunctionPrefix(__FUNCTION__)));
 int size = _openPositions.Total();
 int attempts = 0;
 while (attempts < 25)
 {
  for(int i = size - 1; i>=0; i--) // �� ������� ����� �������
  {
   ClosePosition(i);
  }
  size = _openPositions.Total(); 
  if(size == 0) break;
  attempts++;
 }
 
 delete _positionsToReProcessing;
 delete _openPositions;
 delete _positionsHistory;
 log_file.Write(LOG_DEBUG, StringFormat("%s ������� ��������������� ��������.", MakeFunctionPrefix(__FUNCTION__)));
 FileDelete(rescueDataFileName, FILE_COMMON);
};

//+------------------------------------------------------------------+
/// Called from EA OnTick().
/// Actions virtual positions 
/// Include the folowing in each EA that uses TradeManage
//+------------------------------------------------------------------+
void CTradeManager::OnTick()
{
//--- ������� ���������� ������������� �������
 int total = _positionsToReProcessing.Total();
 for(int i = total - 1; i>=0; i--) // �� ������� ������� �� ���������
 {
  CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� ������
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_DELETED)
  {
   if (pos.RemovePendingPosition() == POSITION_STATUS_DELETED)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ������� ������� [%d].������� � �� positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__), i));
    _positionsHistory.Add(_positionsToReProcessing.Detach(i)); //��������� ��������� ������� � ������
    _historyChanged = 1; // ������ ����, ��� ������� �����������
    SaveArrayToFile(historyDataFileName,_positionsHistory);                    
    break;
   }
  }
  
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_CHANGED)
  {
   if (pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED)
   {
    pos.ChangeStopLossVolume();
   }
   if (pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_PLACED);
   {
    pos.setStopLoss();
   }
  }
  
  if (pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED)
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
    SaveArrayToFile(rescueDataFileName,_openPositions);    
   }
  }
 } 

//--- ���������� �������
 if(!HistorySelect(_historyStart, TimeCurrent()))
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ������� ������� � %s �� %s", MakeFunctionPrefix(__FUNCTION__), _historyStart, TimeCurrent())); 
  return;
 }

//--- ���� ������� ������������, �������� � �������� ���������  
 total = _openPositions.Total();
 CPosition *pos;
//--- �� ������� ����� �������
 for(int i = total - 1; i >= 0; i--) 
 {
  pos = _openPositions.At(i);   // ������� ������� �� �� �������
  ENUM_TM_POSITION_TYPE type = pos.getType();
  
  if (!OrderSelect(pos.getStopLossTicket()) && pos.getPositionStatus() != POSITION_STATUS_PENDING && pos.getStopLossStatus() != STOPLEVEL_STATUS_NOT_DEFINED) // ���� �� �� ����� ������� ���� �� ��� ������, ������ �� ��������
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ��� ������-StopLoss, ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
   pos.setPositionStatus(POSITION_STATUS_CLOSED);
   ClosePosition(i);
   break;                          
  }
  
  if (pos.CheckTakeProfit())    //��������� ������� ���������� TP
  {
   //log_file.Write(LOG_DEBUG, StringFormat("%s ���� ����� �� ������ TP, ��������� ������� type = %s, TPprice = %f", MakeFunctionPrefix(__FUNCTION__), GetNameOP(type),  pos.getTakeProfitPrice()));
   PrintFormat("%s ���� ����� �� ������ TP, ��������� ������� type = %s, TPprice = %f", MakeFunctionPrefix(__FUNCTION__), GetNameOP(type),  pos.getTakeProfitPrice());
   ClosePosition(i);
   break;             
  }
     
  if (pos.getPositionStatus() == POSITION_STATUS_PENDING) // ���� ��� ������� ���������� �������...
  {
   if (!OrderSelect(pos.getOrderTicket())) // ���� �� �� ����� ������� �� �� ������
   {
    long ticket = pos.getOrderTicket();
    if(!FindHistoryTicket(ticket))            // ��������� ����� ���� ����� � �������
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s � ������� ������� �� ������ ����� � ������� %d", MakeFunctionPrefix(__FUNCTION__), ticket));
     return;
    }
    
    long state;
    if (HistoryOrderGetInteger(ticket, ORDER_STATE, state)) // ������� ������ ������ �� �������
    {
     switch (state)
     {
      case ORDER_STATE_FILLED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ��������� ������� ���������� ���������� �������.�������� ���������� StopLoss � TakeProfit.", MakeFunctionPrefix(__FUNCTION__)));
       
       if (pos.setStopLoss() == STOPLEVEL_STATUS_NOT_PLACED
        || pos.setTakeProfit() == STOPLEVEL_STATUS_NOT_PLACED )  // ��������� ���������� �������� � ����������
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ���������� StopLoss �/��� TakeProfit. ���������� ������� [%d] � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));                  
        pos.setPositionStatus(POSITION_STATUS_NOT_COMPLETE);  // ���� �� ����������, ��������, ����� ��������� �������
        _positionsToReProcessing.Add(_openPositions.Detach(i)); 
        break;
       }
       
       log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ���������� StopLoss �/��� TakeProfit. �������� ������� [%d] � openPositions.", MakeFunctionPrefix(__FUNCTION__)));
       pos.setPositionStatus(POSITION_STATUS_OPEN); // ������� ���������, ���� � ���� �����������
       if (pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP) pos.setType(OP_BUY);
       if (pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP) pos.setType(OP_SELL);
       log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
       
       SaveArrayToFile(rescueDataFileName,_openPositions);       
       break;
      }
      case ORDER_STATE_CANCELED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ����� ������� %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getOrderTicket(), ORDER_STATE))));
       _positionsHistory.Add(_openPositions.Detach(i));
       _historyChanged = 1; // ������ ����, ��� ������� �����������  
       SaveArrayToFile(historyDataFileName,_positionsHistory);       
       break;
      }
      case ORDER_STATE_EXPIRED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����� �������� %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getOrderTicket(), ORDER_STATE))));
       _positionsHistory.Add(_openPositions.Detach(i));
       _historyChanged = 1; // ������ ����, ��� ������� �����������
       SaveArrayToFile(historyDataFileName,_positionsHistory);       
       break;
      }
      
      default:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ ������� ��� ����������� � �������: %s; ����� ������: %d", MakeFunctionPrefix(__FUNCTION__), EnumToString((ENUM_ORDER_STATE)state), ticket));
       break;
      }
     }
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ������� ����� �� ������ %d �� �������", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()));
     log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(GetLastError())));
     string str;
     int total = HistoryOrdersTotal();
     for(int i = total-1; i >= 0; i--)
     {
      str += HistoryOrderGetTicket(i) + " ";
     }
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������� �� �������: %s", MakeFunctionPrefix(__FUNCTION__), str));
    } 
   }
  }
 }
}

//+------------------------------------------------------------------+
/// Called from EA OnTrade().
/// Include the folowing in each EA that uses TradeManager
//+------------------------------------------------------------------+
void CTradeManager::OnTrade(datetime history_start=0)
{
 // ���������� ���� ��������� ������� 
 if (_historyChanged != 0)
  {
   _historyChanged = 0;
  }
}

//+----------------------------------------------------
//| ���������� ������� �������
//+----------------------------------------------------
long CTradeManager::GetHistoryDepth() 
{
 return _positionsHistory.Total();
}

//+----------------------------------------------------
//  ������ ��� ������ � Replay Position
//+----------------------------------------------------
CPositionArray* CTradeManager::GetPositionHistory(datetime fromDate, datetime toDate = 0)
{
 CPositionArray *resultArray;
 resultArray = new CPositionArray(); 
 CPosition *pos;
 datetime posTime;
 int total = _positionsHistory.Total();
 //Print("historyTotal=", _positionsHistory.Total());
 if (toDate == 0) toDate = TimeCurrent();
 
 for(int i = 0; i < total; i++)
 {
  pos = _positionsHistory.At(i);
  posTime = pos.getClosePosDT();
  //PrintFormat("posCloseDate=%s, fromDate=%s, toDate=%s", TimeToString(posTime), TimeToString(fromDate), TimeToString(toDate));
  if (posTime < fromDate) continue;   // ������� � ������ ����� - ����������
  if (posTime > toDate) break;        // ��������� �� ������� � ������� ����� - �������
  
  resultArray.Add(pos);               // ��������� ������ ��������� � ����� �������� � ������ ���������
 }
 //Print("resultTotal=", resultArray.Total());
 return resultArray;
} 

//+------------------------------------------------------------------+
//|  ������ ������� �� ������� � �������                             |
//+------------------------------------------------------------------+
int CTradeManager::GetPositionPointsProfit(string symbol)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   int profit = pos.getPositionPointsProfit();
   return(profit);
  }
 }
 return(0);
}

//+------------------------------------------------------------------+
/// Return current position type
/// \param [long] ticket       number of ticket to search
/// \return                    true if successful, false if not
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE CTradeManager::GetPositionType(string symbol)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(pos.getType());
  }
 }
 return OP_UNKNOWN;
}

//+------------------------------------------------------------------+
/// Close a virtual position by symbol.
/// \param [in] ticket			Open virtual order ticket
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(string symbol, color Color=CLR_NONE)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;

 if (total > 0)
 {
  for (i = total - 1; i >= 0; i--) // ���������� ��� ������ ��� ������� 
  {
   pos = _openPositions.At(i);
   if (pos.getSymbol() == symbol)
   {
    if (ClosePosition(i)) return (true);
    else return (false);
   }
  }
 }
 return (true);
}

//+------------------------------------------------------------------+
/// Close a virtual position by ticket.
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
/// Close a virtual position by index.
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _openPositions.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 //PrintFormat("%s �������� �� ������� ��������� �� ������� �� �� �������", MakeFunctionPrefix(__FUNCTION__));
 if (pos.ClosePosition())
 {
  //Print("���������� ������� � �������");
  _positionsHistory.Add(_openPositions.Detach(i)); //��������� ������� � ������� � ������� �� ������� �������� �������
  _historyChanged = 1; // ������ ����, ��� ������� ����������� 
  SaveArrayToFile(historyDataFileName,_positionsHistory); 
  SaveArrayToFile(rescueDataFileName,_openPositions);   
  log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
  PrintFormat("%s ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i);
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
// ������� ���������� ���������� ���������
//+------------------------------------------------------------------+
void CTradeManager::DoUsualTrailing()
{
 int total = _openPositions.Total();
//--- ������� � ����� �� ���� �������
 for(int i = 0; i < total; i++)
 {
  CPosition *pos = _openPositions.At(i);
  if(pos.UsualTrailing())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ��������� SL ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
   log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
  }
 } 
}

//+------------------------------------------------------------------+ 
// ������� ���������� ���������� ���������
//+------------------------------------------------------------------+
void CTradeManager::DoLosslessTrailing()
{
 int total = _openPositions.Total();
//--- ������� � ����� �� ���� �������
 for(int i = 0; i < total; i++)
 {
  CPosition *pos = _openPositions.At(i);
  if(pos.UsualTrailing())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ��������� SL ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
   log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
  }
 } 
}

//+------------------------------------------------------------------+
/// returns if minProfit achieved
//+------------------------------------------------------------------+
bool CTradeManager::isMinProfit(string symbol)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(pos.isMinProfit());
  }
 }
 return false;
}

//+------------------------------------------------------------------+
//| ���������� ������ ��������� �������
//+------------------------------------------------------------------+
bool CTradeManager::IsHistoryChanged(void) 
{ 
 if (_historyChanged!=0)
  return true;
 return false;
}

//+------------------------------------------------------------------+ 
// ������� ����������� �������
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(long ticket, int sl, int tp)
{
 if (sl > 0){}
 if (tp > 0){}
}


//+------------------------------------------------------------------+
//| ��������� ������������ �������                                   |
//| ���� ���������� ����� �� ������� - �������� �� �����             |
//| ���� ���������� ��������������� ������� - ��� ����� �������      |
//+------------------------------------------------------------------+
bool CTradeManager::OpenUniquePosition(string symbol, ENUM_TM_POSITION_TYPE type, double volume, int sl = 0, int tp = 0, 
                                 int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int priceDifferense = 0)
{
 if (_positionsToReProcessing.OrderCount(symbol, _magic) > 0) 
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ������� ������� ��� ��� ��� ���� ������� � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));
  return false;
 }

 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;
 log_file.Write(LOG_DEBUG
               ,StringFormat("%s, ��������� ������� %s. �������� ������� �� ������ ������: %d"
                            , MakeFunctionPrefix(__FUNCTION__), GetNameOP(type), total));
 log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString())); // ���������� ���� ������� �� ������� _openPositions
 switch(type)
 {
  case OP_BUY:
  case OP_BUYLIMIT:
  case OP_BUYSTOP:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // ��������� ��� ������ ��� ������� �� �������
    {
     pos = _openPositions.At(i);
     if (pos.getSymbol() == symbol)
     {
      if (pos.getType() == OP_SELL)
      {
       ClosePosition(i);
      }
      else
      {
       if (pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP)
       {
        ResetLastError();
        if(OrderSelect(pos.getOrderTicket()))
        {
         ClosePosition(i);
        }
        else
        {
         log_file.Write(LOG_DEBUG ,StringFormat("%s, �������� ������� �� �������: �� ������ ����� � ������� %d. ������ %d - %s"
                       , MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()
                       , GetLastError(), ErrorDescription(GetLastError())));
        }
       }
       else
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� ������� �� ������ %d", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()));
       }
      }
     }
    }
   }
   break;
  case OP_SELL:
  case OP_SELLLIMIT:
  case OP_SELLSTOP:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // ��������� ��� ������ ��� ������� �� �������
    {
     pos = _openPositions.At(i);
     if (pos.getSymbol() == symbol)
     {
      if (pos.getType() == OP_BUY)
      {
       ClosePosition(i);
      }
      else
      {
       if (pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP)
       {
        ResetLastError();
        if(OrderSelect(pos.getOrderTicket()))
        {
         ClosePosition(i);
        }
        else
        {
         log_file.Write(LOG_DEBUG ,StringFormat("%s, �������� ������� �� �������: �� ������ ����� � ������� %d. ������ %d - %s"
                        , MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()
                        , GetLastError(), ErrorDescription(GetLastError())));
        }
       }
       else
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� ������� �� ������ %d", MakeFunctionPrefix(__FUNCTION__), pos.getOrderTicket()));
       }
      }
     }
    }
   }
   break;
  default:
   log_file.Write(LOG_DEBUG, StringFormat("%s Error: Invalid ENUM_VIRTUAL_ORDER_TYPE", MakeFunctionPrefix(__FUNCTION__)));
   break;
 }
 
 total = _openPositions.OrderCount(symbol, _magic) + _positionsToReProcessing.OrderCount(symbol, _magic);
 if (total <= 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s openPositions � positionsToReProcessing ����� - ��������� ����� �������", MakeFunctionPrefix(__FUNCTION__)));
  PrintFormat("%s openPositions � positionsToReProcessing ����� - ��������� ����� �������", MakeFunctionPrefix(__FUNCTION__));
  pos = new CPosition(_magic, symbol, type, volume, sl, tp, minProfit, trailingStop, trailingStep, priceDifferense);
  ENUM_POSITION_STATUS openingResult = pos.OpenPosition();
  if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // ������� ���������� �������� �������
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s, magic=%d, symb=%s, type=%s, price=%.05f vol=%.02f, sl=%.05f, tp=%.05f"
                                          , MakeFunctionPrefix(__FUNCTION__), pos.getMagic(), pos.getSymbol(), GetNameOP(pos.getType()), pos.getPositionPrice(), pos.getVolume(), pos.getStopLossPrice(), pos.getTakeProfitPrice()));


   _openPositions.Add(pos);  // ��������� �������� ������� � ������ �������� �������
   SaveArrayToFile(rescueDataFileName ,_openPositions);
   log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
   return(true); // ���� ������ ������� �������
  }
  else
  {
   error = GetLastError();
   if(pos.getType() == OP_SELL || pos.getType() == OP_BUY) _positionsToReProcessing.Add(pos);
   log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� �������. Error{%d} = %s. Status = %s", MakeFunctionPrefix(__FUNCTION__), error, ErrorDescription(error), PositionStatusToStr(pos.getPositionStatus())));
   return(false); // ���� ������� ������� �� �������
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("%s �������� �������� ������� %d", MakeFunctionPrefix(__FUNCTION__), total));
 return(true); // ���� �������� �������� �������, ������ �� ���� ����������� 
}

//+------------------------------------------------------------------+
//| ��������� �������                                   |
//| ���� ���������� ����� �� ������� - �������� �� �����             |
//| ���� ���������� ��������������� ������� - ��� ����� �������      |
//+------------------------------------------------------------------+
bool CTradeManager::OpenMultiPosition(string symbol, ENUM_TM_POSITION_TYPE type, double volume,int sl, int tp, 
                                 int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int priceDifferense = 0)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;
 //log_file.Write(LOG_DEBUG
 //             ,StringFormat("%s, ��������� ������� %s. �������� ������� �� ������ ������: %d"
 //                           , MakeFunctionPrefix(__FUNCTION__), GetNameOP(type), total));
 PrintFormat("%s, ��������� ������-������� %s. �������� ������� �� ������ ������: %d"
                            , MakeFunctionPrefix(__FUNCTION__), GetNameOP(type), total); 
 log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString())); // ���������� ���� ������� �� ������� _openPositions
 
 pos = new CPosition(_magic, symbol, type, volume, sl, tp, minProfit, trailingStop, trailingStep, priceDifferense);
 ENUM_POSITION_STATUS openingResult = pos.OpenPosition();
 //Print("openingResult=", PositionStatusToStr(openingResult));
 if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // ������� ���������� �������� �������
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s, magic=%d, symb=%s, type=%s, price=%.05f vol=%.02f, sl=%.05f, tp=%.05f"
                                         , MakeFunctionPrefix(__FUNCTION__), pos.getMagic(), pos.getSymbol(), GetNameOP(pos.getType()), pos.getPositionPrice(), pos.getVolume(), pos.getStopLossPrice(), pos.getTakeProfitPrice()));
  _openPositions.Add(pos);  // ��������� �������� ������� � ������ �������� �������

  SaveArrayToFile(rescueDataFileName ,_openPositions);  
  log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
  return(true); // ���� ������ ������� �������
 }
 else
 {
  error = GetLastError();
  if(pos.getType() == OP_SELL || pos.getType() == OP_BUY) _positionsToReProcessing.Add(pos);
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� �������. Error{%d} = %s. Status = %s", MakeFunctionPrefix(__FUNCTION__), error, ErrorDescription(error), PositionStatusToStr(pos.getPositionStatus())));
  return(false); // ���� ������� ������� �� �������
 }

 log_file.Write(LOG_DEBUG, StringFormat("%s �������� �������� ������� %d", MakeFunctionPrefix(__FUNCTION__), total));
 return(true); // ���� �������� �������� �������, ������ �� ���� ����������� 
}

//+------------------------------------------------------------------+ 
// ������� ��������� ������ �������
//+------------------------------------------------------------------+
bool CTradeManager::PositionChangeSize(string symbol, double additionalVolume)
{
 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;

 if (total > 0)
 {
  for (i = total - 1; i >= 0; i--) // ���������� ��� ������ ��� ������� 
  {
   pos = _openPositions.At(i);
   if (pos.getSymbol() == symbol)
   {
    if (pos.getVolume() + additionalVolume != 0)
    {
     PrintFormat("%s ������� ����� ������� �������", MakeFunctionPrefix(__FUNCTION__));
     if (pos.ChangeSize(additionalVolume)) return (true);
     PrintFormat("%s �� ������� �������� ����� ������� �������", MakeFunctionPrefix(__FUNCTION__));
    }
    else
    {
     if (ClosePosition(i)) return (true);
    }
   }
  }
 }
 return (false);
}

//+------------------------------------------------------------------+
//|  ��������� ������ � ������� ������� � ��������                   |
//+------------------------------------------------------------------+
void CTradeManager::UpdateData(CPositionArray *positionsHistory)
{
 int index;  // ������ ������� �� �����
 int length = positionsHistory.Total(); // ����� ����������� ������� �������
 CPosition *pos; // ��������� �� ������� �������
 // �������� �� ���� ������� � ��������� ������� �������
    
 for (index = 0; index < length; index++)
 {
  // ��������� ��������� �� ������� ������� �� �������
  pos = positionsHistory.At(index);
  // �������� ������� ������� 
  _current_balance = _current_balance + pos.getPosProfit();
  //���� ������ �������� ������� ������������ ������
  if (_current_balance > _max_balance)  
  {
   // �� �������������� ���
   _max_balance = _current_balance;
  }
  else 
  {
   //���� ���������� ������ ��������, ��� ����
   if ((_max_balance-_current_balance) > _current_drawdown) 
   {
    //�� ���������� ����� �������� �������
    _current_drawdown = _max_balance-_current_balance;  
   }
  }  
 }
}

//---------------PRIVATE-----------------------------


//+------------------------------------------------------------------+
/// Delete a virtual pos from "not_deleted".
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::CloseReProcessingPosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 if (pos.RemoveStopLoss() == STOPLEVEL_STATUS_DELETED)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������� ����������� ����-�����", MakeFunctionPrefix(__FUNCTION__)));
  _positionsHistory.Add(_positionsToReProcessing.Detach(i));
  _historyChanged = 1; // ������ ����, ��� ������� �����������  
  SaveArrayToFile(historyDataFileName,_positionsHistory);  
  return(true);
 }
 return(false);
}

//+------------------------------------------------------------------+
/// Create file name
/// \return							generated string
//+------------------------------------------------------------------+
string CTradeManager::CreateFilename (ENUM_FILENAME filename)
{
 string name, result;
 switch(filename)
   {
    case FILENAME_RESCUE :
      name = "RescueData";
      break;
    case FILENAME_HISTORY :
      name = "History";
      break;
    default:
      break;
   }
 result = StringFormat("%s\\%s\\%s_%s_%s.csv", MQL5InfoString(MQL5_PROGRAM_NAME), name, MQL5InfoString(MQL5_PROGRAM_NAME), StringSubstr(Symbol(),0,6), PeriodToString(Period()));
 return(result);
}

//+----------------------------------------------------
//  �������� �� ����� ������� �������                 
//+----------------------------------------------------
bool CTradeManager::LoadArrayFromFile(string file_url,CPositionArray *array)
{
 if(MQL5InfoInteger(MQL5_TESTING) || MQL5InfoInteger(MQL5_OPTIMIZATION) || MQL5InfoInteger(MQL5_VISUAL_MODE))
 {
  FileDelete(file_url);
  return(true);
 }
 
 int file_handle;   //�������� �����  
 if (!FileIsExist(file_url, FILE_COMMON) ) //�������� ������������� ����� ������� 
 {
  PrintFormat("%s File %s doesn't exist", MakeFunctionPrefix(__FUNCTION__),file_url);
  return (true);
 }  
 file_handle = FileOpen(file_url, FILE_READ|FILE_COMMON|FILE_CSV|FILE_ANSI, ";");
 if (file_handle == INVALID_HANDLE) //�� ������� ������� ����
 {
  PrintFormat("%s error: %s opening %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(::GetLastError()), historyDataFileName);
  return (false);
 }
 
 array.Clear();                   //������� ������
 array.ReadFromFile(file_handle); //��������� ������ �� ����� 
 FileClose(file_handle);          //��������� ����  
 return (true);
} 

//+------------------------------------------------------------------+
/// Create magic number
/// \param [string] str       symbol
/// \return							generated magic number
//+------------------------------------------------------------------+
long CTradeManager::MakeMagic(string strSymbol = "")
{
 if(strSymbol == "") strSymbol = Symbol();
 string s = strSymbol + PeriodToString(Period()) + MQL5InfoString(MQL5_PROGRAM_NAME);
 ulong ulHash = 5381;
 for(int i = StringLen(s) - 1; i >= 0; i--)
 {
  ulHash = ((ulHash<<5) + ulHash) + StringGetCharacter(s,i);
 }
 return MathAbs((long)ulHash);
}

//+----------------------------------------------------
//  ���������� � ���� ������� �������                 |
//+----------------------------------------------------
bool CTradeManager::SaveArrayToFile(string file_url, CPositionArray *array)
{
 int file_handle = FileOpen(file_url, FILE_WRITE|FILE_CSV|FILE_COMMON, ";");
 if(file_handle == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ������� ����: %s", MakeFunctionPrefix(__FUNCTION__), file_url));
  return(false);
 }
 array.WriteToFile(file_handle);  //��������� ������ � ����
 FileClose(file_handle);
 return(true);
}

//  LOCAL

//+------------------------------------------------------------------+
/// Search for ticket in History
/// \param [long] ticket       number of ticket to search
/// \return                    true if successful, false if not
//+------------------------------------------------------------------+
bool FindHistoryTicket(long ticket)
{
 int total = HistoryOrdersTotal();
 for(int i = 0; i < total; i++)
 {
  if(ticket == HistoryOrderGetTicket(i)) return true;  
 }
 return false;
}










