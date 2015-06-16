//+------------------------------------------------------------------+
//|                                               CChickensBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              ht_tp://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "ht_tp://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>  
#include <Lib CisNewBarDD.mqh>              // ������������� ������ ����
#include <CompareDoubles.mqh>               // ��������� ������������ �����
#include <StringUtilities.mqh>              // ��������� ��������������
#include <CLog.mqh>                         // ��� ����
#include <ContainerBuffers.mqh>     // ����� ��������� �������

#define DEPTH 20
#define ALLOW_INTERVAL 4
// ��������� ��������
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0
#define NO_ENTER 2 //�������


//+------------------------------------------------------------------+
//|        ����� CChickensBrain  ������������ ��� ���������� ����    |
//|                              ������� ������� �������� ���������  |                                                          |
//+------------------------------------------------------------------+
class CChickensBrain : public CArrayObj
{
 private:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  //int _handle_pbi; 
  int _tmpLastBar;
  int _lastTrend;            // ��� ���������� ������ �� PBI 
  /*double buffer_pbi[];
  double buffer_high[];
  double buffer_low[];
  double highPrice[], lowPrice[], closePrice[];*/
 
  bool recountInterval;
  CisNewBar *isNewBar;
  CContainerBuffers *_conbuf;
  // ����, ������ � ������� ���������� ����� ������� Get...()
  int _index_max;
  int _index_min;
  int _diff_high; 
  int _diff_low; 
  int _priceDifference;
  int _sl_min;
  double _highBorder; 
  double _lowBorder;

  
 public:
  
                     CChickensBrain(string symbol, ENUM_TIMEFRAMES period, CContainerBuffers *conbuf);
                    ~CChickensBrain();
                   int GetSignal();  //pos_info._tp = 0?
                   int GetLastMoveType ();
                   int GetIndexMax()      { return _index_max;}
                   int GetIndexMin()      { return _index_min;}
                   int GetDiffHigh()      { return _diff_high;}
                   int GetDiffLow()       { return _diff_low;}
                   int GetSLmin()         { return _sl_min;}
                   int GetPriceDifference(){ return _priceDifference;}
                   double GetHighBorder() { return _highBorder;}
                   double GetLowBorder()  { return _lowBorder;}
                   ENUM_TIMEFRAMES GetPeriod() { return _period;}
                  
                   
                   
};
//+------------------------------------------------------------------+
//|      �����������                                                 |
//+------------------------------------------------------------------+
CChickensBrain::CChickensBrain(string symbol, ENUM_TIMEFRAMES period, CContainerBuffers *conbuf)
{
 _conbuf = conbuf;
 _symbol = symbol;
 _period = period;
 isNewBar = new CisNewBar(_symbol, _period);
 _index_max = -1;
 _index_min = -1;
 _lastTrend = 0; 
 isNewBar.isNewBar();
 recountInterval = false;
 log_file.Write(LOG_DEBUG, StringFormat(" CChickensBrain �� %s ������ ������� ", PeriodToString(_period)));
}
//+------------------------------------------------------------------+
//|      ����������                                                  |
//+------------------------------------------------------------------+
CChickensBrain::~CChickensBrain()
{
 delete isNewBar;
 delete _conbuf;
 /*ArrayFree(closePrice);
 ArrayFree(buffer_high);
 ArrayFree(buffer_low);
 ArrayFree(closePrice);
 IndicatorRelease(_handle_pbi);*/
}
//+------------------------------------------------------------------+
//|      ����� GetSignal() ���������� ������ �������� SELL/BUY       |                                                 
//+------------------------------------------------------------------+
int CChickensBrain::GetSignal()
{
 _index_max = -1;
 _index_min = -1;
 if(isNewBar.isNewBar() || recountInterval)
 { 
  if(!_conbuf.isPeriodAvailable(_period))
   log_file.Write(LOG_DEBUG,StringFormat("%s ����� �� �������� ��� ������������� �������", MakeFunctionPrefix(__FUNCTION__)));
  // ���������� ���������� ������� ��� � ���������
  /*ArraySetAsSeries(buffer_high, false);
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
  }*/
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
   _diff_high  = (_conbuf.GetHigh(_period).buffer[1] - _highBorder)/Point();
   _diff_low   = (_lowBorder - _conbuf.GetLow(_period).buffer[1])/Point();
   
   log_file.Write(LOG_DEBUG, StringFormat("����� = %s �� = %s", TimeToString(TimeCurrent()), PeriodToString(_period)));
   log_file.Write(LOG_DEBUG, StringFormat("buffer_pbi[0] == %d  _index_max = %d _index_min = %d", int(_conbuf.GetPBI(_period).buffer[0]), _index_max ,_index_min ));
   log_file.Write(LOG_DEBUG, StringFormat("_lowBorder ( %f ) - Low[DEPTH] ( %f )  = %f",  _lowBorder, _conbuf.GetLow(_period).buffer[1], _lowBorder - _conbuf.GetLow(_period).buffer[1]));
   log_file.Write(LOG_DEBUG, StringFormat("High[0]( %f ) - _highBorder( %f )  = %f",  _conbuf.GetHigh(_period).buffer[1], _highBorder, _conbuf.GetHigh(_period).buffer[1] - _highBorder));
   log_file.Write(LOG_DEBUG, StringFormat("%d > %d && %f > %f && %d > %d && _lastTrend = %d", _index_max, ALLOW_INTERVAL,_conbuf.GetClose(_period).buffer[1],_highBorder,_diff_high,_sl_min,_lastTrend));
   log_file.Write(LOG_DEBUG, "_index_max > ALLOW_INTERVAL && GreatDoubles(closePrice[0], _highBorder) && _diff_high > _sl_min && _lastTrend == SELL");
   log_file.Write(LOG_DEBUG, StringFormat("%d > %d && %f < %f && %d > %d && _lastTrend = %d", _index_min, ALLOW_INTERVAL,_conbuf.GetClose(_period).buffer[1],_lowBorder,_diff_low,_sl_min,_lastTrend));
   log_file.Write(LOG_DEBUG, "_index_min > ALLOW_INTERVAL && LessDoubles(closePrice[0], _lowBorder) && _diff_low > _sl_min && _lastTrend == BUY");
   
   if(_index_max < ALLOW_INTERVAL && GreatDoubles(_conbuf.GetClose(_period).buffer[1], _highBorder) && _diff_high > _sl_min && _lastTrend == SELL)
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
    _priceDifference = (_conbuf.GetClose(_period).buffer[0] - _highBorder)/Point();
    return SELL;
   }
    
   if(_index_min < ALLOW_INTERVAL && LessDoubles(_conbuf.GetClose(_period).buffer[1], _lowBorder) && _diff_low > _sl_min && _lastTrend == BUY)
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
    _priceDifference = (_lowBorder - _conbuf.GetClose(_period).buffer[0])/Point();
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
int  CChickensBrain::GetLastMoveType () // �������� ��������� �������� PriceBasedIndicator
{
 int signTrend;
 /*
 if (copiedPBI < 1)
 {
  log_file.Write(LOG_DEBUG, StringFormat("�� ������� ����������� ��� ������ �� �������  %s", PeriodToString(_period)));
  return (0);
 }*/
 signTrend = int(_conbuf.GetPBI(_period).buffer[0]);
 log_file.Write(LOG_DEBUG, StringFormat("��� ������ �� ��������� ����: %d", int(_conbuf.GetPBI(_period).buffer[0])));
 //PrintFormat("��� ������ �� ��������� ����: %d", signTrend);
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
