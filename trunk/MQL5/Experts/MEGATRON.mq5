//+------------------------------------------------------------------+
//|                                                     MEGATRON.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ������� �������� - ������������ ����������                       |
//+------------------------------------------------------------------+

//-------- ����������� ���������

#include <Lib CisNewBar.mqh>                // ��� �������� ������������ ������ ����
#include <TradeManager/TradeManager.mqh>    // �������� ����������
#include <POINTSYS/POINTSYS.mqh>            // ����� ������� �������

//-------- ������� ���������

// ��������� �����������
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;                                

//��������� Stochastic 
input int    kPeriod = 5;                                              // �-������ ����������
input int    dPeriod = 3;                                              // D-������ ����������
input int    slow  = 3;                                                // ����������� ����������. ��������� �������� �� 1 �� 3.
input int    top_level = 80;                                           // Top-level ���������
input int    bottom_level = 20;                                        // Bottom-level ����������
input int    DEPTH = 100;                                              // ������� ������ �����������
input int    ALLOW_DEPTH_FOR_PRICE_EXTR = 25;                          // ���������� ������� ��� ���������� ����

//��������� MACD
input int fast_EMA_period = 12;                                        // ������� ������ EMA ��� MACD
input int slow_EMA_period = 26;                                        // ��������� ������ EMA ��� MACD
input int signal_period = 9;                                           // ������ ���������� ����� ��� MACD

//��������� ��� EMA
input int    periodEMAfastJr = 15;                                     // ������ �������   EMA
input int    periodEMAslowJr = 9;                                      // ������ ��������� EMA

//��������� ������  
input double orderVolume = 0.1;                                        // ����� ������
input int    slOrder = 100;                                            // Stop Loss
input int    tpOrder = 100;                                            // Take Profit
input int    trStop = 100;                                             // Trailing Stop
input int    trStep = 100;                                             // Trailing Step
input int    minProfit = 250;                                          // Minimal Profit 
input bool   useLimitOrders = false;                                   // ������������ Limit ������
input int    limitPriceDifference = 50;                                // ������� ��� Limit �������
input bool   useStopOrders = false;                                    // ������������ Stop ������
input int    stopPriceDifference = 50;                                 // ������� ��� Stop �������

input        ENUM_TRAILING_TYPE  trailingType = TRAILING_TYPE_USUAL;   // ��� ���������
input bool   useJrEMAExit = false;                                     // ����� �� �������� �� ���
input int    posLifeTime = 10;                                         // ����� �������� ������ � �����
input int    deltaPriceToEMA = 7;                                      // ���������� ������� ����� ����� � EMA ��� �����������
input int    deltaEMAtoEMA = 5;                                        // ����������� ������� ��� ��������� EMA
input int    waitAfterDiv = 4;                                         // �������� ������ ����� ����������� (� �����)
//��������� PriceBased indicator
input int    historyDepth = 40;                                        // ������� ������� ��� �������
input int    bars=30;                                                  // ������� ������ ����������

// ���������� �������� ������

EMA_PARAMS    ema_params;     // ��������� EMA
MACD_PARAMS   macd_params;    // ��������� MACD
STOC_PARAMS   stoc_params;    // ��������� ����������
PBI_PARAMS    pbi_params;     // ��������� PriceBased indicator
DEAL_PARAMS   deal_params;    // ��������� ������
BASE_PARAMS   base_params;    // ������� ���������


// ���������� �������

CTradeManager *ctm;          // ��������� �� ������ ������ TradeManager
POINTSYS      *pointsys;     // ��������� �� ������ ������ ������� �������


//+------------------------------------------------------------------+
//| ������� ���������������                                          |
//+------------------------------------------------------------------+
int OnInit()
  {

   //------- ��������� ��������� ������ 
   
   // ��������� �������� EMA
   ema_params.periodEMAfastJr             = periodEMAfastJr;
   ema_params.periodEMAslowJr             = periodEMAslowJr;
   // ��������� ��������� MACD
   macd_params.fast_EMA_period            = fast_EMA_period; 
   macd_params.signal_period              = signal_period;
   macd_params.slow_EMA_period            = slow_EMA_period;
   ///////////////////////////////////////////////////////////////
   
   // ��������� ��������� ����������
   stoc_params.ALLOW_DEPTH_FOR_PRICE_EXTR = ALLOW_DEPTH_FOR_PRICE_EXTR;
   stoc_params.DEPTH                      = DEPTH;
   stoc_params.bottom_level               = bottom_level;
   stoc_params.dPeriod                    = dPeriod;
   stoc_params.kPeriod                    = kPeriod;
   stoc_params.slow                       = slow;
   stoc_params.top_level                  = top_level;
   //////////////////////////////////////////////////////////////
   
   // ��������� ��������� PriceBased indicator
   pbi_params.bars                        = bars;
   pbi_params.historyDepth                = historyDepth;
   //////////////////////////////////////////////////////////////
   
   // ��������� ��������� ������
   deal_params.limitPriceDifference       = limitPriceDifference;
   deal_params.minProfit                  = minProfit;
   deal_params.orderVolume                = orderVolume;
   deal_params.slOrder                    = slOrder;
   deal_params.stopPriceDifference        = stopPriceDifference;
   deal_params.tpOrder                    = tpOrder;
   deal_params.trStep                     = trStep;
   deal_params.trStop                     = trStop;
   deal_params.useLimitOrders             = useLimitOrders;
   deal_params.useStopOrders              = useStopOrders;
   //////////////////////////////////////////////////////////////
   
   // ��������� ������� ���������
   base_params.deltaEMAtoEMA              = deltaEMAtoEMA;
   base_params.deltaPriceToEMA            = deltaPriceToEMA;
   base_params.eldTF                      = eldTF;
   base_params.jrTF                       = jrTF;
   base_params.posLifeTime                = posLifeTime;
   base_params.useJrEMAExit               = useJrEMAExit;
   base_params.waitAfterDiv               = waitAfterDiv;
   //------- �������� ������ ��� ������������ �������
   ctm      = new CTradeManager(); // �������� ������ ��� ������ ������ TradeManager
   pointsys = new POINTSYS(deal_params,base_params,ema_params,macd_params,stoc_params,pbi_params);      // �������� ������ ��� ������ ������ ������� �������  
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| ������� �����������������                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // ������� ������, ���������� ��� ������������ �������
   delete ctm;      // ������� ������ ������ �������� ����������
   delete pointsys; // ������� ������ ������ �����������
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
int count_bars = 0;

void OnTick()
  {
   // ������� �������� ������
   if ( pointsys.UpLoad() == true )
    {
      // ��������� ������� ������� �������� 
      switch ( pointsys.GetMovingType() )
       {
        case MOVE_TYPE_CORRECTION_UP:          // �� ���������
        case MOVE_TYPE_CORRECTION_DOWN:
        
        break;
        case MOVE_TYPE_FLAT:                   // �� �����
        
        break;
        case MOVE_TYPE_TREND_DOWN:            // �� ������
        case MOVE_TYPE_TREND_DOWN_FORBIDEN:
        case MOVE_TYPE_TREND_UP:
        case MOVE_TYPE_TREND_UP_FORBIDEN:
        
        break;
       }
    } 
  }