//+------------------------------------------------------------------+
//|                                                      ONODERA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// ������������ ��������� 
#include <TradeManager\TradeManager.mqh>        // ����������� �������� ����������
#include <Lib CisNewBar.mqh>                    // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>                   // ��� �������� �����������  ���

#define ADD_TO_STOPPLOSS 50
// ��������� ��������
#define BUY   1    
#define SELL -1
//+------------------------------------------------------------------+
//| �������, ���������� �� ����������� ����������                    |
//+------------------------------------------------------------------+

// ������� ���������
sinput string order_params                         = "";                 // ��������� �������
input  bool   use_limits                           = true;               // ������������� limit-�������
input  bool   flat_as_instant                      = false;              // ����������� �� FLAT �� ����������� �����������

sinput string pbi_Str                              = "";                 // ��������� PBI
input double  percentage_ATR_cur                   = 2;   
input double  difToTrend_cur                       = 1.5;
input int     ATR_ma_period_cur                    = 12;

// �������
CTradeManager    *ctm;                                                   // ��������� �� ������ �������� ����������
static CisNewBar *isNewBar;                                              // ��� �������� ������������ ������ ����

// ������ ����������� 
int handleSmydSTOC;                                                      // ����� ���������� ShowMeYourDivSTOC
int handlePBIcur;                                                        // ����� PriceBasedIndicator

// ���������� ��������
double currentPrice;        // ������� ����
string symbol;              // ������� ������
ENUM_TIMEFRAMES period;     // ������� ������
int historyDepth;           // ������� �������
int priceDifference;        // Price Difference
ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;  // ��� ���������
double lot;                  // ���

double signalBuffer[];                                                   // ����� ��� ��������� ������� �� ����������
double extrLeftTime[];                                                   // ����� ��� �������� ������� ����� �����������
double extrRightTime[];                                                  // ����� ��� �������� ������� ������ �����������
double pbiBuffer[];                                                      // ����� ��� �������� ���������� PriceBasedIndicator

int    copiedSmydSTOC;                                                   // ���������� ��� �������� ����������� ������ �������� �����������
int    copiedLeftExtr;                                                   // ���������� ��� �������� ����������� ������ ����� �����������
int    copiedRightExtr;                                                  // ���������� ��� �������� ����������� ������ ������ �����������
int    copiedPBI;                                                        // ���������� ��� �������� ����������� ������ PBI

// ���������� ��� �������� �������� � ��������� ����� ������������ �����������
double minBetweenExtrs;
double maxBetweenExtrs;

// ���������� ��� �������� �������� ���� ������� � ������ ����� �������  
int    stopLoss;           // ���������� ��� �������� ���� �����
int    takeProfit;         // ���������� ��� �������� ���� �������
int    limitOrderLevel;    // ���������� ��� �������� ������ ����������� ������

int OnInit()
{
 symbol = Symbol();
 period = Period();
 lot = 1;
 
 trailingType = TRAILING_TYPE_PBI;  // ��� ���������
 historyDepth = 1000;
 // �������� ������ ��� ������ ��������� ����������
 isNewBar = new CisNewBar(symbol, period);
 ctm = new CTradeManager(); 
 handlePBIcur = iCustom(symbol, period, "PriceBasedIndicator",historyDepth, percentage_ATR_cur, difToTrend_cur);
 if ( handlePBIcur == INVALID_HANDLE)
  {
   Print("������ ��� ������������� �������� ONODERA. �� ������� ������� ����� PriceBasedIndicator");
   return(INIT_FAILED);
  }
 // ������� ����� ���������� ShowMeYourDivSTOC
 handleSmydSTOC = iCustom (symbol,period,"smydSTOC");   
 if ( handleSmydSTOC == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� ONODERA. �� ������� ������� ����� ShowMeYourDivSTOC");
  return(INIT_FAILED);
 }   
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // ����������� ������
 ArrayFree(signalBuffer);
 ArrayFree(extrLeftTime);
 ArrayFree(extrRightTime);
 ArrayFree(pbiBuffer);   
 // ������� ������ ������ TradeManager
 delete isNewBar;
 delete ctm;
 // ������� ����������
 IndicatorRelease(handleSmydSTOC);
 IndicatorRelease(handlePBIcur);  
}

void OnTick()
{
 ctm.OnTick();
 ctm.DoTrailing();  
 // ���������� ���������� �������� ����������� ������� �������� � ����������� � ��������� ��������
 copiedSmydSTOC  = -1;
 copiedLeftExtr  = -1;
 copiedRightExtr = -1;
 copiedPBI       = -1;
 // ���� ����������� ����� ���
 if (isNewBar.isNewBar() > 0)
 {
  // �������� ����������� ������ 
  copiedSmydSTOC  = CopyBuffer(handleSmydSTOC,2,0,1,signalBuffer);
  copiedLeftExtr  = CopyBuffer(handleSmydSTOC,3,0,1,extrLeftTime);
  copiedRightExtr = CopyBuffer(handleSmydSTOC,4,0,1,extrRightTime);
  copiedPBI       = CopyBuffer(handlePBIcur  ,4,1,1,pbiBuffer);
  // �������� �� ���������� ����������� ���� �������
  if (copiedSmydSTOC < 1 || copiedLeftExtr < 1 || copiedRightExtr < 1 || copiedPBI < 1)
  {
   PrintFormat("�� ������� ���������� ��� ������ Error=%d",GetLastError());
   return;
  }   

  if ( signalBuffer[0] == BUY)  // �������� ����������� �� �������
  { 
   // ��������� ���� ����
   stopLoss = CountStoploss(1);
   // ������� �������� ������� �� BUY �� ����������� ����������
   if (  (pbiBuffer[0] == MOVE_TYPE_TREND_UP           || 
          pbiBuffer[0] == MOVE_TYPE_TREND_UP_FORBIDEN  ||
          pbiBuffer[0] == MOVE_TYPE_CORRECTION_DOWN)   ||     
          !use_limits                                  ||
         (flat_as_instant  && pbiBuffer[0] == MOVE_TYPE_FLAT)
      )
   {
    // �� �� ������ ����������� �� BUY ������������ ����������
    ctm.OpenUniquePosition(symbol,period, OP_BUY, lot, stopLoss, takeProfit, trailingType, 0, 0, 0, handlePBIcur, priceDifference);         
   }
   else
   {
    // ����� �� ���������� LIMIT ������
    if ( GetMaxAndMinBetweenExtrs() )  // ���� ������� ��������� ��������� � ��������
    {
     // ��������� ���� ������ 
     takeProfit = int(2*(maxBetweenExtrs-minBetweenExtrs)/_Point);
     //  �������� ������� ����
     currentPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);           
     //  ������� ����� ������
     limitOrderLevel =  (currentPrice-maxBetweenExtrs)/_Point;
     // � ��������� ������� ����� ������� �� SELL
     if (limitOrderLevel <= SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL))
     {
      ctm.OpenUniquePosition(symbol,period, OP_BUY, lot, stopLoss, takeProfit, trailingType, 0, 0, 0, handlePBIcur, priceDifference);         
     }
     else
     { 
      ctm.OpenUniquePosition(symbol,period,OP_SELLLIMIT,lot,stopLoss,takeProfit, trailingType, 0, 0, 0, handlePBIcur, limitOrderLevel);
     }
    }
   }
  }  // END OF BUY
  
  if ( signalBuffer[0] == SELL) // �������� ����������� �� �������
  {  
   // ��������� ���� ����
   stopLoss = CountStoploss(-1);
   // ������� �������� ������� �� ����������� ����������
   
   if (  (pbiBuffer[0] == MOVE_TYPE_TREND_DOWN          || 
          pbiBuffer[0] == MOVE_TYPE_TREND_DOWN_FORBIDEN ||
          pbiBuffer[0] == MOVE_TYPE_CORRECTION_UP)      ||     
          !use_limits                                   ||
         (flat_as_instant && pbiBuffer[0] == MOVE_TYPE_FLAT)
      )
   {
    // �� �� ������ ����������� �� SELL ������������ ����������
    ctm.OpenUniquePosition(symbol,period, OP_SELL, lot, stopLoss, takeProfit, trailingType, 0, 0, 0, handlePBIcur, priceDifference);        
   }
   else
   {
    // ����� �� ���������� LIMIT ������
    if ( GetMaxAndMinBetweenExtrs() )  // ���� ������� ��������� ��������� � ��������
    {
     // ��������� ���� ������ 
     takeProfit = int(2*(maxBetweenExtrs-minBetweenExtrs)/_Point);
     //  �������� ������� ����
     currentPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);            
     //  ������� ����� ������
     limitOrderLevel =  (currentPrice-minBetweenExtrs)/_Point;
     // � ��������� ������� ����� ������� �� BUY
     if (limitOrderLevel <= SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL))
     {
      ctm.OpenUniquePosition(symbol,period, OP_SELL, lot, stopLoss, takeProfit, trailingType, 0, 0, 0, handlePBIcur, priceDifference);        
     }
     else
     {
      ctm.OpenUniquePosition(symbol,period,OP_BUYLIMIT,lot,stopLoss,takeProfit, trailingType, 0, 0, 0, handlePBIcur, limitOrderLevel);
     }
    }        
   }
  }  // END OF SELL
 }  
}

// ������� ��������� ���� ����
int CountStoploss(int point)
{
 int stoploss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, historyDepth);
 
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6;
  priceAB = SymbolInfoDouble(symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; // ���� point > 0 ������� ����� � ����������, ����� � �����������
  priceAB = SymbolInfoDouble(symbol, SYMBOL_BID);
  direction = -1;
 }
 
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(handlePBIcur, extrBufferNumber, 0,historyDepth, bufferStopLoss);
 }
 if (copiedPBI < historyDepth)
 {
  PrintFormat("%s �� ������� ����������� ����� bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(0);
 }
 
 for(int i = 0; i < historyDepth; i++)
 {
  if (bufferStopLoss[i] > 0)
  {
   if (LessDoubles(direction*bufferStopLoss[i], direction*priceAB))
   {
    stoploss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point()) + ADD_TO_STOPPLOSS;
    break;
   }
  }
 }
 if (stoploss <= 0)
 {
  PrintFormat("�� ��������� ���� �� ����������");
  stoploss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stoploss);
 return(stoploss);
}

// ������� ��������� ������� � �������� ����� ����� ������������
bool  GetMaxAndMinBetweenExtrs()
 {
  double tmpLow[];           // ��������� ����� ������ ���
  double tmpHigh[];          // ��������� ����� ������� ���
  int    copiedHigh = -1;    // ���������� ��� �������� ����������� ������ ������� ���
  int    copiedLow  = -1;    // ���������� ��� �������� ����������� ������ ������ ���
  int    n_bars;             // ���������� ������������� �����
  for (int attempts=0;attempts<25;attempts++)
   {
    copiedHigh = CopyHigh(symbol,period,datetime(extrLeftTime[0]),datetime(extrRightTime[0]),tmpHigh);
    copiedLow  = CopyLow (symbol,period,datetime(extrLeftTime[0]),datetime(extrRightTime[0]),tmpLow);    
    Sleep(100);
   }
  n_bars = Bars(symbol,period,datetime(extrLeftTime[0]),datetime(extrRightTime[0]));
  if (copiedHigh < n_bars || copiedLow < n_bars)
   {
    Print("������ ������ �������� ONODERA. �� ������� ����������� ������ ������� �\��� ������ ��� ��� ������ ��������� � ��������");
    return (false);
   }
  // ��������� �������� ����
  maxBetweenExtrs = tmpHigh[ArrayMaximum(tmpHigh)];
  // ��������� ������� ����
  minBetweenExtrs = tmpLow[ArrayMinimum(tmpLow)];
  return (true);
 }
 