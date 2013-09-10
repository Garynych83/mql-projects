//+------------------------------------------------------------------+
//|                                         CHistoryTradeManager.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CLog.mqh>

#define INITIAL_BALANCE 10000

enum ENUM_HTM_POSITION_TYPE
{
 EMPTY,
 BUY,
 SELL
};

struct virtual_position
{
 ENUM_HTM_POSITION_TYPE type;// ����������� ����������� ������� (0-��� �������� �������,+1 �������,-1 �������)
 //double   volume;            // ����� ������� � �����
 //double   profit;            // ������� ������� �������� ����������� ������� � �������
 //datetime time_open;         // ���� � ����� �������� ����������� �������
 //datetime time_close;        // ���� � ����� �������� ����������� �������
 double   price;             // ���� ����������� �������
};

class CHistoryTradeManager
{
 private:
 bool _is_position;              //���� ������� �������� �������
 virtual_position _position;     //����������� �������
 
 double _balance;                //������ �����
 MqlRates _rates[];              //������ ���������
 
 double _profit;                 //���������� ��� ����� �������������� ������ : ������ �� ������� ������
 int _count_order;               //���������� ��� ����� �������������� ������ : ������� ������
 
 public:
 CHistoryTradeManager(string symbol, ENUM_TIMEFRAMES tf, int depth);
~CHistoryTradeManager(); 
 void   UpdateInfo();
 void   OpenPosition(ENUM_HTM_POSITION_TYPE type, int index); 
 bool   ClosePosition(int index);
 int    GetCountOrder() { return(_count_order); }
 double GetProfit()     { return(_profit); }
 double GetBalance()    { return(_balance); }
};

CHistoryTradeManager::CHistoryTradeManager(string symbol, ENUM_TIMEFRAMES tf, int depth):
                      _balance (INITIAL_BALANCE),
                      _profit (0),
                      _count_order (0)
{
 ArrayResize(_rates, depth);
 ArraySetAsSeries(_rates, true);
 int copiedRates = -1;
 for(int attempts = 0; attempts < 25 && copiedRates < 0; attempts++)
 {
  copiedRates = CopyRates(symbol, tf, 0, depth, _rates);
 }
 if(copiedRates != depth)
 {
  Alert("�� ������� ����������� ������ ���������.");
  return;
 }
 log_file.Write (LOG_DEBUG, StringFormat("%s �������������", __FUNCTION__));
}

CHistoryTradeManager::~CHistoryTradeManager(void)
{
 ArrayFree(_rates);
 log_file.Write (LOG_DEBUG, StringFormat("%s ���������������", __FUNCTION__));
}

void CHistoryTradeManager::UpdateInfo()
{
 //?
}

void CHistoryTradeManager::OpenPosition(ENUM_HTM_POSITION_TYPE type, int index)
{
 if(_is_position) 
 {// ���� ���� �������� ������� ��������������� ����������� - ���������
  switch(type)
  {
   case BUY:
    if(_position.type == SELL)
    {
     ClosePosition (index);
    }
    break;
   case SELL:
    if(_position.type == BUY)
    {
     ClosePosition (index);
    }
    break;
  }
 }
 //�������� ����� �������
 _is_position = true;
 _position.type  = type;
 _position.price = _rates[index].close;
 _balance -= _position.price;
 _count_order++;
 log_file.Write (LOG_DEBUG, StringFormat("%s ������� ������� ���� %s. ������� ������ %f", __FUNCTION__, EnumToString((ENUM_HTM_POSITION_TYPE)type), _balance));
}

bool CHistoryTradeManager::ClosePosition(int index)
{
 if (_is_position)
 {
  _is_position = false;
  _balance += _rates[index].close;
  _profit = _balance - INITIAL_BALANCE;
  log_file.Write (LOG_DEBUG, StringFormat("%s ������� ������� ���� %s. ������� ������ %f. ������� ������ %f.", 
                                          __FUNCTION__, EnumToString((ENUM_HTM_POSITION_TYPE)_position.type), _balance, _profit));
  _position.type = EMPTY;
  _position.price = 0;
  return true;
 }
 return false;
}