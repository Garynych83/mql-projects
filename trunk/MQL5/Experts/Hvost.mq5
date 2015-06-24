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


#define K 0.5
// ������� ��������� ������
input int    channelDepth = 3;      // ������� ������
input int    tailDepth    = 20;     // ������� ����������� ������
input double lot          = 1.0;    // ���     
input bool   skipLastBar  = true;   // ���������� ��������� ��� ��� ������� ������
//input bool   usePBIFilter = true;   // ������������ ������ PBI
// ����������
double max_price;            // ������������ ���� ������
double min_price;            // ����������� ���� ������
double h;                    // ������ ������
double price_bid;            // ������� ���� bid
double price_ask;            // ������� ���� ask
double prev_price_bid=0;     // ���������� ���� bid
double prev_price_ask=0;     // ���������� ���� ask
double average_price;        // �������� ������� ���� �� ������ ��������� ������� � ������ (������������ ���������� wait_for_sell ��� wait_for_buy)
bool wait_for_sell = false;  // ���� �������� ������� �������� �� SELL
bool wait_for_buy = false;   // ���� �������� ������� �������� �� BUY
bool is_flat_now;            // ����, ������������, ���� �� ������ �� ������� ��� ��� 
int opened_position = 0;     // ���� �������� ������� (0 - ��� �������, 1 - buy, (-1) - sell)
int countBars;
int handlePBI;               // ������ PriceBasedIndicator
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
   // ��������� ������ �������� ���������� 
   periodEld = GetTopTimeframe(_Period);   // �������� �� �������, ������� ���������� ������� �� �� ��������� � ��������    
   // ���� ������� ��������� ��������� ������ �������� �� ������� ��
   if (CountChannel()) 
    average_price = (max_price + min_price)/2;            

   // ��������� ���� �������
   pos_info.volume = lot;
   pos_info.expiration = 0;
   // ��������� 
   trailing.trailingType = TRAILING_TYPE_NONE;
   isNewBar = new CisNewBar(_Symbol,_Period);
   isNewBarEld = new CisNewBar(_Symbol, periodEld);
   // ������� ����� ���������� PriceBasedIndicator
   handlePBI = iCustom(_Symbol, periodEld, "PriceBasedIndicator");
   if (handlePBI == INVALID_HANDLE)
    {
     Print("�� ������� ������� ����� ���������� PriceBasedIndicator");
     return (INIT_FAILED);
    }      
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   Print("��� ������ = ",reason);
   // ������� �������
   delete ctm;
   delete isNewBar;
   delete isNewBarEld;
   IndicatorRelease(handlePBI);
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
   if ( GreatDoubles(price_bid-max_price,K*h) && !wait_for_sell && opened_position!=-1 )
      {  
       log_file.Write(LOG_DEBUG, StringFormat("��� ������� = %s", PeriodToString(_Period)));  
       // ���� ���� bid ������ ����� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
       log_file.Write(LOG_DEBUG, StringFormat("(pBid(%f)-pAsk(%f))(%f) > K*h(%f)=(%f) && wait_for_sell(%s) && opened_position(%d)!=-1", price_bid, max_price, (price_bid-max_price), h, K*h, BoolToString(wait_for_sell), opened_position));  
       // �� ��������� � ����� ������� ��� �������� �� SELL 
       wait_for_sell = true;   
       wait_for_buy = false;
       countBars = 0;
       // ��������� ����� ��������� ������� �������� ������ �������� ����
       signal_time = TimeCurrent(); 
      }
   // ���� ���� ask ������ ���� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
   if ( GreatDoubles(min_price-price_ask, K*h) && !wait_for_buy && opened_position != 1 )
      {
       log_file.Write(LOG_DEBUG, StringFormat("��� ������� = %s", PeriodToString(_Period))); 
       log_file.Write(LOG_DEBUG, StringFormat("(min_price(%f) - price_ask(%f))(%f) > K*h(%f)=(%f) && wait_for_buy(%s) && opened_position(%d) != 1", min_price, price_ask, (min_price-price_ask), h, K*h, BoolToString(wait_for_buy), opened_position));  
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
       // ���� ������� ������� ��������� ��� ���� 
       if (IsBeatenBars(-1))
        {
         // ���� �� ������� �� ����� ��� ��� �����
         if (TestEldPeriod(-1) /*&& IsFlatNow ()GetLastTrend ()!=1*/)
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
       // ���� ������� ������� ��������� ��� ���� 
       if (IsBeatenBars(1))
        {
         // �� ������� ���� �� ������� �� ��� ��� ������
         if (TestEldPeriod(1) /*&& IsFlatNow ()&& GetLastTrend ()!=-1*/)
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
 
  }
// ������� ��������� ��������� ������ �� ������� ����������  
bool CountChannel ()
 {
  int startIndex = (skipLastBar)?2:1;
  double high_prices[];
  double low_prices[];
  int copiedHigh;
  int copiedLow;
  for (int attempts=0;attempts<25;attempts++)
   {
    copiedHigh = CopyHigh(_Symbol, periodEld, startIndex, channelDepth, high_prices);
    copiedLow  = CopyLow (_Symbol, periodEld, startIndex, channelDepth, low_prices);
    Sleep(100);
   }
  if (copiedHigh < channelDepth || copiedLow < channelDepth) 
   {
    Print("�� ������� ���������� ��������� �������� ����������");
    return (false);
   }
  max_price = high_prices[ArrayMaximum(high_prices)];
  min_price = low_prices[ArrayMinimum(low_prices)];
  log_file.Write(LOG_DEBUG, StringFormat("��� ���� max_price = %f �� ������� ������� = %s", max_price, PeriodToString(periodEld)));
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
    return ( int( (price_bid-prices[ArrayMinimum(prices)])/_Point) + 50 );   
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
    return ( int( (prices[ArrayMaximum(prices)] - price_ask)/_Point) + 50 );
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
    if (LessDoubles(price_ask,price_low[1]) && LessDoubles(price_ask,price_low[0])// && LessDoubles(price_low[1],price_low[0])
        && GreatDoubles(price_high[1],price_high[0]) && GreatDoubles(price_high[1],price_high[2]) )
     {
      return (true);
     } 
   }
  if (type == -1)
   {
    // ������� �������� ������� SELL 
    if (GreatDoubles(price_bid,price_high[1]) && GreatDoubles(price_bid,price_high[0])// && GreatDoubles(price_high[1],price_high[0]) 
        && LessDoubles(price_low[1],price_low[0]) && LessDoubles(price_low[1],price_low[2]) )
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
  int startIndex = (skipLastBar)?2:1;
  for (int attempts=0; attempts<25; attempts++)
   {
    copied_rates = CopyRates(_Symbol, periodEld, startIndex, tailDepth, eldPriceBuf);
    Sleep(100);
   }
  if (copied_rates < tailDepth)
   {
    Print("�� ������� ���������� ��� ���������");
    return (false);
   }
  // �������� �� ������������� ����� � ���������, ����� �� ���������� ���� �����
  for (int ind = 0; ind < tailDepth+1-startIndex; ind++)
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

// ������� ���������� ��� ���������� ������
int GetLastTrend ()
 {
  double buffPBI[];
  int bars = Bars(_Symbol,_Period);
  for (int ind=1;ind<bars;)
   {
    if (CopyBuffer(handlePBI,4,ind,1,buffPBI) < 1)
      {
       Sleep(100);
       continue;
      }
    // ���� ����� ��������� �������� �����
    if (buffPBI[0] == 1.0 || buffPBI[0] == 2.0)
     return (1);
    // ���� ����� ��������� �������� ����
    if (buffPBI[0] == 3.0 || buffPBI[0] == 4.0)
     return (-1);
    ind++;
   }
  return (0);
 }
 
// ������� ���������� true, ���� � ������ ������ - ����
bool IsFlatNow ()
 {
  double buffPBI[];
  if (CopyBuffer(handlePBI,4,0,1,buffPBI) < 1)
   {
    return (false);
   }
  if (buffPBI[0] == 7.0)
   return (true);
  return (false);
 }
 
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---
   
}
//+------------------------------------------------------------------+