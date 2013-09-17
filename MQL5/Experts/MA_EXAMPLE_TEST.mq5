//+------------------------------------------------------------------+
//| ����������� ���� ��: ������������ �������                        |
//+------------------------------------------------------------------+
#include            <GeneticPack/MATrainLib.mqh>
#include            <GeneticPack/MustHaveLib.mqh>
#include            <GeneticPack/UGAlib.mqh>
#include            <TradeBlocks/CrossEMA.mq5>
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
//int                 MAlong,MAshort;              // ��-������
//double              LongBuffer[],ShortBuffer[];  // ������������ ������
string              sym = _Symbol;               //������� ������
ENUM_TIMEFRAMES     timeFrame = _Period;     
CTradeManager       new_trade; //����� �������� 

//---

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  traindd = trainDD;
  trade_block.InitTradeBlock(sym,timeFrame,FastPer,SlowPer,MA_METHOD,applied_price); //�������������� �������� ����
   tf=Period();
//--- ��� ��������� ������������...
   prevBT[0]=D'2001.01.01';
//... ����� �����
   TimeToStruct(prevBT[0],prevT);
//--- ������� ������� (������, ��� ��� ������������ �� ������������ ������)
   depth=10000;
//--- ������� �� ��� �������� (������, ��� ��� ������������ �� ������������ ������)
   count=2;
   //ArrayResize(LongBuffer,count);
   //ArrayResize(ShortBuffer,count);
   //ArrayInitialize(LongBuffer,0);
   //ArrayInitialize(ShortBuffer,0);
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
  
  signal =  trade_block.GetSignal(false); //�������� �������� ������
   
   if(signal!=OP_IMPOSSIBLE)  
     {
      bool trig=false;
    //  CopyBuffer(MAshort,0,0,count,ShortBuffer);
    //  CopyBuffer(MAlong,0,0,count,LongBuffer);
      //if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        if (signal == OP_SELL)
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
    //  if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
        if (signal == OP_BUY)
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               ClosePosition();
               trig=true;
              }
           }
        }
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
     // CopyBuffer(MAshort,0,0,count,ShortBuffer);
     // CopyBuffer(MAlong,0,0,count,LongBuffer);
      trade_block.GetSignal(false); 
      //if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        if(signal == OP_SELL)
        {
         request.type=ORDER_TYPE_SELL;
         OpenPosition();
        }
    //  if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
        if(signal == OP_BUY)
        {
         request.type=ORDER_TYPE_BUY;
         OpenPosition();
        }
     };
  }
//+------------------------------------------------------------------+
