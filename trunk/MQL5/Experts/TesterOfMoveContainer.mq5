//+------------------------------------------------------------------+
//|                                        TesterOfMoveContainer.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <MC/CMoveContainer.mqh>
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������

input double percent = 0.1;

CMoveContainer *move_container;
bool firstUploaded = false;
int handleDE;

int OnInit()
  {
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
   move_container = new CMoveContainer(0,_Symbol,_Period,handleDE,percent);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   
  }

void OnTick()
  {
   if (!firstUploaded)
    {
     firstUploaded = move_container.UploadOnHistory();
    }
   if (!firstUploaded)
    return;
  }

// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string
                 )
  {
    move_container.UploadOnEvent(sparam,dparam,lparam);
  }