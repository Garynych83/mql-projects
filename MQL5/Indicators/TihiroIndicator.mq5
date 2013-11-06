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
#include <CompareDoubles.mqh>   

//---- ����� ������������� 2 ������
#property indicator_buffers 6
//---- ������������ 1 ����������� ����������
#property indicator_plots   6
//---- � �������� ���������� ������������ �����
#property indicator_type1 DRAW_LINE
//---- ���� ����������
#property indicator_color1  clrBlue
//---- ����� ����� ����������
#property indicator_style1  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width1  1
//---- ����������� ����� ����� ����������
#property indicator_label1  "TREND_DOWN"

//---- � �������� ���������� ������������ �����
#property indicator_type2 DRAW_LINE
//---- ���� ����������
#property indicator_color2  clrRed
//---- ����� ����� ����������
#property indicator_style2  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width2  1
//---- ����������� ����� ����� ����������
#property indicator_label2  "TREND_UP"

//---- � �������� ���������� ������������ �����
#property indicator_type3 DRAW_LINE
//---- ���� ����������
#property indicator_color3  clrLightGreen
//---- ����� ����� ����������
#property indicator_style3  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width3  1


//---- � �������� ���������� ������������ �����
#property indicator_type4 DRAW_LINE
//---- ���� ����������
#property indicator_color4  clrLightYellow
//---- ����� ����� ����������
#property indicator_style4  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width4  1

//---- � �������� ���������� ������������ �����
#property indicator_type5 DRAW_LINE
//---- ���� ����������
#property indicator_color5  clrLightBlue
//---- ����� ����� ����������
#property indicator_style5  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width5  1

//---- � �������� ���������� ������������ �����
#property indicator_type6 DRAW_LINE
//---- ���� ����������
#property indicator_color6  clrLightCyan
//---- ����� ����� ����������
#property indicator_style6  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width6  1

input short bars=50;  //��������� ���������� ����� �������

//---- ����� �������� �����  ������
double trendLineDown[];
double trendLineUp[];
double highPrice[];
double lowPrice[];
double levelLineDown[];
double levelLineUp[];


//---- TD ����� (����������) ����������� ������
Extrem point_up_left;    //����� �����
Extrem point_up_right;   //������ �����
//---- TD ����� (����������) ����������� ������
Extrem point_down_left;  //����� �����
Extrem point_down_right; //������ �����
//---- �������� ������� ����� ������
double tg_down;               //������� ���������� ����� �����
double tg_up;                 //������� ���������� ����� �����
//---- ����� ��� ������ �����������
short  flag_up=0;        //���� ��� ����������� ������, 0-��� ����������, 1-������ ����, 2-��� �������
short  flag_down=0;      //���� ��� ����������� ������, 0-��� ����������, 1-������ ����, 2-��� �������

int OnInit()
  {
//---- ��������� ������� �������
   SetIndexBuffer(0,trendLineDown,INDICATOR_DATA);   
   SetIndexBuffer(1,trendLineUp,  INDICATOR_DATA);   
   SetIndexBuffer(2,highPrice,  INDICATOR_DATA);   
   SetIndexBuffer(3,lowPrice,  INDICATOR_DATA);  
   SetIndexBuffer(4,levelLineDown,  INDICATOR_DATA);   
   SetIndexBuffer(5,levelLineUp,  INDICATOR_DATA);                   
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
   for(i = rates_total-3; i > 0; i--)
    {
     trendLineDown[i]=0;    
     trendLineUp[i]=0;       
     //���� ������� high ���� ������ high ��� ����������� � ����������
     if (GreatDoubles(high[i],high[i-1])&&GreatDoubles(high[i],high[i+1])&&flag_down < 2)
      {
       if (flag_down == 0)
        {
         //��������� ������ ���������
         point_down_right.SetExtrem(time[i],high[i]);
         flag_down=1; 
        }
       else 
        {
         if(GreatDoubles(high[i],point_down_right.price))
          {
          //��������� ����� ���������
          point_down_left.SetExtrem(time[i],high[i]);               
          flag_down=2;
          }
        }            
      }  //���������� �����
     //���� ������� low ���� ������ low ��� ����������� � ����������
     if (LessDoubles(low[i],low[i-1])&&LessDoubles(low[i],low[i+1])&&flag_up < 2)
      {
       if (flag_up == 0)
        {
         //��������� ������ ���������
         point_up_right.SetExtrem(time[i],low[i]);
         flag_up=1; 
        }
       else 
        {
         if(LessDoubles(low[i],point_up_right.price))
          {
          //��������� ����� ���������
          point_up_left.SetExtrem(time[i],low[i]);        
          flag_up=2;
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
    
    datetime L_DOWN,L_UP;
    double H_DOWN,H_UP;
    if (flag_down == 2)
    {
     L_DOWN=point_down_right.time-point_down_left.time;    
     H_DOWN=point_down_right.price-point_down_left.price; 
    }
    if (flag_up == 2)
    {
     L_UP=point_up_right.time-point_up_left.time;    
     H_UP=point_up_right.price-point_up_left.price;    
    }    
    
    for (i = rates_total-2; i > 0 ; i--)
     { 
       trendLineDown[i] = 0;
       trendLineUp[i] = 0;
       highPrice[i] = high[i];
       lowPrice[i]  = low[i];
       
      if (flag_down==2)
       levelLineDown[i] = H_DOWN-tg_down*L_DOWN;
      else
       levelLineDown[i] = 0;
       
      if (flag_up==2)
       levelLineUp[i] = H_UP-tg_up*L_UP;
      else
       levelLineUp[i] = 0;       
      
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
