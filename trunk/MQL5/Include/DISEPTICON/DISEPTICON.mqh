//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// ����������� ���������

#include <TradeManager/TradeManager.mqh>    // �������� ����������
#include "STRUCTS.mqh"                      // ���������� �������� ������ ��� ��������� ��������

// ����� �����������
class DISEPTICON
 { 
  private:
   // ��������� ������ ������ �����������
   ENUM_TIMEFRAMES eldTF;
   ENUM_TIMEFRAMES jrTF;      
   
   
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