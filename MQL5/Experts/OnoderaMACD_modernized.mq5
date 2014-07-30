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

#define ADD_TO_STOPPLOSS 50
// ��������� ��������
#define BUY   1    
#define SELL -1

//+------------------------------------------------------------------+
//| �������, ���������� �� ����������� MACD                          |
//+------------------------------------------------------------------+

// ������� ���������
sinput string base_param                           = "";                 // ������� ��������� ��������
input  int    StopLoss                             = 0;                  // ���� ����
input  int    TakeProfit                           = 0;                  // ���� ������
input  double Lot                                  = 1;                  // ���
input  ENUM_USE_PENDING_ORDERS pending_orders_type = USE_NO_ORDERS;      // ��� ����������� ������                    
input  int    priceDifference                      = 50;                 // Price Difference
input  int    koLock                               = 2;                  // ����������� ������� �� ����

sinput string trailingStr                          = "";                 // ��������� ���������
input         ENUM_TRAILING_TYPE trailingType      = TRAILING_TYPE_PBI;  // ��� ���������
input int     trStop                               = 100;                // Trailing Stop
input int     trStep                               = 100;                // Trailing Step
input int     minProfit                            = 250;                // ����������� �������

sinput string PriceBasedIndicator                  = "";                 // ��������� PBI
input double   percentage_ATR = 1;   // ������� ��� ��� ��������� ������ ����������
input double   difToTrend = 1.5;     // ������� ����� ������������ ��� ��������� ������


// �������
CTradeManager * ctm;                                                     // ��������� �� ������ �������� ����������
static CisNewBar *isNewBar;                                              // ��� �������� ������������ ������ ����

// ������ ����������� 
int handleSmydMACD;                                                      // ����� ���������� ShowMeYourDivMACD
int handle_PBI;

// ���������� ��������
int divSignal;                                                           // ������ �� �����������
double currentPrice;                                                     // ������� ����
ENUM_TM_POSITION_TYPE opBuy,opSell;                                      // ���� ������� 
string symbol;
ENUM_TIMEFRAMES period;
int historyDepth;
double signalBuffer[];                                                   // ����� ��� ��������� ������� �� ����������

int    stopLoss;                                                         // ���������� ��� �������� ��������������� ���� �����
int    copiedSmydMACD;                                                   // ���������� ��� �������� ����������� ������ �������� �����������

int handle_19Lines;

// ��������� �������
struct bufferLevel
 {
  double price[];            // ���� ������
  double atr[];              // ������ ������
 };

// ������ ������� 
bufferLevel buffers[2];     // ����� �������

// �������������� ����������
double lenClosestUp;         // ���������� �� ���������� ������ ������
double lenClosestDown;       // ���������� �� ���������� ������ �����                 

int OnInit()
{
 symbol = Symbol();
 period = Period();
 
 historyDepth = 1000;
 // �������� ������ ��� ������ ��������� ����������
 isNewBar = new CisNewBar(symbol, period);
 ctm = new CTradeManager(); 
 if (trailingType == TRAILING_TYPE_PBI)
 {
  handle_PBI = iCustom(symbol, period, "PriceBasedIndicator", historyDepth, percentage_ATR, difToTrend);
  if(handle_PBI == INVALID_HANDLE)                                //��������� ������� ������ ����������
  {
   Print("�� ������� �������� ����� Price Based Indicator");      //���� ����� �� �������, �� ������� ��������� � ��� �� ������
  }
 }
 
 handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines");     
 if (handle_19Lines == INVALID_HANDLE)
   {
    Print("�� ������� �������� ����� NineteenLines");
   }    
 
 // ������� ����� ���������� ShowMeYourDivMACD
 handleSmydMACD = iCustom (symbol,period,"smydMACD");   
   
 if ( handleSmydMACD == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� ONODERA. �� ������� ������� ����� ShowMeYourDivMACD");
  return(INIT_FAILED);
 }
 // ���������� ����� �������
 switch (pending_orders_type)  
 {
  case USE_LIMIT_ORDERS: 
   opBuy  = OP_BUYLIMIT;
   opSell = OP_SELLLIMIT;
   break;
  case USE_STOP_ORDERS:
   opBuy  = OP_BUYSTOP;
   opSell = OP_SELLSTOP;
   break;
  case USE_NO_ORDERS:
   opBuy  = OP_BUY;
   opSell = OP_SELL;      
   break;
 }          
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // ������� ������ ������ TradeManager
 delete isNewBar;
 delete ctm;
 // ������� ��������� 
 IndicatorRelease(handleSmydMACD);
}

void OnTick()
{
 ctm.OnTick();
 ctm.DoTrailing();
 // ���� �� ������� ���������� ������ �������
 if (!UploadBuffers())
  return;
GetClosestLevel(BUY);  
 // ���������� ���������� �������� ����������� ������ �������� � ��������� ��������
 copiedSmydMACD = -1;
 // ���� ����������� ����� ���
 if (isNewBar.isNewBar() > 0)
  {
   copiedSmydMACD = CopyBuffer(handleSmydMACD,1,0,1,signalBuffer);

   if (copiedSmydMACD < 1)
    {
     PrintFormat("�� ������� ���������� ��� ������ Error=%d",GetLastError());
     return;
    }   
 
   if ( signalBuffer[0] == BUY)  // �������� ����������� �� �������
     { 
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_ASK);
      // �������� ���������� �� ��������� ������� ����� � ������
      lenClosestUp   = 0;//GetClosestLevel(BUY);
      lenClosestDown = 0;//GetClosestLevel(SELL);
      stopLoss = CountStoploss(BUY);
      // ���� ��������� ������� ������ �����������, ��� ������ ���������� ������ �����
      if (lenClosestUp == 0 || 
          GreatDoubles(lenClosestUp, lenClosestDown*koLock) )
         {
          // �� ��������� ������� �� BUY
          ctm.OpenUniquePosition(symbol,period, opBuy, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handle_PBI, priceDifference);        
         }
     }
   if ( signalBuffer[0] == SELL) // �������� ����������� �� �������
     {
      currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);  
      // �������� ���������� �� ��������� ������� ����� � ������
      lenClosestUp   = 0;//GetClosestLevel(BUY);
      lenClosestDown = 0;//GetClosestLevel(SELL);      
      stopLoss = CountStoploss(SELL);
      // ���� ��������� ������� ����� �����������, ��� ������ ���������� ������ ������
      if (lenClosestDown == 0 ||
          GreatDoubles(lenClosestDown, lenClosestUp*koLock) )
         {
          // �� ��������� ������� �� SELL
          ctm.OpenUniquePosition(symbol,period, opSell, Lot, stopLoss, TakeProfit, trailingType, minProfit, trStop, trStep, handle_PBI, priceDifference);        
         }
     }
   }  
}

int CountStoploss(int point)
{
 int stopLoss = 0;
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
  copiedPBI = CopyBuffer(handle_PBI, extrBufferNumber, 0,historyDepth, bufferStopLoss);
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
    stopLoss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point()) + ADD_TO_STOPPLOSS;
    break;
   }
  }
 }
 // �� ������ ���� �������, � ������� �� �����, � �������� � �� �����
 // �������� �� ������ - ��� ���� ��������� ������ ����� �������� �����������
 // ��� ��� �����, �� �� ����� ���������, ��� stopLoss ����� ���� ������������� ������
 // ���� �������������, ��� �� ����� ������������� �� ��-�� ���� �������, �� ����� ���� �� �����
 // � ���� ������ ��� ��� ���������, ����� ������� ;) 
 if (stopLoss <= 0)  
 {
  PrintFormat("�� ��������� ���� �� ����������");
  stopLoss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}


bool UploadBuffers ()   // �������� ��������� �������� �������
 {
  int copiedPrice;
  int copiedATR;
  int indexPer;
  int indexBuff;
  int indexLines = 0;
  for (indexPer=1;indexPer<2;indexPer++)
   {
    for (indexBuff=0;indexBuff<2;indexBuff++)
     {
      copiedPrice = CopyBuffer(handle_19Lines,indexPer*8+indexBuff*2+4,  0,1,  buffers[indexLines].price);
      copiedATR   = CopyBuffer(handle_19Lines,indexPer*8+indexBuff*2+5,  0,1,buffers[indexLines].atr);
      if (copiedPrice < 1 || copiedATR < 1)
       {
        Print("�� ������� ���������� ������ ���������� NineTeenLines");
        return (false);
       }
      indexLines++;
     }
   }
  return(true);     
 }
 
 // ���������� ��������� ������� � ������� ����
 double GetClosestLevel (int direction) 
  {
   double cuPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double len = 0;  //���������� �� ���� �� ������
   double tmpLen; 
   int    index;
   int    savedInd;
   
   switch (direction)
    {
     case BUY:  // ������� ������
      for (index=0;index<2;index++)
       {
        // ���� ������� ����
        if ( GreatDoubles((buffers[index].price[0]-buffers[index].atr[0]),cuPrice)  )
         {
          tmpLen = buffers[index].price[0] - buffers[index].atr[0] - cuPrice;
          if (tmpLen < len || len == 0)
           {
            savedInd = index;
            len = tmpLen;
           }  
         }
       }
       Comment("BUY: ",DoubleToString(buffers[savedInd].price[0]-buffers[savedInd].atr[0]) );
     break;
     case SELL: // ������� �����
      for (index=0;index<2;index++)
       {
        // ���� ������� ����
        if ( LessDoubles((buffers[index].price[0]+buffers[index].atr[0]),cuPrice)  )
          {
           tmpLen = cuPrice - buffers[index].price[0] - buffers[index].atr[0] ;
           if (tmpLen < len || len == 0)
            {
             savedInd = index;
             len = tmpLen;
            }
          }
       }     
       Comment("SELL: ",DoubleToString(buffers[savedInd].price[0]-buffers[savedInd].atr[0]) );
      break;
   }
   return (len);
  }
  
  