//+------------------------------------------------------------------+
//| ����������� ���� ��: ������������ �������                        |
//+------------------------------------------------------------------+
#include            "MATrainLib.mqh"
#include            "MustHaveLib.mqh"
//---
input double        trainDD=0.5;   // ����������� ��������� �������� ������� � ����������
input double        maxDD=0.2;     // �������� �������, ����� ������� ���� ���������������
//---
int                 MAlong,MAshort;              // ��-������
double              LongBuffer[],ShortBuffer[];  // ������������ ������
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
   ArrayResize(LongBuffer,count);
   ArrayResize(ShortBuffer,count);
   ArrayInitialize(LongBuffer,0);
   ArrayInitialize(ShortBuffer,0);
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
   if(isNewBars()==true)
     {
      bool trig=false;
      CopyBuffer(MAshort,0,0,count,ShortBuffer);
      CopyBuffer(MAlong,0,0,count,LongBuffer);
      if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
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
      if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
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
      CopyBuffer(MAshort,0,0,count,ShortBuffer);
      CopyBuffer(MAlong,0,0,count,LongBuffer);
      if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        {
         request.type=ORDER_TYPE_SELL;
         OpenPosition();
        }
      if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
        {
         request.type=ORDER_TYPE_BUY;
         OpenPosition();
        }
     };
  }
//+------------------------------------------------------------------+
