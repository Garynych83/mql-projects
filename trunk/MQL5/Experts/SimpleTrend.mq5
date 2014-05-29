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

// ������� ���������
input double lot = 0.1;                  // ��������� ���
input double lotStep = 0.2;              // ������ �������

// ��������� ����������

// ������ �����������
int handleSmydMACD_D1;                   // ����� ���������� ����������� MACD �� ��������
int handleSmydMACD_H1;                   // ����� ���������� ����������� MACD �� ��������
int handleSmydMACD_M15;                  // ����� ���������� ����������� MACD �� 15 �������
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
bool openedPosition = false;             // ���� �������� �������
double currentPrice;                     // ��� �������� ������� ����
double stopLoss;                         // ���������� ��� �������� ���� �����
double currentLot;                       // ������� ���
ENUM_TENDENTION  lastTendention;         // ���������� ��� �������� ��������� ��������� 

// ���������� ��� �������� �������� �����������
double lastExtr_M5_up[];                 // �������� ���������� �������� ���������� �� M5
double lastExtr_M5_down[];               // �������� ���������� ������� ���������� �� M5
double lastExtr_M15_up[];                // �������� ���������� �������� ���������� �� M15
double lastExtr_M15_down[];              // �������� ���������� ������� ���������� �� M15
double lastExtr_H1_up[];                 // �������� ���������� �������� ���������� �� H1
double lastExtr_H1_down[];               // �������� ���������� ������� ���������� �� H1

// �������� ��������� ������� ������
ENUM_TENDENTION GetLastTendention();     // ���������� ������������� ��������� �� ���������� ����
ENUM_TENDENTION GetCurrentTendention();  // ���������� ������� ��������� ����
bool            GetExtremums_M5_M15_H1();// ���� �������� ����������� �� M5 M15 H1

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // ��������� ������������� ��������
   // �������� ���������������� ������ ����������� MACD 
   handleSmydMACD_D1  = iCustom(_Symbol,periodD1,"smydMACD");  
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD"); 
   // �������� ���������������� ������ ���������� Extremums
   handleDrawExtr_M5  = iCustom(_Symbol,periodM5,"DrawExtremums",false,PERIOD_M5);
   handleDrawExtr_M15 = iCustom(_Symbol,periodM15,"DrawExtremums",false,PERIOD_M15);
   handleDrawExtr_H1  = iCustom(_Symbol,periodH1,"DrawExtremums",false,PERIOD_H1);
       
   if (handleSmydMACD_D1  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� SmydMACD �� D1");
     errorValue = INIT_FAILED;
    }       
   if (handleSmydMACD_H1  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� SmydMACD �� H1");
     errorValue = INIT_FAILED;  
    }      
   if (handleSmydMACD_M15  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� SmydMACD �� M15");
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
   // ������� ������ ������ CisNewBar
   isNewBar_D1 = new CisNewBar(_Symbol,PERIOD_D1);
   // �������������� ����������
   
   return(errorValue);
  }

void OnDeinit(const int reason)
  {
   // ������� ��� ����������
   IndicatorRelease(handleSmydMACD_D1);
   IndicatorRelease(handleSmydMACD_H1);
   IndicatorRelease(handleSmydMACD_M15);
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
    // ���� ��� ������ ������ �������� ��� ������������� ����� ��� 
    if (firstLaunch || isNewBar_D1.isNewBar() > 0)
     {
      firstLaunch = false;
      // ���� ������� ��� �� �������
      if (!openedPosition )
       {
        lastTendention = GetLastTendention();                      // �������� ���������� ���������                 
        GetExtremums_M5_M15_H1();                                  // �������� �������� ��������� �����������
                  Comment(" \n",
                          "M5 UP: ",DoubleToString(lastExtr_M5_up[0]),
                          "\nM5 DOWN: ",DoubleToString(lastExtr_M5_down[0]),                          
                          "\nM15 UP: ",DoubleToString(lastExtr_M15_up[0]),
                          "\nM15 DOWN: ",DoubleToString(lastExtr_M15_down[0]),                          
                          "\nH1 UP: ",DoubleToString(lastExtr_H1_up[0]),
                          "\nH1 DOWN: ",DoubleToString(lastExtr_H1_down[0]),                          
                         "\n����: ",DoubleToString(currentPrice)    );        
       } 
     }
    // �� ������ ����
       // ���� ������� ��� �� �������
       if (!openedPosition )
        {
         currentPrice   = SymbolInfoDouble(_Symbol,SYMBOL_BID);   // �������� ������� ����
         // ���� ����� ���������  - �����
         if (lastTendention == TENDENTION_UP && GetCurrentTendention () == TENDENTION_UP)
           {
                 
             // ���� ������� ���� ������� ���� �� ���������� �� ����� �� �����������
             if ( GreatDoubles (currentPrice,lastExtr_M5_up[0])  ||
                  GreatDoubles (currentPrice,lastExtr_M15_up[0]) ||
                  GreatDoubles (currentPrice,lastExtr_H1_up[0]) )
                {
                  // ���� ������� ����������� MACD �� ������������ �������� ��������
    /*              Comment("���� ���� ������ �� ����������� \n",
                          "M5: ",DoubleToString(lastExtr_M5_up[0]),
                          "\nM15: ",DoubleToString(lastExtr_M15_up[0]),
                          "\nH1: ",DoubleToString(lastExtr_H1_up[0]),
                         "\n����: ",DoubleToString(currentPrice)   
                  );
      */            
                  // ��������� ���� ����
                  stopLoss = 0;                  
                  // �� ��������� ������� �� BUY
             //     ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,currentLot,stopLoss);
                  // ���������� ���� �������� ������� � true
                  openedPosition = true;
                }
    
           }
         // ���� ����� ��������� - ����
         if (lastTendention == TENDENTION_DOWN && GetCurrentTendention () == TENDENTION_DOWN)
           {
                          
           
             // ���� ������� ���� ������� ���� �� ���������� �� ����� �� �����������
             if ( LessDoubles (currentPrice,lastExtr_M5_down[0])  ||
                  LessDoubles (currentPrice,lastExtr_M15_down[0]) ||
                  LessDoubles (currentPrice,lastExtr_H1_down[0]) )
                {
                       /*          Comment("���� ���� ������ �� ����������� \n",
                          "M5: ",DoubleToString(lastExtr_M5_down[0]),
                          "\nM15: ",DoubleToString(lastExtr_M15_down[0]),
                          "\nH1: ",DoubleToString(lastExtr_H1_down[0]),
                          "\n����: ",DoubleToString(currentPrice)
                  ); */
                  // ���� ������� ����������� MACD �� ������������ �������� ��������
                  
                  // ��������� ���� ����
                  stopLoss = 0;
                  // �� ��������� ������� �� SELL
                 
                }      

                
                  
           }
        }
        
  }
  
 // ����������� �������
 ENUM_TENDENTION GetLastTendention ()
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
  
  ENUM_TENDENTION GetCurrentTendention ()
   {
    if ( GreatDoubles (currentPrice,lastBarD1[1].open) )  
       return (TENDENTION_UP);
    if ( LessDoubles  (currentPrice,lastBarD1[1].open) )
       return (TENDENTION_DOWN);
     return (TENDENTION_NO); 
   }
   
  bool  GetExtremums_M5_M15_H1()
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