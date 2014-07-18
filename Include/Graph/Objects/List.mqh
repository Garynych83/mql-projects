//+------------------------------------------------------------------+
//|                                                        Label.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//#include <Graph\Style.mqh>  //���������� ���������� ������
//+------------------------------------------------------------------+
//| ����� ������                                                     |
//+------------------------------------------------------------------+
class List
{
 private:
  string           _name;             // ��� �������
  uint             _x,_y;             // ���������� ������
  uint             _width,_height;    // ������ ������ � ������ ����� 
  short             _elem_height;     // ������ ��������
  string           _caption;          // ������� �� �����
  long             _chart_id;         // id �������
  int              _sub_window;       // ����� ���� (�������) 
  ENUM_BASE_CORNER _corner;           // ���� �������  
  long             _z_order;          // ���������   
  short            _n_elems;          // ���������� ��������� ������
  
 void CreateElem(string elem_name,string caption,uint y);   // ������� ������� ������
   
 public:
  //������ set
  List(string name,
         string caption,
         uint x,
         uint y,
         uint elem_height,
         long chart_id,
         int sub_window,
         ENUM_BASE_CORNER corner,
         long z_order
         ): 
  _name (name),
  _caption(caption), 
  _x(x),_y(y),
  _elem_height(elem_height),
  _chart_id(chart_id),
  _sub_window(sub_window),
  _corner(corner),
  _z_order(z_order),
  _n_elems(0)
  {
   bool objectCreated;
   //�������� ������������ ����� �������
   if (ObjectFind(ChartID(),_name) < 0 )  
   { 
    
   objectCreated = ObjectCreate(_chart_id,_name,OBJ_EDIT,_sub_window,0,0); //�������� ������� ������

   if(objectCreated)  //���� ����������� ������ ������� ������
     {
      ObjectSetInteger(_chart_id, _name,OBJPROP_CORNER,_corner);                  // ��������� ���� �������
      ObjectSetInteger(_chart_id, _name,OBJPROP_BGCOLOR,clrAliceBlue);
      ObjectSetString(_chart_id, _name,OBJPROP_TEXT,"");                          // �������   
      ObjectSetInteger(_chart_id, _name,OBJPROP_XDISTANCE,_x);                    // ��������� ���������� X
      ObjectSetInteger(_chart_id, _name,OBJPROP_YDISTANCE,_y);                    // ��������� ���������� Y
      ObjectSetInteger(_chart_id, _name,OBJPROP_XSIZE,_width);                    // ��������� ������
      ObjectSetInteger(_chart_id, _name,OBJPROP_YSIZE,_height);                   // ��������� ������                  
      ObjectSetInteger(_chart_id, _name,OBJPROP_SELECTABLE,false);                // ������ �������� ������, ���� FALSE
      ObjectSetInteger(_chart_id, _name,OBJPROP_ZORDER,_z_order);                 // ��������� �������
      ObjectSetString (_chart_id, _name,OBJPROP_TOOLTIP,"\n");                    // ��� ����������� ���������, ���� "\n"

        
     }
   }
  };  //����������� ������ ������
 ~List()   
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
  void AddToList(string caption,int value);  //��������� ������� Integer ������ 
  void AddToList(string caption,double value,short digits=8);  //��������� ������� Double ������ 
  void AddToList(string caption,string value);  //��������� ������� String ������ 
  void AddToList(string caption,datetime value,int flags=TIME_DATE|TIME_MINUTES);  //��������� ������� Datetime ������       
};

 void List::CreateElem(string elem_name,string caption,uint y)
 {
   bool objectCreated;
       
   objectCreated = ObjectCreate(_chart_id,elem_name,OBJ_LABEL,_sub_window,0,0); //�������� ������� ������
    
    if(objectCreated)  //���� ����������� ������ ������� ������
     {
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_CORNER,_corner);                  // ��������� ���� �������
      ObjectSetString (_chart_id, elem_name, OBJPROP_TEXT,caption);                    // �������   
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_XDISTANCE,_x);                    // ��������� ���������� X
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_YDISTANCE,y);                     // ��������� ���������� Y
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_XSIZE,_width);                    // ��������� ������
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_YSIZE,_height);                   // ��������� ������                  
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_SELECTABLE,false);                // ������ �������� ������, ���� FALSE
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_ZORDER,_z_order);                 // ��������� �������
      ObjectSetString (_chart_id, elem_name, OBJPROP_TOOLTIP,"\n");                    // ��� ����������� ���������, ���� "\n"
      ObjectSetInteger(_chart_id, elem_name, OBJPROP_COLOR,clrWhite);                // ���� ������ 
     }
 }

 void List::AddToList(string caption,int value)
  {
    AddToList(caption,IntegerToString(value));
  }
  
 void List::AddToList(string caption,double value,short digits=8)
  {
    AddToList(caption,DoubleToString(value,digits));
  }
  
 void List::AddToList(string caption,datetime value,int flags=TIME_DATE|TIME_MINUTES)
  { 
    AddToList(caption,TimeToString(value,flags));
  }
 void List::AddToList(string caption,string value)
  {
    string new_caption = caption+" : "+value;  //������ � �������� ������
    string new_name  = '*'+_name+'_'+IntegerToString(_n_elems);  //���������� ����� ���
    CreateElem(new_name,new_caption,_y+_n_elems*_elem_height);     //������� ����� ������� ������
    _n_elems++; //����������� ���������� ��������� ������ �� �������
  }