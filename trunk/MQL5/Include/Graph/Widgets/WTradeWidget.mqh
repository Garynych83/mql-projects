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
    string  _name;           // ��� �������
    string  _caption;        // ������������ �������
    uint    _x;              // ��������� x
    uint    _y;              // ��������� y
    uint    _sx;             // ������� ��������� ������� X
    uint    _sy;             // ������� ��������� ������� Y
    long    _chart_id;       // id ������� 
    int     _sub_window;     
    long    _z_order;
    bool    _widgetMove;     // ���� ����������� �������
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
      _widgetMove = false;
      // ������� ������ ������ �������
      _wTradeWidget = new Panel(name, caption, x, y, 200, 170, chart_id, sub_window, CORNER_LEFT_UPPER, z_order);
      // ������� ������ �������������� ����������
      _subPanel     = new Panel(name+"_subPanel","",x,y+140,200,130,chart_id,sub_window,CORNER_LEFT_UPPER,z_order);
      // ������� �������� �������� ������
      _wTradeWidget.AddElement (PE_BUTTON,"move","",0,0,200,10);                       // ������ ����������� ������
      _wTradeWidget.AddElement (PE_BUTTON,"close_widget","",190,2,8,8);                // ������ �������� ������
      _wTradeWidget.AddElement (PE_BUTTON,"inst_buy","BUY",0,10,100,50);               // ������ �� ����������� �������
      _wTradeWidget.AddElement (PE_BUTTON,"inst_sell","SELL",100,10,100,50);           // ������ �� ����������� �������   
      _wTradeWidget.AddElement (PE_INPUT, "volume","1.0",70,10,60,25);                 // ���      
      _wTradeWidget.AddElement (PE_BUTTON,"close","CLOSE",70,35,60,25);                // ������ �������� �������   
      _wTradeWidget.AddElement (PE_LABEL, "ask","0.0",0,40,70,20);                     // ����� ���� ASK
      _wTradeWidget.AddElement (PE_LABEL, "bid","0.0",130,40,70,20);                   // ����� ���� BID
      _wTradeWidget.AddElement (PE_LABEL, "sl_label","stop loss",0,60,100,30);         // ����� ���� �����
      _wTradeWidget.AddElement (PE_LABEL, "tp_label","take profit",100,60,100,30);     // ����� ���� �������           
      _wTradeWidget.AddElement (PE_INPUT, "stoploss","0.0",0,90,100,30);               // stop loss
      _wTradeWidget.AddElement (PE_INPUT, "takeprofit","0.0",100,90,100,30);           // take profit      
      _wTradeWidget.AddElement (PE_BUTTON,"edit_pos","�������� �������",0,120,200,20); // �������� �������\     
      // ������� �������� �������������� ������
      _subPanel.AddElement (PE_BUTTON,"buy_stop","BUY STOP",0,0,100,60);               // ������ BUY STOP
      _subPanel.AddElement (PE_BUTTON,"sell_stop","SELL STOP",100,0,100,60);           // ������ SELL STOP

      _subPanel.AddElement (PE_BUTTON,"buy_limit","BUY LIMIT",0,60,100,60);            // ������ BUY LIMIT
      _subPanel.AddElement (PE_BUTTON,"sell_limit","SELL LIMIT",100,60,100,60);        // ������ SELL LIMIT
      
      _subPanel.AddElement (PE_INPUT,"price_stop_limit","0.0",70,45,60,30);            // ���� ����� ����� � ����� ������
      
     // _subPanel.AddElement (PE_LIST,"list_orders","",0,120,100,50);                    // ������ �������
      _subPanel.AddElement (PE_BUTTON,"delete_orders","������� ��� ������",0,120,200,20); // ������ ��� ������          
     };
    // ���������� ������ �������
    ~WTradeWidget()
     {
      // ������� ������� �������
      delete _wTradeWidget;
      delete _subPanel;
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
    int stopLoss;
    int takeProfit;
    double sl,tp;
    double orderPrice;
    if (sparam == _name+"_inst_buy")
     {
     
       stopLoss = StringToInteger(ObjectGetString(_chart_id,_name+"_stoploss",OBJPROP_TEXT));
       if (stopLoss > 0)
        {
         if (stopLoss < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          stopLoss = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         sl = SymbolInfoDouble(_symbol,SYMBOL_ASK)-stopLoss*_Point;
        }
       else if (stopLoss == 0)
         sl = 0.0;
       else 
         Print("������ �������� ������ BUY. �� ��������� ����� ���� ����");
         
          
       takeProfit = StringToInteger(ObjectGetString(_chart_id,_name+"_takeprofit",OBJPROP_TEXT));
       if (takeProfit > 0)
        {
         if (takeProfit < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          takeProfit = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         tp = SymbolInfoDouble(_symbol,SYMBOL_ASK)+takeProfit*_Point;       
        }
       else if (takeProfit == 0)
        tp = 0.0;       
       else 
        Print("������ �������� ������ BUT. �� ��������� ����� ���� ������");
         
       _ctm.PositionOpen(_symbol,POSITION_TYPE_BUY,
                         StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                         SymbolInfoDouble(_symbol,SYMBOL_ASK),
                         sl,
                         tp,
                         "���������� ������"); 
     }
    if (sparam == _name+"_inst_sell")
     {
     
       stopLoss = StringToInteger(ObjectGetString(_chart_id,_name+"_stoploss",OBJPROP_TEXT));
       if (stopLoss > 0)
        {
         if (stopLoss < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          stopLoss = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         sl = SymbolInfoDouble(_symbol,SYMBOL_BID)+stopLoss*_Point;
        }
       else if (stopLoss == 0)
        sl = 0.0;
       else 
        Print("������ �������� ������� SELL. �� ��������� ����� ���� ����");
        
       takeProfit = StringToInteger(ObjectGetString(_chart_id,_name+"_takeprofit",OBJPROP_TEXT));
       if (takeProfit > 0)
        {
         if (takeProfit < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          takeProfit = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         tp = SymbolInfoDouble(_symbol,SYMBOL_BID)-takeProfit*_Point;       
        }
       else if (takeProfit == 0)
        tp = 0.0;
       else
        Print("������ �������� ������ SELL. �� ��������� ����� ���� ������");
        
       _ctm.PositionOpen(_symbol,POSITION_TYPE_SELL,
                         StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                         SymbolInfoDouble(_symbol,SYMBOL_BID),
                         sl,
                         tp,
                         "���������� ������");     
     }
    if (sparam == _name+"_close")
     {
      _ctm.PositionClose(_symbol);
     }
    if (sparam == _name+"_edit_pos")
     {
     
       stopLoss = StringToInteger(ObjectGetString(_chart_id,_name+"_stoploss",OBJPROP_TEXT));
       if (stopLoss > 0)
        {
         if (stopLoss < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          stopLoss = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         sl = SymbolInfoDouble(_symbol,SYMBOL_ASK)-stopLoss*_Point;
        }
       else if (stopLoss == 0)
         sl = 0.0;
       else 
         Print("������ �������� ������ BUY. �� ��������� ����� ���� ����");
         
          
       takeProfit = StringToInteger(ObjectGetString(_chart_id,_name+"_takeprofit",OBJPROP_TEXT));
       if (takeProfit > 0)
        {
         if (takeProfit < SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL) )
          takeProfit = SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL);
         tp = SymbolInfoDouble(_symbol,SYMBOL_ASK)+takeProfit*_Point;       
        }
       else if (takeProfit == 0)
        tp = 0.0;       
       else 
        Print("������ �������� ������ BUT. �� ��������� ����� ���� ������");
     
       _ctm.PositionModify(_Symbol,sl,tp);
              
     }
 
    if (sparam == _name+"_close_widget")
     {
      delete _subPanel;
      delete _wTradeWidget;
     }     
     
    if (sparam ==  _name+"_subPanel_buy_stop")
     {
      orderPrice = StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop_limit",OBJPROP_TEXT,0) ); 
      if ( GreatDoubles (orderPrice,SymbolInfoDouble(_symbol,SYMBOL_ASK)+SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point) )
        {
          _ctm.OrderOpen(_symbol,ORDER_TYPE_BUY_STOP,
                         StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                         orderPrice
                         );            
        }
      else
        Print("�� ������� ��������� Buy Stop");
     }

    if (sparam ==  _name+"_subPanel_sell_stop")
     {
      orderPrice = StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop_limit",OBJPROP_TEXT,0) );
      if (LessDoubles (orderPrice,SymbolInfoDouble(_symbol,SYMBOL_BID)-SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point) )
        {
         _ctm.OrderOpen(_symbol,ORDER_TYPE_SELL_STOP,
                        StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                        orderPrice
                       );            
        }
     }    
    if (sparam ==  _name+"_subPanel_buy_limit")
     {
      orderPrice = StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop_limit",OBJPROP_TEXT,0) );     
      if (LessDoubles (orderPrice,SymbolInfoDouble(_symbol,SYMBOL_BID)-SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point) )
        {      
         _ctm.OrderOpen(_symbol,ORDER_TYPE_BUY_LIMIT,
                        StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                        orderPrice
                       );            
        }
     }
    if (sparam ==  _name+"_subPanel_sell_limit")
     {
      orderPrice = StringToDouble(ObjectGetString(_chart_id,_name+"_subPanel_price_stop_limit",OBJPROP_TEXT,0) );     
      if (GreatDoubles (orderPrice,SymbolInfoDouble(_symbol,SYMBOL_ASK)+SymbolInfoInteger(_symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point) )
        {
         _ctm.OrderOpen(_symbol,ORDER_TYPE_SELL_LIMIT,
                        StringToDouble(ObjectGetString(_chart_id,_name+"_volume",OBJPROP_TEXT)),
                        orderPrice
                       );            
        }
     }        
    if (sparam == _name+"_delete_orders")
     {
      Print("������� ������");
      if ( !_ctm.DeleteAllOrders() )
        Print("�� ������� ������� ��� ���������� ������");
     }
   }
    
  