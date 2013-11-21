//+------------------------------------------------------------------+
//|                                                       KATANA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <CompareDoubles.mqh>              //��� ��������� ���������� ���� double
#include <Lib CisNewBar.mqh>               //��� �������� ������������ ������ ����

//+------------------------------------------------------------------+
//| ��������� KATANA                                                 |
//+------------------------------------------------------------------+
//---- ����� ������������� 2 ������
#property indicator_buffers 1
//---- ������������ 1 ����������� ��� �������
#property indicator_plots   1

//---- � �������� ���������� ������������ �������
#property indicator_type1 DRAW_SECTION
//---- ���� ����������
#property indicator_color1  clrBlue
//---- ����� ����� ����������
#property indicator_style1  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width1  1
//---- ����������� ����� ����� ����������
#property indicator_label1  "TREND_UP"
//---- ��������� ��������� ����������
input uint priceDifference=0;//������� ��� ��� ������ �����������
//---- ��������� ����������� 
struct Extrem
  {
   uint   n_bar;             //����� ���� 
   double price;             //������� ��������� ����������
  };
//---- ��������� ���������� ����������

double tg_up;                //������� ���� ������� ����� ����� (������ �����)
bool   first_start=true;     //���� ������� ������� OnCalculate

//---- ������ �������� �����
double line_up[];            //����� ����� ����� (������ �����)
//---- ����������
Extrem left_extr_up;         //����� ��������� ������ ����� (������ �����)
Extrem right_extr_up;        //������ ��������� ������ ����� (������ �����)
//----  ����� ������ �����������
uint   flag_up;              //���� ������ ���������� ������ ����� (������ �����)
//----  ��� �������� ������������ ������ ����
CisNewBar     isNewBar;                    
double   GetTan(bool trend_type)
//��������� �������� �������� ������� �����
 {
  //���� ����� ��������� ������� ������� ������ ����� (������ �����)
 // if (trend_type == true)
   return ( right_extr_up.price - left_extr_up.price ) / ( right_extr_up.n_bar - left_extr_up.n_bar );
  //���� ����� ��������� ������� ������� ������ ���� (������� �����)
  // return ( right_extr_down.price - left_extr_down.price ) / ( right_extr_down.n_bar - left_extr_down.n_bar );   
 } 

double   GetLineY (bool trend_type,uint n_bar)
//���������� �������� Y ����� ������� �����
 {
  //���� ����� ��������� �������� ����� �� ����� ������ �����
  //if (trend_type == true)
   return (right_extr_up.price + (n_bar-right_extr_up.n_bar)*tg_up);
  //���� ����� ��������� �������� ����� �� ����� ������ ����
  //return (right_extr_down.price + (n_bar-right_extr_down.n_bar)*tg_down);
 }


int OnInit()
  {
  
   SetIndexBuffer(0,line_up,    INDICATOR_DATA);   
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   
//   SetIndexBuffer(1,line_down,  INDICATOR_DATA);  
   
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
  uint index;
  double priceDiff_left;
  double priceDiff_right;
  //���� ������ ������
  if (first_start)
   {
   //0) �������� ����� ������ �����������
   flag_up   = 0;
  
   //1) �������� �� ����� � ���� ��� ����������
    for (index=rates_total-2;index>0;index--)
     {
      //---- ��������� ��������� �������
      line_up[index] = 0;
      //---- ��������� ����������� ������ ���
      //���������� ������ ���
      priceDiff_left  = low[index+1]-low[index];
      priceDiff_right = low[index-1]-low[index]; 
      //���� ������ ���������
      if (priceDiff_left >= priceDifference && priceDiff_right >= priceDifference && flag_up < 2)
       { 
        //���� ��� ������ ��������� ���������
        if (flag_up == 0)
         {
           right_extr_up.n_bar = index;
           right_extr_up.price = low[index];
           flag_up = 1;
         }
        //���� ��� ������ ��������� ���������
        else
         {
           left_extr_up.n_bar = index;
           left_extr_up.price = low[index];
           flag_up = 2;
         }
       }
      
       
     }
     //���� ��� ������ ����� ������� ��� ����������
     if (flag_up == 2)
      {
       //�� ��������� ������� ������� ����� ������
       tg_up = GetTan(true);
       //��������� �������� � ������
       line_up[left_extr_up.n_bar] = left_extr_up.price;
       line_up[rates_total-1] = GetLineY(true,rates_total-1);
      }
   }
   //���� �� ������ ������ 
   else
    {
     //---- ���� ����������� ����� ���
     if ( isNewBar.isNewBar() > 0 )
      {
       //---- ��������� ������� ��� 
       priceDiff_left  = low[rates_total-1]-low[rates_total-2];
       priceDiff_right = low[rates_total-3]-low[rates_total-2];
       //---- �������� �������� �������� �������
       line_up[rates_total-1] = 0;

       //---- ���� ������ ���������
       if (priceDiff_left >= priceDifference && priceDiff_right >= priceDifference) 
        {     
          //---- ���� ���� �� ������� �� ����� ������
          if (low[rates_total-2] > GetLineY(true,rates_total-2) )
           {
             //---- ��������� ����� �������� ��� ������ ����������
             left_extr_up.price = right_extr_up.price;
             left_extr_up.n_bar = right_extr_up.n_bar;
           } 
             //---- ��������� ������� ���������
             right_extr_up.price = low[rates_total-2];
             right_extr_up.n_bar = rates_total-2;        
             //---- ��������� ������� ����� �����    
             tg_up = GetTan(true);
        } 
        line_up[rates_total-1] = GetLineY(true,rates_total-1);
      }
    }
   return(rates_total);
  }