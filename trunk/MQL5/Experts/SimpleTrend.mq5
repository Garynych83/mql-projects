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

// ������ �����������
int handleSmydMACD_M5;                   // ����� ���������� ����������� MACD �� �������
int handleSmydMACD_M15;                  // ����� ���������� ����������� MACD �� 15 �������
int handleSmydMACD_H1;                   // ����� ���������� ����������� MACD �� ��������
int handleDrawExtr_M5;                   // ����� ���������� ����������� �� 5-�������
int handleDrawExtr_M15;                  // ����� ���������� ����������� �� 15-�� �������
int handleDrawExtr_H1;                   // ����� ���������� ����������� �� ��������

// ����������
ENUM_TIMEFRAMES periodD1  = PERIOD_D1; 
ENUM_TIMEFRAMES periodH1  = PERIOD_H1;
ENUM_TIMEFRAMES periodM5  = PERIOD_M5;
ENUM_TIMEFRAMES periodM15 = PERIOD_M15;
ENUM_TIMEFRAMES periodM1  = PERIOD_M1; 

// ����������� ������
MqlRates lastBarD1[];                    // ����� ��� �� ��������

// ������� �������
CTradeManager *ctm;                      // ������ �������� ����������
CisNewBar     *isNewBar_D1;              // ����� ��� �� D1

 
// �������������� ��������� ����������
bool firstLaunch    = true;              // ���� ������� ������� ��������
int  openedPosition = 0;                 // ��� �������� ������� 
int  countAddingToLot = 0;               // ������� �������
double curPrice;                         // ��� �������� ������� ����
double stopLoss;                         // ���������� ��� �������� ���� �����
double currentLot;                       // ������� ���
ENUM_TENDENTION  lastTendention;         // ���������� ��� �������� ��������� ��������� 

// ������ ��� �������� �������� �����������
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
void            MoveStopLossForBuy ();             // ��������� ���� ���� �� ����� ��������� ��� ������� BUY
void            MoveStopLossForSell();             // ��������� ���� ���� �� ����� ��������� ��� ������� SELL

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // ��������� ������������� ��������
   // �������� ���������������� ������ ����������� MACD 
   handleSmydMACD_M5  = iCustom(_Symbol,periodM5,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD");    
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   // �������� ���������������� ������ ���������� Extremums
   handleDrawExtr_M5  = iCustom(_Symbol,periodM5,"DrawExtremums",false,PERIOD_M5);
   handleDrawExtr_M15 = iCustom(_Symbol,periodM15,"DrawExtremums",false,PERIOD_M15);
   handleDrawExtr_H1  = iCustom(_Symbol,periodH1,"DrawExtremums",false,PERIOD_H1);
       
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
   if (handleDrawExtr_H1 == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� DrawExtremums �� H1");
     errorValue = INIT_FAILED;       
    }  
   if (handleDrawExtr_M15 == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� DrawExtremums �� M15");
     errorValue = INIT_FAILED;       
    }  
   if (handleDrawExtr_M5 == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� DrawExtremums �� M5");
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
   ArrayFree(lastBarD1);
   // ������� ��� ����������
   IndicatorRelease(handleSmydMACD_M5);
   IndicatorRelease(handleSmydMACD_M15);   
   IndicatorRelease(handleSmydMACD_H1);
   IndicatorRelease(handleDrawExtr_H1);
   IndicatorRelease(handleDrawExtr_M15);
   IndicatorRelease(handleDrawExtr_M5);
   // ������� ������� �������
   delete ctm;
   delete isNewBar_D1;
  }

void OnTick()
  {
    ctm.OnTick();
    GetExtremums();           // �������� �������� ��������� �����������
    // ���� ��� ������ ������ �������� ��� ������������� ����� ��� 
    if (firstLaunch || isNewBar_D1.isNewBar() > 0)
     {
      firstLaunch = false;
      // ���� ������� ��� �� �������
      if ( openedPosition == NO_POSITION )
       {
        lastTendention = GetLastTendention();                      // �������� ���������� ���������                   
       } 
     }
       // �� ������ ���� 
       if ( openedPosition == NO_POSITION )   // ���� ������� ��� �� �������
        {
         curPrice   = SymbolInfoDouble(_Symbol,SYMBOL_BID);   // �������� ������� ����
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
                     Comment("��������� �� BUY");                   
                     // ��������� ���� ���� �� ���������� ����������
                     stopLoss = int(lastExtr_M5_down[0]/_Point);
                     // ��������� �������
                     ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,currentLot,stopLoss);
                     // ���������� ���� �������� ������� BUY
                     openedPosition = BUY;                    
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
                     Comment("��������� �� SELL");
                     // ��������� ���� ���� �� ���������� ����������
                     stopLoss = int(lastExtr_M5_up[0]/_Point);
                     // ��������� �������
                     ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,currentLot,stopLoss);
                     // ���������� ���� �������� ������� SELL
                     openedPosition = SELL;                    
                   } 
                 
                }      

                
                  
           }
        }
       // ���� ������� ���� ������� �� BUY
       else if ( openedPosition == BUY ) 
        {
         // ������ ���� ����
         MoveStopLossForBuy ();
        }
       // ���� ������� ���� ������� �� SELL
       else if ( openedPosition == SELL)
        {
         // ������ ���� ���� 
         MoveStopLossForSell ();
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
    int copiedM5_up        = CopyBuffer(handleDrawExtr_M5,2,1,1,lastExtr_M5_up);
    int copiedM5_down      = CopyBuffer(handleDrawExtr_M5,3,1,1,lastExtr_M5_down);
    int copiedM15_up       = CopyBuffer(handleDrawExtr_M15,2,1,1,lastExtr_M15_up);
    int copiedM15_down     = CopyBuffer(handleDrawExtr_M15,3,1,1,lastExtr_M15_down);
    int copiedH1_up        = CopyBuffer(handleDrawExtr_H1,2,1,1,lastExtr_H1_up);
    int copiedH1_down      = CopyBuffer(handleDrawExtr_H1,3,1,1,lastExtr_H1_down);        
    
    if (copiedH1_down  < 1 ||
        copiedH1_up    < 1 ||
        copiedM15_down < 1 ||
        copiedM15_up   < 1 ||
        copiedM5_down  < 1 ||
        copiedM5_up    < 1
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
    
   void MoveStopLossForBuy ()         // ������������� ���� ���� ��� ������� BUY
    {
     int type;
     switch (type)
      {
       case 0: // ��� M5
        // ���� ���� ������� ��������� ���������
        if ( GreatDoubles (curPrice, lastExtr_M5_up[0]) )
         {
          // �� ���������� ���� ���� �� ���������� ������ ��������� 
          stopLoss = lastExtr_M5_down[0];
         }
       break;
       case 1: // ��� M15
        if ( GreatDoubles (curPrice, lastExtr_M15_up[0]) )
         {
          // �� ���������� ���� ���� �� ���������� ������ ���������
          stopLoss = lastExtr_M15_down[0];
         }
       break;  
       case 2: // ��� H1
        if ( GreatDoubles (curPrice, lastExtr_H1_up[0]) )
         {
          // �� ���������� ���� ���� �� ���������� ������ ���������
          stopLoss = lastExtr_H1_down[0];
         }
       break;  
      }
    }
    
   void MoveStopLossForSell ()         // ������������� ���� ���� ��� ������� SELL
    {
     int type;
     switch (type)
      {
       case 0: // ��� M5
        // ���� ���� ������� ��������� ���������
        if ( LessDoubles (curPrice, lastExtr_M5_down[0]) )
         {
          // �� ���������� ���� ���� �� ���������� ������ ��������� 
          stopLoss = lastExtr_M5_up[0];
         }
       break;
       case 1: // ��� M15
        if ( LessDoubles (curPrice, lastExtr_M15_down[0]) )
         {
          // �� ���������� ���� ���� �� ���������� ������ ���������
          stopLoss = lastExtr_M15_up[0];
         }
       break;  
       case 2: // ��� H1
        if ( LessDoubles (curPrice, lastExtr_H1_down[0]) )
         {
          // �� ���������� ���� ���� �� ���������� ������ ���������
          stopLoss = lastExtr_H1_up[0];
         }
       break;  
      }
    }    