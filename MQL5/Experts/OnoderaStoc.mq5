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
CTradeManager * ctm;                                                     // ��������� �� ������ �������� ����������
static CisNewBar *isNewBar;                                              // ��� �������� ������������ ������ ����

// ������ ����������� 
int handleSmydSTOC;                                                      // ����� ���������� ShowMeYourDivSTOC
int handlePBIcur;                                                        // ����� PriceBasedIndicator

// ���������� ��������
int divSignal;                                                           // ������ �� �����������
int prevDivSignal;                                                       // ���������� ������ �� �����������
double currentPrice;                                                     // ������� ����
string symbol;                                                           // ������� ������
ENUM_TIMEFRAMES period;
int historyDepth;
double signalBuffer[];                                                   // ����� ��� ��������� ������� �� ����������

int    stopLoss;                                                         // ���������� ��� �������� ��������������� ���� �����
int    copiedSmydSTOC;                                                   // ���������� ��� �������� ����������� ������ �������� �����������

int OnInit()
{
 symbol = Symbol();
 period = Period();
 
 historyDepth = 1000;
 // �������� ������ ��� ������ ��������� ����������
 isNewBar = new CisNewBar(symbol, period);
 ctm = new CTradeManager(); 
 handlePBIcur = iCustom(symbol, period, "PriceBasedIndicator",historyDepth, percentage_ATR_cur, difToTrend_cur);
 // ������� ����� ���������� ShowMeYourDivSTOC
 handleSmydSTOC = iCustom (symbol,period,"smydSTOC");   
 if ( handleSmydSTOC == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� ONODERA. �� ������� ������� ����� ShowMeYourDivSTOC");
  return(INIT_FAILED);
 }
 // �������� ��������� ����������� �� ������� 
 prevDivSignal  =  FindLastDivType (handleSmydSTOC);      
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
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
 // ���������� ���������� �������� ����������� ������ �������� � ��������� ��������
 copiedSmydSTOC = -1;
 // ���� ����������� ����� ���
 if (isNewBar.isNewBar() > 0)
  {
   copiedSmydSTOC = CopyBuffer(handleSmydSTOC,2,0,1,signalBuffer);

   if (copiedSmydSTOC < 1)
    {
     PrintFormat("�� ������� ���������� ��� ������ Error=%d",GetLastError());
     return;
    }   
        
   if ( signalBuffer[0] == _Buy)  // �������� ����������� �� �������
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);
      stopLoss = CountStoploss(1);
      // ���� ���������� ������ ����������� ���� BUY
      if (prevDivSignal == _Buy)
       {
        // �� �� ������ ����������� �� BUY ������������ ����������
        ctm.OpenUniquePosition(symbol,period, OP_BUY, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);         
       }
      else
       {
        // ����� �� ���������� LIMIT
        
       }
        // ��������� ������� ����������� � �������� �����������
        prevDivSignal = signalBuffer[0];
     }
   if ( signalBuffer[0] == _Sell) // �������� ����������� �� �������
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);  
      stopLoss = CountStoploss(-1);
      ctm.OpenUniquePosition(symbol,period, opSell, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handlePBIcur, priceDifference);        
      // ��������� ������� ����������� � �������� �����������
      prevDivSignal = signalBuffer[0];   
     }
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
 // �� ������ ���� �������, � ������� �� �����, � �������� � �� �����
 // �������� �� ������ - ��� ���� ��������� ������ ����� �������� �����������
 // ��� ��� �����, �� �� ����� ���������, ��� stopLoss ����� ���� ������������� ������
 // ���� �������������, ��� �� ����� ������������� �� ��-�� ���� �������, �� ����� ���� �� �����
 // � ���� ������ ��� ��� ���������, ����� ������� ;) 
 if (stoploss <= 0)
 {
  PrintFormat("�� ��������� ���� �� ����������");
  stoploss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}

// ������� ���������� ��� ���������� ����������� �� ������ ������ ��������

int  FindLastDivType (int smydHandle)
 {
  int copiedBuf = -1;   // ���������� ��� �������� ���������� ������������� ������ �� ������
  double smydBuffer[];  // ����� ���������� �������� �������� ����������
  // �������� ���������� ������ ����������
  for (int attempts=0;attempts<25;attempts++)
   {
    copiedBuf = CopyBuffer(smydHandle,2,0,lengthBetween2Div,smydBuffer);   
    Sleep(100);
   }
   if ( copiedBuf < lengthBetween2Div)
    {
     Print("�� ������� ���������� ������ ����������, ������� ��������� ����������� �� ������ ����� �� �������");
     return (0);
    }
   // ������� �� ����� �� ����� ������� � ���������� ����� ��������� �����������
   for (int index = lengthBetween2Div-1;index > 0; index++)
    {
      // ���� ����� �������� �� ���� ��������, ������ ����� �����������
      if (smydBuffer[index] != 0)
       return (smydBuffer[index]);
    }
   return (0);  // ������ ����, ������ �� ����� �� ������� �� ������ �����������
 }
 
// ������� ��������� ���� ������ �� ���� ����������� ����������� 
int  GetTakeProfitByExtremums ()
 {
 
 }
 
