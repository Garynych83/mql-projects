//+------------------------------------------------------------------+
//|                                                       JYumie.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// ���������� ����������� ����������
#include <CExtremum.mqh>   // ��� ���������� �����������

//+------------------------------------------------------------------+
//| ����� ���������� Yumie                                           |
//+------------------------------------------------------------------+

class CYumie 
 {
  private:
   // ��������� ������ 
   SExtremum        _extremums[];      // ����� �����������
   double           _high[];           // ����� ������� ���
   double           _low[];            // ����� ������ ���
   // ��������� ���� ������
   // 1) ��������� ��������� 
   string           _symbol;           // ������
   ENUM_TIMEFRAMES  _period;           // ������
   double           _difToNewExtremum; // ������� �� ���� ����� ������������
   int              _historyDepth;     // ������� �������, �� ������� ����������� ������
   
  public:
   // ������ ������
   
   // ������������ � ����������� ������
   CYumie ();                   // ����������� ������ Yumie
  ~CYumie ();                   // ���������� ������
 };
 
 // �������� ������� 
 
 
 // �������� ������������� � ������������
 
 CYumie::CYumie(void)           // ���������� ������
  {
   
  }
  
 CYumie::~CYumie(void)          // ���������� ������
  {
   // ������� ������ 
   ArrayFree (_extremums);
   ArrayFree (_high);
   ArrayFree (_low);
  }