//������������ ��������� ��������
#include        "UGAlib.mqh"
#include        "MustHaveLib.mqh"
//---
double          cap=10000;      // ��������� �������
double          optF=0.3;       // ����������� F
long            leverage;       // ����� �����
double          contractSize;   // ������ ���������
double          dig;            // ���-�� ������ ����� ������� � ��������� (��� ����������� �������� ������ ������� �� �������� ����� � ������ ���-��� ������)
//--- ��� ���������, ������������ ������������ ������:
int             depth=250;      // ������� ������� (�� ��������� - 250, ���� ���� ���� - �������� � �������������� ��������/�������)
int             from=0;         // ������ �������� ���������� (����������� ���������������� ����� ������ ���������� � ������� InitFirstLayer())
int             count=2;        // ������� �� ��� �������� (�� ��������� - 2, ���� ���� ���� - �������� � �������������� ��������/�������)
//--- 
double          a=2.5;          // �������� ������������ ������� ��������� (��������) (���� �������� ����, �� ��� ��������� ���������� ������� GetANNResult() ���������� ��� ��� �� � 0.75)
int             layers=2;       // ����� (�� ��������� - 2, ���� ���� ���� - �������� � �������������� ��������/�������)
int             neurons=2;      // �������� (�� ��������� - 2, ���� ���� ���� - �������� � �������������� ��������/�������)
double          ne[];           // ������ �������� �������� [�����][�������� � ����]
double          we[];           // ������ ����� �������� [�����][�������� � ����][�������� � ������� �������]
double          ANNRes=0;       // ��������� ������ ���������

double          ERROR=0.0;      // ������� ������ �� ��� (��� ��� ������������� ������������, �������� ��� ����������)
//+------------------------------------------------------------------+
//| InitArrays                                                       |
//| ����������� �������� � �������������� ��������/�������           |
//+------------------------------------------------------------------+
void InitArrays() 
  {
//--- ������ ��������
   ArrayResize(ne,layers*neurons);
//--- ������ ��������
   ArrayResize(we,(layers-1)*neurons*neurons+neurons);
//--- �������������� ������ ��������
   ArrayInitialize(ne,0.5);
//--- �������������� ������ ��������
   ArrayInitialize(we,0.5);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(d,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(o,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(h,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(l,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(c,count);
//--- ��������������� ������ ��� ����������� ��������� �� ������������ ������
   ArrayResize(v,count);
  }
//+------------------------------------------------------------------+
//| ��������� ������ ���������, ����� �������                        |
//| ���� ������� ����������� �������� ������� InitFirstLayer()       |
//+------------------------------------------------------------------+
double GetANNResult() //
  {
   double r;
   int    c1,c2,c3;
   for(c1=2;c1<=layers;c1++)
     {
      for(c2=1;c2<=neurons;c2++)
        {
         ne[(c1-1)*neurons+c2-1]=0;
         for(c3=1;c3<=neurons;c3++)
           {
            ne[(c1-1)*neurons+c2-1]=ne[(c1-1)*neurons+c2-1]+ne[(c1-2)*neurons+c3-1]*we[((c1-2)*neurons+c3-1)*neurons+c2-1];
           }
         ne[(c1-1)*neurons+c2-1]=1/(1+MathExp(-a*ne[(c1-1)*neurons+c2-1]));
        }
     }
   r=0;
   for(c2=1;c2<=neurons;c2++)
     {
      r=r+ne[(layers-1)*neurons+c2-1]*we[(layers-1)*neurons*neurons+c2-1];
     }
   r=1/(1+MathExp(-a*r));
   return(r);
  }
//+------------------------------------------------------------------+
//| �������-������� ��� ������������� ������������ ���������:        |
//| �������� ����, optF, ���� ��������;                              |
//| ����� �������������� ��� ������,                                 |
//| �� ���������� ����������� ������� �� ������������ �����          |
//+------------------------------------------------------------------+
void FitnessFunction(int chromos) 
  {
   int    c1;
   int    b;
//--- ������������� ����� ����� �������� ����� � ��������������� �����������
   int    z;
//������� ������
   double t=cap;                                                      
//������������ ������
   double maxt=t;
//���������� ��������
   double aDD=0;
//������������� ��������
   double rDD=0.000001;
//��������������� �������-�������
   double ff=0;
//�� �������� ���� ��������
   for(c1=1;c1<=GeneCount-2;c1++) we[c1-1]=Colony[c1][chromos];
//�� �������� ����
   z=(int)MathRound(Colony[GeneCount-1][chromos]*12);                 
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
   dig=MathPow(10.0,(double)SymbolInfoInteger(s,SYMBOL_DIGITS));
   //--- �� �������� ����������� F
   optF=Colony[GeneCount][chromos];                                   
   leverage=AccountInfoInteger(ACCOUNT_LEVERAGE);
   contractSize=SymbolInfoDouble(s,SYMBOL_TRADE_CONTRACT_SIZE);
   b=MathMin(Bars(s,tf)-1-count,depth);
   //--- ��� ���������, ������������ ������������ ������ - ������ �������� �� ����������
   for(from=b;from>=1;from--) 
     {
      //--- �������������� ������� ����
      InitFirstLayer();                                                
      //--- �������� ��������� �� ������ ���������
      ANNRes=GetANNResult();
      if(t>0)
        {
         if(ANNRes<0.75) t=t+t*optF*leverage*(o[1]-c[1])*dig/contractSize;
         else            t=t+t*optF*leverage*(c[1]-o[1])*dig/contractSize;
        }
      else t=0;
      if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
      if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
     }
   if(rDD<=trainDD) ff=t; else ff=0.0;
   AmountStartsFF++;
   Colony[0][chromos]=ff;
  }
//+------------------------------------------------------------------+
//| ServiceFunction()                                                |
//+------------------------------------------------------------------+
void ServiceFunction()
  {
  }
//+------------------------------------------------------------------+
//| ���������� � ����� ������������� ������������                    |
//+------------------------------------------------------------------+
void GA()
  {
//--- ���-�� ����� (����� ���-�� �������������� ����������, 
//--- ���� �� ���������� �� �������� ��������� � FitnessFunction())
   GeneCount      =(layers-1)*neurons*neurons+neurons+2;              
//--- ���-�� �������� � �������
   ChromosomeCount=GeneCount*11;                                      
//--- ������� ��������� ������
   RangeMinimum   =0.0;                                               
//--- �������� ��������� ������
   RangeMaximum   =1.0;                                               
//--- ��� ������
   Precision      =0.0001;                                            
//--- 1-�������, ����� ������-��������
   OptimizeMethod =2;                                                 
   ArrayResize(Chromosome,GeneCount+1);
   ArrayInitialize(Chromosome,0);
//--- ���-�� ���� ��� ���������
   Epoch          =100;                                               
//--- ���� ����������, ������������ �������, ������������� �������, ������������� �����, 
//--- �������������, ����������� �������� ������ ���������, ����������� ������� ������� ���� � %
   UGA(100.0,1.0,1.0,1.0,1.0,0.5,1.0);                                
  }
//+------------------------------------------------------------------+
//| GetTrainANNResults()                                             |
//| �������� ���������������� ��������� ���������                    |
//| � ������ ����������; ������ ������ ���� ����� ���-�� �����       |
//+------------------------------------------------------------------+
void GetTrainANNResults()
  {
   int c1;
//--- ������������� ����� ����� �������� ����� � ��������������� �����������
   int z;                                                            
//--- ���������� ������ ���� ��������
   for(c1=1;c1<=GeneCount-2;c1++) we[c1-1]=Chromosome[c1];
//--- ���������� ������ ����
   z=(int)MathRound(Chromosome[GeneCount-1]*12);
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
   optF=Chromosome[GeneCount];                                        
  }
//+------------------------------------------------------------------+
