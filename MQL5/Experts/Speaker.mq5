//+------------------------------------------------------------------+
//|                                                      Speaker.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| �������, ����������� � ���� ��������� ������ � �������� �������  |
//+------------------------------------------------------------------+
long   deal_type=0;  //��� ������
double deal_volume=0; //����� ������
double deal_price=0; //���� ������
long   first_time;     //����� ������ ���� ��� �������� ��������



bool CurrentPositionLastDealPrice() //���������� ��������� ��������� ������
  {
   int    total       =0;   // ����� ������ � ������ ��������� �������
   string deal_symbol ="";  // ������ ������ 
//--- ���� ������� ������� ��������
   if(HistorySelect(first_time,TimeCurrent()))
     {
      //--- ������� ���������� ������ � ���������� ������
      total=HistoryDealsTotal();     
      //--- ������� �� ���� ������� � ���������� ������ �� ��������� ������ � ������ � ������
      for(int i=total-1; i>=0; i--)
        {
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- ���� ������ ������ � ������� ������ �����, ��������� ����
         if(deal_symbol==_Symbol)
           {
            deal_type=HistoryDealGetInteger(HistoryDealGetTicket(i),DEAL_TYPE);
            deal_volume=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_VOLUME);
            deal_price=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_PRICE);              
            first_time = TimeCurrent();
            return true; 
            
           }
        }
     }
     return false;
  }

bool SavePositionToFile(string file_url)  //��������� ������� � ���� 
{
 long tmp_time = TimeCurrent();  //��������� ������� �����
 int file_handle = FileOpen(file_url, FILE_WRITE|FILE_COMMON|FILE_ANSI, "");
 if(file_handle == INVALID_HANDLE)
 {
  Alert("�� ������� ������� ���� ��� ������ ������");
  return false;
 }

   FileWrite(file_handle,tmp_time); //��������� ������� �����
   FileWrite(file_handle, deal_type ); //��������� ��� ������    
   FileWrite(file_handle, deal_volume ); //��������� ����� ������
   FileWrite(file_handle, deal_price ); //��������� ���� ������   
     
   FileClose(file_handle); //��������� ����
   return true;
}

int OnInit()
  {
   first_time = TimeCurrent();


   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {

   
  }

void OnTrade()
  {
   if (CurrentPositionLastDealPrice() )      
   {
    if (FileDelete("mask.txt",FILE_COMMON))  //������� ���� �����
    {
     Print ("������� ����-�����");
    }
    else
    {
     Print ("�� ������� ������� ����-�����");
    }
    
    if (SavePositionToFile("speaker.txt")) //��������� ��������� ������ � ����
    {
     Print ("�������� ������� � ����");
    }
    else
    {
     Print ("�� ������� ��������� ������� � ����");
    }
    
    int handle;
    if ((handle = FileOpen("mask.txt", FILE_WRITE|FILE_COMMON,"")) == INVALID_HANDLE) //������� ���� �����
    {
     Print ("�� ������� ������� ����-����� �������");
    }
    else
    {
     Print ("������� ������� ����-����� �������, ��������� ����");
     FileClose(handle);
    }
   }
  }
