//+------------------------------------------------------------------+
//|                                                       Condom.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <CompareDoubles.mqh>
#include <TradeManager/TradeManagerEnums.mqh> 
#include <TradeManager/TradeManager.mqh> 
#include <Lib CisNewBar.mqh>

//+------------------------------------------------------------------+
//| �������� ����� Condom                                            |
//+------------------------------------------------------------------+

 class Condom //�������� ����� Condom
  {
    private:
     //��������� ���������
     bool waitForSell;
     bool waitForBuy;
     bool tradeOnTrend;
     double globalMax;
     double globalMin;  
     int historyDepth;                       //������� �������
     string sym;                             //���������� ��� �������� �������
     ENUM_TIMEFRAMES timeFrame;              //���������
     MqlTick tick;   
     ENUM_TM_POSITION_TYPE opBuy,opSell;               //�������� ������� 
     //��������� MACD
     int handleMACD;
     double MACD_buf[1], high_buf[], low_buf[], close_buf[2];   //������      
     int fastMACDPeriod;     //������ �������� MACD
     int slowMACDPeriod;     //������ ���������� MACD
     int signalPeriod;
     double levelMACD;     
    public:
     double takeProfit;
     int priceDifference;   
     //------------------
     int InitTradeBlock(string _sym,
                        ENUM_TIMEFRAMES _timeFrame,
                        double _takeProfit,
                        bool   _tradeOnTrend,                        
                        int    _fastMACDPeriod,
                        int _slowMACDPeriod,
                        int _signalPeriod,
                        double _levelMACD,
                        int _historyDepth,
                        bool useLimitOrders,
                        bool useStopOrders,
                        int limitPriceDifference,
                        int stopPriceDifference);       //����� ������������� ��������� �����
     int DeinitTradeBlock();                             //����� ��������������� ��������� �����
     bool UploadBuffers();                               //��������� ������ 
     ENUM_TM_POSITION_TYPE GetSignal (bool ontick);      //�������� �������� ������     
       
  };
  
 int Condom::InitTradeBlock(string _sym,
                        ENUM_TIMEFRAMES _timeFrame,
                        double _takeProfit,
                        bool   _tradeOnTrend,
                        int    _fastMACDPeriod,
                        int _slowMACDPeriod,
                        int _signalPeriod,    
                        double _levelMACD,                    
                        int _historyDepth,
                        bool useLimitOrders,
                        bool useStopOrders,
                        int limitPriceDifference,
                        int stopPriceDifference)
   {
    sym          = _sym;
    timeFrame    = _timeFrame;
   // isNewBar.SetSymbol(sym);
   // isNewBar.SetPeriod(timeFrame);
    tradeOnTrend = _tradeOnTrend;   
    historyDepth = _historyDepth; 
    takeProfit   = _takeProfit;
    if (tradeOnTrend)
    {
     fastMACDPeriod = _fastMACDPeriod;     //������ �������� MACD
     slowMACDPeriod = _slowMACDPeriod;     //������ ���������� MACD
     signalPeriod   = _signalPeriod;       //������ �������
     levelMACD      = _levelMACD;          //������� MACD
     handleMACD = iMACD(sym, timeFrame, fastMACDPeriod, slowMACDPeriod, signalPeriod, PRICE_CLOSE);  //���������� ��������� � �������� ��� �����
     if(handleMACD == INVALID_HANDLE)                                  //��������� ������� ������ ����������
      {
       Print("�� ������� �������� ����� MACD");               //���� ����� �� �������, �� ������� ��������� � ��� �� ������
       return(-1);                                                  //��������� ������ � �������
      }      
     } 
   if (useLimitOrders)
   {
    opBuy = OP_BUYLIMIT;
    opSell = OP_SELLLIMIT;
    priceDifference = limitPriceDifference;
   }
   else if (useStopOrders)
        {
         opBuy = OP_BUYSTOP;
         opSell = OP_SELLSTOP;
         priceDifference = stopPriceDifference;
        }
        else
        {
         opBuy = OP_BUY;
         opSell = OP_SELL;
         priceDifference = 0;
        }
         
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);

   globalMax = 0;
   globalMin = 0;
   waitForSell = false;
   waitForBuy = false;
   
   return(0);      
    }
    
  int  Condom::DeinitTradeBlock(void)  //��������������� ��������� ����� Condom
    {
     //������������ �������
     ArrayFree(low_buf);
     ArrayFree(high_buf);
     return 1;
    } 
    
  bool Condom::UploadBuffers(void)     //��������� ������ 
   {
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errMACD = 0;
   if (tradeOnTrend)
    {
     //�������� ������ �� ������������� ������� � ������������ ������ MACD_buf ��� ���������� ������ � ����
     errMACD=CopyBuffer(handleMACD, 0, 1, 1, MACD_buf);
     if(errMACD < 0)
     {
      Alert("�� ������� ����������� ������ �� ������������� ������"); 
      return false; 
     }
    } 
    //�������� ������ �������� ������� � ������������ ������� ��� ���������� ������ � ����
    errLow=CopyLow(sym, timeFrame, 2, historyDepth, low_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
    errHigh=CopyHigh(sym, timeFrame, 2, historyDepth, high_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
    errClose=CopyClose(sym, timeFrame, 1, 2, close_buf); // (0 - ���. ���, �������� 2 �����. ����)
             
    if(errLow < 0 || errHigh < 0 || errClose < 0)                         //���� ���� ������
    {
     Alert("�� ������� ����������� ������ �� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
     return false;                                                                  //� ������� �� �������
    }  
    return true;
   }
    
  ENUM_TM_POSITION_TYPE Condom::GetSignal(bool ontick)  //�������� �������� ������
   {
   CisNewBar isNewBar(sym, timeFrame);
    ENUM_TM_POSITION_TYPE order_type = OP_UNKNOWN;
     if(isNewBar.isNewBar() > 0)
       {       
       if (!UploadBuffers()) //���� ������ �� ������� �����������
        return OP_UNKNOWN;
       
        globalMax = high_buf[ArrayMaximum(high_buf)];
        globalMin = low_buf[ArrayMinimum(low_buf)];
    
        if(LessDoubles(close_buf[1], globalMin)) // ��������� Close(0 - ������, 1 - ������, �.� �� ��� � ���������) ���� ����������� ��������
         {
          waitForSell = false;
          waitForBuy = true;
         }
        if(GreatDoubles(close_buf[1], globalMax)) // ��������� Close(0 - ������, 1 - ������, �.� �� ��� � ���������) ���� ����������� ���������
         {
          waitForBuy = false;
          waitForSell = true;
         } 
      }
        if(tradeOnTrend)
          {
           if(GreatDoubles(MACD_buf[0], levelMACD) || LessDoubles (MACD_buf[0], -levelMACD))
             {
              return OP_UNKNOWN;
             }
          } 
         if(!SymbolInfoTick(sym,tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
    return OP_UNKNOWN;
   }
      
   if (waitForBuy)
   { 
    if (GreatDoubles(tick.ask, close_buf[0]) && GreatDoubles(tick.ask, close_buf[1]))
    {
      waitForBuy = false;
      waitForSell = false;
      order_type = opBuy;    
    }
   } 

   if (waitForSell)
   { 
    if (LessDoubles(tick.bid, close_buf[0]) && LessDoubles(tick.bid, close_buf[1]))
    {
      waitForBuy = false;
      waitForSell = false;   
      order_type = opSell;        
    }
   }  
      
      return order_type;
   }