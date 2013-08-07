//+------------------------------------------------------------------+
//|                                         desepticonFlatDivSto.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
 
#include <Lib CisNewBar.mqh>
#include <TradeManager/TradeManager.mqh>

input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;

input ENUM_MA_METHOD methodMASto = MODE_SMA; // ����� �����������

//��������� divSto indicator
input int    kPeriod = 5;          // �-������
input int    dPeriod = 3;          // D-������
input int    slow  = 3;            // ����������� �������. ��������� �������� �� 1 �� 3.
input int    deep = 12;            // �������������� ������, ���������� �����.
input int    delta = 2;            // ������ � ����� ����� ������� ������������ ���� � ����������
input double highLine = 80;        // ������� �������� ������� ����������
input double lowLine = 20;         // ������ �������� ������� ����������
input int    firstBarsCount = 3;   // ���������� ������ ����� �� ������� ������ ���������� �������� ��� ������� ����
//��������� ������
input double orderVolume = 0.1;    // ����� ������
input double slOrder = 100;        // Stop Loss
input double tpOrder = 100;        // Take Profit
input int    trStop = 100;         // Trailing Stop
input int    trStep = 100;         // Trailing Step
input int    prDifference = 10;    // Price Difference

input bool   useTrailing = false;
input bool   useJrEMAExit = false; // ����� �� �������� �� ���
input int    minProfit = 100;      // ����������� �������
input int    posLifeTime = 10;     // ����� �������� ������ � �����
input int    deltaPriceToEMA = 7;  // ������� ����� ����� � EMA
input int    periodEMA = 3;        // ������ ���������� EMA
input int    waitAfterDiv = 2;     // �������� ������ ����� ����������� (� �����)
//��������� PriceBased indicator
input int    historyDepth = 40;    // ������� ������� ��� �������
input int    bars=30;              // ������� ������ ����������

int    trendHandle;
int    divStoHandle;
int    emaHandle;

datetime history_start;

double divStoBuffer[];             // ������ �������� ����� ����������.
double trendBuffer[];
double emaBuffer[];


bool   isProfit = false;           // ���� ���������� ������ � ����������� ��������

CisNewBar eldNewBar(eldTF);
CTradeManager tradeManager;

int OnInit()
{
 trendHandle = iCustom(NULL, 0, "PriceBasedIndicator", historyDepth, bars);
 divStoHandle = iCustom(NULL, 0, "div", methodMASto, kPeriod, dPeriod, slow, deep, delta, highLine, lowLine, firstBarsCount);
 emaHandle = iMA(NULL, 0, periodEMA, 0, MODE_EMA, PRICE_CLOSE); 
   
 if (trendHandle == INVALID_HANDLE || divStoHandle == INVALID_HANDLE || emaHandle == INVALID_HANDLE)
 {
  Print("Error: INVALID_HANDLE (trendHandle || divStoHandle || emaHandle)", GetLastError());
  return(INIT_FAILED);
 }
  
 ArraySetAsSeries(divStoBuffer, true);
 ArraySetAsSeries(trendBuffer, true);
 ArraySetAsSeries(emaBuffer, true);
 ArrayResize(divStoBuffer, waitAfterDiv, waitAfterDiv*3);
 ArrayResize(trendBuffer, 1, 3);
 ArrayResize(emaBuffer, 2, 6);
  
 history_start = TimeCurrent();        //--- �������� ����� ������� �������� ��� ��������� �������� �������
 
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 IndicatorRelease(trendHandle); 
 IndicatorRelease(divStoHandle);
 IndicatorRelease(emaHandle);
 ArrayFree(divStoBuffer);
 ArrayFree(trendBuffer);
 ArrayFree(emaBuffer);
 Print("������ (���������) � ������� �������");
}

void OnTick()
{
 int totalPositions = PositionsTotal();
 int positionType = -1;
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 for (int i = 0; i < totalPositions; i++)
 {
  if (PositionGetSymbol(i) == _Symbol)
  {
   positionType = (int)PositionGetInteger(POSITION_TYPE);
   if (positionType == POSITION_TYPE_BUY)
   {
    if (!isProfit && ask - PositionGetDouble(POSITION_PRICE_OPEN) >= minProfit*point)
    {
     isProfit = true;
    }
    if (useJrEMAExit)
    {
     // ����� �� �������� ���
    }
   }
   if (positionType == POSITION_TYPE_SELL)
   {
    if (!isProfit && PositionGetDouble(POSITION_PRICE_OPEN) - bid >= minProfit*point)
    {
     isProfit = true;
    }
    if (useJrEMAExit)
    {
     // ����� �� �������� ���
    }
   }
  }
 }
   
 if (eldNewBar.isNewBar() > 0)
 {
  if (!isProfit)
  {
   if ((positionType > -1) && (TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF)))
   {
    //close position
   }
  }
  
  if ((CopyBuffer(divStoHandle, 1, 1, waitAfterDiv, divStoBuffer) < 0))
  {
   log_file.Write(LOG_DEBUG, "������ ���������� ������� divStoBuffer");
   return;
  }
  if (CopyBuffer(trendHandle, 4, 1, 1, trendBuffer) < 0)
  {
   log_file.Write(LOG_DEBUG, "������ ���������� ������� trendHandle");
   return;
  }
  if (CopyBuffer(emaHandle, 0, 0, 2, emaBuffer) < 0)
  {
   log_file.Write(LOG_DEBUG, "������ ���������� ������� emaHandle");
   return;
  }
   
  if (trendBuffer[0] == 7)
  {   
   for (int i = 0; i < waitAfterDiv; i++)
   {
    if (divStoBuffer[i] == 1)
    {
     if (ask < (emaBuffer[0] - deltaPriceToEMA*point))
     {
      log_file.Write(LOG_DEBUG, "����� � �������");
      if (tradeManager.OpenPosition(_Symbol, OP_BUY, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, prDifference))
      {
       isProfit = false;
      }
      else
      {
       log_file.Write(LOG_DEBUG, "������� ������� �� �������");
      }
     }
    }     
    if (divStoBuffer[i] == 0)
    {
     if (bid > (emaBuffer[0] + deltaPriceToEMA*point))
     {
      log_file.Write(LOG_DEBUG, "����� � �������");
      if (tradeManager.OpenPosition(_Symbol, OP_SELL, orderVolume, slOrder, tpOrder, minProfit, trStop, trStep, prDifference))
      {
       isProfit = false;
      }
      else
      {
       log_file.Write(LOG_DEBUG, "������� ������� �� �������");
      }
     }
    }
   }
  } // close trendBuffer[0] == 7
 } // close newBar
 if (useTrailing)
 {
  tradeManager.DoTrailing();
 }
} // close OnTick

void OnTrade()
{
 tradeManager.OnTrade(history_start);
}