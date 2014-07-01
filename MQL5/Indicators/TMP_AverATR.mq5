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

// ������� ��������� ���������� 
input int ma_period   = 100;                       // ������ ���������� 
input int aver_period = 100;                       // ������ ���������� �������� ATR
 

// ��������� ���������� ���������� 
int    startIndex;               // ������ � �������� ������ ���������� ���������� ATR
int    index;                    // ������ ������� �� �����          
double lastSummPrice;            // ���������� �������� ��������� ����� ���
double lastSummATR;              // ���������� �������� ��������� ����� �������� ATR              
// ������������ ������
double averATRBuffer[];          // ������ �������� ����������� �������� ATR
double bufferATR[];              // ������ �������� ������ ATR

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
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit (const int reason)
 {
  // ������� ������ �����������
  ArrayFree(averATRBuffer);
  ArrayFree(bufferATR);
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
        
       // �������� �� ���� ����� � ��������� ATR
       lastSummPrice = 0;
       for (index=0;index<ma_period;index++)
        lastSummPrice = lastSummPrice + high[ma_period-index-1]-low[ma_period-index-1];
        
       bufferATR[ma_period-1] = lastSummPrice / ma_period;  // ��������� ������ ������� ��������
       // �������� �� ������ ��� � ��������� ��������� ����������� ��������
       for (index = ma_period;index < rates_total; index++)
        {
         lastSummPrice = lastSummPrice + high[index] - low[index] - high[index-ma_period] + low[index-ma_period]; // ��������� ����� �����
         bufferATR[index] = lastSummPrice / ma_period;     // ��������� ������� ��������
        }       
        
       // �������� �� ������ ATR �� startIndex �� ����� � ��������� ����� 
       lastSummATR = 0;
       for (index=0;index<aver_period;index++)
        lastSummATR = lastSummATR + bufferATR[startIndex-index];
       averATRBuffer[startIndex] = lastSummATR / aver_period;  // ��������� ������ ������� ��������
       // �������� �� ������ ATR � ��������� ��������� ����������� ��������
       for (index = startIndex+1;index < rates_total; index++)
        {
         lastSummATR = lastSummATR + bufferATR[index] - bufferATR[index-aver_period];  // ��������� ����� �����
         averATRBuffer[index] = lastSummATR / aver_period;     // ��������� ������� ��������
        }
        
     }
    // ���� �� ������ �������� ����������
    else 
     {      
        lastSummPrice = 0;
        for (index=0;index<ma_period;index++)
         {
          lastSummPrice = lastSummPrice + high[rates_total - index - 1] - low[rates_total - index - 1];
         }         
        bufferATR [rates_total-1] = lastSummPrice / ma_period;     
        lastSummATR = 0;
        for (index=0;index<aver_period;index++)
         lastSummATR = lastSummATR + bufferATR[rates_total-1-index];
        // ���������� ������� �������� ��������  
        averATRBuffer[rates_total-1] = lastSummATR / aver_period;
        Print("[",DoubleToString(averATRBuffer[rates_total-1]),"]");
     }
   return(rates_total);
  }