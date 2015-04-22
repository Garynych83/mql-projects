//+------------------------------------------------------------------+
//|                                               CChickensBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              ht_tp://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "ht_tp://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBarDD.mqh>
#include <TradeManager\TradeManager.mqh>   //���� ����� ���������, ����� ��?
#include <CLog.mqh>                         // ��� ����

#define DEPTH 20
#define ALLOW_INTERVAL 16
// ��������� ��������
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0
#define NO_ENTER 2
//+------------------------------------------------------------------+
//|        ����� CChickensBrain  ������������ ��� ���������� ����    |
//|                              ������� ������� �������� ���������  |                                                          |
//+------------------------------------------------------------------+
class CChickensBrain
{
 private:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  int _handle_pbi; 
  int _tmpLastBar;
  int _lastTrend;            // ��� ���������� ������ �� PBI 
  double buffer_pbi[];
  double buffer_high[];
  double buffer_low[];
  double highPrice[], lowPrice[], closePrice[];
 
  bool recountInterval;
  CisNewBar *isNewBar;
  // ����, ������ � ������� ���������� ����� ������� Get...()
  int _index_max;
  int _index_min;
  int _diff_high; 
  int _diff_low; 

  int _sl_min;
  double _highBorder; 
  double _lowBorder;
  double _priceDifference;
  
 public:
  
                     CChickensBrain(string symbol, ENUM_TIMEFRAMES period);
                    ~CChickensBrain();
                   int GetSignal();  //pos_info._tp = 0?
                   int GetLastMoveType (int handle);
                   int GetIndexMax()      { return _index_max;}
                   int GetIndexMin()      { return _index_min;}
                   int GetDiffHigh()      { return _diff_high;}
                   int GetDiffLow()       { return _diff_low;}
                   int GetSLmin()         { return _sl_min;}
                   double GetHighBorder() { return _highBorder;}
                   double GetLowBorder()  { return _lowBorder;}
                   double GetPriceDifference(){ return _priceDifference;}
                   
                   
};
//+------------------------------------------------------------------+
//|      �����������                                                 |
//+------------------------------------------------------------------+
CChickensBrain::CChickensBrain(string symbol, ENUM_TIMEFRAMES period)
{
 _symbol = symbol;
 _period = period;
 _handle_pbi = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 if (_handle_pbi == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, "�� ������� ������� ����� ���������� PriceBasedIndicator");
  //Print("�� ������� ������� ����� ���������� PriceBasedIndicator");
 }
 isNewBar = new CisNewBar(_symbol, _period);
 _index_max = -1;
 _index_min = -1;
 _lastTrend = 0; 
 isNewBar.isNewBar();
 recountInterval = false;
}
//+------------------------------------------------------------------+
//|      ����������                                                  |
//+------------------------------------------------------------------+
CChickensBrain::~CChickensBrain()
{
 delete isNewBar;
 ArrayFree(closePrice);
 ArrayFree(buffer_high);
 ArrayFree(buffer_low);
 ArrayFree(closePrice);
 IndicatorRelease(_handle_pbi);
 
}
//+------------------------------------------------------------------+
//|      ����� GetSignal() ���������� ������ �������� SELL/BUY       |                                                 
//+------------------------------------------------------------------+
int CChickensBrain::GetSignal()
{
 double _stoplevel;
 _index_max = -1;
 _index_min = -1;
 if(isNewBar.isNewBar() || recountInterval)
 { 
  // ���������� ���������� ������� ��� � ���������
  ArraySetAsSeries(buffer_high, false);
  ArraySetAsSeries(buffer_low, false);
  if(CopyClose(_Symbol, _period, 1, 1, closePrice)     < 1 ||      // ���� �������� ���������� ��������������� ����
     CopyHigh(_Symbol, _period, 1, DEPTH, buffer_high) < DEPTH ||  // ����� ������������ ��� ���� �������������� ����� �� ������� �������
     CopyLow(_Symbol, _period, 1, DEPTH, buffer_low)   < DEPTH ||  // ����� ����������� ��� ���� �������������� ����� �� ������� �������
     CopyBuffer(_handle_pbi, 4, 0, 1, buffer_pbi)       < 1)        // ��������� ���������� ��������
  {
   _index_max = -1;
   _index_min = -1;  // ���� �� ���������� ��������� ��������� �� ����� ��������� ������
   recountInterval = true;
   log_file.Write(LOG_DEBUG,"������ ��� ����������� �������");
  }
  // �������� ������� �������� ���� �� ��������������� �������
  _index_max = ArrayMaximum(buffer_high, 0, DEPTH - 1);
  _index_min = ArrayMinimum(buffer_low, 0, DEPTH - 1);
  recountInterval = false;
  // �������� ��� �������� �� ��������� ����
  _tmpLastBar = GetLastMoveType(_handle_pbi);
  if (_tmpLastBar != 0)
  {
   _lastTrend = _tmpLastBar;
  }
  if (buffer_pbi[0] == MOVE_TYPE_FLAT && _index_max != -1 && _index_min != -1)
  {
   log_file.Write(LOG_DEBUG,"buffer_pbi[0] == MOVE_TYPE_FLAT ������� �� ����� -1");
   log_file.Write(LOG_DEBUG,StringFormat("time[0] = %s", TimeToString(TimeCurrent())));
   //Print();
   // �������� ������� � ������ ���� � ����
   _highBorder = buffer_high[_index_max];
   _lowBorder  = buffer_low[_index_min];
   _sl_min     = MathMax((int)MathCeil((_highBorder - _lowBorder)*0.10/Point()), 50);
   _diff_high  = (buffer_high[DEPTH - 1] - _highBorder)/Point();
   _diff_low   = (_lowBorder - buffer_low[DEPTH - 1])/Point();
   log_file.Write(LOG_DEBUG, StringFormat("%d < %d && %f > %f && %f > %d && _lastTrend = %d", _index_max, ALLOW_INTERVAL,closePrice[0],_highBorder,_diff_high,_sl_min,_lastTrend));
   //PrintFormat("%d < %d && %f > %f && %f > %d && _lastTrend = %d", _index_max, ALLOW_INTERVAL,closePrice[0],_highBorder,_diff_high,_sl_min,_lastTrend);
   log_file.Write(LOG_DEBUG, "_index_max < ALLOW_INTERVAL && GreatDoubles(closePrice[0], _highBorder) && _diff_high > _sl_min && _lastTrend == SELL");
   log_file.Write(LOG_DEBUG, StringFormat("%d < %d && %f < %f && %f > %d && _lastTrend = %d", _index_min, ALLOW_INTERVAL,closePrice[0],_lowBorder,_diff_low,_sl_min,_lastTrend));
   log_file.Write(LOG_DEBUG, "_index_min < ALLOW_INTERVAL && LessDoubles(closePrice[0], _lowBorder) && _diff_low > _sl_min && _lastTrend == BUY");
   if(_index_max < ALLOW_INTERVAL && GreatDoubles(closePrice[0], _highBorder) && _diff_high > _sl_min && _lastTrend == SELL)
   { 
    log_file.Write(LOG_DEBUG, StringFormat("���� �������� ������� ���� �������� = %s, ����� = %s, ���� = %.05f, _sl_min = %d, _diff_high = %d",
          DoubleToString(_highBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          _sl_min, _diff_high));
    /*PrintFormat("���� �������� ������� ���� �������� = %s, ����� = %s, ���� = %.05f, _sl_min = %d, _diff_high = %d",
          DoubleToString(_highBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          _sl_min, _diff_high);*/
    _priceDifference = (closePrice[0] - _highBorder)/Point();
    return SELL;
   }
    
   if(_index_min < ALLOW_INTERVAL && LessDoubles(closePrice[0], _lowBorder) && _diff_low > _sl_min && _lastTrend == BUY)
   {
    log_file.Write(LOG_DEBUG, StringFormat("���� �������� ������� ���� ������� = %s, ����� = %s, ���� = %.05f, _sl_min = %d, _diff_low = %d",
          DoubleToString(_lowBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          _sl_min, _diff_low));
    /*PrintFormat("���� �������� ������� ���� ������� = %s, ����� = %s, ���� = %.05f, _sl_min = %d, _diff_low = %d",
          DoubleToString(_lowBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          _sl_min, _diff_low);*/
    _priceDifference = (_lowBorder - closePrice[0])/Point();
    return BUY;
   }
  } 
  else
   return NO_POSITION;
 } 
 return NO_ENTER;
}

//+------------------------------------------------------------------+
//|      ����� GetLastMoveType()��� �������� ���� �� ��������� ����  |                                                 
//+------------------------------------------------------------------+
int  CChickensBrain::GetLastMoveType (int handle) // �������� ��������� �������� PriceBasedIndicator
{
 int copiedPBI;
 int signTrend;
 copiedPBI = CopyBuffer(handle, 4, 1, 1, buffer_pbi);
 if (copiedPBI < 1)
 {
  log_file.Write(LOG_DEBUG, StringFormat("�� ������� ����������� ��� ������ �� �������  %s", PeriodToString(_period)));
  return (0);
 }
 signTrend = int(buffer_pbi[0]);
 log_file.Write(LOG_DEBUG, StringFormat("��� ������ �� ��������� ����: %d", signTrend));
 //PrintFormat("��� ������ �� ��������� ����: %d", signTrend);
  // ���� ����� �����
 if (signTrend == 1 || signTrend == 2)
  return (1);
 // ���� ����� ����
 if (signTrend == 3 || signTrend == 4)
  return (-1);
 return (0);
}
