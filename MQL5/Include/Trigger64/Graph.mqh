//+------------------------------------------------------------------+
//|                                                        Graph.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <StringUtilities.mqh>
#include "TestFunc.mqh"
#include "PosConst.mqh"
#include "PositionSys.mqh"
//����������� ����������

//

class GraphModule  //����� ������������ ������
 {
  private:

  public:
  void CreateEdit(long             chart_id,         // id �������
                int              sub_window,       // ����� ���� (�������)
                string           name,             // ��� �������
                string           text,             // ������������ �����
                ENUM_BASE_CORNER corner,           // ���� �������
                string           font_name,        // �����
                int              font_size,        // ������ ������
                color            font_color,       // ���� ������
                int              x_size,           // ������
                int              y_size,           // ������
                int              x_distance,       // ���������� �� ��� X
                int              y_distance,       // ���������� �� ��� Y
                long             z_order,          // ���������
                color            background_color, // ���� ����
                bool             read_only);        // ���� "������ ��� ������"
   void CreateLabel(long               chart_id,   // id �������
                 int                sub_window, // ����� ���� (�������)
                 string             name,       // ��� �������
                 string             text,       // ������������ �����
                 ENUM_ANCHOR_POINT  anchor,     // ����� ��������
                 ENUM_BASE_CORNER   corner,     // ���� �������
                 string             font_name,  // �����
                 int                font_size,  // ������ ������
                 color              font_color, // ���� ������
                 int                x_distance, // ���������� �� ��� X
                 int                y_distance, // ���������� �� ��� Y
                 long               z_order);    // ���������  
   public:                            
   void DeleteObjectByName(string name); //������� ������   
   void SetInfoPanel(PositionSys * my_pos);    
   void DeleteInfoPanel();     
   GraphModule();  //����������� ������
  ~GraphModule();  //���������� ������        
 };

void GraphModule::CreateEdit(long             chart_id,         // id �������
                int              sub_window,       // ����� ���� (�������)
                string           name,             // ��� �������
                string           text,             // ������������ �����
                ENUM_BASE_CORNER corner,           // ���� �������
                string           font_name,        // �����
                int              font_size,        // ������ ������
                color            font_color,       // ���� ������
                int              x_size,           // ������
                int              y_size,           // ������
                int              x_distance,       // ���������� �� ��� X
                int              y_distance,       // ���������� �� ��� Y
                long             z_order,          // ���������
                color            background_color, // ���� ����
                bool             read_only)        // ���� "������ ��� ������"
  {
// ���� ������ �������� �������, ��...
   if(ObjectCreate(chart_id,name,OBJ_EDIT,sub_window,0,0))
     {
      // ...��������� ��� ��������
      ObjectSetString (chart_id,name,OBJPROP_TEXT,text);                 // ������������ �����
      ObjectSetInteger(chart_id,name,OBJPROP_CORNER,corner);            // ��������� ���� �������
      ObjectSetString (chart_id,name,OBJPROP_FONT,font_name);            // ��������� ������
      ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,font_size);       // ��������� ������� ������
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,font_color);         // ���� ������
      ObjectSetInteger(chart_id,name,OBJPROP_BGCOLOR,background_color); // ���� ����
      ObjectSetInteger(chart_id,name,OBJPROP_XSIZE,x_size);             // ������
      ObjectSetInteger(chart_id,name,OBJPROP_YSIZE,y_size);             // ������
      ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,x_distance);     // ��������� ���������� X
      ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,y_distance);     // ��������� ���������� Y
      ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,false);         // ������ �������� ������, ���� FALSE
      ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,z_order);           // ��������� �������
      ObjectSetInteger(chart_id,name,OBJPROP_READONLY,read_only);       // ������ ��� ������
      ObjectSetInteger(chart_id,name,OBJPROP_ALIGN,ALIGN_LEFT);         // ������������ �� ������ ����
      ObjectSetString (chart_id,name,OBJPROP_TOOLTIP,"\n");              // ��� ����������� ���������, ���� "\n"
     }                 
  }
//+------------------------------------------------------------------+
//| ������� ������ Label                                             |
//+------------------------------------------------------------------+
void GraphModule::CreateLabel(long               chart_id,   // id �������
                 int                sub_window, // ����� ���� (�������)
                 string             name,       // ��� �������
                 string             text,       // ������������ �����
                 ENUM_ANCHOR_POINT  anchor,     // ����� ��������
                 ENUM_BASE_CORNER   corner,     // ���� �������
                 string             font_name,  // �����
                 int                font_size,  // ������ ������
                 color              font_color, // ���� ������
                 int                x_distance, // ���������� �� ��� X
                 int                y_distance, // ���������� �� ��� Y
                 long               z_order)    // ���������
  {
// ���� ������ �������� �������, ��...
   if(ObjectCreate(chart_id,name,OBJ_LABEL,sub_window,0,0))
     {
      // ...��������� ��� ��������
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);              // ������������ �����
      ObjectSetString(chart_id,name,OBJPROP_FONT,font_name);         // ��������� ������
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,font_color);      // ��������� ����� ������
      ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,anchor);         // ��������� ����� ��������
      ObjectSetInteger(chart_id,name,OBJPROP_CORNER,corner);         // ��������� ���� �������
      ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,font_size);    // ��������� ������� ������
      ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,x_distance);  // ��������� ���������� X
      ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,y_distance);  // ��������� ���������� Y
      ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,false);      // ������ �������� ������, ���� FALSE
      ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,z_order);        // ��������� �������
      ObjectSetString(chart_id,name,OBJPROP_TOOLTIP,"\n");           // ��� ����������� ���������, ���� "\n"
     }
  }
//+------------------------------------------------------------------+
//|   ������� ������ �� �����                                        |
//+------------------------------------------------------------------+
void GraphModule::DeleteObjectByName(string name)
  {
   int  sub_window=0;      // ������������ ����� �������, � ������� ��������� ������
   bool res       =false;  // ��������� ����� ������� ������� ������
//--- ����� ������ �� �����
   sub_window=ObjectFind(ChartID(),name);
//---
   if(sub_window>=0) // ���� ������,..
     {
      res=ObjectDelete(ChartID(),name); // ...������ ���
      //---
      // ���� ���� ������ ��� ��������, ������� �� ����
      if(!res)
         Print("������ ��� �������� �������: ("+IntegerToString(GetLastError())+"): "+ErrorDescription(GetLastError()));
     }
  }

void GraphModule::SetInfoPanel(PositionSys  * my_pos)  //������������� ����������� ������
  {
  
//--- ����� ������������ ��� ��������� �������
   if(IsVisualMode() || IsRealtime())
     {
      int               y_bg=18;             // ���������� �� ��� Y ��� ���� � ���������
      int               y_property=32;       // ���������� �� ��� Y ��� ������ ������� � �� ��������
      int               line_height=12;      // ������ ������
      //---
      int               font_size=8;         // ������ ������
      string            font_name="Calibri"; // �����
      color             font_color=clrWhite; // ���� ������
      //---
      ENUM_ANCHOR_POINT anchor=ANCHOR_RIGHT_UPPER; // ����� �������� � ������ ������� ����
      ENUM_BASE_CORNER  corner=CORNER_RIGHT_UPPER; // ������ ��������� � ������ ������� ���� �������
      //--- ���������� �� ��� X
      int               x_first_column=120;  // ������ ������� (�������� �������)
      int               x_second_column=10;  // ������ ������� (�������� �������)
      //--- ������������ � ������ ������������
      if(IsVisualMode())
        {
         y_bg=2;
         y_property=16;
        }
      //--- ������ � ������������ �� ��� Y ��� �������� ������� ������� � �� ��������
      int               y_prop_array[INFOPANEL_SIZE];
      //--- �������� ������ ������������ ��� ������ ������ �� �������������� ������
      for(int i=0; i<INFOPANEL_SIZE; i++)
        {
         if(i==0) y_prop_array[i]=y_property;
         else     y_prop_array[i]=y_property+line_height*i;
        }
      //--- ��� ����-������
      CreateEdit(0,0,"InfoPanelBackground","",corner,font_name,8,clrWhite,230,250,231,y_bg,0,C'15,15,15',true);
      //--- ��������� ����-������
      CreateEdit(0,0,"InfoPanelHeader","  POSITION  PROPERTIES",corner,font_name,8,clrWhite,230,14,231,y_bg,1,clrFireBrick,true);
      //--- ������ �������� ������� ������� � �� ��������
      for(int i=0; i<INFOPANEL_SIZE; i++)
        {
         //--- �������� ��������
         CreateLabel(0,0,pos_prop_names[i],pos_prop_texts[i],anchor,corner,font_name,font_size,font_color,x_first_column,y_prop_array[i],2);
         //--- �������� ��������
         CreateLabel(0,0,pos_prop_values[i],my_pos.GetPropertyValue(i),anchor,corner,font_name,font_size,font_color,x_second_column,y_prop_array[i],2);
        }
      //---
      ChartRedraw(); // ������������ ������
     }
  }
//+------------------------------------------------------------------+
//| ������� �������������� ������                                    |
//+------------------------------------------------------------------+
void GraphModule::DeleteInfoPanel()
  {
   DeleteObjectByName("InfoPanelBackground");   // ������� ��� ������
   DeleteObjectByName("InfoPanelHeader");       // ������� ��������� ������
//--- ������� �������� ������� � �� ��������
   for(int i=0; i<INFOPANEL_SIZE; i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      DeleteObjectByName(pos_prop_names[i]);    // ������� ��������
      DeleteObjectByName(pos_prop_values[i]);   // ������� ��������
     }
//---
   ChartRedraw(); // ������������ ������
  }
  
  GraphModule::GraphModule(void) //����������� ������
   {

   }
  
  GraphModule::~GraphModule(void) //���������� ������
   {
   
   } 