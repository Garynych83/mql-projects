//+------------------------------------------------------------------+
//|                                              BeatTheExtremum.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager\TradeManager.mqh>   // �������� ����������
#include <BlowInfoFromExtremums.mqh>       // ���������� ��� ��������� ���������� �� ����������

// �����, ��������� �� �������� ����������

// ��������� ����������
double currentPrice;               // ���������� �������� ������� ����
ENUM_EXTR_USE   lastExtr;          // ��������� ���������
ENUM_EXTR_USE   curExtr;           // ������� ���������
bool   openedPosition = false;     // ���� �������� �������

CTradeManager *ctm;                // �������� ����������
CBlowInfoFromExtremums *blowInfo;  // ������ ������ ��� ��������� ���������� �� �����������

int OnInit()
  {
   ctm   = new CTradeManager();
   if (ctm == NULL)
    return (INIT_FAILED);
   blowInfo = new CBlowInfoFromExtremums(_Symbol,_Period);
   if (blowInfo == NULL)
    return (INIT_FAILED);
   // ������ �������� �����������
   if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )
    { 
     lastExtr = blowInfo.GetLastExtrType();
    }
   else
    return (INIT_FAILED);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // ������� �������
   delete ctm;
   delete blowInfo;
  } 

void OnTick()
  {
   ctm.OnTick();
   if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )    // ���� ������� �������� ������ �� �����������
    {
    
     currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  // �������� ������� ����
     curExtr = blowInfo.GetLastExtrType();                 // �������� ��������� ��� �����������
     if (curExtr != lastExtr)                              // ���� ������ ����� ��������� (���������������)
      {
        lastExtr = curExtr;                                // ��������� ��������� ���������
        openedPosition = false;                            // ���������� ���� �������� ������� � false
      }
     if (!openedPosition)  // ���� ��� �������� �������
      {
        if (lastExtr == EXTR_HIGH)
         {
          if (currentPrice < blowInfo.GetExtrByIndex(EXTR_LOW,0).price )  // ���� ���� ������� ���������
           {
             // �� ��������� ������� �� SELL
             ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,1.0);
             openedPosition = true;
           }
         }
        if (lastExtr == EXTR_LOW)
         {
          if (currentPrice > blowInfo.GetExtrByIndex(EXTR_HIGH,0).price ) // ���� ���� ������� ���������
           {
            // �� ��������� ������� �� BUY
            ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0);
            openedPosition = true;
           }
         }
       } // ����� if(!openedPosition)
     } // ����� Upload
  }