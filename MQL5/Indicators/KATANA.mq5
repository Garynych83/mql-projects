//+------------------------------------------------------------------+
//|                                                       KATANA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <CompareDoubles.mqh>  

//+------------------------------------------------------------------+
//| ��������� KATANA                                                 |
//+------------------------------------------------------------------+
//---- ����� ������������� 2 ������
#property indicator_buffers 2
//---- ������������ 1 ����������� ��� �������
#property indicator_plots   2

//---- � �������� ���������� ������������ �������
#property indicator_type1 DRAW_COLOR_SECTION
//---- ���� ����������
#property indicator_color1  clrBlue
//---- ����� ����� ����������
#property indicator_style1  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width1  1
//---- ����������� ����� ����� ����������
#property indicator_label1  "TREND_DOWN"

//---- � �������� ���������� ������������ �������
#property indicator_type2 DRAW_COLOR_SECTION
//---- ���� ����������
#property indicator_color2  clrRed
//---- ����� ����� ����������
#property indicator_style2  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width2  1
//---- ����������� ����� ����� ����������
#property indicator_label2  "TREND_UP"

//��������� ��������� ����������

//��������� ���������� ����������

double tg;  //������� ���� ������� �����
double point_y_left;  //������ ����� ����� �����
double point_y_right; //������ ������ ����� �����

void   GetTan()
//��������� �������� �������� ������� �����
 {
 
 } 
 
uint   GetAverageY ()
//���������� ������� �������� ���� �������� 
 {
 
 }

uint   GetLineY ()
//���������� �������� Y ����� ������� �����
 {
 
 }

int OnInit()
  {

  
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

   return(rates_total);
  }