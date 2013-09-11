//+------------------------------------------------------------------+
//|                                                 ForTerminals.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager/TradeManager.mqh> //���������� ���������� ������

long   deal_type;  //��� ������
double deal_volue; //����� ������
double deal_price; //���� ������
   
long date_last_pos;  //���� ��������� �������
CTradeManager new_trade; //����� ��������

void CurrentPositionLastDealPrice() //���������� ��������� ��������� ������
  {
   int    total       =0;   // ����� ������ � ������ ��������� �������
   string deal_symbol ="";  // ������ ������ 
   double deal_price  =0.0; // ����
//--- ���� ������� ������� ��������
   if(HistorySelect(date_last_pos,TimeCurrent()))
     {
      //--- ������� ���������� ������ � ���������� ������
      total=HistoryDealsTotal();
      //--- ������� �� ���� ������� � ���������� ������ �� ��������� ������ � ������ � ������
      for(int i=total-1; i>=0; i--)
        {
         //--- ������� ���� ������
         Alert("HELL");
         deal_type=HistoryDealGetInteger(HistoryDealGetTicket(i),DEAL_TYPE);
         deal_volue=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_VOLUME);
         deal_price=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_PRICE);                  
         //--- ������� ������ ������
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- ���� ������ ������ � ������� ������ �����, ��������� ����
         if(deal_symbol==_Symbol)
            break;
        }
     }

  }

void SavePositionToFile(string file_url)  //��������� ������� � ���� 
{
 long tmp_time = TimeCurrent();  //��������� ������� �����
 int total;
 int file_handle = FileOpen(file_url, FILE_WRITE|FILE_CSV|FILE_COMMON, ";");
 if(file_handle == INVALID_HANDLE)
 {
  return;
 }
   FileWrite(file_handle,tmp_time); //��������� ������� �����
    
     //��������� ��������� ��������� ������
    /*
    HistorySelect(date_last_pos,tmp_time);  //��������� ������� ������
    
    total = HistoryDealsTotal(); //�������� ���������� ������
    

   */
   CurrentPositionLastDealPrice(); //��������� ��������� ��������� ������
   
   FileWrite(file_handle, HistoryDealGetInteger(HistoryDealGetTicket(total-1),DEAL_TYPE) ); //��������� ��� ������    
   FileWrite(file_handle, HistoryDealGetDouble(HistoryDealGetTicket(total-1),DEAL_VOLUME) ); //��������� ����� ������
   FileWrite(file_handle, HistoryDealGetDouble(HistoryDealGetTicket(total-1),DEAL_PRICE) ); //��������� ���� ������   
     
      
     date_last_pos = tmp_time;  //��������� ����� ������
      
 FileClose(file_handle); //��������� ����
}

bool ReadPositionFromFile (string file_url) //��������� ���� ��� �������� �������
 {
 int file_handle = FileOpen(file_url, FILE_READ|FILE_CSV|FILE_COMMON, ";");
 long tmp_time;
 if(file_handle == INVALID_HANDLE)
 {
  return false;
 }

 //��������� ������� 
 
 tmp_time = FileReadLong(file_handle); //��������� ����� �� ����� 
 
 if (tmp_time > date_last_pos) //���� ����� � ����� ������, ��� ��������� ����������� �����
  {
   deal_type  =  FileReadLong(file_handle); //��������� ��� ������
   deal_volue =  FileReadDouble(file_handle); //��������� ����� ������
   deal_price =  FileReadDouble(file_handle); //��������� ���� ������
   return true;
  } 
 FileClose(file_handle);
 return  false;
 }

int OnInit()
  {
   //��������� ������� ����� �������
   date_last_pos = TimeCurrent();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  {
    //��������� ������ ���, ���� �� 
    if (ReadPositionFromFile("my_file.txt") ) //���� ���� ����� ������
      {
       if (deal_type == DEAL_TYPE_BUY)
       new_trade.OpenPosition(_Symbol,OP_BUY,deal_volue,0,0,0,0,0);
       if (deal_type == DEAL_TYPE_SELL)
       new_trade.OpenPosition(_Symbol,OP_SELL,deal_volue,0,0,0,0,0);       
      } 
  }

void OnTrade()  
  {
      //��������� � ����
      SavePositionToFile("my_file.txt");     
  }
