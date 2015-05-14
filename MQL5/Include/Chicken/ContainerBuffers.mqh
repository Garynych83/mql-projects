//+------------------------------------------------------------------+
//|                                             ContainerBuffers.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#define DEPTH_MAX 25
#define DEPTH_MIN 4


#include <Lib CisNewBarDD.mqh>
#include <CLog.mqh>                         // ��� ����
#include <StringUtilities.mqh>

class CBufferTF : public CObject      //�� ����� �� �������� handle ����?
{
 private:
 ENUM_TIMEFRAMES  tf;               // ��������� ��������� ������ ������
 bool             dataAvailable;    // ���������� � ������������� ���������� ����������� (�������)

 public:
         double   buffer[];         // ����� ������ (����� ���� ����� ������������ �����������)
         CBufferTF(ENUM_TIMEFRAMES period, bool dAvailable = true){tf = period; dataAvailable = dAvailable;}
         ENUM_TIMEFRAMES GetTF()  {return tf;}
         bool isAvailable()       {return dataAvailable;}   // �������
         void SetAvailable(bool value){dataAvailable = value;}
         
};
//+------------------------------------------------------------------------------------------------+
//|    �����  ContainerBuffers ������������ ��� �������� ���������� ������ �� ����� ������� ���:   |
//|      bufferHigh                                                                                |
//|         bufferLow                                                                              |
//|            bufferPBI                                                                           |
//|               bufferClose                                                                      |
//|    ��� ������������� ����������, ���������� ��� �������� � ������, ��� ������� ��              |
//|                                                � ��������� �� ������ ���� � ������� Update().  |
//|        �����: ����������� ������� HIGH � LOW ������������ �� �������  DEPTH_MAX                |
//|               ����������� ������� CLOSE � PBI ������������ �� �������  DEPTH_MIN               |
//|               ���� ������������ ������� �� �� ������ �������� ��� ������ � ����������          |
//|        ���������� ���� �������� ������������ �� ������ ����� ���� ��� ������� ����������       |
//|      ���������� �������� �� ������� ���� ������������ �� ������ ����                           |
//                                                                                                 |      
//+------------------------------------------------------------------------------------------------+
class CContainerBuffers
{
 private: 
 CArrayObj  *_bufferHigh; // ������ ������� High �� ���� �����������
 CArrayObj  *_bufferLow;  // ������ ������� Low �� ���� �����������
 CArrayObj  *_bufferPBI;  // ������ ������� PBI �� ���� �����������
 CArrayObj  *_bufferClose;// ������ ������� Close �� ���� �����������
 CArrayObj  *_allNewBars; // ������ newbars ��� ������� ��
 
 int     _handlePBI[];    // ������ ������� PBI
 int     _tfCount;        // ���������� ��
 
 bool    _handleAvailable[];
 double  tempBuffer[];
 bool    recalculate;
 
 ENUM_TIMEFRAMES _TFs[];
 
 public:
                     CContainerBuffers(ENUM_TIMEFRAMES &TFs[]);
                    ~CContainerBuffers();
               
               bool Update();
               bool isAvailable(ENUM_TIMEFRAMES period); //�������
               CBufferTF *GetHigh (ENUM_TIMEFRAMES period);
               CBufferTF *GetLow  (ENUM_TIMEFRAMES period);
               CBufferTF *GetClose(ENUM_TIMEFRAMES period);
               CBufferTF *GetPBI  (ENUM_TIMEFRAMES period);
               CisNewBar *GetNewBar(ENUM_TIMEFRAMES period);
                
};
//+------------------------------------------------------------------+
//|      �����                                                            |
//+------------------------------------------------------------------+
CContainerBuffers::CContainerBuffers(ENUM_TIMEFRAMES &TFs[])
{
 ArrayCopy(_TFs, TFs);           //�� ����� ����� ����
 _tfCount =  ArraySize(TFs);
 _bufferHigh  = new CArrayObj();
 _bufferLow   = new CArrayObj();
 _bufferPBI   = new CArrayObj();
 _bufferClose = new CArrayObj();
 _allNewBars  = new CArrayObj();
 ArrayResize(_handlePBI,_tfCount);
 ArrayResize(_handleAvailable,_tfCount);
 for(int i = 0; i < _tfCount; i++)
 {
  _bufferHigh.Add(new CBufferTF(TFs[i]));
  _bufferLow.Add (new CBufferTF(TFs[i]));
  _bufferPBI.Add (new CBufferTF(TFs[i]));
  _bufferClose.Add(new CBufferTF(TFs[i]));
  _allNewBars.Add(new CisNewBar(_Symbol,_TFs[i]));
   GetNewBar(TFs[i]).isNewBar();
  _handleAvailable[i] = true;
  _handlePBI[i] = iCustom(_Symbol, TFs[i], "PriceBasedIndicator");
  if (_handlePBI[i] == INVALID_HANDLE)
  {
   log_file.Write(LOG_DEBUG, "�� ������� ������� ����� ���������� PriceBasedIndicator");
   Print("�� ������� ������� ����� ���������� PriceBasedIndicator");
   _handleAvailable[i] = false;
  }
 }
 recalculate = true;
 Update();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CContainerBuffers::~CContainerBuffers()
{
 for(int i = 0; i < _tfCount; i++)
 {
  IndicatorRelease(_handlePBI[i]);
  delete GetClose(_TFs[i]);
  delete GetHigh(_TFs[i]);
  delete GetLow(_TFs[i]);
  delete GetPBI(_TFs[i]);
  delete GetNewBar(_TFs[i]);
 }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CContainerBuffers::Update()
{
 for(int i = 0; i < _tfCount; i++)
 { 
  if(_handleAvailable[i])
  {
   CBufferTF *bufferHigh =  _bufferHigh.At(i);
   CBufferTF *bufferLow  =  _bufferLow.At(i);
   CBufferTF *bufferPBI  =  _bufferPBI.At(i);
   CBufferTF *bufferClose = _bufferClose.At(i);
   ArraySetAsSeries(bufferHigh.buffer, true);
   ArraySetAsSeries(bufferLow.buffer, true);
   ArraySetAsSeries(bufferPBI.buffer, true);
   ArraySetAsSeries(bufferClose.buffer, true); 
   if(GetNewBar(_TFs[i]).isNewBar()||recalculate)
   { 
    if(CopyHigh(_Symbol, bufferHigh.GetTF(), 1, DEPTH_MAX, bufferHigh.buffer)   < DEPTH_MAX) // ���� �������� ���������� ��������������� ����
    {
     bufferHigh.SetAvailable(false); 
     log_file.Write(LOG_DEBUG,StringFormat("%s ������ ��� ����������� ������ High �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferHigh.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ High �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferHigh.GetTF()));
     return false;
    } 
    if(CopyLow(_Symbol, bufferLow.GetTF(), 1, DEPTH_MAX, bufferLow.buffer) < DEPTH_MAX )     // ����� ������������ ��� ���� �������������� ����� �� ������� �������
    {
     bufferLow.SetAvailable(false);
     log_file.Write(LOG_DEBUG,StringFormat("%s ������ ��� ����������� ������ Low �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferLow.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ Low �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferLow.GetTF()));
     return false;
    }   
    if(CopyClose(_Symbol, bufferClose.GetTF(), 0, DEPTH_MIN, bufferClose.buffer)   < DEPTH_MIN)     // ����� ����������� ��� ���� �������������� ����� �� ������� �������
    {
     bufferClose.SetAvailable(false);
     log_file.Write(LOG_DEBUG,StringFormat("%s ������ ��� ����������� ������ Low �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferClose.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ Low �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferClose.GetTF()));
     return false;
    }   
    if(CopyBuffer(_handlePBI[i], 4, 0, DEPTH_MIN, bufferPBI.buffer)      < DEPTH_MIN)          // ��������� ���������� ��������
    {
     bufferPBI.SetAvailable(false);
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� ����������� ������ Low �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferPBI.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ Low �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferPBI.GetTF()));
     return false;
    }
   }
   else
   {
    if(CopyHigh(_Symbol, bufferHigh.GetTF(), 0, 1, tempBuffer) == 1)
     bufferHigh.buffer[0] = tempBuffer[0];
    if(CopyLow(_Symbol, bufferLow.GetTF(), 0, 1, tempBuffer))
     bufferLow.buffer[0] = tempBuffer[0];
    if(CopyClose(_Symbol, bufferClose.GetTF(), 0, 1, tempBuffer))
     bufferClose.buffer[0] = tempBuffer[0];
    if(CopyBuffer(_handlePBI[i], 4, 0, 1, tempBuffer))
     bufferPBI.buffer[0] = tempBuffer[0];
   }
  }
  else 
  {
   _handlePBI[i] = iCustom(_Symbol, _TFs[i], "PriceBasedIndicator");
   if (_handlePBI[i] == INVALID_HANDLE)
   {
    log_file.Write(LOG_DEBUG, "�� ������� ������� ����� ���������� PriceBasedIndicator");
    Print("�� ������� ������� ����� ���������� PriceBasedIndicator");
    recalculate = true;
    return false;
   }
   else
   {
    _handleAvailable[i] = true;
    recalculate = false;
    return false;
   }
  }
 }
 recalculate = false;
 return true;
}


//+-------------------------------------------------------+
//| ������� ����� � dataAvailable, ��� ���������� ������  |
//|  ���������� �� ������ � Update()                      |
//+-------------------------------------------------------+
bool CContainerBuffers::isAvailable(ENUM_TIMEFRAMES period)
{
 bool result;
 CBufferTF *btf;
 for ( int i = 0; i < _tfCount; i++)
 { 
  if(_TFs[i] == period)
  {
   btf = _bufferHigh.At(i);
   result = btf.isAvailable();
   btf = _bufferLow.At(i);
   result = (result && btf.isAvailable());
   btf = _bufferClose.At(i);
   result = (result && btf.isAvailable());
   btf = _bufferPBI.At(i);
   result = (result && btf.isAvailable());
   return result;
  }
 }
 return false;
}

CBufferTF *CContainerBuffers::GetHigh (ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferHigh.At(i);
   return btf;
  }
 }
 PrintFormat("�� ������� �������� ������ � GetHigh  �� %s", PeriodToString(period));
 return new CBufferTF(period, false);
}
CBufferTF *CContainerBuffers::GetLow  (ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferLow.At(i);
   return btf;
  }
 }
 PrintFormat("�� ������� �������� ������ � GetLow  �� %s", PeriodToString(period));  
 return new CBufferTF(period, false);
}
CBufferTF *CContainerBuffers::GetClose(ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferClose.At(i);
   return btf;
  }
 }
 PrintFormat("�� ������� �������� ������ � GetClose  �� %s", PeriodToString(period)); 
 return new CBufferTF(period, false);
}
CBufferTF *CContainerBuffers::GetPBI (ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferPBI.At(i);
   return btf;
  }
 }
 PrintFormat("�� ������� �������� ������ � GetPBI  �� %s", PeriodToString(period));
 return new CBufferTF(period, false);
}

CisNewBar *CContainerBuffers::GetNewBar(ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
   return _allNewBars.At(i);
 }
 PrintFormat("�� ������� �������� ������ � GetNewBar  �� %s", PeriodToString(period));
 return new CisNewBar(_Symbol, period);
}