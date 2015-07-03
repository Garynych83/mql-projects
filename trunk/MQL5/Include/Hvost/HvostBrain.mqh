//+------------------------------------------------------------------+
//|                                                   HvostBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>               // ��� ��������� �������������� �����
#include <TradeManager/TradeManager.mqh>    // �������� ����������
#include <CLog.mqh>                         // ��� ����
#include <ContainerBuffers.mqh>     // ��������� ������� ������ ��� �� CisNewBar
#include <Brain.mqh>

#define BUY   1    
#define SELL -1 
#define NO_POSITION 0
#define K 0.5
#define _channelDepth 3 // ������� ������
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

class CHvostBrain : public CArrayObj
{
 private:
  // ������� ���������
  //bool _skipLastBar;     // ���������� ��������� ��� ��� ��������
  int  _tailDepth;         // =20 ������� ����������� ������ (�������� �� OnInit())
  string _symbol;
  ENUM_TIMEFRAMES _period;
  CContainerBuffers *_conbuf;
  int opened_position;     // ���� �������� ������� (0 - ��� �������, 1 - buy, (-1) - sell)
  int _magic;
  ENUM_SIGNAL_FOR_TRADE _current_direction;  // ������������ ���������� ������� (SEll, BUY, DISCORD(0) - �������� ���������)
  double h;                // ������ ������
  double price_bid;        // ������� ���� bid
  double price_ask;        // ������� ���� ask
  double prev_price_bid;   // ���������� ���� bid
  double prev_price_ask;   // ���������� ���� ask 
  double max_price;        // ������������ ���� ������
  double min_price;        // ����������� ���� ������
  bool wait_for_sell;      // ���� �������� ������� �������� �� SELL
  bool wait_for_buy;       // ���� �������� ������� �������� �� BUY
  CisNewBar *isNewBarEld;  // ��� ���������� ������������ ������ ���� �� ������� ��
  // ���������� ��� �������� ������� �������� ����
  datetime signal_time;        // ����� ��������� ������� �������� ����� ������ �� ���������� H  
  ENUM_TIMEFRAMES periodEld;   // ������ �������� ����������
  double average_price;        // (ר?) �������� ������� ���� �� ������ ��������� ������� � ������ (������������ ���������� wait_for_sell ��� wait_for_buy)
 public:
                     CHvostBrain(string symbol, ENUM_TIMEFRAMES period, CContainerBuffers *conbuf);
                    ~CHvostBrain();
             virtual ENUM_TM_POSITION_TYPE  GetSignal();
             virtual long  GetMagic(){return _magic;}
             virtual ENUM_SIGNAL_FOR_TRADE  GetDirection(){return _current_direction;}
             virtual ENUM_TIMEFRAMES GetPeriod(){return _period;}
             virtual int  GetTakeProfit();
             virtual int  GetStopLoss();
                     bool IsBeatenBars (int type);
                     bool IsBeatenExtremum (int type);
                     bool TestEldPeriod (int type);
                     int  GetLastTrend();
                     bool IsFlatNow();
                     int  GetOpenedPosition()   {return opened_position;}
                     double GetPriceBid()       { return price_bid;}
                     double GetPriceAsk()       { return price_ask;}
                     void SetOpenedPosition(int p){opened_position = p;}
                     bool CountChannel();
                     
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CHvostBrain::CHvostBrain(string symbol, ENUM_TIMEFRAMES period, CContainerBuffers *conbuf)
{
 _tailDepth = 20;
 _symbol = symbol;
 _period = period;
 _conbuf =  conbuf;
 _current_direction = NO_SIGNAL;
 opened_position = 0;
 prev_price_bid = 0;    
 prev_price_ask = 0;     
 wait_for_sell = false;    
 wait_for_buy= false;   
 // �������� �� �������, ������� ���������� ������� �� �� ��������� � ��������
 periodEld = GetTopTimeframe(_period);   // �������� �� �������, ������� ���������� ������� �� �� ��������� � ��������
 // ���� ������� ��������� ��������� ������ �������� �� ������� ��
 if (CountChannel()) 
  average_price = (max_price + min_price)/2;            
 // ��������� ������ �������� ���������� 
 isNewBarEld = new CisNewBar(_symbol, periodEld);
 // ������� ����� ���������� PriceBasedIndicator
}
 //+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CHvostBrain::~CHvostBrain()
{
 delete isNewBarEld;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE CHvostBrain::GetSignal()
{
 // ��������� ���������� �������� ���
 prev_price_ask = price_ask;
 prev_price_bid = price_bid;
 // �������� ������� �������� ��� 
 price_bid = SymbolInfoDouble(_symbol, SYMBOL_BID);
 price_ask = SymbolInfoDouble(_symbol, SYMBOL_ASK);
 if (isNewBarEld.isNewBar() > 0)
 {
  // �� ������������� ��������� ������ 
  CountChannel();
  wait_for_buy = false;
  wait_for_sell = false;
 }  
 if ( GreatDoubles(price_bid-max_price,K*h) && !wait_for_sell && opened_position!=-1 )
 {   
  log_file.Write(LOG_DEBUG, StringFormat("��� ������� = %s", PeriodToString(_period)));
  // ���� ���� bid ������ ����� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
  log_file.Write(LOG_DEBUG, StringFormat("(pBid(%f)-pAsk(%f))(%f) > K*h(%f)=(%f) && wait_for_sell(%s) && opened_position(%d)!=-1", price_bid, max_price, (price_bid-max_price), h, K*h, BoolToString(wait_for_sell), opened_position));
   
  log_file.Write(LOG_DEBUG, " ���� bid ������ ����� � ���������� �� ��� �� ������ � 2 ���� ������ ��� ������ ������");
  // �� ��������� � ����� ������� ��� �������� �� SELL 
  wait_for_sell = true;   
  log_file.Write(LOG_DEBUG, "����� �������� ������� ��� �������� ������� �� SELL");
  wait_for_buy = false;
  //countBars = 0;
  // ��������� ����� ��������� ������� �������� ������ �������� ����
  signal_time = TimeCurrent(); 
 }
 // ���� ���� ask ������ ���� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
 if ( GreatDoubles(min_price-price_ask, K*h) && !wait_for_buy && opened_position!=1 )
 { 
  log_file.Write(LOG_DEBUG, StringFormat("��� ������� = %s", PeriodToString(_period)));
  // ���� ���� bid ������ ����� � ���������� �� ��� �� ������ ��� ������� 2 ���� ������, ��� ������ ������
  log_file.Write(LOG_DEBUG, StringFormat("(min_price(%f)-price_ask(%f))(%f) > K*h(%f)=(%f) && wait_for_buy(%s) && opened_position(%d)!=-1", min_price, price_ask, (min_price - price_ask), h, K*h, BoolToString(wait_for_buy), opened_position));
    
  log_file.Write(LOG_DEBUG, " ���� ask ������ ����� � ���������� �� ��� �� ������ � 2 ���� ������ ��� ������ ������");    
  // �� ��������� � ����� ������� ��� �������� �� BUY
  wait_for_buy = true; 
  wait_for_sell = false;
  log_file.Write(LOG_DEBUG, "����� �������� ������� ��� �������� ������� �� BUY");
  //countBars = 0;    
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
    opened_position = -1;
    wait_for_sell = false;     
    wait_for_buy = false;
    log_file.Write(LOG_DEBUG, "����� �������� �������");
    _current_direction = SELL;
    return OP_SELL;       
   }
  }
 } 
 // ���� ������� � ����� �������� ������� ��� �������� ������� �� BUY
 if (wait_for_buy)
 {
  // ���� ������� ������� ��������� ��� ���� 
  if (IsBeatenBars(1))
  {
   log_file.Write(LOG_DEBUG, "������ ��������� ��� ���� �� IsBeatenBars(1)");
   // �� ������� ���� �� ������� �� ��� ��� ������
   if (TestEldPeriod(1) /*&& IsFlatNow ()&& GetLastTrend ()!=-1*/)
   {
    log_file.Write(LOG_DEBUG, " �����������! �� ������� ���� �� ������� �� ��� ��� ������ TestEldPeriod(1)");
    opened_position = 1;
    wait_for_buy = false;
    wait_for_sell = false;
    _current_direction = BUY;
    return OP_BUY;
   }
  }
 }  
 return OP_UNKNOWN;
}
//+------------------------------------------------------------------+
// ������� ��������� ��������� ������ �� ������� ����������  
bool CHvostBrain::CountChannel()
{
 int startIndex = 2;//(_skipLastBar)?2:1;
 int indexMax = 0;
 int indexMin = 0;
 // ������� ������ ������������� � ������������ ��������� �� ������� _channelDepth
 indexMax = ArrayMaximum(_conbuf.GetHigh(periodEld).buffer, startIndex, _channelDepth);
 indexMin = ArrayMinimum(_conbuf.GetLow(periodEld).buffer, startIndex, _channelDepth);
 if(indexMax < 0 || indexMin < 0)
 return (false);
 max_price = _conbuf.GetHigh(periodEld).buffer[indexMax];
 min_price = _conbuf.GetLow(periodEld).buffer[indexMin];
 log_file.Write(LOG_DEBUG, StringFormat("��� ���� max_price = %f ��� ������� %s �� ������� ������� = %s", max_price, PeriodToString(_period), PeriodToString(periodEld)));

 h = max_price - min_price;
 return (true);
}  



// ������� �������� �������� ��������� ���� �����
bool  CHvostBrain::IsBeatenBars (int type)
{
 //Print ("Count = ", _);
 double prices[];
 if (type == 1)  // ���� ����� ��������� �������� �� BUY
 {
  if (GreatDoubles(price_bid, _conbuf.GetHigh(_period).buffer[1]) 
   && GreatDoubles(price_bid, _conbuf.GetHigh(_period).buffer[2]))
  {
   return (true);  // �������, ��� ������� ������� ��������� ��� ���������
  }     
 }
 if (type == -1)  // ���� ����� ��������� �������� �� SELL
 {
  if(LessDoubles(price_ask, _conbuf.GetLow(_period).buffer[1]) 
  && LessDoubles(price_ask, _conbuf.GetLow(_period).buffer[2]))
  {
   return (true);  // �������, ��� ������� ������� ��������� ��� ���������
  }
 }
 return (false);  // ������ �� �������
}

// ������� ��� �������� ������� �� ����������
bool  CHvostBrain::IsBeatenExtremum (int type)
{

 if (type == 1)
 {
  // ������� �������� ������� BUY
  if(LessDoubles(price_ask, _conbuf.GetLow(_period).buffer[1]) 
  && LessDoubles(price_ask,_conbuf.GetLow(_period).buffer[0])
  && GreatDoubles(_conbuf.GetHigh(_period).buffer[1], _conbuf.GetHigh(_period).buffer[0])
  && GreatDoubles(_conbuf.GetHigh(_period).buffer[1], _conbuf.GetHigh(_period).buffer[2]))
  {
   return (true);
  } 
 }
 if (type == -1)
 {
  // ������� �������� ������� SELL 
  if(GreatDoubles(price_bid, _conbuf.GetHigh(_period).buffer[1]) 
  && GreatDoubles(price_bid,_conbuf.GetHigh(_period).buffer[0])
  && LessDoubles(_conbuf.GetLow(_period).buffer[1], _conbuf.GetLow(_period).buffer[0])
  && LessDoubles(_conbuf.GetLow(_period).buffer[1], _conbuf.GetLow(_period).buffer[2]))
  {
   return (true);
  }    
 }
 return (false);
} 

// ������� ������� �� ������� �� � ���������
bool  CHvostBrain::TestEldPeriod (int type)
{
 MqlRates eldPriceBuf[];  
 int copied_rates = -1;
 int startIndex = 2; //(_skipLastBar)?2:1;
 for (int attempts=0; attempts<25; attempts++)
 {
  copied_rates = CopyRates(_symbol, periodEld, startIndex, _tailDepth, eldPriceBuf);
  Sleep(100);
 }
 if (copied_rates < _tailDepth)
 {
  log_file.Write(LOG_DEBUG, "�� ������� ���������� ������ ���");
  //Print("�� ������� ���������� ��� ���������");
  return (false);
 }
 // �������� �� ������������� ����� � ���������, ����� �� ���������� ���� �����
 for (int ind = 0; ind < _tailDepth + 1 - startIndex; ind++)
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
int  CHvostBrain::GetLastTrend ()
{
 int bars = Bars(_symbol,_period);
 for (int ind = 1; ind < bars;)
 {
  // ���� ����� ��������� �������� �����
  if (_conbuf.GetPBI(periodEld).buffer[ind] == 1.0 
   || _conbuf.GetPBI(periodEld).buffer[ind] == 2.0)
   return (1);
  // ���� ����� ��������� �������� ����
  if (_conbuf.GetPBI(periodEld).buffer[ind] == 3.0 
   || _conbuf.GetPBI(periodEld).buffer[ind] == 4.0)
   return (-1);
  ind++;
 }
 return (0);
}
 
// ������� ���������� true, ���� � ������ ������ - ����
bool  CHvostBrain::IsFlatNow ()
{
 if (_conbuf.GetPBI(periodEld).buffer[0] == 7.0)
  return (true);
 return (false);
}

int CHvostBrain::GetStopLoss()
{
 int stop_level;
 double pr_bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
 double pr_ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
 if (_current_direction == BUY)// ������ ���� ���� �� ������ ��������
 {
  // ������ ���� ���� �� ������ ��������
  return ( int( (pr_bid-_conbuf.GetLow(_period,ArrayMinimum(_conbuf.GetLow(_period).buffer,1,2)+1))/_Point) + 50 );  // + 1 ������ ��� ������ ��� ������ �� ���� ��-�� ������� � 1��� � ���������� �� � �������. ��� ��������� � 0���  
 }
 if (_current_direction == SELL)
 {
  // ������ ���� ���� �� ������ ���������
  return ( int( (_conbuf.GetHigh(_period,ArrayMaximum(_conbuf.GetHigh(_period).buffer,1,2)+1) - pr_ask)/_Point) + 50 );
 }
 stop_level = (int)SymbolInfoInteger(_symbol, SYMBOL_TRADE_STOPS_LEVEL);
 log_file.Write(LOG_DEBUG, StringFormat("%s ������������ �������� �� ������������� ��������� sl = %d", MakeFunctionPrefix(__FUNCTION__), stop_level));
 return stop_level;
}

int CHvostBrain::GetTakeProfit()
{
 double pr_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
 double pr_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
 if (_current_direction == BUY)
 {
  return ( int ( MathAbs(pr_ask - max_price)/_Point ) );  
 }
 if (_current_direction == SELL)
 {
  return ( int ( MathAbs(pr_bid - min_price)/_Point ) );    
 }
  log_file.Write(LOG_DEBUG, StringFormat("%s ������������ TakeProfit �� ������������� ��������� ", MakeFunctionPrefix(__FUNCTION__)));
 return (0);
}