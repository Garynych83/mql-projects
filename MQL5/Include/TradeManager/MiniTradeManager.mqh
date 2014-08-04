//+------------------------------------------------------------------+
//|                                             MiniTradeManager.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ���������� �������� ������� mini Trade Manager                   |
//+------------------------------------------------------------------+

// ��������� ���������� �������� ����������

MqlTradeRequest    mtm_req;        // ��������� �������� ������
MqlTradeResult     mtm_res;        // ��� �������� �����������

bool OrderOpen (string symbol,
                ENUM_ORDER_TYPE type,double lot,
                double stopLoss,double takeProfit,int deviation=3
                ) 
                   // ������� �������� �������
 {  
   mtm_req.action       = TypeOfOrder(type);                   // ��� ������ (����������� ��� ����������)
   mtm_req.symbol       = symbol;                              // ������
   mtm_req.volume       = lot;                                 // ���
   mtm_req.type         = type;                                // ��� ������
   mtm_req.type_filling = ORDER_FILLING_FOK;                   // ��� ����������
   mtm_req.sl=stopLoss;                                        // ���� ����
   mtm_req.tp=takeProfit;                                      // ���� ������
   mtm_req.deviation=deviation;                                // ����������
   mtm_req.comment="Everything is okay";                       // �����������
   if (BuyOrSell (type) )  // ���� BUY                 
    {
     mtm_req.price   = SymbolInfoDouble(symbol,SYMBOL_ASK);   
    }
   else                    // ���� SELL
    {
     mtm_req.price   = SymbolInfoDouble(symbol,SYMBOL_BID);
    }
   // ���������� ����� �� ������ 
   if(OrderSend(mtm_req,mtm_res))
     {
      Print("Sent...");
     }
   Print("ticket =",mtm_res.order,"   retcode =",mtm_res.retcode);
   if(mtm_res.order != 0)
     {
      datetime tm=TimeCurrent();
      HistorySelect(0,tm);
      string comment;
      bool result=HistoryOrderGetString(mtm_res.order,ORDER_COMMENT,comment);
      if(result)
        {
         Print("ticket:",mtm_res.order,"    Comment:",comment);
        }
      else
        {
         Print("failed");  
         return (false);   // ����� �� ��������
        }
     }
   return (true);   // ����� ������� ��������� �� ������
 }
 
bool PositionOpen(string symbol,
                ENUM_POINTER_TYPE type,double lot,
                double stopLoss,double takeProfit,int deviation=3)  // �������� ��������� �������
 {
  return ( OrderOpen(
 }
 
bool PositionClose() // ������� �������� �������
 {
  return (false);
 }
 
bool BuyOrSell (ENUM_ORDER_TYPE type) // ���������� true - ���� buy, � false, ���� sell
 {
  switch (type)
   {
    case ORDER_TYPE_BUY:
    case ORDER_TYPE_BUY_LIMIT:
    case ORDER_TYPE_BUY_STOP:
    case ORDER_TYPE_BUY_STOP_LIMIT:
     return (true);
   }
  return (false);
 }
 
ENUM_TRADE_REQUEST_ACTIONS TypeOfOrder (ENUM_ORDER_TYPE type) // ���������� ��� ������
 {
  switch (type)
   {
    case ORDER_TYPE_BUY:
    case ORDER_TYPE_SELL:
     return (TRADE_ACTION_DEAL);  // ����������� ����������
   }
  return (TRADE_ACTION_PENDING);  // ����������
 }