//+------------------------------------------------------------------+
//|                                                TesterDivMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <divergenceMACD.mqh>                 // ���������� ���������� ��� ������ ��������� � ����������� ����������
#include <CompareDoubles.mqh>                 // ��� �������� �����������  ���
//+------------------------------------------------------------------+
//| ������ ����������� ������������ ����������� MACD                 |
//+------------------------------------------------------------------+

input int bars_ahead=10; // ���������� ����� ������ ����� ������� ��� �������� ������������   

// ���������� ��� �������� ���������� ���������� � �� ���������� ��������

 int countConvPos;       // ���������� ������������� �������� ���������
 int countConvNeg;       // ���������� ���������� �������� ���������
 int countDivPos;        // ���������� ������������� �������� �����������
 int countDivNeg;        // ���������� ���������� �������� ����������� 

// ������ �������� ����� 
 double buffer_high[];   // ������� ����
 double buffer_low[];    // ������ ����
 double buffer_close[];  // ���� �������� 

// ���������� ��� �������� ���������� �������� ����� 

 int copiedHigh;         // ������� ����
 int copiedLow;          // ������ ����
 int copiedClose;        // ���� ��������
 
// ���� MACD
 int handleMACD; 
 
// ������� �������� �����

int lastBarIndex;  // ������ ���������� ���� /// = rates_total - 101;

void OnStart()
  {
   // ���������� �������� ����������
   datetime current = TimeCurrent();           // ������� �����
   int      countBars = Bars(_Symbol,_Period); // ����� ����� �������
   ArraySetAsSeries(Buffer, true); // ���������� ��� � ���������
   ArraySetAsSeries(Buffer, true);
   ArraySetAsSeries(Buffer, true);      
   // 0) - ���������� �������� ������� � ���������� �����
   lastBarIndex  = countBars - 101;
   if (lastBarIndex > 
   // 1) - ��������� ���� �������
   copiedHigh   = CopyHigh(_Symbol, _Period, 0, countBars, buffer_high);   
   copiedLow    = CopyLow(_Symbol, _Period, 0, countBars, buffer_low);   
   copiedClose  = CopyClose(_Symbol, _Period, 0, countBars, buffer_close);
   // 2) - �������� ������������ �������� �����
   if ( copiedClose < countBars || copiedHigh < countBars || copiedLow < countBars)
    { // ���� �� ������� ���������� ��� ���� �������
     Alert("�� ������� ���������� ��� ���� �������");
     return;
    }
   // 3) - ���� ������� ���������, �� ���������� ����� MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE); 
   // 4) - �������� ���������� ����� MACD
   if (handleMACD <= 0)
    {
     Alert("�� ������� ��������� ����� MACD");
     return;
    }  
   // 5) - ��������� �� ���� ����� ������� � ��������� �� ������ ���������\�����������
   
  }