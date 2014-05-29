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
double lastExtr_M5;                      // �������� ���������� ���������� �� M5
double lastExtr_M15;                     // �������� ���������� ���������� �� M15
double lastExtr_H1;                      // �������� ���������� ���������� �� H1

// �������� ��������� ������� ������
ENUM_TENDENTION GetLastTendention();     // ���������� ������������� ��������� �� ���������� ����
ENUM_TENDENTION GetCurrentTendention();  // ���������� ������� ��������� ����
bool            GetExtremums_M5_M15_H1();// ���� �������� ����������� �� M5 M15 H1

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // ��������� ������������� ��������
   // �������� ���������������� ������ ����������� MACD � ����������
   handleSmydMACD_D1  = iCustom(_Symbol,periodD1,"smydMACD");  
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD"); 
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
        lastTendention = GetLastTendention();                   // �������� ���������� ���������
       } 
     }
    // �� ������ ����
    else
     {
       // ���� ������� ��� �� �������
       if (!openedPosition )
        {
         currentPrice   = SymbolInfoDouble(_Symbol,SYMBOL_BID);   // �������� ������� ����
         // ���� ����� ���������  - �����
         if (lastTendention == TENDENTION_UP && GetCurrentTendention () == TENDENTION_UP)
           {
             
           }
         // ���� ����� ��������� - ����
         if (lastTendention == TENDENTION_DOWN && GetCurrentTendention () == TENDENTION_DOWN)
           {
        
           }
        }
        
     }
  }
  
 // ����������� �������
 ENUM_TENDENTION GetLastTendention ()
  {
  
   if ( CopyRates(_Symbol,PERIOD_D1,0,2,lastBarD1) == 1 )
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
   /*
    int copiedM5 = -1;
    int copiedM15
   */
     return (true);
   }