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

class CExpertID: public CGlobalVariable 
 {
  private:

  public:
  // ��������� ������ ������
  bool IsContinue();    // ���������� ������ � ���, ����� �� ���������� �������� ��� ���
  // ����������� ������ ���������� ���������� ��������
  CExpertID(string expert_name,string symbol,ENUM_TIMEFRAMES period);   
  // ���������� ������ 
 ~CExpertID();
 };
 // ���������� ������ � ���, ����� �� ���������� �������� ��� ���
 bool CExpertID::IsContinue(void)
  {
   // ���� �������� �� ��� ������������� 
   if ( IntValue() != 0 )
    return true;
   return false;
  }
 
 // ����������� ������
 CExpertID::CExpertID(string expert_name,string symbol,ENUM_TIMEFRAMES period)
  {
   string var_name = "&"+expert_name+"_"+symbol+"_"+PeriodToString(period); // ��������� ��� ����������   
   Name(var_name); // ��������� ����������
   IntValue(2);    // ������ �������� 1 (����� ������� � ����� ���������)
  }
  
 // ���������� ������
 CExpertID::~CExpertID(void)
  {
   Delete(); // ������� ����������
  }