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
  EXTR_BOTH,
  EXTR_NO
 };

class CBlowInfoFromExtremums
 {
  private:
   // ������ ������
   double _extrBufferHigh[]; // ����� ������� �����������
   double _extrBufferLow[];  // ����� ������ ����������
   // ��������� ���� ������
   int _handleExtremums;     // ����� ���������� DrawExtremums   
   int _historyDepth;        // ������� �������
  public:
  // ������ ������
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_index=0,int historyDepth=100); // ������� ��������� ����������
   double GetExtrByIndex (ENUM_EXTR_USE extr_use,int extr_index);                         // ���������� �������� ���������� �� �������
   ENUM_EXTR_USE GetFirstExtrType ();                                                     // ���������� ��� ���������� ����������
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
    if (extr_use == EXTR_NO)
     return (false);
     
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
  
 double CBlowInfoFromExtremums::GetExtrByIndex(ENUM_EXTR_USE extr_use,int extr_index)  // �������� �������� ���������� �� �������
  {
   int    countExtr = -1;  // ������� �������� �����������
   int    index;           // ������ ������� �� �����
   if (extr_use == EXTR_HIGH)
    {
     // �������� �� ����� ������
     for (index=_historyDepth-1;index>0;index--)
      {
       // ���� � ������ ������ ���������
       if ( _extrBufferHigh[index] != 0 )
        {
          countExtr ++;  
          // ���� ����� ��������� �� ������� 
          if (countExtr == extr_index)
           return (_extrBufferHigh[index]); 
        }
      }
     }
    else if (extr_use == EXTR_LOW)
     {
     // �������� �� ����� ������
     for (index=_historyDepth-1;index>0;index--)
      {
       // ���� � ������ ������ ���������
       if ( _extrBufferLow[index] != 0 )
        {
          countExtr ++;  
          // ���� ����� ��������� �� ������� 
          if (countExtr == extr_index)
           return (_extrBufferLow[index]); 
        }
      }      
     }
     
   return (0.0);
  }
  
  ENUM_EXTR_USE CBlowInfoFromExtremums::GetFirstExtrType(void)  // ���������� ��� ���������� ����������
   {
    int index;
    for (index=_historyDepth-1;index>0;index--)
     {
       if (_extrBufferHigh[index] != 0)
        {
         if (_extrBufferLow[index] != 0)
           return EXTR_BOTH;
          return EXTR_HIGH;
        }
       if (_extrBufferLow[index] != 0)
        return EXTR_LOW;
     }
    return EXTR_NO;
   }