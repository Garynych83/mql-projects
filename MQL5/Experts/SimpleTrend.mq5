//+------------------------------------------------------------------+
//|                                                  SimpleTrend.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| �����, ��������� �� ������                                       |
//+------------------------------------------------------------------+

// ����������� ����������� ���������
#include <Lib CisNewBarDD.mqh>           // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>            // ��� ��������� ������������ �����
#include <TradeManager\TradeManager.mqh> // �������� ����������

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
input double lot     = 0.1;              // ��������� ���
input double lotStep = 0.2;              // ������ �������

// ��������� ����������

// ������ ���������� SmydMACD
int handleSmydMACD_M5;                   // ����� ���������� ����������� MACD �� �������
int handleSmydMACD_M15;                  // ����� ���������� ����������� MACD �� 15 �������
int handleSmydMACD_H1;                   // ����� ���������� ����������� MACD �� ��������
// ������ ������� ���������� Extremums
int handleExtremums[4];                  // 0 - M1,1 - M5, 2 - M15, 3 - H1             

// ����������
ENUM_TIMEFRAMES periodD1  = PERIOD_D1;   // �������
ENUM_TIMEFRAMES periodH1  = PERIOD_H1;   // �������
ENUM_TIMEFRAMES periodM5  = PERIOD_M5;   // 5-�� �������
ENUM_TIMEFRAMES periodM15 = PERIOD_M15;  // 15-�� �������
ENUM_TIMEFRAMES periodM1  = PERIOD_M1;   // �������

// ����������� ������
MqlRates lastBarD1[];                    // ����� ��� �� ��������

// ������� �������
CTradeManager *ctm;                      // ������ �������� ����������
CisNewBar     *isNewBar_D1;              // ����� ��� �� D1

 
// �������������� ��������� ����������
bool firstLaunch    = true;              // ���� ������� ������� ��������
int  openedPosition = 0;                 // ��� �������� ������� 
int  countAddingToLot = 0;               // ������� �������
int  indexHandleForTrail;                // ������ ������ ���������� Extremums ��� ��������� 
double curPrice;                         // ��� �������� ������� ����
double stopLoss;                         // ���������� ��� �������� ���� �����
double currentLot;                       // ������� ���
ENUM_TENDENTION  lastTendention;         // ���������� ��� �������� ��������� ���������
ENUM_TIMEFRAMES  periodForTrailing = PERIOD_M1; // ������ ��� ��������� 

// ������ ��� �������� �������� �����������
double lastExtr_M1_up[];                 // �������� ���������� �������� ���������� �� M1
double lastExtr_M1_down[];               // �������� ���������� ������� ���������� �� M1
double lastExtr_M5_up[];                 // �������� ���������� �������� ���������� �� M5
double lastExtr_M5_down[];               // �������� ���������� ������� ���������� �� M5
double lastExtr_M15_up[];                // �������� ���������� �������� ���������� �� M15
double lastExtr_M15_down[];              // �������� ���������� ������� ���������� �� M15
double lastExtr_H1_up[];                 // �������� ���������� �������� ���������� �� H1
double lastExtr_H1_down[];               // �������� ���������� ������� ���������� �� H1

// ������ ��� �������� ����������� �� MACD
double divMACD_M5[];                     // �� �����������
double divMACD_M15[];                    // �� 15-�������
double divMACD_H1[];                     // �� ��������

// �������� ��������� ������� ������
ENUM_TENDENTION GetLastTendention();               // ���������� ������������� ��������� �� ���������� ����
ENUM_TENDENTION GetCurrentTendention();            // ���������� ������� ��������� ����
bool            GetExtremums();                    // ���� �������� ����������� �� M5 M15 H1
bool            IsMACDCompatible (int direction);  // ��������� ������������� ����������� MACD � ������� ����������
double          ExtremumsTrailing (string symbol,ENUM_TM_POSITION_TYPE type,double sl, int handlePeriod); // ��������

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // ��������� ������������� ��������
   // �������� ���������������� ������ ����������� MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,periodM5,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD");    
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   // �������� ���������������� ������ ���������� Extremums
   handleExtremums[0]  = iCustom(_Symbol,periodM1,"DrawExtremums",false,PERIOD_M1);   
   handleExtremums[1]  = iCustom(_Symbol,periodM5,"DrawExtremums",false,PERIOD_M5);
   handleExtremums[2]  = iCustom(_Symbol,periodM15,"DrawExtremums",false,PERIOD_M15);
   handleExtremums[3]  = iCustom(_Symbol,periodH1,"DrawExtremums",false,PERIOD_H1);
       
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
   if (handleExtremums[3] == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� DrawExtremums �� H1");
     errorValue = INIT_FAILED;       
    }  
   if (handleExtremums[2] == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� DrawExtremums �� M15");
     errorValue = INIT_FAILED;       
    }  
   if (handleExtremums[1] == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� DrawExtremums �� M5");
     errorValue = INIT_FAILED;       
    }          
   if (handleExtremums[0] == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� DrawExtremums �� M1");  
     errorValue = INIT_FAILED;  
    }
   // ������� ������ ������ TradeManager
   ctm = new CTradeManager();                    
   // ������� ������� ������ CisNewBar
   isNewBar_D1 = new CisNewBar(_Symbol,PERIOD_D1);
   // �������������� ����������
   currentLot = lot;
   
   return(errorValue);
  }

void OnDeinit(const int reason)
  {
   // ����������� ������
   ArrayFree(divMACD_M5);
   ArrayFree(divMACD_M15);
   ArrayFree(divMACD_H1);
   ArrayFree(lastExtr_H1_down);
   ArrayFree(lastExtr_H1_up);
   ArrayFree(lastExtr_M15_down);
   ArrayFree(lastExtr_M15_up);
   ArrayFree(lastExtr_M5_down);
   ArrayFree(lastExtr_M5_up);
   ArrayFree(lastExtr_M1_down);
   ArrayFree(lastExtr_M1_down);
   ArrayFree(lastBarD1);
   // ������� ��� ����������
   IndicatorRelease(handleSmydMACD_M5);
   IndicatorRelease(handleSmydMACD_M15);   
   IndicatorRelease(handleSmydMACD_H1);
   IndicatorRelease(handleExtremums[0]);
   IndicatorRelease(handleExtremums[1]);
   IndicatorRelease(handleExtremums[2]);
   IndicatorRelease(handleExtremums[3]);
   // ������� ������� �������
   delete ctm;
   delete isNewBar_D1;
  }

void OnTick()
  {
    ctm.OnTick(); 
    ctm.DoTrailing();  
    GetExtremums();           // �������� �������� ��������� �����������
    curPrice   = SymbolInfoDouble(_Symbol,SYMBOL_BID);   // �������� ������� ����
    // ���� ��� ������ ������ �������� ��� ������������� ����� ��� 
    if (firstLaunch || isNewBar_D1.isNewBar() > 0)
     {
      firstLaunch = false;
      
      // ���� ��� �������� ������� 
      if ( ctm.GetPositionCount() == 0 )
       {
        lastTendention = GetLastTendention();                      // �������� ���������� ���������                   
       } 
     }
       // �� ������ ���� 
       if ( ctm.GetPositionCount() == 0 )   // ���� ������� ��� �� �������
        {
         // ���� ����� ���������  - �����
         if (lastTendention == TENDENTION_UP && GetCurrentTendention () == TENDENTION_UP)
           {
             // ���� ������� ���� ������� ���� �� ���������� �� ����� �� �����������
             if ( GreatDoubles (curPrice,lastExtr_M5_up[0])  ||
                  GreatDoubles (curPrice,lastExtr_M15_up[0]) ||
                  GreatDoubles (curPrice,lastExtr_H1_up[0]) )
                {
                  // ���� ������� ����������� MACD �� ������������ �������� ��������
                  if ( IsMACDCompatible (BUY) )
                   {                 
                     // ��������� ���� ���� �� ���������� ����������
                     stopLoss = int(lastExtr_M5_down[0]/_Point);
                     // ��������� ������� �� BUY
                     ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,currentLot,stopLoss);
                     // ���������� ���� �������� ������� BUY
                     openedPosition = BUY;         
                     // �������� ������ ������� ���������� Extremums ��� ���������
                     indexHandleForTrail = 0;           
                   } 
                        

                }
    
           }
         // ���� ����� ��������� - ����
         if (lastTendention == TENDENTION_DOWN && GetCurrentTendention () == TENDENTION_DOWN)
           {          
             // ���� ������� ���� ������� ���� �� ���������� �� ����� �� �����������
             if ( LessDoubles (curPrice,lastExtr_M5_down[0])  ||
                  LessDoubles (curPrice,lastExtr_M15_down[0]) ||
                  LessDoubles (curPrice,lastExtr_H1_down[0]) )
                {
                  // ���� ������� ����������� MACD �� ������������ �������� ��������
                  if ( IsMACDCompatible (SELL) )
                   {
                     // ��������� ���� ���� �� ���������� ����������
                     stopLoss = int(lastExtr_M5_up[0]/_Point);
                     // ��������� ������� �� SELL
                     ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,currentLot,stopLoss);
                     // ���������� ���� �������� ������� SELL
                     openedPosition = SELL;  
                     // �������� ������ ������� ���������� Extremums ��� ���������
                     indexHandleForTrail = 0;                                         
                   } 
                 
                }      

                
                  
           }
        }
       // ���� ���� �������� �������
       else
        {
       // ���� ������� ���� ������� �� BUY
       if ( openedPosition == BUY ) 
        {
         // ���� ���� ������� ������ 4-� ������� 
         if ( countAddingToLot < 4 )
           {
            // ���� ���� ������� ��������� ������� ��������� �� M1
            if (GreatDoubles(curPrice, lastExtr_M1_up[0]) )
             {
               // �� ���������� 
               currentLot = currentLot + lotStep;
               ctm.PositionChangeSize(_Symbol, lot);
               // � ����������� ���������� ������� �� �������
               countAddingToLot ++;
             } 
           }
         // ������� ���� ����
         switch (indexHandleForTrail)
          {
           case 0:  //  M1
            if ( GreatDoubles (curPrice,lastExtr_M5_up[0]) )  // ���� ���� ������� ��������� �� M5
             {
              indexHandleForTrail = 1;  // �� ��������� �� M5
             }
           break;
           case 1:  // M5
            if ( GreatDoubles (curPrice,lastExtr_M15_up[0]) )  // ���� ���� ������� ��������� �� M15
             {
              indexHandleForTrail = 2;  // �� ��������� �� M15
             }           
           break;
           case 2:  // M15
            if ( GreatDoubles (curPrice,lastExtr_H1_up[0]) )  // ���� ���� ������� ��������� �� H1
             {
              indexHandleForTrail = 3;  // �� ��������� �� H1
             }           
           break;
          }
         // �������� ���� ����
         stopLoss = ExtremumsTrailing(_Symbol,OP_BUY,stopLoss,handleExtremums[indexHandleForTrail]);
        }
       // ���� ������� ���� ������� �� SELL
       else if ( openedPosition == SELL)
        {
         // ���� ���� ������� ������ 4-� ������� 
         if ( countAddingToLot < 4 )
           {
            // ���� ���� ������� ��������� ������ ��������� �� M1
            if (LessDoubles(curPrice, lastExtr_M1_down[0]) )
             {
               // �� ���������� 
               currentLot = currentLot + lotStep;
               ctm.PositionChangeSize(_Symbol, lot);
               // � ����������� ���������� ������� �� �������
               countAddingToLot ++;
             } 
           }
         // ������� ���� ����
         switch (indexHandleForTrail)
          {
           case 0:  //  M1
            if ( LessDoubles (curPrice,lastExtr_M5_down[0]) )  // ���� ���� ������� ��������� �� M5
             {
              indexHandleForTrail = 1;  // �� ��������� �� M5
             }
           break;
           case 1:  // M5
            if ( LessDoubles (curPrice,lastExtr_M15_down[0]) )  // ���� ���� ������� ��������� �� M15
             {
              indexHandleForTrail = 2;  // �� ��������� �� M15
             }           
           break;
           case 2:  // M15
            if ( LessDoubles (curPrice,lastExtr_H1_down[0]) )  // ���� ���� ������� ��������� �� H1
             {
              indexHandleForTrail = 3;  // �� ��������� �� H1
             }           
           break;
          }
         // �������� ���� ����
         stopLoss = ExtremumsTrailing(_Symbol,OP_SELL,stopLoss,handleExtremums[indexHandleForTrail]);
        }
       }
        
  }
  
 // ����������� �������
 
 ENUM_TENDENTION GetLastTendention ()            // ���������� ��������� �� ��������� ����
  {
  
   if ( CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1) == 2 )
     {
      if ( GreatDoubles (lastBarD1[0].close,lastBarD1[0].open) )
       return (TENDENTION_UP);
      if ( LessDoubles  (lastBarD1[0].close,lastBarD1[0].open) )
       return (TENDENTION_DOWN); 
     }
    return (TENDENTION_NO); 
  }
  
  ENUM_TENDENTION GetCurrentTendention ()        // ��������� ��������� ������� ����
   {
    if ( GreatDoubles (curPrice,lastBarD1[1].open) )  
       return (TENDENTION_UP);
    if ( LessDoubles  (curPrice,lastBarD1[1].open) )
       return (TENDENTION_DOWN);
     return (TENDENTION_NO); 
   }
   
  bool  GetExtremums()                           // ��������� ���������� 
   {
    int copiedM1_up        = CopyBuffer(handleExtremums[0],2,1,1,lastExtr_M1_up);
    int copiedM1_down      = CopyBuffer(handleExtremums[0],3,1,1,lastExtr_M1_down);
    int copiedM5_up        = CopyBuffer(handleExtremums[1],2,1,1,lastExtr_M5_up);
    int copiedM5_down      = CopyBuffer(handleExtremums[1],3,1,1,lastExtr_M5_down);
    int copiedM15_up       = CopyBuffer(handleExtremums[2],2,1,1,lastExtr_M15_up);
    int copiedM15_down     = CopyBuffer(handleExtremums[2],3,1,1,lastExtr_M15_down);
    int copiedH1_up        = CopyBuffer(handleExtremums[3],2,1,1,lastExtr_H1_up);
    int copiedH1_down      = CopyBuffer(handleExtremums[3],3,1,1,lastExtr_H1_down);  
          
    
    if (copiedH1_down  < 1 ||
        copiedH1_up    < 1 ||
        copiedM15_down < 1 ||
        copiedM15_up   < 1 ||
        copiedM5_down  < 1 ||
        copiedM5_up    < 1 ||
        copiedM1_up    < 1 ||
        copiedM1_down  < 1
       )
        {
         Print("������ �������� SimpleTrend. �� ������� �������� ������ �� �����������");
         return (false);
        }
        
     return (true);
   }
    
   bool  IsMACDCompatible (int direction)        // ���������, �� ������������ �� ����������� MACD ������� ���������
    {
     int copiedMACD_M5  = CopyBuffer(handleSmydMACD_M5,1,0,1,divMACD_M5);
     int copiedMACD_M15 = CopyBuffer(handleSmydMACD_M15,1,0,1,divMACD_M15);
     int copiedMACD_H1  = CopyBuffer(handleSmydMACD_H1,1,0,1,divMACD_H1);   
     
     if (copiedMACD_M5  < 1 ||
         copiedMACD_M15 < 1 ||
         copiedMACD_H1  < 1
        )
         {
          Print("������ �������� SimpleTrend. �� ������� �������� ������ � ������������");
          return (false);
         }        
      if ( (divMACD_M5[0]+direction) && (divMACD_M15[0]+direction) && (divMACD_H1[0]+direction) )
       {
        return (true);
       }
     return (false);
    }
    
// �������� �� �����������
double  ExtremumsTrailing (string symbol,ENUM_TM_POSITION_TYPE type,double sl, int handleExtremums)
 {
  double extrHigh[]; // ����� ������� ����������� �� ������� ����������
  double extrLow[];  // ����� ������ ����������� �� ������� ���������� 
  double stopLoss;   // ���������� ��� �������� ������ ���� ����� 
  double currentPrice;  // ������� ����
  switch (type)
   {
    case OP_BUY:
     // ��������� ������� ����
     currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);
     // ���� ������� ���������� ������
     if ( CopyBuffer(handleExtremums,2,1,1,extrHigh) == 1 &&
          CopyBuffer(handleExtremums,3,1,1,extrLow)  == 1 
        )
         {
           // ���� ���� ���������� �� ������� ��������� �������� ���������� 
           // � ��������� ������ ��������� ����� (����), ��� ���������� ���� ����
           if ( GreatDoubles(currentPrice,extrHigh[0]) && GreatDoubles(extrLow[0],sl) )
            {
             // �������� ����� �������� ���� �����
             stopLoss = extrLow[0];
             // ������� �������
             ArrayFree(extrHigh);
             ArrayFree(extrLow);
             // �� ������ �������� �� ������ ���������� ������� ���������� �������� ����������
             return (stopLoss);
            }
         }
     
    break;
    case OP_SELL:
     // ��������� ������� ����
     currentPrice = SymbolInfoDouble(symbol,SYMBOL_BID);
     // ���� ������� ���������� ������
     if ( CopyBuffer(handleExtremums,2,1,1,extrHigh) == 1 &&
          CopyBuffer(handleExtremums,3,1,1,extrLow)  == 1 
        )
         {
           // ���� ���� ���������� �� ������ ��������� �������� ����������
           // � ��������� ������� ��������� ����� (����), ��� ���������� ���� ����
           if ( LessDoubles(currentPrice,extrLow[0]) && LessDoubles(extrHigh[0],sl) )
            {
             // �������� ����� �������� ���� �����
             stopLoss = extrHigh[0];
             // ������� ������
             ArrayFree(extrHigh);
             ArrayFree(extrLow);
             // �� ������ �������� �� ������ ���������� �������� ���������� �������� ����������
             return (stopLoss);
            }
         }
         
    break;
   }
  // ��������� ������
  ArrayFree(extrHigh);
  ArrayFree(extrLow);
  return (0.0);
 } 
   