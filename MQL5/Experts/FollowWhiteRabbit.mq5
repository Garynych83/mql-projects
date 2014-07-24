//+------------------------------------------------------------------+
//|                                            FollowWhiteRabbit.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <Trade\PositionInfo.mqh> //���������� ���������� ��� ��������� ���������� � ��������
#include <CompareDoubles.mqh>
#include <Lib CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh>
#include <TradeManager\ReplayPosition.mqh>  

#define DEFAULT_LOT 1
#define DEPTH 30
#define ADD_TO_STOPPLOSS 50
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES timeframe = PERIOD_H1;
input double supremacyPercent = 0.2;
input double profitPercent = 0.5; 
input double levelsKo = 3;
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;
input int minProfit = 250;
input int trailingStop = 150;
input int trailingStep = 5;
input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;           //��� ����������� ������                    
input int priceDifference = 50;                       // Price Difference
input bool replayPositions = true;
input int percentATRforReadyToReplay = 10;
input int percentATRforTrailing = 50;

string symbol;           //���������� ��� �������� �������
datetime history_start;

CTradeManager ctm;       //�������� �����
//ReplayPosition *rp;      //����� �������� ��������� �������
MqlTick tick;

double takeProfit, stopLoss;
double ave_atr_buf[1], close_buf[1], open_buf[1], pbi_buf[1];
ENUM_TM_POSITION_TYPE opBuy, opSell, pos_type;
CPosition *pos;            // ��������� �� �������
CisNewBar *isNewBarM1;
CisNewBar *isNewBarM5;
CisNewBar *isNewBarM15;

int handle_PBI;
int handle_aATR_M1;
int handle_aATR_M5;
int handle_aATR_M15;
int handle_19Lines;
struct bufferLevel         // ��������� �������
{
 double price[];
 double atr[];
};
bufferLevel buffers[20];   // ������ �������


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symbol=Symbol();                 //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   history_start=TimeCurrent();        //--- �������� ����� ������� �������� ��� ��������� �������� �������
   
   switch (pending_orders_type)  //���������� priceDifference
   {
    case USE_LIMIT_ORDERS: //useLimitsOrders = true;
     opBuy  = OP_BUYLIMIT;
     opSell = OP_SELLLIMIT;
    break;
    case USE_STOP_ORDERS:
     opBuy  = OP_BUYSTOP;
     opSell = OP_SELLSTOP;
    break;
    case USE_NO_ORDERS:
     opBuy  = OP_BUY;
     opSell = OP_SELL;      
    break;
   }
   
   //rp = new ReplayPosition(symbol, timeframe, percentATRforReadyToReplay, percentATRforTrailing);
   isNewBarM1  = new CisNewBar(symbol, PERIOD_M1);
   isNewBarM5  = new CisNewBar(symbol, PERIOD_M5);
   isNewBarM15 = new CisNewBar(symbol, PERIOD_M15);
   handle_PBI     = iCustom(symbol, PERIOD_M15, "PriceBasedIndicator");
   handle_aATR_M1  = iMA(symbol,  PERIOD_M1, 100, 0, MODE_EMA, iATR(symbol,  PERIOD_M1, 30));
   handle_aATR_M5  = iMA(symbol,  PERIOD_M5, 100, 0, MODE_EMA, iATR(symbol,  PERIOD_M5, 30)); 
   handle_aATR_M15 = iMA(symbol, PERIOD_M15, 100, 0, MODE_EMA, iATR(symbol, PERIOD_M15, 30));  
   handle_19Lines = iCustom(symbol, timeframe, "NineteenLines");     
   if (handle_PBI == INVALID_HANDLE || handle_19Lines == INVALID_HANDLE)
    {
     PrintFormat("%s �� ������� �������� ����� ������ �� ��������������� �����������", MakeFunctionPrefix(__FUNCTION__));
    }       
   //������������� ���������� ��� �������� ���_buf
   ArraySetAsSeries(ave_atr_buf, false);
   ArraySetAsSeries(close_buf, false);
   ArraySetAsSeries(open_buf, false);
 
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //delete rp;
   // ����������� ������������ ������� �� ������
   ArrayFree(ave_atr_buf);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ctm.OnTick();
   //if (replayPositions) rp.CustomPosition();
   //���������� ��� �������� ����������� ������ � ������� ��������
   
   if(isNewBarM1.isNewBar())
   {
    CheckHugeBar(PERIOD_M1, handle_aATR_M1);
    PrintFormat("������� ��� �� �1. ������ �������");
   }
   
   if(isNewBarM5.isNewBar())
   {
    CheckHugeBar(PERIOD_M5, handle_aATR_M5);
    PrintFormat("������� ��� �� �5. ������ �������");
   }
   
   if(isNewBarM15.isNewBar())
   {
    CheckHugeBar(PERIOD_M15, handle_aATR_M15);
    PrintFormat("������� ��� �� �15. ������ �������");
   }
 
   return;   
  }
//+------------------------------------------------------------------+
void OnTrade()
  {
   ctm.OnTrade();
   //if(replayPositions)rp.OnTrade();
   if (history_start != TimeCurrent())
   {
    //rp.setArrayToReplay(ctm.GetPositionHistory(history_start));
    history_start = TimeCurrent() + 1;
   }
  }
  
bool CheckHugeBar(ENUM_TIMEFRAMES tf, int handle_atr)
{
 int errATR = 0;                                                   
 int errHigh = 0;                                                   
 int errClose = 0;
 int errOpen = 0;
 int errPBI = 0;
   
 double sum = 0;
 double avgBar = 0;
 double lastBar = 0;
 long positionType;

 //�������� ������ �������� ������� � ������������ ������� ��� ���������� ������ � ����
 errClose = CopyClose(symbol, tf, 1, 1, close_buf);          
 errOpen  =  CopyOpen(symbol, tf, 1, 1, open_buf);
 errATR   = CopyBuffer(handle_atr, 0, 0, 1, ave_atr_buf);
 errPBI   = CopyBuffer(handle_PBI, 4, 1, 1, pbi_buf);
 Upload19LinesBuffers();
   
 if(errATR < 0 || errClose < 0 || errOpen < 0)         //���� ���� ������
 {
  Alert("�� ������� ����������� ������ �� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
  return(false);                                                             //� ������� �� �������
 }
   
 if(errPBI < 0)                                                           //���� ���� ������
 {
  Alert("�� ������� ����������� ������ �� ���������������� ����������");  //�� ������� ��������� � ��� �� ������
  return(false);                                                                 //� ������� �� �������
 }
 
 avgBar = ave_atr_buf[0];
 lastBar = MathAbs(open_buf[0] - close_buf[0]);
    
 if(GreatDoubles(lastBar, avgBar*(1 + supremacyPercent)))
 {
  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  int digits  = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  double vol=MathPow(10.0, digits); 
  if(LessDoubles(close_buf[0], open_buf[0])) // �� ��������� ���� close < open (��� ����)
  {  
   pos_type = opSell;
   stopLoss = CountStoploss(-1);
   if(pbi_buf[0] == MOVE_TYPE_TREND_UP || pbi_buf[0] == MOVE_TYPE_TREND_UP_FORBIDEN ||
      GetClosestLevel(-1) <= levelsKo*GetClosestLevel(1))
    return(false);
  }
  if(GreatDoubles(close_buf[0], open_buf[0]))
  { 
   pos_type = opBuy;
   stopLoss = CountStoploss(1);
   if(pbi_buf[0] == MOVE_TYPE_TREND_DOWN || pbi_buf[0] == MOVE_TYPE_TREND_DOWN_FORBIDEN ||
      GetClosestLevel(1) <= levelsKo*GetClosestLevel(-1))
    return(false);
  }
  takeProfit = NormalizeDouble(MathAbs(open_buf[0] - close_buf[0])*vol*(1 + profitPercent),0);
    
  ctm.OpenUniquePosition(symbol, timeframe, pos_type, DEFAULT_LOT, stopLoss, takeProfit, trailingType, minProfit, trailingStop, trailingStep, priceDifference);
 }
 ArrayInitialize(ave_atr_buf, EMPTY_VALUE);
 ArrayInitialize(  close_buf, EMPTY_VALUE);
 ArrayInitialize(   open_buf, EMPTY_VALUE);
 ArrayInitialize(    pbi_buf, EMPTY_VALUE);
 Initialize19LinesBuffers();
 return(true);
}
  
bool Upload19LinesBuffers()   // �������� ��������� �������� �������
{
 int copiedPrice;
 int copiedATR;
 
 for (int i = 0; i < 20; i++)
 {
  copiedPrice = CopyBuffer(handle_19Lines,   i*2, 0, 1, buffers[i].price);
  copiedATR   = CopyBuffer(handle_19Lines, i*2+1, 0, 1, buffers[i].atr);
  if (copiedPrice < 1 || copiedATR < 1)
  {
   Print("�� ������� ���������� ������ ���������� NineTeenLines");
   return (false);
  }
 }
 return(true);     
}

void Initialize19LinesBuffers()   // �������� ��������� �������� �������
{
 for (int i = 0; i < 20; i++)
 {
  ArrayInitialize(buffers[i].price, EMPTY_VALUE);
  ArrayInitialize(buffers[i].atr  , EMPTY_VALUE);  
 } 
}

double GetClosestLevel(int direction)  // ���������� ��������� ������� � ������� ����
{
 double cuPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
 double len = 0;  //���������� �� ���� �� ������
 double tmpLen; 

 switch (direction)
 {
  case 1:  // ������� ������
   for(int i = 0; i < 20; i++)
   {  // ���� ������� ����
    if (GreatDoubles((buffers[i].price[0]-buffers[i].atr[0]),cuPrice))
    {
     tmpLen = buffers[i].price[0] - buffers[i].atr[0] - cuPrice;
     if (tmpLen < len || len == 0)
      len = tmpLen;  
    }
   }
   break;
  case -1: // ������� �����
   for(int j = 0; j < 20; j++)
   {  // ���� ������� ����
    if ( LessDoubles((buffers[j].price[0]+buffers[j].atr[0]),cuPrice)  )
    {
     tmpLen = cuPrice - buffers[j].price[0] - buffers[j].atr[0] ;
     if (tmpLen < len || len == 0)
      len = tmpLen;
    }
   }
   break;
  }
 return (len);
}

// ������� ��������� ���� ����
int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, DEPTH);
 
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6;
  priceAB = SymbolInfoDouble(symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; // ���� point > 0 ������� ����� � ����������, ����� � �����������
  priceAB = SymbolInfoDouble(symbol, SYMBOL_BID);
  direction = -1;
 }
 
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(handle_PBI, extrBufferNumber, 0,DEPTH, bufferStopLoss);

 }
 if (copiedPBI < DEPTH)
 {
  PrintFormat("%s �� ������� ����������� ����� bufferStopLoss", MakeFunctionPrefix(__FUNCTION__));
  return(0);
 }
 
 for(int i = 0; i < DEPTH; i++)
 {
  if (bufferStopLoss[i] > 0)
  {
   if (LessDoubles(direction*bufferStopLoss[i], direction*priceAB))
   {
    PrintFormat("Last extremum %f", bufferStopLoss[i]);
    stopLoss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point());// + ADD_TO_STOPPLOSS;
    break;
   }
  }
 }
 // �� ������ ���� �������, � ������� �� �����, � �������� � �� �����
 // �������� �� ������ - ��� ���� ��������� ������ ����� �������� �����������
 // ��� ��� �����, �� �� ����� ���������, ��� stopLoss ����� ���� ������������� ������
 // ���� �������������, ��� �� ����� ������������� �� ��-�� ���� �������, �� ����� ���� �� �����
 // � ���� ������ ��� ��� ���������, ����� ������� ;) (c) DMIRTRII
 if (stopLoss <= 0)  
 {
  PrintFormat("�� ��������� ���� �� ����������");
  stopLoss = SymbolInfoInteger(symbol, SYMBOL_SPREAD) + ADD_TO_STOPPLOSS;
 }
 //PrintFormat("%s StopLoss = %d",MakeFunctionPrefix(__FUNCTION__), stopLoss);
 return(stopLoss);
}