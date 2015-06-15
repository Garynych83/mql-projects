//+------------------------------------------------------------------+
//|                                              EvgenyWithBrain.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <SystemLib/IndicatorManager.mqh>     // ���������� �� ������ � ������������
#include <TradeManager/TradeManager.mqh>      // �������� ����������
#include <RobotEvgeny/EvgenysBrain.mqh>


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input double lot = 1; // ���
//input double percent = 0.1; // ��� ���������� �������� (������ ����� ������ ����������)

// ������� ������� 
CTradeManager *ctm; 
CEvgenysBrain *evgeny;
CExtrContainer *extremums;
CContainerBuffers *conbuf;
// ������ �����������
int  handleDE;
int  handlePBI;  // ��� ����������� ������������� �������������� ���������� ���� ����������� �� OnInit()
int  evgenySignal;
int  trend;
// ����� ������� 
string eventExtrUpName;    // ������� ������� �������� ����������
string eventExtrDownName;  // ����
string eventMoveChanged;

ENUM_TIMEFRAMES TFs[3] = {PERIOD_M5,PERIOD_M15,PERIOD_H1};

// ��������� ������� � ���������
SPositionInfo pos_info;      // ��������� ���������� � �������
STrailing     trailing;      // ��������� ���������� � ���������
int OnInit()
{ 
 // ��������� ����� �������
 eventExtrDownName = "EXTR_DOWN_FORMED_" + _Symbol + "_"   + PeriodToString(_Period);
 eventExtrUpName   = "EXTR_UP_FORMED_"   + _Symbol + "_"   + PeriodToString(_Period); 
 eventMoveChanged  = "MOVE_CHANGED_"     + _Symbol + "_"   + PeriodToString(_Period); 
 evgenySignal = NO_SIGNAL;
 ctm = new CTradeManager(); 
 // �������� ���������� DrawExtremums 
 handleDE = DoesIndicatorExist(_Symbol, _Period, "DrawExtremums");
 if (handleDE == INVALID_HANDLE)
 {
  handleDE = iCustom(_Symbol, _Period, "DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   Print("�� ������� ������� ����� ���������� DrawExtremums");
   return (INIT_FAILED);
  }
  SetIndicatorByHandle(_Symbol, _Period, handleDE);
 } 
 /*handlePBI = DoesIndicatorExist(_Symbol, _Period, "PriceBasedIndicator");
 if (handlePBI == INVALID_HANDLE)
 {
  handlePBI = iCustom(_Symbol, _Period, "PriceBasedIndicator");
  if (handlePBI == INVALID_HANDLE)
  {
   Print("�� ������� ������� ����� ���������� PriceBasedIndicator");
   return (INIT_FAILED);
  }
  //SetIndicatorByHandle(_Symbol, _Period, handlePBI);
 } */
 conbuf = new CContainerBuffers(TFs);
 for (int attempts = 0; attempts < 25; attempts++)
 {
  conbuf.Update();
  Sleep(100);
  if(conbuf.isFullAvailable())
  {
   PrintFormat("�������-�� ����������! attempts = %d", attempts);
   break;
  }
 }
  if(!conbuf.isFullAvailable())
   return (INIT_FAILED);
  extremums = new CExtrContainer(handleDE, _Symbol, _Period);
  evgeny = new CEvgenysBrain(_Symbol, _Period, extremums, conbuf);   

 // ��������� ���� �������
 pos_info.expiration = 0;
 // ��������� 
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.handleForTrailing = 0;     
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete ctm;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();
 conbuf.Update();
 if(!extremums.isUploaded())
 PrintFormat("%s �� ���������� ��������� �����������, ��� �� ������ ����.");
 //log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ��������� �����������, ��� �� ������ ����.", MakeFunctionPrefix(__FUNCTION__)));
 
 if (evgeny.CheckClose() && ctm.GetPositionCount() > 0)
 { 
  // �� ��������� �������
  ctm.ClosePosition(0);
 }
 evgenySignal = evgeny.GetSignal();
 if(evgenySignal == BUY)
 {
  //Print("������ ������ �� BUY");
  log_file.Write(LOG_DEBUG, "������ ������ �� BUY");
  pos_info.sl = evgeny.CountStopLossForTrendLines();
  pos_info.tp = pos_info.sl*10;
  pos_info.volume = lot;
  pos_info.type = OP_BUY;
  ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
 }
 if(evgenySignal == SELL)
 {
  //Print("������ ������ �� SELL");
  log_file.Write(LOG_DEBUG, "������ ������ �� SELL");
  pos_info.sl = evgeny.CountStopLossForTrendLines();
  pos_info.tp = pos_info.sl*10;
  pos_info.volume = lot;
  pos_info.type = OP_SELL;
  ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing);
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
 extremums.UploadOnEvent(sparam, dparam, lparam);
 double price;
 if (sparam == eventExtrDownName)
 {
  price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  pos_info.type = OP_BUY; 
 }
 if (sparam == eventExtrUpName)
 {
  price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  pos_info.type = OP_SELL;
 }
 // ������ ������� "������������� ����� ���������"
 if (sparam == eventExtrDownName || sparam == eventExtrUpName)
 {
  evgeny.UploadOnEvent();

 }
 // ������ ������� "���������� �������� �� PBI"
 if (sparam == eventMoveChanged)
 {
  // ���� ����� �����
  if (dparam == 1.0 || dparam == 2.0)
  {
  
  }
  // ���� ����� ����
  if (dparam == 3.0 || dparam == 4.0)
  {
   
  }
 }   
}
//+------------------------------------------------------------------+

