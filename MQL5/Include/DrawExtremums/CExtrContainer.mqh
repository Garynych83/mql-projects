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
   SExtremum       _bufferExtr[4];           // ������ ��� �������� �����������  
   // ��������� ���� ������
   int             _handleDE;                // ����� ���������� DrawExtremums
   string          _symbol;                  // ������
   ENUM_TIMEFRAMES _period;                  // ������
   int             _countFormedExtr;         // ���������� �������������� �����������
   
   public:
   CExtrContainer(string symbol,ENUM_TIMEFRAMES period,int handleDE);                  // ����������� ������ ���������� �����������
  ~CExtrContainer();                                                                   // ���������� ������ ���������� �����������
  
   // ������ ������
   void         AddExtrToContainer(SExtremum &extr);                            // ��������� ��������� � ���������
   void         AddExtrToContainer(int direction,double price,datetime time);   // ��������� ��������� � ��������� �� ����������� ����������, ���� � ������� 
   SExtremum    MakeExtremum (double price, datetime time, int direction);      // ��������� �� ������ ��������� ����������
   SExtremum    GetExtremum (int index);                                        // �������� ��������� �� �������
   bool         AddNewExtr (datetime time);                                     // ��������� ����� ��������� � �������� ����
   int          GetCountFormedExtr() {return (_countFormedExtr);};              // ���������� ���������� �������������� �����������  
 };
 
 // ����������� ������� ������
 
 // ����������� ��������� ������� ������
 void CExtrContainer::AddExtrToContainer(SExtremum &extr)    // ��������� ��������� � ���������
  {
   // ���� � ���������� ��� �� ���� �����������
   if (_countFormedExtr == 0)
    {
      _bufferExtr[0] = extr;
      _countFormedExtr++;
    }
   else
    {
     // ���� ���������� ��������� ��� � ��� �� �����������
     if (_bufferExtr[0].direction == extr.direction)
      {
       // �� ������ ��������� ��������� � ����������
       _bufferExtr[0] = extr;
      }
     // ���� �� �� ���������������, �� ��������� � �����
     else
      {
       // ���� �� ���� ������� 4 ����������
       if (_countFormedExtr < 4)
        _countFormedExtr ++;
       // ������� ������ �����������
       for (int ind=3;ind>0;ind--)
          {
           _bufferExtr[ind] = _bufferExtr[ind-1];
          }
       // ��������� ������� ��������
       _bufferExtr[0] = extr;          
     }
   }    
  }
  
 void CExtrContainer::AddExtrToContainer(int direction,double price,datetime time)  // ��������� ��������� � ���������
  {
   // ���� ���������� ������ ���������� ��������� � ������������ ���������� ����������
   if (direction == _bufferExtr[0].direction)
    {
     // �� ������ �������������� ���������
     _bufferExtr[0].price = price;
     _bufferExtr[0].time = time;
    }
   else
    {
     // ����� ������� ��� ���������� � ������
     for (int ind=3;ind>0;ind--)
      {
       _bufferExtr[ind] = _bufferExtr[ind-1];
      }
     // � ���������� ����� ��������� � ������
     _bufferExtr[0].direction = direction;
     _bufferExtr[0].price = price;
     _bufferExtr[0].time = time;
    }
  }
  
 // ��������� �� ������ ���������� ������ ��������� ����������
 SExtremum CExtrContainer::MakeExtremum (double price, datetime time, int direction)
  {
   SExtremum extr;
   extr.price = price;
   extr.time = time;
   extr.direction = direction;
   return (extr);
  }
 
 // ����������� ��������� ������� ������
 CExtrContainer::CExtrContainer(string symbol, ENUM_TIMEFRAMES period,int handleDE/*,int sizeBuf*/)                     // ����������� ������
  {
   // ��������� ��������� �����, �� ������� ����� ��������� ����������
   _symbol = symbol;
   _period = period;
   _handleDE = handleDE;
   _countFormedExtr = 0;
  }

 CExtrContainer::~CExtrContainer() // ���������� ������
  {

  }

 // ����� ���������� ��������� �� ������� 
 SExtremum CExtrContainer::GetExtremum(int index)
 {
  SExtremum nullExtr = {0,0,0};
  if (index < 0 || index >= _countFormedExtr)
    {
     Print("������ ������ GetExtrByIndex ������ CExtrContainer. ������ ���������� ��� ���������");
     return (nullExtr);
    }     
  return (_bufferExtr[index]);          
 }

 // ����� ��������� ����� ��������� �� ������ ���������� �� �������� ����
 bool CExtrContainer::AddNewExtr(datetime time)
  {
   double extrHigh[];
   double extrLow[];
   double extrHighTime[];
   double extrLowTime[];
   datetime timeHigh;
   datetime timeLow;
   if ( CopyBuffer(_handleDE,2,time,1,extrHigh)     < 1 || CopyBuffer(_handleDE,3,time,1,extrLow) < 1 || 
        CopyBuffer(_handleDE,4,time,1,extrHighTime) < 1 || CopyBuffer(_handleDE,5,time,1,extrLowTime) < 1 )
    {
     Print("�� ������� ��������� ����� �����������");
     return (false);
    }
   timeHigh = datetime(extrHighTime[0]);
   timeLow  = datetime(extrLowTime[0]);

   //���� ������ ������ ������� ���������
   if (extrHigh[0]>0 && extrLow[0]==0)
    {
     AddExtrToContainer(MakeExtremum(extrHigh[0],datetime(extrHighTime[0]),1));
    }
   //���� ������ ������ ������ ���������
   if (extrLow[0]>0 && extrHigh[0]==0)
    { 
     AddExtrToContainer(MakeExtremum(extrLow[0],datetime(extrLowTime[0]),-1));
    }
   //���� ������ ��� ����������
   if (extrHigh[0]>0 && extrLow[0]>0)
    { 
     // ���� ������� ������ ������
     if (extrHighTime[0] < extrLowTime[0])
      {
       AddExtrToContainer(MakeExtremum(extrHigh[0],datetime(extrHighTime[0]),1));
       AddExtrToContainer(MakeExtremum(extrLow[0],datetime(extrLowTime[0]),-1));                                                    
      }
     // ���� ������ ������ ������
     if (extrHighTime[0] > extrLowTime[0])
      {
       AddExtrToContainer(MakeExtremum(extrLow[0],datetime(extrLowTime[0]),-1));       
       AddExtrToContainer(MakeExtremum(extrHigh[0],datetime(extrHighTime[0]),1));             
      }      
    }     
   return (true);
  }