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

 class CrossEMA                                                 //����� CrossEMA
  {
   private:
   //������
   double ma_slow[];                                               //������ ��� ���������� ���������� iMA 
   double ma_fast[];                                               //������ ��� �������� ���������� iMA
   double ma_ema3[];                                               //������ ��� EMA(3) 
   double close[];                                                 //������ ��� Close
   datetime date_buffer[];                                         //������ ��� ����
   //������ �����������
   int _ma_slow_handle;                                            //����� ���������� ����������
   int _ma_fast_handle;                                            //����� �������� ����������
   int _ma_ema3_handle;                                            //����� EMA(3) ����������
   //������� �����������  
   uint _fast_per;                                                 //������ �������� ����������
   uint _slow_per;                                                 //������ ���������� ����������
   string _sym;                                                    //������� ������
   ENUM_TIMEFRAMES _timeFrame;                                     //���������
   ENUM_MA_METHOD _method;                                         //����� EMA
   ENUM_APPLIED_PRICE _applied_price;                              //����������� ����
   CisNewBar _newCisBar;                                           //��� �������� ������������ ������ ����
   double  _takeProfit;                                            //���� ������
   public:                  
   double GetTakeProfit() { return (_takeProfit); };               //�������� �������� ���� �������                 
   int InitTradeBlock(string sym,
                      ENUM_TIMEFRAMES timeFrame,   
                      uint FastPer, 
                      uint SlowPer,
                      ENUM_MA_METHOD method,
                      ENUM_APPLIED_PRICE applied_price);           //�������������� �������� ����
   int DeinitTradeBlock();                                         //���������������� �������� ����
   int UpdateHandle(CROSS_EMA_HANDLE handle,uint period);          //�������� ��������� ��������� EMA �� period. ���� �� �������, �� ������ false, � ��������� �� ��������
   bool UploadBuffers(uint start=1);                               //��������� ������ 
   ENUM_TM_POSITION_TYPE GetSignal (bool ontick,uint start=1);     //�������� �������� ������ 
   CrossEMA ();   //����������� ������ CrossEMA           
  };
  
  
 int CrossEMA::InitTradeBlock(string sym,
                              ENUM_TIMEFRAMES timeFrame,
                              uint FastPer, 
                              uint SlowPer,
                              ENUM_MA_METHOD method,
                              ENUM_APPLIED_PRICE applied_price)   //�������������� �������� ����
  {
   
   if (SlowPer<=FastPer || FastPer<=3)
    {
     _fast_per=12;
     _slow_per=26;
     Print("�� ��������� ������ �������. �� ��������� slow=26, fast=12");
    }
   else
    {
     _fast_per=FastPer;
     _slow_per=SlowPer;
    } 
   _sym             = sym;
   _timeFrame       = timeFrame;
   _method          = method;
   _applied_price   = applied_price; 
   _ma_slow_handle=iMA(_sym,_timeFrame,_slow_per,0,_method,_applied_price); //������������� ���������� ����������
   if(_ma_slow_handle<0)
    return INIT_FAILED;
   _ma_fast_handle=iMA(_sym,_timeFrame,_fast_per,0,_method,_applied_price); //������������� �������� ����������
   if(_ma_fast_handle<0)
    return INIT_FAILED;
   _ma_ema3_handle=iMA(_sym,_timeFrame,3,0,_method,_applied_price); //������������� ���������� EMA3
   if(_ma_ema3_handle<0)
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
       if (period > _fast_per) 
        {
         _slow_per = period;
         _ma_slow_handle=iMA(_sym,_timeFrame,_slow_per,0,_method,_applied_price); //������������� ���������� ����������
         if(_ma_slow_handle>=0)
          return INIT_SUCCEEDED;
        }
      break;
      case FAST_EMA: //��������� ���������� ������� EMA
       if (period < _slow_per && period > 3) 
        {
         _fast_per = period;
         _ma_fast_handle=iMA(_sym,_timeFrame,_fast_per,0,_method,_applied_price); //������������� ���������� ����������
         if(_ma_slow_handle>=0)
          return INIT_SUCCEEDED;
        }      
      break;
     }
     return INIT_FAILED;
   } 
   
 bool CrossEMA::UploadBuffers(uint start=1)                       //��������� ������ 
  {
     if(CopyBuffer(_ma_slow_handle, 0, start, 2, ma_slow) <= 0 || 
      CopyBuffer(_ma_fast_handle, 0, start, 2, ma_fast) <= 0 || 
      CopyBuffer(_ma_ema3_handle, 0, start, 1, ma_ema3) <= 0 ||
      CopyClose(_sym, 0, start, 1, close) <= 0 ||
      CopyTime(_sym, 0, start, 1, date_buffer) <= 0) //����������� �������
      return false;
     return true;
  }  

 ENUM_TM_POSITION_TYPE CrossEMA::GetSignal(bool ontick,uint start=1)  //�������� �������� ������
  {
   if ( _newCisBar.isNewBar() > 0 || ontick)
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