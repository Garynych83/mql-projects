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
#include <CLog.mqh>                   // ��� ����
#include <StringUtilities.mqh>
#include <SystemLib/IndicatorManager.mqh>            // ���������� �� ������ � ������������

class CBufferTF : public CObject      // �� ����� �� �������� handle ����?
{
 private:
 ENUM_TIMEFRAMES  tf;               // ��������� ��������� ������ ������
 bool             dataAvailable;    // ���������� � ������������� ���������� ����������� (�������)

 public:
         double   buffer[];         // ����� ������ (����� ���� ����� ������������ �����������)
         CBufferTF(ENUM_TIMEFRAMES period, bool dAvailable = false){tf = period; dataAvailable = dAvailable;}
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
// CArrayObj  *_bufferATR;// ������ ������� ATR �� ���� �����������
  CArrayObj  *_bufferClose;// ������ ������� Close �� ���� �����������
  CArrayObj  *_bufferOpen;// ������ ������� Open �� ���� �����������
  CArrayObj  *_allNewBars; // ������ newbars ��� ������� ��
 
  int     _handlePBI[];    // ������ ������� PBI
// int     _handleATR[];  // ������ ������� ATR
  int     _tfCount;        // ���������� ��
 
  bool    _handleAvailable[];
  double  tempBuffer[];
  bool    recalculate;
 
  ENUM_TIMEFRAMES _TFs[];
 
 public:
  CContainerBuffers(ENUM_TIMEFRAMES &TFs[]);
  ~CContainerBuffers();
               
  bool Update();
  bool isPeriodAvailable (ENUM_TIMEFRAMES period);   
  bool isFullAvailable   ();   
  CBufferTF *GetHigh (ENUM_TIMEFRAMES period);
  CBufferTF *GetLow  (ENUM_TIMEFRAMES period);
  CBufferTF *GetClose(ENUM_TIMEFRAMES period);
  CBufferTF *GetOpen (ENUM_TIMEFRAMES period);
  CBufferTF *GetPBI  (ENUM_TIMEFRAMES period);
  CBufferTF *GetATR  (ENUM_TIMEFRAMES period);   // ���� �� ������������ ATR, ���������� + isAvailable
               
  double GetHigh (ENUM_TIMEFRAMES period, int index);
  double GetLow  (ENUM_TIMEFRAMES period, int index);
  double GetClose(ENUM_TIMEFRAMES period, int index);
  double GetOpen (ENUM_TIMEFRAMES period, int index);
  double GetPBI  (ENUM_TIMEFRAMES period, int index);
  double GetATR  (ENUM_TIMEFRAMES period, int index);
               
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
// _bufferATR   = new CArrayObj();
 _bufferClose = new CArrayObj();
 _bufferOpen  = new CArrayObj();
 _allNewBars  = new CArrayObj();
 ArrayResize(_handlePBI,_tfCount);
// ArrayResize(_handleATR,_tfCount);
 ArrayResize(_handleAvailable,_tfCount);
 for(int i = 0; i < _tfCount; i++)
 {
  _bufferHigh.Add(new CBufferTF(TFs[i]));
  _bufferLow.Add (new CBufferTF(TFs[i]));
  _bufferPBI.Add (new CBufferTF(TFs[i]));
//  _bufferATR.Add (new CBufferTF(TFs[i]));
  _bufferClose.Add(new CBufferTF(TFs[i]));
  _bufferOpen.Add(new CBufferTF(TFs[i]));
  _allNewBars.Add(new CisNewBar(_Symbol,_TFs[i]));
   GetNewBar(TFs[i]).isNewBar();
  _handleAvailable[i] = true;
  _handlePBI[i] = DoesIndicatorExist(_Symbol, TFs[i], "PriceBasedIndicator");
  if(_handlePBI[i] == INVALID_HANDLE)
  {
   _handlePBI[i] = iCustom(_Symbol, TFs[i], "PriceBasedIndicator");
   if (_handlePBI[i] == INVALID_HANDLE)
   {
    log_file.Write(LOG_DEBUG, "�� ������� ������� ����� ���������� PriceBasedIndicator");
    Print("�� ������� ������� ����� ���������� PriceBasedIndicator �� ", PeriodToString(TFs[i]));
    _handleAvailable[i] = false;
   }
  }
  /* _handleATR[i] = iMA(_Symbol, TFs[i], 100, 0, MODE_EMA, iATR(_Symbol, TFs[i], 30));
  if (_handleATR[i] == INVALID_HANDLE)
  {
   log_file.Write(LOG_DEBUG, "�� ������� ������� ����� ���������� ATR");
   Print("�� ������� ������� ����� ���������� ATR");
   _handleAvailable[i] = false;
  }*/
 }
 recalculate = true;
 if(!Update())
  recalculate = true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CContainerBuffers::~CContainerBuffers()
{
 for(int i = 0; i < _tfCount; i++)
 {
  delete GetClose(_TFs[i]);
  delete GetHigh(_TFs[i]);
  delete GetLow(_TFs[i]);
  delete GetPBI(_TFs[i]);
  delete GetOpen(_TFs[i]);
  //delete GetATR(_TFs[i]);
  delete GetNewBar(_TFs[i]);
  IndicatorRelease(_handlePBI[i]);
  //IndicatorRelease(_handleATR[i]);
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
// CBufferTF *bufferATR  =  _bufferATR.At(i);
   CBufferTF *bufferClose = _bufferClose.At(i);
   CBufferTF *bufferOpen =  _bufferOpen.At(i);
   ArraySetAsSeries(bufferHigh.buffer, true);
   ArraySetAsSeries(bufferLow.buffer, true);
   ArraySetAsSeries(bufferPBI.buffer, true);
// ArraySetAsSeries(bufferATR.buffer, true);
   ArraySetAsSeries(bufferClose.buffer, true); 
   ArraySetAsSeries(bufferOpen.buffer, true); 
   
   if(GetNewBar(_TFs[i]).isNewBar() > 0 || recalculate)
   { 
    if(CopyHigh(_Symbol, bufferHigh.GetTF(), 0, DEPTH_MAX, bufferHigh.buffer) < DEPTH_MAX) // ���� �������� ���������� ��������������� ����
    {
     bufferHigh.SetAvailable(false); 
     log_file.Write(LOG_DEBUG,StringFormat("%s ������ ��� ����������� ������ High �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferHigh.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ High �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferHigh.GetTF()));
     return false;
    } 
    if(CopyLow(_Symbol, bufferLow.GetTF(), 0, DEPTH_MAX, bufferLow.buffer) < DEPTH_MAX )     // ����� ������������ ��� ���� �������������� ����� �� ������� �������
    {
     bufferLow.SetAvailable(false);
     log_file.Write(LOG_DEBUG,StringFormat("%s ������ ��� ����������� ������ Low �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferLow.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ Low �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferLow.GetTF()));
     return false;
    }   
    if(CopyClose(_Symbol, bufferClose.GetTF(), 0, DEPTH_MIN, bufferClose.buffer) < DEPTH_MIN)     // ����� ����������� ��� ���� �������������� ����� �� ������� �������
    {
     bufferClose.SetAvailable(false);
     log_file.Write(LOG_DEBUG,StringFormat("%s ������ ��� ����������� ������ Close �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferClose.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ Close �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferClose.GetTF()));
     return false;
    }
    if(CopyOpen(_Symbol, bufferOpen.GetTF(), 0, DEPTH_MIN, bufferOpen.buffer) < DEPTH_MIN)     // �����  ��� �������� ����  ����� �� ������� �������
    {
     bufferOpen.SetAvailable(false);
     log_file.Write(LOG_DEBUG,StringFormat("%s ������ ��� ����������� ������ Open �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferOpen.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ Open �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferOpen.GetTF()));
     return false;
    }   
    if(CopyBuffer(_handlePBI[i], 4, 0, DEPTH_MIN, bufferPBI.buffer) < DEPTH_MIN)          // ��������� ���������� ��������
    {
     bufferPBI.SetAvailable(false);
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� ����������� ������ PBI �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferPBI.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ PBI �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferPBI.GetTF()));
     return false;
    }
    bufferHigh.SetAvailable(true);
    bufferLow.SetAvailable(true);
    bufferClose.SetAvailable(true);
    bufferOpen.SetAvailable(true);
    bufferPBI.SetAvailable(true);
    /*if(CopyBuffer(_handleATR[i], 4, 1, 1, bufferATR.buffer)      < 1)   // �������� ATR
    {
     bufferATR.SetAvailable(false);
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� ����������� ������ ATR �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferATR.GetTF())));
     PrintFormat("%s ������ ��� ����������� ������ ATR �� ������� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(bufferATR.GetTF()));
     return false;
    }*/
   }
   else
   {
    if(CopyHigh(_Symbol, bufferHigh.GetTF(), 0, 1, tempBuffer) == 1)
     bufferHigh.buffer[0] = tempBuffer[0];
    if(CopyLow(_Symbol, bufferLow.GetTF(), 0, 1, tempBuffer) == 1)
     bufferLow.buffer[0] = tempBuffer[0];
    if(CopyClose(_Symbol, bufferClose.GetTF(), 0, 1, tempBuffer))
     bufferClose.buffer[0] = tempBuffer[0];
    if(CopyOpen(_Symbol, bufferOpen.GetTF(), 0, 1, tempBuffer))
     bufferOpen.buffer[0] = tempBuffer[0];
    if(CopyBuffer(_handlePBI[i], 4, 0, 1, tempBuffer) == 1)
      bufferPBI.buffer[0] = tempBuffer[0];
    else
     log_file.Write(LOG_DEBUG, " �� ������� ����������� bufferPBI");
     
    /*if(CopyBuffer(_handleATR[i], 4, 0, 1, tempBuffer))
     bufferATR.buffer[0] = tempBuffer[0];*/
   }
  }
  else 
  {
   _handlePBI[i] = DoesIndicatorExist(_Symbol, _TFs[i], "PriceBasedIndicator");
   if(_handlePBI[i] == INVALID_HANDLE)
   {
    _handlePBI[i] = iCustom(_Symbol, _TFs[i], "PriceBasedIndicator");
    if (_handlePBI[i] == INVALID_HANDLE)
    {
     log_file.Write(LOG_DEBUG, "�� ������� ������� ����� ���������� PriceBasedIndicator");
     Print("�� ������� ������� ����� ���������� PriceBasedIndicator");
     recalculate = true;
     return false;
    }
   } 
   /*else if (_handleATR[i] == INVALID_HANDLE)
   {
    log_file.Write(LOG_DEBUG, "�� ������� ������� ����� ���������� ATR");
    Print("�� ������� ������� ����� ���������� ATR");
    recalculate = true;
    return false;
   }*/
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
bool CContainerBuffers::isPeriodAvailable(ENUM_TIMEFRAMES period)
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
   btf = _bufferOpen.At(i);
   result = (result && btf.isAvailable());
   btf = _bufferPBI.At(i);
   result = (result && btf.isAvailable());
   return result;
  }
 }
 PrintFormat("%s �������� ������ ������������ ��������� �������", MakeFunctionPrefix(__FUNCTION__));
 return false;
}

bool CContainerBuffers::isFullAvailable()
{
 bool result = false;
 CBufferTF *btf;
 for ( int i = 0; i < _tfCount; i++)
 { 
   btf = _bufferHigh.At(i);
   result = btf.isAvailable();
   btf = _bufferLow.At(i);
   result = (result && btf.isAvailable());
   btf = _bufferClose.At(i);
   result = (result && btf.isAvailable());
   btf = _bufferOpen.At(i);
   result = (result && btf.isAvailable());
   btf = _bufferPBI.At(i);
   result = (result && btf.isAvailable());
 }
 PrintFormat("%s ��������� ����������� ������ result = %s", MakeFunctionPrefix(__FUNCTION__), BoolToString(result));
 return result;
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
 log_file.Write(LOG_DEBUG, StringFormat("�� ������� �������� ������ � GetHigh  �� %s", PeriodToString(period)));
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
 log_file.Write(LOG_DEBUG, StringFormat("�� ������� �������� ������ � GetLow  �� %s", PeriodToString(period)));
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
 log_file.Write(LOG_DEBUG, StringFormat("�� ������� �������� ������ � GetClose  �� %s", PeriodToString(period)));
 return new CBufferTF(period, false);
}

CBufferTF *CContainerBuffers::GetOpen(ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferOpen.At(i);
   return btf;
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("�� ������� �������� ������ � GetOpen  �� %s", PeriodToString(period))); 
 PrintFormat("�� ������� �������� ������ � GetOpen  �� %s", PeriodToString(period)); 
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
 log_file.Write(LOG_DEBUG, StringFormat("�� ������� �������� ������ � GetPBI  �� %s", PeriodToString(period)));
 return new CBufferTF(period, false);
}

/*CBufferTF *CContainerBuffers::GetATR (ENUM_TIMEFRAMES period)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferATR.At(i);
   return btf;
  }
 }
 PrintFormat("�� ������� �������� ������ � GetPBI  �� %s", PeriodToString(period));
 return new CBufferTF(period, false);
}*/

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






double CContainerBuffers::GetHigh (ENUM_TIMEFRAMES period, int index)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferHigh.At(i);
   return btf.buffer[index];
  }
 }
 PrintFormat("�� ������� �������� ������ � GetHigh  �� %s", PeriodToString(period));
 return -1;
}

double CContainerBuffers::GetLow  (ENUM_TIMEFRAMES period, int index)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferLow.At(i);
   return btf.buffer[index];
  }
 }
 PrintFormat("�� ������� �������� ������ � GetLow  �� %s", PeriodToString(period));  
 return -1;
}

double CContainerBuffers::GetClose(ENUM_TIMEFRAMES period, int index)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferClose.At(i);
   return btf.buffer[index];
  }
 }
 PrintFormat("�� ������� �������� ������ � GetClose  �� %s", PeriodToString(period)); 
 return -1;
}

double CContainerBuffers::GetOpen(ENUM_TIMEFRAMES period, int index)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferOpen.At(i);
   return btf.buffer[index];
  }
 }
 PrintFormat("�� ������� �������� ������ � GetOpen  �� %s", PeriodToString(period)); 
 return -1;
}

double CContainerBuffers::GetPBI (ENUM_TIMEFRAMES period, int index)
{
 for(int i = 0; i < _tfCount; i++)
 {
  if(_TFs[i] == period)
  {
   CBufferTF *btf = _bufferPBI.At(i);
   return btf.buffer[index];
  }
 }
 PrintFormat("�� ������� �������� ������ � GetPBI  �� %s", PeriodToString(period));
 return -1;
}
