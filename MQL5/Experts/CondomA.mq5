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
#include <Lib CisNewBar.mqh>                // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>               // ��� ��������� �������������� �����
#include <CLog.mqh>                         // ��� ����
// ������� ��������� ������
input int depth = 20;     
input double lot = 1.0;      // ��� 
// ����������
double max_price;            // ������������ ���� ������
double min_price;            // ����������� ���� ������
double h;                    // ������ ������
double price_bid;            // ���� bid
double price_ask;            // ���� ask
double average_price;        // �������� ������� ���� �� ������ ��������� ������� � ������ (������������ ���������� wait_for_sell ��� wait_for_buy)
bool wait_for_sell=false;    // ���� �������� ������� �������� �� SELL
bool wait_for_buy=false;     // ���� �������� ������� �������� �� BUY
int mode=0;                  // ����� ������ ������
int opened_position = 0;     // ���� �������� ������� (0 - ��� �������, 1 - buy, (-1) - sell)
int last_move_bars;          // ���������� ����� ���������� ��������
int count_bars_to_close = 0; // ���������� ����� �� �������� �� �������� �������
// ������� ��� ��������� 4-� ����������� ��� ����������� �������� ��������
double extrHigh[2];          // ������ ����������� High
double extrLow[2];           // ������ ����������� Low
// ������
int handleDE;                // ����� DrawExtremums
// ������� �������
CTradeManager *ctm;          // ������ ��������� ������
CisNewBar *isNewBar;         // ��������� ������ ����

// ��������� ������� � ���������
SPositionInfo pos_info;      // ��������� ���������� � �������
STrailing     trailing;      // ��������� ���������� � ���������

int OnInit()
  {
   // ������� ������ ��������� ������ ��� �������� � �������� �������
   ctm = new CTradeManager();
   if (ctm == NULL)
    {
     Print("�� ������� ������� ������ ������ CTradeManager");
     return (INIT_FAILED);
    }    
   // ������� ������ CIsNewBar
   isNewBar = new CisNewBar(_Symbol,_Period);
   if (isNewBar == NULL)
    {
     Print("�� ������� ������� ������ ������ CisNewBar");
     return (INIT_FAILED);
    }
   // ������� ����� ���������� DrawExtremums
   handleDE = iCustom(_Symbol,_Period,"DE");
   if (handleDE == INVALID_HANDLE)
    {
     // �� ������� ������� ����� ���������� DrawExtremums
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
   delete isNewBar;
  }

void OnTick()
  {
   ctm.OnTick();
   // �������� ������� �������� ��� 
   price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   // ���� ������ ����� ���, �� ����������� ������� ����� �� �������
   if (isNewBar.isNewBar() > 0)
    count_bars_to_close++;
    
   if (ctm.GetPositionCount() == 0)
    {
     opened_position = 0;   
    }
     // ���� ������� ��������� �������� � �������
     if (GetMaxMinChannel())
      {
       // ���� ���� bid ����� ��������� ����� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
       if ( GreatDoubles(price_bid-max_price,/*h*2*/ h) )
        {
         // �� ��������� � ����� ������� ��� �������� �� SELL
         wait_for_sell = true;   
         wait_for_buy = false;
         // ���������� ������� ���� ��� ����������� ���������� ���� ������� 
         average_price = (max_price + min_price)/2;
         // �������� ������� ����� ��� ���������� ������� 
         count_bars_to_close = 0;
        }
       // ���� ���� ask ����� ��������� ���� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
       if ( GreatDoubles(min_price-price_ask,/*h*2*/h) )
        {
         // �� ��������� � ����� ������� ��� �������� �� BUY
         wait_for_buy = true; 
         wait_for_sell = false;   
         // ���������� ������� ���� ��� ����������� ���������� ���� ������� 
         average_price = (max_price + min_price)/2;  
         // �������� ������� ����� ��� ���������� �������
         count_bars_to_close = 0;                
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
         opened_position = -1;
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
         opened_position = 1;
        }
      }  
    /*      
    // ��������� �������� �������
    if (opened_position != 0)
     {     
      // ���� �������� ������ � ���, ��� ����� ��������� �������
      if (IsBeatenExtremum (opened_position))
       {
        ctm.ClosePosition(0);
       }
     }   
     */ 
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
  last_move_bars = depth;  // ��������� ����� ���������� ��������
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
    return ( int ( MathAbs(price_ask - ( (average_price)/2))/_Point ) );
   }
  if (type == -1)
   {
    return ( int ( MathAbs(price_bid - ( (average_price)/2))/_Point ) );   
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
    if (LessDoubles(price_ask,price_low[1]) && GreatDoubles(price_high[1],price_high[0]) && GreatDoubles(price_high[1],price_high[2]) )
     {
      return (true);
     } 
   }
  if (type == -1)
   {
    // ������� �������� ������� SELL  (������ ���������� �� ���������������)
    if (GreatDoubles(price_bid,price_high[1]) && LessDoubles(price_low[1],price_low[0]) && GreatDoubles(price_low[1],price_low[2]) )
     {
      return (true);
     }    
   }
  return (false);
 } 
 
// ������� ��������� ���� ��������� 4-� �����������
bool UploadLastExtremums ()
 {
  int ind;
  int bars = Bars(_Symbol,_Period);
  int extrCountHigh=0;
  int extrCountLow=0;
  double extrHigh[];
  double extrLow[];
  for (ind=0;ind<bars;)
   {
    if (CopyBuffer(handleDE,0,ind,1,extrHigh) < 1 || CopyBuffer(handleDE,1,ind,1,extrLow) < 1)
     continue;
    // ���� ��� ������ high ���������
    if (extrHigh[ind] != 0.0)
     {
      extrHigh[extrCountHigh] = extrHigh[ind];
      extrCountHigh++;
     }
    // ���� ��� ������ low ���������
    if (extrLow[ind] != 0.0)
     {
      extrLow[extrCountLow] = extrLow[ind];
      extrCountLow++;
     }     
    // ���� ���� ������� 4 ��������� ����������
    if (extrCountHigh == 2 && extrCountLow == 2)
     return (true);
    ind++;
   }
  return (false);
 }
 
// ������� ��������� �� 4-� �����������, �� �������� �� ��������� �������� ������
bool IsFlatNow ()
 {
  // ���� ������������ �������� �����
  if ( GreatDoubles (extrHigh[0],extrHigh[1]) && GreatDoubles(extrLow[0],extrLow[1]) )
   return (false);
  // ���� ������������ �������� ����
  if ( LessDoubles (extrHigh[0],extrHigh[1]) && LessDoubles(extrLow[0],extrLow[1]) )
   return (false);   
  return (true);
 }