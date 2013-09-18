//+------------------------------------------------------------------+
//|                                                      MATrain.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <cUGA/CTrainLib.mqh>  //���������� ����� CTrainLib ��� ������������
#include <TradeBlocks/CrossEMA.mq5>  //���������� ���������� ��� ������ � CrossEMA
//+------------------------------------------------------------------+
//| ����� MATrain                                                    |
//+------------------------------------------------------------------+
 class MATrain: public CTrainBlock
  {
   private:
    CrossEMA  trade_block;                   // �������� ���� CrossEMA
   public: 
    void   GetTrainResults();                // ��������� ���������������� ���������� 
    void   FitnessFunction(int chromos);     //������ �������
    MATrain ();                              //����������� ������
  };
  
  void MATrain::GetTrainResults(void)   //��������� ���������������� ���������� 
   { 
 //--- ������������� ����� ����� �������� ����� � ��������������� �����������
   int z;
 //  MAshort=iMA(s,tf,(int)MathRound(Chromosome[1]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
 //  MAlong =iMA(s,tf,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
   
   trade_block.UpdateHandle(FAST_EMA,(int)MathRound(uGA.Chromosome[1]*MaxMAPeriod)+1);   //������ ������ �����������
   trade_block.UpdateHandle(SLOW_EMA,(int)MathRound(uGA.Chromosome[2]*MaxMAPeriod)+1);
   
   trade_block.UploadBuffers(from);  //�������� ������
   
// CopyBuffer(MAshort,0,from,count,ShortBuffer);
//   CopyBuffer(MAlong,0,from,count,LongBuffer);
//--- ���������� ������ ����
   z=(int)MathRound(uGA.Chromosome[uGA.UGAGetInteger(UGA_GENE_COUNT)-1]*12);
   switch(z)
     {
      case  0: {s="AUDUSD"; break;};
      case  1: {s="AUDUSD"; break;};
      case  2: {s="EURAUD"; break;};
      case  3: {s="EURCHF"; break;};
      case  4: {s="EURGBP"; break;};
      case  5: {s="EURJPY"; break;};
      case  6: {s="EURUSD"; break;};
      case  7: {s="GBPCHF"; break;};
      case  8: {s="GBPJPY"; break;};
      case  9: {s="GBPUSD"; break;};
      case 10: {s="USDCAD"; break;};
      case 11: {s="USDCHF"; break;};
      case 12: {s="USDJPY"; break;};
      default: {s="EURUSD"; break;};
     }
//--- ���������� ������ �������� ������������ F
   optF=uGA.Chromosome[uGA.UGAGetInteger(UGA_GENE_COUNT)];
   }
   
  void MATrain::FitnessFunction(int chromos) //������� �������
   {
   
   } 
  
  MATrain::MATrain(void)       //����������� ������ CTrainLib
   {
    cap=10000;           // ��������� �������
    optF=0.3;            // ����������� F
    OptParamCount=2;     // ���-�� �������������� ����������
    MaxMAPeriod=250;     // ������������ ������ ���������� �������
    depth=250;           // ������� ������� (�� ��������� - 250, ���� ���� ���� - �������� � �������������� ��������/�������)
    from=0;              // ������ �������� ���������� (����������� ���������������� ����� ������ ���������� � ������� InitFirstLayer())
    count=2;             // ������� �� ��� �������� (�� ��������� - 2, ���� ���� ���� - �������� � �������������� ��������/�������)
    ERROR=0.0;           // ������� ������ �� ��� (��� ��� ������������� ������������, �������� ��� ����������)
   }