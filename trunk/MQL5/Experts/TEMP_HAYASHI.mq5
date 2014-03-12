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

input double lot              = 0.1;      // ��������� ������ ����
input int    stop_loss        = 60;       // ���� ����
input int    size_of_series   = 5;        // ������� ������ ����� ������
input double lot_d            = 1.5;      // ����������� ���������� ����


//+------------------------------------------------------------------+
//| ������� ���c�                                                    |
//+------------------------------------------------------------------+


CTradeManager ctm(); 
bool   openedPosition = false;            // ���� ������� �������
bool   isNormalPos    = false;            // ���� �������� ���������� �������
bool   was_a_part     = false;            // ���� �������� �����
double openPrice;                         // ���� ��������
//double lot_d          = 1.5;              // ������� ��������� ����
double current_lot    = lot;              // ������� ���
int    count_long     = 0;                // ������� ����� �����
datetime history_start;



void   ModifyLot (bool mode)              // ������� �������� ������ ����
 {
  if (mode == true)
   current_lot = current_lot * lot_d;     // ������������ ���
  else
   current_lot = lot;                     // ������������ ����������� ��� 
 }

int OnInit()
  {
   history_start=TimeCurrent();  
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }

int cnt=0;

void OnTick()
  {
    static CisNewBar isNewBar(_Symbol, _Period);   // ��� �������� ������������ ������ ����
    double currentPrice;                           // ������� ����
    double spread;                                 // �����
   
    //Comment("������� ������ ����� = ",count_long);
    // ���� ����������� ����� ���  
    
    
    
    cnt++;
    if(isNewBar.isNewBar() > 0)
     {
      if (isNormalPos == false)  // ���� �� ���������� ���� ������� �� ���������, ��� �����
       {
         was_a_part  = false;
         count_long  = 0; 
         current_lot = lot;      // ���������� ��� �����  
       //  Comment("������� ��������� �� �� �������");          
       }
      else
         Alert("������� ��������� �� �������");
      isNormalPos = false;
      if (openedPosition == false)
       { // ���� �� ����� ������� ��� �� ���� ������� �������
         if (ctm.OpenUniquePosition(_Symbol, OP_BUY, current_lot,stop_loss) ) // �������� ��������� �� BUY 
           {
             Comment("��� = "+current_lot);
             openPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ��������� ���� �������� �������
             openedPosition = true;                            // ���� �������� ������� ���������� � true
             was_a_part     = true;                            // ���������� ���� ����������� ����� � true
           }  
       }
      else
       {
         // ���� ��� ���� �������� �������
         openPrice   = SymbolInfoDouble(_Symbol,SYMBOL_ASK);   // �� ��������� ������� ���� �������� 
       }
     }
    else
     { // ���� ��� �� �����������
       if (openedPosition == true)
        { // ���� ���� ������� �������
          currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID); // �������� ������� ����
          spread       = SymbolInfoDouble(_Symbol,SYMBOL_ASK) - currentPrice; // ��������� ������� ������
 //         Comment ("����� = ",spread);
          if ((currentPrice - openPrice) > spread)
           { // ���� ������� ���� ��������� ���� ��������
             ctm.ClosePosition(_Symbol); // ��������� �������
             openedPosition = false;     // ���������� ���� �������� ������� � false
             isNormalPos    = true;      // ������, �� ������� ��������� �� �����������
             if (was_a_part == true)     // ���� �� ���� ��������� ���� �������
              {
                if (count_long < size_of_series)
                 {
                   ModifyLot (true); // ������������ ���
                 }
                else
                 {
                  ModifyLot (false); // ������ ��� � ����������� ��������
                  count_long = 0;
                 }
                count_long ++;   // ����������� ����� �����
              }

           }
        }
     }
  }
  
  
  void OnTrade ()
   {
    ctm.OnTrade(history_start);
   }