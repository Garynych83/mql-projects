//+------------------------------------------------------------------+
//|                                                       Button.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ����� ������                                                     |
//+------------------------------------------------------------------+

class Button
{
 private:
  string           _name;             // ��� �������
  uint             _x,_y;             // ���������� ������
  uint             _width,_height;    // ������ � ������ ������
  string           _caption;          // ������� �� ������
  long             _chart_id;         // id �������
  int              _sub_window;       // ����� ���� (�������) 
  ENUM_BASE_CORNER _corner;           // ���� �������  
  long             _z_order;          // ���������   
 public:
  //������ set
  Button(string name,
         string caption,
         uint x,
         uint y,
         uint width,
         uint height,
         long chart_id,
         int sub_window,
         ENUM_BASE_CORNER corner,
         long z_order
         ): 
  _name (name),
  _caption(caption), 
  _x(x),_y(y),
  _width(width),
  _height(height),
  _chart_id(chart_id),
  _sub_window(sub_window),
  _corner(corner),
  _z_order(z_order)
  {
   bool objectCreated;
   //�������� ������������ ����� �������
   if (ObjectFind(ChartID(),_name) < 0 )  
   { 
    
   objectCreated = ObjectCreate(_chart_id,_name,OBJ_BUTTON,_sub_window,0,0); //�������� ������� ������

   if(objectCreated)  //���� ����������� ������ ������� ������
     {

      ObjectSetInteger(_chart_id, _name,OBJPROP_CORNER,_corner);                  // ��������� ���� �������
      ObjectSetString(_chart_id,  _name,OBJPROP_TEXT,_caption);                   // ������� �� ������
      ObjectSetInteger(_chart_id, _name,OBJPROP_XSIZE,_width);                    // ������ ������
      ObjectSetInteger(_chart_id, _name,OBJPROP_YSIZE,_height);                   // ������ ������
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,_x);                    // ��������� ���������� X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,_y);                    // ��������� ���������� Y
      ObjectSetInteger(_chart_id, _name,OBJPROP_SELECTABLE,false);                // ������ �������� ������, ���� FALSE
      ObjectSetInteger(_chart_id, _name,OBJPROP_ZORDER,_z_order);                 // ��������� �������
      ObjectSetString (_chart_id, _name,OBJPROP_TOOLTIP,"\n");                    // ��� ����������� ���������, ���� "\n"
      ObjectSetInteger(_chart_id, _name,OBJPROP_BGCOLOR,clrSilver);               // ���� ������� ����
       
     }
   }
  };  //����������� ������ ������
 ~Button()   
  {
   int  sub_window=0;      // ������������ ����� �������, � ������� ��������� ������
   bool res       =false;  // ��������� ����� ������� ������� ������
   sub_window=ObjectFind(ChartID(),_name);
   if(sub_window>=0) 
     {
      res=ObjectDelete(ChartID(),_name); // ...������ ���
      if(!res)
         Print("������ ��� �������� �������: ",_name);
     }
  }; //���������� ������
};
