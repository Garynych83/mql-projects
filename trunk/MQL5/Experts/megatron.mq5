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
#include <PointSystem/PointSystem.mqh>            // ����� ������� �������
#include <ColoredTrend/ColoredTrendUtilities.mqh>

//-------- ������� ���������
sinput string time_string="";                                           // ��������� �����������
input ENUM_TIMEFRAMES eldTF = PERIOD_H1;
input ENUM_TIMEFRAMES jrTF = PERIOD_M5;                                

sinput string stoc_string="";                                           // ��������� Stochastic 
input int    kPeriod = 5;                                               // �-������ ����������
input int    dPeriod = 3;                                               // D-������ ����������
input int    slow  = 3;                                                 // ����������� ����������. ��������� �������� �� 1 �� 3.
input int    top_level = 80;                                            // Top-level ���������
input int    bottom_level = 20;                                         // Bottom-level ����������
input int    allow_depth_for_price_extr = 25;                           // ���������� ������� ��� ���������� ����
input int    depth_stoc = 100;                                          // ������� ������ �����������

sinput string macd_string="";                                           // ��������� MACD
input int fast_EMA_period = 12;                                         // ������� ������ EMA ��� MACD
input int slow_EMA_period = 26;                                         // ��������� ������ EMA ��� MACD
input int signal_period = 9;                                            // ������ ���������� ����� ��� MACD
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE; // ��� ����  

sinput string ema_string="";                                            // ��������� ��� EMA
input int    periodEMAfastEld = 26;                                     // ������ �������   EMA �� ������� ���������� 
input int    periodEMAfastJr = 9;                                       // ������ �������   EMA �� ������� ����������
input int    periodEMAslowJr = 15;                                      // ������ ��������� EMA �� ������� ����������

sinput string pbi_string ="";                                           // ��������� PriceBased indicator
input int    historyDepth = 2000;                                       // ������� ������� ��� �������
input int    bars=30;                                                   // ������� ������ ����������

sinput string deal_string="";                                           // ��������� ������  
input double orderVolume = 0.1;                                         // ����� ������
input int    slOrder = 100;                                             // Stop Loss
input int    tpOrder = 100;                                             // Take Profit
input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;   // ��� ����������� ������                    
input int    priceDifference = 50;                                      // Price Difference

sinput string base_string ="";                                          // ������� ��������� ������
input bool    useJrEMAExit = false;                                     // ����� �� �������� �� ���
input int     posLifeTime = 10;                                         // ����� �������� ������ � �����
input int     deltaPriceToEMA = 7;                                      // ���������� ������� ����� ����� � EMA ��� �����������
input int     deltaEMAtoEMA = 5;                                        // ����������� ������� ��� ��������� EMA
input int     waitAfterDiv = 4;                                         // �������� ������ ����� ����������� (� �����)

input        ENUM_TRAILING_TYPE  trailingType = TRAILING_TYPE_PBI;      // ��� ���������
input int    trStop = 100;                                              // Trailing Stop
input int    trStep = 100;                                              // Trailing Step
input int    minProfit = 250;                                           // Minimal Profit 

// ���������� �������� ������
sEmaParams    ema_params;          // ��������� EMA
sMacdParams   macd_params;         // ��������� MACD
sStocParams   stoc_params;         // ��������� ����������
sPbiParams    pbi_params;          // ��������� PriceBased indicator
sDealParams   deal_params;          // ��������� ������
sBaseParams   base_params;          // ������� ���������


// ���������� �������
CTradeManager  *ctm;                // ��������� �� ������ ������ TradeManager
CPointSys      *pointsys;           // ��������� �� ������ ������ ������� �������

// ���������� ��������� ����������
string symbol;                       // ���������� ��� �������� �������
ENUM_TIMEFRAMES period;              // ���������� ��� �������� ����������
ENUM_TM_POSITION_TYPE deal_type;     // ��� ���������� ������
ENUM_TM_POSITION_TYPE opBuy, opSell; // ������ �� ������� 

//+------------------------------------------------------------------+
//| ������� ���������������                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   //------- ��������� ��������� ������ 
   
   // ��������� �������� EMA
   ema_params.periodEMAfastEld            = periodEMAfastEld;
   ema_params.periodEMAfastJr             = periodEMAfastJr;
   ema_params.periodEMAslowJr             = periodEMAslowJr;
   // ��������� ��������� MACD
   macd_params.fast_EMA_period            = fast_EMA_period; 
   macd_params.signal_period              = signal_period;
   macd_params.slow_EMA_period            = slow_EMA_period;
   ///////////////////////////////////////////////////////////////
   
   // ��������� ��������� ����������
   stoc_params.allow_depth_for_price_extr = allow_depth_for_price_extr;
   stoc_params.depth                      = depth_stoc;
   stoc_params.bottom_level               = bottom_level;
   stoc_params.dPeriod                    = dPeriod;
   stoc_params.kPeriod                    = kPeriod;
   stoc_params.slow                       = slow;
   stoc_params.top_level                  = top_level;
   //////////////////////////////////////////////////////////////
   
   // ��������� ��������� ������
   deal_params.minProfit                  = minProfit;
   deal_params.orderVolume                = orderVolume;
   deal_params.slOrder                    = slOrder;
   deal_params.tpOrder                    = tpOrder;
   deal_params.trStep                     = trStep;
   deal_params.trStop                     = trStop;
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
   pointsys = new CPointSys(base_params,ema_params,macd_params,stoc_params,pbi_params);      // �������� ������ ��� ������ ������ ������� �������  
   
   // ��������� ������ � ������
   
   symbol = _Symbol;
   period = _Period;
   
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
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| ������� �����������������                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // ������� ������, ���������� ��� ������������ �������
   delete ctm;      // ������� ������ ������ �������� ����������
   delete pointsys; // ������� ������ ������ �������� �������
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();  
 // ������������ �������
 if (pointsys.GetFlatSignals() >= 2 || pointsys.GetTrendSignals() >= 2)
 {
  ctm.OpenUniquePosition(symbol,period, opBuy, orderVolume, slOrder, tpOrder, trailingType, minProfit, trStop, trStep, priceDifference);        
 }
 if (pointsys.GetFlatSignals() <= -2 || pointsys.GetTrendSignals() <= -2)
 {
  ctm.OpenUniquePosition(symbol,period, opSell, orderVolume, slOrder, tpOrder, trailingType, minProfit, trStop, trStep, priceDifference);        
 }

}