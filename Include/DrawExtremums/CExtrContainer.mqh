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
#include <CLog.mqh>                        // ��� ����
#include <CompareDoubles.mqh>              // ��� ��������� ������������ �����
#include <DrawExtremums/CExtremum.mqh>  // ��� ������� �����������
#include <Arrays\ArrayObj.mqh>

class CExtrContainer 
{
 private:
 // ����� �����������
 CArrayObj       _bufferExtr;              // ������ ��� �������� �����������           
 // ��������� ���� ������
 int             _handleDE;                // ����� ���������� DrawExtremums
 string          _symbol;                  // ������
 ENUM_TIMEFRAMES _period;                  // ������

 
 public:
 CExtrContainer(string symbol,ENUM_TIMEFRAMES period,int handleDE);                  // ����������� ������ ���������� �����������
 ~CExtrContainer();                                                                   // ���������� ������ ���������� �����������
  
 // ������ ������
 void         AddExtrToContainer(CExtremum *extr);                            // ��������� ��������� � ���������
 void         AddExtrToContainer(int direction,double price,datetime time);   // ��������� ��������� � ��������� �� ����������� ����������, ���� � ������� 
 CExtremum    *MakeExtremum (double price, datetime time, int direction);
 CExtremum    *GetExtremum (int index);
 bool         AddNewExtr (datetime time);                                     // ��������� ����� ��������� � �������� ����
 int          GetCountFormedExtr() {return (_bufferExtr.Total());};              // ���������� ���������� �������������� �����������  
};
 
 // ����������� ������� ������
 
 // ����������� ��������� ������� ������
 void CExtrContainer::AddExtrToContainer(CExtremum *extr)    // ��������� ��������� � ���������
  {
   // ���� � ���������� ��� �� ���� �����������
   if (_bufferExtr.Total() == 0)
    {
      _bufferExtr.Add(extr);
    }
   else
    {
     CExtremum *tempExtr;
     tempExtr = _bufferExtr.At(0);
     // ���� ���������� ��������� ��� � ��� �� �����������
     if (tempExtr.direction == extr.direction)
      {
       // �� ������ ��������� ��������� � ����������
       _bufferExtr.Update(0,extr);
      }
     // ���� �� �� ���������������, �� ��������� � �����
     else
      {
       // ��������� ������� ��������
       _bufferExtr.Insert(extr,0);         
     }
   }    
  }
  
 void CExtrContainer::AddExtrToContainer(int direction,double price,datetime time)  // ��������� ��������� � ���������
  {
    CExtremum *tempExtr;
    tempExtr = _bufferExtr.At(0);
   // ���� ���������� ������ ���������� ��������� � ������������ ���������� ����������
   if (direction == tempExtr.direction)
    {
     // �� ������ �������������� ���������
     tempExtr.price = price;
     tempExtr.time = time;
     _bufferExtr.Update(0,tempExtr);
    }
   else
    {
     // ����� ���������� ����� ��������� � ������
     tempExtr.price = price;
     tempExtr.time = time;
     tempExtr.direction = direction;
     _bufferExtr.Insert(tempExtr,0);
    }
  }
  
 // ��������� �� ������ ���������� ������ ��������� ����������
 CExtremum *CExtrContainer::MakeExtremum (double price, datetime time, int direction)
  {
   CExtremum *extr = new CExtremum(direction, price, time);
   return (extr);
  }
 
 // ����������� ��������� ������� ������
 CExtrContainer::CExtrContainer(string symbol, ENUM_TIMEFRAMES period,int handleDE/*,int sizeBuf*/)                     // ����������� ������
  {
   // ��������� ��������� �����, �� ������� ����� ��������� ����������
   _symbol = symbol;
   _period = period;
   _handleDE = handleDE;
  }

 CExtrContainer::~CExtrContainer() // ���������� ������
  {

  }

 // ����� ���������� ��������� �� ������� 
 CExtremum *CExtrContainer::GetExtremum(int index)
 {
     
  if (index < 0 || index >= _bufferExtr.Total())
    {
     CExtremum *nullExtr  = new CExtremum(0,-1);    //�������!!!
     Print("������ ������ GetExtrByIndex ������ CExtrContainer. ������ ���������� ��� ���������");
     return (nullExtr);
    }  
    CExtremum *extr = _bufferExtr.At(index);
  return (_bufferExtr.At(index));          
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