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
input int    n_spreads       = 1;    // ���������� ������

//+------------------------------------------------------------------+
//| ������� ���c�                                                    |
//+------------------------------------------------------------------+

CTradeManager ctm(); 
bool   openedPosition = false;  // ���� ������� �������
double openPrice;               // ���� ��������
bool   was_a_part = false;      // ���� �������� �����
int    count_long = 0;          // ������� ����� �����
double current_lot = lot;       // ������� ���

int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

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
         if (ctm.OpenUniquePosition(_Symbol, OP_BUY, current_lot) ) // �������� ��������� �� BUY 
           {
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ��������� ���� �������� �������
             openedPosition = true;                            // ���� �������� ������� ���������� � true
             was_a_part     = true;                            // ������� ����� �������, ������ ����� ������ ������� ����� �����
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
          spread =   SymbolInfoDouble(_Symbol,SYMBOL_ASK) - currentPrice; // ��������� ������� ������
         
          if ((currentPrice - openPrice) >  n_spreads*spread )
           { // ���� ������� ���� ��������� ���� ��������
             
             ctm.ClosePosition(_Symbol);                // ��������� �������
             openedPosition = false;                    // ���������� ���� �������� ������� � false
             count_long ++;                             // ����������� ����� �����
           //  if ( (current_lot+lot_diff) < max_lot)   // ���� ��� �� �������� ���������� �����
           //     current_lot = current_lot + lot_diff; // ����������� ���
             
              
           }
           
        }
     }
  }