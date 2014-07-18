//+------------------------------------------------------------------+
//|                                                    CTrainLib.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <cUGA/UGALib.mqh>     //���������� ����� �������������� ������������� ���������
//+------------------------------------------------------------------+
//| ����� CTrainLib                                                  |
//+------------------------------------------------------------------+

 class CTrainBlock
  {
   protected:
    double          cap;                     // ��������� �������
    double          optF;                    // ����������� F
    double          contractSize;            // ������ ���������
    double          dig;                     // ���-�� ������ ����� ������� � ��������� (��� ����������� �������� ������ ������� �� �������� ����� � ������ ���-��� ������)    
    double          ERROR;                   // ������� ������ �� ��� (��� ��� ������������� ������������, �������� ��� ����������)
    double          traindd; 
    //-------------------------------------------
    long            leverage;                // ����� �����
    int             OptParamCount;           // ���-�� �������������� ����������
    int             MaxMAPeriod;             // ������������ ������ ���������� �������
    int             depth;                   // ������� ������� (�� ��������� - 250, ���� ���� ���� - �������� � �������������� ��������/�������)
    int             from;                    // ������ �������� ���������� (����������� ���������������� ����� ������ ���������� � ������� InitFirstLayer())
    int             count;                   // ������� �� ��� �������� (�� ��������� - 2, ���� ���� ���� - �������� � �������������� ��������/�������)
    UGA             uGA;                     // ������������� ������������ ��������
    
    string              fn;                  // ��� �����
    int                 handle;              // ������ �� ����������� ����
    string              f;                   // ���-������, ������������ � ����
    string              s;                   // ����
    ENUM_TIMEFRAMES     tf;                  // ���������
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
   public:
    void   InitRelDD();                      // 
    double GetRelDD();                       // 
    double GetPossibleLots();                // 
    //------------------------------------------- 
    void   InitArrays();                     // ������������� ��������
    void   GA();                             // ���������� � ����� ������������� ������������
    void   GetTrainResults();                // ��������� ���������������� ���������� (��� ������� ����)
    void   FitnessFunction(int chromos);     // ������ ������� (��� ������� ����)                 
  };
  
 void CTrainBlock::InitRelDD(void)   
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
  double CTrainBlock::GetRelDD(void)
   {
    if(AccountInfoDouble(ACCOUNT_BALANCE)>maxBalance) maxBalance=AccountInfoDouble(ACCOUNT_BALANCE);
     return((maxBalance-AccountInfoDouble(ACCOUNT_BALANCE))/maxBalance);  
   }
   
  double CTrainBlock::GetPossibleLots(void)
   {
    request.volume=1.0;
    if(request.type==ORDER_TYPE_SELL) request.price=SymbolInfoDouble(s,SYMBOL_BID); else request.price=SymbolInfoDouble(s,SYMBOL_ASK);
     OrderCheck(request,check);
    return(NormalizeDouble(AccountInfoDouble(ACCOUNT_FREEMARGIN)/check.margin,2));   
   }
        
  void CTrainBlock::InitArrays(void)  //������������� ��������
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
   
  void CTrainBlock::GA(void)    //���������� � ����� ������������� ���������
   {
//--- ���-�� ����� (����� ���-�� �������������� ����������, 
//--- ���� �� ���������� �� �������� ��������� � FitnessFunction())
//>>>   GeneCount=OptParamCount+2;
   uGA.UGASetInteger(UGA_GENE_COUNT,OptParamCount+2);
//--- ���-�� �������� � �������
//>>>   ChromosomeCount=GeneCount*11;
   uGA.UGASetInteger(UGA_CHROMOSOME_COUNT,uGA.UGAGetInteger(UGA_GENE_COUNT)*11);
//--- ������� ��������� ������
//>>>   RangeMinimum=0.0;
   uGA.UGASetDouble(UGA_RANGE_MINIMUM,0.0);
//--- �������� ��������� ������
//>>>   RangeMaximum=1.0;
   uGA.UGASetDouble(UGA_RANGE_MAXIMUM,1.0);
//--- ��� ������
//>>>   Precision=0.0001;
   uGA.UGASetDouble(UGA_PRECISION,0.0001);
//--- 1-�������, ����� ������-��������
//>>>   OptimizeMethod=2;
   uGA.UGASetInteger(UGA_OPTIMIZE_METHOD,2);
   
   ArrayResize(uGA.Chromosome,uGA.UGAGetInteger(UGA_GENE_COUNT)+1);
   ArrayInitialize(uGA.Chromosome,0);
//--- ���-�� ���� ��� ���������
//>>>   Epoch=100;
   uGA.UGASetInteger(UGA_EPOCH,100);
//--- ���� ����������, ������������ �������, ������������� �������, ������������� �����, 
//--- �������������, ����������� �������� ������ ���������, ����������� ������� ������� ���� � %
   uGA.RunUGA(100.0,1.0,1.0,1.0,1.0,0.5,1.0);   
   } 
    
