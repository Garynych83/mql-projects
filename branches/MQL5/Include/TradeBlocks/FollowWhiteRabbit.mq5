#property library
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| �������� ����� Follow White Rabbit
//+------------------------------------------------------------------+
#include <TradeManager/TradeManagerEnums.mqh> 
#include <CIsNewBar.mqh>
#include <CompareDoubles.mqh>

 class FWRabbit  //����� Follow White Rabbit
  {
   private:
   //��������� ����������
   string sym;                                       //���������� ��� �������� �������
   ENUM_TIMEFRAMES timeFrame;
   double supremacyPercent;
   double profitPercent;
   MqlTick tick;
   int historyDepth;                                //������� �������
   //������
   double  high_buf[]; 
   double  low_buf[]; 
   double  close_buf[1]; 
   double  open_buf[1];
   ENUM_TM_POSITION_TYPE opBuy, opSell, pos_type;
   public:
   double takeProfit;
   int priceDifference;
   int InitTradeBlock(string _sym,
                      ENUM_TIMEFRAMES _timeFrame,
                      double _supremacyPercent,
                      double _profitPercent,
                      int _historyDepth,
                      bool useLimitOrders,
                      bool useStopOrders,
                      int limitPriceDifference,
                      int stopPriceDifference);          //�������������� �������� ����
   int DeinitTradeBlock();                                         //���������������� �������� ����
   bool UploadBuffers();                               //��������� ������ 
   ENUM_TM_POSITION_TYPE GetSignal (bool ontick);     //�������� �������� ������ 
  // FWRabbit ();   //����������� ������ Follow White Rabbit      
  };

int FWRabbit::InitTradeBlock(string _sym,
                             ENUM_TIMEFRAMES _timeFrame,
                             double _supremacyPercent,
                             double _profitPercent,
                             int _historyDepth,
                             bool useLimitOrders,
                             bool useStopOrders,
                             int limitPriceDifference,
                             int stopPriceDifference
                             )  //������������� ��������� �����
 {
   sym = _sym;                 //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   timeFrame = _timeFrame; //�������� ����� ������� �������� ��� ��������� �������� �������
   supremacyPercent =  _supremacyPercent;
   profitPercent    =  _profitPercent;
   historyDepth     =  _historyDepth;
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
   //������������� ���������� ��� �������� ���_buf
   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);
   ArraySetAsSeries(close_buf, false);
   ArraySetAsSeries(open_buf, false);  
   return(INIT_SUCCEEDED);
 }
 
int FWRabbit::DeinitTradeBlock(void)  //��������������� ��������� �����
 {
    // ����������� ������������ ������� �� ������
    ArrayFree(low_buf);
    ArrayFree(high_buf);
   return 1;
 } 
 
bool FWRabbit::UploadBuffers()    //��������� ������
 {
   int errLow = 0;                                                   
   int errHigh = 0;                                                   
   int errClose = 0;
   int errOpen = 0;
   errLow   = CopyLow(sym, timeFrame, 1, historyDepth, low_buf);
   errHigh  = CopyHigh(sym, timeFrame, 1, historyDepth, high_buf);
   errClose = CopyClose(sym, timeFrame, 1, 1, close_buf);          
   errOpen  = CopyOpen(sym, timeFrame, 1, 1, open_buf);
    if(errLow < 0 || errHigh < 0 || errClose < 0 || errOpen < 0)         //���� ���� ������
    {
     return false; //� ������� �� ������� 
    } 
  return true;
 }  

ENUM_TM_POSITION_TYPE FWRabbit::GetSignal(bool ontick)  //�������� �������� ������
 {
   double sum = 0;
   double avgBar = 0;
   double lastBar = 0;
   int i = 0;   // �������
   long positionType;
   
   static CIsNewBar isNewBar;
   
   if ( isNewBar.isNewBar(sym, timeFrame) || ontick)
      
   {
    //�������� ������ �������� ������� � ������������ ������� ��� ���������� ������ � ����
  
    if ( !UploadBuffers () )  //��������, ����������� �� ������
     return OP_UNKNOWN;
     
    for(i = 0; i < historyDepth; i++)
    {
     sum = sum + high_buf[i] - low_buf[i];  
    }
    avgBar = sum / historyDepth;

    lastBar = MathAbs(open_buf[0] - close_buf[0]);
    
    if(GreatDoubles(lastBar, avgBar*(1 + supremacyPercent)))
    {
     double point = SymbolInfoDouble(sym, SYMBOL_POINT);
     int digits   = SymbolInfoInteger(sym, SYMBOL_DIGITS);
     double vol=MathPow(10.0, digits); 
      
     if(LessDoubles(close_buf[0], open_buf[0])) // �� ��������� ���� close < open (��� ����)
     {
      takeProfit = NormalizeDouble(MathAbs(open_buf[0] - close_buf[0])*vol*(1 + profitPercent),0);
      return opSell;
     }
     if(GreatDoubles(close_buf[0], open_buf[0]))
     {   
      takeProfit = NormalizeDouble(MathAbs(open_buf[0] - close_buf[0])*vol*(1 + profitPercent),0);
      return opBuy;
     }
 
    }
    
   }
   return OP_UNKNOWN;      
 }