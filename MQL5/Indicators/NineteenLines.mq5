//+------------------------------------------------------------------+
//|                                                NineteenLines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#include <CExtremumCalc.mqh>
#include <Lib CisNewBar.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
struct ThreeExtr
{
 CExtremum one;
 CExtremum two;
 CExtremum three;
};

struct FourPrice
{
 CExtremum open;
 CExtremum close;
 CExtremum high;
 CExtremum low;
};

CExtremumCalc calcMN;
CExtremumCalc calcW1;
CExtremumCalc calcD1;
CExtremumCalc calcH4;
CExtremumCalc calcH1;

ThreeExtr estructMN;
ThreeExtr estructW1;
ThreeExtr estructD1;
ThreeExtr estructH4;
ThreeExtr estructH1;
FourPrice pstructH1;

CisNewBar barMN(Symbol(), PERIOD_MN1);
CisNewBar barW1(Symbol(), PERIOD_W1);
CisNewBar barD1(Symbol(), PERIOD_D1);
CisNewBar barH4(Symbol(), PERIOD_H4);
CisNewBar barH1(Symbol(), PERIOD_H1);
int OnInit()
{
//--- indicator buffers mapping
 HLineCreate(0, "L", 0, SymbolInfoDouble(Symbol(), SYMBOL_ASK), clrAqua);  
//---
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 HLineDelete(0, "L");
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
   if(barMN.isNewBar() > 0)
   {
   }
   if(barW1.isNewBar() > 0)
   {
   }
   if(barD1.isNewBar() > 0)
   {
   }
   if(barH4.isNewBar() > 0)
   {
   }
   if(barH1.isNewBar() > 0)
   {
   }
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