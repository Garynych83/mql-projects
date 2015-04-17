//+------------------------------------------------------------------+
//|                                                        Event.mqh |
//|                                           Copyright 2014, denkir |
//|                           https://login.mql5.com/ru/users/denkir |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, denkir"
#property link      "https://login.mql5.com/ru/users/denkir"
#property version   "1.00"

//+------------------------------------------------------------------+
//| ����������� ���������                                            |
//+------------------------------------------------------------------+
#include <Object.mqh>
#include <Arrays\ArrayObj.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>                                       // ��� ����
//+------------------------------------------------------------------+
//| A custom event type enumeration                                  |
//+------------------------------------------------------------------+
enum ENUM_EVENT_TYPE
  {
   EVENT_TYPE_NULL=0,      // no event
   EVENT_TYPE_EXTREMUMS=1  // extremums event
  };
//+------------------------------------------------------------------+
//| A custom event data                                              |
//+------------------------------------------------------------------+
struct SEventData
  {
   long              lparam;
   double            dparam;
   string            sparam;
   //--- default constructor
   void SEventData::SEventData(void)
     {
      lparam=0;
      dparam=0.0;
      sparam=NULL;
     }
   //--- copy constructor
   void SEventData::SEventData(const SEventData &_src_data)
     {
      lparam=_src_data.lparam;
      dparam=_src_data.dparam;
      sparam=_src_data.sparam;
     }
   //--- assignment operator
   void operator=(const SEventData &_src_data)
     {
      lparam=_src_data.lparam;
      dparam=_src_data.dparam;
      sparam=_src_data.sparam;
     }
  };
  
class CEvent : public CObject
{
 public:
  ushort id;
  string name;
  
  void CEvent(ushort _id, string _name): id(_id), name(_name){};
};

class CEventBase : public CObject
  {
// ���������� ���� ������
protected:
   ushort            start_id;   // ����������� ��� 
   ushort            _id;
   CArrayObj         *aEvents;
   //ushort            id_array[];    // ������ id �������
   //string            name_array[];  // ������ ���� �������
   string            _symbol;       // ������
   ENUM_TIMEFRAMES   _period;       // ���������      
   SEventData        _data;

private:
// ��������� ������ ������
   int  GetEventIndByName(string eventName);                     // ����������  ������ ID ������� � ������� �� ����� �������
   int  GetSymbolCode(string symbol);                            // ���������� ��� ������� �� �������
   long GenerateEventID (string symbol,ENUM_TIMEFRAMES period);  // ����� ��������� ��� ID ������� 

public:
   void CEventBase(string symbol,ENUM_TIMEFRAMES period,const ushort startid)
     {
      this._id=0;
      this.start_id=startid;
      this._symbol = symbol;
      this._period = period;
      aEvents = new CArrayObj();
     };
   void ~CEventBase(void){};
   //--
   bool AddNewEvent(string eventName);   // ����� ��������� ����� ������� �� ��������� ������� � �� � �������� ������   
   
   bool Generate(long _chart_id, int _id_ind, SEventData &_data,
                 const bool _is_custom=true);                       // ��������� ������� �� ������� 
   void Generate(string id_nam, SEventData &_data, 
                 const bool _is_custom = true);                     // ��������� �������, ���������� �� ���� ��������
                              
   string GenUniqEventName (string eventName);                      // ���������� ���������� ��� ������� 
  };  
  
// ���������� ������ ID ������� � ������� �� ����� �������
int CEventBase::GetEventIndByName(string eventName)
 {
  for(int i = 0; i < aEvents.Total(); i++)
   {
    CEvent *event = aEvents.At(i);
    if (event.name == eventName)
     return (i);
   }
  return (-1); 
 }  
  
// ������� ���������� ��� �� �������
int CEventBase::GetSymbolCode (string symbol)
 {
    if (symbol == "EURUSD")
     return (1);
    if (symbol == "GBPUSD")
     return (2);
    if (symbol == "USDCHF")
     return (3);
    if (symbol == "USDJPY")
     return (4);
    if (symbol == "USDCAD")
     return (5);
    if (symbol == "AUDUSD")
     return (6);
  return (0); 
 }

// �������, ������������ ��� ID �������
long CEventBase::GenerateEventID (string symbol,ENUM_TIMEFRAMES period)
 {
  int scode = GetSymbolCode(symbol);
  if (scode == 0)
   return (0);    // ��� ���� ID
  return (start_id + 100*int(period)+10*scode+aEvents.Total());   // ���������� ��� ID �������
 }   
  
// ��������� ����� �������
bool CEventBase::AddNewEvent(string eventName)
 {
  long tmp_id;
  int ind;  // ������� ������� �� ������
  string generatedName = GenUniqEventName(eventName);
  // ���� ��� �� ������, ������ ��� ������ => ����� ��������� ��� ������������
  if (generatedName != "")
   {
    for (ind=0; ind<aEvents.Total(); ind++)
     {
      CEvent *event = aEvents.At(ind);
      if (event.name == generatedName)
       {
        Print("�� ������� �������� ����� id �������, ��������� ������ �� ���������� ���");
        return (false);
       }
     }
   }   
  tmp_id = GenerateEventID(_symbol, _period);
  if (tmp_id == 0)
   {
    Print("�� ������� �������� ����� id �������, ��������� �� ������� ��� ���������");
    return (false);
   } 
  // �������� �� ������ id ��� �������� ������������ id
  for (ind=0; ind<aEvents.Total(); ind++)
   {
    CEvent *event = aEvents.At(ind);
    // ���� ��� ��� �������� id
    if (event.id == tmp_id)
     {
      Print("�� ������� �������� ����� id �������, ��������� ����� id ��� ���������� Symbol = ",_symbol," period = ",PeriodToString(_period)," name = ",eventName );
      return (false);
     }
   }
  // ��������� ����� id � �����
  CEvent *event = new CEvent(tmp_id, generatedName);
  aEvents.Add(event);
  return (true);
 }  
  
//+------------------------------------------------------------------+
//| ����� ���������� �������                                         |
//+------------------------------------------------------------------+
bool CEventBase::Generate(long _chart_id, int _id_ind, SEventData &_data,
                          const bool _is_custom=true)
  {
   bool is_generated = true;
   // ���� ������ id ������� � ������� �� �����
   if (_id_ind < 0 || _id_ind >= aEvents.Total())
    {
     Print("�� ����� ����� ������ ID �������");
     return (false);
    }
   // ��������� ���� 
   CEvent *event = aEvents.At(_id_ind);
   this._id = (ushort)(CHARTEVENT_CUSTOM+event.id);
   this._data = _data;
   this._data.sparam = event.name; // ��������� ��� �������
   
   if(_is_custom)
     {
      ResetLastError();
      is_generated = EventChartCustom(_chart_id, event.id, this._data.lparam,
                                      this._data.dparam, this._data.sparam);
      if(!is_generated && _LastError!=4104)
         {
          Print("is_generated = ", is_generated);
          PrintFormat("%s Error while generating a custom event: %d", __FUNCTION__,_LastError);
          Print( ChartSymbol(_chart_id)," ",ChartPeriod(_chart_id), "������! _chart_id =", _chart_id, " event.id = ", event.id, " data.dparam = " ,this._data.dparam, " data.sparam = ", this._data.sparam);
         }
     }
   return is_generated;
  }

//+------------------------------------------------------------------+
//| ����� ���������� ������� �� ��� �������                          |
//+------------------------------------------------------------------+
void CEventBase::Generate(string id_nam, SEventData &_data, const bool _is_custom = true)
{
 // �������� �� ���� �������� �������� � ������� �������� � �� � ���������� ��� ��� �������
 long chart_id = ChartFirst();
 int ind;
 string eventName = GenUniqEventName(id_nam);
 _data.sparam = eventName;
 // ���� ��� ������� �� ������ � ������
 for (ind=0; ind<aEvents.Total(); ind++)
  {
   // ���� ����� ������� �� �����
   CEvent *event = aEvents.At(ind);
   if (event.name == eventName)
    {     
      // �������� �� ���� �������� � ������� �������
      while (chart_id >= 0)
       {
        // ������� ������� ��� �������� �������
        int ind_id = GetEventIndByName(event.name);
        Generate(chart_id, ind_id, _data, _is_custom);
        chart_id = ChartNext(chart_id);      
       }  
      return;
    }
  }
} 

//+------------------------------------------------------------------+
//| ����� ���������� ���������� ��� �������                          |
//+------------------------------------------------------------------+
string CEventBase::GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _symbol + "_" + PeriodToString(_period));
 } 
 