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
#include <StringUtilities.mqh>             // ��������� ���������
#include <CompareDoubles.mqh>              // ��� ��������� ������������ �����
#include <DrawExtremums/CExtremum.mqh>     // ��� ������� �����������
#include <Arrays\ArrayObj.mqh>             // ����� ������������ ��������

// ������������ ����� �����������
enum ENUM_EXTR_USE
 {
  EXTR_HIGH = 0,
  EXTR_LOW,
  EXTR_BOTH,
  EXTR_NO
 };

class CExtrContainer  : public CObject
{
 private:
 // ������ ������
 double   _extrHigh[];          // ����� ������� �����������
 double   _extrLow [];          // ����� ������ ����������
 double   _lastExtrSignal[];    // ����� ���������� ��������������� ���������� ����������
 double   _prevExtrSignal[];    // ����� �������������� ����������
 double   _extrBufferHighTime[];// ����� ������� �����������
 double   _extrBufferLowTime[]; // ����� ������� �����������
 string   _symbol;              // ������, �� ������ ��� ������ ���������
 string   _eventExtrUp;         // ��� ����������� ������� ��� ���������� �������� ����������     
 string   _eventExtrDown;       // ��� ����������� ������� ��� ���������� ������� ���������� 
 ENUM_TIMEFRAMES _period;
 bool    _iUploaded;
 
 CArrayObj       _bufferExtr;       // ������ ��� �������� �����������  
 CExtremum       *extrTemp;         
 // ��������� ���� ������
 int      _handleDE;                // ����� ���������� DrawExtremums
 int      _historyDepth;            // ������� �������
 int      _countHigh;
 int      _countLow;
 int      _historyLengh;            // ���������� ����� �� ������� ������� ���������� ���������� 
  
 // ��������� ������ ������
 string GenEventName (string eventName) { return(eventName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
 public:
 CExtrContainer(int handleExtremums, string symbol, 
               ENUM_TIMEFRAMES period, int history_lengh = -1);               // ����������� ������ ���������� �����������
 ~CExtrContainer();                                                           // ���������� ������ ���������� �����������
  
 // ������ ������
 int          GetCountByType(ENUM_EXTR_USE extr_use);                         // ���������� ��������� ������/������� ����������� � ����������
 int          GetExtrIndexByTime (datetime time);                             // ���������� ������ ���������� 
 CExtremum    *GetExtrByTime(datetime time);                                  // ���������� ������ ���������� �������� �������� ��� ����� ������
 void         AddExtrToContainer(CExtremum *extr);                            // ��������� ��������� � ���������
 bool         AddNewExtrByTime(datetime time);                                // ��������� ��������� �� �������
 bool         Upload(int bars = -1);
 bool         UploadOnEvent(string sparam,double dparam,long lparam);   
 bool         isUploaded();      
 int          GetCountFormedExtr() {return (_bufferExtr.Total()-1);};         // ���������� ���������� �������������� �����������
 CExtremum    *GetExtrByIndex(int index, ENUM_EXTR_USE extr_use = EXTR_BOTH); // ���������� ��������� �� �������, ��� ����� extr_use
 CExtremum    *GetLastFormedExtr(ENUM_EXTR_USE extr_use);                     // ���������� ��������� �������������� �� ����
 CExtremum    *GetLastFormingExtr();                                          // ���������� ��������� �������������
 CExtremum    *GetFormedExtrByIndex(int index, ENUM_EXTR_USE extr_use = EXTR_BOTH);
 ENUM_EXTR_USE GetPrevExtrType(void);
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
// �����������                                                       |
//+------------------------------------------------------------------+
CExtrContainer::CExtrContainer(int handleExtremums, string symbol, ENUM_TIMEFRAMES period, int history_lengh = -1)                     // ����������� ������
{
 _handleDE = handleExtremums;                 
 _symbol = symbol;            
 _period = period;
 _countHigh = 0;
 _countLow = 0;
 _iUploaded = false;
 _historyDepth = history_lengh;    
 _eventExtrUp =  GenEventName("EXTR_UP");
 _eventExtrDown = GenEventName("EXTR_DOWN");
 if(!Upload(_historyDepth))
  StringFormat("%s �� ������� �������� ���������!", MakeFunctionPrefix(__FUNCTION__));
}

//+------------------------------------------------------------------+
// ����������                                                        |
//+------------------------------------------------------------------+
CExtrContainer::~CExtrContainer() // ���������� ������
{ 
 Print(__FUNCTION__," �������� ������.");
 
 for(int i = _bufferExtr.Total()-1; i >= 0; i--)
  delete _bufferExtr.At(i);
 _bufferExtr.Clear();
 delete extrTemp;
}

  
//+--------------------------------------------------------------------------+
// ���������� ��������� ����� ��������� ��������, (���� �������� - true)     |
// ����� ������������ ������ �������� ����� �������������� ����������        |
//                                         �������� �� OnTick()/OnCalculate()|
//+--------------------------------------------------------------------------+
bool CExtrContainer::isUploaded()
{
 if(!_iUploaded || _bufferExtr.Total() < 1)
 { 
  Upload(_historyDepth);
  //Print ("��������� ������������� Upload() ���������� ��������� � ������� ", _bufferExtr.Total(), "_iUploaded = ", _iUploaded);
 }
 if(_iUploaded)
  return true;
 else 
  return false;
}

  
//+------------------------------------------------------------------+
// ��������� ������ ����������� �� ���� �������                      |
//+------------------------------------------------------------------+
bool CExtrContainer::Upload(int bars = -1)       
{
 //if(isUploaded())
 _bufferExtr.Clear();
 if(bars == -1)
 {
   bars = Bars(_symbol,_period);
  _historyDepth = bars;
 }
 int copiedHigh     = _historyDepth;
 int copiedLow      = _historyDepth;
 int copiedHighTime = _historyDepth;
 int copiedLowTime  = _historyDepth;
 if ( CopyBuffer(_handleDE, 2, 0, 1, _lastExtrSignal) < 1
   || CopyBuffer(_handleDE, 3, 0, 1, _prevExtrSignal) < 1)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ���������� ������ ������������� ����������� ���������� DrawExtremums ", MakeFunctionPrefix(__FUNCTION__)));           
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
     AddExtrToContainer(new CExtremum(1, _extrHigh[i],datetime(_extrBufferHighTime[i]),EXTR_FORMED));
     AddExtrToContainer(new CExtremum(-1, _extrLow[i],datetime(_extrBufferLowTime[i]),EXTR_FORMED));                                                    
    }
    // ���� ������ ������ ������
    if (_extrBufferHighTime[i] > _extrBufferLowTime[i])
    {   
     AddExtrToContainer(new CExtremum(-1, _extrLow[i],datetime(_extrBufferLowTime[i]),EXTR_FORMED));       
     AddExtrToContainer(new CExtremum(1, _extrHigh[i],datetime(_extrBufferHighTime[i]),EXTR_FORMED));             
    }
   } 
   //���� ��������� ���� �� ����������� 
   else
   {  
    if(_extrHigh[i]!=0) //���� ��� ������� ���������  
     AddExtrToContainer(new CExtremum(1, _extrHigh[i],datetime(_extrBufferHighTime[i]),EXTR_FORMED));
    if(_extrLow[i]!=0)  //���� ��� ������ ���������
     AddExtrToContainer(new CExtremum(-1, _extrLow[i],datetime(_extrBufferLowTime[i]),EXTR_FORMED));
   }
  }
  //�������� ���� �� ������������� ���������?
  if(_lastExtrSignal[0] != 0)
   AddExtrToContainer(new CExtremum(1, _lastExtrSignal[0],datetime(_extrBufferHighTime[0]),EXTR_FORMING));
  if(_prevExtrSignal[0] != 0)
   AddExtrToContainer(new CExtremum(-1, _prevExtrSignal[0],datetime(_extrBufferLowTime[0]),EXTR_FORMING));
 }
 Print("��������� ���������� �� ",PeriodToString(_period)," ��������. �����: ",_bufferExtr.Total());
 _iUploaded = true;
 return (true);
}

//+------------------------------------------------------------------+
// ��������� ����� ��������� �� �������                              |
//+------------------------------------------------------------------+
bool  CExtrContainer::UploadOnEvent(string sparam,double dparam,long lparam)
{
 CExtremum *lastExtr;
 // ���� ������ ����� ��������� High
 if (sparam == _eventExtrUp)
  {
   lastExtr =  new CExtremum(1, dparam, datetime(lparam), EXTR_FORMING); 
   if (lastExtr == NULL)
    {
     delete lastExtr;
     return false;
    }
   AddExtrToContainer(lastExtr);
    return true;
  } 
 // ���� ������ ����� ��������� Low
 if (sparam == _eventExtrDown)
  {
   lastExtr = new CExtremum(-1, dparam, datetime(lparam), EXTR_FORMING); 
   if (lastExtr == NULL)
   {
    delete lastExtr;
    return false;
   }
   AddExtrToContainer(lastExtr);
    return true;
  }  
 return false;
} 

//+------------------------------------------------------------------+
// ����������� ��������� �� ������� � ����                           |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtrByIndex(int index, ENUM_EXTR_USE extr_use = EXTR_BOTH)
{
 int k = 0;             //���������� ����������� ���������������� �����������
 if(index >= _bufferExtr.Total() || index < 0) 
 {
  return new CExtremum(0,-1,0,EXTR_NO_TYPE);
 } 
 switch(extr_use)
 {
  case EXTR_BOTH:
    return(_bufferExtr.At(index));
  break;
  case EXTR_HIGH:
   for(int i = 0; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == 1)
    {
     if(k == index)
     {
      return extrTemp;
     }
     k++;
    }
   }
   return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
  case EXTR_LOW:
   for(int i = 0; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == -1)
    {
     if(k == index)
     {
      return extrTemp;
     }
     k++;
    }
   }
   return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
  default:
  return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
 }
}


//+------------------------------------------------------------------+
// ���������� ������ �������������� ��������� �� ������� � ����                           |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetFormedExtrByIndex(int index, ENUM_EXTR_USE extr_use = EXTR_BOTH)
{
 int k = 0;             //���������� ����������� ���������������� �����������
 int in_index = index + 1;
 if(index >= _bufferExtr.Total() || index < 0) 
 {
  return new CExtremum(0,-1,0,EXTR_NO_TYPE);
 } 
 switch(extr_use)
 {
  case EXTR_BOTH:
   return(_bufferExtr.At(in_index));
  break;
  case EXTR_HIGH:
   for(int i = 1; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == 1)
    {
     if(k == index)
     {
      return extrTemp;
     }
     k++;
    }
   }
   return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
  case EXTR_LOW:
   for(int i = 1; i < _bufferExtr.Total(); i++) 
   {
    extrTemp = _bufferExtr.At(i);
    if(extrTemp.direction == -1)
    {
     if(k == index)
     {
      return extrTemp;
     }
     k++;
    }
   }
   return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
  default:
  return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
  break;
 }
}

//+------------------------------------------------------------------+
// ���������� ������ ���������� �� �������                           |
//+------------------------------------------------------------------+
int CExtrContainer::GetExtrIndexByTime(datetime time)
{
 CExtremum *extr;
 for(int i = 0; i < _bufferExtr.Total(); i++)
 {
  extr = _bufferExtr.At(i);
  if(extr.time <= time)
  {
   return i;
  }
 }
 return -1;
}

//+------------------------------------------------------------------+
// ���������� ��������� �� �������                                   |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetExtrByTime(datetime time)
{
 CExtremum *extr;
 for(int i = 0; i < _bufferExtr.Total(); i++)
 {
  extr = _bufferExtr.At(i);
  if(extr.time <= time)
  {
   return extr;
  }
 }
 return new CExtremum(0,-1,0,EXTR_NO_TYPE);;
}


//+-----------------------------------------------------------------------+
// ����� ��������� ����� ��������� �� ������ ���������� �� �������� ����  |
//+-----------------------------------------------------------------------+
bool CExtrContainer::AddNewExtrByTime(datetime time)
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
  log_file.Write(LOG_DEBUG, 
  StringFormat("%s �� ������� ��������� ����� �����������. ����� = %i", MakeFunctionPrefix(__FUNCTION__), _bufferExtr.Total())); 
  return (false);
 } 
  
 timeHigh = datetime(extrHighTime[0]);
 timeLow  = datetime(extrLowTime[0]);
 //���� ������ ������ ������� ���������
 if (extrHigh[0]>0 && extrLow[0]==0)
 {
  AddExtrToContainer(new CExtremum(1,extrHigh[0],datetime(extrHighTime[0]),EXTR_FORMED));   
 }
 //���� ������ ������ ������ ���������
 if (extrLow[0]>0 && extrHigh[0]==0)
 { 
  AddExtrToContainer(new CExtremum(-1,extrLow[0],datetime(extrLowTime[0]),EXTR_FORMED));
 }
 //���� ������ ��� ����������
 if (extrHigh[0]>0 && extrLow[0]>0)
 { 
  // ���� ������� ������ ������
  if (extrHighTime[0] < extrLowTime[0])
  {
   AddExtrToContainer(new CExtremum(1,extrHigh[0],datetime(extrHighTime[0]),EXTR_FORMED));
   AddExtrToContainer(new CExtremum(-1,extrLow[0],datetime(extrLowTime[0]),EXTR_FORMED));                                                    
  }
  // ���� ������ ������ ������
  if (extrHighTime[0] > extrLowTime[0])
  {      
   AddExtrToContainer(new CExtremum(-1,extrLow[0],datetime(extrLowTime[0]),EXTR_FORMED));       
   AddExtrToContainer(new CExtremum(1,extrHigh[0],datetime(extrHighTime[0]),EXTR_FORMED));             
  }      
 }     
 return (true);
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
 
 
//+------------------------------------------------------------------+  
// ����������� ���� ���������� ��������������� ����������            |
//+------------------------------------------------------------------+
ENUM_EXTR_USE CExtrContainer::GetPrevExtrType(void)
{
 if(_bufferExtr.Total()!= 0)
 {
  CExtremum *extr = _bufferExtr.At(1);
  switch ( int(extr.direction) )
  {
   case 1:
    return EXTR_HIGH;
   case -1:
    return EXTR_LOW;
  }
 }
 return EXTR_NO;
}

//+------------------------------------------------------------------+
// �������� ��������� �������������� ���������                       |
//+------------------------------------------------------------------+
CExtremum *CExtrContainer::GetLastFormedExtr(ENUM_EXTR_USE extr_use)
{
 if(_bufferExtr.Total() < 2)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s � ���������� ������������ ��������� ����� ���������� � ���������������. ����� = %i", MakeFunctionPrefix(__FUNCTION__), _bufferExtr.Total())); 
  return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
 }     
 switch (extr_use)
 {
  case EXTR_BOTH:
   return _bufferExtr.At(1);
  break;
  case EXTR_HIGH:
   if(GetPrevExtrType() == EXTR_HIGH)   //���� ��������� ��������� HIGH. ������ �� �������������
    return GetExtrByIndex(1, EXTR_HIGH);//���������� ��������� ��������������� HIGH
   if(GetPrevExtrType() == EXTR_LOW)    //���� ��������� ��������� LOW. ������ ��������� HIGH ��������������
    return GetExtrByIndex(0, EXTR_HIGH);
   return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
  break;
  case EXTR_LOW:
   if(GetPrevExtrType() == EXTR_LOW)    //���� ��������� ��������� LOW. ������ �� �������������
    return GetExtrByIndex(1, EXTR_LOW); //���������� ��������� ��������������� LOW
   if(GetPrevExtrType() == EXTR_HIGH)   //���� ��������� ��������� HIGH. ������ ��������� LOW ��������������
    return GetExtrByIndex(0, EXTR_LOW);
   return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
  break;
 }
 return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
}
CExtremum *CExtrContainer::GetLastFormingExtr()
{
 if(_bufferExtr.Total() == 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s � ���������� ������������ ��������� ����� ���������� �������������� ����������. ����� = %i", MakeFunctionPrefix(__FUNCTION__), _bufferExtr.Total())); 
  return new CExtremum(0, -1, 0, EXTR_NO_TYPE);
 }     
 return _bufferExtr.At(0);
}