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
#include <ChartObjects/ChartObjectsLines.mqh>      // ��� ��������� ����� �����������
#define ADD_TO_STOPPLOSS 50
// ��������� ��������
#define BUY   1    
#define SELL -1

//+------------------------------------------------------------------+
//| �������, ���������� �� ����������� MACD                          |
//+------------------------------------------------------------------+                                                                 
   
// ������� ���������
sinput string base_param                           = "";                 // ������� ��������� ��������
input  double lot                                  = 0.1;                // ���         
input  int    spread                               = 300;                // ������ ������       
input  int    koLock                               = 2;                  // ����������� ������� �� ����
sinput string trailingStr                          = "";                 // ��������� ���������
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;               // ��� ���������
input int     trStop                               = 100;                // Trailing Stop
input int     trStep                               = 100;                // Trailing Step
input int     minProfit                            = 250;                // ����������� �������
input bool    use19Lines                           = false;              // ���� ������������� �������
// ��������� �������
struct bufferLevel
 {
  double price[];  // ���� ������
  double atr[];    // ������ ������
 };
// �������
CTradeManager    *ctm;                                                   // ��������� �� ������ �������� ����������
static CisNewBar *isNewBar;                                              // ��� �������� ������������ ������ ����
SPositionInfo pos_info;
STrailing trailing;
// ������ ����������� 
int handleSmydSTOC;                                                      // ����� ���������� smySTOC
int handle_PBI;                                                          // ����� PriceBasedIndicator
int handle_19Lines;                                                      // ����� 19 Lines
// ���������� ��������
int    stopLoss;                                                         // ���������� ��� �������� ��������������� ���� �����
double currentPrice;                                                     // ������� ����
double lenClosestUp;                                                     // ���������� �� ���������� ������ ������
double lenClosestDown;                                                   // ���������� �� ���������� ������ �����    
double lastRightExtr=0;                                                  // �������� ��������� ���� ������� ���������� �����������
// ������ 
double signalBuffer[];                                                   // ����� ��� ��������� ������� �� ���������� smydStochastic
double dateRightExtr[];                                                  // ����� ��� ��������� ������� ������� ������� ���������� �����������
bufferLevel buffers[10];                                                  // ����� �������

CChartObjectHLine  horLine;                                              // ������ ������ ������������ �����
int OnInit()
{
 // �������� ������ ��� ������ ��������� ����������
 isNewBar = new CisNewBar(_Symbol, _Period);
 ctm = new CTradeManager(); 
 handle_PBI = iCustom(_Symbol, _Period, "PriceBasedIndicator", 1000, 1, 1.5);
 if(handle_PBI == INVALID_HANDLE)                                //��������� ������� ������ ����������
  {
   Print("�� ������� �������� ����� Price Based Indicator");      //���� ����� �� �������, �� ������� ��������� � ��� �� ������
  }
 // ���� ������������ ������ ��� ������� �� ����
 if (use19Lines)
  {
   handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines",
                            "",3,3,
                            "","",true,0.1,
                            "",true,0.15,
                            "",true,0.25,
                            "",true,0.25,
                            "",true,0.25,
                            "",false
                           );     
   if (handle_19Lines == INVALID_HANDLE)
    {
     Print("�� ������� �������� ����� NineteenLines");
     return (INIT_FAILED);
    }
   }    
 // ������� ����� ���������� ShowMeYourDivMACD
 handleSmydSTOC = iCustom (_Symbol,_Period,"smydSTOC");   
 if ( handleSmydSTOC == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� TradeOnStochastic. �� ������� ������� ����� smydSTOC");
  return(INIT_FAILED);
 }     
 pos_info.tp = 0;
 pos_info.volume = lot;
 pos_info.expiration = 0;
 pos_info.priceDifference = 0;
  
 trailing.trailingType = trailingType;
 trailing.minProfit    = minProfit;
 // ���� ��� ��������� ������������ PBI
 if (trailingType == TRAILING_TYPE_PBI)
  {
   trailing.trailingStop = trStop;
   trailing.trailingStep = trStep;
   trailing.handlePBI    = handle_PBI; 
  }
 else
  {
   trailing.trailingStop = 0;
   trailing.trailingStep = 0;
   trailing.handlePBI    = 0;
  }
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // ������� ������ ������ TradeManager
 delete isNewBar;
 delete ctm;
 // ������� ��������� 
 IndicatorRelease(handleSmydSTOC);
 // ���� ������������ ������ ��� ������� �� ����
 if (use19Lines)
  IndicatorRelease(handle_19Lines);
 IndicatorRelease(handle_PBI);
}

void OnTick()
{
 ctm.OnTick();
 if (trailingType != TRAILING_TYPE_NONE)
 ctm.DoTrailing();
 // ���� ������������ ������ ��� ������� �� ����
 if (use19Lines)
  {
   // ���� �� ������� ���������� ������ �������
   if (!UploadBuffers())
    return;
  }
 // ���� ����������� ����� ���
   if (CopyBuffer(handleSmydSTOC,2,0,1,signalBuffer) < 1 || CopyBuffer(handleSmydSTOC,4,0,1,dateRightExtr) < 1 )
    {
     PrintFormat("�� ������� ���������� ��� ������ Error=%d",GetLastError());
     return;
    }   
  
   if ( signalBuffer[0] == BUY)  // �������� ����������� �� �������
     { 
      // ���� ��������� ���������� ������ �� ����� �����������
      if ( !EqualDoubles( lastRightExtr,dateRightExtr[0]) ) 
       {
        currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        // ���� ������������ ������ ��� ������� �� ����
        if (use19Lines)
         {
          // �������� ���������� �� ��������� ������� ����� � ������
          lenClosestUp   = GetClosestLevel(BUY);
          lenClosestDown = GetClosestLevel(SELL);
          // ���� ��������� ������� ������ �����������, ��� ������ ���������� ������ �����
          if (lenClosestUp != 0 && LessOrEqualDoubles(lenClosestUp, lenClosestDown*koLock) )
           return;
         }
          stopLoss = CountStoploss(BUY);        
          // �� ��������� ������� �� BUY
          pos_info.type = OP_BUY;
          pos_info.sl = stopLoss;
          ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing,spread);                  
        }
       // ��������� ��������� ������
       lastRightExtr = dateRightExtr[0];
     }
   if ( signalBuffer[0] == SELL) // �������� ����������� �� �������
     {
      // ���� ��������� ���������� ������ �� ����� �����������
      if ( !EqualDoubles( lastRightExtr,dateRightExtr[0]) )
       {
        currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  
        // ���� ������������ ������ ��� ������� �� ����
        if (use19Lines)
         {      
         // �������� ���������� �� ��������� ������� ����� � ������
         lenClosestUp   = GetClosestLevel(BUY);
         lenClosestDown = GetClosestLevel(SELL);      
         // ���� ��������� ������� ����� �����������, ��� ������ ���������� ������ ������
         if (lenClosestDown != 0 && LessOrEqualDoubles(lenClosestDown,lenClosestUp*koLock) )
           return;
         }
          stopLoss = CountStoploss(SELL);
          // �� ��������� ������� �� SELL
          pos_info.type = OP_SELL;
          pos_info.sl = stopLoss;
          ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing,spread);                   
       }
      //��������� ��������� ������ ��������� �����������
      lastRightExtr = dateRightExtr[0]; 
     }
}

int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, 1000);
 
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6;
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; // ���� point > 0 ������� ����� � ����������, ����� � �����������
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  direction = -1;
 }
 
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  //Sleep(100);
  copiedPBI = CopyBuffer(handle_PBI, extrBufferNumber, 0,1000, bufferStopLoss);
 }
 if (copiedPBI < 1000)
 {
  PrintFormat("%s �� ������� ����������� ����� bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(0);
 }
 for(int i = 0; i < 1000; i++)
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
 if (stopLoss <= 0)  
 {
  PrintFormat("�� ��������� ���� �� ����������");
  stopLoss = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 return(stopLoss);
}

bool UploadBuffers ()   // �������� ��������� �������� �������
 {
  int copiedPrice;
  int copiedATR;
  int indexPer;
  int indexBuff;
  int indexLines = 0;
  for (indexPer=0;indexPer<5;indexPer++)
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
      for (index=0;index<10;index++)
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
     break;
     case SELL: // ������� �����
      for (index=0;index<10;index++)
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
      break;
   }
   return (len);
  }