//+------------------------------------------------------------------+
//| ����������� ���� ��: ������������ �������                        |
//+------------------------------------------------------------------+


#include            <UGA\MATrainLib.mqh>
#include            <UGA\MustHaveLib.mqh>
#include            <TradeManager/TradeManager.mqh>

//---
input double        trainDD=0.5;   // ����������� ��������� �������� ������� � ����������
input double        maxDD=0.2;     // �������� �������, ����� ������� ���� ���������������
input uint          SlowPer=26;    // ������ ���������� EMA
input uint          FastPer=12;    // ������ �������� ���
input int           TakeProfit=100;//take profit
input int           StopLoss=100; //stop loss
input double        orderVolume = 1;
input ENUM_MA_METHOD MA_METHOD=MODE_EMA;
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;
//---
int                 MAlong,MAshort;              // ��-������
double              LongBuffer[],ShortBuffer[];  // ������������ ������
string              sym = _Symbol;               //������� ������
ENUM_TIMEFRAMES     timeFrame = _Period;     
CTradeManager       new_trade; //����� �������� 



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   tf=Period();
//--- ��� ��������� ������������...
   prevBT[0]=D'2001.01.01';
//... ����� �����
   TimeToStruct(prevBT[0],prevT);
//--- ������� ������� (������, ��� ��� ������������ �� ������������ ������)
   depth=10000;
//--- ������� �� ��� �������� (������, ��� ��� ������������ �� ������������ ������)
   count=2;
   traindd = trainDD;    
   
  // ArrayResize(LongBuffer,count);
  // ArrayResize(ShortBuffer,count);
  // ArrayInitialize(LongBuffer,0);
  // ArrayInitialize(ShortBuffer,0);
   
  trade.InitTradeBlock(_Symbol,timeFrame,FastPer,SlowPer,MA_METHOD,applied_price);  //�������������� �������� ����
      
//--- �������� ������� ������������ ����������� ���������
   GA();
//--- �������� ���������������� ��������� ��������� � ������ ����������
   GetTrainResults();
//--- �������� �������� �� �������
   InitRelDD();
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    trade.DeinitTradeBlock();   //������� �� ������ ������ ������ CrossEMA
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

      bool trig=false;
      new_trade.OnTick();
      my_signal =  trade.GetSignal(false); //�������� �������� ������
      
      if (my_signal != OP_UNKNOWN)      //���� ������ ������� �������
       {
        new_trade.OpenPosition(sym,my_signal,orderVolume,StopLoss,TakeProfit,0,0,0); //�� ��������� �������      
        trig=true;
       }
       
       /*
        if(my_signal == OP_SELL)
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               ClosePosition();
               trig=true;
              }
           }
        }
        if (my_signal == OP_BUY)
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               ClosePosition();
               trig=true;
              }
           }
        } */
        
        
      if(trig==true)
        {
        //--- ���� �������� ������� ��������� ����������:
         if(GetRelDD()>maxDD) 
           {
            //--- �������� ������� ������������ ����������� ���������
            GA();
            //--- �������� ���������������� ��������� ��������� � ������ ����������
            GetTrainResults();
            //--- ������ �������� ����� ������ ����� �� �� ��������� �������, � �� �������� �������
            maxBalance=AccountInfoDouble(ACCOUNT_BALANCE);
           }
        }
      my_signal = trade.GetSignal(false); //�������� �������� ������
      if (my_signal != OP_UNKNOWN)      //���� ������ ������� �������
       new_trade.OpenPosition(sym,my_signal,orderVolume,StopLoss,TakeProfit,0,0,0); //�� ��������� �������      
      
     
  }
//+------------------------------------------------------------------+
