//+------------------------------------------------------------------+
//|                                               CChickensBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              ht_tp://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "ht_tp://www.mql5.com"
#property version   "1.00"

#include <Brain.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>  

#define DEPTH 20
#define ALLOW_INTERVAL 4

//+------------------------------------------------------------------+
//|        ����� CChickensBrain  ������������ ��� ���������� ����    |
//|                              ������� ������� �������� ���������  |                                                          |
//+------------------------------------------------------------------+
class CChickensBrain : public CBrain
{
 private:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  int _tmpLastBar;
  int _lastTrend;          // ��� ���������� ������ �� PBI 
  int _magic;              // ���������� ����� ��� ����� ������
  ENUM_SIGNAL_FOR_TRADE _current_direction;  // ������������ ���������� ������� (SEll, BUY, NO_SIGNAL(0) - �������� ���������)

  bool recountInterval;    // ��� ������� ��������� �� GetSignal() �������� ������������ ����� ������)
  CisNewBar *isNewBar;     // ����� ��� �� ��
  CContainerBuffers *_conbuf;
  // ����, ������ � ������� ���������� ����� ������� Get...()
  int _index_max;
  int _index_min;
  int _diff_high; 
  int _diff_low; 
  int _priceDifference;
  int _sl_min;   
  int _expiration;      
  double _highBorder; 
  double _lowBorder;

  
 public:
  
   CChickensBrain(string symbol, ENUM_TIMEFRAMES period, CContainerBuffers *conbuf);
   ~CChickensBrain();
   virtual ENUM_TM_POSITION_TYPE  GetSignal();
   virtual long   GetMagic(){return _magic;}
   virtual string  GetName(){return StringFormat("CChickensBrain_%s",PeriodToString(_period));};
   virtual ENUM_SIGNAL_FOR_TRADE  GetDirection(){return _current_direction;}
   virtual ENUM_TIMEFRAMES GetPeriod(){return _period;}
   virtual int  CountTakeProfit();
   virtual int  CountStopLoss();
   virtual int  GetPriceDifference(){return _priceDifference;}
   virtual int  GetExpiration()     {return _expiration;};
   int GetLastMoveType ();
   int GetIndexMax()      { return _index_max;}
   int GetIndexMin()      { return _index_min;}
};
//+------------------------------------------------------------------+
//|      �����������                                                 |
//+------------------------------------------------------------------+
CChickensBrain::CChickensBrain(string symbol, ENUM_TIMEFRAMES period, CContainerBuffers *conbuf)
{
 _conbuf = conbuf;
 _symbol = symbol;
 _period = period;
 _current_direction = SELL;
 _expiration = 0;
 _priceDifference = 0;
 isNewBar = new CisNewBar(_symbol, _period);
 _index_max = -1;
 _index_min = -1;
 _lastTrend = 0; 
 isNewBar.isNewBar();
 recountInterval = true;
 log_file.Write(LOG_DEBUG, StringFormat(" CChickensBrain �� %s ������ ������� ", PeriodToString(_period)));
}
//+------------------------------------------------------------------+
//|      ����������                                                  |
//+------------------------------------------------------------------+
CChickensBrain::~CChickensBrain()
{
 delete isNewBar;
 delete _conbuf;

}
//+------------------------------------------------------------------+
//|      ����� GetSignal() ���������� ������ �������� SELL/BUY       |                                                 
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE CChickensBrain::GetSignal()
{
 _index_max = -1;
 _index_min = -1;
 if(isNewBar.isNewBar() || recountInterval)
 { 
  if(!_conbuf.isPeriodAvailable(_period))
   log_file.Write(LOG_DEBUG,StringFormat("%s ����� �� �������� ��� ������������� �������", MakeFunctionPrefix(__FUNCTION__)));
   
  // �������� ������� �������� ���� �� ��������������� �������
  _index_max = ArrayMaximum(_conbuf.GetHigh(_period).buffer, 2, DEPTH-1);
  _index_min = ArrayMinimum(_conbuf.GetLow(_period).buffer, 2, DEPTH-1);
  recountInterval = false;
  // �������� ��� �������� �� ��������� ����
  _tmpLastBar = GetLastMoveType();
  if (_tmpLastBar != 0)
  {
   _lastTrend = _tmpLastBar;
   log_file.Write(LOG_DEBUG, StringFormat("��������� ��������� �������� lastTrend = %d", _lastTrend));
  }
  log_file.Write(LOG_DEBUG,StringFormat("buffer_pbi[0] = %d index_max = %d, index_min = %d", int(_conbuf.GetPBI(_period).buffer[0]),_index_max, _index_min ));
  if (_conbuf.GetPBI(_period).buffer[0] == MOVE_TYPE_FLAT && _index_max != -1 && _index_min != -1)
  { 
   // �������� ������� � ������ ���� � ����
   _highBorder = _conbuf.GetHigh(_period).buffer[_index_max];
   _lowBorder  = _conbuf.GetLow(_period).buffer[_index_min];
   _sl_min     = MathMax((int)MathCeil((_highBorder - _lowBorder) * 0.10/Point()), 50);
   _diff_high  = (int)((_conbuf.GetHigh(_period).buffer[1] - _highBorder)/Point());
   _diff_low   = (int)((_lowBorder - _conbuf.GetLow(_period).buffer[1])/Point());
   
   log_file.Write(LOG_DEBUG, StringFormat("����� = %s �� = %s", TimeToString(TimeCurrent()), PeriodToString(_period)));
   log_file.Write(LOG_DEBUG, StringFormat("buffer_pbi[0] == %d  _index_max = %d _index_min = %d", int(_conbuf.GetPBI(_period).buffer[0]), _index_max ,_index_min ));
   log_file.Write(LOG_DEBUG, StringFormat("_lowBorder ( %f ) - Low[DEPTH] ( %f )  = %f",  _lowBorder, _conbuf.GetLow(_period).buffer[1], _lowBorder - _conbuf.GetLow(_period).buffer[1]));
   log_file.Write(LOG_DEBUG, StringFormat("High[0]( %f ) - _highBorder( %f )  = %f",  _conbuf.GetHigh(_period).buffer[1], _highBorder, _conbuf.GetHigh(_period).buffer[1] - _highBorder));
   log_file.Write(LOG_DEBUG, StringFormat("%d > %d && %f > %f && %d > %d && _lastTrend = %d", _index_max, ALLOW_INTERVAL,_conbuf.GetClose(_period).buffer[1],_highBorder,_diff_high,_sl_min,_lastTrend));
   log_file.Write(LOG_DEBUG, "_index_max > ALLOW_INTERVAL && GreatDoubles(closePrice[0], _highBorder) && _diff_high > _sl_min && _lastTrend == SELL");
   log_file.Write(LOG_DEBUG, StringFormat("%d > %d && %f < %f && %d > %d && _lastTrend = %d", _index_min, ALLOW_INTERVAL,_conbuf.GetClose(_period).buffer[1],_lowBorder,_diff_low,_sl_min,_lastTrend));
   log_file.Write(LOG_DEBUG, "_index_min > ALLOW_INTERVAL && LessDoubles(closePrice[0], _lowBorder) && _diff_low > _sl_min && _lastTrend == BUY");
   
   if(_index_max > ALLOW_INTERVAL && GreatDoubles(_conbuf.GetClose(_period).buffer[1], _highBorder) && _diff_high > _sl_min && _lastTrend == SELL)
   { 
    log_file.Write(LOG_DEBUG, StringFormat("���� �������� ������� ���� �������� = %s, ����� = %s, ���� = %.05f, _sl_min = %d, _diff_high = %d",
          DoubleToString(_highBorder, 5),
          TimeToString(TimeCurrent()),
          _conbuf.GetClose(_period).buffer[0],
          _sl_min, _diff_high));
    /*PrintFormat("���� �������� ������� ���� �������� = %s, ����� = %s, ���� = %.05f, _sl_min = %d, _diff_high = %d",
          DoubleToString(_highBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          _sl_min, _diff_high);*/
    _priceDifference = (int)((_conbuf.GetClose(_period).buffer[0] - _highBorder)/Point());
    _current_direction = SELL;
    return OP_SELLSTOP;
   }
    
   if(_index_min > ALLOW_INTERVAL && LessDoubles(_conbuf.GetClose(_period).buffer[1], _lowBorder) && _diff_low > _sl_min && _lastTrend == BUY)
   {
    log_file.Write(LOG_DEBUG, StringFormat("���� �������� ������� ���� ������� = %s, ����� = %s, ���� = %.05f, _sl_min = %d, _diff_low = %d",
          DoubleToString(_lowBorder, 5),
          TimeToString(TimeCurrent()),
          _conbuf.GetClose(_period).buffer[0],
          _sl_min, _diff_low));
    /*PrintFormat("���� �������� ������� ���� ������� = %s, ����� = %s, ���� = %.05f, _sl_min = %d, _diff_low = %d",
          DoubleToString(_lowBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          _sl_min, _diff_low);*/
    _priceDifference = (int)((_lowBorder - _conbuf.GetClose(_period).buffer[0])/Point());
    _current_direction = BUY;
    return OP_BUYSTOP;
   }
  } 
  else
  {
   _current_direction = NO_SIGNAL; //(=0)
   return OP_UNKNOWN;
   //return DISCORD;
  }
 } 
 return OP_UNKNOWN;
}

//+------------------------------------------------------------------+
//|      ����� GetLastMoveType()��� �������� ���� �� ��������� ����  |                                                 
//+------------------------------------------------------------------+
int  CChickensBrain::GetLastMoveType () // �������� ��������� �������� PriceBasedIndicator
{
 int signTrend;

 signTrend = int(_conbuf.GetPBI(_period).buffer[0]);
 log_file.Write(LOG_DEBUG, StringFormat("��� ������ �� ��������� ����: %d", int(_conbuf.GetPBI(_period).buffer[0])));

  // ���� ����� �����
 if (signTrend == 1 || signTrend == 2)
 {
  log_file.Write(LOG_DEBUG, StringFormat("��������� pbi = %d � ��� +1", int(_conbuf.GetPBI(_period).buffer[0])));
  return (1);
 }
 // ���� ����� ����
 if (signTrend == 3 || signTrend == 4)
 {
  log_file.Write(LOG_DEBUG, StringFormat("��������� pbi = %d � ��� -1", int(_conbuf.GetPBI(_period).buffer[0])));
  return (-1);
 }
 log_file.Write(LOG_DEBUG, StringFormat("��������� pbi = %d ", int(_conbuf.GetPBI(_period).buffer[0])));
 return (0);
}

int CChickensBrain::CountStopLoss(void)
{
 int stop_level;
 int sl = 0;
 if(_current_direction == SELL)
  sl = _diff_high;
 if(_current_direction == BUY)
  sl = _diff_low;
  
 stop_level = (int)SymbolInfoInteger(_symbol, SYMBOL_TRADE_STOPS_LEVEL);
 if(sl > stop_level)
  return sl;
 else
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������������ �������� �� ������������� ��������� sl = %d", MakeFunctionPrefix(__FUNCTION__), stop_level));
  return stop_level;
 }
}

int CChickensBrain::CountTakeProfit()
{
 
 return (int)MathCeil((_highBorder - _lowBorder)*0.75/Point());
}