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

int    handleTrend;
int    handleEMA;
double bufferTrend[];
double bufferEMA[];

datetime history_start;

CisNewBar eldNewBar(eldTF);
CTradeManager tradeManager;

int OnInit()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s �����������.", MakeFunctionPrefix(__FUNCTION__)));
 history_start = TimeCurrent();        //--- �������� ����� ������� �������� ��� ��������� �������� �������
 handleTrend =  iCustom(NULL, 0, "PriceBasedIndicator", historyDepth, bars);
 handleEMA = iMA(NULL, 0, periodEMA, 0, MODE_EMA, PRICE_CLOSE); 
   
 if (handleTrend == INVALID_HANDLE || handleEMA == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend || handleEMA). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  return(INIT_FAILED);
 }
  
 ArraySetAsSeries(bufferTrend, true);
 ArraySetAsSeries(bufferEMA, true);;
 ArrayResize(bufferTrend, 1, 3);
 ArrayResize(bufferEMA, 2, 6);
   
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 IndicatorRelease(handleTrend); 
 IndicatorRelease(handleEMA);
 ArrayFree(bufferTrend);
 ArrayFree(bufferEMA);
 log_file.Write(LOG_DEBUG, StringFormat("%s �������������.", MakeFunctionPrefix(__FUNCTION__)));
}

void OnTick()
{
 int totalPositions = PositionsTotal();
 int positionType = -1;
 static bool isProfit = false;
 static int  wait = 0;
 double point = Point();
 double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 
 for (int i = 0; i < totalPositions; i++)    //���� �� ���� ��������
 {
  if (PositionGetSymbol(i) == _Symbol)       //���� ���� ������� �� ������� �������
  {
   positionType = (int)PositionGetInteger(POSITION_TYPE);
   switch (positionType)         //��������� �� ������������ minProfit � ������� �� ������� EMA
   {
    case POSITION_TYPE_BUY:
    {
     if (!isProfit && ask - PositionGetDouble(POSITION_PRICE_OPEN) >= minProfit*point)
     {
      isProfit = true;
     }
     if (useJrEMAExit)
     {
      // ����� �� �������� ���
     }
     break;
    }
    case POSITION_TYPE_SELL:
    {
     if (!isProfit && PositionGetDouble(POSITION_PRICE_OPEN) - bid >= minProfit*point)
     {
      isProfit = true;
     }
     if (useJrEMAExit)
     {
      // ����� �� �������� ���
     }
     break;
    }    
   }
  }
 }
   
 if (eldNewBar.isNewBar() > 0)   //�� ������ ����� ���� �������� TF
 {
  if (!isProfit && positionType > -1 && TimeCurrent() - PositionGetInteger(POSITION_TIME) > posLifeTime*PeriodSeconds(eldTF))
  { //���� �� �������� minProfit �� ������ �����
     //close position 
  }
  
  if ((CopyBuffer( handleTrend, 4, 1, 1,  bufferTrend) < 0) ||
      (CopyBuffer(   handleEMA, 0, 0, 2,    bufferEMA) < 0) )   //�������� ������ �����������
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ������. (divStoBuffer || bufferTrend || bufferEMA).Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return;
  }
   
  if (bufferTrend[0] == 7)               //���� ����������� ������ FLAT  
  {   
   for (int i = 0; i < waitAfterDiv; i++)
   {
    if (1) //�������� �� ������������
    {

    }     
    if (1) //�������� �� ���������
    {

    }
   }
  } // close bufferTrend[0] == 7
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

/*
     if (ask < (bufferEMA[0] - deltaPriceToEMA*point))
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
     
          if (bid > (bufferEMA[0] + deltaPriceToEMA*point))
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

*/