//+------------------------------------------------------------------+
//|                                             RabbitWithBrains.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//����������� ����������� ���������

#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <CTrendChannel.mqh> // ��������� ���������
#include <Rabbit/RabbitsBrain.mqh>

//���������
#define KO 3            //����������� ��� ������� �������� �������, �� ������� ��� ������� ����������� ���� ������ ������ ��������� ����������� ���� ����
#define SPREAD 30       // ������ ������ 

// ---------���������� ������------------------
CContainerBuffers *conbuf; // ����� ����������� �� ��������� ��, ����������� �� OnTick()
                           // highPrice[], lowPrice[], closePrice[] � �.�; 
CRabbitsBrain *rabbit;
CTradeManager *ctm;        // �������� ����� 
     
datetime history_start;    // ����� ��� ��������� �������� �������                           

ENUM_TIMEFRAMES TFs[3] = {PERIOD_M1, PERIOD_M5, PERIOD_M15};
//---------��������� ������� � ���������------------
SPositionInfo pos_info;
STrailing     trailing;

// ����������� �������� �������
int signalForTrade;
long magic;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 history_start = TimeCurrent(); // �������� ����� ������� �������� ��� ��������� �������� �������

 //---------- ����� ��������� NineTeenLines----------------
 conbuf = new CContainerBuffers(TFs);
 
 rabbit = new CRabbitsBrain(_Symbol, conbuf); // �������� ��� ��������� � ����� - ������ �������
 
 pos_info.volume = 1;
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
 ctm = new CTradeManager();

 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete ctm;
 delete conbuf;  
 delete rabbit;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();  
 rabbit.UpdateBuffers();      // ��������� ���������� ������ �������            
 pos_info.type = OP_UNKNOWN;  // ����� �������� �������
 signalForTrade = NO_SIGNAL;  // ������� ������� ������
 rabbit.OpenedPosition(ctm.GetPositionCount());  // ToDo �������� ������� ��� ����������� ������
 signalForTrade = rabbit.GetSignal();             
 if((signalForTrade == BUY || signalForTrade == SELL )) 
 {
  pos_info.sl = rabbit.GetSL();                          // ���������� ������������ SL
  pos_info.tp = 10 * pos_info.sl; 
  if(signalForTrade == BUY)
   pos_info.type = OP_BUY;
  else 
   pos_info.type = OP_SELL;
  ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, SPREAD);   // ������� �������
 }    
}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
{
 ctm.OnTrade();
 if(history_start != TimeCurrent())
 {
  history_start = TimeCurrent() + 1;
 }   
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
 if(rabbit.UpdateOnEvent(lparam, dparam, sparam, ctm.GetPositionCount()))
  ctm.ClosePosition(0);
}
//+------------------------------------------------------------------+
