//+------------------------------------------------------------------+
//|                                             RabbitWithBrains.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//����������� ����������� ���������

#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <CTrendChannel.mqh> // ��������� ���������
#include <Rabbit/Timeframe.mqh>
#include <Rabbit/RabbitsBrain.mqh>

//���������
#define KO 3            //����������� ��� ������� �������� �������, �� ������� ��� ������� ����������� ���� ������ ������ ��������� ����������� ���� ����
#define SPREAD 30       // ������ ������ 

//---------------------��������---------------------------------+
// ENUM ��� �������
// ������� ��������� ��� �������� supremacyPercent
// ����� �� � ������ ��������� ������ ���������� ���, � ���� ��������?
//--------------------------------------------------------------+

//-------�������� ������������� ��������� ��� ���������� � ���������, ���� ��������� ���� �������-------------
input double percent = 0.1;   // �������
input double M1_Ratio  = 5;   //�������, ��������� ��� M1 ������ �������� ��������
input double M5_Ratio  = 3;   //�������, ��������� ��� M1 ������ �������� ��������
input double M15_Ratio  = 1;  //�������, ��������� ��� M1 ������ �������� ��������

// ---------���������� ������------------------
CTrendChannel *trend;      // ����� �������
CTimeframe *ctf;           // ������ �� ��
CContainerBuffers *conbuf; // ����� ����������� �� ��������� ��, ����������� �� OnTick()
                           // highPrice[], lowPrice[], closePrice[] � �.�; 
CArrayObj *dataTFs;        // ������ ��, ��� �������� �� ���������� �� ������������
CArrayObj *trends;         // ������ ������� ������� (��� ������� �� ���� �����)
CRabbitsBrain *rabbit;
CTimeframe *posOpenedTF;  // ������ �� ������� ���� ������� �������
CTradeManager ctm;         // �������� ����� 
     
datetime history_start;    // ����� ��� ��������� �������� �������                           
ENUM_TIMEFRAMES TFs[3] = {PERIOD_M1, PERIOD_M5, PERIOD_M15};// ------------------������� ���������� ������ � ��� � ���� �������, +���������
ENUM_TM_POSITION_TYPE opBuy, opSell;
int handle19Lines; 
int handleATR;
int handleDE;


//---------��������� ������� � ���������------------
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   // �����  

// ����������� �������� �������
int signalForTrade;
int SL, TP;
long magic;



int indexPosOpenedTF;         // ������� ����� �������� ������� �� ������� ������ ������ ��� �� ��� �� ��� � ���� �������

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

 history_start = TimeCurrent(); //�������� ����� ������� �������� ��� ��������� �������� �������

 //---------- ����� ��������� NineTeenLines----------------
 conbuf = new CContainerBuffers(TFs);
 opBuy  = OP_BUY;  // ��� ����. �����?
 opSell = OP_SELL;
 
 rabbit = new CRabbitsBrain(_Symbol, conbuf, TFs); // �������� ��� ��������� � ����� - ������ �������
 
 pos_info.volume = 1;
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;

 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete trend;
 delete conbuf;
 dataTFs.Clear();
 delete dataTFs;
 trends.Clear();
 delete trends;  
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
 if( (signalForTrade == BUY || signalForTrade == SELL ) ) //(signalForTrade != NO_POISITION)
 {
  pos_info.sl = rabbit.GetSL();                     // ���������� ������������ SL
  pos_info.tp = 10 * SL; 
  if(signalForTrade == BUY)
   pos_info.type = opBuy;
  else 
   pos_info.type = opSell;
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
