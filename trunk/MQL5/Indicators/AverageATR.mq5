//+------------------------------------------------------------------+
//|                                                   AverageATR.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window       // ������ ��������� ����� �������� � ��������� ����
#property indicator_buffers 2             // ���������� ������� �����     
#property indicator_plots   2             // �� ���, ������� ������������ � ����
// �������� �������
#property indicator_type1   DRAW_LINE     // � �������� ���������� ������������ �����
#property indicator_color1  clrWhite      // ���� �����
#property indicator_style1  STYLE_SOLID   // ����� �����
#property indicator_width1  1             // ������� �����
#property indicator_label1  "������� ATR" // ������������ ������

#property indicator_type2   DRAW_LINE     // � �������� ���������� ������������ �����
#property indicator_color2  clrLightCoral // ���� �����
#property indicator_style2  STYLE_SOLID   // ����� �����
#property indicator_width2  1             // ������� �����
#property indicator_label2  "ATR"         // ������������ ������


//+------------------------------------------------------------------+
//| ��������� ����������� ATR                                        |
//+------------------------------------------------------------------+

// ���������� ����������� ����������
#include <Lib CisNewBar.mqh>     // ��� �������� ������������ ������ ����

// ������� ��������� ���������� 
input int ma_period   = 100;     // ������ ���������� 
input int aver_period = 100;     // ������ ���������� �������� ATR


// ��������� ���������� ����������
int    handleATR;                // ����� ���������� ATR
int    copiedATR = -1;           // ���������� ��� ��������� ���������� ������������� ������ ���������� ATR   
int    startIndex;               // ������ � �������� ������ ���������� ���������� ATR
int    index;                    // ������ ������� �� �����          
double lastSumm;                 // ���������� �������� ��������� ����� ��������              
// ������������ ������
double averATRBuffer[];          // ������ �������� ����������� �������� ATR
double bufferATR[];              // ������ �������� ������ ATR
double tmpBuffer[];              // ����� ���������� ��������

// ������������ ������� �������
CisNewBar *isNewBar;             // ������ ������ �������� ��������� ������ ����

int OnInit()
  {
   int barsCount;             // ��� �������� ���������� ����� � �������
   // ��������� ���������� ����� � �������
   barsCount = Bars(_Symbol,_Period); 
   // ��������� ��������� ������, � �������� ������ ��������� ����������� �������� ATR 
   startIndex = ma_period-1+aver_period;
   // ���� ��������� ������ �������� ���������� ���������� �����
   if (startIndex >= barsCount)
    {
     Print("������ ������������� ���������� AverageATR. �� ��������� ������ ������� ����������");
     return (INIT_FAILED);
    }
   // ������ ��������� ������������ �������
   SetIndexBuffer(0,averATRBuffer,INDICATOR_DATA);  
   SetIndexBuffer(1,bufferATR,INDICATOR_DATA);     
   // ��������� ����� ATR
   handleATR = iATR(_Symbol,_Period,ma_period);
   // ������� ������ ������ isNewBar
   isNewBar = new CisNewBar(_Symbol,_Period);
   if (handleATR == INVALID_HANDLE)
    {
     Print("������ ������������� ���������� AverageATR. �� ������� ������� ��������� ATR");
     return(INIT_FAILED);
    }
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit (const int reason)
 {
  // ������� ������ �����������
  ArrayFree(averATRBuffer);
  // ����������� ����� ���������� ATR
  IndicatorRelease(handleATR);
  // ������� ������ ������ isNewBar
  delete isNewBar;
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
    // ���� ��� ������ ������ ����������
    if (prev_calculated == 0)
     {
       // �������� ����������� ������ ���������� ATR
       copiedATR = CopyBuffer(handleATR,0,0,rates_total,bufferATR);
       
       if (copiedATR < rates_total)
        {
         Print("������ ���������� AverageATR. �� ������� ���������� ����� ���������� ATR");
         return(0);  // ����� ��������� �� ��������
        } 
       // �������� �� ������ ATR �� startIndex �� ����� � ��������� ����� 
       lastSumm = 0;
       for (index=0;index<aver_period;index++)
        lastSumm = lastSumm + bufferATR[startIndex-index];
       averATRBuffer[startIndex] = lastSumm / aver_period;  // ��������� ������ ������� ��������
       // �������� �� ������ ATR � ��������� ��������� ����������� ��������
       for (index = startIndex+1;index < rates_total; index++)
        {
         lastSumm = lastSumm + bufferATR[index] - bufferATR[index-aver_period];  // ��������� ����� �����
         averATRBuffer[index] = lastSumm / aver_period;     // ��������� ������� ��������
        }
     }
    // ���� �� ������ �������� ����������
    else 
     {
        // �������� ����������� ������ ���������� ATR
        copiedATR = CopyBuffer(handleATR,0,0,aver_period,tmpBuffer);
        if (copiedATR == aver_period)
         {
          lastSumm = 0;
          for (index=0;index<aver_period;index++)
           lastSumm = lastSumm + tmpBuffer[index];
          ArrayResize(averATRBuffer,rates_total);
          ArrayResize(bufferATR,rates_total);
          // ���������� ������� �������� ��������  
          averATRBuffer[rates_total-1] = lastSumm / aver_period;
          // ���������� �������� ATR
          bufferATR[rates_total-1] = tmpBuffer[aver_period-1];
         }
        
     }
   return(rates_total);
  }