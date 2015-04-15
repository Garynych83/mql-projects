//+------------------------------------------------------------------+
//|                                               CChickensBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBarDD.mqh>
#include <TradeManager\TradeManager.mqh>   //���� ����� ���������, ����� ��?

#define DEPTH 20
#define ALLOW_INTERVAL 16
// ��������� ��������
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0
#define NO_ENTER 2
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CChickensBrain
{
 private:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  int _handle_pbi; 
  CisNewBar *isNewBar;
  int  tmpLastBar;
  int  lastTrend;            // ��� ���������� ������ �� PBI 
  double buffer_pbi[];
  double buffer_high[];
  double buffer_low[];
  double highPrice[], lowPrice[], closePrice[];
  bool recountInterval;
 public:
                     CChickensBrain(string symbol, ENUM_TIMEFRAMES period, int handle_pbi);
                    ~CChickensBrain();
                   int GetSignal();  //pos_info.tp = 0?
                   int GetLastMoveType (int handle);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CChickensBrain::CChickensBrain(string symbol, ENUM_TIMEFRAMES period, int handle_pbi)
{
 _symbol = symbol;
 _period = period;
 _handle_pbi = handle_pbi; 
 isNewBar = new CisNewBar(_symbol, _period);
 lastTrend = 0; 
 recountInterval = false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CChickensBrain::~CChickensBrain()
{
}
//+------------------------------------------------------------------+
int CChickensBrain::GetSignal()
{
 int diff_high, diff_low, sl_min, tp;
 double highBorder, lowBorder;
 double stoplevel;
 static int index_max = -1;
 static int index_min = -1;
 if(isNewBar.isNewBar() || recountInterval)
 {
  ArraySetAsSeries(buffer_high, false);
  ArraySetAsSeries(buffer_low, false);
  if(CopyClose(_symbol, _period, 1, 1, closePrice)     < 1 ||      // ���� �������� ���������� ��������������� ����
     CopyHigh(_symbol, _period, 1, DEPTH, buffer_high) < DEPTH ||  // ����� ������������ ��� ���� �������������� ����� �� ������� �������
     CopyLow(_symbol, _period, 1, DEPTH, buffer_low)   < DEPTH ||  // ����� ����������� ��� ���� �������������� ����� �� ������� �������
     CopyBuffer(_handle_pbi, 4, 0, 1, buffer_pbi)       < 1)        // ��������� ���������� ��������
  {
   index_max = -1;
   index_min = -1;  // ���� �� ���������� ��������� ��������� �� ����� ��������� ������
   recountInterval = true;
  }
  index_max = ArrayMaximum(buffer_high, 0, DEPTH - 1);
  index_min = ArrayMinimum(buffer_low, 0, DEPTH - 1);
  recountInterval = false;
  
  tmpLastBar = GetLastMoveType(_handle_pbi);
  if (tmpLastBar != 0)
  {
   lastTrend = tmpLastBar;
  }
  
  if (buffer_pbi[0] == MOVE_TYPE_FLAT && index_max != -1 && index_min != -1)
  {
   highBorder = buffer_high[index_max];
   lowBorder = buffer_low[index_min];
   sl_min = MathMax((int)MathCeil((highBorder - lowBorder) * 0.10 / Point()), 50);
   diff_high = (buffer_high[DEPTH - 1] - highBorder)/Point();
   diff_low = (lowBorder - buffer_low[DEPTH - 1])/Point();
   stoplevel = MathMax(sl_min, SymbolInfoInteger(_symbol, SYMBOL_TRADE_STOPS_LEVEL))*Point();
   if(index_max < ALLOW_INTERVAL && GreatDoubles(closePrice[0], highBorder) && diff_high > sl_min && lastTrend == SELL)
   { 
    PrintFormat("���� �������� ������� ���� �������� = %s, ����� = %s, ���� = %.05f, sl_min = %d, diff_high = %d",
          DoubleToString(highBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          sl_min, diff_high);
   
    return SELL;
   }
    
   if(index_min < ALLOW_INTERVAL && LessDoubles(closePrice[0], lowBorder) && diff_low > sl_min && lastTrend == BUY)
   {
    PrintFormat("���� �������� ������� ���� ������� = %s, ����� = %s, ���� = %.05f, sl_min = %d, diff_low = %d",
          DoubleToString(lowBorder, 5),
          TimeToString(TimeCurrent()),
          closePrice[0],
          sl_min, diff_low);
         
    return BUY;
   }
  } 
  else
   return NO_POSITION;
 } 
 return NO_ENTER;
}

int  CChickensBrain::GetLastMoveType (int handle) // �������� ��������� �������� PriceBasedIndicator
{
 int copiedPBI;
 int signTrend;
 copiedPBI = CopyBuffer(handle, 4, 1, 1, buffer_pbi);
 if (copiedPBI < 1)
  return (0);
 signTrend = int(buffer_pbi[0]);
  // ���� ����� �����
 if (signTrend == 1 || signTrend == 2)
  return (1);
 // ���� ����� ����
 if (signTrend == 3 || signTrend == 4)
  return (-1);
 return (0);
}
