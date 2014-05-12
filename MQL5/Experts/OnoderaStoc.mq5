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
#include <Constants.mqh>                        // ���������� ��������

#define ADD_TO_STOPPLOSS 0

//+------------------------------------------------------------------+
//| �������, ���������� �� ����������� ����������                    |
//+------------------------------------------------------------------+

// ������� ���������
sinput string base_param                           = "";                 // ������� ��������� ��������
input  int    StopLoss                             = 0;                  // ���� ����
input  int    TakeProfit                           = 0;                  // ���� ������
input  double Lot                                  = 1;                  // ���
input  ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS;      // ��� ����������� ������                    
input  int    priceDifference                      = 50;                 // Price Difference
input  int    lengthBetween2Div                    = 100;                // ���������� ����� � ������� ��� ������ ���������� �����������

sinput string trailingStr                          = "";                 // ��������� ���������
input         ENUM_TRAILING_TYPE trailingType      = TRAILING_TYPE_PBI;  // ��� ���������
input int     trStop                               = 100;                // Trailing Stop
input int     trStep                               = 100;                // Trailing Step
input int     minProfit                            = 250;                // ����������� �������

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
double currentPrice;                                                     // ������� ����
string symbol;                                                           // ������� ������
ENUM_TIMEFRAMES period;
int historyDepth;
double signalBuffer[];                                                   // ����� ��� ��������� ������� �� ����������
double extrLeftTime[];                                                   // ����� ��� �������� ������� ����� �����������
double extrRightTime[];                                                  // ����� ��� �������� ������� ������ �����������
double pbiBuffer[];                                                      // ����� ��� �������� ���������� PriceBasedIndicator

int    stopLoss;                                                         // ���������� ��� �������� ��������������� ���� �����
int    copiedSmydSTOC;                                                   // ���������� ��� �������� ����������� ������ �������� �����������
int    copiedLeftExtr;                                                   // ���������� ��� �������� ����������� ������ ����� �����������
int    copiedRightExtr;                                                  // ���������� ��� �������� ����������� ������ ������ �����������
int    copiedPBI;                                                        // ���������� ��� �������� ����������� ������ PBI

// ���������� ��� �������� �������� � ��������� ����� ������������ �����������
double minBetweenExtrs;
double maxBetweenExtrs;

// ���������� ��� �������� �������� ���� ������� � ������ ����� �������  
int    takeProfit;
int    limitOrderLevel;

int OnInit()
{
 symbol = Symbol();
 period = Period();
 
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
   copiedPBI       = CopyBuffer(handlePBIcur,4,1,1,pbiBuffer);
   // �������� �� ���������� ����������� ���� �������
   if (copiedSmydSTOC < 1 || copiedLeftExtr < 1 || copiedRightExtr < 1 || copiedPBI < 1)
    {
     PrintFormat("�� ������� ���������� ��� ������ Error=%d",GetLastError());
     return;
    }   
       if (signalBuffer[0] != 0)
       { 
  Comment
   (
     "������ = ",signalBuffer[0],
     "\n���� ������ = ",TimeToString(datetime(extrLeftTime[0])),  
     "\n���� ������� = ",TimeToString(datetime(extrRightTime[0]))      
   );
   }
   
   if ( signalBuffer[0] == _Buy)  // �������� ����������� �� �������
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);    
      stopLoss = CountStoploss(1);
      // ���� ����� ����
      if (pbiBuffer[0] == MOVE_TYPE_TREND_DOWN || pbiBuffer[0] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
       {
        // �� �� ������ ����������� �� BUY ������������ ����������
        ctm.OpenUniquePosition(symbol,period, OP_BUY, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);         
       }
      else
       {
        // ����� �� ���������� LIMIT ������
        if ( GetMaxAndMinBetweenExtrs() )  // ���� ������� ��������� ��������� � ��������
         {
          // ��������� ���� ������ 
          takeProfit      =  2*(maxBetweenExtrs-minBetweenExtrs)/_Point;
          //  ������� ����� ������
          limitOrderLevel =  maxBetweenExtrs/_Point;
          // � ��������� ������� ����� ������� �� SELL
          ctm.OpenUniquePosition(symbol,period,OP_SELLLIMIT,Lot,stopLoss,takeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, limitOrderLevel);
         }
       }
    }  // END OF BUY
   if ( signalBuffer[0] == _Sell) // �������� ����������� �� �������
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);  
      stopLoss = CountStoploss(-1);
      if (pbiBuffer[0] == MOVE_TYPE_TREND_UP || pbiBuffer[0] == MOVE_TYPE_TREND_UP_FORBIDEN)
       {
        // �� �� ������ ����������� �� SELL ������������ ����������
        ctm.OpenUniquePosition(symbol,period, OP_SELL, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);        
       }
      else
       {
        // ����� �� ���������� LIMIT ������
        if ( GetMaxAndMinBetweenExtrs() )  // ���� ������� ��������� ��������� � ��������
         {
          // ��������� ���� ������ 
          takeProfit      =  2*(maxBetweenExtrs-minBetweenExtrs)/_Point;
          //  ������� ����� ������
          limitOrderLevel =  minBetweenExtrs/_Point;
          // � ��������� ������� ����� ������� �� BUY
          ctm.OpenUniquePosition(symbol,period,OP_BUYLIMIT,Lot,stopLoss,takeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, limitOrderLevel);
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
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
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
    copiedHigh = CopyHigh(symbol,period,(datetime)extrLeftTime[0],(datetime)extrRightTime[0],tmpLow);
    copiedLow  = CopyLow (symbol,period,(datetime)extrLeftTime[0],(datetime)extrRightTime[0],tmpLow);    
    Sleep(100);
   }
  n_bars = Bars(symbol,period,(datetime)extrLeftTime[0],(datetime)extrRightTime[0]);
  if (copiedHigh < n_bars || copiedLow < n_bars)
   {
    Print("������ ������ �������� ONODERA. �� ������� ����������� ������ ������� �\��� ������ ��� ��� ������ ��������� � ��������");
    return (false);
   }
  // ��������� �������� ����
  maxBetweenExtrs = ArrayMaximum(tmpHigh);
  // ��������� ������� ����
  minBetweenExtrs = ArrayMinimum(tmpLow);
  return (true);
 }
 