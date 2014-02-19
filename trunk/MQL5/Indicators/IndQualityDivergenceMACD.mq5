//+------------------------------------------------------------------+
//|                                        QualityDivergenceMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//TODO �������� ����� �� OnDeinit
//     �������� �������� ���������!

#include <Lib CisNewBAr.mqh>
#include <divergenceMACD.mqh>

input int fast_ema_period = 12; // ������ ������� EMA MACD
input int slow_ema_period = 26; // ������ ��������� EMA MACD
input int signal_period = 9;    // ������ ���������� EMA MACD

int handleMACD;
CisNewBar bar;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 handleMACD = iMACD(NULL, Period(), fast_ema_period, slow_ema_period, signal_period, PRICE_CLOSE); 
 return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason)
{
 IndicatorRelease(handleMACD);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
 int direction = 0;
 PointDiv divergence_point = {0};
 if(bar.isNewBar() > 0)
 {
    direction = divergenceMACD(handleMACD, Symbol(), Period(), 0, null);
    if(direction != 0)
    {
     int rand_color = rand()%255;
     TrendCreate(0, TimeToString(TimeCurrent())+"_1", 0, divergence_point.extrMACD1,  divergence_point.valuePrice1, 
                                                         divergence_point.extrPrice2, divergence_point.valuePrice2,
                                                         rand_color);
     TrendCreate(0, TimeToString(TimeCurrent()+"_2"), 1, divergence_point.extrMACD1, divergence_point.valueMACD1, 
                                                         divergence_point.extrMACD2, divergence_point.valueMACD2,
                                                         rand_color);                                               
    }
 }
 return(rates_total);
}
//+------------------------------------------------------------------+
bool TrendCreate(const long            chart_ID=0,        // ID �������
                 const string          name="TrendLine",  // ��� �����
                 const int             sub_window=0,      // ����� �������
                 datetime              time1=0,           // ����� ������ �����
                 double                price1=0,          // ���� ������ �����
                 datetime              time2=0,           // ����� ������ �����
                 double                price2=0,          // ���� ������ �����
                 const color           clr=clrRed,        // ���� �����
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // ����� �����
                 const int             width=1,           // ������� �����
                 const bool            back=false,        // �� ������ �����
                 const bool            selection=true,    // �������� ��� �����������
                 const bool            ray_left=false,    // ����������� ����� �����
                 const bool            ray_right=false,   // ����������� ����� ������
                 const bool            hidden=true,       // ����� � ������ ��������
                 const long            z_order=0)         // ��������� �� ������� �����
  {
//--- ������� �������� ������
   ResetLastError();
//--- �������� ��������� ����� �� �������� �����������
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2))
     {
      Print(__FUNCTION__,
            ": �� ������� ������� ����� ������! ��� ������ = ",GetLastError());
      return(false);
     }
//--- ��������� ���� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- ��������� ����� ����������� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- ��������� ������� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- ��������� �� �������� (false) ��� ������ (true) �����
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- ������� (true) ��� �������� (false) ����� ����������� ����� �����
//--- ��� �������� ������������ ������� �������� ObjectCreate, �� ��������� ������
//--- ������ �������� � ����������. ������ �� ����� ������ �������� selection
//--- �� ��������� ����� true, ��� ��������� �������� � ���������� ���� ������
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- ������� (true) ��� �������� (false) ����� ����������� ����������� ����� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left);
//--- ������� (true) ��� �������� (false) ����� ����������� ����������� ����� ������
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
//--- ������ (true) ��� ��������� (false) ��� ������������ ������� � ������ ��������
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- ��������� ��������� �� ��������� ������� ������� ���� �� �������
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- �������� ����������
   return(true);
  }

//+------------------------------------------------------------------+
//| ������� ������� ����� ������ � �������.                          |
//+------------------------------------------------------------------+
bool TrendDelete(const long   chart_ID=0,       // ID �������
                 const string name="TrendLine") // ��� �����
  {
//--- ������� �������� ������
   ResetLastError();
//--- ������ ����� ������
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": �� ������� ������� ����� ������! ��� ������ = ",GetLastError());
      return(false);
     }
//--- �������� ����������
   return(true);
  }
