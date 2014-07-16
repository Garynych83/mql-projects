//+------------------------------------------------------------------+
//|                                                     TRAILING.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ����� ��� ������������ ���������                                 |
//+------------------------------------------------------------------+
// ����������� ����������� ���������
#include <Lib CisNewBarDD.mqh>             // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>              // ��� ��������� ������������ �����
#include <TradeManager\TradeManager.mqh>   // �������� ����������
#include <BlowInfoFromExtremums.mqh>       // ����� �� ������ � ������������ ���������� DrawExtremums
#include <SIMPLE_TREND\SimpleTrendLib.mqh> // ���������� ������ Simple Trend

input  ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_EXTREMUMS;  // ��� ���������

// ��������� ���������� 
double curPrice;          // ������� ����
double prevPrice;         // ���������� ����
int    stopLoss;          // ���� ����
bool   openedPos = false; // ���� �������� �������
int    indexForTrail = 0; // ������ ��� ���������

// ������� ������� 
CBlowInfoFromExtremums *blowInfo[3];               // ������ �������� ������ ��������� ���������� �� ����������� ���������� DrawExtremums 
CTradeManager *ctm;                                // �������� ����������

// ������ ��� �������� �������� �����������
Extr             lastExtrHigh[3];                  // ����� ��������� ����������� �� HIGH
Extr             lastExtrLow[3];                   // ����� ��������� ����������� �� LOW
Extr             currentExtrHigh[3];               // ����� ������� ����������� �� HIGH
Extr             currentExtrLow[3];                // ����� ������� ����������� �� LOW
bool             extrHighBeaten[3];                // ����� ������ �������� ����������� HIGH
bool             extrLowBeaten[3];                 // ����� ������ �������� ����������� LOW

int OnInit()
  {
   ctm = new CTradeManager();
   blowInfo[0] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,1000,clrLightYellow,clrYellow);
   blowInfo[1] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15,1000,clrLightBlue,clrBlue);
   blowInfo[2] = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1,1000,clrPink,clrRed);
   if (!blowInfo[0].IsInitFine() || !blowInfo[1].IsInitFine() ||
       !blowInfo[2].IsInitFine())
        return (INIT_FAILED);
   // �������� ��������� ����������
   if ( blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) && 
        blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000) )
       
       
        {
         // �������� ������ ����������
         for (int index=0;index<3;index++)
           {
            lastExtrHigh[index]   =  blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);  // �������� �������� ���������� ���������� HIGH
            lastExtrLow[index]    =  blowInfo[index].GetExtrByIndex(EXTR_LOW,0);   // �������� �������� ���������� ���������� LOW
           }
       }
   else
     return (INIT_FAILED);   
   curPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID); 
   ArrayInitialize(extrHighBeaten,false);
   ArrayInitialize(extrLowBeaten,false);        
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {
   delete ctm;
   delete blowInfo[0];
   delete blowInfo[1];
   delete blowInfo[2];
  }
void OnTick()
  {
    ctm.OnTick();
    ctm.DoTrailing(blowInfo[indexForTrail]);   
    prevPrice = curPrice;                                // �������� ���������� ����
    curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // �������� ������� ����     
    if (!openedPos)
     {
      // ��������� ���� ���� �� ���������� ������� ����������, ��������� � ������
      stopLoss = int(MathAbs(curPrice - blowInfo[0].GetExtrByIndex(EXTR_LOW,0).price)/_Point); 
      ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0,stopLoss,0,trailingType);
      openedPos = true;
     }
    if (blowInfo[0].Upload(EXTR_BOTH,TimeCurrent(),1000) && 
        blowInfo[1].Upload(EXTR_BOTH,TimeCurrent(),1000) &&
        blowInfo[2].Upload(EXTR_BOTH,TimeCurrent(),1000)  )
        {   
    // �������� ����� �������� �����������
    for (int index=0;index<3;index++)
      {
       currentExtrHigh[index]  = blowInfo[index].GetExtrByIndex(EXTR_LOW,0);
       currentExtrLow[index]   = blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);    
       if (currentExtrHigh[index].time != lastExtrHigh[index].time)          // ���� ������ ����� HIGH ���������
        {
         lastExtrHigh[index] = currentExtrHigh[index];   // �� ��������� ������� ��������� � �������� ����������
         extrHighBeaten[index] = false;                  // � ���������� ���� ��������  � false     
        }
       if (currentExtrLow[index].time != lastExtrLow[index].time)            // ���� ������ ����� LOW ���������
        {
         lastExtrLow[index] = currentExtrLow[index];     // �� ��������� ������� ��������� � �������� ����������
         extrLowBeaten[index] = false;                   // � ���������� ���� �������� � false
        } 
      }
          
     // ������� ���� ����
   /*  if (indexForTrail < 3)  // ���� ������ ��������� 
      {
       if (IsExtremumBeaten ( indexForTrail, BUY) )
      }
   */


    } //END OF UPLOADS
  }
  
 bool IsExtremumBeaten (int index,int direction)   // ��������� �������� ����� ����������
 {
  switch (direction)
   {
    case BUY:
    if (LessDoubles(curPrice,lastExtrLow[index].price)&& GreatDoubles(prevPrice,lastExtrLow[index].price) && !extrLowBeaten[index])
      {      
       extrLowBeaten[index] = true;
       return (true);    
      }     
    break;
    case SELL:
    if (GreatDoubles(curPrice,lastExtrHigh[index].price) && LessDoubles(prevPrice,lastExtrHigh[index].price) && !extrHighBeaten[index])
      {
       extrHighBeaten[index] = true;
       return (true);
      }     
    break;
   }
  return (false);
 }   