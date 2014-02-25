//+------------------------------------------------------------------+
//|                                                    CExpertID.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <GlobalVariable.mqh>
#include <StringUtilities.mqh>
//+------------------------------------------------------------------+
//| ����� ��� �������� ���������� ���������� ���������� ���������    |
//+------------------------------------------------------------------+

// ������������ ������� �������� ��������
enum  TRADE_MODE 
 {
  TM_NO_DEALS     = 0,
  TM_DEAL_DONE    = 1,
  TM_CANNOT_TRADE = 2
 };

class CExpertID: public CGlobalVariable 
 {
  public:
  // ��������� ������ ������
  bool IsContinue();    // ���������� ������ � ���, ����� �� ���������� �������� ��� ���  
  // ����� ������ ���������� � ���, ��� ���� ��������� ������
  void DealDone() { IntValue(TM_DEAL_DONE); };
  // ����������� ������ ���������� ���������� ��������
  CExpertID(string expert_name,string symbol,ENUM_TIMEFRAMES period);   
  // ���������� ������ 
 ~CExpertID();
 };
 // ���������� ������ � ���, ����� �� ���������� �������� ��� ���
 bool CExpertID::IsContinue(void)
  {
   // ���� �������� �� ��� ������������� 
   if ( IntValue() != TM_CANNOT_TRADE )
    return true;
   return false;
  }
 // ����������� ������
 CExpertID::CExpertID(string expert_name,string symbol,ENUM_TIMEFRAMES period)
  {
   string var_name = "&"+expert_name+"_"+symbol+"_"+PeriodToString(period); // ��������� ��� ����������   
   Name(var_name); // ��������� ����������
   IntValue(TM_NO_DEALS);    // ������ �������� 1 (����� ������� � ����� ���������)
  }
  
 // ���������� ������
 CExpertID::~CExpertID(void)
  {
   Delete(); // ������� ����������
  }