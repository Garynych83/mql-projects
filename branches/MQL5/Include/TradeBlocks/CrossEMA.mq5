//+------------------------------------------------------------------+
//|                                                     CrossEMA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property library
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManagerEnums.mqh> 
#include <Lib CisNewBar.mqh>
#include <CompareDoubles.mqh>
//+------------------------------------------------------------------+
//|��������� ������ - 16.09.2013   
//|��������� ������������ ��� ���� EMA                                  
//|�������� �����  UpdateHandle ��� �������������� ������ EMA        
//|�������� ����� �������� ������� UploadBuffers 
//|�������� ����������� ������, � ������� ���������������� �������                                     
//+------------------------------------------------------------------+ 
 enum CROSS_EMA_HANDLE //��� ������ ��� CrossEMA
  {
   SLOW_EMA=0,
   FAST_EMA=1  
  };

 class CrossEMA                                                   //����� CrossEMA
  {
   private:
   //������
   double ma_slow[];                                              //������ ��� ���������� ���������� iMA 
   double ma_fast[];                                              //������ ��� �������� ���������� iMA
   double ma_ema3[];                                              //������ ��� EMA(3) 
   double close[];                                                //������ ��� Close
   datetime date_buffer[];                                        //������ ��� ����
   //������ �����������
   int ma_slow_handle;                                            //����� ���������� ����������
   int ma_fast_handle;                                            //����� �������� ����������
   int ma_ema3_handle;                                            //����� EMA(3) ����������
   //������� �����������  
   uint fast_per;                                                 //������ �������� ����������
   uint slow_per;                                                 //������ ���������� ����������
   string sym;                                                    //������� ������
   ENUM_TIMEFRAMES timeFrame;                                     //���������
   ENUM_MA_METHOD method;                                         //
   ENUM_APPLIED_PRICE applied_price;                              //
   CisNewBar newCisBar; 
   public:
   double takeProfit;                                             //���� ������
   int priceDifference;                                           
   int InitTradeBlock(string _sym,
                      ENUM_TIMEFRAMES _timeFrame,
                      double _takeProfit,
                      uint FastPer, 
                      uint SlowPer,
                      ENUM_MA_METHOD _method,
                      ENUM_APPLIED_PRICE _applied_price);          //�������������� �������� ����
   int DeinitTradeBlock();                                         //���������������� �������� ����
   int UpdateHandle(CROSS_EMA_HANDLE handle,uint period);          //�������� ��������� ��������� EMA �� period. ���� �� �������, �� ������ false, � ��������� �� ��������
   bool UploadBuffers(uint start=1);                                           //��������� ������ 
   ENUM_TM_POSITION_TYPE GetSignal (bool ontick,uint start=1);                 //�������� �������� ������ 
  // bool UpdateParam (string sym,ENUM_TIMEFRAMES timeframe);      //��������� ��������� �������
   CrossEMA ();   //����������� ������ CrossEMA           
  };
  
  
 int CrossEMA::InitTradeBlock(string _sym,
                              ENUM_TIMEFRAMES _timeFrame,
                              double _takeProfit,
                              uint FastPer, 
                              uint SlowPer,
                              ENUM_MA_METHOD _method,
                              ENUM_APPLIED_PRICE _applied_price)   //�������������� �������� ����
  {
   
   if (SlowPer<=FastPer || FastPer<=3)
    {
     fast_per=12;
     slow_per=26;
     Print("�� ��������� ������ �������. �� ��������� slow=26, fast=12");
    }
   else
    {
     fast_per=FastPer;
     slow_per=SlowPer;
    } 
   sym             = _sym;
   timeFrame       = _timeFrame;
   method          = _method;
   applied_price   = _applied_price; 
   takeProfit      = _takeProfit;
   priceDifference = 0;
   ma_slow_handle=iMA(sym,timeFrame,slow_per,0,method,applied_price); //������������� ���������� ����������
   if(ma_slow_handle<0)
    return INIT_FAILED;
   ma_fast_handle=iMA(sym,timeFrame,fast_per,0,method,applied_price); //������������� �������� ����������
   if(ma_fast_handle<0)
    return INIT_FAILED;
   ma_ema3_handle=iMA(sym,timeFrame,3,0,method,applied_price); //������������� ���������� EMA3
   if(ma_ema3_handle<0)
    return INIT_FAILED;    
   return INIT_SUCCEEDED;
  }
  
 int CrossEMA::DeinitTradeBlock(void)  //��������������� ��������� �����
  {
   //�������� �� ������ ������� 
   ArrayFree(ma_slow);
   ArrayFree(ma_fast);
   ArrayFree(ma_ema3);
   ArrayFree(close);
   ArrayFree(date_buffer); 
   return 1;   
  }
  
 int CrossEMA::UpdateHandle(CROSS_EMA_HANDLE handle,uint period) //��������� ��������� �������
   {
    switch (handle)  //������� �� ������
     {
      case SLOW_EMA: //��������� ���������� ��������� EMA
       if (period > fast_per) 
        {
         slow_per = period;
         ma_slow_handle=iMA(sym,timeFrame,slow_per,0,method,applied_price); //������������� ���������� ����������
         if(ma_slow_handle>=0)
          return INIT_SUCCEEDED;
        }
      break;
      case FAST_EMA: //��������� ���������� ������� EMA
       if (period < slow_per && period > 3) 
        {
         fast_per = period;
         ma_fast_handle=iMA(sym,timeFrame,fast_per,0,method,applied_price); //������������� ���������� ����������
         if(ma_slow_handle>=0)
          return INIT_SUCCEEDED;
        }      
      break;
     }
     return INIT_FAILED;
   } 
   
 bool CrossEMA::UploadBuffers(uint start=1)                       //��������� ������ 
  {
     if(CopyBuffer(ma_slow_handle, 0, start, 2, ma_slow) <= 0 || 
      CopyBuffer(ma_fast_handle, 0, start, 2, ma_fast) <= 0 || 
      CopyBuffer(ma_ema3_handle, 0, start, 1, ma_ema3) <= 0 ||
      CopyClose(sym, 0, start, 1, close) <= 0 ||
      CopyTime(sym, 0, start, 1, date_buffer) <= 0) //����������� �������
      return false;
     return true;
  }  

 ENUM_TM_POSITION_TYPE CrossEMA::GetSignal(bool ontick,uint start=1)  //�������� �������� ������
  {
   if ( newCisBar.isNewBar() > 0 || ontick)
   {
   if(!UploadBuffers()) //����������� �������
     {
      return OP_UNKNOWN;  //����������� ������
     }  
   if(GreatDoubles(ma_slow[1],ma_fast[1]) && GreatDoubles(ma_fast[0],ma_slow[0]) && GreatDoubles(ma_ema3[0],close[0]))
    {      
      return OP_BUY;  //������� ������ �� �������
    }
   if (GreatDoubles(ma_fast[1],ma_slow[1]) && GreatDoubles(ma_slow[0],ma_fast[0]) && GreatDoubles(close[0],ma_ema3[0])  ) 
    {
      return OP_SELL; //������� ������ �� �������
    }
   }
   return OP_UNKNOWN; //������� ������������ �������
  } 
  
  CrossEMA::CrossEMA(void)  //����������� ������ CrossEMA
   {
    ArraySetAsSeries(ma_fast, true); // �������� �������� � �������� �������
    ArraySetAsSeries(ma_slow, true);     
   }