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
   double   _lastExtrSignal[];  // ����� ���������� ��������������� ���������� ����������
   double   _prevExtrSignal[];  // ����� �������������� ����������
   double   _extrCountHigh [];  // ������� ����������� HIGH
   double   _extrCountLow  [];  // ������� ����������� LOW
   // ��������� ���� ������
   int _handleExtremums;        // ����� ���������� DrawExtremums   
   int _historyDepth;           // ������� �������
   string _symbol;              // ������
   ENUM_TIMEFRAMES _period;     // ������
  public:
  // ������ ������
   int  GetExtrCountHigh() { return( int(_extrCountHigh[0]) ); };                              // ���������� ���������� ����������� HIGH
   int  GetExtrCountLow()  { return ( int(_extrCountLow[0]) ); };                              // ���������� ���������� ����������� LOW
   bool IsInitFine ();                                                                         // ���������, ������ �� ����������������� ������   
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,datetime start_time=0,int historyDepth=1000); // ������� ��������� ���������� �� �������
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_pos=0,int historyDepth=1000);       // ������� ��������� ���������� �� �������
   Extr GetExtrByIndex (ENUM_EXTR_USE extr_use,int extr_index);                                // ���������� �������� ���������� �� �������
   ENUM_EXTR_USE GetLastExtrType ();                                                           // ���������� ��� ���������� ����������
   ENUM_EXTR_USE GetPrevExtrType ();                                                           // ���������� ��� �������������� ����������   
   string ShowExtrType (ENUM_EXTR_USE extr_use);                                               // ���������� � ���� ������ ��� ����������� 
  // ������������ � �����������
  CBlowInfoFromExtremums (string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,int periodATR=30,int period_average_ATR=100);
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
   _historyDepth = historyDepth;
    if (extr_use == EXTR_NO)
     return (false);
      if ( CopyBuffer(_handleExtremums,2,0,1,_lastExtrSignal) < 1 )
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);       
       }
      if ( CopyBuffer(_handleExtremums,3,0,1,_prevExtrSignal) < 1 )
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);       
       }       
      if ( CopyBuffer(_handleExtremums,4,0,1,_extrCountHigh) < 1 )
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);           
       }
      if ( CopyBuffer(_handleExtremums,5,0,1,_extrCountLow) < 1 )
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);           
       }       
      for (int attempts = 0; attempts < 25; attempts ++)
       {
       if (extr_use != EXTR_LOW) 
         {      
          copiedHigh     = CopyBuffer(_handleExtremums,0,start_time,historyDepth,_extrBufferHigh);       
         }
       if (extr_use != EXTR_HIGH) 
         {
          copiedLow      = CopyBuffer(_handleExtremums,1,start_time,historyDepth,_extrBufferLow);  
         }
       }
      if ( copiedHigh != historyDepth || copiedLow != historyDepth )
       {
     //   Print("������ ������ Upload ������ CExtremums. �� ������� ���������� ������ ���������� DrawExtremums ",PeriodToString(_period));
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ������ ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);
       }
       
   return (true);
  }
  
 bool CBlowInfoFromExtremums::Upload(ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_pos=0,int historyDepth=1000)       // ��������� ������ �����������
  {
   int copiedHigh     = historyDepth;
   int copiedLow      = historyDepth;
   
   _historyDepth = historyDepth;
    if (extr_use == EXTR_NO)
     return (false);
      if ( CopyBuffer(_handleExtremums,2,0,1,_lastExtrSignal) < 1 )
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);       
       }
      if ( CopyBuffer(_handleExtremums,3,0,1,_prevExtrSignal) < 1 )
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);       
       }         
      if ( CopyBuffer(_handleExtremums,4,0,1,_extrCountHigh) < 1 )
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);           
       }   
      if ( CopyBuffer(_handleExtremums,5,0,1,_extrCountLow) < 1 )
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ Upload ������ CExtremums. �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
        return (false);           
       }              
      for (int attempts = 0; attempts < 25; attempts ++)
       {
       if (extr_use != EXTR_LOW) 
         {      
          copiedHigh     = CopyBuffer(_handleExtremums,0,start_pos,historyDepth,_extrBufferHigh);          
         }
       if (extr_use != EXTR_HIGH) 
         {
          copiedLow      = CopyBuffer(_handleExtremums,1,start_pos,historyDepth,_extrBufferLow); 
         }
       }
      if ( copiedHigh != historyDepth || copiedLow != historyDepth )
       {
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
            return (extr); 
           }
        }
      }      
     }
     
   return (extr);
  }  
   
   ENUM_EXTR_USE CBlowInfoFromExtremums::GetLastExtrType(void)
    {
     switch ( int(_lastExtrSignal[0]) )
      {
       case 1:
        return EXTR_HIGH;
       case -1:
        return EXTR_LOW;
      }
     return EXTR_NO;
    }
  
   ENUM_EXTR_USE CBlowInfoFromExtremums::GetPrevExtrType(void)
    {
     switch ( int(_prevExtrSignal[0]) )
      {
       case 1:
        return EXTR_HIGH;
       case -1:
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
   

   CBlowInfoFromExtremums::CBlowInfoFromExtremums(string symbol,ENUM_TIMEFRAMES period,int historyDepth=1000,int periodATR=30,int period_average_ATR=100)   // ����������� ������ 
    {
     _historyDepth = historyDepth;
     _symbol       = symbol;
     _period       = period;
     _handleExtremums = iCustom(symbol,period,"DrawExtremums",period,historyDepth,periodATR,period_average_ATR);
    }
    
   CBlowInfoFromExtremums::~CBlowInfoFromExtremums(void)   // ���������� ������
    {
     ArrayFree(_extrBufferHigh);
     ArrayFree(_extrBufferLow);
     IndicatorRelease(_handleExtremums);
    }