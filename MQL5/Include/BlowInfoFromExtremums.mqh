//+------------------------------------------------------------------+
//|                                                   CExtremums.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//|  �����  ��� ��������� ������ ���������� DrawExtremums            |
//+------------------------------------------------------------------+

enum ENUM_EXTR_USE
 {
  EXTR_HIGH = 0,
  EXTR_LOW,
  EXTR_BOTH
 };

class CBlowInfoFromExtremums
 {
  private:
   // ������ ������
   double _extrBufferHigh[]; // ����� ������� �����������
   double _extrBufferLow[];  // ����� ������ ����������
   // ��������� ���� ������
   int _handleExtremums;    // ����� ���������� DrawExtremums    
  public:
  // ������ ������
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_index=0,int historyDepth=100); // ������� ��������� ����������
  // ������������ � �����������
  CBlowInfoFromExtremums (string symbol,ENUM_TIMEFRAMES period);
  CBlowInfoFromExtremums (int handle): _handleExtremums(handle) {};
 ~CBlowInfoFromExtremums ();
 };
 
 // ����������� ������� ������
 
 bool CBlowInfoFromExtremums::Upload(ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_index=0,int historyDepth=100)       // ��������� ������ �����������
  {
   int copiedHigh = historyDepth;
   int copiedLow  = historyDepth;
      for (int attempts = 0; attempts < 5; attempts ++)
       {
       if (extr_use != EXTR_LOW)  copiedHigh = CopyBuffer(_handleExtremums,0,start_index,historyDepth,_extrBufferHigh);
       if (extr_use != EXTR_HIGH) copiedLow  = CopyBuffer(_handleExtremums,1,start_index,historyDepth,_extrBufferLow);
        Sleep(100);
       }
   if ( copiedHigh != historyDepth || copiedLow != historyDepth)
    {
     Print("������ ������ Upload ������ CExtremums. �� ������� ���������� ������ ���������� DrawExtremums");
     return (false);
    }
   return (true);
  }