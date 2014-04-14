//+------------------------------------------------------------------+
//|                                                        HLine.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

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
