#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <CompareDoubles.mqh>
#include <Lib CisNewBar.mqh>
#include<TradeManager/TradeManager.mqh>

input ENUM_MA_METHOD MA_METHOD=MODE_EMA;
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;
input int      TakeProfit=100;//take profit
input int      StopLoss=100; //stop loss
input double   orderVolume = 1;
input ulong    magic = 111222;
input uint SlowPer=15;
input uint FastPer=9;

double ma_slow[];   // ������ ��� ���������� ���������� iMA 
double ma_fast[];   // ������ ��� �������� ���������� iMA
double ma_ema3[];   //������ ��� EMA(3) 
double close[];     //������ ��� Close
double point = _Point; //������ ������
datetime date_buffer[];
int ma_slow_handle;  //����� ���������� ����������
int ma_fast_handle;  //����� �������� ����������
int ma_ema3_handle;  //����� EMA(3) ����������  
int takeProfit;
int stopLoss;
uint fast_per;
uint slow_per;
string sym = _Symbol;
ENUM_TIMEFRAMES timeFrame = _Period; 
CisNewBar newCisBar; 
CTradeManager new_trade; //����� �������

int OnInit() //������� �������������
 {
 new_trade.Initialization(); //������������� 
 if (SlowPer<=FastPer || FastPer<=3)
  {
   fast_per=9;
   slow_per=15;
   Alert("�� ��������� ������ �������. �� ��������� slow=15, fast=9");
  }
 else
  {
   fast_per=FastPer;
   slow_per=SlowPer;
  } 
  ma_slow_handle=iMA(sym,timeFrame,slow_per,0,MA_METHOD,applied_price); //������������� ���������� ����������
  if(ma_slow_handle<0)
   return INIT_FAILED;
  ma_fast_handle=iMA(sym,timeFrame,fast_per,0,MA_METHOD,applied_price); //������������� �������� ����������
  if(ma_fast_handle<0)
   return INIT_FAILED;
  ma_ema3_handle=iMA(sym,timeFrame,3,0,MA_METHOD,applied_price); //������������� ���������� EMA3
  if(ma_ema3_handle<0)
   return INIT_FAILED;  
  ArraySetAsSeries(ma_fast, true); // �������� �������� � �������� �������
  ArraySetAsSeries(ma_slow, true);    
  ArraySetAsSeries(ma_ema3, true);
  ArraySetAsSeries(close, true);
  ArraySetAsSeries(date_buffer, true); 
  stopLoss = StopLoss;
  takeProfit = TakeProfit;      
  return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
  ArrayFree(ma_slow);
  ArrayFree(ma_fast);
  ArrayFree(ma_ema3);
  ArrayFree(close);
  ArrayFree(date_buffer);  
  new_trade.Deinitialization();
  }
  
void OnTick()
 { 
  new_trade.OnTick();
  if ( newCisBar.isNewBar() > 0 )
   {
   if(CopyBuffer(ma_slow_handle, 0, 1, 2, ma_slow) <= 0 || 
      CopyBuffer(ma_fast_handle, 0, 1, 2, ma_fast) <= 0 || 
      CopyBuffer(ma_ema3_handle, 0, 1, 1, ma_ema3) <= 0 ||
      CopyClose(sym, 0, 1, 1, close) <= 0 ||
      CopyTime(sym, 0, 1, 1, date_buffer) <= 0) //����������� �������
     {
     Alert("����������� ����������� ������");
     return;
     }  
   if(GreatDoubles(ma_slow[1],ma_fast[1]) && GreatDoubles(ma_fast[0],ma_slow[0]) && GreatDoubles(ma_ema3[0],close[0]))
    {      
      new_trade.OpenPosition(sym,OP_BUY,orderVolume,stopLoss,takeProfit,0,0,0);
      Print("������� ���� ������: ",date_buffer[0]);
    }
   if (GreatDoubles(ma_fast[1],ma_slow[1]) && GreatDoubles(ma_slow[0],ma_fast[0]) && GreatDoubles(close[0],ma_ema3[0])  ) 
     {
      new_trade.OpenPosition(sym,OP_SELL,orderVolume,stopLoss,takeProfit,0,0,0);
            Print("������� ���� ������: ",date_buffer[0]);
     }
   }
 }
