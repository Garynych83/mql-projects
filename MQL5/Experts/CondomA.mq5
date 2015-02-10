//+------------------------------------------------------------------+
//|                                                      CondomA.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ������ ����������� ������� ��������� �                           |
//+------------------------------------------------------------------+

// ����������� ����������� ���������
#include <TradeManager/TradeManager.mqh>    // �������� ����������
#include <CompareDoubles.mqh>               // ��� ��������� �������������� �����
#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <SystemLib/IndicatorManager.mqh>   // ���������� �� ������ � ������������
#include <CLog.mqh>                         // ��� ����
// ������� ��������� ������
input int depth = 20;     
input double lot = 1.0;   // ��� 
// ����������
double max_price;         // ������������ ���� ������
double min_price;         // ����������� ���� ������
double h;                 // ������ ������
double price_bid;         // ���� bid
double price_ask;         // ���� ask
bool wait_for_sell=false; // ���� �������� ������� �������� �� SELL
bool wait_for_buy=false;  // ���� �������� ������� �������� �� BUY
int mode=0;               // ����� ������ ������
// ������� �������
CTradeManager *ctm;     // ������ ��������� ������
// ��������� ������� � ���������
SPositionInfo pos_info; // ��������� ���������� � �������
STrailing     trailing; // ��������� ���������� � ���������

int OnInit()
  {
   // ������� ������ ��������� ������ ��� �������� � �������� �������
   ctm = new CTradeManager();
   if (ctm == NULL)
    {
     Print("�� ������� ������� ������ ������ CTradeManager");
     return (INIT_FAILED);
    }    
   // ��������� ���� �������
   pos_info.volume = lot;
   pos_info.expiration = 0;
   // ��������� 
   trailing.trailingType = TRAILING_TYPE_NONE;
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // ������� �������
   delete ctm;
  }

void OnTick()
  {
   // �������� ������� �������� ��� 
   price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   // ���� ������� ��������� �������� � �������
   if (GetMaxMinChannel())
    {
     // ���� ���� bid ����� ��������� ����� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
     if ( GreatDoubles(price_bid-max_price,/*h*2*/ h) )
      {
       // �� ��������� � ����� ������� ��� �������� �� SELL
       wait_for_sell = true;   
       wait_for_buy = false;      
      }
     // ���� ���� ask ����� ��������� ���� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
     if ( GreatDoubles(min_price-price_ask,/*h*2*/h) )
      {
       // �� ��������� � ����� ������� ��� �������� �� BUY
       wait_for_buy = true; 
       wait_for_sell = false;            
      }        
    }         
   // ���� ������� � ����� �������� ������� ��� �������� ������� �� SELL
   if (wait_for_sell)
    {
     // ���� ������� ������� ��������� ��� ���� 
     if (IsBeatenBars(-1))
      {
       // ��������� ���� ����, ���� ������ � ��������� ������� �� SELL
       pos_info.type = OP_SELL;
       pos_info.sl = CountStopLoss(-1);       
       pos_info.tp = CountTakeProfit(-1);
       pos_info.priceDifference = 0;     
       ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing); 
       wait_for_sell = false;     
       wait_for_buy = false;  
      }
    } 
   // ���� ������� � ����� �������� ������� ��� �������� ������� �� BUY
   if (wait_for_buy)
    {
     // ���� ������� ������� ��������� ��� ����
     if (IsBeatenBars(1))
      {
       // ��������� ���� ����, ���� ������ � ��������� ������� �� BUY
       pos_info.type = OP_BUY;
       pos_info.sl = CountStopLoss(1);       
       pos_info.tp = CountTakeProfit(1);
       pos_info.priceDifference = 0;       
       ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);    
       wait_for_buy = false;
       wait_for_sell = false;
      }
    }
  }
  
// ����������� �������������� ������� ������
bool GetMaxMinChannel ()
 {
  // �� ������ ����� �������� ������� � �������� ������ �� �������� �������
  int copied_high;
  int copied_low;
  double price_high[];
  double price_low[];
  for(int i=0;i<5;i++)
   {
    copied_high = CopyHigh(_Symbol,_Period,1,depth,price_high);
    copied_low  = CopyLow(_Symbol,_Period,1,depth,price_low);
    Sleep(100);
   }
  if (copied_high < depth || copied_low < depth)
   {
    Print("�� ������� ���������� ������ ���");
    return (false);
   }
  // ����� ��������� �������� � ������� �� �������� ��������
  max_price = price_high[ArrayMaximum(price_high)]; 
  min_price = price_low[ArrayMinimum(price_low)];
  h = max_price - min_price;
  // Comment("������������ ���� = ",DoubleToString(max_price)," ����������� ���� = ",DoubleToString(min_price) );
  return (true);
 }

// ��������� ���� ����
int CountStopLoss (int type)
 {
  int copied;
  double prices[];
  if (type == 1)
   {
    copied = CopyLow(_Symbol,_Period,1,2,prices);
    if (copied < 2)
     {
      Print("�� ������� ����������� ����");
      return (0);
     } 
    // ������ ���� ���� �� ������ ��������
    return ( int( (price_bid-prices[ArrayMinimum(prices)])/_Point) + 30 );   
   }
  if (type == -1)
   {
    copied = CopyHigh(_Symbol,_Period,1,2,prices);
    if (copied < 2)
     {
      Print("�� ������� ����������� ����");
      return (0);
     } 
    // ������ ���� ���� �� ������ ���������
    return ( int( (prices[ArrayMaximum(prices)] - price_ask)/_Point) + 30 );
   }
  return (0);
 }
  
// ��������� ���� ������
int CountTakeProfit (int type)
 {
  if (type == 1)
   {
    return ( int ( MathAbs(price_ask - ( (max_price+min_price)/2))/_Point ) );
   }
  if (type == -1)
   {
    return ( int ( MathAbs(price_bid - ( (max_price+min_price)/2))/_Point ) );   
   }
  return (0);
 }
  
// ������� �������� �������� ��������� ���� �����
bool IsBeatenBars (int type)
 {
  int copiedBars;
  double prices[];
  if (type == 1)  // ���� ����� ��������� �������� �� BUY
   {
     copiedBars = CopyHigh(_Symbol,_Period,1,2,prices);
     if (copiedBars < 2)
      {
       Print("�� ������� ����������� ����");
       return (false);
      }
     if ( GreatDoubles(price_bid,prices[0]) && GreatDoubles(price_bid,prices[1]) )
      {
       return (true);  // �������, ��� ������� ������� ��������� ��� ���������
      }     
   }
  if (type == -1)  // ���� ����� ��������� �������� �� SELL
   {
     copiedBars = CopyLow(_Symbol,_Period,1,2,prices);
     if (copiedBars < 2)
      {
       Print("�� ������� ����������� ����");
       return (false);
      }
     if ( LessDoubles(price_ask,prices[0]) && LessDoubles(price_ask,prices[1]) )
      {
       return (true);  // �������, ��� ������� ������� ��������� ��� ���������
      }
   }
   return (false);  // ������ �� �������
 }
 
// ������� ��� �������� ������� �� ����������
bool IsBeatenExtremum (int type)
 {
  int copied_high;
  int copied_low;
  double price_high[];
  double price_low[];
  copied_high = CopyHigh(_Symbol,_Period,0,3,price_high);
  copied_low  = CopyLow(_Symbol,_Period,0,3,price_low);
  if (copied_high < 3 || copied_low < 3)
   {
    Print("�� ������� ���������� ������ ���");
    return (false);
   }
  if (type == 1)
   {
    // ������� �������� ������� BUY
    if (LessDoubles(price_ask,price_low[1]) && GreatDoubles(price_high[1],price_high[0]) && GreatDoubles(price_high[1],price_high[2])
     {
      return (true);
     } 
   }
  if (type == -1)
   {
    // ������� �������� ������� SELL  (������ ���������� �� ���������������)
    if (LessDoubles(price_ask,price_low[1]) && GreatDoubles(price_high[1],price_high[0]) && GreatDoubles(price_high[1],price_high[2])
     {
      return (true);
     }    
   }
  return (false);
 }