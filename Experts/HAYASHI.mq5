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



input double lot             = 1;          // ���
input int    n_spreads       = 1;          // ���������� ������


  ///--------------------------------------------
  ///------------------------------------------ /
  ///                                        / /
  ///                                       / /
  ///                JAPAN                 / /
  ///              JAPANJAPAN             / /
  ///            JAPANJAPANJAPA          / /
  ///           JAPANJAPANJAPANJ        / /
  ///           JAPANJAPANJAPANJ        \ \ 
  ///            JAPANJAPANJAPA          \ \
  ///              JAPANJAPAN             \ \
  ///                JAPAN                 \ \
  ///                                       \ \
  ///                                        \ \
  ///-----------------------------------------  \
  ///--------------------------------------------
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  
//+------------------------------------------------------------------+
//| ������� Funayama (ex. HAYASHI)                                   |
//+------------------------------------------------------------------+

CTradeManager ctm();            // ������ �������� ����������
bool   openedPosition = false;  // ���� ������� �������
double openPrice;               // ���� ��������
double currentPrice;            // ������� ����
double spread;                  // �����

CisNewBar isNewBar(_Symbol, _Period);   // ��� �������� ������������ ������ ����

int OnInit()
  {

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  { 
    ctm.OnTick();
    // ���� ����������� ����� ���
    if(isNewBar.isNewBar() > 0)
     {        

      if (openedPosition == false)
       { // ���� �� ����� ������� ��� �� ���� ������� �������
     
         if (ctm.OpenUniquePosition(_Symbol,_Period, OP_BUY, lot) )              // �������� ��������� �� BUY
           {
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);                   // ��������� ���� �������� �������
             openedPosition = true;                                              // ���� �������� ������� ���������� � true
           }
          
       }
      else
       {
         // ���� ��� ���� �������� �������
         openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);                       // �� ��������� ������� ���� �������� 

       }
       
     }
    else
     { // ���� ��� �� �����������
       if (openedPosition == true)
        { // ���� ���� ������� �������
         
          currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);                   // �������� ������� ����
          spread       = SymbolInfoDouble(_Symbol,SYMBOL_ASK) - currentPrice;    // ��������� ������� ������
         
          if ( (currentPrice - openPrice) > n_spreads*spread )
           {
              ctm.ClosePosition(_Symbol);                                        // ��������� �������
              openedPosition = false;                                            // ���������� ���� �������� ������� � false
     
           }
      
        }
     }
  }