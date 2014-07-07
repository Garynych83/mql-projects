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
#include <Lib CisNewBarDD.mqh>           // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>            // ��� ��������� ������������ �����
#include <TradeManager\TradeManager.mqh> // �������� ����������
#include <BlowInfoFromExtremums.mqh>     // ����� �� ������ � ������������ ���������� DrawExtremums

// ������������ � ���������
enum ENUM_TENDENTION
 {
  TENDENTION_NO = 0,     // ��� ���������
  TENDENTION_UP,         // ��������� �����
  TENDENTION_DOWN        // ��������� ����
 };
 
// ��������� ��������
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0

// ������� ���������
sinput string baseStr = "";                                        // �������� ���������
input  double lot     = 0.1;                                       // ��������� ���
input  double lot_step = 0.1;                                      // ��� ���������� ����
input  ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_EXTREMUMS;  // ��� ���������

// ������ ���������� SmydMACD
int handleSmydMACD_M5;                             // ����� ���������� ����������� MACD �� �������
int handleSmydMACD_M15;                            // ����� ���������� ����������� MACD �� 15 �������
int handleSmydMACD_H1;                             // ����� ���������� ����������� MACD �� ��������

// ����������� ������
MqlRates lastBarD1[];                              // ����� ��� �� ��������

// ������� �������
CTradeManager *ctm;                                // ������ �������� ����������
CisNewBar     *isNewBar_D1;                        // ����� ��� �� D1
CisNewBar     *isNewBar_M1;                        // ����� ��� �� M1
CisNewBar     *isNewBar_M5;                        // ����� ��� �� M5
CisNewBar     *isNewBar_M15;                       // ����� ��� �� M15
CisNewBar     *isNewBar_H1;                        // ����� ��� �� H1

CBlowInfoFromExtremums *blowInfo[4];               // ������ �������� ������ ��������� ���������� �� ����������� ���������� DrawExtremums 

bool blowInfoFlag0;
bool blowInfoFlag1;
bool blowInfoFlag2;
bool blowInfoFlag3;

// �������������� ��������� ����������
bool             firstLaunch       = true;         // ���� ������� ������� ��������
int              openedPosition    = 0;            // ��� �������� ������� 
int              countAddingToLot  = 0;            // ������� �������
int              indexForTrail     = 0;            // ������ ������� BlowInfoFromExtremums ��� ��������� 
double           curPrice          = 0;            // ��� �������� ������� ����
double           prevPrice         = 0;            // ��� �������� ���������� ����
double           stopLoss;                         // ���������� ��� �������� ���� �����
ENUM_TENDENTION  lastTendention;                   // ���������� ��� �������� ��������� ���������

// ������ ��� �������� ����������� �� MACD
double divMACD_M5[];                               // �� �����������
double divMACD_M15[];                              // �� 15-�������
double divMACD_H1[];                               // �� ��������

// �������� ��������� ������� ������
ENUM_TENDENTION GetTendention(double priceOpen,double priceAfter);  // ���������� ��������� 
bool            IsMACDCompatible (int direction);  // ��������� ������������� ����������� MACD � ������� ����������
bool            IsExtremumBeaten (int index,
                                  int direction);  // ��������� �������� ���������� �� �������
                                  
  

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // ��������� ������������� ��������
   // �������� ���������������� ������ ����������� MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,PERIOD_M5,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,PERIOD_M15,"smydMACD");    
   handleSmydMACD_H1  = iCustom(_Symbol,PERIOD_H1,"smydMACD");  
       
   if (handleSmydMACD_M5  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� SmydMACD �� M5");
     errorValue = INIT_FAILED;
    }      
   if (handleSmydMACD_M15  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� SmydMACD �� M15");
     errorValue = INIT_FAILED;     
    }        
   if (handleSmydMACD_H1  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� SmydMACD �� H1");
     errorValue = INIT_FAILED;  
    }          
   // ������� ������ ������ TradeManager
   ctm = new CTradeManager();                    
   // ������� ������� ������ CisNewBar
   isNewBar_D1  = new CisNewBar(_Symbol,PERIOD_D1);
   isNewBar_M1  = new CisNewBar(_Symbol,PERIOD_M1);
   isNewBar_M5  = new CisNewBar(_Symbol,PERIOD_M5);
   isNewBar_M15 = new CisNewBar(_Symbol,PERIOD_M15);
   isNewBar_H1  = new CisNewBar(_Symbol,PERIOD_H1);
   // ������� ������� ������ CBlowInfoFromExtremums
   blowInfo[0] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M1);   // �������
   blowInfo[1] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M5);   // 5-�� �������
   blowInfo[2] = new CBlowInfoFromExtremums(_Symbol,PERIOD_M15);  // 15-�� �������
   blowInfo[3] = new CBlowInfoFromExtremums(_Symbol,PERIOD_H1);   // �������      
   return(errorValue);
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
   delete isNewBar_H1;
   delete isNewBar_M1;
   delete isNewBar_M5;
   delete isNewBar_M15;
   delete isNewBar_H1;
  }

void OnTick()
  {
   // blowInfoFlag0 = blowInfo[0].Upload();
   // blowInfoFlag1 = blowInfo[1].Upload();
   // blowInfoFlag2 = blowInfo[2].Upload();
   // blowInfoFlag3 = blowInfo[3].Upload();
    ctm.OnTick(); 
    ctm.UpdateData();
    ctm.DoTrailing(blowInfo[indexForTrail]);
    prevPrice = curPrice;                                // �������� ���������� ����
    curPrice  = SymbolInfoDouble(_Symbol, SYMBOL_BID);   // �������� ������� ����
    
    if (firstLaunch || isNewBar_M1.isNewBar() > 0)
     blowInfoFlag0 = blowInfo[0].Upload();
    if (firstLaunch || isNewBar_M5.isNewBar() > 0)
     blowInfoFlag1 = blowInfo[1].Upload();
    if (firstLaunch || isNewBar_M15.isNewBar() > 0)
     blowInfoFlag2 = blowInfo[2].Upload();
    if (firstLaunch || isNewBar_H1.isNewBar() > 0)
     blowInfoFlag3 = blowInfo[3].Upload();   
                 
    // ���� ��� ������ ������ �������� ��� ������������� ����� ��� 
    if (firstLaunch || isNewBar_D1.isNewBar() > 0)
    {
     firstLaunch = false;
     if ( CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1) == 2 )     
      {
       lastTendention = GetTendention(lastBarD1[0].open,lastBarD1[0].close);        // �������� ���������� ��������� 
      }
    }
    if ( blowInfoFlag3 )
     Comment("",blowInfo[3].ShowExtrType(blowInfo[3].GetLastExtrType()) );    
    
    // �� ������ ���� 
    if ( ctm.GetPositionCount() == 0 )   // ���� ������� ��� �� �������
    {
     // ���� ����� ���������  - �����
     if (lastTendention == TENDENTION_UP && GetTendention (lastBarD1[1].open,curPrice) == TENDENTION_UP)
     {
      // ���� ������� ���� ������� ���� �� ���������� �� ����� �� �����������
      if ( IsExtremumBeaten(1,BUY) || IsExtremumBeaten(2,BUY) || IsExtremumBeaten(3,BUY) )
      
      {
       // ���� ������� ����������� MACD �� ������������ �������� ��������
       if (IsMACDCompatible(BUY))
       {                 
        // ��������� ���� ���� �� ���������� ������� ����������, ��������� � ������
        stopLoss = int(blowInfo[1].GetExtrByIndex(EXTR_LOW,0).price/_Point);
        // ��������� ������� �� BUY
        ctm.OpenUniquePosition(_Symbol, _Period, OP_BUY, lot, stopLoss, 0, trailingType);
        // ���������� ���� �������� ������� BUY
        openedPosition = BUY;         
        // �������� ������ ������� ���������� Extremums ��� ���������
        indexForTrail = 0;           
       } 
       
      }
     }
     // ���� ����� ��������� - ����
     if (lastTendention == TENDENTION_DOWN && GetTendention (lastBarD1[1].open,curPrice) == TENDENTION_DOWN)
     {           
      // ���� ������� ���� ������� ���� �� ���������� �� ����� �� �����������
      if ( IsExtremumBeaten(1,SELL) || IsExtremumBeaten(2,SELL) || IsExtremumBeaten(3,SELL)   )
      {
     //  Comment("����� ��������� ����"); 
       // ���� ������� ����������� MACD �� ������������ �������� ��������
       if (IsMACDCompatible(SELL))
       {
        // ��������� ���� ���� �� ���������� ����������, ��������� � ������
        stopLoss = int(blowInfo[1].GetExtrByIndex(EXTR_HIGH,0).price/_Point);
        // ��������� ������� �� SELL
        ctm.OpenUniquePosition(_Symbol, _Period, OP_SELL, lot, stopLoss, 0, trailingType);
        // ���������� ���� �������� ������� SELL
        openedPosition = SELL;  
        // �������� ������ ������� ���������� Extremums ��� ���������
        indexForTrail = 0;                                         
       } 
      }      
     }
    }
    // ���� ���� �������� �������
    else
    { 
      // ���� ������� ���� ������� �� BUY
      if (openedPosition == BUY) 
       {
        if (countAddingToLot < 4)
          {
           // ���� ���� ������� ��������� ������� ��������� �� M1
           if ( IsExtremumBeaten(0,BUY) )
            {
             // �� ���������� 
             ctm.PositionChangeSize(_Symbol, lot_step);
             // � ����������� ���������� ������� �� �������
             countAddingToLot++;
            } 
          }
         // ���� ��� ����� ���������� �� ����� ������� ���������
         if ( indexForTrail < 3)
           {
            if (  IsExtremumBeaten (indexForTrail+1,BUY) )    // ���� ���� ������� ��������� �������� ����������
               indexForTrail ++; 
           }          
       }

      // ���� ������� ���� ������� �� SELL
      if (openedPosition == SELL) 
       {
        if (countAddingToLot < 4)
          {
           // ���� ���� ������� ��������� ������� ��������� �� M1
           if ( IsExtremumBeaten(0,SELL) )
            {
             // �� ���������� 
             ctm.PositionChangeSize(_Symbol, lot_step);
             // � ����������� ���������� ������� �� �������
             countAddingToLot++;
            } 
          }
         // ���� ��� ����� ���������� �� ����� ������� ���������
         if ( indexForTrail < 3)
           {
            if (  IsExtremumBeaten (indexForTrail+1,SELL) )    // ���� ���� ������� ��������� �������� ����������
               indexForTrail ++; 
           }          
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
  Extr   lastExtrHigh;                                         // ��������� HIGH ���������
  Extr   lastExtrLow;                                          // ��������� LOW ���������
  ENUM_EXTR_USE last_extr;                                     // ���������� ��� �������� ���������� ���������� 
   // �������� ��� ���������� ����������
   last_extr = blowInfo[index].GetLastExtrType();
   if (last_extr == EXTR_NO)
    return (0.0);
   if (direction == OP_BUY)
    {
     // ���� ��������� ����������� ��� HIGH ��� BOTH
     if (last_extr == EXTR_HIGH || last_extr == EXTR_BOTH)
       lastExtrHigh = blowInfo[index].GetExtrByIndex(EXTR_HIGH,1);  // �� ����� ��� �������� ������������� ���������
     if (last_extr == EXTR_LOW)
      lastExtrHigh  = blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);  // �� ����� ��� �������� ��������� ��������� 
     lastExtrLow = blowInfo[index].GetExtrByIndex(EXTR_LOW,0);      // �������� ��������� ������ ���������
     // ���� ������� ���� ������� ��������� �������� HIGH ���������
     if ( GreatDoubles(curPrice,lastExtrHigh.price) && GreatDoubles(lastExtrHigh.price,prevPrice) && prevPrice > 0 )
      {
       // �� ��������� true (���� ������� ���������)
       return (true);
      }
    }
    
   if (direction == OP_SELL)
    {
      // ���� ��������� ����������� ��� LOW ��� BOTH
      if (last_extr == EXTR_LOW || last_extr == EXTR_BOTH)
       lastExtrLow = blowInfo[index].GetExtrByIndex(EXTR_LOW,1);  // �� ����� ��� �������� ������������� ���������
      if (last_extr == EXTR_HIGH)
       lastExtrLow  = blowInfo[index].GetExtrByIndex(EXTR_LOW,0);  // �� ����� ��� �������� ��������� ��������� 
      lastExtrHigh = blowInfo[index].GetExtrByIndex(EXTR_HIGH,0);  // �������� ��������� ������� ���������
      // ���� ������� ���� ������� ��������� �������� HIGH ��������� 
      if ( LessDoubles(curPrice,lastExtrLow.price) && LessDoubles(lastExtrLow.price,prevPrice) && prevPrice > 0 )
       {
        // �� ��������� true (���� ������� ���������)
        return (true);
       }
    }
  return (false);
 }   