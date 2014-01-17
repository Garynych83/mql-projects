//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#include <Lib CisNewBar.mqh>    //��� �������� ������������ ������ ����
#include <CDivergence\CDivergenceMACD.mqh>   // ���������� ���������� ��� ������ ��������� � ����������� MACD
//+------------------------------------------------------------------+
//| ��������� ����������� MACD                                       |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ��������� ����������                                             |
//+------------------------------------------------------------------+

#property indicator_buffers 1
//---- ������������ 1 ����������� ����������
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
#property indicator_label1  "Divergence MACD"

//+------------------------------------------------------------------+
//| �������� ��������� ����������                                    |
//+------------------------------------------------------------------+

input short               bars=100;                  // ��������� ���������� ����� �������
input short               tale=15;                   // ����� ����� ��� ������ ����������
input int                 fast_ema_period=9;         // ������ ������� �������
input int                 slow_ema_period=12;        // ������ ��������� �������
input int                 signal_period=6;           // ������ ���������� ��������
input ENUM_APPLIED_PRICE  applied_price=PRICE_HIGH;  // ��� ���� ��� handle
input uint                priceDifference=0;         // ������� ��� ��� ������ ����������   

//+------------------------------------------------------------------+
//| ���������� ����������                                            |
//+------------------------------------------------------------------+

int handleMACD;                       // ����� MACD
string symbol = _Symbol;              // ������� ������
ENUM_TIMEFRAMES timeFrame = _Period;  // ������� ���������

double tg;                            // ������� ���� ������� �����

double line_buffer[];                 // ����� ����� ����� 

// ��������� �������� ����� 
struct Vertex
  {
   uint   n_bar;             //����� ���� 
   double price;             //������� ��������� �����
  };

Vertex pn1,pn2;   // ��� �����, ������������� ����� ����� ������ (pn1 - ����� �����, pn2 - ������ �����)
bool   first_calculate = true;   // ���� ������� ������ OnCalculate


//+------------------------------------------------------------------+
//| ���������� ������� ����������                                    |          
//+------------------------------------------------------------------+

double   GetTan()
//��������� �������� �������� ������� �����
 {
   return ( pn2.price - pn1.price ) / ( pn2.n_bar - pn1.n_bar );   
 } 

double   GetLineY (uint n_bar)
//���������� �������� Y ����� ������� �����
 {
   return (pn1.price + (n_bar-pn1.n_bar)*tg);
 }

//+------------------------------------------------------------------+
//| ������� ������� ����������                                       |
//+------------------------------------------------------------------+

int OnInit()
  {
   // ��������� ����� ���������� MACD
   handleMACD = iMACD(symbol, timeFrame, fast_ema_period,slow_ema_period,signal_period,applied_price);
   // ��������� ����� �����
   SetIndexBuffer(0,line_buffer,    INDICATOR_DATA);     
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
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
   // �������� ������� �������� ���������\�����������
   int retCode;  // ���, ������������ �������� ������ ���������\�����������
   int index;    // ������� ������� �� ����� 
   // ���� ������ ������ OnCalculate
   if ( first_calculate )
    {
     // ������ ���� �� �������������
     first_calculate = false; 
     // �������� �� ���� ����� � �������� ����� ����������
     for (index=rates_total-1;index>=0;index--)
      {
       line_buffer[index] = 0;
      }
     // ��������� � retCode
     retCode = divergenceMACD(handleMACD,symbol,timeFrame,0);
     retCode = 1;
     if (retCode == 1)  // ���� ������� �����������
      {
       // Alert("����� ����������� - ����� ����� = ");
       // ���������� ��������� �����
       //pn1.n_bar = index_Price_global_max; 
       pn1.n_bar = rates_total-11;
       pn1.price = high[rates_total-11];
       pn2.n_bar = rates_total-1;
       pn2.price = high[rates_total-1];
       // ���������� ��������
       tg = GetTan();
       Alert("������� = ",tg);
       //���������� ����� �����
       for (index=pn1.n_bar;index<pn2.n_bar;index++)
        {
         line_buffer[index] = GetLineY(index);

        }
       //return(rates_total);
      }
     if (retCode == -1) // ���� ������� ��������� 
      {  
       // Alert("����� ��������� - ������ ����� = ");
       // ���������� ��������� �����
              
       // ���������� ��������
       tg = GetTan();       
      }
     
     
    }
    return(rates_total);
  }
