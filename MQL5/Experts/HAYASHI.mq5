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

enum SYMBOLS 
 {
  SYM_EURUSD=0,
  SYM_GBPUSD,
  SYM_USDCHF,
  SYM_USDJPY,
  SYM_USDCAD,
  SYM_AUDUSD
 };


input double lot             = 1;          // ���
input int    n_spreads       = 1;          // ���������� ������
input SYMBOLS sym            = SYM_EURUSD; // ������
input ENUM_TIMEFRAMES per    = PERIOD_M1;  // ������


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
//| ������� ���c�                                                    |
//+------------------------------------------------------------------+

CTradeManager ctm(); 
bool   openedPosition = false;  // ���� ������� �������
double openPrice;               // ���� ��������
string symb;

    static CisNewBar isNewBar(symb, per);   // ��� �������� ������������ ������ ����

MqlDateTime timeStr;            // ��������� ������� ��� �������� �������� �������

int OnInit()
  {
   switch (sym)
    {
     case SYM_EURUSD:
      symb = "EURUSD";
     break;
     case SYM_AUDUSD:
      symb = "AUDUSD";
     break;
     case SYM_GBPUSD:
      symb = "GBPUSD";
     break;
     case SYM_USDCAD:
      symb = "USDCAD";
     break;
     case SYM_USDCHF:
      symb = "USDCHF";
     break;
     case SYM_USDJPY:
      symb = "USDJPY";
     break;
    }
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  { 

    double currentPrice;                           // ������� ����
    double spread;                                 // �����
    
    // ���� ����������� ����� ���
    if(isNewBar.isNewBar() > 0)
     {        
      if (openedPosition == false)
       { // ���� �� ����� ������� ��� �� ���� ������� �������
     
         if (ctm.OpenUniquePosition(symb,per, OP_SELL, lot) ) // �������� ��������� �� SELL
           {
             openPrice = SymbolInfoDouble(symb,SYMBOL_BID);       // ��������� ���� �������� �������
             openedPosition = true;                                  // ���� �������� ������� ���������� � true
           }
          
       }
      else
       {
         // ���� ��� ���� �������� �������
         openPrice = SymbolInfoDouble(symb,SYMBOL_BID); // �� ��������� ������� ���� �������� 

       }
     }
    else
     { // ���� ��� �� �����������
       if (openedPosition == true)
        { // ���� ���� ������� �������
         
          currentPrice = SymbolInfoDouble(symb,SYMBOL_ASK);                // �������� ������� ����
          spread       = currentPrice - SymbolInfoDouble(symb,SYMBOL_BID); // ��������� ������� ������
         
          if ( (currentPrice - openPrice) > n_spreads*spread )
           {
              ctm.ClosePosition(symb);             // ��������� �������
             openedPosition = false;                  // ���������� ���� �������� ������� � false
     
           }
       
          
           
               
        }
     }
  }