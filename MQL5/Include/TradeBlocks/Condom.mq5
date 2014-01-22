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
//#include <TradeManager/TradeManager.mqh> 
#include <Lib CisNewBar.mqh>
#include <ColoredTrend\ColoredTrendUtilities.mqh> //��������� ����������� ������


//+------------------------------------------------------------------+
//| �������� ����� Condom                                            |
//+------------------------------------------------------------------+

 class Condom //�������� ����� Condom
  {
    private:
     //��������� ���������
     bool _waitForSell;                       //���� �������� �������
     bool _waitForBuy;                        //���� ��������� ��������
     bool _tradeOnTrend;                      //���� �������� �� ������
     double _globalMax;                       //��������
     double _globalMin;                       //�������
     int _historyDepth;                       //������� �������
     string _sym;                             //���������� ��� �������� �������
     ENUM_TIMEFRAMES _timeFrame;              //���������
     MqlTick _tick;                           //���
     //��������� Price Based Indicator 
     int _handle_PBI;                         //����� Price Based Indicator
     double PBI_buf[1],                       //����� Price Based Indicator
            high_buf[],                       //����� ������� ���
            low_buf[],                        //����� ������ ���
            close_buf[2];                     //����� ��� ��������      
     double _takeProfit;     
    public:
     double GetTakeProfit() { return (_takeProfit); }; //�������� �������� ���� �������
     int InitTradeBlock(string sym,
                        ENUM_TIMEFRAMES timeFrame,
                        bool   tradeOnTrend,                        
                        int historyDepth);       //����� ������������� ��������� �����
     int DeinitTradeBlock();                             //����� ��������������� ��������� �����
     bool UploadBuffers();                               //��������� ������ 
     short GetSignal (bool ontick);      //�������� �������� ������     
       
  };
  
    int Condom::InitTradeBlock             (string sym,   //����������� ������
                        ENUM_TIMEFRAMES timeFrame,
                        bool   tradeOnTrend,                  
                        int historyDepth)
   {
    _sym          = sym;
    _timeFrame    = timeFrame;
    
    _tradeOnTrend = tradeOnTrend;   
    _historyDepth = historyDepth; 

    if (_tradeOnTrend)
    {
     _handle_PBI = iCustom(_sym,_timeFrame,"PriceBasedIndicator",4,_historyDepth,false);  //���������� ��������� � �������� ��� �����
     if(_handle_PBI == INVALID_HANDLE)                                  //��������� ������� ������ ����������
      {
       Print("�� ������� �������� ����� Price Based Indicator");               //���� ����� �� �������, �� ������� ��������� � ��� �� ������                                                //��������� ������ � �������
      }      
     } 

   ArraySetAsSeries(low_buf, false);
   ArraySetAsSeries(high_buf, false);

   _globalMax = 0;
   _globalMin = 0;
   _waitForSell = false;
   _waitForBuy = false;
   return(INIT_SUCCEEDED);
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
   int errPBI = 0;
   if (_tradeOnTrend)
    {
     //�������� ������ �� ������������� ������� � ������������ ������ MACD_buf ��� ���������� ������ � ����
     errPBI = CopyBuffer(_handle_PBI, 4, 1, 1, PBI_buf);
     if(errPBI < 0)
     {
      Alert("�� ������� ����������� ������ �� ������������� ������"); 
      return false; 
     }
    } 
    //�������� ������ �������� ������� � ������������ ������� ��� ���������� ������ � ����
    errLow=CopyLow(_sym, _timeFrame, 2, _historyDepth, low_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
    errHigh=CopyHigh(_sym, _timeFrame, 2, _historyDepth, high_buf); // (0 - ���. ���, 1 - ����. �����. 2 - �������� �����.)
    errClose=CopyClose(_sym, _timeFrame, 1, 2, close_buf); // (0 - ���. ���, �������� 2 �����. ����)
             
    if(errLow < 0 || errHigh < 0 || errClose < 0)                         //���� ���� ������
    {
     Alert("�� ������� ����������� ������ �� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
     return false;                                                                  //� ������� �� �������
    }  
    return true;
   }
    
  short Condom::GetSignal(bool ontick)  //�������� �������� ������
   {
   CisNewBar isNewBar(_sym, _timeFrame);
    ENUM_TM_POSITION_TYPE order_type = OP_UNKNOWN;
     if(isNewBar.isNewBar() > 0)
       {       
       if (!UploadBuffers()) //���� ������ �� ������� �����������
        return 0; //����������� ������
       
        _globalMax = high_buf[ArrayMaximum(high_buf)];
        _globalMin = low_buf[ArrayMinimum(low_buf)];
    
        if(LessDoubles(close_buf[1], _globalMin)) // ��������� Close(0 - ������, 1 - ������, �.� �� ��� � ���������) ���� ����������� ��������
         {
          _waitForSell = false;
          _waitForBuy = true;
         }
        if(GreatDoubles(close_buf[1], _globalMax)) // ��������� Close(0 - ������, 1 - ������, �.� �� ��� � ���������) ���� ����������� ���������
         {
          _waitForBuy = false;
          _waitForSell = true;
         } 
      }
        if(_tradeOnTrend)
          {
            if (PBI_buf[0]==MOVE_TYPE_TREND_DOWN || 
                PBI_buf[0]==MOVE_TYPE_TREND_UP)
             {
              return 0; //����������� ������
             }
          } 
         if(!SymbolInfoTick(_sym,_tick))
   {
    Alert("SymbolInfoTick() failed, error = ",GetLastError());
    return 0; //����������� ������
   }
      
   if (_waitForBuy)
   { 
    if (GreatDoubles(_tick.ask, close_buf[0]) && GreatDoubles(_tick.ask, close_buf[1]))
    {
      _waitForBuy  = false;
      _waitForSell = false;
       order_type  = 1;  //BUY
    }
   } 

   if (_waitForSell)
   { 
    if (LessDoubles(_tick.bid, close_buf[0]) && LessDoubles(_tick.bid, close_buf[1]))
    {
      _waitForBuy  = false;
      _waitForSell = false;   
       order_type  = 2;   //SELL
    }
   }  
      
      return order_type;
   }