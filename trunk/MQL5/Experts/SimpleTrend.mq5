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
 
// ������� ���������
input double lot      = 0.20;                      // ������ ����
input double lotStep  = 0.20;                      // ������ ���� ���������� ����
input int    lotCount = 4;                         // ���������� �������
input int    spread   = 30;                        // ����������� ���������� ������ ������ � ������� �� �������� � ������� �������

// ������ ���������� SmydMACD
int handleSmydMACD_M5;                             // ����� ���������� ����������� MACD �� �������
int handleSmydMACD_M15;                            // ����� ���������� ����������� MACD �� 15 �������
int handleSmydMACD_H1;                             // ����� ���������� ����������� MACD �� ��������

// ����������� ������
MqlRates lastBarD1[];                              // ����� ��� �� ��������
// ������ ��� �������� ����������� �� MACD
double divMACD_M5[];                               // �� �����������
double divMACD_M15[];                              // �� 15-�������
double divMACD_H1[];                               // �� ��������
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
double           curPriceAsk       = 0;            // ��� �������� ������� ���� Ask
double           curPriceBid       = 0;            // ��� �������� ������� ���� Bid 
double           prevPriceAsk      = 0;            // ��� �������� ���������� ���� Ask
double           prevPriceBid      = 0;            // ��� �������� ���������� ���� Bid
double           lotReal;                          // �������������� ���
ENUM_TENDENTION  lastTendention;                   // ���������� ��� �������� ��������� ���������
                           
int OnInit()
  {
   // �������� ���������������� ������ ����������� MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,PERIOD_M5,"smydMACD","");  
   handleSmydMACD_M15 = iCustom(_Symbol,PERIOD_M15,"smydMACD","");    
   handleSmydMACD_H1  = iCustom(_Symbol,PERIOD_H1,"smydMACD","");   
   if (handleSmydMACD_M5  == INVALID_HANDLE || handleSmydMACD_M15 == INVALID_HANDLE || handleSmydMACD_H1 == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� SmydMACD ");
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
 Comment("������ ������ = ",indexForTrail);
 prevPriceAsk = curPriceAsk;                             // �������� ���������� ���� Ask
 prevPriceBid = curPriceBid;                             // �������� ���������� ���� Bid
 curPriceBid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // �������� ������� ���� Bid    
 curPriceAsk  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // �������� ������� ���� Ask
 if (blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
     blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
     blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
     blowInfo[3].Upload(EXTR_BOTH,TimeCurrent(),1000)
    )
 {   
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
   // ���� ������� ���� ������� ���� �� ���������� �� ����� �� �����������
   if ( IsExtremumBeaten(1,BUY) || IsExtremumBeaten(2,BUY) || IsExtremumBeaten(3,BUY) )
   { 
    // ���� ������� ����������� MACD �� ������������ �������� ��������
    if (IsMACDCompatible(BUY))
    {                       
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
      // ��������� ����������� ����������
      changeLotValid = true; 
      // ���������� ���� �������� ������� BUY
      openedPosition = BUY;                 
      // ���������� ��� �� ���������
      lotReal = lot;
      // ��������� ���� ����
      stopLoss = GetStopLoss();             
      // ��������� ������� �� BUY
      ctm.OpenUniquePosition(_Symbol, _Period, OP_BUY, lotReal, stopLoss, 0,TRAILING_TYPE_EXTREMUMS);
     }
    } 
   }
  }
  // ���� ����� ��������� - ����
  if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPriceAsk) == TENDENTION_DOWN)
  {                     
   // ���� ������� ���� ������� ���� �� ���������� �� ����� �� �����������
   if ( IsExtremumBeaten(1,SELL) || IsExtremumBeaten(2,SELL) || IsExtremumBeaten(3,SELL) )
   {                
    // ���� ������� ����������� MACD �� ������������ �������� ��������
    if (IsMACDCompatible(SELL))
    {
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
      // ��������� ����������� ����������
      changeLotValid = true; 
      // ���������� ���� �������� ������� SELL
      openedPosition = SELL;                 
      // ���������� ��� �� ���������
      lotReal = lot;    
      // ��������� ���� ����
      stopLoss = GetStopLoss();    
      // ��������� ������� �� SELL
      ctm.OpenUniquePosition(_Symbol, _Period, OP_SELL, lotReal, stopLoss, 0,TRAILING_TYPE_EXTREMUMS);
     }
    } 
   }      
  }
 }  // END OF UPLOAD EXTREMUMS
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
  // ���� ������� ��������� �� ����� ������� ����������
  if (IsExtremumBeaten ( indexForTrail+1, openedPosition) )
  {
   indexForTrail ++;  // �� ��������� �� ����� ������� ���������
   changeLotValid = false; // ��������� ����������
  }
  else if (countAdd == 4)  // ���� ���� ������� 4 �������
       {
        indexForTrail ++;  // �� ��������� �� ����� ������� ��������� 
        changeLotValid = false; // ��������� ����������
        countAdd = 5;
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
     Comment("������ ��������� = ",cont);
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
 Alert("� ����� ���");
 return (0.0);
}
  