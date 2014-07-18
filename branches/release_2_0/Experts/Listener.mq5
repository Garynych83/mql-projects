//+------------------------------------------------------------------+
//|                                                     Listener.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Trade/Trade.mqh>
//+------------------------------------------------------------------+
//| �������, ����������� ��������� ��������� ������                  |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE deal_type=0;  //��� ������
double deal_volume=0; //����� ������
double deal_price=0; //���� ������

long date_last_pos;  //���� ��������� �������
CTrade new_trade; //����� ��������
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ReadPositionFromFile(string file_url) //��������� ���� ��� �������� �������
  {
   int file_handle;
   int tmp_time;
   string tmp_string;

   file_handle=FileOpen(file_url,FILE_READ|FILE_COMMON|FILE_ANSI|FILE_TXT|FILE_SHARE_READ,"");
   if(file_handle==INVALID_HANDLE)
     {
      return false;
     }
     
   tmp_string=FileReadString(file_handle,-1);

   if(StringToInteger(tmp_string) > date_last_pos) //���� ����� � ����� ������, ��� ��������� ����������� �����
     {
      deal_type=StringToInteger(FileReadString(file_handle)); //��������� ��� ������
      deal_volume=StringToDouble(FileReadString(file_handle)); //��������� ��� ������
      date_last_pos=StringToInteger(tmp_string);  //��������� ����� ��������� ������       
      FileClose(file_handle);
      return true;
     }

   FileClose(file_handle);
   return  false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   date_last_pos=TimeCurrent();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!FileIsExist("mask.txt",FILE_COMMON)) return;

   if(ReadPositionFromFile("speaker.txt")) //���� ������ ����������
     {
      double price;
      MqlTradeRequest my_trade;
      MqlTradeResult my_trade_result;
      MqlTick last_tick;
      SymbolInfoTick(_Symbol,last_tick);

      ZeroMemory(my_trade);
      ZeroMemory(my_trade_result);
      Comment("DEAL TYPE = ",EnumToString(deal_type),"  DEAL VOLUME = ",deal_volume);

      if(deal_type==0) //BUY
        {
         my_trade.type=ORDER_TYPE_BUY;
         price=last_tick.ask;
        }
      if(deal_type==1) //SELL
        {
         my_trade.type=ORDER_TYPE_SELL;
         price=last_tick.bid;
        }

      my_trade.action=TRADE_ACTION_DEAL;
      my_trade.symbol=_Symbol;
      my_trade.volume=deal_volume;
      my_trade.price=NormalizeDouble(price,_Digits);
      my_trade.sl=0;
      my_trade.tp=0;
      my_trade.deviation=0;
      my_trade.type_filling=ORDER_FILLING_FOK;
      my_trade.comment="";

      MyOrderSend(my_trade,my_trade_result);     
     }
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|  �������� ��������� ������� � ���������� ����������              |
//+------------------------------------------------------------------+
bool MyOrderSend(MqlTradeRequest &request,MqlTradeResult &result)
  {
//--- ������� ��� ��������� ������ � ����
   ResetLastError();
//--- �������� ������
   bool success=OrderSend(request,result);
//--- ���� ��������� ��������� - ��������� ������ � ��� ����
   if(!success)
     {
      int answer=result.retcode;
      Print("TradeLog: Trade request failed. Error = ",GetLastError());
      switch(answer)
        {
         //--- �������
         case 10004:
           {
            Print("TRADE_RETCODE_REQUOTE");
            Print("request.price = ",request.price,"   result.ask = ",
                  result.ask," result.bid = ",result.bid);
            break;
           }
         //--- ����� �� ������ ��������
         case 10006:
           {
            Print("TRADE_RETCODE_REJECT");
            Print("request.price = ",request.price,"   result.ask = ",
                  result.ask," result.bid = ",result.bid);
            break;
           }
         //--- ������������ ����
         case 10015:
           {
            Print("TRADE_RETCODE_INVALID_PRICE");
            Print("request.price = ",request.price,"   result.ask = ",
                  result.ask," result.bid = ",result.bid);
            break;
           }
         //--- ������������ SL �/��� TP
         case 10016:
           {
            Print("TRADE_RETCODE_INVALID_STOPS");
            Print("request.sl = ",request.sl," request.tp = ",request.tp);
            Print("result.ask = ",result.ask," result.bid = ",result.bid);
            break;
           }
         //--- ������������ �����
         case 10014:
           {
            Print("TRADE_RETCODE_INVALID_VOLUME");
            Print("request.volume = ",request.volume,"   result.volume = ",
                  result.volume);
            break;
           }
         //--- �� ������� ����� �� �������� ��������  
         case 10019:
           {
            Print("TRADE_RETCODE_NO_MONEY");
            Print("request.volume = ",request.volume,"   result.volume = ",
                  result.volume,"   result.comment = ",result.comment);
            break;
           }
         //--- �����-�� ������ �������, ������� ��� ������ �������   
         default:
           {
            Print("Other answer = ",answer);
           }
        }
      //--- ������� � ��������� ���������� ��������� ������� ��������� false
      return(false);
     }
//--- OrderSend() ������ true - �������� �����
   return(true);
  }
