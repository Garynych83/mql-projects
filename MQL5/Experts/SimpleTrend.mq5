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
// ��������� �������
struct bufferLevel
 {
  double price[];  // ���� ������
  double atr[];    // ������ ������
 };
/// ������� ���������
input string baseParam = "";                       // ������� ���������
input double lot      = 1;                         // ������ ����
input double lotStep  = 1;                         // ������ ���� ���������� ����
input int    lotCount = 3;                         // ���������� �������
input int    spread   = 30;                        // ����������� ���������� ������ ������ � ������� �� �������� � ������� �������
input string addParam = "";                        // ���������
input bool   useMultiFill=true;                    // ������������ ������� ��� �������� �� �����. ������
input  int   koLock   = 2;                         // ����������� ������� �� ����
input string pbiParam = "";                        // ��������� PriceBasedIndicator
input bool   usePBI=true;                          // ���� ������������� PBI
input int    pbiDepth = 1000;                      // ������� ���������� ���������� PBI
input ENUM_TIMEFRAMES pbiPeriod = PERIOD_H1;       // ������ PBI

// ����� PriceBasedIndicator
int handlePBI;                                     // ����� PriceBasedIndicator 
// ����� NineteenLines
int handle_19Lines;
// ����������� ������
MqlRates lastBarD1[];                              // ����� ��� �� ��������
// ����� ��� �������� PriceBasedIndicator
double pbiBuf[];
bufferLevel buffers[10];                           // ����� �������
// ������ ��� �������� �������� �����������
Extr             lastExtrHigh[4];                  // ����� ��������� ����������� �� HIGH
Extr             lastExtrLow[4];                   // ����� ��������� ����������� �� LOW
Extr             currentExtrHigh[4];               // ����� ������� ����������� �� HIGH
Extr             currentExtrLow[4];                // ����� ������� ����������� �� LOW
bool             extrHighBeaten[4];                // ����� ������ �������� ����������� HIGH
bool             extrLowBeaten[4];                 // ����� ������ �������� ����������� LOW

// ������� �������
CTradeManager *ctm;                                // ������ �������� ����������
CisNewBar     *isNewBar_D1;                        // ����� ��� �� D1
CBlowInfoFromExtremums *blowInfo[4];               // ������ �������� ������ ��������� ���������� �� ����������� ���������� DrawExtremums 

// �������������� ��������� ����������
bool             firstLaunch       = true;         // ���� ������� ������� ��������
bool             changeLotValid;                   // ���� ����������� ������� �� M1
int              openedPosition    = NO_POSITION;  // ��� �������� ������� 
int              stopLoss;                         // ���� ����
int              indexForTrail     = 0;            // ������ ��� ���������
int              countAdd          = 0;            // ���������� �������

int              lastTrendPBI      = 0;            // ��� ���������� ������ �� PBI 
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
   // ���� �� ���������� PriceBasedIndicator ��� ���������� ���������� ������
   if (usePBI)
    {
     // �������� ���������������� ����� PriceBasedIndicator
     handlePBI  = iCustom(_Symbol,pbiPeriod,"PriceBasedIndicator");   
     if ( handlePBI == INVALID_HANDLE )
      {
       Print("������ ��� ����������� �������� SimpleTrend. �� ������� ������� ����� ���������� PriceBasedIndicator");
       return (INIT_FAILED);
      } 
     // �������� ��������� ��� ������ �� 3-� �����������
     lastTrendPBI  = GetLastTrendDirection(handlePBI,pbiPeriod); 
    }           
   handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines");     
   if (handle_19Lines == INVALID_HANDLE)
     {
      Print("�� ������� �������� ����� NineteenLines");
      return (INIT_FAILED);
     }        
   // ������� ������ ������ TradeManager
   ctm = new CTradeManager();                    
   // ������� ������� ������ CisNewBar
   isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
   // ������� ������� ������ CBlowInfoFromExtremums
   blowInfo[0]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M1,1000,30,30,217);  // M1 
   blowInfo[1]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5,1000,30,30,217);  // M5 
   blowInfo[2]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,1000,30,30,217); // M15 
   blowInfo[3]  = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1,1000,30,30,217);  // H1          
   if (!blowInfo[0].IsInitFine() )
        return (INIT_FAILED);
   // �������� ��������� ����������
   if ( blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),1000)
    )
    {
     // �������� ������ ����������
     for (int index = 0; index < 4; index++)
     {
      lastExtrHigh[index]   =  blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);  // �������� �������� ���������� ���������� HIGH
      lastExtrLow[index]    =  blowInfo[index].GetExtrByIndex(EXTR_LOW,0);   // �������� �������� ���������� ���������� LOW
     }
    }
   else
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
   // ����������� ������ �����������
   IndicatorRelease(handle_19Lines);
   IndicatorRelease(handlePBI);   
   // ���������� ������ ������ ������ ���� �� D1
   ArrayFree(lastBarD1);
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
 ctm.OnTick(); 
 ctm.UpdateData();
 ctm.DoTrailing(blowInfo[indexForTrail]);
 
 prevPriceAsk = curPriceAsk;                             // �������� ���������� ���� Ask
 prevPriceBid = curPriceBid;                             // �������� ���������� ���� Bid
 curPriceBid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // �������� ������� ���� Bid    
 curPriceAsk  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // �������� ������� ���� Ask
 // ���� �� ������� ��������� ������ 19 �����
 if (!Upload19LinesBuffers ())
  {
   return;
  }
 
 if (!blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) ||
     !blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) ||
     !blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) ||
     !blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),1000)
    )
 {   
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
 // ���� ������������ PriceBasedIndicator
 if (usePBI)
  {
   // ��������� �������� ���������� ������
   tmpLastBar = GetLastMoveType(handlePBI);
   if (tmpLastBar != 0)
    lastTrendPBI = tmpLastBar;   
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
  if (countAdd < 4 && changeLotValid)            // ���� ���� ��������� ������ 4-� ������� � ���� ���������� �� �������
  {
   if (ChangeLot())                           // ���� �������� ������ �� ��������� 
   {
    ctm.PositionChangeSize(_Symbol, lotStep);   // ���������� 
   }       
  }        
 }
 
 // ���� ����� ���������  - �����
 if (lastTendention == TENDENTION_UP && GetTendention (lastBarD1[1].open,curPriceBid) == TENDENTION_UP)
 {   
  // ���� ������� ���� ������� ���� �� ���������� �� ����� �� ����������� � ������� ����������� MACD �� ������������ �������� ��������
  if (( IsExtremumBeaten(1,BUY) || IsExtremumBeaten(2,BUY) || IsExtremumBeaten(3,BUY) ) && (lastTrendPBI==BUY||!usePBI) )
  {        
   // ���� ����� �� ��������� �������� ����� �������
   if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
   {
    // �������� ���������� �� ��������� ������� ����� � ������
    lenClosestUp   = GetClosestLevel(BUY);
    lenClosestDown = GetClosestLevel(SELL);
    // ���� ��������� ������� ������ �����������, ��� ������ ���������� ������ �����
    if (lenClosestUp == 0 || 
        GreatDoubles(lenClosestUp, lenClosestDown*koLock) )
         {       

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
   /* Print("��������� UP = ",DoubleToString(lenClosestUp)," ���������� down = ",DoubleToString(lenClosestDown) );   
   Print("Ask = ",DoubleToString( SymbolInfoDouble(_Symbol,SYMBOL_ASK) ),
         " Bid = ",DoubleToString( SymbolInfoDouble(_Symbol,SYMBOL_BID) )
    ); */             
    // ��������� ������� �� BUY
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
     } // ����� �� �������� �� ������

   }
  }
 }
 
 // ���� ����� ��������� - ����
 if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPriceAsk) == TENDENTION_DOWN)
 {                     
  // ���� ������� ���� ������� ���� �� ���������� �� ����� �� ����������� � ������� ����������� MACD �� ������������ �������� ��������
  if (( IsExtremumBeaten(1,SELL) || IsExtremumBeaten(2,SELL) || IsExtremumBeaten(3,SELL) ) && (lastTrendPBI==SELL||!usePBI) )
  {                
   // ���� ����� �� ��������� �������� ����� �������
   if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
   { 
    // �������� ���������� �� ��������� ������� ����� � ������
    lenClosestUp   = GetClosestLevel(BUY);
    lenClosestDown = GetClosestLevel(SELL);               
    // ���� ��������� ������� ����� �����������, ��� ������ ���������� ������ ������
    if (lenClosestDown == 0 ||
        GreatDoubles(lenClosestDown, lenClosestUp*koLock) )
        {    
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
  /* Print("��������� UP = ",DoubleToString(lenClosestUp)," ���������� down = ",DoubleToString(lenClosestDown) );   
   Print("Ask = ",DoubleToString( SymbolInfoDouble(_Symbol,SYMBOL_ASK) ),
         " Bid = ",DoubleToString( SymbolInfoDouble(_Symbol,SYMBOL_BID) )
    ); */
   // ��������� ������� �� SELL
   ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
   } // ����� �� �������� �� ������
 
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
  
  for (index=1;index<nBars;index++)
   {
    copiedPBI = CopyBuffer(handle,4,index,1,pbiBuf);
    if (copiedPBI < 1)
     return(0);
    signTrend = int(pbiBuf[0]);
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
      break;
   }
   return (len);
  }