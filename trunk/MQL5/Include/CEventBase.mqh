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
   void  SEventData:: SEventData(const SEventData &_src_data)
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

class CEventBase : public CObject
  {
// ���������� ���� ������
protected:
   ENUM_EVENT_TYPE   m_type;
   ushort            start_id;   // ����������� ��� 
   ushort            m_id;
   ushort            id_array[]; // ������ id �������
   string            id_name[];  // ������ ���� �������
   int               id_count;   // ���������� id �������
   string            _symbol;    // ������
   ENUM_TIMEFRAMES   _period;    // ���������      
   SEventData        m_data;

private:
// ��������� ������ ������
   int  GetEventIndByName(string eventName); // ����������  ������ ID ������� � ������� �� ����� �������
   int  GetSymbolCode(string symbol);   // ���������� ��� ������� �� �������
   long GenerateIsNewBarEventID (string symbol,ENUM_TIMEFRAMES period);  // ����� ��������� ��� ID ������� 

public:
   void              CEventBase(string symbol,ENUM_TIMEFRAMES period,const ushort startid)
     {
      this.m_id=0;
      this.m_type=EVENT_TYPE_NULL;
      this.start_id=start_id;
      this.id_count = 0; 
      this._symbol = symbol;
      this._period = period;
     };
   void             ~CEventBase(void){};
   //--
   bool AddNewEvent(string eventName);   // ����� ��������� ����� ������� �� ��������� ������� � �� � �������� ������   
   
   bool              Generate(long _chart_id, int _id_ind, SEventData &_data,
                              const bool _is_custom=true);                       // ��������� ������� �� �������
   bool              Generate(long _chart_id,string id_nam,SEventData &_data, 
                              const bool _is_custom=true);                       // ���������� ������� �� ����� ������� 
  
   void              Generate(string id_nam, SEventData &_data, 
                              const bool _is_custom = true);                     // ��������� �������, ���������� �� ���� ��������
                              
   ushort            GetId(void) {return this.m_id;};                            // ���������� ID �������
   
   string            GenUniqEventName (string eventName);                        // ���������� ���������� ��� ������� 
                                               
   void  PrintAllNames();                                            
   
private:
   virtual bool      Validate(void) {return true;};
  };  
  
// ���������� ������ ID ������� � ������� �� ����� �������
int CEventBase::GetEventIndByName(string eventName)
 {
  for (int ind=0;ind<id_count;ind++)
   {
    if (id_name[ind] == eventName)
     return (ind);
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
long CEventBase::GenerateIsNewBarEventID (string symbol,ENUM_TIMEFRAMES period)
 {
  int scode = GetSymbolCode(symbol);
  if (scode == 0)
   return (0);    // ��� ���� ID
  return (start_id + 100*int(period)+10*scode+id_count);   // ���������� ��� ID �������
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
    for (ind=0;ind<id_count;ind++)
     {
      if (id_name[ind] == generatedName)
       {
        Print("�� ������� �������� ����� id �������, ��������� ������ �� ���������� ���");
        return (false);
       }
     }
   }   
  tmp_id = GenerateIsNewBarEventID(_symbol, _period);
  if (tmp_id == 0)
   {
    Print("�� ������� �������� ����� id �������, ��������� �� ������� ��� ���������");
    return (false);
   } 
  // �������� �� ������ id ��� �������� ������������ id
  for (ind=0;ind<id_count;ind++)
   {
    // ���� ��� ��� �������� id
    if (id_array[ind]==tmp_id)
     {
      Print("�� ������� �������� ����� id �������, ��������� ����� id ��� ���������� Symbol = ",_symbol," period = ",PeriodToString(_period)," name = ",eventName );
      return (false);
     }
   }
  // ��������� ����� id � �����
  
  ArrayResize(id_array,id_count+1);
  ArrayResize(id_name,id_count+1);
  id_array[id_count] = tmp_id;
  id_name[id_count]  = generatedName;
  id_count++;
  
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
   if (_id_ind < 0 || _id_ind >= id_count)
    {
     Print("�� ����� ����� ������ ID �������");
     return (false);
    }
   // ��������� ���� 
   this.m_id = (ushort)(CHARTEVENT_CUSTOM+id_array[_id_ind]);
   this.m_data = _data;
   this.m_data.sparam = id_name[_id_ind]; // ��������� ��� �������
   
   if(_is_custom)
     {
      ResetLastError();
      is_generated = EventChartCustom(_chart_id,id_array[_id_ind],this.m_data.lparam,
                                    this.m_data.dparam,this.m_data.sparam);
      if(!is_generated && _LastError!=4104)
         Print("Error while generating a custom event: ",_LastError);
     }
   if(is_generated)
     {
      is_generated = this.Validate();
      if(!is_generated)
         this.m_id = 0;
     }
   return is_generated;
  }

//+------------------------------------------------------------------+
//| ����� ���������� ������� �� �����                                |
//+------------------------------------------------------------------+
bool CEventBase::Generate(long _chart_id,string id_nam,SEventData &_data,const bool _is_custom=true)
 {
  int ind_id = GetEventIndByName(id_nam);   // �������� ������ ID ������� � ������� �� ����� �������
  // ���� �� ������ ������
  if ( ind_id == -1)
   {
    Print("�� ������� ����� ������ ������� �� ����� ",id_nam);
    return (false);
   }
  Generate(_chart_id,ind_id,_data,_is_custom);
  return (true);
 }

//+------------------------------------------------------------------+
//| ����� ���������� ������� �� ��� �������                          |
//+------------------------------------------------------------------+
void CEventBase::Generate(string id_nam, SEventData &_data, const bool _is_custom = true)
{
 // �������� �� ���� �������� �������� � ������� �������� � �� � ���������� ��� ��� �������
 long z = ChartFirst();
 int ind;
 string eventName = GenUniqEventName(id_nam);
 _data.sparam = eventName;
 // ���� ��� ������� �� ������ � ������
 for (ind=0;ind<id_count;ind++)
  {
   // ���� ����� ������� �� �����
   if (id_name[ind] == eventName)
    {     
      // �������� �� ���� �������� � ������� �������
      while (z >= 0)
       {
        // ������� ������� ��� �������� �������
        Generate(z,id_name[ind],_data,_is_custom);
        z = ChartNext(z);      
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
  return ( eventName + "_" + _symbol + "_" + PeriodToString(_period) );
 } 
 
void CEventBase::PrintAllNames(void)
 {
  for(int i=0;i<ArraySize(id_name);i++)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%i ��� = %s",i,id_name[i]) );  
   }
 }