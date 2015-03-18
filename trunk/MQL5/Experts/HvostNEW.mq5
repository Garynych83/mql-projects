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
#include <SystemLib/IndicatorManager.mqh>   // ���������� �� ������ � ������������
#include <CLog.mqh>                         // ��� ����

#include <ChartObjects/ChartObjectsLines.mqh>      // ��� ��������� ����� �����������

// ������� ��������� ������
input int    depth        = 3;      // �������      
input double lot          = 1.0;    // ���     

// ����������
double max_price;            // ������������ ���� ������
double min_price;            // ����������� ���� ������
double h;                    // ������ ������
double price_bid;            // ������� ���� bid
double price_ask;            // ������� ���� ask
double prev_price_bid=0;     // ���������� ���� bid
double prev_price_ask=0;     // ���������� ���� ask
double average_price;        // �������� ������� ���� �� ������ ��������� ������� � ������ (������������ ���������� wait_for_sell ��� wait_for_buy)
bool wait_for_sell=false;    // ���� �������� ������� �������� �� SELL
bool wait_for_buy=false;     // ���� �������� ������� �������� �� BUY
bool is_flat_now;            // ����, ������������, ���� �� ������ �� ������� ��� ��� 
int opened_position = 0;     // ���� �������� ������� (0 - ��� �������, 1 - buy, (-1) - sell)
int countBars;
ENUM_TIMEFRAMES periodEld;   // ������ �������� ����������
// ���������� ��� �������� ������� �������� ����
datetime signal_time;        // ����� ��������� ������� �������� ����� ������ �� ���������� H
datetime open_pos_time;      // ����� �������� �������   
// ������� �������
CTradeManager *ctm;          // ������ ��������� ������
CisNewBar *isNewBar;         // ��� ���������� ������������ ������ ���� �� ������� ��
CisNewBar *isNewBarEld;      // ��� ���������� ������������ ������ ���� �� ������� ��
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
   // ���� ������� ��������� ��������� ������ �������� �� ������� ��
   if (CountChannel()) 
    average_price = (max_price + min_price)/2;            
   // ��������� ������ �������� ���������� 
   periodEld = GetTopTimeframe(_Period);   // �������� �� �������, ������� ���������� ������� �� �� ��������� � ��������
   // ��������� ���� �������
   pos_info.volume = lot;
   pos_info.expiration = 0;
   // ��������� 
   trailing.trailingType = TRAILING_TYPE_NONE;
   isNewBar = new CisNewBar(_Symbol,_Period);
   isNewBarEld=new CisNewBar(_Symbol,periodEld);
      
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   Print("��� ������ = ",reason);
   // ������� �������
   delete ctm;
   delete isNewBar;
   delete isNewBarEld;
  }

void OnTick()
  { 
   ctm.OnTick();
   // ��������� ���������� �������� ���
   prev_price_ask = price_ask;
   prev_price_bid = price_bid;
   // �������� ������� �������� ��� 
   price_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   price_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   // ���� ������ ����� ��� �� ������� ��
   if (isNewBarEld.isNewBar() > 0)
    {
     // �� ������������� ��������� ������ 
     CountChannel();
     wait_for_buy = false;
     wait_for_sell = false;
    }
    
   // ���� ��� �������� ������� �� ���������� ��� ������� �� ����
   if (ctm.GetPositionCount() == 0)
    {
     opened_position = 0;   
    }
        
   // ���� ���� bid ������ ����� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
   if ( GreatDoubles(price_bid-max_price,h)  && LessOrEqualDoubles(prev_price_bid-max_price,h) && !wait_for_sell && opened_position!=-1 )
      {      
       Comment("max = ",DoubleToString(max_price), " min=",DoubleToString(min_price),
               "\n bid = ",DoubleToString(price_bid)," prev_bid = ",DoubleToString(prev_price_bid)," \n������ �� ������ �����",
               "\n ����� = ",TimeToString(TimeCurrent())
               );
       // �� ��������� � ����� ������� ��� �������� �� SELL 
       wait_for_sell = true;   
       wait_for_buy = false;
       countBars = 0;
       // ��������� ����� ��������� ������� �������� ������ �������� ����
       signal_time = TimeCurrent(); 
      }
   // ���� ���� ask ������ ���� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
   if ( GreatDoubles(min_price-price_ask,h) && LessOrEqualDoubles(min_price-prev_price_ask,h) && !wait_for_buy && opened_position!=1 )
      {      
       Comment("max = ",DoubleToString(max_price), " min=",DoubleToString(min_price),
               "\n ask = ",DoubleToString(price_ask)," prev_ask = ",DoubleToString(prev_price_ask)," \n������ �� ������ ����",
                              "\n ����� = ",TimeToString(TimeCurrent())
               );        
       // �� ��������� � ����� ������� ��� �������� �� BUY
       wait_for_buy = true; 
       wait_for_sell = false;
       countBars = 0;    
       // ��������� ����� ��������� ������� �������� ������ �������� ����
       signal_time = TimeCurrent();           
      }     
   // ���� ������� � ����� �������� ������� ��� �������� ������� �� SELL
   if (wait_for_sell)
      {  
       Print("������� SELL, ����� = ",TimeToString(TimeCurrent()) );               
       // ���� ������� ������� ��������� ��� ���� � �� ������� ���� �� ������� �� ��� ��� ������ 
       if (IsBeatenBars(-1))
        {
         Print("������ ��������� �� SELL ", TimeToString(TimeCurrent()));        
         // ���� �� ������� �� ����� ��� ��� �����
         if (/*TestEldPeriod(-1)*/true)
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
           // ��������� ����� �������� �������
           open_pos_time = TimeCurrent();         
          }
        }
      } 
     // ���� ������� � ����� �������� ������� ��� �������� ������� �� BUY
     if (wait_for_buy)
      {
       Print("������� BUY, ����� = ",TimeToString(TimeCurrent()) );
       // ���� ������� ������� ��������� ��� ���� � �� ������� ���� �� ������� �� ��� ��� ������
       if (IsBeatenBars(1))
        {
         Print("������ ��������� �� BUY ", TimeToString(TimeCurrent()));
         // ���� ������� ������� ��������� ��� ���� � �� ������� ���� �� ������� �� ��� ��� ������
         if (/*TestEldPeriod(1)*/true)
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
           // ��������� ����� �������� �������
           open_pos_time = TimeCurrent();   
          }
        }
      }
   // ���� ������� ��� �������, �� ������������ ������� �������� �������  
   if (opened_position)
    {    
     // ���� �� �������� ������ ������� �������� ������� (�������� �� ����������)
     if (IsBeatenExtremum(opened_position))
      {
       ctm.ClosePosition(0);
       Print("������� ������� �� ����������. ����� = ",TimeToString(TimeCurrent()) );  
      }
       
   /*  // ���� �� �������� ������ ������� �������� ������� (�������� �� ������������ ������� ��������� �������� �������)
     if ( (TimeCurrent() - open_pos_time) > 1.5*(open_pos_time - signal_time) )
      {
       ctm.ClosePosition(0);
       Print("������� ������� �� ������� ����� = ",TimeToString(TimeCurrent())," ����� ������� = ",TimeToString(signal_time)," ����� ������� = ",TimeToString(open_pos_time));
      } 
   */ 
    }  
  }
// ������� ��������� ��������� ������ �� ������� ����������  
bool CountChannel ()
 {
  double high_prices[];
  double low_prices[];
  int copiedHigh;
  int copiedLow;
  for (int attempts=0;attempts<25;attempts++)
   {
    copiedHigh = CopyHigh(_Symbol,periodEld,1,depth,high_prices);
    copiedLow  = CopyLow(_Symbol,periodEld,1,depth,low_prices);
    Sleep(100);
   }
  if (copiedHigh < depth || copiedLow < depth) 
   {
    Print("�� ������� ���������� ��������� �������� ����������");
    return (false);
   }
  max_price = high_prices[ArrayMaximum(high_prices)];
  min_price = low_prices[ArrayMinimum(low_prices)];
  h = max_price - min_price;
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
    return ( int ( MathAbs(price_ask - max_price)/_Point ) );  
   }
  if (type == -1)
   {
    return ( int ( MathAbs(price_bid - min_price)/_Point ) );    
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
    if (LessDoubles(price_ask,price_low[1]) && LessDoubles(price_ask,price_low[0]) && LessDoubles(price_low[1],price_low[0]) &&
        GreatDoubles(price_high[1],price_high[0]) && GreatDoubles(price_high[1],price_high[2]) )
     {
      return (true);
     } 
   }
  if (type == -1)
   {
    // ������� �������� ������� SELL 
    if (GreatDoubles(price_bid,price_high[1]) && GreatDoubles(price_bid,price_high[0]) && GreatDoubles(price_high[1],price_high[0]) &&
        LessDoubles(price_low[1],price_low[0]) && LessDoubles(price_low[1],price_low[2]) )
     {
      return (true);
     }    
   }
  return (false);
 } 

// ������� ������� �� ������� �� � ���������
bool TestEldPeriod (int type)
 {
  MqlRates eldPriceBuf[];  
  int copied_rates;
  for (int attempts=0;attempts<25;attempts++)
   {
    copied_rates = CopyRates(_Symbol,periodEld,1,depth,eldPriceBuf);
    Sleep(100);
   }
  if (copied_rates < depth)
   {
    Print("�� ������� ���������� ��� ���������");
    return (false);
   }
  // �������� �� ������������� ����� � ���������, ����� �� ���������� ���� �����
  for (int ind=0;ind<depth;ind++)
   {
    // ���� ����� ����������� �� Buy, �� �� ���� �������� ���� ����
    if (type == 1  &&  ( GreatDoubles(price_ask,eldPriceBuf[ind].open) || GreatDoubles(price_ask,eldPriceBuf[ind].close) ) )
      return (false);
    // ���� ����� ����������� �� Sell, �� �� ���� �������� ���� ����
    if (type == -1 &&  ( LessDoubles(price_bid,eldPriceBuf[ind].open)  || LessDoubles(price_bid,eldPriceBuf[ind].close) ) )
      return (false);      
   }
  return (true);
 } 