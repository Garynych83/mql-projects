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
#include <StringUtilities.mqh>
#include <CompareDoubles.mqh>              // ��� ��������� ������������ �����
#include <DrawExtremums/CExtremum.mqh>     // ��� ������� �����������
#include <Arrays\ArrayObj.mqh>

// ������������ ����� �����������
enum ENUM_EXTR_USE
 {
  EXTR_HIGH = 0,
  EXTR_LOW,
  EXTR_BOTH,
  EXTR_NO
 };

class CExtrContainer 
{
 private:
 // ������ ������
 double   _extrHigh[];    // ����� ������� �����������
 double   _extrLow [];    // ����� ������ ����������
 double   _lastExtrSignal[];    // ����� ���������� ��������������� ���������� ����������
 double   _prevExtrSignal[];    // ����� �������������� ����������
 double   _extrBufferHighTime[];// ������ ������� �����������
 double   _extrBufferLowTime[]; // ������ ������� �����������
 string   _symbol;
 ENUM_TIMEFRAMES _period;
 
 CArrayObj       _bufferExtr;       // ������ ��� �������� �����������  
 CExtremum       *extrTemp;         
 // ��������� ���� ������
 int      _handleDE;                // ����� ���������� DrawExtremums
 int      _historyDepth;            // ������� �������
 int      _countHigh;
 int      _countLow;
 public:
 CExtrContainer(int handleExtremums, string symbol, ENUM_TIMEFRAMES period);          // ����������� ������ ���������� �����������
 ~CExtrContainer();                                                                   // ���������� ������ ���������� �����������
  
 // ������ ������
 int          GetCountByType(ENUM_EXTR_USE extr_use);                          // ���������� ��������� ������/������� ����������� � ����������
 CExtremum    *GetExtrByTime(datetime time);
 void         AddExtrToContainer(CExtremum *extr);                            // ��������� ��������� � ���������
 CExtremum    *MakeExtremum (double price, datetime time, int direction, STATE_OF_EXTR state);
 CExtremum    *GetExtremum (int index);
 bool         Upload();
 bool         UploadOnEvent(string sparam);
 int          GetCountFormedExtr() {return (_bufferExtr.Total()-1);};         // ���������� ���������� �������������� �����������
 CExtremum    *GetExtrByIndex(int index, ENUM_EXTR_USE extr_use);             // ���������� ��������� �� �������, ��� ����� extr_use   
};
 
 // ����������� ������� ������
//+------------------------------------------------------------------+
// ��������� ��������� � ���������
//+------------------------------------------------------------------+
void CExtrContainer::AddExtrToContainer(CExtremum *extr)    
{
 // ���� � ���������� ��� �� ���� �����������
 if (_bufferExtr.Total() == 0)
 {
  _bufferExtr.Add(extr);
  if(extr.direction == 1)
  _countHigh++;
  if(extr.direction == -1)
   _countLow++;
 }
 else
 {
  CExtremum *tempExtr;
  tempExtr = _bufferExtr.At(0);
  //if(extr.price == 0)
  // Print("������� �������� ������ ��������� ����� ���������� = ", tempExtr.time);
  // ���� ���������� ��������� ��� � ��� �� �����������
  if (tempExtr.direction == extr.direction)
  {
   // �� ������ ��������� ��������� � ����������
   _bufferExtr.Update(0,extr);
    delete tempExtr;
  }
  // ���� �� �� ���������������, �� ��������� � ������
  else
  {
   //�������� ������ ���������� ���������� �� ��������������
   tempExtr.state = EXTR_FORMED; //����������� �� ��, ��� �� ������� ��������� ��������, ������������ � �������
   // ��������� ������� ��������
   _bufferExtr.Insert(extr,0);  
   if(extr.direction == 1)
    _countHigh++;
   if(extr.direction == -1)
    _countLow++;    
  }
 }    
}
//+------------------------------------------------------------------+  
// ��������� �� ������ ���������� ������ ��������� ����������        |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::MakeExtremum (double price, datetime time, int direction, STATE_OF_EXTR state) 
{
 CExtremum *extr = new CExtremum(direction, price, time, state);
 return (extr);
}

//+------------------------------------------------------------------+
// �����������                                                       |
//+------------------------------------------------------------------+
 CExtrContainer::CExtrContainer(int handleExtremums, string symbol, ENUM_TIMEFRAMES period)                     // ����������� ������
  {
   _handleDE = handleExtremums;
   _symbol = symbol;            
   _period = period;
   _countHigh = 0;
   _countLow = 0;
   Upload();
   //���� ����� �� ������� ������ ������, ����������� ��, ��� ����
  }

//+------------------------------------------------------------------+
// ����������                                                       |
//+------------------------------------------------------------------+
CExtrContainer::~CExtrContainer() // ���������� ������
{
 _bufferExtr.Clear();
 delete extrTemp;
}


//+------------------------------------------------------------------+
// ����� ���������� ��������� �� �������                             |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtremum(int index)
{   
 if (index < 0 || index >= _bufferExtr.Total())
 {
  CExtremum *nullExtr  = new CExtremum(0,-1, 0, EXTR_NO_TYPE);    //�������!!!
  Print("������ ������ GetExtrByIndex ������ CExtrContainer. ������ ���������� ��� ���������");
  return (nullExtr);
 }  
 CExtremum *extr = _bufferExtr.At(index);
 return (extr);          
}
 
 
//+------------------------------------------------------------------+
// ��������� ������ ����������� �� ���� �������                      |
//+------------------------------------------------------------------+
bool CExtrContainer::Upload()       
{
 int bars = Bars(_symbol,_period);
 //bars = 420;
 _historyDepth = bars;
 int copiedHigh     = _historyDepth;
 int copiedLow      = _historyDepth;
 int copiedHighTime = _historyDepth;
 int copiedLowTime  = _historyDepth;
 Sleep(10000);
 if ( CopyBuffer(_handleDE, 2, 0, 1, _lastExtrSignal) < 1
   || CopyBuffer(_handleDE, 3, 0, 1, _prevExtrSignal) < 1)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ����� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
  return (false);           
 }
            
 copiedHigh       = CopyBuffer(_handleDE, 0, 0, _historyDepth, _extrHigh);   
 copiedHighTime   = CopyBuffer(_handleDE, 4, 0, _historyDepth, _extrBufferHighTime);     
 copiedLow        = CopyBuffer(_handleDE, 1, 0, _historyDepth, _extrLow);
 copiedHighTime   = CopyBuffer(_handleDE, 5, 0, _historyDepth, _extrBufferLowTime); 
 
 if (copiedHigh     != _historyDepth || copiedLow != _historyDepth ||
     copiedHighTime != _historyDepth || copiedLowTime != _historyDepth)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ������ ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
  return (false);
 }
 else
 {
  ArraySetAsSeries(_extrHigh, true);
  ArraySetAsSeries(_extrLow, true);
  ArraySetAsSeries(_extrBufferHighTime, true);
  ArraySetAsSeries(_extrBufferLowTime, true);
  //��������� ��������� ����������� � ������� historyDepth
  for(int i = _historyDepth - 1; i >=  0; i--)
  {
   //���� �� i-�� ���� ���� ���������� ��� ����������
   if(_extrHigh[i]!=0 && _extrLow[i]!=0)
   {
    // ���� ������� ������ ������
    if (_extrBufferHighTime[i] < _extrBufferLowTime[i])
    {
     AddExtrToContainer(MakeExtremum(_extrHigh[i],datetime(_extrBufferHighTime[i]),1, EXTR_FORMED));
     AddExtrToContainer(MakeExtremum(_extrLow[i] ,datetime(_extrBufferLowTime[i]),-1, EXTR_FORMED));                                                    
    }
    // ���� ������ ������ ������
    if (_extrBufferHighTime[i] > _extrBufferLowTime[i])
    {
     AddExtrToContainer(MakeExtremum(_extrLow[i] ,datetime(_extrBufferLowTime[i]),-1, EXTR_FORMED));       
     AddExtrToContainer(MakeExtremum(_extrHigh[i],datetime(_extrBufferHighTime[i]),1, EXTR_FORMED));             
    }
   } 
   //���� ��������� ���� �� ����������� 
   else
   {  
    if(_extrHigh[i]!=0) //���� ��� ������� ���������
     AddExtrToContainer(MakeExtremum(_extrHigh[i],datetime(_extrBufferHighTime[i]),1, EXTR_FORMED));
    if(_extrLow[i]!=0)  //���� ��� ������ ���������
     AddExtrToContainer(MakeExtremum(_extrLow[i] ,datetime(_extrBufferLowTime[i]),-1, EXTR_FORMED));
   }
  }
  //�������� ���� �� ������������� ���������?

  if(_lastExtrSignal[0] != 0)
   AddExtrToContainer(MakeExtremum(_lastExtrSignal[0], _extrBufferHighTime[0], 1, EXTR_FORMING));
  if(_prevExtrSignal[0] != 0)
   AddExtrToContainer(MakeExtremum(_prevExtrSignal[0], _extrBufferLowTime[0], -1, EXTR_FORMING));
 }
 return (true);
}



//+------------------------------------------------------------------+
// ��������� ����� ��������� �� �������                              |
//+------------------------------------------------------------------+
bool  CExtrContainer::UploadOnEvent(string sparam)
{
 int copied;
 int copiedTime;
 //�������� ���� �� ������ �������������� ����������� High
 if(sparam == "EXTR_UP"||sparam == "EXTR_UP_FORMED")
 {
  copied       = CopyBuffer(_handleDE, 2, 0, 1, _extrHigh);
  copiedTime   = CopyBuffer(_handleDE, 4, 0, 1, _extrBufferHighTime);  
  if(copied < 0 || copiedTime < 0)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ������ ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
   return (false);
  }
  if(_extrHigh[0]!=0)
  AddExtrToContainer(MakeExtremum(_extrHigh[0], datetime(_extrBufferHighTime[0]), 1, EXTR_FORMING));
  if(_extrHigh[0] == 0)
  Print("������� �������� ������ ���������   ", _extrHigh[0]);
 }
 if(sparam == "EXTR_DOWN"||sparam == "EXTR_DOWN_FORMED")
 {
  copied       = CopyBuffer(_handleDE, 3, 0, 1, _extrLow);
  copiedTime   = CopyBuffer(_handleDE, 5, 0, 1, _extrBufferLowTime);  
  if(copied < 0 || copiedTime < 0)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ������ ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
   return (false);
  }
  if(_extrLow[0]!=0)
  AddExtrToContainer(MakeExtremum(_extrLow[0], datetime(_extrBufferLowTime[0]), -1, EXTR_FORMING));
 }
 return true;
} 

//+------------------------------------------------------------------+
// ����������� ��������� �� ������� � ����                           |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtrByIndex(int index, ENUM_EXTR_USE extr_use)
{
 CExtremum *extrERROR = new CExtremum(0,-1,0,EXTR_NO_TYPE);
 int k = 0;             //���������� ����������� ���������������� �����������
 if(index >= _bufferExtr.Total() || index < 0) 
 {
  Print(" ������ ��� ������ ������� _bufferExtr.Total = ", _bufferExtr.Total());
  return extrERROR;
 } 
 switch(extr_use)
 {
  case EXTR_BOTH:
   return(GetExtremum(index));
  break;
  case EXTR_HIGH:
   for(int i = 0; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == 1)
    {
     if(k == index)
     {
      return GetExtremum(i);
     }
     k++;
    }
   }
   return extrERROR;
  break;
  case EXTR_LOW:
   for(int i = 0; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == -1)
    {
     if(k == index)
     {
      return GetExtremum(i);
     }
     k++;
    }
   }
   return extrERROR;
  break;
  default:
  return extrERROR;
  break;
 }
}


//+------------------------------------------------------------------+
// ���������� ��������� �� �������                                   |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtrByTime(datetime time)
{
 CExtremum *extr;
 CExtremum *errorExtr = new CExtremum(0, -1, 0, 2);
 for(int i = 0; i < _bufferExtr.Total(); i++)
 {
  extr = _bufferExtr.At(i);
  if(extr.time <= time)
  {
   return extr;
  }
 }
 return errorExtr;
}


//+------------------------------------------------------------------+
// ����� ���������� ���������� ��������� �� ����                     |
//+------------------------------------------------------------------+
int CExtrContainer::GetCountByType(ENUM_EXTR_USE extr_use)
{
 switch (extr_use)
 {
  case EXTR_BOTH:
   return _bufferExtr.Total();
  break;
  case EXTR_HIGH:
   return _countHigh;
  break;
  case EXTR_LOW:
   return _countLow;
  break;
  default:
   return -1;
  break;
 }
}