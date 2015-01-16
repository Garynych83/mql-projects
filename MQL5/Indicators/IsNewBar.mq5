//+------------------------------------------------------------------+
//|                                                     IsNewBar.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include  <Lib CisNewBar.mqh>  // ��� �������� �� ����� ���
#include  <CEventBase.mqh>  // ��� ��������� ����� ������� 
//+------------------------------------------------------------------+
//| ���������, ������������ ������� ���������� ������ ����           |
//+------------------------------------------------------------------+
CisNewBar *isNewBar; // ������ ��������� ������ ����������
CEventBase *eventBase; // ������ ������������ 
SEventData eventData; // ��������� ����� �������

int OnInit()
  {
   isNewBar = new CisNewBar(_Symbol,_Period);
   eventBase = new CEventBase(100);
   if (eventBase == NULL)
    {
     Print("�� ������� ������� ������ ������ ���������� �������");
     return (INIT_FAILED);
    }
   // ������� id ������� 
   eventBase.AddNewEvent(_Symbol,_Period,"����� ���");
   eventBase.AddNewEvent(_Symbol,PERIOD_M5,"����� ����");
   return(INIT_SUCCEEDED);
  }

void OnDeinit()
  { 
   delete isNewBar;
   delete eventBase;
  }

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   // ���� ������ ����� ���
   if (isNewBar.isNewBar()>0)
    {
     // ������� ������� ��� ���� ��������
     Generate("����� ���",eventData,true); 
    }
   return(rates_total);
  }
  
// �������� �� ���� �������� � ������� ������� ��� ���
void Generate(string id_nam,SEventData &_data,const bool _is_custom=true)
  {
   // �������� �� ���� �������� �������� � ������� �������� � �� � ���������� ��� ��� �������
   long z = ChartFirst();
   while (z>=0)
     {
      if (ChartSymbol(z) == _Symbol && ChartPeriod(z)==_Period)  // ���� ������ ������ � ������� �������� � �������� 
        {
         // ������� ������� ��� �������� �������
         eventBase.Generate(z,id_nam,_data,_is_custom);
        }
      z = ChartNext(z);      
     }     
  }    