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

 input int epsilon = 25;          //����������� ��� ������ �����������
 input int depth = 50;            //������� ������ ���� �����������
 input int period_ATR = 100;      //������ ATR
 input double percent_ATR = 0.03; //������ ������ ������ � ��������� �� ATR 

 input bool  show_Extr_MN = true;
 input color color_Extr_MN = clrRed;
 input bool  show_Extr_W1 = false;
 input color color_Extr_W1 = clrOrange;
 input bool  show_Extr_D1 = false;
 input color color_Extr_D1 = clrYellow;
 input bool  show_Extr_H4 = false;
 input color color_Extr_H4 = clrBlue;
 input bool  show_Extr_H1 = false;
 input color color_Extr_H1 = clrAqua;
 input bool  show_Price_D1 = false;
 input color color_Price_D1 = clrDarkKhaki;

 CExtremumCalc calcMN(epsilon, depth);
 CExtremumCalc calcW1(epsilon, depth);
 CExtremumCalc calcD1(epsilon, depth);
 CExtremumCalc calcH4(epsilon, depth);
 CExtremumCalc calcH1(epsilon, depth);

 SExtremum estructMN[3];
 SExtremum estructW1[3];
 SExtremum estructD1[3];
 SExtremum estructH4[3];
 SExtremum estructH1[3];
 SExtremum pstructD1[4];
 CisNewBar barMN(Symbol(), PERIOD_MN1);
 CisNewBar barW1(Symbol(), PERIOD_W1);
 CisNewBar barD1(Symbol(), PERIOD_D1);
 CisNewBar barH4(Symbol(), PERIOD_H4);
 CisNewBar barH1(Symbol(), PERIOD_H1);

 string symbol = Symbol();
 int handle_ATR_MN;
 int handle_ATR_W1;
 int handle_ATR_D1;
 int handle_ATR_H4;
 int handle_ATR_H1;

 double buffer_ATR_MN [];
 double buffer_ATR_W1 [];
 double buffer_ATR_D1 [];
 double buffer_ATR_H4 [];
 double buffer_ATR_H1 [];
 
 bool first = true;
 //+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
 if(depth < 10) return(INIT_PARAMETERS_INCORRECT);
 handle_ATR_MN = iATR(symbol, PERIOD_MN1, period_ATR);
 handle_ATR_W1 = iATR(symbol,  PERIOD_W1, period_ATR);
 handle_ATR_D1 = iATR(symbol,  PERIOD_D1, period_ATR);
 handle_ATR_H4 = iATR(symbol,  PERIOD_H4, period_ATR);
 handle_ATR_H1 = iATR(symbol,  PERIOD_H1, period_ATR);
 SetInfoTabel();

//---
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 IndicatorRelease(handle_ATR_MN);
 IndicatorRelease(handle_ATR_W1);
 IndicatorRelease(handle_ATR_D1);
 IndicatorRelease(handle_ATR_H4);
 IndicatorRelease(handle_ATR_H1);
 ArrayFree(buffer_ATR_MN);
 ArrayFree(buffer_ATR_W1); 
 ArrayFree(buffer_ATR_D1); 
 ArrayFree(buffer_ATR_H4); 
 ArrayFree(buffer_ATR_H1); 
 if(show_Extr_MN)  DeleteExtrLines(PERIOD_MN1);
 if(show_Extr_W1)  DeleteExtrLines(PERIOD_W1);
 if(show_Extr_D1)  DeleteExtrLines(PERIOD_D1);
 if(show_Extr_H4)  DeleteExtrLines(PERIOD_H4);
 if(show_Extr_H1)  DeleteExtrLines(PERIOD_H1);
 if(show_Price_D1) DeletePriceLines(PERIOD_D1);
 DeleteInfoTabel();
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
   bool load = FillATRbuffer();
 
   if(load)
   {
    if(first)
    {
     if(show_Extr_MN)
     {
      FillThreeExtr(symbol, PERIOD_MN1, calcMN, estructMN, buffer_ATR_MN);
      CreateExtrLines(estructMN, PERIOD_MN1, color_Extr_MN);
     }
     if(show_Extr_W1)
     {
      FillThreeExtr(symbol, PERIOD_W1, calcW1, estructW1, buffer_ATR_W1);
      CreateExtrLines(estructW1,  PERIOD_W1, color_Extr_W1);
     }
     if(show_Extr_D1)
     {
      FillThreeExtr(symbol, PERIOD_D1, calcD1, estructD1, buffer_ATR_D1);
      CreateExtrLines(estructD1,  PERIOD_D1, color_Extr_D1); 
     }
     if(show_Price_D1)
     {
      FillFourPrice(symbol, PERIOD_D1, pstructD1, buffer_ATR_D1);
      CreatePriceLines(pstructD1, PERIOD_D1, color_Price_D1);
     }
     if(show_Extr_H4)
     {
      FillThreeExtr(symbol, PERIOD_H4, calcH4, estructH4, buffer_ATR_H4);
      CreateExtrLines(estructH4,  PERIOD_H4, color_Extr_H4);
     }
     if(show_Extr_H1)
     {
      FillThreeExtr(symbol, PERIOD_H1, calcH1, estructH1, buffer_ATR_H1);
      CreateExtrLines(estructH1,  PERIOD_H1, color_Extr_H1);
     }
     first = false;
    }//end first
    
    if(barMN.isNewBar() > 0)
    {
     if(show_Extr_MN)
     {
      FillThreeExtr(symbol, PERIOD_MN1, calcMN, estructMN, buffer_ATR_MN);
      MoveExtrLines(estructMN, PERIOD_MN1);
     }
    }
    if(barW1.isNewBar() > 0)
    {
     if(show_Extr_W1)
     {
      FillThreeExtr(symbol, PERIOD_W1, calcW1, estructW1, buffer_ATR_W1);
      MoveExtrLines(estructW1, PERIOD_W1);
     }
    }
    if(barD1.isNewBar() > 0)
    { 
     if(show_Extr_D1)
     {
      FillThreeExtr(symbol, PERIOD_D1, calcD1, estructD1, buffer_ATR_D1);
      MoveExtrLines(estructD1, PERIOD_D1);
     }
     if(show_Price_D1)
     {
      FillFourPrice(symbol, PERIOD_D1, pstructD1, buffer_ATR_D1);
      MovePriceLines(pstructD1, PERIOD_D1);
     }
    }
    if(barH4.isNewBar() > 0)
    {
     if(show_Extr_H4)
     {
      FillThreeExtr(symbol, PERIOD_H4, calcH4, estructH4, buffer_ATR_H4);
      MoveExtrLines(estructH4, PERIOD_H4);
     }
    }
    if(barH1.isNewBar() > 0)
    {
     if(show_Extr_H1)
     {
      FillThreeExtr(symbol, PERIOD_H1, calcH1, estructH1, buffer_ATR_H1);
      MoveExtrLines(estructH1, PERIOD_H1);
     }
    }
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
                 const int             width=1,           // ������� �����
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // ����� �����
                 const bool            back=true          // �� ������ �����
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

bool HLineMove(const long   chart_ID=0,   // ID �������
               const string name="HLine", // ��� �����
               double       price=0)      // ���� �����
{
//--- ���� ���� ����� �� ������, �� ���������� �� �� ������� ������� ���� Bid
 if(!price)
  price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- ������� �������� ������
 ResetLastError();
//--- ���������� �������������� �����
 if(!ObjectMove(chart_ID,name,0,0,price))
 {
  Print(__FUNCTION__, ": �� ������� ����������� �������������� �����! ��� ������ = ",GetLastError());
  return(false);
 }
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

void FillFourPrice(string symbol, ENUM_TIMEFRAMES tf, SExtremum &resArray[], double &buffer_ATR[])
{
 double  open_buf[1];
 double close_buf[1];
 double  high_buf[1];
 double   low_buf[1];
   
 CopyOpen (symbol, tf, 1, 1,  open_buf);
 CopyClose(symbol, tf, 1, 1, close_buf);
 CopyHigh (symbol, tf, 1, 1,  high_buf);
 CopyLow  (symbol, tf, 1, 1,   low_buf);
 
 resArray[0].price   =   open_buf[0];
 resArray[0].channel = (buffer_ATR[0]*percent_ATR)/2;
 resArray[1].price   =  close_buf[0];
 resArray[1].channel = (buffer_ATR[0]*percent_ATR)/2;
 resArray[2].price   =   high_buf[0];
 resArray[2].channel = (buffer_ATR[0]*percent_ATR)/2;
 resArray[3].price   =    low_buf[0];
 resArray[3].channel = (buffer_ATR[0]*percent_ATR)/2;
}

void CreatePriceLines(const SExtremum &fp[], ENUM_TIMEFRAMES tf, color clr)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"open"  , 0, fp[0].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"open+" , 0, fp[0].price+fp[0].channel, clr, 2);
 HLineCreate(0, name+"open-" , 0, fp[0].price-fp[0].channel, clr, 2); 
 HLineCreate(0, name+"close" , 0, fp[1].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"close+", 0, fp[1].price+fp[1].channel, clr, 2);
 HLineCreate(0, name+"close-", 0, fp[1].price-fp[1].channel, clr, 2);
 HLineCreate(0, name+"high"  , 0, fp[2].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"high+" , 0, fp[2].price+fp[2].channel, clr, 2);
 HLineCreate(0, name+"high-" , 0, fp[2].price-fp[2].channel, clr, 2);
 HLineCreate(0, name+"low"   , 0, fp[3].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"low+"  , 0, fp[3].price+fp[3].channel, clr, 2);
 HLineCreate(0, name+"low-"  , 0, fp[3].price-fp[3].channel, clr, 2);
}

void MovePriceLines(const SExtremum &fp[], ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineMove(0, name+"open"  , fp[0].price);
 HLineMove(0, name+"open+" , fp[0].price+fp[0].channel);
 HLineMove(0, name+"open-" , fp[0].price-fp[0].channel);
 HLineMove(0, name+"close" , fp[1].price);
 HLineMove(0, name+"close+", fp[1].price+fp[1].channel);
 HLineMove(0, name+"close-", fp[1].price-fp[1].channel); 
 HLineMove(0, name+"high"  , fp[2].price);
 HLineMove(0, name+"high+" , fp[2].price+fp[2].channel);
 HLineMove(0, name+"high-" , fp[2].price-fp[2].channel); 
 HLineMove(0, name+"low"   , fp[3].price);
 HLineMove(0, name+"low+"  , fp[3].price+fp[3].channel);
 HLineMove(0, name+"low-"  , fp[3].price-fp[3].channel);  
}

void DeletePriceLines(ENUM_TIMEFRAMES tf)
{
 string name = "price_" + EnumToString(tf) + "_";
 HLineDelete(0, name+"open");
 HLineDelete(0, name+"open+");
 HLineDelete(0, name+"open-");
 HLineDelete(0, name+"close");
 HLineDelete(0, name+"close+");
 HLineDelete(0, name+"close-");
 HLineDelete(0, name+"high");
 HLineDelete(0, name+"high+");
 HLineDelete(0, name+"high-");
 HLineDelete(0, name+"low");
 HLineDelete(0, name+"low+");
 HLineDelete(0, name+"low-");
}

void FillThreeExtr (string symbol, ENUM_TIMEFRAMES tf, CExtremumCalc &extrcalc, SExtremum &resArray[], double &buffer_ATR[])
{
 extrcalc.FillExtremumsArray(symbol, tf);
 if (extrcalc.NumberOfExtr() < 3)
 {
  Alert(__FUNCTION__, "�� ������� ���������� ��� ���������� �� ���������� ", EnumToString((ENUM_TIMEFRAMES)tf));
  return;
 }
  
 int count = 0;
 for(int i = 0; i < depth && count < 3; i++)
 {
  if(extrcalc.getExtr(i).price > 0)
  {
   resArray[count] = extrcalc.getExtr(i);
   resArray[count].channel = (buffer_ATR[i]*percent_ATR)/2;
   count++;
  }
 }
}

void CreateExtrLines(const SExtremum &te[], ENUM_TIMEFRAMES tf, color clr)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineCreate(0, name+"one"   , 0, te[0].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"one+"  , 0, te[0].price+te[0].channel, clr, 2);
 HLineCreate(0, name+"one-"  , 0, te[0].price-te[0].channel, clr, 2);
 HLineCreate(0, name+"two"   , 0, te[1].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"two+"  , 0, te[1].price+te[1].channel, clr, 2);
 HLineCreate(0, name+"two-"  , 0, te[1].price-te[1].channel, clr, 2);
 HLineCreate(0, name+"three" , 0, te[2].price              , clr, 1, STYLE_DASHDOT);
 HLineCreate(0, name+"three+", 0, te[2].price+te[2].channel, clr, 2);
 HLineCreate(0, name+"three-", 0, te[2].price-te[2].channel, clr, 2);
}

void MoveExtrLines(const SExtremum &te[], ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineMove(0, name+"one"   , te[0].price);
 HLineMove(0, name+"one+"  , te[0].price+te[0].channel);
 HLineMove(0, name+"one-"  , te[0].price-te[0].channel);
 HLineMove(0, name+"two"   , te[1].price);
 HLineMove(0, name+"two+"  , te[1].price+te[1].channel);
 HLineMove(0, name+"two-"  , te[1].price-te[1].channel);
 HLineMove(0, name+"three" , te[2].price);
 HLineMove(0, name+"three+", te[2].price+te[2].channel);
 HLineMove(0, name+"three-", te[2].price-te[2].channel);
}

void DeleteExtrLines(ENUM_TIMEFRAMES tf)
{
 string name = "extr_" + EnumToString(tf) + "_";
 HLineDelete(0, name+"one");
 HLineDelete(0, name+"one+");
 HLineDelete(0, name+"one-");
 HLineDelete(0, name+"two");
 HLineDelete(0, name+"two+");
 HLineDelete(0, name+"two-");
 HLineDelete(0, name+"three");
 HLineDelete(0, name+"three+");
 HLineDelete(0, name+"three-");
}

bool FillATRbuffer()
{
   if(handle_ATR_MN != INVALID_HANDLE && handle_ATR_W1 != INVALID_HANDLE && handle_ATR_D1 != INVALID_HANDLE &&
      handle_ATR_H4 != INVALID_HANDLE && handle_ATR_H1 != INVALID_HANDLE )
   {
    int copiedATR_MN = CopyBuffer(handle_ATR_MN, 0, 1, depth, buffer_ATR_MN);
    int copiedATR_W1 = CopyBuffer(handle_ATR_W1, 0, 1, depth, buffer_ATR_W1);
    int copiedATR_D1 = CopyBuffer(handle_ATR_D1, 0, 1, depth, buffer_ATR_D1);
    int copiedATR_H4 = CopyBuffer(handle_ATR_H4, 0, 1, depth, buffer_ATR_H4);
    int copiedATR_H1 = CopyBuffer(handle_ATR_H1, 0, 1, depth, buffer_ATR_H1); 
    
    if (copiedATR_MN != depth || copiedATR_W1 != depth || copiedATR_D1 != depth ||
        copiedATR_H4 != depth || copiedATR_H1 != depth) 
    {
     Print(__FUNCTION__, "�� ������� ��������� ����������� ������ ATR. Error = ", GetLastError());
     if(GetLastError() == 4401) 
      Print(__FUNCTION__, "��������� ��������� ����� ��� ���������� ������� �������.");
     return false;
    }
    return true;
   }
  return false;
}



//CREATE AND DELETE LABEL AND RECTLABEL

void SetInfoTabel()
{
 int X = 10;
 int Y = 10;
 RectLabelCreate(0, "Extr_Title", 0, X, Y, 130, 105, clrBlack, BORDER_FLAT, CORNER_LEFT_UPPER, clrWhite, STYLE_SOLID, 1, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_MN", 0, X+65, Y+15, CORNER_LEFT_UPPER, "EXTREMUM MONTH", "Arial Black", 8,  color_Extr_MN, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_W1", 0, X+65, Y+30, CORNER_LEFT_UPPER,  "EXTREMUM WEEK", "Arial Black", 8,  color_Extr_W1, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_D1", 0, X+65, Y+45, CORNER_LEFT_UPPER,   "EXTREMUM DAY", "Arial Black", 8,  color_Extr_D1, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_H4", 0, X+65, Y+60, CORNER_LEFT_UPPER, "EXTREMUM 4HOUR", "Arial Black", 8,  color_Extr_H4, ANCHOR_CENTER, false, false, false);
 LabelCreate(0,  "Extr_PERIOD_H1", 0, X+65, Y+75, CORNER_LEFT_UPPER, "EXTREMUM 1HOUR", "Arial Black", 8,  color_Extr_H1, ANCHOR_CENTER, false, false, false);
 LabelCreate(0, "Price_PERIOD_D1", 0, X+65, Y+90, CORNER_LEFT_UPPER,      "PRICE DAY", "Arial Black", 8, color_Price_D1, ANCHOR_CENTER, false, false, false);
 ChartRedraw();
}

void DeleteInfoTabel()
{
 RectLabelDelete(0, "Extr_Title");
 LabelDelete(0, "Extr_PERIOD_MN");
 LabelDelete(0, "Extr_PERIOD_W1");
 LabelDelete(0, "Extr_PERIOD_D1");
 LabelDelete(0, "Extr_PERIOD_H4");
 LabelDelete(0, "Extr_PERIOD_H1");
 LabelDelete(0, "Price_PERIOD_D1");
 ChartRedraw();
}
//+------------------------------------------------------------------+
//| ������� ������������� �����                                      |
//+------------------------------------------------------------------+
bool RectLabelCreate(const long             chart_ID=0,               // ID �������
                     const string           name="RectLabel",         // ��� �����
                     const int              sub_window=0,             // ����� �������
                     const int              x=0,                      // ���������� �� ��� X
                     const int              y=0,                      // ���������� �� ��� Y
                     const int              width=50,                 // ������
                     const int              height=18,                // ������
                     const color            back_clr=C'236,233,216',  // ���� ����
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // ��� �������
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // ���� ������� ��� ��������
                     const color            clr=clrRed,               // ���� ������� ������� (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // ����� ������� �������
                     const int              line_width=1,             // ������� ������� �������
                     const bool             back=false,               // �� ������ �����
                     const bool             selection=false,          // �������� ��� �����������
                     const bool             hidden=true)              // ����� � ������ ��������
  {
//--- ������� �������� ������
   ResetLastError();
//--- �������� ������������� �����
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": �� ������� ������� ������������� �����! ��� ������ = ",GetLastError());
      return(false);
     }
//--- ��������� ���������� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- ��������� ������� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- ��������� ���� ����
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- ��������� ��� �������
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border);
//--- ��������� ���� �������, ������������ �������� ����� ������������ ���������� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- ��������� ���� ������� ����� (� ������ Flat)
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- ��������� ����� ����� ������� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- ��������� ������� ������� �������
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- ��������� �� �������� (false) ��� ������ (true) �����
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- ������� (true) ��� �������� (false) ����� ����������� ����� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- ������ (true) ��� ��������� (false) ��� ������������ ������� � ������ ��������
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- �������� ����������
   return(true);
  }
//+------------------------------------------------------------------+
//| ������� ������������� �����                                      |
//+------------------------------------------------------------------+
bool RectLabelDelete(const long   chart_ID=0,       // ID �������
                     const string name="RectLabel") // ��� �����
  {
//--- ������� �������� ������
   ResetLastError();
//--- ������ �����
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": �� ������� ������� ������������� �����! ��� ������ = ",GetLastError());
      return(false);
     }
//--- �������� ����������
   return(true);
  }
//+------------------------------------------------------------------+
//| ������� ������������� �����                                      |
//+------------------------------------------------------------------+
bool LabelCreate(const long              chart_ID=0,               // ID �������
                 const string            name="Label",             // ��� �����
                 const int               sub_window=0,             // ����� �������
                 const int               x=0,                      // ���������� �� ��� X
                 const int               y=0,                      // ���������� �� ��� Y
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // ���� ������� ��� ��������
                 const string            text="Label",             // �����
                 const string            font="Arial",             // �����
                 const int               font_size=10,             // ������ ������
                 const color             clr=clrRed,               // ����
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // ������ ��������
                 const bool              back=false,               // �� ������ �����
                 const bool              selection=false,          // �������� ��� �����������
                 const bool              hidden=true)              // ����� � ������ ��������
  {
//--- ������� �������� ������
   ResetLastError();
//--- �������� ��������� �����
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": �� ������� ������� ��������� �����! ��� ������ = ",GetLastError());
      return(false);
     }
//--- ��������� ���������� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- ��������� ���� �������, ������������ �������� ����� ������������ ���������� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- ��������� �����
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- ��������� ����� ������
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- ��������� ������ ������
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- ��������� ������ ��������
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- ��������� ����
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- ��������� �� �������� (false) ��� ������ (true) �����
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- ������� (true) ��� �������� (false) ����� ����������� ����� �����
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- ������ (true) ��� ��������� (false) ��� ������������ ������� � ������ ��������
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- �������� ����������
   return(true);
  }

//+------------------------------------------------------------------+
//| ������� ��������� �����                                          |
//+------------------------------------------------------------------+
bool LabelDelete(const long   chart_ID=0,   // ID �������
                 const string name="Label") // ��� �����
  {
//--- ������� �������� ������
   ResetLastError();
//--- ������ �����
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": �� ������� ������� ��������� �����! ��� ������ = ",GetLastError());
      return(false);
     }
//--- �������� ����������
   return(true);
  }