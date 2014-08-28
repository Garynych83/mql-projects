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
input double lotStep  = 1;                         // ������ ���� ���������� ����
input int    lotCount = 3;                         // ���������� �������
input int    spread   = 30;                        // ����������� ���������� ������ ������ � ������� �� �������� � ������� �������
input string addParam = "";                        // ���������
input bool   useMultiFill=true;                    // ������������ ������� ��� �������� �� �����. ������
input int    pbiDepth = 1000;                      // ������� ���������� ���������� PBI
input int    addToStopLoss = 50;                   // �������� ������� � ���������� ���� �����
input  int    koLock         = 2;                  // ����������� ������� �� ���� 

// ��������� �������
struct bufferLevel
 {
  double price[];  // ���� ������
  double atr[];    // ������ ������
 };

// ������ ���������� SmydMACD
int handleSmydMACD_M5;                             // ����� ���������� ����������� MACD �� �������
int handleSmydMACD_M15;                            // ����� ���������� ����������� MACD �� 15 �������
int handleSmydMACD_H1;                             // ����� ���������� ����������� MACD �� ��������
// ������ Price Based Indicator
int handlePBI_M1;                                  // ����� PriceBasedIndicator M1
int handlePBI_M5;                                  // ����� PriceBasedIndicator M5
int handlePBI_M15;                                 // ����� PriceBasedIndicator M15
int handlePBI_H1;                                  // ����� PriceBasedIndicator MH1
// ����� NineTeenLines
int handle_19Lines;
// ����������� ������
MqlRates lastBarD1[];                              // ����� ��� �� ��������
// ������ ��� �������� ����������� �� MACD
double divMACD_M5[];                               // �� �����������
double divMACD_M15[];                              // �� 15-�������
double divMACD_H1[];                               // �� ��������
// ����� ��� �������� PriceBasedIndicator
double pbiBuf[];
// ������ �������
bufferLevel buffers[10];                                                 // ����� �������
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

int              lastTrendM5       = 0;            // ��� ���������� ������ �� PBI M5
int              lastTrendM15      = 0;            // ��� ���������� ������ �� PBI M15
int              lastTrendH1       = 0;            // ��� ���������� ������ �� PBI H1
int              tmpLastBar;

double           curPriceAsk       = 0;            // ��� �������� ������� ���� Ask
double           curPriceBid       = 0;            // ��� �������� ������� ���� Bid 
double           prevPriceAsk      = 0;            // ��� �������� ���������� ���� Ask
double           prevPriceBid      = 0;            // ��� �������� ���������� ���� Bid
double           lotReal;                          // �������������� ���
double           lenClosestUp;                     // ���������� �� ���������� ������ ������
double           lenClosestDown;                   // ���������� �� ���������� ������ ����� 
ENUM_TENDENTION  lastTendention;                   // ���������� ��� �������� ��������� ���������
// ����� �������� ����������� ��� ��������� �������
bool             M5,M15,H1;
                           
SPositionInfo pos_info;
STrailing trailing;                           
                           
int OnInit()
  {
   // �������� ���������������� ������ ����������� MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,PERIOD_M5,"smydMACD","");  
   handleSmydMACD_M15 = iCustom(_Symbol,PERIOD_M15,"smydMACD","");    
   handleSmydMACD_H1  = iCustom(_Symbol,PERIOD_H1,"smydMACD","");   

   //iCustom(_Symbol,_Period,"NineteenLines");  
          
   if (handleSmydMACD_M5  == INVALID_HANDLE || handleSmydMACD_M15 == INVALID_HANDLE || handleSmydMACD_H1 == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� SmydMACD ");
     return (INIT_FAILED);
    }
   // �������� ���������������� ����� NineTeenLines      
   handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines");     
   if (handle_19Lines == INVALID_HANDLE)
     {
      Print("�� ������� �������� ����� NineteenLines");
      return (INIT_FAILED);
     }     
   // �������� ���������������� ����� PriceBasedIndicator
   handlePBI_M5  = iCustom(_Symbol,PERIOD_M5,"PriceBasedIndicator");
   handlePBI_M15 = iCustom(_Symbol,PERIOD_M15,"PriceBasedIndicator");    
   handlePBI_H1  = iCustom(_Symbol,PERIOD_H1,"PriceBasedIndicator");   
   if ( handlePBI_M5 == INVALID_HANDLE || 
       handlePBI_M15 == INVALID_HANDLE || handlePBI_H1 == INVALID_HANDLE)
    {
     Print("������ ��� ����������� �������� SimpleTrend. �� ������� ������� ����� ���������� PriceBasedIndicator");
     return (INIT_FAILED);
    } 
   // �������� ��������� ��� ������ �� 3-� �����������
   lastTrendM5  = GetLastTrendDirection(handlePBI_M5,PERIOD_M5);
   lastTrendM15 = GetLastTrendDirection(handlePBI_M15,PERIOD_M15);
   lastTrendH1  = GetLastTrendDirection(handlePBI_H1,PERIOD_H1);            
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
   // ����������� ������
   ArrayFree(divMACD_M5);
   ArrayFree(divMACD_M15);
   ArrayFree(divMACD_H1);
   ArrayFree(lastBarD1);
   // ������� ��� ����������
   IndicatorRelease(handleSmydMACD_M5);
   IndicatorRelease(handleSmydMACD_M15);   
   IndicatorRelease(handleSmydMACD_H1);
   IndicatorRelease(handlePBI_H1);
   IndicatorRelease(handlePBI_M15);
   IndicatorRelease(handlePBI_M5);
   IndicatorRelease(handle_19Lines);
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
 // ���� �� ������� ���������� ������ �������
 if (!UploadBuffers())
  return;
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
 
 // ��������� �������� ��������� �������
 tmpLastBar = GetLastMoveType(handlePBI_M5);
 if (tmpLastBar != 0)
  lastTrendM5 = tmpLastBar;
  
 tmpLastBar = GetLastMoveType(handlePBI_M15);
 if (tmpLastBar != 0)
  lastTrendM15 = tmpLastBar;
  
 tmpLastBar = GetLastMoveType(handlePBI_H1);
 if (tmpLastBar != 0)
  lastTrendH1 = tmpLastBar;    
  
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
  if (( (M5=IsExtremumBeaten(1,BUY)) || (M15=IsExtremumBeaten(2,BUY)) || (H1=IsExtremumBeaten(3,BUY)) ) /*&& IsMACDCompatible(BUY) */)
  { 
   // �������� ���������� �� ��������� ������� ����� � ������
   lenClosestUp   = GetClosestLevel(BUY);
   lenClosestDown = GetClosestLevel(SELL);  
   // ���� ��������� ������� ������ �����������, ��� ������ ���������� ������ �����
   if (lenClosestUp == 0 || 
       GreatDoubles(lenClosestUp, lenClosestDown*koLock) )
    {   
     // ���� ������ ������� ��������� �� H1, �� ��������� ����� �� H1 � ��������������� �������      
     if (H1 && lastTrendH1==-1 )
      {
       Comment("������ H1");    
       return;
      }
     // ���� ������ ������� ��������� �� M15, �� ��������� ����� �� M15 � ��������������� �������      
     if (M15 && lastTrendM15==-1 )
      {
       Comment("������ M15");    
       return;
      }
     // ���� ������ ������� ��������� �� M5, �� ��������� ����� �� M5 � ��������������� �������      
     if (M5 && lastTrendM5==-1 )
      {
       Comment("������ M5");     
       return;
      }
       
    // ���� ����� �� ��������� �������� ����� �������
    if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
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
     // ��������� ������� �� BUY
     pos_info.type = OP_BUY;
     pos_info.sl = stopLoss;
     ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
   } // ����� �� �������� �� ������
   
   }
  }
 }
 
 // ���� ����� ��������� - ����
 if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPriceAsk) == TENDENTION_DOWN)
 {                     
  // ���� ������� ���� ������� ���� �� ���������� �� ����� �� ����������� � ������� ����������� MACD �� ������������ �������� ��������
  if (( (M5=IsExtremumBeaten(1,SELL))  || (M15=IsExtremumBeaten(2,SELL)) || (H1=IsExtremumBeaten(3,SELL)) ) /*&& IsMACDCompatible(SELL)*/)
  {    
   // �������� ���������� �� ��������� ������� ����� � ������
   lenClosestUp   = GetClosestLevel(BUY);
   lenClosestDown = GetClosestLevel(SELL);
   // ���� ��������� ������� ����� �����������, ��� ������ ���������� ������ ������
    if (lenClosestDown == 0 ||
        GreatDoubles(lenClosestDown, lenClosestUp*koLock) )
       {      
        // ���� ������ ������ ��������� �� H1, �� ��������� ����� �� H1 � ��������������� �������      
        if (H1 && lastTrendH1==1 )
         {
          Comment("������ H1");
          return;
         }
        // ���� ������ ������ ��������� �� M15, �� ��������� ����� �� M15 � ��������������� �������      
        if (M15 && lastTrendM15==1 )
         {
          Comment("������ M15");    
          return;
         }
        // ���� ������ ������ ��������� �� M5, �� ��������� ����� �� M5 � ��������������� �������      
        if (M5 && lastTrendM5==1 )
         {
          Comment("������ M5");    
          return;
         }              
        // ���� ����� �� ��������� �������� ����� �������
        if (LessDoubles(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), spread))
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
        // ��������� ������� �� SELL
        pos_info.type = OP_SELL;
        pos_info.sl = stopLoss;
        ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
     }// ����� �������� �� ������
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
  
bool IsMACDCompatible(int direction)        // ���������, �� ������������ �� ����������� MACD ������� ���������
{
 int copiedMACD_M5  = CopyBuffer(handleSmydMACD_M5,1,0,1,divMACD_M5);
 int copiedMACD_M15 = CopyBuffer(handleSmydMACD_M15,1,0,1,divMACD_M15);
 int copiedMACD_H1  = CopyBuffer(handleSmydMACD_H1,1,0,1,divMACD_H1);   
 if (copiedMACD_M5  < 1 || copiedMACD_M15 < 1 || copiedMACD_H1  < 1)
 {
  Print("������ �������� SimpleTrend. �� ������� �������� ������ � ������������");
  return (false);
 }        
 // dir = 1 ��� -1, div = -1 ��� 1; ���� ����������� ������ �����������, �� ���-� ����� 0 = false, � ��������� ������ true
 return ((divMACD_M5[0]+direction) && (divMACD_M15[0]+direction) && (divMACD_H1[0]+direction));
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
 if (indexForTrail < 3)  // ��������� �� ������� ��������� � ������, ���� ������ �� H1
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
    return ( (slValue/_Point)+addToStopLoss );
   else
    return ( ((stopLevel+0.0001)/_Point)+addToStopLoss );
  case SELL:
   slValue = blowInfo[0].GetExtrByIndex(EXTR_HIGH,0).price - curPriceAsk;
   if ( GreatDoubles(slValue,stopLevel) )
    return ( (slValue/_Point)+addToStopLoss );     
   else
    return ( ((stopLevel+0.0001)/_Point)+addToStopLoss );     
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
  
  string GetLT(int type)
   {
    if (type == 1)
     return "����� �����";
    if (type == -1)
     return "����� ����";
    return "��� ������";
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
     