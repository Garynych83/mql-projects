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

input double lot             = 1;  // ������ ����
input double priceDifference = 10; // ������� ��� � �������

//+------------------------------------------------------------------+
//| ������� ���c�                                                    |
//+------------------------------------------------------------------+

CTradeManager ctm(); 
bool   openedPosition = false;  // ���� ������� �������
double openPrice;               // ���� ��������

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
    // ���� ����������� ����� ���
    if(isNewBar.isNewBar() > 0)
     {
      if (openedPosition == false)
       { // ���� �� ����� ������� ��� �� ���� ������� �������
         if (ctm.OpenUniquePosition(_Symbol, OP_BUY, lot) ) // �������� ��������� �� BUY 
           {
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ��������� ���� �������� �������
             openedPosition = true;                            // ���� �������� ������� ���������� � true
           }  
       }
      else
       {
         // ���� ��� ���� �������� �������
         openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // �� ��������� ������� ���� �������� 
       }
     }
    else
     { // ���� ��� �� �����������
       if (openedPosition == true)
        { // ���� ���� ������� �������
          currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID); // �������� ������� ����
          if ((currentPrice - openPrice) > 0.0001)
           { // ���� ������� ���� ��������� ���� ��������
             
             ctm.ClosePosition(_Symbol); // ��������� �������
             openedPosition = false;     // ���������� ���� �������� ������� � false
           }
        }
     }
  }