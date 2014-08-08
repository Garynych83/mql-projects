//+------------------------------------------------------------------+
//|                                                    WBackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <Graph\Objects\Panel.mqh>  //���������� ���������� ������
#include <TradeManager\TMPCTM.mqh>  //���������� �������� ���������� 
//+------------------------------------------------------------------+
//| �������� ������                                                  |
//+------------------------------------------------------------------+
  
 class WTradeWidget 
  {
   private:
    // ��������� ����
    string  _symbol;         // ������
    CTMTradeFunctions *_ctm; // ������ ������ �������� ����������
    // ���� �������
    Panel * _wTradeWidget;   // ������ ��������� �������
    Panel * _subPanel;       // ������ �������������� ������������
    bool    _showPanel;      // ���� ����������� ������ �� �������. true - ������ ����������, false - ������ ������ 
    string  _name;
    string  _caption;
    uint    _x;
    uint    _y;
    long    _chart_id;
    int     _sub_window;
    long    _z_order;
   public:
    // ������ ����������� ������
    void   HidePanel (){_wTradeWidget.HidePanel();};  // �������� ������
    void   ShowPanel (){_wTradeWidget.ShowPanel();};  // ���������� ������ �� �������
    void   OnTick();                                  // ��� ���������� ������ �� ������
    void   Action(string sparam);                     // �������� ������
    
    // ����������� ������ �������
    WTradeWidget (
         string symbol,
         string name,
         string caption,
         uint x,
         uint y,
         long chart_id,
         int sub_window,
         long z_order)
     { 
      // �������� ������� ������ ������ CTMTradeFunctions
      _ctm = new CTMTradeFunctions();
      // ��������� ��������� ���� ������
      _symbol = symbol;
      _name = name;
      _caption = caption;
      _x = x;
      _y = y;
      _chart_id = chart_id;
      _sub_window = sub_window;
      _z_order = z_order;
      // ������� ������ ������ �������
      _wTradeWidget = new Panel(name, caption, x, y, 200, 70, chart_id, sub_window, CORNER_LEFT_UPPER, z_order);
      // ������� ������ �������������� ����������
      _subPanel     = new Panel(name+"_subPanel","",x,y+70,200,200,chart_id,sub_window,CORNER_LEFT_UPPER,z_order);
      // ������� �������� �������� ������
      _wTradeWidget.AddElement (PE_BUTTON,"inst_buy","BUY",0,0,100,50);           // ������ �� ����������� �������
      _wTradeWidget.AddElement (PE_BUTTON,"inst_sell","SELL",100,0,100,50);       // ������ �� ����������� �������   
      _wTradeWidget.AddElement (PE_INPUT, "volume","1.0",70,0,60,25);             // ���      
      _wTradeWidget.AddElement (PE_BUTTON,"close","CLOSE",70,25,60,25);           // ������ �������� �������   
      _wTradeWidget.AddElement (PE_LABEL,"ask","0.0",0,30,70,20);                 // ����� ���� ASK
      _wTradeWidget.AddElement (PE_LABEL,"bid","0.0",130,30,70,20);               // ����� ���� BID
      _wTradeWidget.AddElement (PE_INPUT,"stoploss","0.0",0,50,100,30);           // stop loss
      _wTradeWidget.AddElement (PE_INPUT,"takeprofit","0.0",100,50,100,30);           // take profit      
      _wTradeWidget.AddElement (PE_BUTTON,"showall","�������������",0,80,200,20); // ������ �������������� ������������      
      // ������� �������� �������������� ������
      _subPanel.AddElement (PE_BUTTON,"buy_stop","BUY STOP",0,0,100,60);          // ������ BUY STOP
      _subPanel.AddElement (PE_BUTTON,"sell_stop","SELL STOP",100,0,100,60);      // ������ SELL STOP
      _subPanel.AddElement (PE_INPUT,"price_stop","0.0",70,0,60,25);              // ���� ����� �����

      _subPanel.AddElement (PE_BUTTON,"buy_limit","BUY LIMIT",0,60,100,60);       // ������ BUY LIMIT
      _subPanel.AddElement (PE_BUTTON,"sell_limit","SELL LIMIT",100,60,100,60);   // ������ SELL LIMIT
      _subPanel.AddElement (PE_INPUT,"price_limit","0.0",70,60,60,25);            // ���� ����� �����      
     };
  };   
  
  // ��� ���������� ������ �� ������
  void WTradeWidget::OnTick(void)
   {
    ObjectSetString(_chart_id,_name+"_"+"ask",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_ASK),5) );
    ObjectSetString(_chart_id,_name+"_"+"bid",OBJPROP_TEXT,DoubleToString(SymbolInfoDouble(_Symbol,SYMBOL_BID),5) );    
   }
   
  // ����� �������� ������
  void WTradeWidget::Action(string sparam)
   {
    if (sparam == _name+"_inst_buy")
     {
       _ctm.PositionOpen(_symbol,POSITION_TYPE_BUY,
                         StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                         SymbolInfoDouble(_symbol,SYMBOL_ASK),
                         StringToDouble(ObjectGetString(_chart_id,_name+"_stoploss",OBJPROP_TEXT)),
                         StringToDouble(ObjectGetString(_chart_id,_name+"_takeprofit",OBJPROP_TEXT)),
                         "���������� ������"); 
     }
    if (sparam == _name+"_inst_sell")
     {
       _ctm.PositionOpen(_symbol,POSITION_TYPE_SELL,
                         StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                         SymbolInfoDouble(_symbol,SYMBOL_BID),
                         StringToDouble(ObjectGetString(_chart_id,_name+"_stoploss",OBJPROP_TEXT)),
                         StringToDouble(ObjectGetString(_chart_id,_name+"_takeprofit",OBJPROP_TEXT)),
                         "���������� ������");     
     }
    if (sparam == _name+"_close")
     {
      _ctm.PositionClose(_symbol);
     }
    if (sparam == _name+"_showall")
     {
     if (_subPanel.IsPanelShown())
       _subPanel.HidePanel();
     else
       _subPanel.ShowPanel();
     }
    if (sparam ==  _name+"_subPanel_buy_stop")
     {
      _ctm.OrderOpen(_symbol,ORDER_TYPE_BUY_STOP,
                     StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                     StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop",OBJPROP_TEXT,0))
                      );            
     }
    if (sparam ==  _name+"_subPanel_sell_stop")
     {
      _ctm.OrderOpen(_symbol,ORDER_TYPE_SELL_STOP,
                     StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                     StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop",OBJPROP_TEXT,0))
                      );            
     }    
    if (sparam ==  _name+"_subPanel_buy_limit")
     {
      _ctm.OrderOpen(_symbol,ORDER_TYPE_BUY_LIMIT,
                     StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                     StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_limit",OBJPROP_TEXT,0))
                      );            
     }
    if (sparam ==  _name+"_subPanel_sell_limit")
     {
      _ctm.OrderOpen(_symbol,ORDER_TYPE_SELL_LIMIT,
                     StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                     StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_limit",OBJPROP_TEXT,0))
                      );            
     }        
   }
    
  