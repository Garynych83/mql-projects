//+------------------------------------------------------------------+
//|                                               Example5NewBar.mq5 |
//|                                            Copyright 2010, Lizar |
//|                                               Lizar-2010@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar-2010@mail.ru"
#property version   "1.00"

#include <Lib CisNewBar.mqh>

CisNewBar newbar_ind; // ��������� ������ CisNewBar: ����������� ����� ������� �����
int HandleIndicator;  // ����� ����������
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- �������� ����� ����������:
   HandleIndicator=iCustom(_Symbol,_Period,"TickColorCandles v2.00",16,0,""); 
   if(HandleIndicator==INVALID_HANDLE)
     {
      Alert(" ������ ��� �������� ������ ����������, ����� ������: ",GetLastError());
      Print(" ������������� ��������� ��������� �����������. �������� ���������.");
      return(1);
     }

//--- ������������ ��������� � �������:  
   if(!ChartIndicatorAdd(ChartID(),1,HandleIndicator))
     {
      Alert(" ������ ������������� ���������� � �������, ����� ������: ",GetLastError());
      return(1);
     }
//--- ���� ����� �� ����, �� ������������� ������ �������     
   Print(" ������������� ��������� ��������� �������. �������� ���������.");
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   double iTime[1];

//--- �������� ����� �������� ��������� ������������� ������� �����:
   if(CopyBuffer(HandleIndicator,5,0,1,iTime)<=0)
     {
      Print(" ��������� ������� �������� �������� ������� ����������. "+
            "\n��������� ������� �������� �������� ���������� ����� ����������� �� ��������� ����.",GetLastError());
      return;
     }
//--- ���������� ��������� ����� ������� �����:
   if(newbar_ind.isNewBar((datetime)iTime[0]))
     {
      PrintFormat("����� ���. ����� ��������: %s  ����� ���������� ����: %s",TimeToString((datetime)iTime[0],TIME_SECONDS),TimeToString(TimeCurrent(),TIME_SECONDS));
     }
  }
  
 
