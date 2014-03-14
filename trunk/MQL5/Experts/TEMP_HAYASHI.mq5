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
int    stopLoss;                // ������� �����
datetime history_start;

int OnInit()
  {
   history_start=TimeCurrent();    
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
        // stopLoss = ( SymbolInfoDouble(_Symbol,SYMBOL_ASK) - SymbolInfoDouble(_Symbol,SYMBOL_BID) )/_Point;
         stopLoss = 30;
         Comment("���� ���� = ",stopLoss);
         if (ctm.OpenUniquePosition(_Symbol, OP_BUY, lot,stopLoss) ) // �������� ��������� �� BUY 
           {
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ��������� ���� �������� �������
             openedPosition = true;                            // ���� �������� ������� ���������� � true
           }  
       }
      else
       {
         // ���� ��� ���� �������� �������
         openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // �� ��������� ������� ���� �������� 
         stopLoss = ( SymbolInfoDouble(_Symbol,SYMBOL_ASK) - SymbolInfoDouble(_Symbol,SYMBOL_BID) )/_Point;       
       }
     }
    if (ctm.isHistoryChanged())
     {
      Alert("�������");
      openedPosition = false;
     }
  }
  
void OnTrade()
 {
     ctm.OnTrade(history_start);
 }