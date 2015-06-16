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
#include <Strings\String.mqh>
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
   
   ushort            _counter;        // [0-9] ��������, ToDo ������� ���������� ����� �������
   string            _symbolmass[10]; // ������� ��������� ������ � _counter

   CArrayObj         *aEvents;
   //ushort            id_array[];    // ������ id �������
   //string            name_array[];  // ������ ���� �������
   string            _symbol;       // ������
   ENUM_TIMEFRAMES   _period;       // ���������      
   SEventData        _data;

private:
// ��������� ������ ������
   int  GetEventIndByName(string event_name);                     // ����������  ������ ID ������� � ������� �� ����� �������
   long GenerateEventID (string event_name);  // ����� ��������� ��� ID ������� 

public:
   void CEventBase(string symbol,ENUM_TIMEFRAMES period,const ushort startid)
     {
      this.start_id=startid;
      this._symbol = symbol;
      this._period = period;
      this._counter = 0;
      aEvents = new CArrayObj();
      log_file.Write(LOG_DEBUG, StringFormat("��� ������ ������ CEventBase � ����������� start_id = %i symbol  = %s period = %s", startid, symbol, PeriodToString(period)));
     };
   void ~CEventBase(void) // �������� 16.06.2015 �� ����� �������� �������, ����� ������ � 4001
   {
    aEvents.Clear();
    delete aEvents;
   };
   //--
   bool AddNewEvent(string event_name);   // ����� ��������� ����� ������� �� ��������� ������� � �� � �������� ������   
   
   bool Generate(long _chart_id, int _id_ind, SEventData &_data,
                 const bool _is_custom=true);                       // ��������� ������� �� ������� 
   void Generate(string event_name, SEventData &_data, 
                 const bool _is_custom = true);                     // ��������� �������, ���������� �� ���� ��������
                              
   string GenUniqEventName (string event_name);                      // ���������� ���������� ��� ������� 
  };  
  
// ���������� ������ ID ������� � ������� �� ����� �������
int CEventBase::GetEventIndByName(string event_name)
 {
  for(int i = 0; i < aEvents.Total(); i++)
   {
    CEvent *event = aEvents.At(i);
    if (event.name == event_name)
     return (i);
   }
  return (-1); 
 }  

// �������, ������������ ��� ID �������
long CEventBase::GenerateEventID (string event_name)
 {
  ulong ulHash = 5381;
  for(int i = StringLen(event_name) - 1; i >= 0; i--)
  {
   ulHash = ((ulHash<<5) + ulHash) + StringGetCharacter(event_name,i);
  }
  return MathAbs((long)ulHash);
 }   
  
// ��������� ����� �������
bool CEventBase::AddNewEvent(string event_name)
 {
  long tmp_id;
  int ind;  // ������� ������� �� ������
  string generatedName = GenUniqEventName(event_name);
  // ���� ��� �� ������, ������ ��� ������ => ����� ��������� ��� ������������
  if (generatedName != "")
   {
    for (ind=0; ind<aEvents.Total(); ind++)
     {
      CEvent *event = aEvents.At(ind);
      if (event.name == generatedName)
       {
        PrintFormat("%s �� ������� �������� ����� id �������, ��������� ������ �� ���������� ���", MakeFunctionPrefix(__FUNCTION__));
        return (false);
       }
     }
   }   
  tmp_id = GenerateEventID(generatedName);
  if (tmp_id == 0)
   {
    PrintFormat("%s �� ������� �������� ����� id �������, ��������� �� ������� ��� ���������", MakeFunctionPrefix(__FUNCTION__));
    return (false);
   } 
  // �������� �� ������ id ��� �������� ������������ id
  for (ind=0; ind<aEvents.Total(); ind++)
   {
    CEvent *event = aEvents.At(ind);
    // ���� ��� ��� �������� id
    if (event.id == tmp_id)
     {
      Print("�� ������� �������� ����� id �������, ��������� ����� id ��� ���������� Symbol = ",_symbol," period = ",PeriodToString(_period)," name = ",event_name );
      return (false);
     }
   }
  // ��������� ����� ������� � �����
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
   this._data = _data;
   this._data.sparam = event.name; // ��������� ��� �������
   
   if(_is_custom)
     {
      ResetLastError();
      is_generated = EventChartCustom(_chart_id, event.id, this._data.lparam,
                                      this._data.dparam, this._data.sparam);
      if(!is_generated && _LastError != 4104)
         {
          Print("is_generated = ", BoolToString(is_generated));
          PrintFormat("%s Error while generating a custom event: %d", __FUNCTION__,_LastError);
          Print( ChartSymbol(_chart_id)," ",PeriodToString(ChartPeriod(_chart_id)), "������! _chart_id =", _chart_id, " event.id = ", event.id, " data.dparam = " ,this._data.dparam, " data.sparam = ", this._data.sparam);
          log_file.Write(LOG_DEBUG, StringFormat("time = %s", TimeToString(TimeCurrent())));
          log_file.Write(LOG_DEBUG, StringFormat("is_generated = %s", BoolToString(is_generated)));
          log_file.Write(LOG_DEBUG, StringFormat("%s Error while generating a custom event: %d", __FUNCTION__,_LastError));
          log_file.Write(LOG_DEBUG, StringFormat("chart_id = %s , ChartPeriod = %s  ������! event.id = %d data.dparam = %f data.sparam = %s", ChartSymbol(_chart_id),PeriodToString(ChartPeriod(_chart_id)), event.id, this._data.dparam,  this._data.sparam));
         }
     }
   return is_generated;
  }

//+------------------------------------------------------------------+
//| ����� ���������� ������� �� ��� �������                          |
//+------------------------------------------------------------------+
void CEventBase::Generate(string event_name, SEventData &_data, const bool _is_custom = true)
{
 // �������� �� ���� �������� �������� � ������� �������� � �� � ���������� ��� ��� �������
 long chart_id = ChartFirst();
 _data.sparam = GenUniqEventName(event_name);
 
 // ���� ��� ������� �� ������ � ������
 for (int ind=0; ind < aEvents.Total(); ind++)
  {
   // ���� ����� ������� �� �����
   CEvent *event = aEvents.At(ind);
   if (event.name == _data.sparam)
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
string CEventBase::GenUniqEventName(string event_name)
 {
  return (event_name + "_" + _symbol + "_" + PeriodToString(_period));
 } 
 