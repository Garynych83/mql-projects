//+------------------------------------------------------------------+
//|                                              crossStochastic.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

input ENUM_MA_METHOD Method = MODE_SMA; // ����� �����������

input double slOrder = 200; // Stop Limit
input double tpOrder = 200; // Take Profit
input double orderVolume = 0.1; // ����� ������
input int kPeriod = 5; // �-������
input int dPeriod = 3; // D-������
input int slov  = 3; // ����������� �������. ��������� �������� �� 1 �� 3.

int totalPositions; // ����� ���������� ������� �� ���������.
int positionType; // ��� �������� ������� �� �������.
int stoHandle; // ��������� �� ���������.
double stoMain[]; // ������ ��� �������� �����.
double stoSignal[]; // ������ ��� ���������� �����.
double price; // ���� ����������� �������.
double point = Point();
ENUM_ORDER_TYPE orderType; // ��� ����������� �������.

int OnInit()
  {   
   if (Method < 0)
   {
    Print("Error: �� �������� ����� �����������!");
    return(-1);  
   }
   
   stoHandle = iStochastic(NULL, 0, kPeriod, dPeriod, slov, Method, STO_LOWHIGH); // ������������� ���������.
   if (stoHandle < 0)
   {
    Print("Error: ����� (���������) �� ���������������!", GetLastError());
    return(-1);
   }
   else Print("������������� ������ (���������) ������ �������!");
   
   ArraySetAsSeries(stoMain, true); // ��������������� ����������� �������.
   ArraySetAsSeries(stoSignal, true);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(stoHandle);
   Print("����� (���������) stoHandle ������");
  }

void OnTick()
  {
   if (CopyBuffer(stoHandle, MAIN_LINE, 0, 50, stoMain) < 0) // ���������� � �������� ������� �������� �����.
   {
    Print("������ ���������� ������� stoMain");
    return;
   }
   if (CopyBuffer(stoHandle, SIGNAL_LINE, 0, 50, stoSignal) < 0) // ���������� � �������� ������� ���������� �����.
   {
    Print("������ ���������� ������� stoSignal");
    return;
   }
   
   totalPositions = PositionsTotal();
   positionType = -1;
   orderType = -1;
   
   for (int i = 0; i < totalPositions; i++)
   {
    if (PositionGetSymbol(i) == _Symbol)
    {
     positionType = (int)PositionGetInteger(POSITION_TYPE);
    }
   }
   
   if (((stoMain[2] > 80) && (stoMain[1] < 80)) || ((stoMain[2] >= stoSignal[2]) && (stoSignal[1] > stoMain[1]))) // ������� ��� ������ ������� (SELL).
   {
    orderType = ORDER_TYPE_SELL;
   }
   if (((stoMain[2] < 20) && (stoMain[1] > 20)) || ((stoSignal[2] >= stoMain[2]) && (stoMain[1] > stoSignal[1]))) // ������� ��� ������ ������� (BUY).
   {
    orderType = ORDER_TYPE_BUY;
   }
   
   if (orderType == ORDER_TYPE_SELL) // ���� �� ������� ����� ����� �� ������ ������� (SELL)
   {
    if (positionType < 0) // ... � ���� ��� �������� �������
    {
     openPosition(orderType); // ... �� ��������� ���� ������� ������� (SELL)
    }
    if (positionType == POSITION_TYPE_BUY) // ���� �� ���� �������� ������� ������� (BUY)
    {
     openPosition(orderType); // ... �� ��������� � (�.�. ������� (BUY))
     openPosition(orderType); // ... � ��������� ������� (SELL)
    }
    if (positionType == POSITION_TYPE_SELL) // ���� ������� ������� (SELL) ��� �������
    {
     return; //�� ����������� � �� �����
    }
   }
   
   if (orderType == ORDER_TYPE_BUY) // ���� �� ������� ����� ����� �� ������ ������� (BUY)
   {
    if (positionType < 0) // ... � ���� ��� �������� �������
    {
     openPosition(orderType); // ... �� ��������� ���� ������� ������� (BUY)
    }
    if (positionType == POSITION_TYPE_SELL) // ���� �� ���� �������� ������� ������� (SELL)
    {
     openPosition(orderType); // ... �� ��������� � (�.�. ������� (SELL))
     openPosition(orderType); // ... � ��������� ������� (BUY)
    }
    if (positionType == POSITION_TYPE_BUY) // ���� ������� ������� (BUY) ��� �������
    {
     return; // �� ����������� � �� �����
    }
   }
  }
  
void openPosition (ENUM_ORDER_TYPE ot)
  {
   double sl = slOrder;
   double tp = tpOrder;
   
   switch (ot)
   {
    case ORDER_TYPE_SELL:
    tp = -tp;
    price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    break;
    case ORDER_TYPE_BUY:
    sl = -sl;
    price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   }
   
   MqlTradeRequest request = {0};
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = orderVolume;
   request.price = price;
   
   if (slOrder == 0)
   {
    request.sl = 0;
   }
   else
   {
    request.sl = request.price + sl*point;
   }
   
   if (tpOrder == 0)
   {
    request.tp = 0;
   }
   else
   {
    request.tp = request.price + tp*point;
   }
   
   request.type = ot;
   request.type_filling = ORDER_FILLING_FOK;
   
   MqlTradeResult result = {0};
   
   if (OrderSend(request, result) == false)
   {
    switch (result.retcode)
    {
     case 10004:
     Print("Error: TRADE_RETCODE_REQUOTE (�������)");
     Print("request.price = ", request.price, " || result.ask = ", result.ask, " || result.bid = ", result.bid);
     break;
     case 10014:
     Print("Error: TRADE_RETCODE_INVALID_VOLUME (������������ ����� � �������)");
     Print("request.volume = ", request.volume, " || result.volume = ", result.volume);
     break;
     case 10015:
     Print("Error: TRADE_RETCODE_INVALID_PRICE (������������ ���� � �������)");
     Print("request.price = ", request.price, " || result.ask = ", result.ask, " || result.bid = ", result.bid);
     break;
     case 10016:
     Print("Error: TRADE_RETCODE_INVALID_STOPS (������������ ����� � �������)");
     Print("request.sl = ", request.sl, " || request.tp = ", request.tp, " || result.ask = ", result.ask, " || result.bid = ", result.bid);
     break;
     case 10019:
     Print("Error: TRADE_RETCODE_NO_MONEY (��� ����������� �������� ������� ��� ���������� �������)");
     Print("request.volume = ", request.volume, " || result.volume = ", result.volume, " || result.comment = ", result.comment);
     break;
    }
   }
  }