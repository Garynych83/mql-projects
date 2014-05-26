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
#property indicator_type1 DRAW_LINE       // � �������� ���������� ������������ �����
#property indicator_color1  clrWhite      // ���� �����
#property indicator_style1  STYLE_SOLID   // ����� �����
#property indicator_width1  1             // ������� �����
#property indicator_label1  "������� ATR" // ������������ ������

#property indicator_type1 DRAW_LINE       // � �������� ���������� ������������ �����
#property indicator_color1  clrLightBlue  // ���� �����
#property indicator_style1  STYLE_SOLID   // ����� �����
#property indicator_width1  1             // ������� �����
#property indicator_label1  "ATR" // ������������ ������

//+------------------------------------------------------------------+
//| ��������� ����������� ATR                                        |
//+------------------------------------------------------------------+

// ���������� ����������� ����������
#include <Lib CisNewBar.mqh>  // ��� �������� ������������ ������ ����

// ������� ��������� ���������� 
input int ma_period   = 100;       // ������ ���������� 
input int aver_period = 100;       // ������ ���������� �������� ATR


// ��������� ���������� ����������
int handleATR;                // ����� ���������� ATR
int copiedATR = -1;           // ���������� ��� ��������� ���������� ������������� ������ ���������� ATR   
int startIndex;               // ������ � �������� ������ ���������� ���������� ATR                     
// ������������ ������
double averATRBuffer[];       // ������ �������� ����������� �������� ATR
double bufferATR[];           // ������ �������� ������ ATR

// ������������ ������� �������
CisNewBar *isNewBar;          // ������ ������ �������� ��������� ������ ����


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

         
     }
    // ���� �� ������ �������� ����������
    else 
     {
     /*  // ���� ����� ��� �����������
       if ( isNewBar.isNewBar() > 0 )
        {
          copiedATR 
          averATRBuffer[0] = 
        }*/
     }
   return(rates_total);
  }
  
  // ������� ������� ������� �������� ������������� ������ ATR
  double  GetAverageATRValue (int start_pos)   // start_pos - ������ ������ ��������� ������� �������� ������������� ������ 
   {
     double averValue = 0;   // ���������� ��� �������� �������� �������� 
     int    index;           // ���������� ��� ������� �� �����
    // for (index=start_pos;index
   }