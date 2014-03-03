//+------------------------------------------------------------------+
//|                                                TesterDivMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs                  // ������ ��������� ������
#include <divergenceMACD.mqh>                 // ���������� ���������� ��� ������ ��������� � ����������� ����������
#include <CompareDoubles.mqh>                 // ��� �������� �����������  ���
//+------------------------------------------------------------------+
//| ������ ����������� ������������ ����������� MACD                 |
//+------------------------------------------------------------------+

// ���������, �������� �������������

input int bars_ahead      = 10;    // ���������� ����� ������ ����� ������� ��� �������� ������������  
input int fast_ema_period = 12;    // ������ ������� ������� MACD
input int slow_ema_period = 26;    // ������ ��������� ������� MACD
input int signal_period   = 9;     // ������ ���������� �������� MACD 

// ���������� ��� �������� ���������� ���������� � �� ���������� ��������

 int countConvPos = 0;       // ���������� ������������� �������� ���������
 int countConvNeg = 0;       // ���������� ���������� �������� ���������
 int countDivPos  = 0;       // ���������� ������������� �������� �����������
 int countDivNeg  = 0;       // ���������� ���������� �������� ����������� 

// ������ �������� ����� 
 double buffer_high [];      // ������� ����
 double buffer_low  [];      // ������ ����
 double buffer_close[];      // ���� �������� 

// ���������� ��� �������� ���������� �������� ����� 

 int copiedHigh;             // ������� ����
 int copiedLow;              // ������ ����
 int copiedClose;            // ���� ��������
 
// ����� MACD
 int handleMACD; 
 
// ������� �������� �����
 int lastBarIndex;  // ������ ���������� ���� 

// ����� ��� �������� ����������� ������ ���������\����������� MACD
 PointDiv  divergencePoints;    

// ��������� ���������� ��� �������� ��������� ��������� � ����������
 double localMax;
 double localMin;

// ������� ������ ��������� � �������� �� �������� �����
 void GetMaxMin(int index)
 {
  int count;
  localMax = buffer_high[index];
  localMin = buffer_low[index];
  for (count=1;count<=bars_ahead;count++)
   {
    if (buffer_high[index-count] > localMax)
     localMax = buffer_high[index-count];
    if (buffer_low[index-count] < localMin)
     localMin = buffer_low[index-count];
   }
 }

void OnStart()
  {
   // ���������� �������� ����������
   int      countBars = Bars(_Symbol,_Period); // ����� ����� �������
   ArraySetAsSeries(buffer_high , true); // ���������� ��� � ���������
   ArraySetAsSeries(buffer_low  , true); // ���������� ��� � ���������
   ArraySetAsSeries(buffer_close, true); // ���������� ��� � ���������
   // 0) - ���������� ������� ������� ����
   lastBarIndex  = countBars - 101;
   if (lastBarIndex <= bars_ahead)
    {
     Alert("�������������� ����������� ������� �������� � ���������� ����� �������");
     return;
    }
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
   // 5) - ��������� �� ���� ����� ������� � ��������� �� ������ ���������\����������� (� ������ ������� � �����)
   for(int index=lastBarIndex;index>bars_ahead;index--)
    {
     // ��������� ���������\�����������
     switch ( divergenceMACD (handleMACD,_Symbol,_Period,index,divergencePoints) )
      {
       // ���� ������� ���������
       case 1:
        GetMaxMin(index+1); // ������� �������� � ������� ���
        // ���� ��������� �������
        if ( (localMax - buffer_close[index]) > (buffer_close[index] - localMin) )
         {
          countConvPos ++; // ����������� ������� ������������� ���������
         }
        else
         {
          countConvNeg ++; // ����� ����������� ������� ������������� ���������
         }
       break;
       // ���� ������� �����������
       case -1:
        GetMaxMin(index+1); // ������� �������� � ������� ���
        // ���� ����������� �������
        if ( (localMax - buffer_close[index]) < (buffer_close[index] - localMin) )
         {
          countDivPos ++; // ����������� ������� ������������� �����������
         }
        else
         {
          countDivNeg ++; // ����� ����������� ������� ������������� �����������
         }       
       break;
      }
    }
    Alert("________________________________________");
    Alert("�� ���������� �����������: ",countDivNeg);
    Alert("���������� �����������: ",countDivPos);
    Alert("����� �����������: ",countDivPos+countDivNeg);
    Alert("�� ���������� ���������: ",countConvNeg);
    Alert("���������� ���������: ",countConvPos);
    Alert("����� ���������: ",countConvPos+countConvNeg);
    Alert("���������� ������ ���������\�����������:");
  }