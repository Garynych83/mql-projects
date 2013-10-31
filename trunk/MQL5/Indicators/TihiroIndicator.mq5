//+------------------------------------------------------------------+
//|                                              TihiroIndicator.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <TIHIRO\Extrem.mqh>     //���������� ���������� ��� ������ �����������

//---- ����� ������������� 1 �����
#property indicator_buffers 2
//---- ������������ 1 ����������� ����������
#property indicator_plots   2
//---- � �������� ���������� ������������ �����
#property indicator_type1 DRAW_LINE
//---- ���� ����������
#property indicator_color1  clrBlue
//---- ����� ����� ����������
#property indicator_style1  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width1  2
//---- � �������� ���������� ������������ �����
#property indicator_type2 DRAW_LINE
//---- ���� ����������
#property indicator_color2  clrRed
//---- ����� ����� ����������
#property indicator_style2  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width2  2
//---- ����������� ����� ����� ����������
#property indicator_label1  "TIHIRO"

input short bars=50;  //��������� ���������� ����� �������

//---- ����� �������� ����� ����������� ������
double trendLineDown[];
//---- ����� �������� ����� ����������� ������
double trendLineUp[];


//---- TD ����� (����������) ����������� ������
Extrem point_up_left;    //����� �����
Extrem point_up_right;   //������ �����
//---- TD ����� (����������) ����������� ������
Extrem point_down_left;  //����� �����
Extrem point_down_right; //������ �����
//---- �������� ������� ����� ������
double tg_up;            //������� ���������� �����
double tg_down;          //������� ���������� �����
//---- ����� ��� ������ �����������
short   flag_up=0;       //���� ��� ����������� ������, 0-��� ����������, 1-������ ����, 2-��� �������
short   flag_down=0;     //���� ��� ����������� ������, 0-��� ����������, 1-������ ����, 2-��� �������

int OnInit()
  {
//---- ��������� ������� �������
   SetIndexBuffer(0,trendLineDown,INDICATOR_DATA);   
   SetIndexBuffer(1,trendLineUp,  INDICATOR_DATA);
//---- ����������� �������� ����������
//--- ������� ��� ������� ��� ��������� � PLOT_ARROW

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
   int i;
   //�������� �� ����� � ��������� ����������
   for(i = rates_total-2; i > 0; i--)
    {
     trendLineDown[i]=0;    
     trendLineUp[i]=0;
     //���� ������� high ���� ������ high ��� ����������� � ����������
     if (high[i] > high[i-1] && high[i] > high[i+1] && flag_down < 2 )
      {
       if (flag_down == 0)
        {
         //��������� ������ ���������
         point_down_right.SetExtrem(time[i],high[i]);
         flag_down++; 
        }
       else 
        {
         if(high[i] > point_down_right.price)
          {
          //��������� ����� ���������
          point_down_left.SetExtrem(time[i],high[i]);               
          flag_down++;
          }
        }            
      }  //���������� �����
     //���� ������� low ���� ������ low ��� ����������� � ����������
     if (low[i] < low[i-1] && low[i] < low[i+1] && flag_up < 2 )
      {
       if (flag_up == 0)
        {
         //��������� ������ ���������
         point_up_right.SetExtrem(time[i],low[i]);
         flag_up++; 
        }
       else 
        {
         if(low[i] < point_up_right.price)
          {
          //��������� ����� ���������
          point_up_left.SetExtrem(time[i],low[i]);        
          flag_up++;
          }
        }            
      }  //���������� �����         
    } 
    //��������� �������� ������� ����� �����
    if (flag_down==2) //���� ��� ���������� ��� ����������� ������ �������
     {
      tg_down = (point_down_right.price-point_down_left.price)/(point_down_right.time-point_down_left.time);
     }
    if (flag_up==2) //���� ��� ���������� ��� ����������� ������ �������
     {
      tg_up = (point_up_right.price-point_up_left.price)/(point_up_right.time-point_up_left.time);
     }     
    //�������� �� ����� � ��������� �����, ������������� ������ ������
    for (i = rates_total-1; i > 0 ; i--)
     {
      if (flag_down==2)
       {
        if (time[i]>=point_down_left.time)
         trendLineDown[i] = point_down_left.price+(time[i]-point_down_left.time)*tg_down;
       }
      if (flag_up==2)
       {
        if (time[i]>=point_up_left.time)
         trendLineUp[i] = point_up_left.price+(time[i]-point_up_left.time)*tg_up;
       }       
     }
     flag_down = 0;
     flag_up = 0;
   return(rates_total);
  }
