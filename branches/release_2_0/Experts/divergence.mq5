//+------------------------------------------------------------------+
//|                                                   divergence.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <divSignals.mqh>
#include <Lib CisNewBar.mqh>

input ENUM_MA_METHOD Method = MODE_SMA; // ����� �����������

input double slOrder = 100;        // Stop Limit
input double tpOrder = 100;        // Take Profit
input double orderVolume = 0.1;   // ����� ������
input int    kPeriod = 5;         // �-������
input int    dPeriod = 3;         // D-������
input int    slov  = 3;           // ����������� �������. ��������� �������� �� 1 �� 3.
input int    deep = 12;           // �������������� ������, ���������� �����.

input int    delta = 2;           // ������ � ����� ����� ������� ������������ ���� � ����������
input double highLine = 80;       // ������� �������� ������� ����������
input double lowLine = 20;        // ������ �������� ������� ����������
input int    firstBarsCount = 3;  // ���������� ������ ����� �� ������� ������ ���������� �������� ��� ������� ����


int totalPositions;        // ����� ���������� ������� �� ���������.
int positionType;          // ��� �������� ������� �� �������.
int divHandle;             // ��������� �� ���������.
int stoHandle;

int firstBar;              // ������ ����, � ������� ���������� ����������.

double mainDiv[];          // ������ �����������/��������� ����������.
double priceDiv[];         // ������ ��� �����������/���������.
double price;              // ���� ����������� �������.
double point = Point();
ENUM_ORDER_TYPE orderType; // ��� ����������� �������.

CisNewBar nb;              // ��������� ������ CisNewBar
divSignals ds;             // ��������� ������ divSignals


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
   
   ArraySetAsSeries(mainDiv, true); // ��������������� ����������� �������.
   ArraySetAsSeries(priceDiv, true);
   
   ds.SetDelta(delta);
   ds.SetHighLineOfStochastic(highLine);
   ds.SetLowLineOfStochastic(lowLine);
   ds.SetFirstBarsCount(firstBarsCount);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(divHandle);
   Print("����� (���������) divHandle ������"); 
   IndicatorRelease(stoHandle);
   Print("����� (���������) stoHandle ������"); 
  }

void OnTick()
  {   
   if (nb.isNewBar() > 0)
   {
   totalPositions = PositionsTotal();
   positionType = -1;
   orderType = -1;
   
   if (CopyClose(_Symbol, 0, 0, deep, priceDiv) < 0) // ���������� � �������� ������� � ������.
   {
    Print("������ ���������� ������� priceDiv");
    return;
   }
   if (CopyBuffer(stoHandle, MAIN_LINE, 0, deep, mainDiv) < 0) // ���������� � �������� ������� �������� �����.
   {
    Print("������ ���������� ������� mainDiv");
    return;
   }
   
   for (int i = 0; i < totalPositions; i++)
   {
    if (PositionGetSymbol(i) == _Symbol)
    {
     positionType = (int)PositionGetInteger(POSITION_TYPE);
    }
   }
   
   firstBar = deep - 1;
   
   if (ds.Divergence(priceDiv, mainDiv, firstBar, deep) == true) // ������� ��� ������ ������� (SELL).
   {
    orderType = ORDER_TYPE_SELL;
   }
   if (ds.Convergence(priceDiv, mainDiv, firstBar, deep) == true) // ������� ��� ������ ������� (BUY).
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