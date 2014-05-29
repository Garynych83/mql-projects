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
#include <TradeManager\TradeManager.mqh> // �������� ����������

// ������� ���������
     
// ��������� ����������

// ������ �����������
int handleSmydMACD_D1;                   // ����� ���������� ����������� MACD �� ��������
int handleSmydMACD_H1;                   // ����� ���������� ����������� MACD �� ��������
int handleSmydMACD_M15;                  // ����� ���������� ����������� MACD �� 15 �������
int handleSmydSTOC_D1;                   // ����� ���������� ����������� STOC �� ��������
int handleSmydSTOC_H1;                   // ����� ���������� ����������� STOC �� ��������
int handleSmydSTOC_M15;                  // ����� ���������� ����������� STOC �� 15 �������

// ����������
ENUM_TIMEFRAMES periodD1  = PERIOD_D1; 
ENUM_TIMEFRAMES periodH1  = PERIOD_H1;
ENUM_TIMEFRAMES periodM5  = PERIOD_M5;
ENUM_TIMEFRAMES periodM15 = PERIOD_M15;
ENUM_TIMEFRAMES periodM1  = PERIOD_M1; 

// ������� �������
CTradeManager *ctm;                      // ������ �������� ����������
 

// �������� ��������� ������� ������

int OnInit()
  {
   int errorValue  = INIT_SUCCEEDED;  // ��������� ������������� ��������
   // �������� ���������������� ������ ����������� MACD � ����������
   handleSmydMACD_D1  = iCustom(_Symbol,periodD1,"smydMACD");  
   handleSmydMACD_H1  = iCustom(_Symbol,periodH1,"smydMACD");  
   handleSmydMACD_M15 = iCustom(_Symbol,periodM15,"smydMACD");  
   handleSmydSTOC_D1  = iCustom(_Symbol,periodD1,"smydSTOC");  
   handleSmydSTOC_H1  = iCustom(_Symbol,periodH1,"smydSTOC");  
   handleSmydSTOC_M15 = iCustom(_Symbol,periodM15,"smydSTOC");  
       
   if (handleSmydMACD_D1  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� MACD �� D1");
     errorValue = INIT_FAILED;
    }       
   if (handleSmydMACD_H1  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� MACD �� H1");
     errorValue = INIT_FAILED;  
    }      
   if (handleSmydMACD_M15  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� MACD �� M15");
     errorValue = INIT_FAILED;     
    }      
   if (handleSmydSTOC_D1  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� ���������� �� D1");
     errorValue = INIT_FAILED;     
    }      
   if (handleSmydSTOC_H1  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� ���������� �� H1");
     errorValue = INIT_FAILED;     
    }      
   if (handleSmydSTOC_M15  == INVALID_HANDLE)
    {
     Print("������ ��� ������������� �������� SimpleTrend. �� ������� ������� ����� ���������� ���������� �� M15");
     errorValue = INIT_FAILED;     
    }     
   // ������� ������ ������ TradeManager
   ctm = new CTradeManager();                    
   return(errorValue);
  }

void OnDeinit(const int reason)
  {
   // ������� ��� ����������
   IndicatorRelease(handleSmydMACD_D1);
   IndicatorRelease(handleSmydMACD_H1);
   IndicatorRelease(handleSmydMACD_M15);
   IndicatorRelease(handleSmydSTOC_D1);
   IndicatorRelease(handleSmydSTOC_H1);
   IndicatorRelease(handleSmydSTOC_M15);
   // ������� ������ ������ TradeManager
   delete ctm;
  }

void OnTick()
  {
    ctm.OnTick();
  }
  
 