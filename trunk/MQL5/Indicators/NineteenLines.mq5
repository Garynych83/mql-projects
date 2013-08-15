//+------------------------------------------------------------------+
//|                                                NineteenLines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
//---
   return(INIT_SUCCEEDED);
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
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // ID �������
                 const string          name="HLine",      // ��� �����
                 const int             sub_window=0,      // ����� �������
                 double                price=0,           // ���� �����
                 const color           clr=clrRed,        // ���� �����
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // ����� �����
                 const int             width=1,           // ������� �����
                 const bool            back=false         // �� ������ �����
                )      
{
//--- ���� ���� �� ������, �� ��������� �� �� ������ ������� ���� Bid
 if(!price)
  price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- ������� �������� ������
 ResetLastError();
//--- �������� �������������� �����
 if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
 {
  Print(__FUNCTION__, ": �� ������� ������� �������������� �����! ��� ������ = ",GetLastError());
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
//--- �������� ����������
 return(true);
}

bool HLineDelete(const long   chart_ID=0,   // ID �������
                 const string name="HLine") // ��� �����
{
//--- ������� �������� ������
 ResetLastError();
//--- ������ �������������� �����
 if(!ObjectDelete(chart_ID,name))
 {
  Print(__FUNCTION__, ": �� ������� ������� �������������� �����! ��� ������ = ",GetLastError());
  return(false);
 }
//--- �������� ����������
 return(true);
}