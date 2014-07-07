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

// ������������ ����� �����������
enum ENUM_EXTR_USE
 {
  EXTR_HIGH = 0,
  EXTR_LOW,
  EXTR_BOTH,
  EXTR_NO
 };

 
   ENUM_EXTR_USE GetLastExtrType(int historyDepth,double &extrBufferHigh[],double &extrBufferLow[])
    {
     // �������� �� ����� ������� ������� �� ������� ����������� ����������
     for (int index=historyDepth-1;index>0;index--)
      {
        if (extrBufferHigh[index] != 0 )  // ���� ������� ��������� ������
         { 
           if (extrBufferLow[index] == 0) // ���� ������� ���������� ���
             return EXTR_HIGH;  
           else 
             continue;                
         }
        if (extrBufferLow[index] != 0)
         return EXTR_LOW;
      } 
      return EXTR_NO;
    }
  