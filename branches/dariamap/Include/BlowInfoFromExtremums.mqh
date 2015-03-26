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

#include <Object.mqh>
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

class CBlowInfoFromExtremums : public CObject
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
  public:
  // ������ ������
   int  GetExtrCountHigh() { return( int(_extrCountHigh[0]) ); };                              // ���������� ���������� ����������� HIGH
   int  GetExtrCountLow()  { return ( int(_extrCountLow[0]) ); };                              // ���������� ���������� ����������� LOW
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,datetime start_time=0,int historyDepth = 1000); // ������� ��������� ���������� �� �������
   bool Upload (ENUM_EXTR_USE extr_use=EXTR_BOTH,int start_pos=0,int historyDepth = 1000);       // ������� ��������� ���������� �� �������
   Extr GetExtrByIndex (ENUM_EXTR_USE extr_use,int extr_index);                                // ���������� �������� ���������� �� �������
   ENUM_EXTR_USE GetLastExtrType ();                                                           // ���������� ��� ���������� ����������
   ENUM_EXTR_USE GetPrevExtrType ();                                                           // ���������� ��� �������������� ����������   
   string ShowExtrType (ENUM_EXTR_USE extr_use);                                               // ���������� � ���� ������ ��� ����������� 
  // ������������ � �����������
  CBlowInfoFromExtremums (int handleExtremums, int historyDepth = 1000);
 ~CBlowInfoFromExtremums ();
 };
 
 // ����������� ������� ������
bool CBlowInfoFromExtremums::Upload(ENUM_EXTR_USE extr_use = EXTR_BOTH,datetime start_time = 0,int historyDepth = 1000)       // ��������� ������ �����������
{
 int copiedHigh = historyDepth;
 int copiedLow  = historyDepth;
 int c1 = 0;
 int c2 = 0;
 int c3 = 0;
 int c4 = 0;
 int attempts = 0;
 
 _historyDepth = historyDepth;
 if (extr_use == EXTR_NO)
  return (false);
 
 while (c1 < 1 && c2 < 1 && c3 < 1 && c4 < 1 && attempts < 5 && !IsStopped())
 {
  c1 = CopyBuffer(_handleExtremums, 2, 0, 1, _lastExtrSignal);
  c2 = CopyBuffer(_handleExtremums, 3, 0, 1, _prevExtrSignal);
  c3 = CopyBuffer(_handleExtremums, 4, 0, 1, _extrCountHigh); 
  c4 = CopyBuffer(_handleExtremums, 5, 0, 1, _extrCountLow);
  attempts++;
  Sleep(111);
 }  
 
 if (c1 != 1 || c2 != 1 || c3 != 1 || c4 != 1)     
 {
  //log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ����� ���������� DrawExtremums _handleExtremums= %d", MakeFunctionPrefix(__FUNCTION__), _handleExtremums));           
  return (false);           
 }

 
 if (extr_use != EXTR_LOW) 
 {      
  copiedHigh = CopyBuffer(_handleExtremums, 0, start_time, historyDepth, _extrBufferHigh);          
 }
 if (extr_use != EXTR_HIGH) 
 {
  copiedLow = CopyBuffer(_handleExtremums, 1, start_time, historyDepth, _extrBufferLow); 
 }
 
 if ( copiedHigh != historyDepth || copiedLow != historyDepth )
 {
  Print("copiedHigh != historyDepth || copiedLow != historyDepth");
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ������ ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
  return (false);
 }
 return (true);
}
  
bool CBlowInfoFromExtremums::Upload(ENUM_EXTR_USE extr_use = EXTR_BOTH, int start_pos = 0, int historyDepth = 1000)       // ��������� ������ �����������
{
 int copiedHigh = historyDepth;
 int copiedLow  = historyDepth;
 
 _historyDepth = historyDepth;
 if (extr_use == EXTR_NO)
  return (false);
  
 if ( CopyBuffer(_handleExtremums, 2, 0, 1, _lastExtrSignal) < 1
   || CopyBuffer(_handleExtremums, 3, 0, 1, _prevExtrSignal) < 1
   || CopyBuffer(_handleExtremums, 4, 0, 1, _extrCountHigh)  < 1 
   || CopyBuffer(_handleExtremums, 5, 0, 1, _extrCountLow)   < 1)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
  return (false);           
 }  
             
 if (extr_use != EXTR_LOW) 
 {      
  copiedHigh = CopyBuffer(_handleExtremums, 0, start_pos, historyDepth, _extrBufferHigh);          
 }
 if (extr_use != EXTR_HIGH) 
 {
  copiedLow = CopyBuffer(_handleExtremums, 1, start_pos, historyDepth, _extrBufferLow); 
 }
 
 if ( copiedHigh != historyDepth || copiedLow != historyDepth )
 {
  //log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ������ ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
  return (false);
 }
 return (true);
}  
  
Extr CBlowInfoFromExtremums::GetExtrByIndex(ENUM_EXTR_USE extr_use, int extr_index)  // �������� �������� ���������� �� �������
{
 int countExtr = -1;  // ������� �������� �����������
 int index;           // ������ ������� �� �����
 Extr extr = {0,0};   // ���������
 
 if (extr_use == EXTR_HIGH)
 {
  // �������� �� ����� ������
  for (index = _historyDepth-1; index > 0; index--)
  {
   // ���� � ������ ������ ���������
   if (_extrBufferHigh[index] != 0)
   {
    countExtr ++;  
    // ���� ����� ��������� �� ������� 
    if (countExtr == extr_index)
    {
     extr.price = _extrBufferHigh[index];
    }
   }
  }
 }
 else if (extr_use == EXTR_LOW)
 {
  // �������� �� ����� ������
  for (index = _historyDepth-1; index > 0; index--)
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
 if(Upload(EXTR_BOTH, TimeCurrent(), 1000))
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
 if(Upload(EXTR_BOTH, TimeCurrent(), 1000))
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
  case EXTR_HIGH:
   return "������� ����������";
  case EXTR_LOW:
   return "������ ����������";
  case EXTR_NO:
   return "��� ����������";
 }
 return "";
}
   
CBlowInfoFromExtremums::CBlowInfoFromExtremums(int handleExtremums, int historyDepth = 1000)   // ����������� ������ 
{
 _historyDepth = historyDepth;
 _handleExtremums = handleExtremums;
 Upload(EXTR_BOTH, TimeCurrent(), 1000);
}
    
CBlowInfoFromExtremums::~CBlowInfoFromExtremums(void)   // ���������� ������
{
 ArrayFree(_extrBufferHigh);
 ArrayFree(_extrBufferLow);
}