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

// ��������� �������� �����������
struct Extr
 {
  double   price;
  datetime time; 
 };

   bool IsInitFine ();                                                                         // ���������, ������ �� ����������������� ������   
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,datetime start_time=0,int historyDepth=1000); // ������� ��������� ����������
   Extr GetExtrByIndex (ENUM_EXTR_USE extr_use,int extr_index);                                // ���������� �������� ���������� �� �������
   ENUM_EXTR_USE GetLastExtrType ();                                                           // ���������� ��� ���������� ����������
   string ShowExtrType (ENUM_EXTR_USE extr_use);                                               // ���������� � ���� ������ ��� ����������� 
  // ������������ � �����������
  CBlowInfoFromExtremums (string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,double percentageATR=1,int periodATR=30,int period_average_ATR=1);
 ~CBlowInfoFromExtremums ();
 };
 
 // ����������� ������� ������
 
 bool CBlowInfoFromExtremums::IsInitFine(void)   // ��������� ������������ ������������� �������
  {
   if (_handleExtremums == INVALID_HANDLE)
    {
     Print("������ ������������� ������ CBlowInfoFromExtremums. �� ������� ������� ����� ���������� DrawExtremums");
     return(false);
    }
   return(true);
  }
 
  
 Extr GetExtrByIndex(ENUM_EXTR_USE extr_use,int extr_index)  // �������� �������� ���������� �� �������
  {
   int    countExtr = -1;  // ������� �������� �����������
   int    index;           // ������ ������� �� �����
   Extr extr;              // ���������
   extr.price = 0;
   extr.time  = 0;
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
           {
            
            extr.price = _extrBufferHigh[index];
            extr.time  = _timeBufferHigh[index];
            //return (extr); 
           }
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
           {
            extr.price = _extrBufferLow[index];
            extr.time  = _timeBufferLow[index];
            return (extr); 
           }
        }
      }      
     }
     
   return (extr);
  }
  
   
   GetLastExtrType(void)
    {
     // �������� �� ����� ������� ������� �� ������� ����������� ����������
     for (int index=_historyDepth-1;index>0;index--)
      {
        if (_extrBufferHigh[index] != 0 )  // ���� ������� ��������� ������
         { 
           if (_extrBufferLow[index] == 0) // ���� ������� ���������� ���
             return EXTR_HIGH;  
           else 
             continue;                
         }
        if (_extrBufferLow[index] != 0)
         return EXTR_LOW;
      } 
      return EXTR_NO;
    }
  