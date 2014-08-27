//+------------------------------------------------------------------+
//|                                           TradeManager Enums.mqh |
//|                                                    Copyright GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"

//+------------------------------------------------------------------+
/// Similar enum to ENUM_ORDER_TYPE.
//+------------------------------------------------------------------+
enum ENUM_USE_PENDING_ORDERS 
 { 
  USE_LIMIT_ORDERS=0, //������������ ����� ������
  USE_STOP_ORDERS,    //������������ ���� ������
  USE_NO_ORDERS       //�� ������������ �����������
 };
 
//+------------------------------------------------------------------+
/// Similar enum to ENUM_ORDER_TYPE.
//+------------------------------------------------------------------+
enum ENUM_TM_POSITION_TYPE
  {
   OP_BUY,           //������� 
   OP_SELL,          //������� 
   OP_BUYLIMIT,      //���������� ����� BUY LIMIT 
   OP_SELLLIMIT,     //���������� ����� SELL LIMIT 
   OP_BUYSTOP,       //���������� ����� BUY STOP 
   OP_SELLSTOP,      //���������� ����� SELL STOP
   OP_UNKNOWN       //��� ������������� ��� ������
  };
  
//+------------------------------------------------------------------+
/// ENUM_ORDER_TYPE to ENUM_TM_POSITION_TYPE.
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE OrderTypeToTMPositionType(ENUM_ORDER_TYPE type)
{
 switch (type)
 {
  case ORDER_TYPE_BUY        : return(OP_BUY);
  case ORDER_TYPE_SELL       : return(OP_SELL);
  case ORDER_TYPE_BUY_LIMIT  : return(OP_BUYLIMIT);
  case ORDER_TYPE_SELL_LIMIT : return(OP_SELLLIMIT);
  case ORDER_TYPE_BUY_STOP   : return(OP_BUYSTOP);
  case ORDER_TYPE_SELL_STOP  : return(OP_SELLSTOP);
  default          : return(OP_UNKNOWN);
 }
}

//+------------------------------------------------------------------+
/// string to ENUM_ORDER_TYPE
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE StringToOrderType(string str)
{
 ENUM_ORDER_TYPE result;
 if(str == "ORDER_TYPE_BUY_LIMIT" )result = ORDER_TYPE_BUY_LIMIT;
 if(str == "ORDER_TYPE_SELL_LIMIT")result = ORDER_TYPE_SELL_LIMIT;
 if(str == "ORDER_TYPE_BUY_STOP"  )result = ORDER_TYPE_BUY_STOP;
 if(str == "ORDER_TYPE_SELL_STOP" )result = ORDER_TYPE_SELL_STOP;
 return(result);
}
//+------------------------------------------------------------------+ 
// ������� �������� �������� �������� �� �� ������
//+------------------------------------------------------------------+
string GetNameOP(ENUM_TM_POSITION_TYPE op)
{
 switch (op)
 {
  case OP_BUY      : return("Buy");
  case OP_SELL     : return("Sell");
  case OP_BUYLIMIT : return("Buy Limit");
  case OP_SELLLIMIT: return("Sell Limit");
  case OP_BUYSTOP  : return("Buy Stop");
  case OP_SELLSTOP : return("Sell Stop");
  default          : return("Unknown Operation");
 }
};

//+------------------------------------------------------------------+
/// Converts Virtual Order string name to enum
/// \param [in]   strVirtualOrderType
/// \return ENUM_VIRTUAL_ORDER_TYPE      
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE StringToPositionType(string posType)
  {
   if(posType == "Buy") return(OP_BUY);
   if(posType == "Sell") return(OP_SELL);
   if(posType == "Buy Limit") return(OP_BUYLIMIT);
   if(posType == "Sell Limit") return(OP_SELLLIMIT);
   if(posType == "Buy Stop") return(OP_BUYSTOP);
   if(posType == "Sell Stop") return(OP_SELLSTOP);   
   return(OP_UNKNOWN);
  }

//+------------------------------------------------------------------+
/// Tracks status of virtual orders.
//+------------------------------------------------------------------+
enum ENUM_POSITION_STATUS
  {
   POSITION_STATUS_OPEN,
   POSITION_STATUS_PENDING,
   POSITION_STATUS_CLOSED,
   POSITION_STATUS_DELETED,
   POSITION_STATUS_NOT_DELETED,       
   POSITION_STATUS_NOT_CHANGED,       // �� ������� �������� �������� ��� ��������� ������ �������
   POSITION_STATUS_NOT_INITIALISED,   // ������ ������� ����������, �� �������� ������� ���
   POSITION_STATUS_NOT_COMPLETE,      // �� ������ ���������� ����-���� ��� ����-������  
   POSITION_STATUS_MUST_BE_REPLAYED,  // ������� ������ ����������
   POSITION_STATUS_READY_TO_REPLAY,   // ������� ������ � ��������
   POSITION_STATUS_ON_REPLAY
  };
//+------------------------------------------------------------------+
/// Returns string description of ENUM_POSITION_STATUS.                                                                 
/// \param [in]   ENUM_POSITION_STATUS enumVirtualOrderStatus
/// \return       string description of enumVirtualOrderType
//+------------------------------------------------------------------+
string PositionStatusToStr(ENUM_POSITION_STATUS enumPositionStatus)
  {
   switch(enumPositionStatus)
     {
      case POSITION_STATUS_OPEN: return("open");
      case POSITION_STATUS_PENDING: return("pending");
      case POSITION_STATUS_CLOSED: return("closed");
      case POSITION_STATUS_DELETED: return("deleted");
      case POSITION_STATUS_NOT_DELETED: return("not deleted");
      case POSITION_STATUS_NOT_CHANGED: return("not changed");
      case POSITION_STATUS_NOT_INITIALISED: return("not initialised");
      case POSITION_STATUS_NOT_COMPLETE: return("not completed");
      case POSITION_STATUS_MUST_BE_REPLAYED: return("must be replayed");
      case POSITION_STATUS_READY_TO_REPLAY: return ("ready to replay");            
      default: return("Error: unknown virtual order status "+(string)enumPositionStatus);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS StringToPositionStatus(string posStatus)
  {
   if(posStatus=="open")   return(POSITION_STATUS_OPEN);
   if(posStatus=="closed") return(POSITION_STATUS_CLOSED);
   if(posStatus=="deleted")return(POSITION_STATUS_DELETED);
   return(POSITION_STATUS_NOT_INITIALISED);
  }

//+------------------------------------------------------------------+
/// Status of stoplevels
//+------------------------------------------------------------------+
enum ENUM_STOPLEVEL_STATUS
  {
   STOPLEVEL_STATUS_NOT_DEFINED,
   STOPLEVEL_STATUS_PLACED,
   STOPLEVEL_STATUS_NOT_PLACED,
   STOPLEVEL_STATUS_DELETED,
   STOPLEVEL_STATUS_NOT_DELETED
  };
  
//+------------------------------------------------------------------+
/// Returns string description of ENUM_STOPLEVEL_STATUS.                                                                 
/// \param [in]   ENUM_POSITION_STATUS enumVirtualOrderStatus
/// \return       string description of enumVirtualOrderType
//+------------------------------------------------------------------+
string StoplevelStatusToStr(ENUM_STOPLEVEL_STATUS enumStoplevelStatus)
  {
   switch(enumStoplevelStatus)
     {
      case STOPLEVEL_STATUS_NOT_DEFINED: return("not definned");
      case STOPLEVEL_STATUS_PLACED     : return("placed");
      case STOPLEVEL_STATUS_NOT_PLACED : return("not placed");
      case STOPLEVEL_STATUS_DELETED    : return("deleted");
      case STOPLEVEL_STATUS_NOT_DELETED: return("not deleted");           
      default: return("Error: unknown virtual order status "+(string)enumStoplevelStatus);
     }
  }
  
ENUM_STOPLEVEL_STATUS StringToStoplevelStatus(string str)
{
  if(str == "not definned") return(STOPLEVEL_STATUS_NOT_DEFINED);
  if(str == "placed"      ) return(STOPLEVEL_STATUS_PLACED);
  if(str == "not placed"  ) return(STOPLEVEL_STATUS_NOT_PLACED);
  if(str == "deleted"     ) return(STOPLEVEL_STATUS_DELETED);
  if(str == "not deleted" ) return(STOPLEVEL_STATUS_NOT_DELETED);
  
  return(STOPLEVEL_STATUS_NOT_DEFINED);           
}
  
enum ENUM_FILENAME
  {
   FILENAME_RESCUE,
   FILENAME_HISTORY
  };

//+------------------------------------------------------------------+
/// Used by CTradeManager::OrderSelect()
/// Similar to MT4
//+------------------------------------------------------------------+
enum ENUM_SELECT_MODE
  {
   MODE_TRADES, ///< Select from CVirtualOrdermanager::m_OpenOrders
   MODE_HISTORY ///< Select from CVirtualOrdermanager::m_OrderHistory
  };
  
//+------------------------------------------------------------------+
/// Position trailing types
//+------------------------------------------------------------------+
enum ENUM_TRAILING_TYPE
  {
   TRAILING_TYPE_NONE,
   TRAILING_TYPE_USUAL,
   TRAILING_TYPE_LOSSLESS,
   TRAILING_TYPE_PBI,
   TRAILING_TYPE_EXTREMUMS
  };

//+------------------------------------------------------------------+ 
// ������� �������� �������� ���� ��������� �� ��� ������
//+------------------------------------------------------------------+
string GetNameTrailing(ENUM_TRAILING_TYPE type)
{
 switch (type)
 {
  case TRAILING_TYPE_NONE    : return("NONE");
  case TRAILING_TYPE_USUAL   : return("USUAL");
  case TRAILING_TYPE_LOSSLESS: return("LOSSLESS");
  case TRAILING_TYPE_PBI     : return("PBI");
  default                    : return("Unknown trailing type");
 }
};

//+------------------------------------------------------------------+ 
// ������� �������� ���� ��������� �� ��� ��������
//+------------------------------------------------------------------+
ENUM_TRAILING_TYPE StringToTrailingType(string str)
{
 if(str == "NONE"    ) return(TRAILING_TYPE_NONE);
 if(str == "USUAL"   ) return(TRAILING_TYPE_USUAL);
 if(str == "LOSSLESS") return(TRAILING_TYPE_LOSSLESS);
 if(str == "PBI"     ) return(TRAILING_TYPE_PBI);
 return(TRAILING_TYPE_NONE);
};
  
//+------------------------------------------------------------------+
/// Used by CTradeManager::OrderSelect()
/// Similar to MT4
//+------------------------------------------------------------------+
enum ENUM_SELECT_TYPE
  {
   SELECT_BY_POS,
   SELECT_BY_TICKET
  };
  
//+------------------------------------------------------------------+
/// ��������� ������� ������� �� �������
//+------------------------------------------------------------------+
class ReplayPos
{
 public:  
  string symbol;               //������ 
  double price_open;           //���� ��������
  double price_close;          //���� ��������
  double profit;               //������ �������
  ENUM_POSITION_STATUS status; //������ �������
  ENUM_TM_POSITION_TYPE type;  //��� �������
};

//+------------------------------------------------------------------+
/// ��������� ���������� �� �������
//+------------------------------------------------------------------+
struct SPositionInfo
{
 ENUM_TM_POSITION_TYPE type;   // ��� �������/������
 double volume;                // ����� �������/������
 int sl;                       // �������� � �������
 int tp;                       // ����������
 int priceDifference;          // ������� �� ���� ��� ���������� ������� � �������
 int expiration;               // ����� ����� ����������� ������ � ����� (0 - ����� �� ��� ��� ���� ���� �� ������)
 datetime expiration_time;     // ����� ��������� ����� ����������� ������(����������� � ������������ CPosition)
};

//+------------------------------------------------------------------+
/// ��������� ������� ���������
//+------------------------------------------------------------------+
struct STrailing
{
 ENUM_TRAILING_TYPE trailingType;
 int minProfit;
 int trailingStop;
 int trailingStep;
 int handlePBI;
};


