//+------------------------------------------------------------------+
//|                                               CExtrContainer.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| �����-��������� �����������                                      |
//+------------------------------------------------------------------+

// ���������� ����������� ����������
#include "SExtremum.mqh"      // ��������� �����������
#include <CLog.mqh>           // ��� ����
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����

class CExtrContainer 
 {
  private:
   // ����� �����������
   SExtremum       _bufferFormedExtr[];      // ����� ��� �������� �������������� �����������
   SExtremum       _bufferExtr[];            // ����� ��� �������� ���� ����������� � �������   
   SExtremum       _lastExtr;                // ��������� ������������� ���������
   // ��������� ���� ������
   int             _handleDE;                // ����� ���������� DrawExtremums
   datetime        _lastTimeUploadedFormed;  // ��������� ����� �������� �������������� �����������
   datetime        _lastTimeUploaded;        // ��������� ����� �������� ����������� � ���������
   string          _symbol;                  // ������
   ENUM_TIMEFRAMES _period;                  // ������
   int             _countFormedExtr;         // ���������� �������������� �����������
   int             _countExtr;               // ���������� ����� ����������� �����������
   int             _prevBars;                // ���������� ���������� ������������� �����
  public:
   CExtrContainer(string symbol,ENUM_TIMEFRAMES period,int handleDE);                                   // ����������� ������ ���������� �����������
  ~CExtrContainer();                                                                                    // ���������� ������ ���������� �����������
   // ������ ������
   bool         UploadFormedExtremums   (bool useIndi=false);                                           // ����� ��������� ����� �������������� ����������
   bool         UploadExtremums         (bool useIndi=false);                                           // ����� ��������� ����� ����������
   SExtremum    GetExtremum             (int index,bool useFormedExtr=true);                            // �������� ��������� �� �������
   SExtremum    GetExtremumClean        (int startRealIndex,int index);                                 // ����� ��� ������� ������� � ����������� �� �������
   SExtremum    GetLastExtremum   () { return (_bufferExtr[_countExtr-1]); };                           // �������� �������� ���������� �������������� ����������
   void         AddNewExtr        (double price,datetime time, int direction,bool useFormedExtr=true);  // ��������� ����� ��������� � ����� ����������
   void         UpdateLastExtr    (double price,datetime time, int direction);                          // ��������� ��������� ������������� ���������
   int          GetIndexByTime    (datetime time,bool useFormedExtr=true);                              // ���������� ������ ���������� � ������ �� ���� 
   int          GetCountFormedExtr() { return (_countFormedExtr); };                                    // ���������� ���������� �������������� �����������  
   int          GetCountExtr      () { return (_countExtr); };                                          // ���������� ���������� �����������
   void         PrintExtremums ();
 };
 
 // ����������� ������� ������
 CExtrContainer::CExtrContainer(string symbol, ENUM_TIMEFRAMES period,int handleDE)                     // ����������� ������
  {
   // ��������� ��������� �����, �� ������� ����� ��������� ����������
   _lastTimeUploadedFormed = 0;
   _lastTimeUploaded = 0;
   _symbol = symbol;
   _period = period;
   _handleDE = handleDE;
   _countFormedExtr = 0;
   _countExtr = 0;
   _prevBars = 0;
  }
  
 CExtrContainer::~CExtrContainer() // ���������� ������
  {
   // ������������ ������� ������
   ArrayFree(_bufferFormedExtr);
   ArrayFree(_bufferExtr);
  }
  
 bool CExtrContainer::UploadFormedExtremums(bool useIndi=false)  // ����� ��������� ����� �������������� ����������
  {
   double bufHigh[];         // ����� ������� �����������
   double bufLow[];          // ����� ������ �����������
   double bufTimeHigh[];     // ����� ������� ������� �����������
   double bufTimeLow[];      // ����� ������� ������ �����������
   int attempts;             // ���������� ������� �������� ������������ �������
   int copiedHigh,copiedLow,copiedTimeHigh,copiedTimeLow; // ���������� ������������� ��������� ������
   int ind;                  // ������� ������� �� ������
   int bars;
   if (useIndi)
    attempts = 1;
   else
    attempts = 25; 
   bars = Bars(_symbol,_period);
   for (ind=0;ind<attempts;ind++)
    {
     copiedHigh      =  CopyBuffer(_handleDE,0,0,bars,bufHigh);
     copiedLow       =  CopyBuffer(_handleDE,1,0,bars,bufLow);
     copiedTimeHigh  =  CopyBuffer(_handleDE,4,0,bars,bufTimeHigh);
     copiedTimeLow   =  CopyBuffer(_handleDE,5,0,bars,bufTimeLow);
     Sleep(1000);
    }
   if (copiedHigh < bars || copiedLow < bars || copiedTimeHigh < bars || copiedTimeLow < bars)
    {
     Print("������ ������ CExtrContainer. �� ������� ���������� ��� ������");
     return (false);
    }
    // �������� �� ����� � ��������� ������ �����������
   for (ind=0;ind<bars;ind++)
    {
     // ���� ������ ������� ���������
     if (bufHigh[ind] != 0 && bufLow[ind] == 0)
      {
       ArrayResize(_bufferFormedExtr,_countExtr+1);
       _bufferFormedExtr[_countFormedExtr].price = bufHigh[ind];
       _bufferFormedExtr[_countFormedExtr].time  = bufTimeHigh[ind];
       _bufferFormedExtr[_countFormedExtr].direction = 1;
       _countFormedExtr ++;   
      }
     // ���� ������ ������ ���������
     if (bufLow[ind] != 0 && bufHigh[ind] == 0)
      {
       ArrayResize(_bufferFormedExtr,_countFormedExtr+1);
       _bufferFormedExtr[_countFormedExtr].price = bufLow[ind];
       _bufferFormedExtr[_countFormedExtr].time  = bufTimeLow[ind];
       _bufferFormedExtr[_countFormedExtr].direction = -1;
       _countFormedExtr ++;   
      }  
     // ���� ������ ������� � ������ ���������� �� ����� ����
     if (bufHigh[ind] != 0 && bufLow[ind] != 0)
      {
       // �������� ������ ��� ��� ����������
       ArrayResize(_bufferFormedExtr,_countFormedExtr+2);
       // ���� High ������ ������ Low
       if (bufTimeHigh[ind] < bufTimeLow[ind])
        { 
         _bufferFormedExtr[_countFormedExtr].price = bufHigh[ind];
         _bufferFormedExtr[_countFormedExtr].time  = bufTimeHigh[ind];
         _bufferFormedExtr[_countFormedExtr].direction  = 1;
         _bufferFormedExtr[_countFormedExtr+1].price = bufLow[ind];
         _bufferFormedExtr[_countFormedExtr+1].time  = bufTimeLow[ind];
         _bufferFormedExtr[_countFormedExtr+1].direction  = -1;         
        }   
       // ���� Low ������ ������ High
       if (bufTimeHigh[ind] > bufTimeLow[ind])
        { 
         _bufferFormedExtr[_countFormedExtr].price = bufLow[ind];
         _bufferFormedExtr[_countFormedExtr].time  = bufTimeLow[ind];
         _bufferFormedExtr[_countFormedExtr].direction  = -1;
         _bufferFormedExtr[_countFormedExtr+1].price = bufHigh[ind];
         _bufferFormedExtr[_countFormedExtr+1].time  = bufTimeHigh[ind];
         _bufferFormedExtr[_countFormedExtr+1].direction  = 1;         
        }      
       _countFormedExtr = _countFormedExtr + 2;     
      }        
    }
   // ��������� �������� �����
   _lastTimeUploadedFormed = TimeCurrent();
   return (true);
  }
  
 bool CExtrContainer::UploadExtremums(bool useIndi=false)  // ����� ��������� ����� ����������
  {
   double bufHigh[];         // ����� ������� �����������
   double bufLow[];          // ����� ������ �����������
   double bufTimeHigh[];     // ����� ������� ������� �����������
   double bufTimeLow[];      // ����� ������� ������ �����������
   int copiedHigh;           // ���������� ������������� ��������� High
   int copiedLow;            // ���������� ������������� ��������� Low
   int copiedTimeHigh;       // ���������� ������������� ��������� ������� ������� �����������
   int copiedTimeLow;        // ���������� ������������� ��������� ������� ������ �����������
   int ind;                  // ������� ������� �� ������
   int bars;                 // ���������� ����� � �������
   int needToCopyBars;       // ����������, ������� ����� �����������
   // �������� ���������� ����� ����� � �������
   bars = Bars(_symbol,_period);           
   // �������� ���������� �����, ������� ����� ����������� � ��� ��������
   needToCopyBars = bars - _prevBars;
   // �������� ������� ��������
   ArrayResize(_bufferExtr,bars*2);
   // �������� ������ 
   copiedHigh      =  CopyBuffer(_handleDE,2,0,needToCopyBars,bufHigh);
   copiedLow       =  CopyBuffer(_handleDE,3,0,needToCopyBars,bufLow);
   copiedTimeHigh  =  CopyBuffer(_handleDE,4,0,needToCopyBars,bufTimeHigh);
   copiedTimeLow   =  CopyBuffer(_handleDE,5,0,needToCopyBars,bufTimeLow);
   if (copiedHigh < needToCopyBars || copiedLow < needToCopyBars || copiedTimeHigh < needToCopyBars || copiedTimeLow < needToCopyBars)
    {
     Print("������ ������ CExtrContainer. �� ������� ���������� ��� ������");
     return (false);
    }
    // �������� �� ����� � ��������� ������ �����������
   for (ind=0;ind<needToCopyBars;ind++)
    {
     
     // ���� ������ ������� ���������
     if ( bufHigh[ind]!=0.0 && bufLow[ind]==0.0 )
      {
       _bufferExtr[_countExtr].price = bufHigh[ind];
       _bufferExtr[_countExtr].time  = bufTimeHigh[ind];
       _bufferExtr[_countExtr].direction = 1;    
       _countExtr ++;   
      }
     // ���� ������ ������ ���������
     else if (bufLow[ind]!=0.0 && bufHigh[ind]==0.0)
      {
       _bufferExtr[_countExtr].price = bufLow[ind];
       _bufferExtr[_countExtr].time  = bufTimeLow[ind];
       _bufferExtr[_countExtr].direction = -1;       
       _countExtr ++;   

      }  
     // ���� ������ ������� � ������ ���������� �� ����� ����
     else if ( bufHigh[ind]!=0.0 && bufLow[ind]!=0.0 )
      {
       // ���� High ������ ������ Low
       if (bufTimeHigh[ind] < bufTimeLow[ind])
        { 
         _bufferExtr[_countExtr].price = bufHigh[ind];
         
         _bufferExtr[_countExtr].time  = bufTimeHigh[ind];
         _bufferExtr[_countExtr].direction  = 1;
         _bufferExtr[_countExtr+1].price = bufLow[ind];
         _bufferExtr[_countExtr+1].time  = bufTimeLow[ind];
         _bufferExtr[_countExtr+1].direction  = -1;           
        }   
       // ���� Low ������ ������ High
       if (bufTimeHigh[ind] > bufTimeLow[ind])
        { 
         _bufferExtr[_countExtr].price = bufLow[ind];
         _bufferExtr[_countExtr].time  = bufTimeLow[ind];
         _bufferExtr[_countExtr].direction  = -1;
         _bufferExtr[_countExtr+1].price = bufHigh[ind];
         _bufferExtr[_countExtr+1].time  = bufTimeHigh[ind];
         _bufferExtr[_countExtr+1].direction  = 1;                      
        }      
       _countExtr = _countExtr + 2;     
      }        
    }
   // ��������� �������� �����
   _lastTimeUploaded = TimeCurrent();
   // ��������� ��������� �������� ������������� �����
   _prevBars = bars;
   return (true);
  }  
  
 // ����� ���������� ��������� �� ������� 
 SExtremum CExtrContainer::GetExtremum(int index,bool useFormedExtr=true)
  {
    SExtremum nullExtr = {0,0,0};
    // ���� ������������ ������ �������������� ����������
    if (useFormedExtr)
     {
      if (index < 0 || index >= _countFormedExtr)
       {
        Print("������ ������ GetExtrByIndex ������ CExtrContainer. ������ ���������� ��� ���������");
        return (nullExtr);
       }     
      return (_bufferFormedExtr[_countFormedExtr - index - 1]);
     }
    // ���� ������������ ��� ����������
    else
     {
      if (index < 0 || index >= _countExtr)
       {
        Print("������ ������ GetExtrByIndex ������ CExtrContainer. ������ ���������� ��� ���������");
        return (nullExtr);
       }     
      return (_bufferExtr[_countExtr - index - 1]);     
     }
   return (nullExtr); 
  }
  
 // ����� ��� ������� ������� � ����������� �� �������
 SExtremum CExtrContainer::GetExtremumClean(int startRealIndex,int index)
  {
   int ind;
   int countIndex = 0;
   int direction; 
   //Print("_countExtr = ",_countExtr," startRealIndex = ",startRealIndex," ArraySize = ",ArraySize(_bufferExtr) );
   direction = _bufferExtr[_countExtr-startRealIndex-1].direction;
   SExtremum nullExtr = {0,0,0};
   if (index == 0)
    return (_bufferExtr[_countExtr-startRealIndex-1]);
   // �������� �� ����� � ���� ��������� �� �������
   for (ind=startRealIndex;ind<_countExtr;ind++)
    {
     // ���� ������ ��������� � ��������������� ������ 
     if (_bufferExtr[_countExtr-ind-1].direction != direction)
      {
       direction = _bufferExtr[_countExtr-ind-1].direction;        // ��������� ������� ����
       countIndex ++;                                 // ����������� ������� �����������
       // ���� �� ����� ��������� �� ��������� �������
       if (index == countIndex)
        {
         return (_bufferExtr[_countExtr-ind-1]);                   // ���������� ��������� �� �������
        }
      }
    }
   // ���������� ������� ���������
   return (nullExtr);
  } 
  
 // ����� ��������� ����� ��������� � ����� ����������
 void CExtrContainer::AddNewExtr(double price,datetime time,int direction,bool useFormedExtr=true)
  {
   // ���� ������������ ������ �������������� ����������
   if (useFormedExtr)
    {
     // ����������� ������ ����������
     ArrayResize(_bufferFormedExtr,_countFormedExtr+1);
     _bufferFormedExtr[_countFormedExtr].price = price;
     _bufferFormedExtr[_countFormedExtr].time = time;
     _bufferFormedExtr[_countFormedExtr].direction = direction;
     _countFormedExtr ++;
    }
   // ���� ������������ ��� ����������
   else
    {
     // ����������� ������ ����������
     ArrayResize(_bufferExtr,_countExtr+1);
     _bufferExtr[_countExtr].price = price;
     _bufferExtr[_countExtr].time = time;
     _bufferExtr[_countExtr].direction = direction;
     _countExtr ++;    
    }
  }
  
  // ����� ��������� ��������� ������������� ���������
  void CExtrContainer::UpdateLastExtr(double price,datetime time,int direction)
   {
    _lastExtr.price = price;
    _lastExtr.time  = time;
    _lastExtr.direction  = direction;
   }
  
  // ����� ���������� ������ ���������� � ������ �� ������
  int CExtrContainer::GetIndexByTime(datetime time,bool useFormedExtr=true)
   {
    int ind;
    // ���� ������������ ������ �������������� ����������
    if (useFormedExtr)
     {
      // �������� �� ����� ���������� � ���� ���������, ��� ���� ������ ��� ����� ��������
      for (ind=_countFormedExtr-1;ind>=0;ind--)
       { 
        // ���� ����� ����, ������� ������ ��� ����� �������� �������
        if (_bufferFormedExtr[ind].time <= time)
         break;
       }
      // ���� ���� ��� � �����
      if (ind<0)
       return (-1);
      // ���� ���� �� �� �����
      return (_countFormedExtr - ind - 1); 
     }  
    // ���� ������������ ��� ����������
    else
     {
      // �������� �� ����� ���������� � ���� ���������, ��� ���� ������ ��� ����� ��������
      for (ind=_countExtr-1;ind>=0;ind--)
       { 
      //  Print("����� _CountExtr = ",_countExtr," = ",TimeToString(_bufferExtr[ind].time) );
        // ���� ����� ����, ������� ������ ��� ����� �������� �������
        if (_bufferExtr[ind].time <= time)
         break;
       }
      // ���� ���� ��� � �����
      if (ind<0)
       return (-1);
      // ���� ���� �� �� �����
      return (_countExtr - ind - 1); 
     }       
    // ���� ���� �� �� �����
    return (-1);
   }
   
void CExtrContainer::PrintExtremums(void)
 {
  for (int ind=_countExtr-1;ind>0;ind--)
   {
    log_file.Write(LOG_DEBUG,StringFormat("��������� %i (%s,%s)",ind,DoubleToString(_bufferExtr[ind].price),TimeToString(_bufferExtr[ind].time)  ) )  ;      
   }
 }