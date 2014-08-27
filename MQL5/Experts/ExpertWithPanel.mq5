//+------------------------------------------------------------------+
//|                                              ExpertWithPanel.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Graph\Widgets\WtradeWidget.mqh>   // �������� ������ 

WTradeWidget *widget;

int OnInit()
  {
   widget = new WTradeWidget(_Symbol,"trade_panel","�������� ������",50,10,0,0,0);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete widget;
  }

void OnTick()
  {
    widget.OnTick();
  }
  
// ����� ��������� �������  
void OnChartEvent(const int id,
                const long &lparam,
                const double &dparam,
                const string &sparam)
  { 
   // ���� ������ ������
   if(id==CHARTEVENT_OBJECT_CLICK)
    {
     // ��������� ���� ������� ������
     widget.Action(sparam);      
    }
   if(id==CHARTEVENT_MOUSE_MOVE)
    {
     // ��������� ����������� ������� ����
     widget.MoveTo(lparam,dparam);
     Comment("X = ",lparam);
    }
  } 