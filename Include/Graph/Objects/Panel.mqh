//+------------------------------------------------------------------+
//|                                                        Panel.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Button.mqh"   // ���������� ������ "������"
#include "Input.mqh"    // ���������� ������ "���� �����"
#include "Label.mqh"    // ���������� ������ "��������� ����"
#include "List.mqh"     // ���������� ������ "������"

 //������������ ����� �������� �� ������ 
 enum PANEL_ELEMENTS
  { 
   PE_BUTTON = 0, //������
   PE_INPUT,      //���� �����
   PE_LABEL,      //�����
   PE_LIST        //������
  };

//+------------------------------------------------------------------+
//| ����� ������                                                     |
//+------------------------------------------------------------------+

class Panel
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
  //---- ���������� ��� �������� ���������� �������� ���������� ������
  string           _object_name[];    // ������ ���� ��������� ��������
  uint             _n_objects;        // ���������� �������� 
  bool             _show_panel;       // ���� ����������� ������ �� �������. true - ������ ����������, false - ������ ������ 
 private:
  // ��������� ������ ������
  void DrawPanel (bool show_panel);   // ��������� �����, ������������� ��� ���������� ������ � �������
 public:
  //������ set
  
  Panel(string name,
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
  _z_order(z_order),
  _n_objects(0),
  _show_panel(true)
  {
   bool objectCreated;
   //�������� ������������ ����� �������
   if (ObjectFind(ChartID(),_name) < 0 )  
   { 
   
   objectCreated = ObjectCreate(_chart_id,_name,OBJ_EDIT,_sub_window,0,0); //�������� ������� ������

   if(objectCreated)  //���� ����������� ������ ������� ������
     {
      ObjectSetInteger(_chart_id, _name,OBJPROP_CORNER,_corner);                  // ��������� ���� �������
    //  ObjectSetInteger(_chart_id, _name,OBJPROP_FONTSIZE,_style.font_size);     // ��������� ������� ������
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,_x);                    // ��������� ���������� X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,_y);                    // ��������� ���������� Y
      ObjectSetInteger(_chart_id, _name,OBJPROP_XSIZE,_width);                    // ��������� ������
      ObjectSetInteger(_chart_id, _name,OBJPROP_YSIZE,15);                        // ��������� ������ �����         
      ObjectSetInteger(_chart_id, _name,OBJPROP_SELECTABLE,false);                // ������ �������� ������, ���� FALSE
      ObjectSetInteger(_chart_id, _name,OBJPROP_ZORDER,_z_order);                 // ��������� �������
      ObjectSetString (_chart_id, _name,OBJPROP_TOOLTIP,"\n");                    // ��� ����������� ���������, ���� "\n"
        
     }
   objectCreated = ObjectCreate(_chart_id,_name,OBJ_EDIT,_sub_window,0,0); //�������� ������� ������

   if(objectCreated)  //���� ����������� ������ ������� ������
     {
      ObjectSetInteger(_chart_id, _name,OBJPROP_CORNER,_corner);                  // ��������� ���� �������
    //  ObjectSetInteger(_chart_id, _name,OBJPROP_FONTSIZE,_style.font_size);     // ��������� ������� ������
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,_x);                    // ��������� ���������� X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,_y);                    // ��������� ���������� Y
      ObjectSetInteger(_chart_id, _name,OBJPROP_XSIZE,_width);                    // ��������� ������
      ObjectSetInteger(_chart_id, _name,OBJPROP_YSIZE,_height);                   // ��������� ������ �����         
      ObjectSetInteger(_chart_id, _name,OBJPROP_SELECTABLE,false);                // ������ �������� ������, ���� FALSE
      ObjectSetInteger(_chart_id, _name,OBJPROP_ZORDER,_z_order);                 // ��������� �������
      ObjectSetString (_chart_id, _name,OBJPROP_TOOLTIP,"\n");                    // ��� ����������� ���������, ���� "\n"
      ObjectSetInteger(_chart_id, _name,OBJPROP_BGCOLOR,clrSilver);               // ���� ������� ����  
     }     
   }
  };  //����������� ������ ������
 ~Panel()   
  {
   int  sub_window=0;      // ������������ ����� �������, � ������� ��������� ������
   bool res       =false;  // ��������� ����� ������� ������� ������
   // �������� �� ���� �������� �� ������ � ������� ��
   for (int index=0;index<ArraySize(_object_name);index++)
    {
     sub_window=ObjectFind(ChartID(),_object_name[index]);
     if(sub_window>=0) 
       {
        res=ObjectDelete(ChartID(),_object_name[index]); // ...������ ���
        if(!res)
         Print("������ ��� �������� �������: ",_object_name[index]);
       }     
    }
   sub_window=ObjectFind(ChartID(),_name);
   if(sub_window>=0) 
     {
      res=ObjectDelete(ChartID(),_name); // ...������ ���
      if(!res)
         Print("������ ��� �������� �������: ",_name);
     }
  }; //���������� ������
  
//+-------------------------------------------------------------------+
//| ��������� ������ ������ ������                                    |
//+-------------------------------------------------------------------+

 //----  �������� �������� ������
 void HidePanel ();
 //----  ���������� �������� ������
 void ShowPanel (); 
 //----  ������� ������� 
 void AddElement (PANEL_ELEMENTS elem_type, string elem_name,string caption,uint x,uint y,uint w,uint h);
 //---   ���������� ������ �� ���������� x, y
 void MoveTo(int x,int y);
 //---   �������� �� ������ ��� ���
 bool IsPanelShown(){ return (_show_panel); };
};

//�������� ������� ������ Panel

//+-------------------------------------------------------------------+
//| ��������� ������ ������ ������                                    |
//+-------------------------------------------------------------------+

 void Panel::DrawPanel(bool show_panel)
  {
   int index;
   _show_panel = !show_panel;
   // ��������� ��������� ������
   ObjectSetInteger(_chart_id, _name,OBJPROP_HIDDEN,show_panel);
    for (index=0;index<_n_objects;index++)
       { 
        // ��������� ��������� ��������� ������
        ObjectSetInteger(_chart_id,_object_name[index],OBJPROP_HIDDEN,show_panel);  
       }
  }

//+-------------------------------------------------------------------+
//| ��������� ������ ������ ������                                    |
//+-------------------------------------------------------------------+

 void Panel::HidePanel(void)
  //�������� �������� ������
  {
   DrawPanel(true);
  }
  
 void Panel::ShowPanel(void)
  //���������� �������� ������
  {
   DrawPanel(false);
  }

 void Panel::AddElement(PANEL_ELEMENTS elem_type,string elem_name,string caption,uint x,uint y,uint w,uint h)
  //��������� ������� � �������� ������
  {
   //������������ ����� �������, � ������� ��������� ������
   int  sub_win=0;      
   //������� ���������� ��� ������ ������
   string new_name = _name + "_" + elem_name;
   //�������� �� ������������� ������� � ����� �� ������
   sub_win = ObjectFind(_chart_id,new_name);
   //���� ������ � ����� ������ �� ����������
   if (sub_win < 0)
    {
     //��������� ��� ���������� ������� � ������ ����
     _n_objects++; 
     ArrayResize(_object_name, _n_objects,0);
     _object_name[_n_objects-1] = new_name;
     //�������� �������� �� ����
     switch (elem_type)
      {
       //������ "������"
       case PE_BUTTON:
       new Button(new_name,caption,x+_x,y+_y,w,h,_chart_id,_sub_window,_corner,_z_order);
       break;
       //������ "���� �����"
       case PE_INPUT:
       new Input(new_name,caption,x+_x,y+_y,w,h,_chart_id,_sub_window,_corner,_z_order);
       break;
       //������ "�����"
       case PE_LABEL:
       new Label(new_name,caption,x+_x,y+_y,w,h,_chart_id,_sub_window,_corner,_z_order);
       break;              
      }
    }
  }
  
  void Panel::MoveTo(int x,int y)
  //���������� ������ � ��������� �� ���������� x, y
   {
    //������ ��� �����
    uint index;
    // �������� ���������  
    int x_diff,y_diff;
    // ������� ���������� �������
    int x_now,y_now;
    //���� ���������� ������������� ��������
    if (x>=0&&y>=0)
     {
      //��������� �������� ���������
      x_diff = x-ObjectGetInteger(_chart_id,_name,OBJPROP_XDISTANCE);
      y_diff = y-ObjectGetInteger(_chart_id,_name,OBJPROP_YDISTANCE);
      //���������� ������ �� ����� ����������
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,x);  // ��������� ���������� X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,y);  // ��������� ���������� Y
      //��������� �� ���� ��������� ������� ���� �������� 
      for (index=0;index<_n_objects;index++)
       {
        //�������� ������� ���������� ��������
        x_now = ObjectGetInteger(_chart_id,_object_name[index],OBJPROP_XDISTANCE);
        y_now = ObjectGetInteger(_chart_id,_object_name[index],OBJPROP_YDISTANCE);        
        //� ���������� ��� ������� �� �������� ���������� � ����������� �� ����� ������������
        ObjectSetInteger(_chart_id,_object_name[index],OBJPROP_XDISTANCE,x_now+x_diff);
        ObjectSetInteger(_chart_id,_object_name[index],OBJPROP_YDISTANCE,y_now+y_diff);        
       }
     }
   }