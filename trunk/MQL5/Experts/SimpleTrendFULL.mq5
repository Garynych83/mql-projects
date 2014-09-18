//+------------------------------------------------------------------+
//|                                                  SimpleTrend.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| �����, ��������� �� ������� ������                               |
//+------------------------------------------------------------------+
// ����������� ����������� ���������
#include <Lib CisNewBarDD.mqh>                     // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>                      // ��� ��������� ������������ �����
#include <TradeManager\TradeManager.mqh>           // �������� ����������
#include <BlowInfoFromExtremums.mqh>               // ����� �� ������ � ������������ ���������� DrawExtremums

// ��������� ��������
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0

// ������������ � ���������
enum ENUM_TENDENTION
{
 TENDENTION_NO = 0,     // ��� ���������
 TENDENTION_UP,         // ��������� �����
 TENDENTION_DOWN        // ��������� ����
};

// ������������ ������� PriceBasedIndicator
enum ENUM_PBI
{
 PBI_NO = 0,            // ��� PBI
 PBI_SELECTED,          // PBI � ��������� �����������
 PBI_FIXED              // PBI � �������������� ������������
};

/// ������� ���������
input string baseParam = "";                       // ������� ���������
input double lot      = 1;                         // ������ ����
input double lotStep  = 1;                         // ������ ���� ���������� ����
input int    lotCount = 3;                         // ���������� �������
input int    spread   = 30;                        // ����������� ���������� ������ ������ � ������� �� �������� � ������� �������
input string addParam = "";                        // ���������
input bool   useMultiFill=true;                    // ������������ ������� ��� �������� �� �����. ������
input string pbiParam = "";                        // ��������� PriceBasedIndicator
input ENUM_PBI  usePBI=PBI_NO;                     // ���  ������������� PBI
input ENUM_TIMEFRAMES pbiPeriod = PERIOD_H1;       // ������ PBI
input string lockParams="";                        // ��������� �������� �� ����
input bool useLinesLock=false;                     // ���� ��������� ������� �� ���� �� ���������� NineTeenLines
input  int    koLock  = 2;                         // ����������� ������� �� ����
input  bool   useMACDLock=false;                   // ���� ��������� ������� �� ���� �� ����������� �� MACD
input  int    lenToMACD = 5;                       // ���������� �� ������ ������� �� MACD

// ��������� �������
struct bufferLevel
 {
  double price[];  // ���� ������
  double atr[];    // ������ ������
 };
// ������ PriceBasedIndicator
int handlePBI_1;
int handlePBI_2;
int handlePBI_3;
// ����� ���������� NineTeenLines
int handle_19Lines;                                // ����� 19 Lines
// ������ ���������� smydMACD
int handleMACDM5;                                  // ����� smydMACD M5
int handleMACDM15;                                 // ����� smydMACD M15
int handleMACDH1;                                  // ����� smydMACD H1 
// ����������� ������
MqlRates lastBarD1[];                              // ����� ��� �� ��������
// ����� ��� �������� PriceBasedIndicator
double pbiBuf[];
// ������ ��� �������� �������� �����������
Extr             lastExtrHigh[4];                  // ����� ��������� ����������� �� HIGH
Extr             lastExtrLow[4];                   // ����� ��������� ����������� �� LOW
Extr             currentExtrHigh[4];               // ����� ������� ����������� �� HIGH
Extr             currentExtrLow[4];                // ����� ������� ����������� �� LOW
bool             extrHighBeaten[4];                // ����� ������ �������� ����������� HIGH
bool             extrLowBeaten[4];                 // ����� ������ �������� ����������� LOW

// ������� �������
CTradeManager *ctm;                                // ������ �������� ����������
//CTradeManager *ctm2;                              
CisNewBar     *isNewBar_D1;                        // ����� ��� �� D1
CBlowInfoFromExtremums *blowInfo[4];               // ������ �������� ������ ��������� ���������� �� ����������� ���������� DrawExtremums 
// ������ 
double signalBuffer[];                             // ����� ��� ��������� ������� �� ���������� smydMACD
bufferLevel buffers[8];                            // ����� �������
// �������������� ��������� ����������
bool             firstLaunch       = true;         // ���� ������� ������� ��������
bool             changeLotValid;                   // ���� ����������� ������� �� M1
bool             beatM5;                           // ���� �������� �� M5
bool             beatM15;                          // ���� �������� �� M15
bool             beatH1;                           // ���� �������� �� H1
int              openedPosition    = NO_POSITION;  // ��� �������� ������� 
int              stopLoss;                         // ���� ����
int              indexForTrail     = 0;            // ������ ��� ���������
int              countAdd          = 0;            // ���������� �������

int              lastTrendPBI_1    = 0;            // ��� ���������� ������ �� PBI 
int              lastTrendPBI_2    = 0;            // ��� ���������� ������ �� PBI
int              lastTrendPBI_3    = 0;            // ��� ���������� ������ �� PBI
  
int              tmpLastBar;

double           curPriceAsk       = 0;            // ��� �������� ������� ���� Ask
double           curPriceBid       = 0;            // ��� �������� ������� ���� Bid 
double           prevPriceAsk      = 0;            // ��� �������� ���������� ���� Ask
double           prevPriceBid      = 0;            // ��� �������� ���������� ���� Bid
double           lotReal;                          // �������������� ���
double           lenClosestUp;                     // ���������� �� ���������� ������ ������
double           lenClosestDown;                   // ���������� �� ���������� ������ ����� 
ENUM_TENDENTION  lastTendention;                   // ���������� ��� �������� ��������� ���������

// ��������� ��� ������ � ���������            
SPositionInfo pos_info;                            // ���������� �� �������� ������� 
STrailing trailing;                                // ��������� ���������
                           
int OnInit()
  {     
   // ���� �� ���������� PriceBasedIndicator ��� ���������� ���������� ������ �� ���������� ����������
   if (usePBI == PBI_SELECTED)
    {
     // �������� ���������������� ����� PriceBasedIndicator
     handlePBI_1  = iCustom(_Symbol,pbiPeriod,"PriceBasedIndicator");   
     if ( handlePBI_1 == INVALID_HANDLE )
      {
       Print("������ ��� ����������� �������� SimpleTrend. �� ������� ������� ����� ���������� PriceBasedIndicator");
       return (INIT_FAILED);
      } 
     // �������� ��������� ��� ������ �� 3-� �����������
     lastTrendPBI_1  = GetLastTrendDirection(handlePBI_1,pbiPeriod);
     lastTrendPBI_2  = lastTrendPBI_1;
     lastTrendPBI_3  = lastTrendPBI_1;           
    }           
  // ���� ������������� ������������� ����������
  else if (usePBI == PBI_FIXED) 
   {
     // �������� ���������������� ����� PriceBasedIndicator
     handlePBI_1  = iCustom(_Symbol,PERIOD_M5,"PriceBasedIndicator");   
     handlePBI_2  = iCustom(_Symbol,PERIOD_M15,"PriceBasedIndicator");  
     handlePBI_3  = iCustom(_Symbol,PERIOD_H1,"PriceBasedIndicator");            
     if ( handlePBI_1 == INVALID_HANDLE || handlePBI_2 == INVALID_HANDLE || handlePBI_3 == INVALID_HANDLE)
      {
       Print("������ ��� ����������� �������� SimpleTrend. �� ������� ������� ����� ���������� PriceBasedIndicator");
       return (INIT_FAILED);
      } 
     // �������� ��������� ��� ������ �� 3-� �����������
     lastTrendPBI_1  = GetLastTrendDirection(handlePBI_1,PERIOD_M5);
     lastTrendPBI_2  = GetLastTrendDirection(handlePBI_2,PERIOD_M15);
     lastTrendPBI_3  = GetLastTrendDirection(handlePBI_3,PERIOD_H1); 
   }
  // ���� ������������ ������� �� ���� �� NineTeenLines
  if (useLinesLock)
   {
    handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines");     
    if (handle_19Lines == INVALID_HANDLE)
     {
      Print("������ ��� ������������� �������� SimpleTrend. �� ������� �������� ����� NineteenLines");
      return (INIT_FAILED);
     }    
   }
  // ���� ������������ ������ �� ���� �� MACD
  if (useMACDLock)
   {
   // ������� ����� ���������� ShowMeYourDivMACD
   handleMACDM5  = iCustom (_Symbol,PERIOD_M5,"smydMACD");
   handleMACDM15 = iCustom (_Symbol,PERIOD_M15,"smydMACD");
   handleMACDH1  = iCustom (_Symbol,PERIOD_H1,"smydMACD");   
   if ( handleMACDM5 == INVALID_HANDLE || handleMACDM15 == INVALID_HANDLE || handleMACDH1 == INVALID_HANDLE )
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ShowMeYourDivMACD");
     return (INIT_FAILED);
    }
   } 
   // ������� ������ ������ TradeManager
   ctm = new CTradeManager();  
   // ������� ������� ������ CisNewBar
   isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
   // ������� ������� ������ CBlowInfoFromExtremums
   blowInfo[0]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M1,100,30,30,217);  // M1 
   blowInfo[1]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5,100,30,30,217);  // M5 
   blowInfo[2]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,100,30,30,217); // M15 
   blowInfo[3]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1,100,30,30,217);  // H1          
   if (!blowInfo[0].IsInitFine() )
        return (INIT_FAILED);
   curPriceAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);  
   curPriceBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);  
   ArrayInitialize(extrHighBeaten,false);
   ArrayInitialize(extrLowBeaten,false);   
   lotReal = lot;
   
   pos_info.tp = 0;
   pos_info.volume = lotReal;
   pos_info.expiration = 0;
   pos_info.priceDifference = 0;
 
   trailing.trailingType = TRAILING_TYPE_EXTREMUMS;
   trailing.minProfit    = 0;
   trailing.trailingStop = 0;
   trailing.trailingStep = 0;
   trailing.handlePBI    = 0;  
   
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   ArrayFree(lastBarD1);
   ArrayFree(pbiBuf);
   // ������� ������� �������
   delete ctm;
   // ����������� ������ �����������
   IndicatorRelease(handleMACDM5);
   IndicatorRelease(handleMACDM15);
   IndicatorRelease(handleMACDH1);
   IndicatorRelease(handle_19Lines);
   delete isNewBar_D1;
   delete blowInfo[0];
   delete blowInfo[1];
   delete blowInfo[2];
   delete blowInfo[3];  
  }

void OnTick()
{     
 ctm.OnTick(); 
 ctm.UpdateData();
 ctm.DoTrailing(blowInfo[indexForTrail]); 

 
 prevPriceAsk = curPriceAsk;                             // �������� ���������� ���� Ask
 prevPriceBid = curPriceBid;                             // �������� ���������� ���� Bid
 curPriceBid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // �������� ������� ���� Bid    
 curPriceAsk  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // �������� ������� ���� Ask
 
 if (!blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),100) ||
     !blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),100) ||
     !blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),100) ||
     !blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),100)
    )
 {   
  return;
 }
 /*
Comment("��������� ��������� ��� = ",blowInfo[1].ShowExtrType(blowInfo[1].GetLastExtrType()) ,
        "\n ��������� ��������� = ",DoubleToString( blowInfo[1].GetExtrByIndex(EXTR_HIGH,0).price )
  );
 */
 // ���� �� ���������� ������ �� ���� �� NineTeenLines
 if (useLinesLock)
 {
  // ���� �� ������� ���������� ������ NineTeenLines
  if ( !Upload19LinesBuffers () ) 
   return;
 }
 
 // �������� ����� �������� �����������
 for (int index = 0; index < 4; index++)
 {
  currentExtrHigh[index]  = blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);
  currentExtrLow[index]   = blowInfo[index].GetExtrByIndex(EXTR_LOW,0);    
  if (currentExtrHigh[index].time != lastExtrHigh[index].time && currentExtrHigh[index].price)          // ���� ������ ����� HIGH ���������
  {
   lastExtrHigh[index] = currentExtrHigh[index];   // �� ��������� ������� ��������� � �������� ����������
   extrHighBeaten[index] = false;                  // � ���������� ���� ��������  � false     
  }
  if (currentExtrLow[index].time != lastExtrLow[index].time && currentExtrLow[index].price)            // ���� ������ ����� LOW ���������
  {
   lastExtrLow[index] = currentExtrLow[index];     // �� ��������� ������� ��������� � �������� ����������
   extrLowBeaten[index] = false;                   // � ���������� ���� �������� � false
  } 
 } 
 // ���� ������������ PriceBasedIndicator � ��������� �����������
 if (usePBI == PBI_SELECTED)
 {
  // ��������� �������� ���������� ������
  tmpLastBar = GetLastMoveType(handlePBI_1);
  if (tmpLastBar != 0)
  {
   lastTrendPBI_1 = tmpLastBar;
   lastTrendPBI_2 = tmpLastBar;
   lastTrendPBI_3 = tmpLastBar;
  }   
 }
 // ���� ������������ PriceBasedIndicator � �������������� ������������
 else if (usePBI == PBI_FIXED)
 {
  // ��������� �������� ���������� ������
  tmpLastBar = GetLastMoveType(handlePBI_1);
  if (tmpLastBar != 0)
  {
   lastTrendPBI_1 = tmpLastBar;
  }   
  // ��������� �������� ���������� ������
  tmpLastBar = GetLastMoveType(handlePBI_2);
  if (tmpLastBar != 0)
  {
   lastTrendPBI_2 = tmpLastBar;
  }   
  // ��������� �������� ���������� ������
  tmpLastBar = GetLastMoveType(handlePBI_3);
  if (tmpLastBar != 0)
  {
   lastTrendPBI_3 = tmpLastBar;
  }           
 } 
 // ���� ��� ������ ������ �������� ��� ������������� ����� ��� 
 if (firstLaunch || isNewBar_D1.isNewBar() > 0)
 {
  firstLaunch = false;
  if ( CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1) == 2 )     
  {
   lastTendention = GetTendention(lastBarD1[0].open,lastBarD1[0].close);        // �������� ���������� ��������� 
  }
 }
 
 // ���� ��� �������� �������
 if (ctm.GetPositionCount() == 0)
  openedPosition = NO_POSITION;
 else    // ����� ������ ������ ��������� � ����������, ���� ��� ��������
 {
  ChangeTrailIndex();                            // �� ������ ������ ���������
  if (countAdd < lotCount && changeLotValid)     // ���� ���� ��������� ������ lotCount ������� � ���� ���������� �� �������
  {
   if (ChangeLot())                              // ���� �������� ������ �� ��������� 
   {

    ctm.PositionChangeSize(_Symbol, lotStep);    // ���������� 
   }       
  }        
 }
 
 // ���� ����� ���������  - �����
 if (lastTendention == TENDENTION_UP && GetTendention (lastBarD1[1].open,curPriceBid) == TENDENTION_UP)
 {   
  // ���� ������� ���� ������� ���� �� ���������� �� ����� �� ����������� � ������� ����������� MACD �� ������������ �������� ��������
  if (  ((beatM5=IsExtremumBeaten(1,BUY)) && (lastTrendPBI_1==BUY||usePBI==PBI_NO)) || 
        ((beatM15=IsExtremumBeaten(2,BUY))&& (lastTrendPBI_2==BUY||usePBI==PBI_NO)) || 
        ((beatH1=IsExtremumBeaten(3,BUY)) && (lastTrendPBI_3==BUY||usePBI==PBI_NO))  )
  {        
   // ���� ����� �� ��������� �������� ����� �������
   if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
   {
    // ���� ������������ ������� �� smydMACD
    if (useMACDLock)
     {
      // ���� ������� M5 � ������ MACD �� M5 ���������������, �� ��������� �����������
      if (beatM5&&GetMACDSignal(handleMACDM5)==SELL)
       return;
      // ���� ������� M15 � ������ MACD �� M15 ���������������, �� ��������� �����������
      if (beatM15&&GetMACDSignal(handleMACDM15)==SELL)
       return;
      // ���� ������� H1 � ������ MACD �� H1 ���������������, �� ��������� �����������
      if (beatH1&&GetMACDSignal(handleMACDH1)==SELL)
       return;
     }
    // ���� ������������ ������� �� NineTeenLines
    if (useLinesLock)
     {
      // �������� ���������� �� ��������� ������� ����� � ������
      lenClosestUp   = GetClosestLevel(BUY);
      lenClosestDown = GetClosestLevel(SELL);
      // ���� �������� ������ �� ������ �� ����
      if (lenClosestUp != 0 && 
        LessOrEqualDoubles(lenClosestUp, lenClosestDown*koLock) )
         {
          return;
         }   
     }
    // ���� ������� �� ���� ��� ������� �� BUY   
    if (openedPosition != BUY)
    {
     // �������� ������� ���������
     indexForTrail = 0; 
     // �������� ������� �������, ���� 
     countAdd = 0;                                   
    }
    if (useMultiFill || openedPosition!=BUY)
    // ��������� ����������� ����������
    changeLotValid = true; 
    // ���������� ���� �������� ������� BUY
    openedPosition = BUY;                 
    // ���������� ��� �� ���������
    lotReal = lot;
    // ��������� ���� ����
    stopLoss = GetStopLoss();        
    // ��������� ��������� �������� �������
    pos_info.type = OP_BUY;
    pos_info.sl = stopLoss;    
    // ��������� ������� �� BUY
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing,100);

   }
  }
 }
 
 // ���� ����� ��������� - ����
 if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPriceAsk) == TENDENTION_DOWN)
 {                     
  // ���� ������� ���� ������� ���� �� ���������� �� ����� �� ����������� � ������� ����������� MACD �� ������������ �������� ��������
  if ( ((beatM5=IsExtremumBeaten(1,SELL)) && (lastTrendPBI_1==SELL||usePBI==PBI_NO)) || 
       ((beatM15=IsExtremumBeaten(2,SELL))&& (lastTrendPBI_2==SELL||usePBI==PBI_NO)) || 
       ((beatH1=IsExtremumBeaten(3,SELL)) && (lastTrendPBI_3==SELL||usePBI==PBI_NO)))  
  {                
   // ���� ����� �� ��������� �������� ����� �������
   if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
   {    
    // ���� ������������ ������� �� smydMACD
    if (useMACDLock)
     {
      // ���� ������� M5 � ������ MACD �� M5 ���������������, �� ��������� �����������
      if (beatM5 && GetMACDSignal(handleMACDM5)==BUY)
       return;
      // ���� ������� M15 � ������ MACD �� M15 ���������������, �� ��������� �����������
      if (beatM15 && GetMACDSignal(handleMACDM15)==BUY)
       return;
      // ���� ������� H1 � ������ MACD �� H1 ���������������, �� ��������� �����������
      if (beatH1 && GetMACDSignal(handleMACDH1)==BUY)
       return;
     }   
    // ���� ������������ ������� �� NineTeenLines
    if (useLinesLock)
     { 
     // �������� ���������� �� ��������� ������� ����� � ������
     lenClosestUp   = GetClosestLevel(BUY);
     lenClosestDown = GetClosestLevel(SELL);    
     // ���� �������� ������ ������� �� ����
     if (lenClosestDown != 0 &&
         LessOrEqualDoubles(lenClosestDown, lenClosestUp*koLock) )
         {            
          return;
         }
     }
    // ���� ������� �� ���� ��� ������� �� SELL
    if (openedPosition != SELL)
    {
     // �������� ������� ���������
     indexForTrail = 0; 
     // �������� ������� �������
     countAdd = 0;  
    }
   }
   if (useMultiFill || openedPosition!=SELL)
   // ��������� ����������� ����������
   changeLotValid = true; 
   // ���������� ���� �������� ������� SELL
   openedPosition = SELL;                 
   // ���������� ��� �� ���������
   lotReal = lot;    
   // ��������� ���� ����
   stopLoss = GetStopLoss();   
   // ��������� ��������� �������� �������
   pos_info.type = OP_SELL;
   pos_info.sl = stopLoss;    
   // ��������� ������� �� SELL 
  // ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing,100);
  }
 } 
}
  
// ����������� �������
ENUM_TENDENTION GetTendention (double priceOpen,double priceAfter)            // ���������� ��������� �� ���� �����
{
 if ( GreatDoubles (priceAfter,priceOpen) )
  return (TENDENTION_UP);
 if ( LessDoubles  (priceAfter,priceOpen) )
  return (TENDENTION_DOWN); 
 return (TENDENTION_NO); 
}

bool IsExtremumBeaten (int index,int direction)   // ��������� �������� ����� ����������
{
 switch (direction)
 {
  case SELL:
   if (LessDoubles(curPriceAsk,lastExtrLow[index].price)&& GreatDoubles(prevPriceAsk,lastExtrLow[index].price) && !extrLowBeaten[index])
   {      
    extrLowBeaten[index] = true;
    return (true);    
   }     
  break;
  case BUY:
   if (GreatDoubles(curPriceBid,lastExtrHigh[index].price) && LessDoubles(prevPriceBid,lastExtrHigh[index].price) && !extrHighBeaten[index])
   {
    extrHighBeaten[index] = true;
    return (true);
   }     
  break;
 }
 return (false);
}
 
void  ChangeTrailIndex()   // ������� ������ ������ ���������� ��� ���������
{
  // ������� ���� ����
  if (indexForTrail < (lotCount-1))  // ��������� �� ������� ��������� � ������, ���� ������ �� H1
  {
   // ���� ������� ��������� �� ����� ������� ����������
   if (IsExtremumBeaten ( indexForTrail+1, openedPosition) )
   {
    indexForTrail ++;  // �� ��������� �� ����� ������� ���������
    changeLotValid = false; // ��������� ����������
   }
   else if (countAdd == lotCount)  // ���� ���� ������� 4 �������
        {
         indexForTrail ++;  // �� ��������� �� ����� ������� ��������� 
         changeLotValid = false; // ��������� ����������
         countAdd = lotCount+1;
        }
  }
}
   
bool ChangeLot()    // ������� �������� ������ ����, ���� ��� �������� (�������)
{
 int cont = 0;
 double pricePos = ctm.GetPositionPrice(_Symbol);

// � ����������� �� ���� �������� �������
 switch (openedPosition)
 {
  case BUY:  // ���� ������� ������� �� BUY
   if ( blowInfo[0].GetLastExtrType() == EXTR_LOW )  // ���� ��������� ��������� LOW
   {
    if (IsExtremumBeaten(0,BUY) && 
        GreatDoubles(ctm.GetPositionStopLoss(_Symbol),pricePos)
       ) // ���� ������ ��������� � ���� ���� � ���������
    {
     countAdd++; // ����������� ������� �������
     return (true);
    }
   } 
  break;
  case SELL: // ���� ������� ������� �� SELL
   if ( blowInfo[0].GetLastExtrType() == EXTR_HIGH ) // ���� ��������� ��������� HIGH
   {
    if (IsExtremumBeaten(0,SELL) &&
        LessDoubles(ctm.GetPositionStopLoss(_Symbol),pricePos)
       ) // ���� ������ ��������� � ���� ���� � ���������
    {
     cont++;
     countAdd++; // ����������� ������� �������
     return (true);
    }   
   }
  break;
 }
 return(false);
}
 
int GetStopLoss()     // ��������� ���� ����
{
 double slValue;          // �������� ���� �����
 double stopLevel;        // ���� �����
 stopLevel = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;  // �������� ���� �����
 switch (openedPosition)
 {
  case BUY:
   slValue = curPriceBid - blowInfo[0].GetExtrByIndex(EXTR_LOW,0).price; 
   if ( GreatDoubles(slValue,stopLevel) )
    return ( slValue/_Point );
   else
    return ( (stopLevel+0.0001)/_Point );
  case SELL:
   slValue = blowInfo[0].GetExtrByIndex(EXTR_HIGH,0).price - curPriceAsk;
   if ( GreatDoubles(slValue,stopLevel) )
    return ( slValue/_Point );     
   else
    return ( (stopLevel+0.0001)/_Point );     
 }
 return (0.0);
}
  
 int GetLastTrendDirection (int handle,ENUM_TIMEFRAMES period)   // ���������� true, ���� ��������� �� ������������ ���������� ������ �� ������� ����������
 {
  int copiedPBI=-1;     // ���������� ������������� ������ PriceBasedIndicator
  int signTrend=-1;     // ���������� ��� �������� ����� ���������� ������
  int index=1;          // ������ ����
  int nBars;            // ���������� �����
  
  ArraySetAsSeries(pbiBuf,true);
  
  nBars = Bars(_Symbol,period);
  
  for (int attempts=0;attempts<25;attempts++)
   {
     copiedPBI = CopyBuffer(handle,4,1,nBars-1,pbiBuf);
     //Sleep(100);
   }
  if (copiedPBI < (nBars-1))
   {
   // Comment("�� ������� ����������� ��� ����");
    return (0);
   }
  for (index=0;index<nBars-1;index++)
   {
    signTrend = int(pbiBuf[index]);
    // ���� ������ ��������� ����� �����
    if (signTrend == 1 || signTrend == 2)
     return (1);
    // ���� ������ ��������� ����� ����
    if (signTrend == 3 || signTrend == 4)
     return (-1);
   }
  
  return (0);
 }
 
 int  GetLastMoveType (int handle) // �������� ��������� �������� PriceBasedIndicator
  {
   int copiedPBI;
   int signTrend;
   copiedPBI = CopyBuffer(handle,4,1,1,pbiBuf);
   if (copiedPBI < 1)
    return (0);
   signTrend = int(pbiBuf[0]);
   // ���� ����� �����
   if (signTrend == 1 || signTrend == 2)
    return (1);
   // ���� ����� ����
   if (signTrend == 3 || signTrend == 4)
    return (-1);
   return (0);
  }
  
bool Upload19LinesBuffers ()   // �������� ��������� �������� �������
 {
  int copiedPrice;
  int copiedATR;
  int indexPer;
  int indexBuff;
  int indexLines = 0;
  for (indexPer=1;indexPer<5;indexPer++)
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
      for (index=0;index<8;index++)
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
      for (index=0;index<8;index++)
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
  
  // ������ ���������� ������ �� MACD
  int  GetMACDSignal (int handleMACD)
   {
    double bufMACD[];
    int copiedMACD;
    for (int attempts = 0; attempts < 5; attempts ++)
     {
       copiedMACD = CopyBuffer(handleMACD,1,1,lenToMACD,bufMACD);
     }
    if (copiedMACD < lenToMACD)
     {
      Print("������! �� ������� ���������� ����� smydMACD");
      return (0);
     }
    // �������� �� ������� �������� MACD � ���� ��������� �����������
    for (int ind=lenToMACD-1;ind>=0;ind--)
     {
      if (int(bufMACD[ind])!=0)
       {
        //Comment("������ = ",int(bufMACD[ind])," ������ = ",ind );     
        return ( int(bufMACD[ind]) );
       }
     }
     //Comment("��� �������");
    return (0);
   }
   
   