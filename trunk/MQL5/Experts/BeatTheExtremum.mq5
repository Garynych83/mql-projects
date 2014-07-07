//+------------------------------------------------------------------+
//|                                              BeatTheExtremum.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <CExtremum.mqh>                   // ��������� 
#include <TradeManager\TradeManager.mqh>   // �������� ����������

// �����, ��������� �� �������� ����������

// ������� �������
CExtremum     *cExtr;    // ���������
CTradeManager *ctm;      // �������� ����������
//SExtremum extr_cur[2];   // ���������

int OnInit()
  {
   cExtr = new CExtremum(_Symbol,_Period);
   if (cExtr == NULL)
    return (INIT_FAILED);
   ctm   = new CTradeManager();
   if (ctm == NULL)
    return (INIT_FAILED);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete cExtr;
   delete ctm;
  } 

void OnTick()
  {
   ctm.OnTick();
SExtremum extr_cur[2] = {{0, -1}, {0, -1}};
  }
  
  
void RecountUpdated(datetime start_pos, bool now, SExtremum &ret_extremums[])
{
 int count_new_extrs = extr.RecountExtremum(start_pos, now);
 if (count_new_extrs > 0)
 { //� ������� ������������ ����������� �� 0 ����� ����� max, �� ����� 1 ����� min
  
  if(count_new_extrs == 1)
  {
   if(extr.getExtr(0).direction == 1)       ret_extremums[0] = extr.getExtr(0);
   else if(extr.getExtr(0).direction == -1) ret_extremums[1] = extr.getExtr(0);
  }
  
  if(count_new_extrs == 2)
  {
   if(extr.getExtr(0).direction == 1)       { ret_extremums[0] = extr.getExtr(0); ret_extremums[1] = extr.getExtr(1);}
   else if(extr.getExtr(0).direction == -1) { ret_extremums[0] = extr.getExtr(1); ret_extremums[1] = extr.getExtr(0); }
  }     
  
  
  
 }
}  