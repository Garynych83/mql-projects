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

#include <StringUtilities.mqh>
#include <CLog.mqh>

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

class CBlowInfoFromExtremums
 {
  private:
   // ������ ������
   double   _extrBufferHigh[];  // ����� ������� �����������
   double   _extrBufferLow [];  // ����� ������ ����������
   datetime _timeBufferHigh[];  // ����� ��������� ������� �����������
   datetime _timeBufferLow [];  // ����� ��������� ������ �����������
   // ��������� ���� ������
   int _handleExtremums;        // ����� ���������� DrawExtremums   
   int _historyDepth;           // ������� �������
   string _symbol;              // ������
   ENUM_TIMEFRAMES _period;     // ������
   int _symbolCode;             // ��� ������� ����������
  public:
  // ������ ������
   bool IsInitFine ();                                                                         // ���������, ������ �� ����������������� ������   
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,datetime start_time=0,int historyDepth=1000); // ������� ��������� ����������
   Extr GetExtrByIndex (ENUM_EXTR_USE extr_use,int extr_index);                                // ���������� �������� ���������� �� �������
   ENUM_EXTR_USE GetLastExtrType ();                                                           // ���������� ��� ���������� ����������
   string ShowExtrType (ENUM_EXTR_USE extr_use);                                               // ���������� � ���� ������ ��� ����������� 
  // ������������ � �����������
  CBlowInfoFromExtremums (string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,int periodATR=30,int period_average_ATR=1,int symbolCode=217);
 ~CBlowInfoFromExtremums ();
 };
 
 // ����������� ������� ������
 
 bool CBlowInfoFromExtremums::IsInitFine(void)   // ��������� ������������ ������������� �������
  {
   if (_handleExtremums == INVALID_HANDLE)
    {
    // Print("������ ������������� ������ CBlowInfoFromExtremums. �� ������� ������� ����� ���������� DrawExtremums");
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������������� ������ CBlowInfoFromExtremums. �� ������� ������� ����� ���������� DrawExtremums", MakeFunctionPrefix(__FUNCTION__)));     
     return(false);
    }
   return(true);
  }
 
 bool CBlowInfoFromExtremums::Upload(ENUM_EXTR_USE extr_use=EXTR_BOTH,datetime start_time=0,int historyDepth=1000)       // ��������� ������ �����������
  {
   int copiedHigh     = historyDepth;
   int copiedLow      = historyDepth;
   int copiedHighTime = historyDepth;
   int copiedLowTime  = historyDepth;
   _historyDepth = historyDepth;
    if (extr_use == EXTR_NO)
     return (false);
     
      for (int attempts = 0; attempts < 25; attempts ++)
       {
       if (extr_use != EXTR_LOW) 
         {      
          copiedHigh     = CopyBuffer(_handleExtremums,0,start_time,historyDepth,_extrBufferHigh);
          copiedHighTime = CopyTime  (_symbol,_period,start_time,historyDepth,_timeBufferHigh);
          
         }
       if (extr_use != EXTR_HIGH) 
         {
          copiedLow      = CopyBuffer(_handleExtremums,1,start_time,historyDepth,_extrBufferLow); 
          copiedLowTime  = CopyTime  (_symbol,_period,start_time,historyDepth,_timeBufferLow);
          
          
         }
        Sleep(1000);
       }
      // Print("copiedHIGH = ",copiedHigh," copiedHighTime = ",copiedHighTime, " PERIOD = ",PeriodToString(_period));
      // Print("copiedLOW = ",copiedLow," copiedLowTime = ",copiedLowTime, " PERIOD = ",PeriodToString(_period));
      if ( copiedHigh != historyDepth || copiedLow != historyDepth || copiedHighTime != historyDepth || copiedLowTime != historyDepth)
       {
     //   Print("������ ������ Upload ������ CExtremums. �� ������� ���������� ������ ���������� DrawExtremums ",PeriodToString(_period));
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ������ ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);
       }
       
   return (true);
  }
  
 Extr CBlowInfoFromExtremums::GetExtrByIndex(ENUM_EXTR_USE extr_use,int extr_index)  // �������� �������� ���������� �� �������
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
  
   
   ENUM_EXTR_USE CBlowInfoFromExtremums::GetLastExtrType(void)
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
  
   
   string CBlowInfoFromExtremums::ShowExtrType(ENUM_EXTR_USE extr_use)  // ���������� � ���� ������ ��� �����������
    {
     switch (extr_use)
      {
       case EXTR_BOTH:
        return "��� ���� �����������";
       break;
       case EXTR_HIGH:
        return "������� ����������";
       break;
       case EXTR_LOW:
        return "������ ����������";
       break;
       case EXTR_NO:
        return "��� ����������";
       break;
      }
     return "";
    }
   

   CBlowInfoFromExtremums::CBlowInfoFromExtremums(string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,int periodATR=30,int period_average_ATR=1,int symbolCode=217)   // ����������� ������ 
    {
     _historyDepth = historyDepth;
     _symbol       = symbol;
     _period       = period;
     _symbolCode   = symbolCode;
     _handleExtremums = iCustom(symbol,period,"DrawExtremums",period,historyDepth,periodATR,period_average_ATR,symbolCode);
    }
    
   CBlowInfoFromExtremums::~CBlowInfoFromExtremums(void)   // ���������� ������
    {
     ArrayFree(_extrBufferHigh);
     ArrayFree(_extrBufferLow);
     IndicatorRelease(_handleExtremums);
    }