//+------------------------------------------------------------------+
//|                                              TihiroIndicator.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

//---- ����� ������������� 1 �����
#property indicator_buffers 1
//---- ������������ 1 ����������� ����������
#property indicator_plots   1
//---- � �������� ���������� ������������ �����
#property indicator_type1   DRAW_LINE
//---- ���� ����������
#property indicator_color1  clrBlue
//---- ����� ����� ����������
#property indicator_style1  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width1  1
//---- ����������� ����� ����� ����������
#property indicator_label1  "TIHIRO"


//---- ����� �������� ����� ������
double trendLine[];


int OnInit()
  {
//---- ��������� ������ ������
   SetIndexBuffer(0,trendLine,INDICATOR_DATA);
//---- ����������� �������� ����������
   //PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, clrYellow);
   return(INIT_SUCCEEDED);
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
   for(int i = 0; i <= rates_total; i++)
    {
     trendLine[i] = 1.37860;
    }
   return(rates_total);
  }
