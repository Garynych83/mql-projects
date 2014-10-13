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
/// ������� ���������
input string baseParam = "";                       // ������� ���������
input double lot      = 1;                         // ������ ����
input int    spread   = 30;                        // ����������� ���������� ������ ������ � ������� �� �������� � ������� �������
// ����������� ������
MqlRates lastBarD1[];                              // ����� ��� �� ��������
// ����� ��� �������� PriceBasedIndicator
double pbiBuf[];
// ������ ��� �������� �������� �����������
int      countExtrHigh[4];                         // ������ ��������� ����������� HIGH
int      countExtrLow[4];                          // ������ ��������� ����������� LOW
int      countLastExtrHigh[4];                     // ������ ��������� �������� ��������� ����������� HIGH 
int      countLastExtrLow[4];                      // ������ �������� �������� ��������� ����������� LOW
bool     beatenExtrHigh[4];                        // ������ ������ �������� ����������� HIGH
bool     beatenExtrLow[4];                         // ������ ������ �������� ����������� LOW
// ������� �������
CTradeManager *ctm;                                // ������ �������� ����������                             
CisNewBar     *isNewBar_D1;                        // ����� ��� �� D1
CBlowInfoFromExtremums *blowInfo[4];               // ������ �������� ������ ��������� ���������� �� ����������� ���������� DrawExtremums 
// �������������� ��������� ����������
bool             firstLaunch       = true;         // ���� ������� ������� ��������
bool             changeLotValid;                   // ���� ����������� ������� �� M1
bool             beatM5;                           // ���� �������� �� M5
bool             beatM15;                          // ���� �������� �� M15
bool             beatH1;                           // ���� �������� �� H1
int              openedPosition    = NO_POSITION;  // ��� �������� ������� 
int              stopLoss;                         // ���� ����
int              indexForTrail     = 0;            // ������ ��� ���������
 
int              tmpLastBar;

double           curPriceAsk       = 0;            // ��� �������� ������� ���� Ask
double           curPriceBid       = 0;            // ��� �������� ������� ���� Bid 
double           prevPriceAsk      = 0;            // ��� �������� ���������� ���� Ask
double           prevPriceBid      = 0;            // ��� �������� ���������� ���� Bid
double           lotReal;                          // �������������� ���

ENUM_TENDENTION lastTendention, currentTendention; // ���������� ��� �������� ����������� ����������� � �������� �����

// ��������� ��� ������ � ���������            
SPositionInfo pos_info;                            // ���������� �� �������� ������� 
STrailing trailing;                                // ��������� ���������
                           
int OnInit()
 {     
  // ������������� ��������
  ArrayInitialize(countExtrHigh,0);
  ArrayInitialize(countExtrLow,0);
  ArrayInitialize(countLastExtrHigh,0);
  ArrayInitialize(countLastExtrLow,0);
  ArrayInitialize(beatenExtrHigh,false);
  ArrayInitialize(beatenExtrLow,false);      
  // ������� ������ ������ TradeManager
  ctm = new CTradeManager();  
  // ������� ������� ������ CisNewBar
  isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
  // ������� ������� ������ CBlowInfoFromExtremums
  blowInfo[0]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M1,100,30,30,217);  // M1 
  blowInfo[1]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5,100,30,30,217);  // M5 
  blowInfo[2]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,100,30,30,217); // M15 
  blowInfo[3]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1,100,30,30,217);  // H1          
  if (!blowInfo[0].IsInitFine())
     return (INIT_FAILED);
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
  trailing.handlePBI    = 0;  
  
  return(INIT_SUCCEEDED);
 }
 
void OnDeinit(const int reason)
  {
   ArrayFree(lastBarD1);
   ArrayFree(pbiBuf);
   // ������� ������� �������
   delete ctm;
   delete isNewBar_D1;
   delete blowInfo[0];
   delete blowInfo[1];
   delete blowInfo[2];
   delete blowInfo[3];  
  }

void OnTick()
{     
 int copied = 0;        // ���������� ������������� ������ �� ������
 int attempts = 0;      // ���������� ������� ����������� ������ �� ������

 ctm.OnTick(); 
 ctm.UpdateData();
 ctm.DoTrailing(blowInfo[indexForTrail]); 

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
  return;
 } 
 // �������� ����� �������� ��������� �����������
 for (int ind=0;ind<4;ind++)
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
 // ���� ��� ������ ������ �������� ��� ������������� ����� ��� 
 if (firstLaunch || isNewBar_D1.isNewBar() > 0)
 {
  firstLaunch = false;
  do
  {
   copied = CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1);
   attempts++;
   PrintFormat("attempts = %d, copied = %d", attempts, copied);
  }
  while (copied < 2 && attempts < 5 && !IsStopped());
  
  if (copied == 2 )     
  {
   lastTendention = GetTendention(lastBarD1[0].open, lastBarD1[0].close);        // �������� ���������� ��������� 
   copied = 0;
   attempts = 0;
 }
 }
 
 // ���� ��� �������� �������
 if (ctm.GetPositionCount() == 0)
  openedPosition = NO_POSITION;
 else    // ����� ������ ������ ��������� � ����������, ���� ��� ��������
 {
  ChangeTrailIndex();                            // �� ������ ������ ���������      
 }
 
 currentTendention = GetTendention(lastBarD1[1].open, curPriceBid);
// Comment(StringFormat("lastTendention = %s, currentTendention = %s", TendentionToString(lastTendention), TendentionToString(currentTendention)));
 // ���� ����� ���������  - �����
 if (lastTendention == TENDENTION_UP && currentTendention == TENDENTION_UP)
 {   
  // ���� ������� ���� ������� ���� �� ���������� �� ����� �� ����������� � ������� ����������� MACD �� ������������ �������� ��������
  if ( (beatM5  =  IsExtremumBeaten(1,BUY) )  || 
       (beatM15 =  IsExtremumBeaten(2,BUY) )  || 
       (beatH1  =  IsExtremumBeaten(3,BUY) )   )
   {      
    // ���� ������� �� ���� ��� ������� �� BUY   
    if (openedPosition != BUY)
    {
     // �������� ������� ���������
     indexForTrail = 0;                                  
    }   
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
   ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
   }
  }
 
 // ���� ����� ��������� - ����
 if (lastTendention == TENDENTION_DOWN && currentTendention == TENDENTION_DOWN)
 {                     
  // ���� ������� ���� ������� ���� �� ���������� �� ����� �� ����������� � ������� ����������� MACD �� ������������ �������� ��������
  if ( (beatM5   =  IsExtremumBeaten(1,SELL))  || 
       (beatM15  =  IsExtremumBeaten(2,SELL))  || 
       (beatH1   =  IsExtremumBeaten(3,SELL)) )  
  {                
    // ���� ������� �� ���� ��� ������� �� SELL
    if (openedPosition != SELL)
    {
     // �������� ������� ���������
     indexForTrail = 0; 
    }
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
   ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, spread);
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
 
void  ChangeTrailIndex()   // ������� ������ ������ ���������� ��� ���������
{
  // ������� ���� ����
  if (indexForTrail < 3)  // ��������� �� ������� ��������� � ������, ���� ������ �� H1
  {
   // ���� ������� ��������� �� ����� ������� ����������
   if (IsExtremumBeaten ( indexForTrail+1, openedPosition) )
   {
    indexForTrail ++;  // �� ��������� �� ����� ������� ���������
   }
  }
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