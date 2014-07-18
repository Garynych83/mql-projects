//+------------------------------------------------------------------+
//|                                                TesterDivMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs                  // ������ ��������� ������
#include <Divergence\divergenceMACD.mqh>                 // ���������� ���������� ��� ������ ��������� � ����������� ����������
#include <CompareDoubles.mqh>                 // ��� �������� �����������  ���
//+------------------------------------------------------------------+
//| ������ ����������� ������������ ����������� MACD                 |
//+------------------------------------------------------------------+

 // ������������ ������ �������� ����� �������
 enum BARS_MODE
 {
  ALL_HISTORY=0, // ��� �������
  INPUT_BARS     // �������� ���������� ����� ������������
 };

// ���������, �������� �������������

input BARS_MODE mode      = INPUT_BARS; // ����� �������� �����
input int depth           = 1000;       // ������� �������
input int bars_ahead      = 10;         // ���������� ����� �������� ������������
input int fast_ema_period = 12;         // ������ ������� ������� MACD
input int slow_ema_period = 26;         // ������ ��������� ������� MACD
input int signal_period   = 9;          // ������ ���������� �������� MACD 

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
 PointDivMACD  divergencePoints;    

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
//    if (buffer_high[index-count] > localMax)
    if (GreatDoubles(buffer_high[index-count],localMax) )
     localMax = buffer_high[index-count];
//    if (buffer_low[index-count] < localMin)
    if ( LessDoubles(buffer_low[index-count],localMin) )
     localMin = buffer_low[index-count];
   }
 }

void OnStart()
  {
   // ���������� �������� ����������
   int      countBars;
   ArraySetAsSeries(buffer_high , true); // ���������� ��� � ���������
   ArraySetAsSeries(buffer_low  , true); // ���������� ��� � ���������
   ArraySetAsSeries(buffer_close, true); // ���������� ��� � ���������
   // ���������� ���������� �����
   if (mode == ALL_HISTORY)
    countBars =    Bars(_Symbol,_Period); // ����� ����� �������
   else
    countBars =    depth;
   // ���������� ������� ������� ����
   lastBarIndex  = countBars - 101;
   if (lastBarIndex <= bars_ahead)
    {
     Alert("�������������� ����������� ������� �������� � ���������� ����� �������");
     return;
    }
   // ��������� ���� �������
   copiedHigh   = CopyHigh(_Symbol, _Period, 0, countBars, buffer_high);   
   copiedLow    = CopyLow(_Symbol, _Period, 0, countBars, buffer_low);   
   copiedClose  = CopyClose(_Symbol, _Period, 0, countBars, buffer_close);
   // �������� ������������ �������� �����
   if ( copiedClose < countBars || copiedHigh < countBars || copiedLow < countBars)
    { // ���� �� ������� ���������� ��� ���� �������
     Alert("�� ������� ���������� ��� ���� �������");
     return;
    }
   // ���� ������� ���������, �� ���������� ����� MACD
   handleMACD = iMACD(_Symbol, _Period, fast_ema_period,slow_ema_period,signal_period,PRICE_CLOSE); 
   // �������� ���������� ����� MACD
   if (handleMACD <= 0)
    {
     Alert("�� ������� ��������� ����� MACD");
     return;
    }  
   // ��������� �� ���� ����� ������� � ��������� �� ������ ���������\����������� (� ������ ������� � �����)
   for(int index=lastBarIndex;index>bars_ahead;index--)
    {
     Comment("____________________________");
     Comment("�������� ����������: ",MathRound(100*(1.0*(lastBarIndex-bars_ahead-index)/(lastBarIndex-bars_ahead)))+"%");
     // ��������� ���������\�����������
     switch ( divergenceMACD (handleMACD,_Symbol,_Period,divergencePoints,index) )
      {
       // ���� ������� �����������
       case 1:
        GetMaxMin(index+1); // ������� �������� � ������� ���
        // ���� ��������� �������
       // if ( (localMax - buffer_close[index]) > (buffer_close[index] - localMin) )
        if ( GreatDoubles ( (localMax - buffer_close[index]), (buffer_close[index] - localMin) ) )
         {
          countDivPos ++; // ����������� ������� ������������� ���������
         }
        else
         {
          countDivNeg ++; // ����� ����������� ������� ������������� ���������
         }
       break;
       // ���� ������� ���������
       case -1:
        GetMaxMin(index+1); // ������� �������� � ������� ���
        // ���� ����������� �������
      //  if ( (localMax - buffer_close[index]) < (buffer_close[index] - localMin) )
        if (LessDoubles ( (localMax - buffer_close[index]), (buffer_close[index] - localMin) ) )
         {
          countConvPos ++; // ����������� ������� ������������� �����������
         }
        else
         {
          countConvNeg ++; // ����� ����������� ������� ������������� �����������
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