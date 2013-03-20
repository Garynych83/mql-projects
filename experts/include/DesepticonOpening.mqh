//+------------------------------------------------------------------+
//|                                            DesepticonOpening.mq4 |
//|                                            Copyright � 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
//|  ������   : 25.02.2013                                           |
//|  �������� : �������� ������ �� �������� ������ ��� �������       |
//|             � �������� �����������                               |
//+------------------------------------------------------------------+
//|  ���������:                                                      |
//|    iDirection - �����������                                      |
//|    timeframe - ���������                                         |
//+------------------------------------------------------------------+ 
#property copyright "��� ����� �. aka KimIV"
#property link  "http://www.kimiv.ru"
#property show_confirm
int DesepticonOpening(int iDirection, int timeframe)
{
 int i, ticket;
 int operation = -1;
 total=OrdersTotal();

 if (iDirection < 0) // ����� ��������� �� Bid ��� ��������� SELLLIMIT
 {
  if (useLimitOrders) operation = OP_SELLLIMIT;
  else if (useStopOrders) operation = OP_SELLSTOP;
       else operation = OP_SELL;

  if (ExistOrders("", -1, _MagicNumber) || ExistPositions("", -1, _MagicNumber)) // ���� ���� �������� ������ ��� �������
  {
   for (i=0; i<total; i++) // ��������� ��� ������ ��� ������� �� �������
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_BUY)   // ������� ������� ������� BUY
      {
       ClosePosBySelect(Bid); // ��������� ������� BUY
       Alert("DesepticonOpening: ������� ����� BUY" );
      }
      if (OrderType()==OP_BUYLIMIT)
      {
       OrderDelete(OrderTicket(), clDelete);
       Alert("DesepticonOpening: ������� ����� BUYLIMIT" );
      }
     }
    }
   }
  }
 } // close ����� ���������
 
 if (iDirection > 0) // ����� �������� �� Ask ��� ��������� BUYLIMIT
 {
  if (useLimitOrders) operation = OP_BUYLIMIT;
  else if (useStopOrders) operation = OP_BUYSTOP;
  else operation = OP_BUY;

  if (ExistOrders("", -1, _MagicNumber) || ExistPositions("", -1, _MagicNumber)) // ���� ���� �������� ������ ��� �������
  {
   for (i=0; i<total; i++) // ��������� ��� ������ ��� ������� �� �������
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_SELL)   // ������� �������� ������� SELL
      {
       ClosePosBySelect(Ask); // ��������� ������� SELL
       Alert("DesepticonOpening: ������� ����� SELL" );
      }
      if (OrderType()==OP_SELLLIMIT)
      {
       OrderDelete(OrderTicket(), clDelete);
       Alert("DesepticonOpening: ������� ����� SELLLIMIT" );
      }
     }
    }
   }
  }
 } // close ����� ��������
 
 total=OrdersTotal();
 if (total <= 0)
 {
  if (useLimitOrders || useStopOrders)
  {
   ticket = SetOrder(NULL, operation, openPlace, timeframe, 0, 0, _MagicNumber);
  } 
  else  ticket = OpenPosition(NULL, operation, openPlace, timeframe, 0, 0, _MagicNumber);
  if (ticket > 0)
  {
  /*
   OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
   ticket = OrderTicket();
   Alert("������� ����� �� ������. ticket=",ticket," OrderExpiration = ", TimeToStr(OrderExpiration(), TIME_DATE),":",TimeToStr(OrderExpiration(), TIME_MINUTES));
  */ 
   return (ticket);
  }
   else return(-1); // ������ ��������
 } 
}

//+----------------------------------------------------------------------------+
//+----------------------------------------------------------------------------+
//|  ������   :                                                      |
//|  �������� : ��������� ������� � ���������� � �����.                       |
//+----------------------------------------------------------------------------+
//|  ���������:                                                                |
//|    symb - ������������ �����������   (NULL ��� "" - ������� ������)        |
//|    operation - ��������                                                    |
//|    Lots - ���                                                              |
//|    sl - ������� ����                                                       |
//|    tp - ������� ����                                                       |
//|    mn - MagicNumber                                                        |
//+----------------------------------------------------------------------------+
int OpenPosition(string symb, int operation, string openPlace, int timeframe, double sl=0, double tp=0, int mn=0, string lsComm="")
 {
  Alert("��������� �������");
  color op_color;
  datetime currentTime, expirationTime;
  double price, pAsk, pBid, vol, addPrice;
  int dg, err, it, ticket=0;

  lots = GetLots();
   
  if (symb=="" || symb=="0") symb=Symbol();
  if (lsComm=="" || lsComm=="0") lsComm=WindowExpertName()+" "+GetNameTF(Period()) + " " + openPlace;
  dg=MarketInfo(symb, MODE_DIGITS);
  vol=MathPow(10.0,dg);
  addPrice=0.0003*vol;

  switch (operation)
  {
   case OP_BUY:
   {
    /*
    stopLoss = Ask - iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 4, 0)) + addPrice*Point; //(���_���� - ���.������� + 30�.)
    if (stopLoss < StopLoss_min*Point) { stopLoss = StopLoss_min*Point; }
    if (stopLoss > StopLoss_max*Point) { stopLoss = StopLoss_max*Point; }
    */
    sl = Bid-stopLoss*Point;
    tp = Ask+takeProfit*Point;
    op_color = clOpenBuy;
    break;
   }
  
   case OP_SELL:
   {
   /*
    stopLoss = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 4, 0)) - Bid + addPrice*Point; //(����_���� - ���.������� + 30�.)
    if (stopLoss < StopLoss_min*Point) { stopLoss = StopLoss_min*Point; }
    if (stopLoss > StopLoss_max*Point) { stopLoss = StopLoss_max*Point; }
   */
    sl = Ask+stopLoss*Point;
    tp = Bid-takeProfit*Point;
    op_color = clOpenSell;
    break;
   }
  } // close switch
  
  for (it=1; it<=NumberOfTry; it++)
  {
   if (!IsTesting() && (!IsExpertEnabled() || IsStopped()))
   {
     Alert("OpenPosition(): ��������� ������ �������");
     break;
   }
   while (!IsTradeAllowed()) Sleep(5000);
   RefreshRates();
   pAsk=MarketInfo(symb, MODE_ASK);
   pBid=MarketInfo(symb, MODE_BID);
   switch (operation)
   {
    case OP_BUY: {price = pAsk; break;}
    case OP_SELL: {price = pBid; break;}
   }
   price=NormalizeDouble(price, dg);
   currentTime=TimeCurrent();
   Alert("stopLoss=", sl, " takeProfit =",tp);
   ticket=OrderSend(symb, operation, lots, price, Slippage, 0, 0, lsComm, mn, 0, op_color);
   if (ticket > 0)
   {
    if (UseSound) PlaySound("expert.wav");
    if(tp != 0 || sl != 0)
     if(OrderSelect(ticket, SELECT_BY_TICKET))
      ModifyOrder(-1, sl, tp);
    break;
   }
   else
   {
    err=GetLastError();
    if (pAsk==0 && pBid==0) Message("��������� � ������ ����� ������� ������� "+symb);
    // ����� ��������� �� ������
    Print("Error(",err,") opening position: ",ErrorDescription(err),", try ",it);
    Print("Ask=",pAsk," Bid=",pBid," symb=",symb," Lots=",lots," operation=",GetNameOP(operation),
          " price=",price," sl=",sl," tp=",tp," mn=",mn);
    // ���������� ������ ���������
    if (err==2 || err==64 || err==65 || err==133) {
      gbDisabled=True; break;
    }
    // ���������� �����
    if (err==4 || err==131 || err==132) {
      Sleep(1000*300); break;
    }
    if (err==128 || err==142 || err==143) {
      Sleep(1000*66.666);
      if (ExistPositions(symb, operation, mn, currentTime)) {
        if (UseSound) PlaySound("expert.wav"); break;
      }
    }
    if (err==140 || err==148 || err==4110 || err==4111) break;
    if (err==141) Sleep(1000*100);
    if (err==145) Sleep(1000*17);
    if (err==146) while (IsTradeContextBusy()) Sleep(1000*11);
    if (err!=135) Sleep(1000*7.7);
   }
  } // close for
  return(ticket);
}

//+----------------------------------------------------------------------------+
//|  �����    : ��� ����� �. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  ������   : 13.03.2008                                                     |
//|  �������� : ��������� ������.                                              |
//+----------------------------------------------------------------------------+
//|  ���������:                                                                |
//|    symb - ������������ �����������   (NULL ��� "" - ������� ������)          |
//|    operation - ��������                                                           |
//|    price - ����                                                               |
//|    sl - ������� ����                                                       |
//|    tp - ������� ����                                                       |
//|    mn - Magic Number                                                       |
//|    expirationTime - ���� ���������                                                     |
//+----------------------------------------------------------------------------+
int SetOrder(string symb, int operation, string openPlace, int timeframe, double sl=0, double tp=0, int mn=0)
{
 color    op_color;
 datetime currentTime, expirationTime;
 double   pAsk, pBid, addPrice, vol, price;
 int      err, it, ticket, stopLevel, dg;
 string   lsComm = WindowExpertName()+" "+GetNameTF(Period());
 
 if (symb=="" || symb=="0") symb = Symbol();
 stopLevel=MarketInfo(symb, MODE_STOPLEVEL);
 dg=MarketInfo(symb, MODE_DIGITS);
 vol=MathPow(10.0,dg);
 addPrice=0.0003*vol;
 lots = GetLots();

 switch (operation)
 {
  case OP_BUYLIMIT:
   expirationTime = TimeCurrent() + 2*timeframe*60;
   sl = (Bid - limitPriceDifference*Point)-stopLoss*Point;
   tp = (Ask + limitPriceDifference*Point)+takeProfit*Point;
   op_color = clOpenBuy;
   break;
  
  case OP_SELLLIMIT:
   expirationTime = TimeCurrent() + 2*timeframe*60;
   sl = (Ask + limitPriceDifference*Point)+stopLoss*Point;
   tp = (Bid - limitPriceDifference*Point)-takeProfit*Point;
   op_color = clOpenSell;
   break;
   
  case OP_BUYSTOP:
   expirationTime = TimeCurrent() + 2*timeframe*60;
   sl = (Bid - stopPriceDifference*Point)-stopLoss*Point;
   tp = (Ask + stopPriceDifference*Point)+takeProfit*Point;
   op_color = clOpenBuy;
   break;
  
  case OP_SELLSTOP:
   expirationTime = TimeCurrent() + 2*timeframe*60;
   sl = (Ask + stopPriceDifference*Point)+stopLoss*Point;
   tp = (Bid - stopPriceDifference*Point)-takeProfit*Point;
   op_color = clOpenSell;
   break;
 } // close switch
 
 if (expirationTime > 0 && expirationTime < TimeCurrent()) expirationTime = 0;
 for (it = 1; it <= NumberOfTry; it++)
 {
  if (!IsTesting() && (!IsExpertEnabled() || IsStopped()))
  {
   Print("SetOrder(): ��������� ������ �������");
   break;
  }
  while (!IsTradeAllowed()) Sleep(5000);
  RefreshRates();
  pAsk=MarketInfo(symb, MODE_ASK);
  pBid=MarketInfo(symb, MODE_BID);
  switch (operation)
  {
   case OP_BUYLIMIT:
    price = pBid - limitPriceDifference*Point;
    break;
   case OP_SELLLIMIT:
    price = pAsk + limitPriceDifference*Point;
    break;
   case OP_BUYSTOP:
    price = pAsk + stopPriceDifference*Point;
    break;
   case OP_SELLSTOP:
    price = pBid - stopPriceDifference*Point;
    break;
  }
  
  price=NormalizeDouble(price, dg);
  currentTime=TimeCurrent();
  ticket=OrderSend(symb, operation, lots, price, Slippage, sl, tp, lsComm, mn, expirationTime, op_color);
  if (ticket>0)
  {
   if (UseSound) PlaySound("expert.wav");
/*   if(tp != 0 || sl != 0)
    if(OrderSelect(ticket, SELECT_BY_TICKET))
     ModifyOrder(-1, sl, tp);*/
   break;
  }
  else
  {
   err=GetLastError();
   if (err==128 || err==142 || err==143)
   {
    Sleep(1000*66);
    if (ExistOrders(symb, operation, mn, currentTime))
    {
     if (UseSound) PlaySound(NameFileSound); break;
    }
    Print("Error(",err,") set order: ",ErrorDescription(err),", try ",it);
    continue;
   }
   pAsk=MarketInfo(symb, MODE_ASK);
   pBid=MarketInfo(symb, MODE_BID);
   if (pAsk==0 && pBid==0) Message("SetOrder(): ��������� � ������ ����� ������� ������� "+symb);
   Print("Error(",err,") set order: ",ErrorDescription(err),", try ",it);
   Print("Ask=",pAsk,"  Bid=",pBid, "  symb=",symb,"  lots=",lots,"  operation=",GetNameOP(operation),
         "  price=",price,"  sl=",sl,"  tp=",tp,"  mn=",mn);
   // ������������ �����
   if (err==130) {
     switch (operation) {
       case OP_BUYLIMIT:
         if (price > pAsk - stopLevel*Point) price = pAsk - stopLevel*Point;
         if (sl > price - (stopLevel+1)*Point) sl = price - (stopLevel+1)*Point;
         if (tp > 0 && tp < price+(stopLevel+1)*Point) tp = price + (stopLevel+1)*Point;
         break;
       case OP_BUYSTOP:
         if (price < pAsk + (stopLevel+1)*Point) price = pAsk + (stopLevel+1)*Point;
         if (sl > price - (stopLevel+1)*Point) sl = price - (stopLevel+1)*Point;
         if (tp > 0 && tp < price + (stopLevel+1)*Point) tp = price + (stopLevel+1)*Point;
         break;
       case OP_SELLLIMIT:
         if (price < pBid + stopLevel*Point) price = pBid + stopLevel*Point;
         if (sl > 0 && sl < price+(stopLevel+1)*Point) sl = price + (stopLevel+1)*Point;
         if (tp > price - (stopLevel+1)*Point) tp = price - (stopLevel+1)*Point;
         break;
       case OP_SELLSTOP:
         if (price > pBid-stopLevel*Point) price = pBid - stopLevel*Point;
         if (sl > 0 && sl < price + (stopLevel+1)*Point) sl = price + (stopLevel+1)*Point;
         if (tp > price - (stopLevel+1)*Point) tp = price - (stopLevel+1)*Point;
         break;
     }
     Print("SetOrder(): ��������������� ������� ������");
   }
   // ���������� ������ ���������
   if (err==2 || err==64 || err==65 || err==133) {
     gbDisabled=True; break;
   }
   // ���������� �����
   if (err==4 || err==131 || err==132) {
     Sleep(1000*300); break;
   }
   // ������� ������ ������� (8) ��� ������� ����� �������� (141)
   if (err==8 || err==141) Sleep(1000*100);
   if (err==139 || err==140 || err==148) break;
   // �������� ������������ ���������� ��������
   if (err==146) while (IsTradeContextBusy()) Sleep(1000*11);
   // ��������� ���� ���������
   if (err==147) {
     expirationTime = 0; continue;
   }
   if (err!=135 && err!=138) Sleep(1000*7.7);
  }
 }
 return(ticket);
}
//+----------------------------------------------------------------------------+