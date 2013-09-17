//+------------------------------------------------------------------+
//|                                                          UGA.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include        <TradeBlocks/CrossEMA.mq5>
#include        <TradeManager/TradeManager.mqh>

class  GenOptimosator //����� ������������� ������������
 {
   public:
//���������� ���������� ��� ������� UGALib
double Chromosome[];            //����� �������������� ���������� ������� - �����                            //(��������: ���� ��������� ���� � �.�.)-���������
int    ChromosomeCount;  //����������� ��������� ���������� �������� � �������
int    TotalOfChromosomesInHistory;//����� ���������� �������� � �������
int    ChrCountInHistory;  //���������� ���������� �������� � ���� ��������
int    GeneCount;  //���������� ����� � ���������
double RangeMinimum;//������� ��������� ������
double RangeMaximum;//�������� ��������� ������
double Precision;//��� ������
int    OptimizeMethod;  //1-�������, ����� ������ - ��������
double Population   [][1000];   //���������
double Colony       [][500];    //������� ��������
int    PopulChromosCount;  //������� ���������� �������� � ���������
int    Epoch;  //���-�� ���� ��� ���������
int    AmountStartsFF;        //���������� �������� ������� �����������������
//���������� ���������� ��� ������� MATrainLib
double          cap;           // ��������� �������
double          optF;            // ����������� F
long            leverage;            // ����� �����
double          contractSize;        // ������ ���������
double          dig;                 // ���-�� ������ ����� ������� � ��������� (��� ����������� �������� ������ ������� �� �������� ����� � ������ ���-��� ������)
int             OptParamCount;     // ���-�� �������������� ����������
int             MaxMAPeriod;     // ������������ ������ ���������� �������
int             depth;           // ������� ������� (�� ��������� - 250, ���� ���� ���� - �������� � �������������� ��������/�������)
int             from;              // ������ �������� ���������� (����������� ���������������� ����� ������ ���������� � ������� InitFirstLayer())
int             count;             // ������� �� ��� �������� (�� ��������� - 2, ���� ���� ���� - �������� � �������������� ��������/�������)
double          ERROR;           // ������� ������ �� ��� (��� ��� ������������� ������������, �������� ��� ����������)
CrossEMA        trade_block;         //����� ����
int                 MAlong,MAshort;              // ��-������
double              LongBuffer[],ShortBuffer[];  // ������������ ������
ENUM_TM_POSITION_TYPE   signal;      //�������� ������
ENUM_TM_POSITION_TYPE   signal2;      //�������� ������
string              fn;                  // ��� �����
int                 handle;              // ������ �� ����������� ����
string              f;                   // ���-������, ������������ � ����
string              s;          // ����
ENUM_TIMEFRAMES     tf;        // ���������
MqlDateTime         dt;                  // ����-����� � ���� ���������, � �� �������� int-������
datetime            d[];                 // ����-����� int-������
double              o[];                 // ��������
double              h[];                 // ���������
double              l[];                 // ��������
double              c[];                 // ��������
long                v[];                 // �������� ������
datetime            prevBT[1],curBT[1];  // ����� ������ ���� � ������� �����
MqlDateTime         prevT,curT;          // ����� ������ ���� � ������� ���������
MqlTradeRequest     request;             // �������� ������
MqlTradeCheckResult check;               // �������� ��������� ������� 
MqlTradeResult      result;              // ��������� ��������� �������
double              maxBalance;          // ������������ ������
double              traindd;
 public:
 //������� ������ UGA
void UGA(
         double ReplicationPortion, //���� ����������.
         double NMutationPortion,   //���� ������������ �������.
         double ArtificialMutation, //���� ������������� �������.
         double GenoMergingPortion, //���� ������������� �����.
         double CrossingOverPortion,//���� �������������.
         double ReplicationOffset,  //����������� �������� ������ ���������
         double NMutationProbability//����������� ������� ������� ���� � %
        );
void ProtopopulationBuilding(); //�������� ��������������
void GetFitness(double &historyHromosomes[][100000]); //��������� ����������������� ��� ������ �����
void CheckHistoryChromosomes(
         int chromos,
         double &historyHromosomes[][100000]
        ); //�������� ��������� �� ���� ��������
void CycleOfOperators(
         double &historyHromosomes[][100000],
         double ReplicationPortion, //���� ����������.
         double NMutationPortion,   //���� ������������ �������.
         double ArtificialMutation, //���� ������������� �������.
         double GenoMergingPortion, //���� ������������� �����.
         double CrossingOverPortion,//���� �������������.
         double ReplicationOffset,  //����������� �������� ������ ���������
         double NMutationProbability//����������� ������� ������� ���� � %
        ); //���� ���������� UGA
void Replication(
         double &child[],
         double  ReplicationOffset
        ); //����������
void NaturalMutation(
         double &child[],
         double  NMutationProbability
        ); //������������ �������
void ArtificialMutation(
         double &child[],
         double  ReplicationOffset
        ); //������������ �������
void GenoMerging(double &child[]); //������������� �����
void CrossingOver(double &child[]); //������������
void SelectTwoParents(
         int &address_mama,
         int &address_papa
        ); //����� ���� ������
void SelectOneParent(int &address); //����� ������ ��������
int NaturalSelection(); //������������ �����
void RemovalDuplicates(); //�������� ���������� � ����������� �� VFF
void PopulationRanking(); //������������ ���������

double RNDfromCI(double Minimum,double Maximum);  //��������� ��������� ����� �� ��������� ���������
double SelectInDiscreteSpace(
         double In, 
         double InMin, 
         double InMax, 
         double step, 
         int    RoundMode
        ); //����� � ���������� ������������

//������� ��� ������� MATRAINLIB

void InitRelDD(); 
double GetRelDD();
double GetPossibleLots(); 
void InitArrays();
void FitnessFunction(int chromos);
void ServiceFunction();
void GA();
void GetTrainResults();
//����������� ������
GenOptimosator();
};
//+------------------------------------------------------------------+
//| ������� ��� ������� UGA
//+------------------------------------------------------------------+
//�������� ������� UGA
void GenOptimosator::UGA
(
double ReplicationPortion, //���� ����������.
double NMutationPortion,   //���� ������������ �������.
double ArtificialMutation, //���� ������������� �������.
double GenoMergingPortion, //���� ������������� �����.
double CrossingOverPortion,//���� �������������.
//---
double ReplicationOffset,  //����������� �������� ������ ���������
double NMutationProbability//����������� ������� ������� ���� � %
)
{ 
  //����� ����������, ������������ ������ ���� ���
  MathSrand((int)TimeLocal());
  //-----------------------����������-------------------------------------
  int    chromos=0, gene  =0;//������� �������� � �����
  int    resetCounterFF   =1;//������� ������� "���� ��� ���������"
  int    currentEpoch     =1;//����� ������� �����
  int    SumOfCurrentEpoch=0;//����� "���� ��� ���������"
  int    MinOfCurrentEpoch=Epoch;//����������� "���� ��� ���������"
  int    MaxOfCurrentEpoch=0;//������������ "���� ��� ���������"
  int    epochGlob        =0;//����� ���������� ����
  // ������� [���������� ���������(�����)][���������� ������ � �������]
  ArrayResize    (Population,GeneCount+1);
  ArrayInitialize(Population,0.0);
  // ������� �������� [���������� ���������(�����)][���������� ������ � �������]
  ArrayResize    (Colony,GeneCount+1);
  ArrayInitialize(Colony,0.0);
  // ���� ��������
  // [���������� ���������(�����)][���������� �������� � �����]
  double          historyHromosomes[][100000];
  ArrayResize    (historyHromosomes,GeneCount+1);
  ArrayInitialize(historyHromosomes,0.0);
  //----------------------------------------------------------------------
  //--------------�������� ������������ ������� ����������----------------
  //...���������� �������� ������ ���� �� ������ 2
  if (ChromosomeCount<=1)  ChromosomeCount=2;
  if (ChromosomeCount>500) ChromosomeCount=500;
  //----------------------------------------------------------------------
  //======================================================================
  // 1) ������� ��������������                                     �����1)
  ProtopopulationBuilding ();
  //======================================================================
  // 2) ���������� ����������������� ������ �����                  �����2)
  //��� 1-�� �������
  for (chromos=0;chromos<ChromosomeCount;chromos++)
    for (gene=1;gene<=GeneCount;gene++)
      Colony[gene][chromos]=Population[gene][chromos];

  GetFitness(historyHromosomes);

  for (chromos=0;chromos<ChromosomeCount;chromos++)
    Population[0][chromos]=Colony[0][chromos];

  //��� 2-�� �������
  for (chromos=ChromosomeCount;chromos<ChromosomeCount*2;chromos++)
    for (gene=1;gene<=GeneCount;gene++)
      Colony[gene][chromos-ChromosomeCount]=Population[gene][chromos];

  GetFitness(historyHromosomes);

  for (chromos=ChromosomeCount;chromos<ChromosomeCount*2;chromos++)
    Population[0][chromos]=Colony[0][chromos-ChromosomeCount];
  //======================================================================
  // 3) ����������� ��������� � �����������                         ����3)
  RemovalDuplicates();
  //======================================================================
  // 4) �������� ��������� ���������                               �����4)
  for (gene=0;gene<=GeneCount;gene++)
    Chromosome[gene]=Population[gene][0];
  //======================================================================
  //ServiceFunction();

  //�������� ���� ������������� ��������� � 5 �� 6
  while (currentEpoch<=Epoch)
  {
    //====================================================================
    // 5) ��������� UGA                                            �����5)
    CycleOfOperators
    (
    historyHromosomes,
    //---
    ReplicationPortion, //���� ����������.
    NMutationPortion,   //���� ������������ �������.
    ArtificialMutation, //���� ������������� �������.
    GenoMergingPortion, //���� ������������� �����.
    CrossingOverPortion,//���� �������������.
    //---
    ReplicationOffset,  //����������� �������� ������ ���������
    NMutationProbability//����������� ������� ������� ���� � %
    );
    //====================================================================
    // 6) �������� ���� ������� ������� � ������ ��������� ���������. 
    // ���� ��������� ������� ������� ����� ���������,
    // �������� ���������.                                         �����6)
    //���� ����� ����������� - �����������
    if (OptimizeMethod==1)
    {
      //���� ������ ��������� ��������� ����� ���������
      if (Population[0][0]<Chromosome[0])
      {
        //������� ��������� ���������
        for (gene=0;gene<=GeneCount;gene++)
          Chromosome[gene]=Population[gene][0];
      //  ServiceFunction();
        //������� ������� "���� ��� ���������"
        if (currentEpoch<MinOfCurrentEpoch)
          MinOfCurrentEpoch=currentEpoch;
        if (currentEpoch>MaxOfCurrentEpoch)
          MaxOfCurrentEpoch=currentEpoch;
        SumOfCurrentEpoch+=currentEpoch; currentEpoch=1; resetCounterFF++;
      }
      else
        currentEpoch++;
    }
    //���� ����� ����������� - ������������
    else
    {
      //���� ������ ��������� ��������� ����� ���������
      if (Population[0][0]>Chromosome[0])
      {
        //������� ��������� ���������
        for (gene=0;gene<=GeneCount;gene++)
          Chromosome[gene]=Population[gene][0];
     //   ServiceFunction();
        //������� ������� "���� ��� ���������"
        if (currentEpoch<MinOfCurrentEpoch)
          MinOfCurrentEpoch=currentEpoch;
        if (currentEpoch>MaxOfCurrentEpoch)
          MaxOfCurrentEpoch=currentEpoch;
        SumOfCurrentEpoch+=currentEpoch; currentEpoch=1; resetCounterFF++;
      }
      else
        currentEpoch++;
    }
    //====================================================================
    //������ ��� ���� �����....
    epochGlob++;
  }

}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//�������� ��������������
void GenOptimosator::ProtopopulationBuilding()
{ 
  PopulChromosCount=ChromosomeCount*2;
  //��������� ��������� ����������� �� ����������
  //...������ � ��������� RangeMinimum...RangeMaximum
  for (int chromos=0;chromos<PopulChromosCount;chromos++)
  {
    //������� � 1-�� ������� (0-�� -�������������� ��� VFF) 
    for (int gene=1;gene<=GeneCount;gene++)
      Population[gene][chromos]=
      SelectInDiscreteSpace(RNDfromCI(RangeMinimum,RangeMaximum),RangeMinimum,RangeMaximum,Precision,3);
    TotalOfChromosomesInHistory++;
  }
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//��������� ����������������� ��� ������ �����.
void GenOptimosator::GetFitness
(
double &historyHromosomes[][100000]
)
{ 
  for (int chromos=0;chromos<ChromosomeCount;chromos++)
    CheckHistoryChromosomes(chromos,historyHromosomes);
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//�������� ��������� �� ���� ��������.
void GenOptimosator::CheckHistoryChromosomes
(
int     chromos,
double &historyHromosomes[][100000]
)
{ 
  //-----------------------����������-------------------------------------
  int   Ch1=0;  //������ ��������� �� ����
  int   Ge =0;  //������ ����
  int   cnt=0;  //������� ���������� �����. ���� ���� ���� ��� ���������� 
                //- ��������� ���������� ����������
  //----------------------------------------------------------------------
  //���� � ���� �������� ���� ���� ���������
  if (ChrCountInHistory>0)
  {
    //��������� ��������� � ����, ����� ����� ����� ��
    for (Ch1=0;Ch1<ChrCountInHistory && cnt<GeneCount;Ch1++)
    {
      cnt=0;
      //������� ����, ���� ������ ���� ������ ���-�� ����� � ���� ���������� ���������� ����
      for (Ge=1;Ge<=GeneCount;Ge++)
      {
        if (Colony[Ge][chromos]!=historyHromosomes[Ge][Ch1])
          break;
        cnt++;
      }
    }
    //���� ��������� ���������� ����� ������� ��, ����� ����� ������� ������� �� ����
    if (cnt==GeneCount)
      Colony[0][chromos]=historyHromosomes[0][Ch1-1];
    //���� ��� ����� �� ��������� � ����, �� ���������� ��� �� FF...
    else
    {
    
      FitnessFunction(chromos);
      //.. � ���� ���� ����� � ���� ��������
      if (ChrCountInHistory<100000)
      {
        for (Ge=0;Ge<=GeneCount;Ge++)
          historyHromosomes[Ge][ChrCountInHistory]=Colony[Ge][chromos];
        ChrCountInHistory++;
      }
    }
  }
  //���� ���� ������, ���������� ��� �� FF � �������� � � ����
  else
  {
    FitnessFunction(chromos);
    for (Ge=0;Ge<=GeneCount;Ge++)
      historyHromosomes[Ge][ChrCountInHistory]=Colony[Ge][chromos];
    ChrCountInHistory++;
  }
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//���� ���������� UGA
void GenOptimosator::CycleOfOperators
(
double &historyHromosomes[][100000],
//---
double    ReplicationPortion, //���� ����������.
double    NMutationPortion,   //���� ������������ �������.
double    ArtificialMutation, //���� ������������� �������.
double    GenoMergingPortion, //���� ������������� �����.
double    CrossingOverPortion,//���� �������������.
//---
double    ReplicationOffset,  //����������� �������� ������ ���������
double    NMutationProbability//����������� ������� ������� ���� � %
)
{
  //-----------------------����������-------------------------------------
  double          child[];
  ArrayResize    (child,GeneCount+1);
  ArrayInitialize(child,0.0);

  int gene=0,chromos=0, border=0;
  int    i=0,u=0;
  double p=0.0,start=0.0;
  double          fit[][2];
  ArrayResize    (fit,6);
  ArrayInitialize(fit,0.0);

  //������� ���������� ���� � ����� ���������.
  int T=0;
  //----------------------------------------------------------------------

  //������� ���� ���������� UGA
  double portion[6];
  portion[0]=ReplicationPortion; //���� ����������.
  portion[1]=NMutationPortion;   //���� ������������ �������.
  portion[2]=ArtificialMutation; //���� ������������� �������.
  portion[3]=GenoMergingPortion; //���� ������������� �����.
  portion[4]=CrossingOverPortion;//���� �������������.
  portion[5]=0.0;
  //----------------------------
  if (NMutationProbability<0.0)
    NMutationProbability=0.0;
  if (NMutationProbability>100.0)
    NMutationProbability=100.0;
  //----------------------------
  //------------------------���� ���������� UGA---------
  //��������� ����� ������� ��������� 
  while (T<ChromosomeCount)
  {
    //============================
    for (i=0;i<6;i++)
    {
      fit[i][0]=start;
      fit[i][1]=start+MathAbs(portion[i]-portion[5]);
      start=fit[i][1];
    }
    p=RNDfromCI(fit[0][0],fit[4][1]);
    for (u=0;u<5;u++)
    {
      if ((fit[u][0]<=p && p<fit[u][1]) || p==fit[u][1])
        break;
    }
    //============================
    switch (u)
    {
    //---------------------
    case 0:
      //------------------------����������--------------------------------
      //���� ���� ����� � ����� �������, �������� ����� �����
      if (T<ChromosomeCount)
      {
        Replication(child,ReplicationOffset);
        //������� ����� ����� � ����� �������
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //���� ����� ������, ������� ���������� ������
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    case 1:
      //---------------------������������ �������-------------------------
      //���� ���� ����� � ����� �������, �������� ����� �����
      if (T<ChromosomeCount)
      {
        NaturalMutation(child,NMutationProbability);
        //������� ����� ����� � ����� �������
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //���� ����� ������, ������� ���������� ������
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    case 2:
      //----------------------������������� �������-----------------------
      //���� ���� ����� � ����� �������, �������� ����� �����
      if (T<ChromosomeCount)
      {
        ArtificialMutation(child,ReplicationOffset);
        //������� ����� ����� � �����  �������
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //���� ����� ������, ������� ���������� ������
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    case 3:
      //-------------����������� ����� � ��������������� ������-----------
      //���� ���� ����� � ����� �������, �������� ����� �����
      if (T<ChromosomeCount)
      {
        GenoMerging(child);
        //������� ����� ����� � ����� ������� 
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //���� ����� ������, ������� ���������� ������
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------
      break;
      //---------------------
    default:
      //---------------------------������������---------------------------
      //���� ���� ����� � ����� �������, �������� ����� �����
      if (T<ChromosomeCount)
      {
        CrossingOver(child);
        //������� ����� ����� � �����  �������
        for (gene=1;gene<=GeneCount;gene++) Colony[gene][T]=child[gene];
        //���� ����� ������, ������� ���������� ������
        T++;
        TotalOfChromosomesInHistory++;
      }
      //---------------------------------------------------------------

      break;
      //---------------------
    }
  }//����� ����� ���������� UGA--

  //��������� ����������������� ������ ����� � ������� ��������
  GetFitness(historyHromosomes);

  //������� �������� � �������� ���������
  if (PopulChromosCount>=ChromosomeCount)
  {
    border=ChromosomeCount;
    PopulChromosCount=ChromosomeCount*2;
  }
  else
  {
    border=PopulChromosCount;
    PopulChromosCount+=ChromosomeCount;
  }
  for (chromos=0;chromos<ChromosomeCount;chromos++)
    for (gene=0;gene<=GeneCount;gene++)
      Population[gene][chromos+border]=Colony[gene][chromos];

  //���������� ��������� � ���������� �����������
  RemovalDuplicates();
}//����� �-��
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//����������
void GenOptimosator::Replication
(
double &child[],
double  ReplicationOffset
)
{
  //-----------------------����������-------------------------------------
  double C1=0.0,C2=0.0,temp=0.0,Maximum=0.0,Minimum=0.0;
  int address_mama=0,address_papa=0;
  //----------------------------------------------------------------------
  SelectTwoParents(address_mama,address_papa);
  //-------------------���� �������� �����--------------------------------
  for (int i=1;i<=GeneCount;i++)
  {
    //----��������� ������ ���� � ���� --------
    C1 = Population[i][address_mama];
    C2 = Population[i][address_papa];
    //------------------------------------------
    
    //------------------------------------------------------------------
    //....��������� ���������� � ���������� �� ���,
    //���� �1>C2, �������� �� �������
    if (C1>C2)
    {
      temp = C1; C1=C2; C2 = temp;
    }
    //--------------------------------------------
    if (C2-C1<Precision)
    {
      child[i]=C1; continue;
    }
    //--------------------------------------------
    //�������� ������� �������� ������ ����
    Minimum = C1-((C2-C1)*ReplicationOffset);
    Maximum = C2+((C2-C1)*ReplicationOffset);
    //--------------------------------------------
    //������������ ��������, ��� �� ����� �� ����� �� ��������� ���������
    if (Minimum < RangeMinimum) Minimum = RangeMinimum;
    if (Maximum > RangeMaximum) Maximum = RangeMaximum;
    //---------------------------------------------------------------
    temp=RNDfromCI(Minimum,Maximum);
    child[i]=
    SelectInDiscreteSpace(temp,RangeMinimum,RangeMaximum,Precision,3);
  }
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//������������ �������.
void GenOptimosator::NaturalMutation
(
double &child[],
double  NMutationProbability
)
{
  //-----------------------����������-------------------------------------
  int    address=0;
  //----------------------------------------------------------------------
  
  //-----------------����� ��������------------------------
  SelectOneParent(address);
  //---------------------------------------
  for (int i=1;i<=GeneCount;i++)
    if (RNDfromCI(0.0,100.0)<=NMutationProbability)
      child[i]=
      SelectInDiscreteSpace(RNDfromCI(RangeMinimum,RangeMaximum),RangeMinimum,RangeMaximum,Precision,3);
    else
      child[i]=Population[i][address];
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//������������� �������.
void GenOptimosator::ArtificialMutation
(
double &child[],
double  ReplicationOffset
)
{
  //-----------------------����������-------------------------------------
  double C1=0.0,C2=0.0,temp=0.0,Maximum=0.0,Minimum=0.0,p=0.0;
  int address_mama=0,address_papa=0;
  //----------------------------------------------------------------------
  //-----------------����� ���������------------------------
  SelectTwoParents(address_mama,address_papa);
  //--------------------------------------------------------
  //-------------------���� �������� �����------------------------------
  for (int i=1;i<=GeneCount;i++)
  {
    //----��������� ������ ���� � ���� --------
    C1 = Population[i][address_mama];
    C2 = Population[i][address_papa];
    //------------------------------------------
    
    //------------------------------------------------------------------
    //....��������� ���������� � ���������� �� ���,
    //���� �1>C2, �������� �� �������
    if (C1>C2)
    {
      temp=C1; C1=C2; C2=temp;
    }
    //--------------------------------------------
    //�������� ������� �������� ������ ����
    Minimum=C1-((C2-C1)*ReplicationOffset);
    Maximum=C2+((C2-C1)*ReplicationOffset);
    //--------------------------------------------
    //������������ ��������, ��� �� ����� �� ����� �� ��������� ���������
    if (Minimum < RangeMinimum) Minimum = RangeMinimum;
    if (Maximum > RangeMaximum) Maximum = RangeMaximum;
    //---------------------------------------------------------------
    p=MathRand();
    if (p<16383.5)
    {
      temp=RNDfromCI(RangeMinimum,Minimum);
      child[i]=
      SelectInDiscreteSpace(temp,RangeMinimum,RangeMaximum,Precision,3);
    }
    else
    {
      temp=RNDfromCI(Maximum,RangeMaximum);
      child[i]=
      SelectInDiscreteSpace(temp,RangeMinimum,RangeMaximum,Precision,3);
    }
  }
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//������������� �����.
void GenOptimosator::GenoMerging
(
double &child[]
)
{
  //-----------------------����������-------------------------------------
  int  address=0;
  //----------------------------------------------------------------------
  for (int i=1;i<=GeneCount;i++)
  {
    //-----------------����� ��������------------------------
    SelectOneParent(address);
    //--------------------------------------------------------
    child[i]=Population[i][address];
  }
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//������������.
void GenOptimosator::CrossingOver
(
double &child[]
)
{
  //-----------------------����������-------------------------------------
  int address_mama=0,address_papa=0;
  //----------------------------------------------------------------------
  //-----------------����� ���������------------------------
  SelectTwoParents(address_mama,address_papa);
  //--------------------------------------------------------
  //��������� ����� �������
  int address_of_gene=(int)MathFloor((GeneCount-1)*(MathRand()/32767.5));

  for (int i=1;i<=GeneCount;i++)
  {
    //----�������� ���� ������--------
    if (i<=address_of_gene+1)
      child[i]=Population[i][address_mama];
    //----�������� ���� ����--------
    else
      child[i]=Population[i][address_papa];
  }
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//����� ���� ���������.
void GenOptimosator::SelectTwoParents
(
int &address_mama,
int &address_papa
)
{
  //-----------------------����������-------------------------------------
  int cnt=1;
  address_mama=0;//����� ����������� ����� � ���������
  address_papa=0;//����� ��������� ����� � ���������
  //----------------------------------------------------------------------
  //----------------------------����� ���������--------------------------
  //������ ������� ������� ������ ���������.
  while (cnt<=10)
  {
    //��� ����������� �����
    address_mama=NaturalSelection();
    //��� ��������� �����
    address_papa=NaturalSelection();
    if (address_mama!=address_papa)
      break;
    cnt++;
  }
  //---------------------------------------------------------------------
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//����� ������ ��������.
void GenOptimosator::SelectOneParent
(
int &address//����� ������������ ����� � ���������
)
{
  //-----------------------����������-------------------------------------
  address=0;
  //----------------------------------------------------------------------
  //----------------------------����� ��������--------------------------
  address=NaturalSelection();
  //---------------------------------------------------------------------
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//������������ �����.
int GenOptimosator::NaturalSelection()
{
  //-----------------------����������-------------------------------------
  int    i=0,u=0;
  double p=0.0,start=0.0;
  double          fit[][2];
  ArrayResize    (fit,PopulChromosCount);
  ArrayInitialize(fit,0.0);
  double delta=(Population[0][0]-Population[0][PopulChromosCount-1])*0.01-Population[0][PopulChromosCount-1];
  //----------------------------------------------------------------------

  for (i=0;i<PopulChromosCount;i++)
  {
    fit[i][0]=start;
    fit[i][1]=start+MathAbs(Population[0][i]+delta);
    start=fit[i][1];
  }
  p=RNDfromCI(fit[0][0],fit[PopulChromosCount-1][1]);

  for (u=0;u<PopulChromosCount;u++)
    if ((fit[u][0]<=p && p<fit[u][1]) || p==fit[u][1])
      break;

  return(u);
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//�������� ���������� � ����������� �� VFF
void GenOptimosator::RemovalDuplicates()
{
  //-----------------------����������-------------------------------------
  int             chromosomeUnique[1000];//������ ������ ������� ������������ 
                                         //������ ���������: 0-��������, 1-����������
  ArrayInitialize(chromosomeUnique,1);   //�����������, ��� ���������� ���
  double          PopulationTemp[][1000];
  ArrayResize    (PopulationTemp,GeneCount+1);
  ArrayInitialize(PopulationTemp,0.0);

  int Ge =0;                             //������ ����
  int Ch =0;                             //������ ���������
  int Ch2=0;                             //������ ������ ���������
  int cnt=0;                             //�������
  //----------------------------------------------------------------------

  //----------------------������ ���������---------------------------1
  //�������� ������ �� ���� ��� ���������...
  for (Ch=0;Ch<PopulChromosCount-1;Ch++)
  {
    //���� �� ��������...
    if (chromosomeUnique[Ch]!=0)
    {
      //�������� ������ �� ����...
      for (Ch2=Ch+1;Ch2<PopulChromosCount;Ch2++)
      {
        if (chromosomeUnique[Ch2]!=0)
        {
          //������� ������� ���������� ���������� �����
          cnt=0;
          //������� ����, ���� ���������� ���������� ����
          for (Ge=1;Ge<=GeneCount;Ge++)
          {
            if (Population[Ge][Ch]!=Population[Ge][Ch2])
              break;
            else
              cnt++;
          }
          //���� ��������� ���������� ����� ������� ��, ������� ����� �����
          //..��������� ���������� ����������
          if (cnt==GeneCount)
            chromosomeUnique[Ch2]=0;
        }
      }
    }
  }
  //������� ��������� ���������� ���������� ��������
  cnt=0;
  //��������� ���������� ��������� �� ��������� �����
  for (Ch=0;Ch<PopulChromosCount;Ch++)
  {
    //���� ��������� ���������, ��������� �, ���� ���, �������� � ���������
    if (chromosomeUnique[Ch]==1)
    {
      for (Ge=0;Ge<=GeneCount;Ge++)
        PopulationTemp[Ge][cnt]=Population[Ge][Ch];
      cnt++;
    }
  }
  //�������� ���������� "����� ��������" �������� �������� ���������� ��������
  PopulChromosCount=cnt;
  //������ ���������� ��������� ������� � ������ ��� ���������� �������� 
  //..������������ ��������� 
  for (Ch=0;Ch<PopulChromosCount;Ch++)
    for (Ge=0;Ge<=GeneCount;Ge++)
      Population[Ge][Ch]=PopulationTemp[Ge][Ch];
  //=================================================================1

  //----------------������������ ���������---------------------------2
  PopulationRanking();
  //=================================================================2
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//������������ ���������.
void GenOptimosator::PopulationRanking()
{
  //-----------------------����������-------------------------------------
  int cnt=1, i = 0, u = 0;
  double          PopulationTemp[][1000];           //��������� ��������� 
  ArrayResize    (PopulationTemp,GeneCount+1);
  ArrayInitialize(PopulationTemp,0.0);

  int             Indexes[];                        //������� ��������
  ArrayResize    (Indexes,PopulChromosCount);
  ArrayInitialize(Indexes,0);
  int    t0=0;
  double          ValueOnIndexes[];                 //VFF ���������������
                                                    //..�������� ��������
  ArrayResize    (ValueOnIndexes,PopulChromosCount);
  ArrayInitialize(ValueOnIndexes,0.0); double t1=0.0;
  //----------------------------------------------------------------------

  //��������� ������� �� ��������� ������� temp2 � 
  //...��������� ������ ������ �� ������������ �������
  for (i=0;i<PopulChromosCount;i++)
  {
    Indexes[i] = i;
    ValueOnIndexes[i] = Population[0][i];
  }
  if (OptimizeMethod==1)
  {
    while (cnt>0)
    {
      cnt=0;
      for (i=0;i<PopulChromosCount-1;i++)
      {
        if (ValueOnIndexes[i]>ValueOnIndexes[i+1])
        {
          //-----------------------
          t0 = Indexes[i+1];
          t1 = ValueOnIndexes[i+1];
          Indexes   [i+1] = Indexes[i];
          ValueOnIndexes   [i+1] = ValueOnIndexes[i];
          Indexes   [i] = t0;
          ValueOnIndexes   [i] = t1;
          //-----------------------
          cnt++;
        }
      }
    }
  }
  else
  {
    while (cnt>0)
    {
      cnt=0;
      for (i=0;i<PopulChromosCount-1;i++)
      {
        if (ValueOnIndexes[i]<ValueOnIndexes[i+1])
        {
          //-----------------------
          t0 = Indexes[i+1];
          t1 = ValueOnIndexes[i+1];
          Indexes   [i+1] = Indexes[i];
          ValueOnIndexes   [i+1] = ValueOnIndexes[i];
          Indexes   [i] = t0;
          ValueOnIndexes   [i] = t1;
          //-----------------------
          cnt++;
        }
      }
    }
  }
  //�������� ��������������� ������ �� ���������� ��������
  for (i=0;i<GeneCount+1;i++)
    for (u=0;u<PopulChromosCount;u++)
      PopulationTemp[i][u]=Population[i][Indexes[u]];
  //��������� ��������������� ������ �������
  for (i=0;i<GeneCount+1;i++)
    for (u=0;u<PopulChromosCount;u++)
      Population[i][u]=PopulationTemp[i][u];
}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//��������� ��������� ����� �� ��������� ���������.
double GenOptimosator::RNDfromCI(double Minimum,double Maximum) 
{ return(Minimum+((Maximum-Minimum)*MathRand()/32767.5));}
//������������������������������������������������������������������������

//������������������������������������������������������������������������
//����� � ���������� ������������.
//������:
//1-��������� �����
//2-��������� ������ 
//�����-�� ����������
double GenOptimosator::SelectInDiscreteSpace
(
double In, 
double InMin, 
double InMax, 
double step, 
int    RoundMode
)
{
  if (step==0.0)
    return(In);
  // ��������� ������������ ������
  if ( InMax < InMin )
  {
    double temp = InMax; InMax = InMin; InMin = temp;
  }
  // ��� ��������� - ������ ���������� �������
  if ( In < InMin ) return( InMin );
  if ( In > InMax ) return( InMax );
  if ( InMax == InMin || step <= 0.0 ) return( InMin );
  // �������� � ��������� ��������
  step = (InMax - InMin) / MathCeil ( (InMax - InMin) / step );
  switch ( RoundMode )
  {
  case 1:  return( InMin + step * MathFloor ( ( In - InMin ) / step ) );
  case 2:  return( InMin + step * MathCeil  ( ( In - InMin ) / step ) );
  default: return( InMin + step * MathRound ( ( In - InMin ) / step ) );
  }
}
//+------------------------------------------------------------------+
//| ������� ��� ������� MATRAINLIB
//+------------------------------------------------------------------+
void GenOptimosator::InitRelDD()
  {
   ulong DealTicket;
   double curBalance;
   prevBT[0]=D'2000.01.01 00:00:00';
   TimeToStruct(prevBT[0],prevT);
   curBalance=AccountInfoDouble(ACCOUNT_BALANCE);
   maxBalance=curBalance;
   HistorySelect(D'2000.01.01 00:00:00',TimeCurrent());
   for(int i=HistoryDealsTotal();i>0;i--)
     {
      DealTicket=HistoryDealGetTicket(i);
      curBalance=curBalance+HistoryDealGetDouble(DealTicket,DEAL_PROFIT);
      if(curBalance>maxBalance) maxBalance=curBalance;
     }
  }
//+------------------------------------------------------------------+
//| GetRelDD()                                                       |
//+------------------------------------------------------------------+
double GenOptimosator::GetRelDD()
  {
   if(AccountInfoDouble(ACCOUNT_BALANCE)>maxBalance) maxBalance=AccountInfoDouble(ACCOUNT_BALANCE);
   return((maxBalance-AccountInfoDouble(ACCOUNT_BALANCE))/maxBalance);
  }
//+------------------------------------------------------------------+
//| GetPossibleLots()                                                |
//+------------------------------------------------------------------+
double GenOptimosator::GetPossibleLots()
  {
   request.volume=1.0;
   if(request.type==ORDER_TYPE_SELL) request.price=SymbolInfoDouble(s,SYMBOL_BID); else request.price=SymbolInfoDouble(s,SYMBOL_ASK);
   OrderCheck(request,check);
   return(NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN)/check.margin,2));
  }
  
void GenOptimosator::InitArrays()
  {
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
//| �������-������� ��� ������������� ������������ ���������:        |
//| �������� ����, optF, ���� ��������;                              |
//| ����� �������������� ��� ������, �� ����������                   |
//| ����������� ������� �� ������������ �����                        |
//+------------------------------------------------------------------+
void GenOptimosator::FitnessFunction(int chromos)
  {
   int    b;
//--- ���� �������� �������?   
   bool   trig=false;
//--- ����������� �������� �������
   string dir="";
//--- ���� �������� �������
   double OpenPrice=0;
//--- ������������� ����� ����� �������� ����� � ��������������� �����������
   int    z;
//--- ������� ������
   double t=cap;
//--- ������������ ������
   double maxt=t;
//--- ���������� ��������
   double aDD=0;
//--- ������������� ��������
   double rDD=0.000001;
//--- ��������������� �������-�������
   double ff=0;
//--- �� �������� ����
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
       
   trade_block.UpdateHandle(FAST_EMA,(int)MathRound(Colony[1][chromos]*MaxMAPeriod)+1); //��������� ����� �������� ����������   
   trade_block.UpdateHandle(SLOW_EMA,(int)MathRound(Colony[2][chromos]*MaxMAPeriod)+1); //��������� ����� ���������� ����������

   
   dig=MathPow(10.0,(double)SymbolInfoInteger(s,SYMBOL_DIGITS));
//--- �� �������� ����������� F
   optF=Colony[GeneCount][chromos];
   leverage=AccountInfoInteger(ACCOUNT_LEVERAGE);
   contractSize=SymbolInfoDouble(s,SYMBOL_TRADE_CONTRACT_SIZE);
   b=MathMin(Bars(s,tf)-1-count-MaxMAPeriod,depth);
//--- ��� ���������, ������������ ������������ ������ - ������ �������� �� ����������
   for(from=b;from>=1;from--)
     {
     // CopyBuffer(MAshort,0,from,count,ShortBuffer);
     // CopyBuffer(MAlong,0,from,count,LongBuffer);
      
      signal2 = trade_block.GetSignal(true,from); //�������� �������� ������
      
      //if(LongBuffer[0]>LongBuffer[1] && ShortBuffer[0]>LongBuffer[0] && ShortBuffer[1]<LongBuffer[1])
        if(signal2 == OP_SELL)
        {
         if(trig==false)
           {
            CopyOpen(s,tf,from,count,o);
            OpenPrice=o[1];
            dir="SELL";
            trig=true;
           }
         else
           {
            if(dir=="BUY")
              {
               CopyOpen(s,tf,from,count,o);
               if(t>0) t=t+t*optF*leverage*(o[1]-OpenPrice)*dig/contractSize; else t=0;
               if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
               if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
               OpenPrice=o[1];
               dir="SELL";
               trig=true;
              }
           }
        }
     // if(LongBuffer[0]<LongBuffer[1] && ShortBuffer[0]<LongBuffer[0] && ShortBuffer[1]>LongBuffer[1])
       if (signal2 == OP_BUY)
        {
         if(trig==false)
           {
            CopyOpen(s,tf,from,count,o);
            OpenPrice=o[1];
            dir="BUY";
            trig=true;
           }
         else
           {
            if(dir=="SELL")
              {
               CopyOpen(s,tf,from,count,o);
               if(t>0) t=t+t*optF*leverage*(OpenPrice-o[1])*dig/contractSize; else t=0;
               if(t>maxt) {maxt=t; aDD=0;} else if((maxt-t)>aDD) aDD=maxt-t;
               if((maxt>0) && (aDD/maxt>rDD)) rDD=aDD/maxt;
               OpenPrice=o[1];
               dir="BUY";
               trig=true;
              }
           }
        }
     }
   if(rDD<=traindd) ff=t; else ff=0.0;
   AmountStartsFF++;
   Colony[0][chromos]=ff;
  }
//+------------------------------------------------------------------+
//| ServiceFunction                                                  |
//+------------------------------------------------------------------+
void GenOptimosator::ServiceFunction()
  {
  }
//+------------------------------------------------------------------+
//| ���������� � ����� ������������� ������������                    |
//+------------------------------------------------------------------+
void GenOptimosator::GA()
  {
//--- ���-�� ����� (����� ���-�� �������������� ����������, 
//--- ���� �� ���������� �� �������� ��������� � FitnessFunction())
   GeneCount=OptParamCount+2;
//--- ���-�� �������� � �������
   ChromosomeCount=GeneCount*11;
//--- ������� ��������� ������
   RangeMinimum=0.0;
//--- �������� ��������� ������
   RangeMaximum=1.0;
//--- ��� ������
   Precision=0.0001;
//--- 1-�������, ����� ������-��������
   OptimizeMethod=2;
   ArrayResize(Chromosome,GeneCount+1);
   ArrayInitialize(Chromosome,0);
//--- ���-�� ���� ��� ���������
   Epoch=100;
//--- ���� ����������, ������������ �������, ������������� �������, ������������� �����, 
//--- �������������, ����������� �������� ������ ���������, ����������� ������� ������� ���� � %
   UGA(100.0,1.0,1.0,1.0,1.0,0.5,1.0);
  }
//+------------------------------------------------------------------+
//| �������� ���������������� ��������� ���������                    |
//| � ������ ����������; ������ ������ ���� ����� ���-�� �����       |
//+------------------------------------------------------------------+
void GenOptimosator::GetTrainResults() //
  {
//--- ������������� ����� ����� �������� ����� � ��������������� �����������
   int z;
   
 //  MAshort=iMA(s,tf,(int)MathRound(Chromosome[1]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
 //  MAlong =iMA(s,tf,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1,0,MODE_SMA,PRICE_OPEN);
   
   trade_block.UpdateHandle(SLOW_EMA,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1);   //������ ������ �����������
   trade_block.UpdateHandle(SLOW_EMA,(int)MathRound(Chromosome[2]*MaxMAPeriod)+1);
   
   trade_block.UploadBuffers(from);  //�������� ������
   
// CopyBuffer(MAshort,0,from,count,ShortBuffer);
//   CopyBuffer(MAlong,0,from,count,LongBuffer);
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
  
  GenOptimosator::GenOptimosator(void)  //����������� ������
   {
ChromosomeCount=0;             //����������� ��������� ���������� �������� � �������
TotalOfChromosomesInHistory=0; //����� ���������� �������� � �������
ChrCountInHistory=0;           //���������� ���������� �������� � ���� ��������
GeneCount=0;                   //���������� ����� � ���������
RangeMinimum=0.0;              //������� ��������� ������
RangeMaximum=0.0;              //�������� ��������� ������
Precision=0.0;                 //��� ������
OptimizeMethod=0;              //1-�������, ����� ������ - ��������
PopulChromosCount=0;           //������� ���������� �������� � ���������
Epoch=0;                       //���-�� ���� ��� ���������
AmountStartsFF=0;              //���������� �������� ������� �����������������
cap=10000;                     // ��������� �������
optF=0.3;                      // ����������� F
OptParamCount=2;               // ���-�� �������������� ����������
MaxMAPeriod=250;               // ������������ ������ ���������� �������
depth=250;                     // ������� ������� (�� ��������� - 250, ���� ���� ���� - �������� � �������������� ��������/�������)
from=0;                        // ������ �������� ���������� (����������� ���������������� ����� ������ ���������� � ������� InitFirstLayer())
count=2;                       // ������� �� ��� �������� (�� ��������� - 2, ���� ���� ���� - �������� � �������������� ��������/�������)
ERROR=0.0;                     // ������� ������ �� ��� (��� ���  
s="EURUSD";                    // ����
tf=PERIOD_D1;                  // ���������
   }