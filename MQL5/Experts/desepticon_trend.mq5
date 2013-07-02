//+------------------------------------------------------------------+
//|                                           fast-start-example.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
//-------------------Include----------------------------------------
#include <Trade\Trade.mqh>                                         //���������� ���������� ��� ���������� �������� ��������
#include <Trade\PositionInfo.mqh>                                  //���������� ���������� ��� ��������� ���������� � ��������
#include <CisNewBar.mqh>                                           //���������� ���������� ��� ��������� ���������� � ��������� ������ ����
#include <DesepticonTrendCriteria.mqh>                             //���������� ���������� ��� ������ ����������� ������
#include <CompareDoubles.mqh>
//-------------------Define-----------------------------------------
#define JUNIOR 0                                                   //������ �������� ���������� � ������� TrendDirection
#define ELDER  1                                                   //������ �������� ���������� � ������� TrendDirection
#define CURRENT 0                                                  //��� ��������� � �������� ����������� ������ � ������� TrendDirection
#define HISTORY 1                                                  //��� ��������� � ����������� ����������� ������ � ������� TrendDirection     
//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input int jrfastEMA = 12;
input int jrslowEMA = 26;
input int eldfastEMA = 12;
input int eldslowEMA = 26;
input int fastMACDperiod = 12;
input int slowMACDperiod = 26;
input int deltaEMAtoEMA = 0;
input int deltaPricetoEMA = 0;
input double channelJrMACD = 0.0002;
input double channelEldMACD = 0.002;
input int stoploss = 200;
input int takeprofit = 800;

//JUNIOR
int             iMA_fast_jr_handle;                                 //���������� ��� �������� ������ ����������
int             iMA_slow_jr_handle;                                 //���������� ��� �������� ������ ����������
int             iMACD_jr_handle;                                    //���������� ��� �������� ������ ����������

double          iMA_fast_jr_buf[2];                                  //������ ��� �������� �������� ����������
double          iMA_slow_jr_buf[2];                                  //������ ��� �������� �������� ����������
double          Close_jr_buf[2];                                     //������ ��� �������� ���� �������� ������� ���� �������� ��

//ELDER
int             iMA_fast_eld_handle;                                 //���������� ��� �������� ������ ����������
int             iMA_slow_eld_handle;                                 //���������� ��� �������� ������ ����������
int             iMACD_eld_handle;                                    //���������� ��� �������� ������ ����������

double          iMA_fast_eld_buf[2];                                  //������ ��� �������� �������� ����������
double          iMA_slow_eld_buf[2]; 
double          Close_eld_buf[2];                                     //������ ��� �������� ���� �������� ������� ���� �������� ��
double          Low_eld_buf[2];                                       //������ ��� �������� ����������� ��� ������� ���� �������� ��
double          High_eld_buf[2];                                      //������ ��� �������� ������������ ������� ���� �������� �� 


int             iMA_daily_handle;
double          iMA_daily_buf[1];
string          my_symbol;                                           //���������� ��� �������� �������
ENUM_TIMEFRAMES my_jr_timeframe;                                     //���������� ��� �������� �������� ����������
ENUM_TIMEFRAMES my_eld_timeframe;                                    //���������� ��� �������� �������� ����������

int             trendDirection[2][2];                                //������ �������� ����������� ������� �� ����� �����������. [TIMEFRAME][CURRENT | HISTORY]

CTrade          m_Trade;                                         //����� ��� ���������� �������� ��������
CPositionInfo   m_Position;                                      //����� ��� ��������� ���������� � ��������
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Alert("�������������.");
   my_symbol = Symbol();                  //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   my_jr_timeframe = PERIOD_M5;                                    
   my_eld_timeframe = PERIOD_H1;                                   
   iMA_fast_jr_handle  = iMA(my_symbol,  my_jr_timeframe,  jrfastEMA, 0, MODE_SMA, PRICE_CLOSE);  //���������� ��������� � �������� ��� �����
   iMA_slow_jr_handle  = iMA(my_symbol,  my_jr_timeframe,  jrslowEMA, 0, MODE_SMA, PRICE_CLOSE);  //���������� ��������� � �������� ��� �����
   iMA_fast_eld_handle = iMA(my_symbol, my_eld_timeframe, eldfastEMA, 0, MODE_SMA, PRICE_CLOSE);  //���������� ��������� � �������� ��� �����
   iMA_slow_eld_handle = iMA(my_symbol, my_eld_timeframe, eldslowEMA, 0, MODE_SMA, PRICE_CLOSE);  //���������� ��������� � �������� ��� �����
   iMA_daily_handle = iMA(my_symbol, PERIOD_D1, 3, 0, MODE_SMA, PRICE_CLOSE);
   iMACD_jr_handle  = iMACD(my_symbol,  my_jr_timeframe, fastMACDperiod, slowMACDperiod, 9, PRICE_CLOSE);
   iMACD_eld_handle = iMACD(my_symbol, my_eld_timeframe, fastMACDperiod, slowMACDperiod, 9, PRICE_CLOSE);
   if( iMA_fast_jr_handle == INVALID_HANDLE ||  iMA_slow_jr_handle == INVALID_HANDLE ||
      iMA_fast_eld_handle == INVALID_HANDLE || iMA_slow_eld_handle == INVALID_HANDLE ||
          iMACD_jr_handle == INVALID_HANDLE ||    iMACD_eld_handle == INVALID_HANDLE ||
         iMA_daily_handle == INVALID_HANDLE )
   {
      Print("�� ������� �������� ����� ����������");                     //���� ����� �� �������, �� ������� ��������� � ��� �� ������
      return(INIT_FAILED);                                               //��������� ������ � �������
   }
   //Alert(__FUNCTION__, ";JR@hMACD = ", iMACD_jr_handle, "; hF_EMA = ", iMA_fast_jr_handle, "; hS_EMA = ", iMA_slow_jr_handle);
   //Alert(__FUNCTION__, ";ELD@hMACD = ", iMACD_eld_handle, "; hF_EMA = ", iMA_fast_eld_handle, "; hS_EMA = ", iMA_slow_eld_handle);
   trendDirection[JUNIOR][CURRENT] = InitTrendDirection( iMACD_jr_handle,  iMA_fast_jr_handle,  iMA_slow_jr_handle, deltaEMAtoEMA, channelJrMACD);
   trendDirection[ELDER][CURRENT]  = InitTrendDirection(iMACD_eld_handle, iMA_fast_eld_handle, iMA_slow_eld_handle, deltaEMAtoEMA, channelEldMACD);
   
   //ChartIndicatorAdd(ChartID(),0,iMA_handle);                      //��������� ��������� �� ������� ������
   ArraySetAsSeries(iMA_fast_jr_buf,true);                           //������������� ���������� ��� ������� iMA_buf ��� � ���������
   ArraySetAsSeries(iMA_slow_jr_buf,true);                           //������������� ���������� ��� ������� iMA_buf ��� � ���������
   ArraySetAsSeries(iMA_fast_eld_buf,true);                          //������������� ���������� ��� ������� iMA_buf ��� � ���������
   ArraySetAsSeries(iMA_slow_eld_buf,true);                          //������������� ���������� ��� ������� iMA_buf ��� � ���������
   ArraySetAsSeries(Close_jr_buf,true);                              //������������� ���������� ��� ������� Close_buf ��� � ���������
   ArraySetAsSeries(Close_eld_buf,true);                             //������������� ���������� ��� ������� Close_buf ��� � ���������
   ArraySetAsSeries(iMA_daily_buf,true);                             //������������� ���������� ��� ������� iMA_buf ��� � ���������   
   return(INIT_SUCCEEDED);                                           //���������� 0, ������������� ���������
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Alert("���������������.");
   IndicatorRelease(iMA_fast_jr_handle);                              //������� ����� ���������� � ����������� ������ ���������� ��
   IndicatorRelease(iMA_slow_jr_handle);                              //������� ����� ���������� � ����������� ������ ���������� ��
   IndicatorRelease(iMA_fast_eld_handle);                             //������� ����� ���������� � ����������� ������ ���������� ��
   IndicatorRelease(iMA_slow_eld_handle);                             //������� ����� ���������� � ����������� ������ ���������� ��
   IndicatorRelease(iMACD_jr_handle);                                 //������� ����� ���������� � ����������� ������ ���������� ��
   IndicatorRelease(iMACD_eld_handle);                                //������� ����� ���������� � ����������� ������ ���������� ��
   IndicatorRelease(iMA_daily_handle);                                //������� ����� ���������� � ����������� ������ ���������� ��
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   static CIsNewBar isNewBarEld;
   static CIsNewBar isNewBarJr;
   
   if (CopyHigh(my_symbol, my_eld_timeframe, 1, 2, High_eld_buf) < 0 ||
       CopyLow (my_symbol, my_eld_timeframe, 1, 2, Low_eld_buf)  < 0 ||
       CopyClose(my_symbol,  my_jr_timeframe, 1, 2,  Close_jr_buf) < 0 ||
       CopyClose(my_symbol, my_eld_timeframe, 1, 2, Close_eld_buf) < 0 ||
       CopyBuffer(   iMA_daily_handle, 0, 0, 1,    iMA_daily_buf) < 0 ||
       CopyBuffer(iMA_fast_eld_handle, 0, 1, 2, iMA_fast_eld_buf) < 0 ||
       CopyBuffer(iMA_slow_eld_handle, 0, 1, 2, iMA_slow_eld_buf) < 0 ||  
       CopyBuffer( iMA_fast_jr_handle, 0, 1, 2,  iMA_fast_jr_buf) < 0 ||
       CopyBuffer( iMA_slow_jr_handle, 0, 1, 2,  iMA_slow_jr_buf) < 0 ) 
   {
     Print("�� ������� ����������� ������ �� ������������� ������ ��� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
     return;       
   }

//--------------------------------------
// ����� ��� �� ������� ��
//--------------------------------------   
   if(isNewBarEld.isNewBar(my_symbol, my_eld_timeframe))
   {
    trendDirection[ELDER][CURRENT] = TwoTitsCriteria(iMACD_eld_handle, iMA_fast_eld_handle, iMA_slow_eld_handle, deltaEMAtoEMA, channelEldMACD, trendDirection[ELDER][CURRENT], trendDirection[ELDER][HISTORY]);
    //��������� ������ ���������
   }
   
//--------------------------------------
// ����� ��� �� ������� ��
//--------------------------------------   
   if(isNewBarJr.isNewBar(my_symbol, my_jr_timeframe))
   {
    trendDirection[JUNIOR][CURRENT] = TwoTitsCriteria(iMACD_jr_handle, iMA_fast_jr_handle, iMA_slow_jr_handle, deltaEMAtoEMA, channelJrMACD, trendDirection[JUNIOR][CURRENT], trendDirection[JUNIOR][HISTORY]);
    if(trendDirection[JUNIOR][CURRENT] > 0) // ���� ����� ����� �� ������� ����������
    { 
     trendDirection[JUNIOR][HISTORY] = 1;
    } 
    else if(trendDirection[JUNIOR][CURRENT] < 0) // ���� ����� ���� �� ������� ����������
    {
     trendDirection[JUNIOR][HISTORY] = -1;
    }
    else if(trendDirection[JUNIOR][CURRENT] == 0) // ���� �� ������� ���� �� �������
    {
     //Alert("���� �� �������");
     return; // ��������� ��� ����� �� �����
    }
   }
   
//--------------------------------------
// ������� ����� �����
//--------------------------------------
   if(trendDirection[ELDER][CURRENT] > 0)
   {
    trendDirection[ELDER][HISTORY] = 1;
    //�������� �� ��������� �����
    if(LessDoubles(bid, iMA_daily_buf[0] + deltaPricetoEMA*point))
    {
     if(LessDoubles(Low_eld_buf[0], iMA_fast_eld_buf[0] + deltaPricetoEMA*point) &&
        LessDoubles(Low_eld_buf[1], iMA_fast_eld_buf[1] + deltaPricetoEMA*point))
     {
      if(GreatDoubles(iMA_fast_jr_buf[0], iMA_slow_jr_buf[0]) &&
          LessDoubles(iMA_fast_jr_buf[1], iMA_slow_jr_buf[1]))
      {
       if(m_Position.Select(my_symbol))                             //���� ��� ���������� ������� �� ����� �������
       {

        if(m_Position.PositionType()==POSITION_TYPE_SELL)
        {
         Alert("��������� ������� SELL. ����� �����.");
         m_Trade.PositionClose(my_symbol);  //� ��� ���� ������� Sell, �� ��������� ��
        }
        if(m_Position.PositionType()==POSITION_TYPE_BUY)  return;                            //� ���� ��� ���� ������� Buy, �� �������
       }
       Alert("��������� ������� BUY");
       //m_Trade.Buy(1, my_symbol);
       m_Trade.Buy(1, my_symbol, ask, bid-stoploss*point, ask+takeprofit*point); 
      }
     }
    }
   }
   
//--------------------------------------
// ������� ����� ����
//--------------------------------------
   if(trendDirection[ELDER][CURRENT] < 0)
   {
    trendDirection[ELDER][HISTORY] = -1;
    //�������� �� ��������� �����
    if(GreatDoubles(ask, iMA_daily_buf[0] - deltaPricetoEMA*point))
    {
     if(GreatDoubles(High_eld_buf[0], iMA_fast_eld_buf[0] - deltaPricetoEMA*point) &&
        GreatDoubles(High_eld_buf[1], iMA_fast_eld_buf[1] - deltaPricetoEMA*point))
     {
      if( LessDoubles(iMA_fast_jr_buf[0], iMA_slow_jr_buf[0]) &&
         GreatDoubles(iMA_fast_jr_buf[1], iMA_slow_jr_buf[1]))
      {
       if(m_Position.Select(my_symbol))                             //���� ��� ���������� ������� �� ����� �������
       {
        if(m_Position.PositionType()==POSITION_TYPE_BUY)  
        {
         Alert("��������� ������� BUY. ����� ����.");
         m_Trade.PositionClose(my_symbol);   //� ��� ���� ������� Buy, �� ��������� ��
        }
        if(m_Position.PositionType()==POSITION_TYPE_SELL) return;                             //� ���� ��� ���� ������� Sell, �� �������
       }
       Alert("��������� ������� SELL");
       //m_Trade.Sell(1,my_symbol);
       m_Trade.Sell(1,my_symbol, bid, ask+stoploss*point, bid-takeprofit*point);
      }
     }
    }
   }   
  }
