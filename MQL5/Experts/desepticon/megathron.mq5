//+------------------------------------------------------------------+
//|                                                    megathron.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//����������� ����������� ���������

#include <Chicken/ChickensBrain.mqh>

#include <SystemLib/IndicatorManager.mqh>   // ���������� �� ������ � ������������
#include <MoveContainer/CMoveContainer.mqh> // ������(�����) ��������� ��������
#include <CTrendChannel.mqh>                // ������(�� ��������) ��������� ���������
#include <Rabbit/RabbitsBrain.mqh>
#include <Hvost/HvostBrain.mqh>

//���������
#define SPREAD 30       // ������ ������ 

// ---------���������� ������------------------
CContainerBuffers *conbuf; // ����� ����������� �� ��������� ��, ����������� �� OnTick()
                           // highPrice[], lowPrice[], closePrice[] � �.�; 
CRabbitsBrain *rabbit;
CChickensBrain *chickenM5, *chickenM15, *chickenH1;
CHvostBrain *hvostBrain;

CTradeManager *ctm;        // �������� ����� 
     
datetime history_start;    // ����� ��� ��������� �������� �������                           

ENUM_TM_POSITION_TYPE opBuy, opSell;
ENUM_TIMEFRAMES TFs[7] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1};
ENUM_TIMEFRAMES JrTFs[3] =  {PERIOD_M1, PERIOD_M5, PERIOD_M15};
ENUM_TIMEFRAMES MedTFs[2] = {PERIOD_H1, PERIOD_H4};
ENUM_TIMEFRAMES EldTFs[2] = {PERIOD_D1, PERIOD_W1};
//---------��������� ������� � ���������------------
SPositionInfo pos_info;
STrailing     trailing;

// ����������� �������� �������
long magic[6] = {1111, 1112, 1113, 1114, 1115, 1116};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 ctm = new CTradeManager();
 history_start = TimeCurrent(); // �������� ����� ������� �������� ��� ��������� �������� �������

 //---------- ����� ��������� NineTeenLines----------------
 conbuf = new CContainerBuffers(TFs);
 
 rabbit = new CRabbitsBrain(_Symbol, conbuf); // �������� ��� ��������� � ����� - ������ �������
 chickenM5 = new CChickensBrain(_Symbol,PERIOD_M5, conbuf);
 chickenM15 = new CChickensBrain(_Symbol,PERIOD_M15, conbuf);
 chickenH1 = new CChickensBrain(_Symbol,PERIOD_H1, conbuf);
 

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
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //�������� ������� �� ������� ��, �������� ��������� � ��������������� ����������
    //
   //� ������������ �� �������� ���������, �������� ������ �� ������� ������� ��; ��������� ���������� ���������
    //����� ������� ���� ����� ������� ��� ��� ������� ������ ����?
    //���� ��������� ������� - ��� ��������� ��� ���� ��������� ������� �� ������ ��?
   //�������� ������� �� ������� ��
   
   //��������� ��������� �� ����, ������� �� ������� ��; ������� ������� � ������ ����� ���������
   //�� ���������� �������� ��������� ����������� �������� �� ������� ��
   //
   
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
