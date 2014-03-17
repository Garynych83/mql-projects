//+------------------------------------------------------------------+
//|                                                      HAYASHI.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager\TradeManager.mqh>  // �������� ����������
#include <CompareDoubles.mqh>             // ��� ��������� ������������ �����
#include <Lib CisNewBar.mqh>              // ��� ������������ ������ ����

input double lot             = 0.1;  // ����������� ������ ����
input double max_lot         = 1;    // ������������ ������ ����
input double lot_diff        = 0.1;  // ������� ��������� ����
input double aver            = 8;    // ������� ����� �����

//+------------------------------------------------------------------+
//| ������� ���c�                                                    |
//+------------------------------------------------------------------+

CTradeManager ctm(); 
bool   openedPosition = false;  // ���� ������� �������
double openPrice;               // ���� ��������
bool   was_a_part = false;      // ���� �������� �����
int    count_long = 0;          // ������� ����� �����
double current_lot = lot;       // ������� ���

int    startPeriod  = 10;       // ����� � ����� - ������ �������������
int    finishPeriod = 20;       // ����� � ����� - ����� �������������

MqlDateTime timeStr;            // ��������� ������� ��� �������� �������� �������
int    handlePBI;               // ����� ����������-����������

double bufferPBI[];             // ����� ����������-���������� 



int OnInit()
  {
   // �������� ��������� ����� ����������-����������
   handlePBI = iCustom (_Symbol,_Period,"test_PBI_NE");
   // ���� ����� �� ������������ 
   if ( handlePBI == INVALID_HANDLE)
    return (INIT_FAILED);  // �� ���������� ��������� �������������
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
    ArrayFree(bufferPBI);
  }

void OnTick()
  { 
    static CisNewBar isNewBar(_Symbol, _Period);   // ��� �������� ������������ ������ ����
    double currentPrice;                           // ������� ����
    double spread;                                 // �����
    
    // ���� ����������� ����� ���
    if(isNewBar.isNewBar() > 0)
     {        
      if (openedPosition == false)
       { // ���� �� ����� ������� ��� �� ���� ������� �������
         
         TimeCurrent(timeStr);  // �������� ������� �����
        
        // �������� ������� �������� ������������� ����
        if ( CopyBuffer(handlePBI,4,1,1,bufferPBI) < 1)  
         return;
         
         // ���� ������ �� ������ ����� ����� 
         if ( timeStr.hour >= startPeriod && timeStr.hour <= finishPeriod &&  ( bufferPBI[0] == 7 || bufferPBI[0] == 2 || bufferPBI[0] == 1) )
          {
         if (ctm.OpenUniquePosition(_Symbol, OP_BUY, current_lot) ) // �������� ��������� �� BUY 
           {
           //  Comment("������� ��� = "+current_lot);
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ��������� ���� �������� �������
             openedPosition = true;                            // ���� �������� ������� ���������� � true
             was_a_part     = true;                            // ������� ����� �������, ������ ����� ������ ������� ����� �����
           }
          }  
       }
      else
       {
         // ���� ��� ���� �������� �������
         openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // �� ��������� ������� ���� �������� 
         count_long = 0; // �������� ������� ����� 
         was_a_part     = false;  // ������ ����� �� ������������
         current_lot    = lot;    // ���������� ������� ��� �� ��������� �������
       }
     }
    else
     { // ���� ��� �� �����������
       if (openedPosition == true)
        { // ���� ���� ������� �������
         
          currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID); // �������� ������� ����
          spread = SymbolInfoDouble(_Symbol,SYMBOL_ASK) - currentPrice; // ��������� ������� ������
         
          if ((currentPrice - openPrice) < spread)
           { // ���� ������� ���� ��������� ���� ��������
             
             ctm.ClosePosition(_Symbol); // ��������� �������
             openedPosition = false;     // ���������� ���� �������� ������� � false
             count_long ++;              // ����������� ����� �����
             if ( (current_lot+lot_diff) < max_lot)  // ���� ��� �� �������� ���������� �����
                current_lot = current_lot + lot_diff; // ����������� ���
             
              
           }
        }
     }
  }