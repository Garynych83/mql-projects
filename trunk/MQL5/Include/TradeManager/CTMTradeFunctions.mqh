//+------------------------------------------------------------------+
//|                                            CTMTradeFunctions.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <StringUtilities.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CTMTradeFunctions : public CTrade
{
 public:
  CTMTradeFunctions(void){};
  ~CTMTradeFunctions(void){};
  
  bool OrderOpen(const string symbol,const ENUM_ORDER_TYPE type, const double volume, const double price,
                 const ENUM_ORDER_TYPE_TIME type_time=ORDER_TIME_GTC,const datetime expiration=0,const string comment="");
  bool OrderDelete(const ulong ticket);
  bool PositionOpen(const string symbol,const ENUM_POSITION_TYPE type,const double volume,
                    const double price,const double sl = 0.0,const double tp = 0.0,const string comment = "");
  bool PositionClose(const string symbol, const ENUM_POSITION_TYPE type, const double volume, const ulong deviation=ULONG_MAX);
};

//+------------------------------------------------------------------+
//| ��������� ���������                                              |
//+------------------------------------------------------------------+
bool CTMTradeFunctions::OrderOpen(const string symbol, const ENUM_ORDER_TYPE type, const double volume, const double price,
                                  const ENUM_ORDER_TYPE_TIME type_time=ORDER_TIME_GTC,const datetime expiration=0,const string comment="")
{
 double sl = 0.0, tp = 0.0;
 if(volume<=0.0)
 {
  m_result.retcode=TRADE_RETCODE_INVALID_VOLUME;
  return(false);
 }
 
 if (OrderOpen(symbol,type,volume,0.0,price,sl,tp,type_time,expiration,comment))
 {
  return(true);
 }
 return(false);
}
//+------------------------------------------------------------------+
//| �������� ���������                                               |
//+------------------------------------------------------------------+
bool CTMTradeFunctions::OrderDelete(ulong ticket)
{
  int i = 0;
  int tryNumber = 5;
  bool res = false;
  uint result_code;
  
  ZeroMemory(m_request);
  ZeroMemory(m_result);
  
  m_request.action = TRADE_ACTION_REMOVE;
  m_request.order = ticket;
  //error_list = "";
  
  while (!IsStopped() && i <= tryNumber)
  {
   Print("Current action:", m_request.action);
   res = false;
   if(OrderCheck(m_request,m_check_result)==true)
   {
    ResetLastError();
    PrintFormat("%s �������� ��������, �������� ������� �����, ������� �%d", MakeFunctionPrefix(__FUNCTION__), i+1);
    OrderSend(m_request,m_result);
    switch (m_result.retcode)
    {
     case TRADE_RETCODE_DONE:
      res = true;
      PrintFormat("%s ����� ������� ������", MakeFunctionPrefix(__FUNCTION__));
      break;
     case TRADE_RETCODE_REQUOTE:
     case TRADE_RETCODE_INVALID_STOPS:
     case TRADE_RETCODE_FROZEN:
      Sleep(1000);
     case TRADE_RETCODE_PRICE_CHANGED:
     case TRADE_RETCODE_INVALID_PRICE:
     case TRADE_RETCODE_INVALID:
     default:
      res = false;
      PrintFormat("%s ����� �� ������. ������: %s", MakeFunctionPrefix(__FUNCTION__), ReturnCodeDescription(m_result.retcode));
      break;
    }
    result_code = m_result.retcode;
   }
   else
   {
    result_code = m_check_result.retcode;
   }
   
   if (res) break;
   else
   {
     Print("��� �������� ������ ", ticket, " �������� ������: ", result_code, "; GetLastError() = ", GetLastError(), "; Bid = ", m_result.bid, "; Ask = ", m_result.ask, "; Price = ", m_result.price);
   }
   i++;
  }
  
  return(res);
}

//+-------------------------------------------------------------------------+
//| �������� CTM-�������                                                    |
//+-------------------------------------------------------------------------+
bool CTMTradeFunctions::PositionOpen(const string symbol,const ENUM_POSITION_TYPE type,const double volume,
                                     const double price,const double sl = 0.0,const double tp = 0.0,const string comment = "")
{
 ENUM_ORDER_TYPE order_type;
 if(volume <= 0.0)
 {
  m_result.retcode=TRADE_RETCODE_INVALID_VOLUME;
  return(false);
 }
 switch(type)
 {
  case POSITION_TYPE_BUY:
   order_type = ORDER_TYPE_BUY;
   break;
  case POSITION_TYPE_SELL:
   order_type = ORDER_TYPE_SELL;
   break;
  default:
   Print("������������ ��� �������");
   return(false);
 }
 return(PositionOpen(symbol, order_type, volume, price, sl, tp, comment));
}                                     

//+-------------------------------------------------------------------------+
//| �������� CTM-������� (���������� ��������������� ����� ������� ������)  |
//+-------------------------------------------------------------------------+
bool CTMTradeFunctions::PositionClose(const string symbol, const ENUM_POSITION_TYPE type, const double volume, const ulong deviation=ULONG_MAX)
{
 int tryNumber = 5;

 ZeroMemory(m_request);
 ZeroMemory(m_result);
 ZeroMemory(m_check_result);
 
 while (!IsStopped() && 0 <= tryNumber)
 {
  if(type == POSITION_TYPE_BUY)
  {
   //--- prepare request for close BUY position
   m_request.type =ORDER_TYPE_SELL;
   m_request.price=SymbolInfoDouble(symbol,SYMBOL_BID);
  }
  else
  {
   //--- prepare request for close SELL position
   m_request.type =ORDER_TYPE_BUY;
   m_request.price=SymbolInfoDouble(symbol,SYMBOL_ASK);
  }

  //--- setting request
  m_request.action      =TRADE_ACTION_DEAL;
  m_request.symbol      =symbol;
  m_request.magic       =m_magic;
  m_request.deviation   =(deviation==ULONG_MAX) ? m_deviation : deviation;
  //--- check filling
  if(!FillingCheck(symbol))
   return(false);
  m_request.volume = volume;
  //--- order send
  if(OrderSend(m_request,m_result))
  {
   return(true);
  }
  else
  {
   --tryNumber;
  }
 }

 return(false);
}
