//+------------------------------------------------------------------+
//|                                                UDragDropLine.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------------+
//| ��������������� �������� DragDropLine ������ ���������� ������ �����:  |
//| 1. �������� �������������� ����� �� ���������� (������������) �������� |
//| 2. �������� ������� ����� �����-���� �� ������� ������                 |
//| 3. �������� ����� �������� ����� �� ��������� �����������              |                   |
//+------------------------------------------------------------------------+

#include <TradeManager/ChartObjectsTradeLines.mqh> // ��� ��������� ����� �����������



CTakeProfitLine line; // ������ ������ �����
double linePrice = 1.09000;
int id_line = 778;
string curObjName;

int OnInit()
{
 line.Create(id_line, linePrice);
 //line_name = ObjectGetString(0,line_name,OBJPROP_NAME);
 //ENUM_OBJECT_PROPERTY_DOUBLE
 //ChartGetDouble(0,
 //--- ��������� ����� ��������� ������� �������� �������� �������
 //ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_CREATE,true);
 //--- ��������� ����� ��������� ������� �������� �������� �������
 //ChartSetInteger(ChartID(),CHART_EVENT_OBJECT_DELETE,true);
 return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------------+
//+------------------------------------------------------------------------+

void OnDeinit(const int reason)
{

}
  
//+-----------------------------------------------------------------------+
//+-----------------------------------------------------------------------+
void OnTick()
{
 
   
}
//+-----------------------------------------------------------------------+
//| ChartEvent function                                                   |
//+-----------------------------------------------------------------------+

int count=0;

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
 switch(id)
 {
  case CHARTEVENT_MOUSE_MOVE:
  break;
  case CHARTEVENT_OBJECT_DRAG:
   Print("��������� ������� CHARTEVENT_OBJECT_DRAG");
   //curObjName = sparam;
   //if(line_name == curObjName)
   //{
    linePrice = line.Value();
    //linePrice = ObjectGetDouble(0,line_name,OBJPROP_PRICE,0);
    Print("linePrice = ", linePrice);
  // }
  break;
  case CHARTEVENT_CLICK:
   //Print("��������� ������� CHARTEVENT_CLICK");
  break;   
  case CHARTEVENT_OBJECT_CLICK:
   //Print("��������� ������� CHARTEVENT_OBJECT_CLICK, sparam = ", sparam);
  break;   
  default: 
   //Print("�������� default");
  break;   
} 

}
