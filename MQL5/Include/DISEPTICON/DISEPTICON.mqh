//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// ����������� ���������

#include <TradeManager/TradeManager.mqh>    // �������� ����������

// ����� �����������
class DISEPTICON
 { 
  private:
   // ��������� ������ ������ �����������
   ENUM_TIMEFRAMES eldTF = PERIOD_H1;
   ENUM_TIMEFRAMES jrTF  = PERIOD_M5;      
   
   
  public:
  // ������ 
  
  // ������������ � ����������� ������ �����������
  DISEPTICON (); // ����������� ������
 ~DISEPTICON (); // ���������� ������ 
 };
 
 // ����������� ������������ � �����������
 
 // ����������� ������ �����������
 DISEPTICON::DISEPTICON(void)
  {
   // �������������� ���������, ������, ���������� � ������
  }
  
 // ���������� ������ �����������
 
 DISEPTICON::~DISEPTICON(void)
  {
  
  }