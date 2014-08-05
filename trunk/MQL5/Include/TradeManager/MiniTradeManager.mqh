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

MqlTradeRequest    mtm_pos_req;              // ��������� �������� �������
MqlTradeResult     mtm_pos_res;              // ��� �������� ����������� �������� �������
bool               openedPosition=false; // ���� �������� �������

// ���������� ��������� ������ �� �������
void  SetTradeRequest (MqlTradeRequest &mtr,string symbol, ENUM_ORDER_TYPE type,
                                 double lot, double stopLoss,double takeProfit,
                                 int deviation=3, string comment="ok"                               
                                 )
  {
    mtr.action          = TypeOfOrder(type);
    mtr.symbol          = symbol;
    mtr.volume          = lot;
    mtr.type_filling    = ORDER_FILLING_FOK;
    mtr.sl              = stopLoss;
    mtr.tp              = takeProfit;
    mtr.deviation       = deviation;
    mtr.comment         = comment; 
    
   if (BuyOrSell (type) )  // ���� BUY                 
    {
     mtr.price   = SymbolInfoDouble(symbol,SYMBOL_ASK);   
    }
   else                    // ���� SELL
    {
     mtr.price   = SymbolInfoDouble(symbol,SYMBOL_BID);
    }    
  }
  
// ������� ����� � ���������� ��� ����� � ������ ������
ulong OrderCreate ( MqlTradeRequest &mtr,MqlTradeResult &mt_res)
 {
  ulong ticket = 0;
  if ( OrderSend(mtr,mt_res) ) // ���� ��� ������� ��������� �����
   {
    ticket = mt_res.order;     // ��������� �����
   }
  return (ticket);
 }
// ������������ ����� �� ������ 
bool OrderModify( ulong ticket, MqlTradeRequest &mtr)
 {
  MqlTradeResult tmp_res;
  // ���� ��� ������� ������ �����
  if (OrderSelect(ticket)) 
   {
    return (OrderSend(mtr,tmp_res));
   }
   return (false);
 }
 
// ��������� �������
ulong PositionOpen( string symbol,
                ENUM_POSITION_TYPE type,double lot,
                double stopLoss,double takeProfit,int deviation=3 )
 {
   ENUM_ORDER_TYPE ot;
   MqlTradeRequest pos_req;
   MqlTradeResult  pos_res;
   
   switch (type)
    {
     case POSITION_TYPE_BUY:
      ot = ORDER_TYPE_BUY;
     break;
     case POSITION_TYPE_SELL:
      ot = ORDER_TYPE_SELL;
     break;
    }
   // ���� ������� ��� ���������� �� ������� �������
   if ( PositionSelect (symbol) )
    {
     // ���� ���� ������� ����� ��, ��� � ��� ��������
     if (ENUM_POSITION_TYPE(PositionGetInteger(POSITION_TYPE)) != type)
      return (0); // �� ������ ������� ����� � ������ �� ������
     
    }
   SetTradeRequest(pos_req,symbol,ot,lot,stopLoss,takeProfit,deviation);
   return (OrderCreate (pos_req,pos_res) );
 }

// ��������� �������
  
bool PositionClose (string symbol)
 {
  ulong ticket;
  MqlTradeRequest pos_req;
  MqlTradeResult  pos_res;
  if ( PositionSelect(symbol) )
   {
     if ( ENUM_POSITION_TYPE( PositionGetInteger(POSITION_TYPE) ) == POSITION_TYPE_BUY)
      {
       if (PositionOpen(symbol,POSITION_TYPE_SELL,PositionGetDouble(POSITION_VOLUME),
                       PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP) ) )
          return (true);             
      }  
     else if ( ENUM_POSITION_TYPE( PositionGetInteger(POSITION_TYPE) ) == POSITION_TYPE_SELL)
      {
        if ( PositionOpen(symbol,POSITION_TYPE_BUY,PositionGetDouble(POSITION_VOLUME),
                       PositionGetDouble(POSITION_SL),PositionGetDouble(POSITION_TP) ) )
          return (true);             
      }  
   }
  return (false);  // �� ������� ������� �������
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