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

MqlTradeRequest    mtm_req;              // ��������� �������� ������
MqlTradeResult     mtm_res;              // ��� �������� �����������
bool               openedPosition=false; // ���� �������� �������


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
   mtm_req.sl           = stopLoss;                            // ���� ����
   mtm_req.tp           = takeProfit;                          // ���� ������
   mtm_req.deviation    = deviation;                           // ����������
  // mtm_req.magic        = ;                                    // 
   mtm_req.comment      = "Everything is okay";                // �����������
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
                ENUM_POSITION_TYPE type,double lot,
                double stopLoss,double takeProfit,int deviation=3)  // ������� ��������� �������
 {
  switch (type)
   {
    case POSITION_TYPE_BUY:
     if (!openedPosition || mtm_req.order == ORDER_TYPE_SELL)
       {
        if (OrderOpen(symbol,ORDER_TYPE_BUY,lot,stopLoss,takeProfit,deviation))
          {
           openedPosition = true;
           return (true);
          }
       }
    case POSITION_TYPE_SELL:
     if (!openedPosition || mtm_req.order == ORDER_TYPE_BUY)
       {
        if (OrderOpen(symbol,ORDER_TYPE_SELL,lot,stopLoss,takeProfit,deviation))
          {
           openedPosition = true;
           return (true);
          }
       }
   }
  return (false);
 }
 
bool PositionClose() // ������� �������� �������
 {
  // ���� ���� �������� �������
  if (openedPosition)
   {
    if ( BuyOrSell(mtm_req.type) )  // ���� BUY
      {
       PositionOpen(mtm_req.symbol, POSITION_TYPE_SELL,
                    mtm_req.volume, 0,0,mtm_req.deviation);
      }
    else                            // ���� SELL
      {
       PositionOpen(mtm_req.symbol, POSITION_TYPE_BUY,
                    mtm_req.volume, 0,0,mtm_req.deviation);   
      }
   }
  return (false);
 }
 
bool ChangeStopLoss (double stopLoss)  // ������� �������� ���� ���� �������
 {
  double prevStop = mtm_req.sl;
  // ���� ���� �������� �������
  if (openedPosition)
   {
    mtm_req.action=TRADE_ACTION_SLTP;       
    mtm_req.sl = stopLoss;
    if ( OrderSend(mtm_req,mtm_res) )
     {
      Print("���� ���� �������");
      return (true);
     }
    mtm_req.sl = prevStop; 
   }
  return (false); // �� ������� �������� ���� ����
 } 
 
bool ChangeTakeProfit (double takeProfit)  // ������� �������� ���� ������ �������
 {
  double prevTake = mtm_req.tp;
  // ���� ���� �������� �������
  if (openedPosition)
   {
    mtm_req.action=TRADE_ACTION_SLTP;       
    mtm_req.tp = takeProfit;
    if ( OrderSend(mtm_req,mtm_res) )
     {
      Print("���� ������ �������");
      return (true);
     }
    mtm_req.tp = prevTake; 
   }
  return (false); // �� ������� �������� ���� ������
 }  
 
bool ChangeLot (double lot)  // ������� �������� ��� �������
 {
  double prevLot = mtm_req.volume;
  // ���� ���� �������� �������
  if (openedPosition)
   {
    mtm_req.action=TRADE_ACTION_MODIFY;       
    mtm_req.volume = lot;
    mtm_req.sl = 1.373;
    mtm_req.tp = 1.38;
    if ( OrderSend(mtm_req,mtm_res) )
     {
      Print("����� ������� �������");
      return (true);
     }
    mtm_req.volume = lot; 
   }
  return (false); // �� ������� �������� ���� ������
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