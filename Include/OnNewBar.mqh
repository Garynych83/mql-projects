//+------------------------------------------------------------------+
//|                                                     OnNewBar.mqh |
//|                                            Copyright 2010, Lizar |
//|                                                    Lizar@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar@mail.ru"

#include <Lib CisNewBar.mqh>
CisNewBar current_chart; // ��������� ������ CisNewBar: ������� ������

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int period_seconds=PeriodSeconds(_Period);                     // ���������� ������ � ������� �������� �������
   datetime new_time=TimeCurrent()/period_seconds*period_seconds; // ����� �������� ���� �� ������� �������
   if(current_chart.isNewBar(new_time)) OnNewBar();               // ��� ��������� ������ ���� ��������� ���������� ������� NewBar
  }
