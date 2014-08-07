//+------------------------------------------------------------------+
//|                                              ExpertWithPanel.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Graph\Objects\Panel.mqh>   // ����� ������
#include <TradeManager\TMPCTM.mqh>   // �������� ����������

Panel * panel;           // ������ ������
CTMTradeFunctions * ctm; // ������ �������� ����������

int OnInit()
  {
   panel = new Panel("panel","panel",1,1,200,400,0,0,CORNER_LEFT_UPPER,0);
   panel.AddElement (PE_BUTTON,"inst_buy","BUY",30,0,50,15);                       // ������ �� ����������� �������
   panel.AddElement (PE_BUTTON,"inst_sell","SELL",30,25,50,15);                    // ������ �� ����������� �������
   panel.AddElement (PE_BUTTON,"buy_stop","BUY STOP",30,50,150,15);                // ������ �� buy stop
   panel.AddElement (PE_BUTTON,"sell_stop","SELL STOP",30,75,150,15);              // ������ �� sell stop
   panel.AddElement (PE_BUTTON,"buy_limit","BUY LIMIT",30,100,150,15);             // ������ �� buy limit
   panel.AddElement (PE_BUTTON,"sell_limit","SELL LIMIT",30,125,150,15);           // ������ �� sell limit
   panel.AddElement (PE_LABEL, "label_price","���� �����������",30,150,150,15);    
   panel.AddElement (PE_INPUT, "price","",30,175,150,15);                          // ���� ��� ������������
   
   panel.AddElement (PE_LABEL, "new_stoploss_label","����� ���� ����",30,200,150,15);
   panel.AddElement (PE_INPUT, "new_stoploss","",30,225,150,15);                   // ����� �������� ���� �����    
   
   panel.AddElement (PE_LABEL, "new_takeprofit_label","����� ���� ������",30,250,150,15);
   panel.AddElement (PE_INPUT, "new_takeprofit","",30,275,150,15);                 // ����� �������� ���� �������     
   
   panel.AddElement (PE_LABEL, "new_volume_label","����� �����",30,300,150,15);
   panel.AddElement (PE_INPUT, "new_volume","",30,325,150,15);                     // ����� �����
   
   panel.AddElement (PE_BUTTON,"close_position","������� �������",30,350,150,15);  // �������� �������  
         
   panel.AddElement (PE_BUTTON,"delete_order","������� ����. �����",30,375,150,15);  // ������� ��������� �����  
   
   panel.AddElement (PE_BUTTON,"change_sltp","�������� ���� � ����",30,400,150,15);  // �������� ���� ���� � ���� ������  
   
   panel.AddElement (PE_BUTTON,"change_volume","�������� �����",30,425,150,15);  // �������� �����     
   
   ctm = new CTMTradeFunctions();
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete panel;
   delete ctm;
  }

void OnTick()
  {

  }
  
// ����� ��������� �������  
void OnChartEvent(const int id,
                const long &lparam,
                const double &dparam,
                const string &sparam)
  { 
   // ���� ������ ������
   if(id==CHARTEVENT_OBJECT_CLICK)
    {
     // ��������� ���� ������� ������

       if (sparam == "panel_inst_buy")     // ������ ����������� �������
        {
         ctm.PositionOpen(_Symbol,POSITION_TYPE_BUY,1.0,SymbolInfoDouble(_Symbol,SYMBOL_ASK),
          0.0,0.0,"���������� ������");     
         Print("BUY");
        }
       if (sparam == "panel_inst_sell")     // ������ ����������� �������
        {
         ctm.PositionOpen(_Symbol,POSITION_TYPE_SELL,1.0,SymbolInfoDouble(_Symbol,SYMBOL_BID),
          0.0,0.0,"���������� �������");     
         Print("SELL");
        }
       if (sparam == "panel_buy_stop")
        {
         ctm.OrderOpen(_Symbol,ORDER_TYPE_BUY_STOP,1.0, StringToDouble(ObjectGetString(0,"panel_price",OBJPROP_TEXT,0)) );
         //Print("�������� � = ",ObjectGetString(0,"panel_price",OBJPROP_TEXT,0) );
        }
       if (sparam == "panel_sell_stop")
        {
         ctm.OrderOpen(_Symbol,ORDER_TYPE_SELL_STOP,1.0, StringToDouble(ObjectGetString(0,"panel_price",OBJPROP_TEXT,0)) );
         //Print("�������� � = ",ObjectGetString(0,"panel_price",OBJPROP_TEXT,0) );
        }
       if (sparam == "panel_buy_limit")
        {
         ctm.OrderOpen(_Symbol,ORDER_TYPE_BUY_LIMIT,1.0, StringToDouble(ObjectGetString(0,"panel_price",OBJPROP_TEXT,0)) );
         //Print("�������� � = ",ObjectGetString(0,"panel_price",OBJPROP_TEXT,0) );
        }
       if (sparam == "panel_sell_limit")
        {
         ctm.OrderOpen(_Symbol,ORDER_TYPE_SELL_LIMIT,1.0, StringToDouble(ObjectGetString(0,"panel_price",OBJPROP_TEXT,0)) );
         //Print("�������� � = ",ObjectGetString(0,"panel_price",OBJPROP_TEXT,0) );
        }                        
       if (sparam == "panel_close_position")
        {
         ctm.PositionClose(_Symbol);  // ��������� �������
        }
       if (sparam == "panel_delete_order") // ������� ��������� �����
        {
         for (int ind=0;ind<OrdersTotal();ind++)
          {
            ctm.OrderDelete(OrderGetTicket(ind));  // ������� ��������� �����
            return;
          }
        }
    }
  } 