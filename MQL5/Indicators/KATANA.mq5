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
#property indicator_width1  2
//---- ����������� ����� ����� ����������
#property indicator_label1  "TREND_UP"

//---- � �������� ���������� ������������ �������
#property indicator_type2 DRAW_SECTION
//---- ���� ����������
#property indicator_color2  clrRed
//---- ����� ����� ����������
#property indicator_style2  STYLE_SOLID
//---- ������� ����� ����������
#property indicator_width2  2
//---- ����������� ����� ����� ����������
#property indicator_label2  "TREND_DOWN"

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
double tg_down;              //������� ���� ������� ����� ���� (������� �����)

bool   first_start=true;     //���� ������� ������� OnCalculate

//---- ������ �������� �����
double line_up[];            //����� ����� ����� (������ �����)
double line_down[];          //����� ����� ���� (������� �����)
//---- ����������
Extrem left_extr_up;         //����� ��������� ������ ����� (������ �����)
Extrem right_extr_up;        //������ ��������� ������ ����� (������ �����)
Extrem left_extr_down;       //����� ��������� ������ ���� (������� �����)
Extrem right_extr_down;      //������ ��������� ������ ���� (������� �����)
//----  ����� ������ �����������
uint   flag_up;              //���� ������ ���������� ������ ����� (������ �����)
uint   flag_down;            //���� ������ ���������� ������ ���� (������� �����)
//----  ��� �������� ������������ ������ ����
CisNewBar     isNewBar; 
//---- ���������� ��� �������� ������ ���
double priceDiff_left;       
double priceDiff_right;

                   
double   GetTan(bool trend_type)
//��������� �������� �������� ������� �����
 {
  //���� ����� ��������� ������� ������� ������ ����� (������ �����)
  if (trend_type == true)
   return ( right_extr_up.price - left_extr_up.price ) / ( right_extr_up.n_bar - left_extr_up.n_bar );
  //���� ����� ��������� ������� ������� ������ ���� (������� �����)
  return ( right_extr_down.price - left_extr_down.price ) / ( right_extr_down.n_bar - left_extr_down.n_bar );   
 } 

double   GetLineY (bool trend_type,uint n_bar)
//���������� �������� Y ����� ������� �����
 {
  //���� ����� ��������� �������� ����� �� ����� ������ �����
  if (trend_type == true)
   return (left_extr_up.price + (n_bar-left_extr_up.n_bar)*tg_up);
  //���� ����� ��������� �������� ����� �� ����� ������ ����
  return (right_extr_down.price + (n_bar-right_extr_down.n_bar)*tg_down);
 }
 
 /*

void     GetPriceDifferences(double &array[],bool trend_type,uint index)
//���������� ������ ���
    {
     switch (trend_type)
      {
       //---- ����� ����� (������ �����)
       case 0:  
        priceDiff_left  = array[index+1]-array[index];
        priceDiff_right = array[index-1]-array[index]; 
       break;
       //---- ����� ���� (������� �����)
       case 1:
        priceDiff_left  = array[index]-array[index+1];
        priceDiff_right = array[index]-array[index-1];
       break;
      }
    }
 
void     ChangeFlag (double &array[],bool trend_type,int index)
//�������� ���� ������ �����������
  {
   switch (trend_type)
    {
     case 0:
      if (flag_up == 0)
       {
        right_extr_up.n_bar = index;
        right_extr_up.price = array[index];
        flag_up = 1;
       }
      //���� ��� ������ ��������� ���������
      else
       {
        left_extr_up.n_bar = index;
        left_extr_up.price = array[index];
        flag_up = 2;
       }     
     break;
     case 1:
      if (flag_down == 0)
       {
        right_extr_down.n_bar = index;
        right_extr_down.price = array[index];
        flag_down = 1;
       }
      //���� ��� ������ ��������� ���������
      else
       {
        left_extr_down.n_bar = index;
        left_extr_down.price = array[index];
        flag_down = 2;
       }       
     break;
    }
  }    */

int OnInit()
  {
  
   SetIndexBuffer(0,line_up,    INDICATOR_DATA);   
   SetIndexBuffer(1,line_down,  INDICATOR_DATA);  
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   
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

  //���� ������ ������
  if (first_start)
   {
   //0) �������� ����� ������ �����������
     flag_up   = 0;
   //��������� ��������� �������
     line_up[rates_total-1]=0;     
     line_up[rates_total-2]=0;
   //1) �������� �� ����� � ���� ��� ����������
    for (index=rates_total-3;index>0 && flag_up < 2;index--)
     {
      //---- ��������� ��������� �������
      line_up[index] = 0;
      //---- ��������� ����������� ������ ���
      //���������� ������ ���
      priceDiff_left  = low[index+1]-low[index];
      priceDiff_right = low[index-1]-low[index]; 
      //���� ������ ���������
      if (priceDiff_left > priceDifference && priceDiff_right > priceDifference)
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
       first_start = false;
      }
   }
   //���� �� ������ ������ 
   else
    {
     //---- ���� ����������� ����� ���
     if ( isNewBar.isNewBar() > 0 )
      {
      
       //---- ��������� ������� ��� 
       priceDiff_left  = low[rates_total-2]-low[rates_total-3];  
       priceDiff_right = low[rates_total-4]-low[rates_total-3]; 
       //---- �������� �������� �������� �������
       line_up[rates_total-2] = 0;

       //---- ���� ������ ���������
       if (priceDiff_left >= priceDifference && priceDiff_right >= priceDifference) 
        {     
          //---- ���� ���� �� ������� �� ����� ������
          if (low[rates_total-3] > GetLineY(true,rates_total-3) )
           {
             //---- ��������� ����� �������� ��� ������ ����������
             line_up[left_extr_up.n_bar] = 0;
             left_extr_up.price = right_extr_up.price;
             left_extr_up.n_bar = right_extr_up.n_bar;
             line_up[left_extr_up.n_bar] = left_extr_up.price;             
           } 
             //---- ��������� ������� ���������
             right_extr_up.price = low[rates_total-3];
             right_extr_up.n_bar = rates_total-3;        
             //---- ��������� ������� ����� �����    
             tg_up = GetTan(true);
             Comment("(",DoubleToString(left_extr_up.price),") (",DoubleToString(right_extr_up.price),")");    
        } 
        line_up[rates_total-1] = GetLineY(true,rates_total-1);
      }
    }
   return(rates_total);
  }