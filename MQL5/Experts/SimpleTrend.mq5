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
input int    spread   = 30;                        // ����������� ���������� ������ ������ � ������� �� �������� � ������� �������
input string lotAddParam="";                       // ��������� �������
input bool   useMultiFill=true;                    // ������������ ������� ��� �������� �� �����. ������
input double lotStep  = 1;                         // ������ ���� ���������� ����
input int    lotCount = 3;                         // ���������� �������
input string pbiParam = "";                        // ��������� PriceBasedIndicator
input ENUM_PBI  usePBI = PBI_NO;                   // ���  ������������� PBI
input ENUM_TIMEFRAMES pbiPeriod = PERIOD_H1;       // ������ PBI
input string lockParams="";                        // ��������� �������� �� ����
input bool useLinesLock=false;                     // ���� ��������� ������� �� ���� �� ���������� NineTeenLines
input int    koLock  = 2;                          // ����������� ������� �� ����
input bool   useExtr = true;                       // ������������ �������� �����������
input bool   useClose = true;                      // ������������ �������� close-�
input int indexStopLoss = 0;                       // ������ �� �������� ���������� ���� ����
// ��������� �������
struct bufferLevel
 {
  double price[];  // ���� ������
  double atr[];    // ������ ������
 };
// ����������� ������
MqlRates lastBarD1[];                              // ����� ��� �� ��������
// ������ PriceBasedIndicator
int handlePBI_1;
int handlePBI_2;
int handlePBI_3;
// ����� ���������� NineTeenLines
int handle_19Lines; 
// ������ ���������� DrawExtremums
int aHandleExtremums[4];
// ������ ��� �������� �������� �����������
int      countExtrHigh[4];                         // ������ ��������� ����������� HIGH
int      countExtrLow[4];                          // ������ ��������� ����������� LOW
int      countLastExtrHigh[4];                     // ������ ��������� �������� ��������� ����������� HIGH 
int      countLastExtrLow[4];                      // ������ �������� �������� ��������� ����������� LOW
bool     beatenExtrHigh[4];                        // ������ ������ �������� ����������� HIGH
bool     beatenExtrLow[4];                         // ������ ������ �������� ����������� LOW
double   closes[];                                 // ������ ��� �������� ��� �������� ��������� ���� ����� 
// ������� �������
CTradeManager *ctm;                                // ������ �������� ����������                                                     
CisNewBar     *isNewBar_D1;                        // ����� ��� �� D1
CBlowInfoFromExtremums *blowInfo[4];               // ������ �������� ������ ��������� ���������� �� ����������� ���������� DrawExtremums 
// �������������� ��������� ����������
bool             firstLaunch       = true;         // ���� ������� ������� ��������
bool             beatM5;                           // ���� �������� �� M5
bool             beatM15;                          // ���� �������� �� M15
bool             beatH1;                           // ���� �������� �� H1
bool             beatCloseM5;                      // ���� �������� ��������� ���� close M5
bool             beatCloseM15;                     // ���� �������� ��������� ���� close M15
bool             beatCloseH1;                      // ���� �������� ��������� ���� close H1
int              openedPosition    = NO_POSITION;  // ��� �������� ������� 
int              stopLoss;                         // ���� ����
int              indexForTrail     = 0;            // ������ ��� ���������
int              tmpLastBar;

double           curPriceAsk       = 0;            // ��� �������� ������� ���� Ask
double           curPriceBid       = 0;            // ��� �������� ������� ���� Bid 
double           prevPriceAsk      = 0;            // ��� �������� ���������� ���� Ask
double           prevPriceBid      = 0;            // ��� �������� ���������� ���� Bid
double           lotReal;                          // �������������� ���

// ���������� �������
int              countAdd          = 0;            // ���������� �������
bool             changeLotValid    = false;        // ���� ����������� ������� �� M1
// ���������� PriceBasedIndicator
int              lastTrendPBI_1    = 0;            // ��� ���������� ������ �� PBI 
int              lastTrendPBI_2    = 0;            // ��� ���������� ������ �� PBI
int              lastTrendPBI_3    = 0;            // ��� ���������� ������ �� PBI
double pbiBuf[];                                   // ����� ��� �������� PriceBasedIndicator
ENUM_TENDENTION lastTendention, currentTendention; // ���������� ��� �������� ����������� ����������� � �������� �����
// ���������� � ������ NineTeenLines
double signalBuffer[];                             // ����� ��� ��������� ������� �� ���������� smydMACD
bufferLevel buffers[8];                            // ����� �������
double           lenClosestUp;                     // ���������� �� ���������� ������ ������
double           lenClosestDown;                   // ���������� �� ���������� ������ ����� 
// ��������� ��� ������ � ���������            
SPositionInfo pos_info;                            // ���������� �� �������� ������� 
STrailing trailing;                                // ��������� ���������
// ����� ���������� �������� �������
datetime  timeOpenPos = 0;
// ����� ��� �������� �������
datetime  timeBuf[]; 
int OnInit()
 {     
  // ���� �� ���������� PriceBasedIndicator ��� ���������� ���������� ������ �� ��������� ����������
  if (usePBI == PBI_SELECTED)
  {
  // �������� ���������������� ����� PriceBasedIndicator
   handlePBI_1 = iCustom(_Symbol, pbiPeriod, "PriceBasedIndicator");   
   if ( handlePBI_1 == INVALID_HANDLE )
   {
    Print("������ ��� ����������� �������� SimpleTrend. �� ������� ������� ����� ���������� PriceBasedIndicator");
    return (INIT_FAILED);
   } 
   // �������� ��������� ��� ������ �� 3-� �����������
   lastTrendPBI_1 = GetLastTrendDirection(handlePBI_1, pbiPeriod);
   lastTrendPBI_2 = lastTrendPBI_1;
   lastTrendPBI_3 = lastTrendPBI_1;           
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
   lastTrendPBI_1 = GetLastTrendDirection(handlePBI_1,PERIOD_M5);
   lastTrendPBI_2 = GetLastTrendDirection(handlePBI_2,PERIOD_M15);
   lastTrendPBI_3 = GetLastTrendDirection(handlePBI_3,PERIOD_H1); 
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
  // ������������� ��������
  ArrayInitialize(countExtrHigh,0);
  ArrayInitialize(countExtrLow,0);
  ArrayInitialize(countLastExtrHigh,0);
  ArrayInitialize(countLastExtrLow,0);
  ArrayInitialize(beatenExtrHigh,false);
  ArrayInitialize(beatenExtrLow,false);      
  // ������� ������ ������ TradeManager
  ctm  = new CTradeManager();  
  // ������� ������� ������ CisNewBar
  isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
  
  aHandleExtremums[0] = iCustom(_Symbol, PERIOD_M1, "DrawExtremums");
  aHandleExtremums[1] = iCustom(_Symbol, PERIOD_M5, "DrawExtremums");
  aHandleExtremums[2] = iCustom(_Symbol, PERIOD_M15, "DrawExtremums");
  aHandleExtremums[3] = iCustom(_Symbol, PERIOD_H1, "DrawExtremums");
  
  // ������� ������� ������ CBlowInfoFromExtremums
  for (int i = 0; i < 4; ++i)
  {
   blowInfo[i] = new CBlowInfoFromExtremums(aHandleExtremums[i]);  // M1 
  }
  
  curPriceAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);  
  curPriceBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);    
  lotReal = lot;
   
  pos_info.tp = 0;
  pos_info.volume = lotReal;
  pos_info.expiration = 0;
  pos_info.priceDifference = 0;
  trailing.trailingType = TRAILING_TYPE_EXTREMUMS;
  trailing.minProfit    = 0;
  trailing.trailingStop = 0;
  trailing.trailingStep = 0;
  trailing.handleForTrailing = 0; 
  
  return(INIT_SUCCEEDED);
 }
 
void OnDeinit(const int reason)
{
 ArrayFree(lastBarD1);
 ArrayFree(pbiBuf);
 ArrayFree(timeBuf);
 ArrayFree(closes);
 // ������� ������� �������
 delete ctm;
 delete isNewBar_D1;
 delete blowInfo[0];
 delete blowInfo[1];
 delete blowInfo[2];
 delete blowInfo[3]; 
 // ����������� ������ ����������� 
 if (usePBI == PBI_SELECTED) IndicatorRelease(handlePBI_1);  
 if (usePBI == PBI_FIXED)
 {
  IndicatorRelease(handlePBI_1);  
  IndicatorRelease(handlePBI_1);  
  IndicatorRelease(handlePBI_1);  
 }
 if (useLinesLock) IndicatorRelease(handle_19Lines);   
 for (int i = 0; i < 4; ++i)
 {
  IndicatorRelease(aHandleExtremums[i]);  
 }
}

int countDeal = 0;
int lastDeal = 0;

void OnTick()
{     
 int copied = 0;        // ���������� ������������� ������ �� ������
 int attempts = 0;      // ���������� ������� ����������� ������ �� ������

 ctm.OnTick(); 
 ctm.UpdateData();
 ctm.DoTrailing(aHandleExtremums[indexForTrail]); 
 
 prevPriceAsk = curPriceAsk;                             // �������� ���������� ���� Ask
 prevPriceBid = curPriceBid;                             // �������� ���������� ���� Bid
 curPriceBid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // �������� ������� ���� Bid    
 curPriceAsk  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // �������� ������� ���� Ask
 if (!blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) ||
     !blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) ||
     !blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) ||
     !blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),1000)
    )
 {   
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
  return;
 }
 // ���� �� ���������� ������ �� ���� �� NineTeenLines
 if (useLinesLock)
 {
  // ���� �� ������� ���������� ������ NineTeenLines
  if (!Upload19LinesBuffers()) 
  {
   Print("�� ������� ���������� ������ NineTeenLines");
   return;
  }
 } 
 // �������� ����� �������� ��������� �����������
 for (int ind = 0; ind < 4; ind++)
 {
  countExtrHigh[ind] = blowInfo[ind].GetExtrCountHigh();   // �������� ������� �������� �������� ����������� HIGH
  countExtrLow[ind]  = blowInfo[ind].GetExtrCountLow();    // �������� ������� �������� �������� ����������� LOW
  // ���� ������� ����������� High ��������� 
  if (countExtrHigh[ind] != countLastExtrHigh[ind])
  {
   // ��������� �������� ��������
   countLastExtrHigh[ind] = countExtrHigh[ind];
   // ���������� ���� �������� ���������� � false
   beatenExtrHigh[ind] = false; 
  } 
  // ���� ������� ����������� Low ���������
  if (countExtrLow[ind] != countLastExtrLow[ind])
  {
   // ��������� �������� ��������
   countLastExtrLow[ind] = countExtrLow[ind];
   // ���������� ���� �������� ���������� � false
   beatenExtrLow[ind] = false; 
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
  while (copied < 2 && attempts < 5 && !IsStopped())
  {
   copied = CopyRates(_Symbol, PERIOD_D1, 0, 2, lastBarD1);
   attempts++;
   Sleep(111);
  }
  
  if (copied == 2 )     
  {
   lastTendention = GetTendention(lastBarD1[0].open, lastBarD1[0].close);        // �������� ���������� ��������� 
   copied = 0;
   attempts = 0;
  }
  else
  {
   firstLaunch = true;
   return;
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
    Print("���������� lotCount = ",lotCount);
    ctm.PositionChangeSize(_Symbol, lotStep);    // ���������� 
   }       
  }        
 }
 currentTendention = GetTendention(lastBarD1[1].open, curPriceBid);
 // ���� ����� ���������  - �����
 if (lastTendention == TENDENTION_UP && currentTendention == TENDENTION_UP)
 {   
  // ���� ������� ���� ������� ���� �� ���������� �� ����� �� �����������
  if ( ( (beatM5       =  IsExtremumBeaten(1,BUY) ) && (lastTrendPBI_1==BUY||usePBI==PBI_NO) && useExtr)    || 
       ( (beatM15      =  IsExtremumBeaten(2,BUY) ) && (lastTrendPBI_2==BUY||usePBI==PBI_NO) && useExtr)    || 
       ( (beatH1       =  IsExtremumBeaten(3,BUY) ) && (lastTrendPBI_3==BUY||usePBI==PBI_NO) && useExtr)    ||
       ( (beatCloseM5  = IsLastClosesBeaten(PERIOD_M5,BUY))      && (lastTrendPBI_1==BUY)    && useClose) ||
       ( (beatCloseM15 = IsLastClosesBeaten(PERIOD_M15,BUY))     && (lastTrendPBI_2==BUY)    && useClose) ||
       ( (beatCloseH1  = IsLastClosesBeaten(PERIOD_H1,BUY))      && (lastTrendPBI_3==BUY)    && useClose)         
       )
   {      

 // ���� ������������ ������� �� NineTeenLines
    if (useLinesLock)
     {
      Print("���������� ������ �� 19 ������");
      // �������� ���������� �� ��������� ������� ����� � ������
      lenClosestUp   = GetClosestLevel(BUY);
      lenClosestDown = GetClosestLevel(SELL);
      // ���� �������� ������ �� ������ �� ����
      if (lenClosestUp != 0 && 
        LessOrEqualDoubles(lenClosestUp, lenClosestDown*koLock) )
         {
          Print("�������� ������ ������� �� ���� �� BUY");
          return;
         }   
     }   
    // ���� ������� �� ���� ��� ������� �� BUY   
    if (openedPosition != BUY)
    {
     // �������� ������� ���������
     indexForTrail = indexStopLoss;
     // �������� ������� �������, ���� 
     countAdd = 0;                                         
    }   
   if (useMultiFill || openedPosition!=BUY)
   {
   // ��������� ����������� ����������
    changeLotValid = true;
   }     
    if (openedPosition!=BUY) 
    countDeal++;   
    // ���������� ���� �������� ������� BUY
    openedPosition = BUY;                 
    // ���������� ��� �� ���������
    lotReal = lot;
    // ��������� ���� ����
    stopLoss = GetStopLoss();        
    // ��������� ��������� �������� �������
    pos_info.type = OP_BUY;
    pos_info.sl = stopLoss;    
    pos_info.volume = lotReal; 
    // ��������� ������� �� BUY
      if ( ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread) )
        {
         timeOpenPos = TimeCurrent();
         lastDeal = BUY;
        }    
   }
  }
 
 // ���� ����� ��������� - ����
 if (lastTendention == TENDENTION_DOWN && currentTendention == TENDENTION_DOWN)
 {                     
  // ���� ������� ���� ������� ���� �� ���������� �� ����� �� ����������� 
  if ( ( (beatM5   =  IsExtremumBeaten(1,SELL) ) && (lastTrendPBI_1==SELL||usePBI==PBI_NO) && useExtr) || 
       ( (beatM15  =  IsExtremumBeaten(2,SELL) ) && (lastTrendPBI_2==SELL||usePBI==PBI_NO) && useExtr) || 
       ( (beatH1   =  IsExtremumBeaten(3,SELL) ) && (lastTrendPBI_3==SELL||usePBI==PBI_NO) && useExtr) || 
       ( (beatCloseM5  = IsLastClosesBeaten(PERIOD_M5,SELL))   && (lastTrendPBI_1==SELL)   && useClose)  ||
       ( (beatCloseM15 = IsLastClosesBeaten(PERIOD_M15,SELL))  && (lastTrendPBI_2==SELL)   && useClose)  ||
       ( (beatCloseH1  = IsLastClosesBeaten(PERIOD_H1,SELL))   && (lastTrendPBI_3==SELL)   && useClose)       
        )  
  {    
    // ���� ������������ ������� �� NineTeenLines
    if (useLinesLock)
     { 
     Print("���������� ������ �� 19 ������");
     // �������� ���������� �� ��������� ������� ����� � ������
     lenClosestUp   = GetClosestLevel(BUY);
     lenClosestDown = GetClosestLevel(SELL);    
     // ���� �������� ������ ������� �� ����
     if (lenClosestDown != 0 &&
         LessOrEqualDoubles(lenClosestDown, lenClosestUp*koLock) )
         {        
          Print("�������� ������ ������� �� ���� �� SELL");
          return;
         }
     }                
    // ���� ������� �� ���� ��� ������� �� SELL
    if (openedPosition != SELL)
    {
     // �������� ������� ���������
     indexForTrail = indexStopLoss; 
     // �������� ������� �������, ���� 
     countAdd = 0;        
    }
   if (useMultiFill || openedPosition!=SELL)
   {
   // ��������� ����������� ����������
    changeLotValid = true;
   } 
   if (openedPosition!=SELL)
   countDeal++;          
   // ���������� ���� �������� ������� SELL
   openedPosition = SELL;                 
   // ���������� ��� �� ���������
   lotReal = lot;    
   // ��������� ���� ����
   stopLoss = GetStopLoss();   
   // ��������� ��������� �������� �������
   pos_info.type = OP_SELL;
   pos_info.sl = stopLoss;   
   pos_info.volume = lotReal;  
   // ��������� ������� �� SELL 
     if ( ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread) )
      {
       timeOpenPos = TimeCurrent();
       lastDeal = SELL;
      }
  } 
  }
}
  
// ����������� �������
ENUM_TENDENTION GetTendention (double priceOpen,double priceAfter)            // ���������� ��������� �� ���� �����
{
 if (GreatDoubles (priceAfter, priceOpen))
  return (TENDENTION_UP);
 if (LessDoubles  (priceAfter, priceOpen))
  return (TENDENTION_DOWN); 
 return (TENDENTION_NO); 
}

bool IsExtremumBeaten (int index,int direction)   // ��������� �������� ����� ����������
{
 switch (direction)
 {
  case SELL:
   if (LessDoubles(curPriceBid,blowInfo[index].GetExtrByIndex(EXTR_LOW,0).price)&& GreatDoubles(prevPriceBid,blowInfo[index].GetExtrByIndex(EXTR_LOW,0).price) && !beatenExtrLow[index])
   {
    beatenExtrLow[index] = true;
    return (true);    
   }     
  break;
  case BUY:
   if (GreatDoubles(curPriceBid,blowInfo[index].GetExtrByIndex(EXTR_HIGH,0).price) && LessDoubles(prevPriceBid,blowInfo[index].GetExtrByIndex(EXTR_HIGH,0).price) && !beatenExtrHigh[index])
   {
    beatenExtrHigh[index] = true;
    return (true);
   }     
  break;
 }
 return (false);
}
 
void ChangeTrailIndex()   // ������� ������ ������ ���������� ��� ���������
{
 // ������� ���� ����
 while (indexForTrail < 3 && IsExtremumBeaten(indexForTrail+1, openedPosition))  // ��������� �� ������� ��������� � ������, ���� ������ �� H1
 {
  indexForTrail++;  // �� ��������� �� ����� ������� ���������
    changeLotValid = false; // ���������� ���� ����������� ������� � false
 }
}
 
int GetStopLoss()         // ��������� ���� ����
{
 int slValue;          // �������� ���� �����
 int stopLevel;        // ���� �����
 stopLevel = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);  // �������� ���� �����
 switch (openedPosition)
 {
  case BUY:
   slValue = (curPriceBid - blowInfo[indexStopLoss].GetExtrByIndex(EXTR_LOW,0).price)/_Point; 
   if ( slValue > stopLevel )
    {
     return ( slValue );
    }
   else
    {
     return ( stopLevel+1 );
    }
  case SELL:
   slValue = (blowInfo[indexStopLoss].GetExtrByIndex(EXTR_HIGH,0).price - curPriceAsk)/_Point;
   if ( slValue > stopLevel )
    {   
     return ( slValue );     
    }
   else
    {
     return ( stopLevel+1 );     
    }
 }
 return (0);
}

bool ChangeLot()    // ������� �������� ������ ����, ���� ��� �������� (�������)
{
 double pricePos = ctm.GetPositionPrice(_Symbol);
 double posAverPrice;  // ������� ���� ������� 
 // � ����������� �� ���� �������� �������
 switch (openedPosition)
 {
  case BUY:  // ���� ������� ������� �� BUY
   if ( blowInfo[indexStopLoss].GetPrevExtrType() == EXTR_LOW )  // ���� ��������� ��������� LOW
   { 
    // �������� ����� ������� ���� �������
    posAverPrice = (lotReal*pricePos + lotStep*SymbolInfoDouble(_Symbol,SYMBOL_ASK) ) / (lotReal+lotStep);   
    if (IsExtremumBeaten(indexStopLoss,BUY)  && 
        GreatDoubles(ctm.GetPositionStopLoss(_Symbol),posAverPrice) 
       ) // ���� ������ ��������� � ���� ���� � ���������
    { 
     countAdd++; // ����������� ������� �������
     return (true);
    }
   } 
  break;
  case SELL: // ���� ������� ������� �� SELL
   if ( blowInfo[indexStopLoss].GetPrevExtrType() == EXTR_HIGH ) // ���� ��������� ��������� HIGH
   {   
    // �������� ����� ������� ���� �������
    posAverPrice = (lotReal*pricePos + lotStep*SymbolInfoDouble(_Symbol,SYMBOL_BID) ) / (lotReal+lotStep);      
    if (IsExtremumBeaten(indexStopLoss,SELL) &&
        LessDoubles(ctm.GetPositionStopLoss(_Symbol),posAverPrice)  
       ) // ���� ������ ��������� � ���� ���� � ���������
    {
     countAdd++; // ����������� ������� �������
     return (true);
    }   
   }
  break;
 }
 return(false);
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
  // ������� ��������� �������� ��� close ��������� ���� �����
  bool IsLastClosesBeaten (ENUM_TIMEFRAMES period,int direction)
   {
    // �������� ����������� ����� �������� ���������� ����
    if ( CopyTime(_Symbol,period,1,1,timeBuf) < 1 )
     {
      Print("�� ������� ����������� ����� �������� ���������� ����");
      return false;
     }
    // ���� ����� �������� ��������� ������� ������ ������� �������� ���������� ����
    if (timeOpenPos < timeBuf[0])
     {
     // �������� ����������� ���� �������� ��������� 3-� �����
     if ( CopyClose(_Symbol,period,1,3,closes) < 3 )
      {
       Print("�� ������� ����������� ���� close 3-� ��������� �������������� �����");
       return false;
      }
     switch (direction)
      {
       case BUY:
        // ���� ���� close �� ��������� ���� ������� ���� close �� ���� ���������� 
        if ( GreatDoubles(closes[2],closes[1]) && GreatDoubles (closes[2],closes[0]) && LessDoubles(closes[1],closes[0]) )
         {
         return true;
        }
      case SELL:
       // ���� ���� close �� ��������� ���� ������� ���� close �� ���� ����������
       if ( LessDoubles(closes[2],closes[1]) && LessDoubles (closes[2],closes[0]) && GreatDoubles(closes[1],closes[0]) )
        {  
         return true;
        }
      }
     }
    return false;
   }  