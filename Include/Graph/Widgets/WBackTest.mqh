//+------------------------------------------------------------------+
//|                                                    WBackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <Graph\Objects\Panel.mqh>  //���������� ���������� ������
//+------------------------------------------------------------------+
//| ������ ������� �������                                           |
//+------------------------------------------------------------------+
 class WBackTest 
  {
   private:
    // ���� �������
    Panel * _wBackTest;  // ������ ������ ��������
    bool    _showPanel; // ���� ����������� ������ �� �������. true - ������ ����������, false - ������ ������ 
   public:
    // ������ ����������� ������
    void HidePanel (){_wBackTest.HidePanel();};  // �������� ������
    void ShowPanel (){_wBackTest.ShowPanel();};  // ���������� ������ �� �������
    // ����������� ������ �������
    WBackTest (string name,
         string caption,
         uint x,
         uint y,
         uint width,
         uint height,
         long chart_id,
         int sub_window,
         ENUM_BASE_CORNER corner,
         long z_order)
     { 
      // ������� ������ ������ �������
      _wBackTest = new Panel(name, caption, x, y, width, height, chart_id, sub_window, corner, z_order);
      // ������� �������� ������
      _wBackTest.AddElement (PE_LABEL,"label",caption,x+13,y,width,height);              // ���� ������
      _wBackTest.AddElement (PE_BUTTON,"close_button","x",width-16,2,13,13);             // ������ �������� ������
      _wBackTest.AddElement (PE_BUTTON,"all_expt","��� ��������",0,30,width/2,20);       // ������
      _wBackTest.AddElement (PE_BUTTON,"cur_expt","���� �������",width/2,30,width/2,20); // ������      
     };
  };   