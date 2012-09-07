//+------------------------------------------------------------------+
//|                                                      Opening.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int DesepticonOpening(string symb, int operation, string openPlace, int timeframe, double sl=0, double tp=0, int mn=0)
{
  double price;
  color op_color;
  Lots = GetLots();
  if (symb=="" || symb=="0") symb=Symbol();
  
  if (operation == 0)
  {
   price = Ask;
   StopLoss = Ask - iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 4, 0)) + 30*Point; //(���_���� - ���.������� + 30�.)
   if (StopLoss < StopLoss_min*Point) { StopLoss = StopLoss_min*Point; }
   if (StopLoss > StopLoss_max*Point) { StopLoss = StopLoss_max*Point; }
   sl = Bid-StopLoss;
   tp = Ask+TakeProfit*Point;
   op_color = clOpenBuy;
  }
  
  if (operation == 1)
  {
   price = Bid;
   StopLoss = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 4, 0)) - Bid + 30*Point; //(����_���� - ���.������� + 30�.)
   if (StopLoss < StopLoss_min*Point) { StopLoss = StopLoss_min*Point; }
   if (StopLoss > StopLoss_max*Point) { StopLoss = StopLoss_max*Point; }
   sl = Ask+StopLoss;
   tp = Bid-TakeProfit*Point;
   op_color = clOpenSell;
  }
  
  Alert (openPlace, " ����������� �� ", timeframe, "-�������� �� ",  " _MagicNumber ", _MagicNumber);
  Alert("buyCondition=",buyCondition," sellCondition=",sellCondition
  //, " buy_condition = ", buy_condition, " sell_condition=",sell_condition
  );
  //Alert(" wantToOpen[0]=",wantToOpen[frameIndex][0], "  wantToOpen[1]=",wantToOpen[frameIndex][1]);
  //Alert(" wantToOpen[0]=",wantToOpen[frameIndex+1][0], "  wantToOpen[1]=",wantToOpen[frameIndex+1][1]);
  ticket = OrderSend(symb, operation, Lots, price, Slippage, sl, tp, "MACD_test", _MagicNumber, 0, op_color);
  if(ticket < 0 ) //���� �� ������ ���������
  {
   _GetLastError = GetLastError();
   Alert("?????? OrderSend ? ", _GetLastError);
   return (-1);
  } // close ���� �� ������ ���������
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   wantToOpen[frameIndex][0] = 0;
   wantToOpen[frameIndex][1] = 0;
   //Alert("�������� wantToOpen. wantToOpen[0]=",wantToOpen[frameIndex][0], "  wantToOpen[1]=",wantToOpen[frameIndex][1]);
   barsCountToBreak[frameIndex][0] = 0;
   barsCountToBreak[frameIndex][1] = 0;
  }
  return (1);
}

//+----------------------------------------------------------------------------+
//|  �����    : ��� ����� �. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  ������   : 21.03.2008                                                     |
//|  �������� : ��������� ������� � ���������� � �����.                       |
//+----------------------------------------------------------------------------+
//|  ���������:                                                                |
//|    symb - ������������ �����������   (NULL ��� "" - ������� ������)          |
//|    operation - ��������                                                           |
//|    Lots - ���                                                                |
//|    sl - ������� ����                                                       |
//|    tp - ������� ����                                                       |
//|    mn - MagicNumber                                                        |
//+----------------------------------------------------------------------------+
int OpenPosition(string symb, int operation, string openPlace, int timeframe, double sl=0, double tp=0, int mn=0, string lsComm="")
 {
  color op_color;
  datetime ot;
  double   price, pAsk, pBid;
  int      dg, err, it, ticket=0;
  
  Lots = GetLots();
   
  if (symb=="" || symb=="0") symb=Symbol();
  if (lsComm=="" || lsComm=="0") lsComm=WindowExpertName()+" "+GetNameTF(Period()) + " " + openPlace;
  
  if (operation == OP_BUY)
  {
   price = Ask;
   StopLoss = Ask - iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 4, 0)) + 30*Point; //(���_���� - ���.������� + 30�.)
   if (StopLoss < StopLoss_min*Point) { StopLoss = StopLoss_min*Point; }
   if (StopLoss > StopLoss_max*Point) { StopLoss = StopLoss_max*Point; }
   sl = Bid-StopLoss;
   tp = Ask+TakeProfit*Point;
   op_color = clOpenBuy;
  }
  
  if (operation == OP_SELL)
  {
   price = Bid;
   StopLoss = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 4, 0)) - Bid + 30*Point; //(����_���� - ���.������� + 30�.)
   if (StopLoss < StopLoss_min*Point) { StopLoss = StopLoss_min*Point; }
   if (StopLoss > StopLoss_max*Point) { StopLoss = StopLoss_max*Point; }
   sl = Ask+StopLoss;
   tp = Bid-TakeProfit*Point;
   op_color = clOpenSell;
  }
  
  for (it=1; it<=NumberOfTry; it++)
  {
   if (!IsTesting() && (!IsExpertEnabled() || IsStopped()))
   {
     Print("OpenPosition(): ��������� ������ �������");
     break;
   }
   while (!IsTradeAllowed()) Sleep(5000);
   RefreshRates();
   dg=MarketInfo(symb, MODE_DIGITS);
   pAsk=MarketInfo(symb, MODE_ASK);
   pBid=MarketInfo(symb, MODE_BID);
   if (operation==OP_BUY) price=pAsk; else price=pBid;
   price=NormalizeDouble(price, dg);
   ot=TimeCurrent();
   ticket=OrderSend(symb, operation, Lots, price, Slippage, sl, tp, lsComm, mn, 0, op_color);
   if (ticket>0)
   {
    if (UseSound) PlaySound("expert.wav");
    break;
   }
   else
   {
    err=GetLastError();
    if (pAsk==0 && pBid==0) Message("��������� � ������ ����� ������� ������� "+symb);
    // ����� ��������� �� ������
    Print("Error(",err,") opening position: ",ErrorDescription(err),", try ",it);
    Print("Ask=",pAsk," Bid=",pBid," symb=",symb," Lots=",Lots," operation=",GetNameOP(operation),
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
      if (ExistPositions(symb, operation, mn, ot)) {
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