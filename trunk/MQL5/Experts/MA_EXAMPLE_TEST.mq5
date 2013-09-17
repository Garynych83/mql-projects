//#include            <GeneticPack/MATrainLib.mqh>
//#include            <GeneticPack/MustHaveLib.mqh>
//#include            <GeneticPack/UGAlib.mqh>
//#include            <TradeBlocks/CrossEMA.mq5>
#include <GeneticPack/UGA.mqh>
input double        trainDD=0.5;   // ����������� ��������� �������� ������� � ����������
input double        maxDD=0.2;     // �������� �������, ����� ������� ���� ���������������
input uint          SlowPer=26;    // ������ ���������� EMA
input uint          FastPer=12;    // ������ �������� ���
input int           TakeProfit=100;//take profit
input int           StopLoss=100; //stop loss
input double        orderVolume = 1;
input ENUM_MA_METHOD MA_METHOD=MODE_EMA;
input ENUM_APPLIED_PRICE applied_price=PRICE_CLOSE;
string              sym = _Symbol;               //������� ������
ENUM_TIMEFRAMES     timeFrame = _Period;     
//CTradeManager       new_trade; //����� �������� 
GenOptimosator      gen_optimisator;   //������������ �����������

int OnInit()
  {
  gen_optimisator.traindd = trainDD;
  gen_optimisator.trade_block.InitTradeBlock(sym,timeFrame,FastPer,SlowPer,MA_METHOD,applied_price); //�������������� �������� ����
  gen_optimisator.tf=Period();
//--- ��� ��������� ������������...
  gen_optimisator.prevBT[0]=D'2001.01.01';
//... ����� �����
   TimeToStruct(gen_optimisator.prevBT[0],gen_optimisator.prevT);
//--- ������� ������� (������, ��� ��� ������������ �� ������������ ������)
   gen_optimisator.depth=10000;
   gen_optimisator.count=2;
   gen_optimisator.GA();
   gen_optimisator.GetTrainResults();
   gen_optimisator.InitRelDD();
   return(0);
  }

void OnDeinit(const int reason)
  {
  }
void OnTrade()
  {
  }
void OnTick()
  {
  
  gen_optimisator.signal =  gen_optimisator.trade_block.GetSignal(false); //�������� �������� ������
   
   if(gen_optimisator.signal!=OP_IMPOSSIBLE)  
     {
      bool trig=false;
      
        if (gen_optimisator.signal == OP_SELL)
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               //ClosePosition();
               gen_optimisator.new_trade.ClosePosition(0);
               trig=true;
              }
           }
        }
        if (gen_optimisator.signal == OP_BUY)
        {
         if(PositionsTotal()>0)
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               gen_optimisator.new_trade.ClosePosition(0);
               trig=true;
              }
           }
        }
        
      if(trig==true)
        {
        //--- ���� �������� ������� ��������� ����������:
         if(gen_optimisator.GetRelDD()>maxDD) 
           {
            //--- �������� ������� ������������ ����������� ���������
            gen_optimisator.GA();
            //--- �������� ���������������� ��������� ��������� � ������ ����������
            gen_optimisator.GetTrainResults();
            //--- ������ �������� ����� ������ ����� �� �� ��������� �������, � �� �������� �������
            gen_optimisator.maxBalance=AccountInfoDouble(ACCOUNT_BALANCE);
           }
        }
        gen_optimisator.signal = gen_optimisator.trade_block.GetSignal(false); 
        if(signal == OP_SELL)
        {
         gen_optimisator.request.type=ORDER_TYPE_SELL;
       //  OpenPosition();
         gen_optimisator.new_trade.OpenPosition(sym,OP_SELL,orderVolume,StopLoss,TakeProfit,0,0,0);
        }
        if(gen_optimisator.signal == OP_BUY)
        {
         gen_optimisator.request.type=ORDER_TYPE_BUY;
       //  OpenPosition();
         gen_optimisator.new_trade.OpenPosition(sym,OP_BUY,orderVolume,StopLoss,TakeProfit,0,0,0);
        }
     };
  }