//+------------------------------------------------------------------+
//|                                                      Speaker.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| ������ WIN API ����������                                        |
//+------------------------------------------------------------------+

#import "kernel32.dll"

  bool CloseHandle                // �������� �������
       ( int hObject );                  // ����� �������
       
  int CreateFileW                 // �������� �������� �������
      ( string lpFileName,               // ������ ���� ������� � �������
        int    dwDesiredAccess,          // ��� ������� � �������
        int    dwShareMode,              // ����� ������ �������
        int    lpSecurityAttributes,     // ��������� ������������
        int    dwCreationDisposition,    // ��������� ��������
        int    dwFlagsAndAttributes,     // ����� ����������
        int    hTemplateFile );      
          
  bool WriteFile                  // ������ ������ � ����
       ( int    hFile,                   // handle to file to write to
         char    &dBuffer[],             // pointer to data to write to file
         int    nNumberOfBytesToWrite,   // number of bytes to write
         int&   lpNumberOfBytesWritten[],// pointer to number of bytes written
         int    lpOverlapped );          // pointer to structure needed for overlapped I/O    
  
  int  RtlGetLastWin32Error();
  
  int  RtlSetLastWin32Error (int dwErrCode);       
    
#import

//+------------------------------------------------------------------+
//| ����������� ���������                                            |
//+------------------------------------------------------------------+

// ��� ������� � �������
#define _GENERIC_WRITE_      0x40000000
// ����� ������ �������
#define _FILE_SHARE_WRITE_   0x00000002
// ��������� ��������
#define _CREATE_ALWAYS_      2

//+------------------------------------------------------------------+
//| ��������� �������                                                |
//+------------------------------------------------------------------+

// ��������� ��������
input string   path     = "D:\\";        // ���� � �����, ��������� ���������� � ��������� ������� 
input string   file_instant = "INSTANT"; // �����  ����� �����, ��������� ���������� � ��������� ����������� �������
input string   file_pending = "PENDING"; // �����  ����� �����, ��������� ���������� � ��������� ���������� �������

string   full_path_instant;              // ������ ���� � ����� ����������� �������
string   full_path_pending;              // ������ ���� � ����� ���������� �������  

int      total_instant_orders  = 0;            // ����� ����������� ������� � �������

// ��������� ��� ���� ����� ������
long     order_type     = 0;     //��� ������
double   order_volume   = 0;     //����� ������
double   take_profit    = 0;     //���� ������
double   stop_loss      = 0;     //���� ����
// ��������� ��� ������������
double   order_price    = -1;    //���� ������ 


//+------------------------------------------------------------------+
//| ������� �������                                                  |
//+------------------------------------------------------------------+

// �������� �� ���� ��������� ����������� ������� � ��������� �� � ���� 

void SaveNewInstantOrders (int total) 
{
 bool   openFileFlag = true;  // ���� �������� ����� �� 
 int    file_handle  = -1;    // ����� �����  
  //--- ������� �� ���� ������� � ���������� ������ �� ���������� ������ � ������ � ���������� ������ ���������� ��������
 for(int i = total-1; i >= total_instant_orders; i--)
  {
     // ���� ������ ������ ����� �������� �������
   if (HistoryOrderGetString(HistoryOrderGetTicket(i), ORDER_SYMBOL) == _Symbol)
     {
        order_type   =  HistoryOrderGetInteger(HistoryOrderGetTicket(i), ORDER_TYPE);          // ��������� ��� ������
        order_volume =  HistoryOrderGetDouble(HistoryOrderGetTicket(i),ORDER_VOLUME_INITIAL);  // ��������� ����� ������ (���) 
        take_profit  =  HistoryOrderGetDouble(HistoryOrderGetTicket(i), ORDER_TP);             // ���� ������ ������
        stop_loss    =  HistoryOrderGetDouble(HistoryOrderGetTicket(i), ORDER_SL);             // ���� ���� ������    
     
    // ���� ����� ������ ����� � ������� ��������
    if (openFileFlag)               
     {
      // ��������� ���� �� ������
      file_handle = CreateFileW(full_path_instant, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
      // ������ ���� 
      openFileFlag = false;
     }
    // ���������� ����� � ����  
     SaveOrderToFile(file_handle);
     } 
  
 }
  // ��������� ����� ���������� ������� �������
  total_instant_orders = total;
  // ��������� ����
  CloseHandle(file_handle);
}


// �������� �� ���� ��������� ���������� ������� � ��������� �� � ���� 

void SaveNewPendingOrders (int total) 
{
 bool   openFileFlag = true;  // ���� �������� ����� �� 
 int    file_handle  = -1;    // ����� �����  
  //--- ������� �� ���� ������� � ���������� ������ �� ���������� ������ � ������ � ���������� ������ ���������� ��������
 for(int i = total-1; i >= total_instant_orders; i--)
  {
     // ���� ������ ������ ����� �������� �������
   if (HistoryOrderGetString(HistoryOrderGetTicket(i), ORDER_SYMBOL) == _Symbol)
     {
        order_type   =  HistoryOrderGetInteger(HistoryOrderGetTicket(i), ORDER_TYPE);          // ��������� ��� ������
        order_volume =  HistoryOrderGetDouble(HistoryOrderGetTicket(i),ORDER_VOLUME_INITIAL);  // ��������� ����� ������ (���) 
        take_profit  =  HistoryOrderGetDouble(HistoryOrderGetTicket(i), ORDER_TP);             // ���� ������ ������
        stop_loss    =  HistoryOrderGetDouble(HistoryOrderGetTicket(i), ORDER_SL);             // ���� ���� ������    
     
    // ���� ����� ������ ����� � ������� ��������
    if (openFileFlag)               
     {
      // ��������� ���� �� ������
      file_handle = CreateFileW(full_path_instant, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
      // ������ ���� 
      openFileFlag = false;
     }
    // ���������� ����� � ����  
     SaveOrderToFile(file_handle);
     } 
  
 }
  // ��������� ����� ���������� ������� �������
  total_instant_orders = total;
  // ��������� ����
  CloseHandle(file_handle);
}

bool SaveOrderToFile(int handle)  //��������� ���������� �� ������� � ���� 
{
 if(handle < 0 )
 {
  Alert("�� ������� �������� ����� � ����");
  return false;
 }
 
 WriteTo(handle, IntegerToString(order_type)+"&");   // ��������� ��� ������
 WriteTo(handle, DoubleToString(order_volume)+"&");  // ��������� ����� ������
 WriteTo(handle, DoubleToString(take_profit)+"&");   // ��������� take profit
 WriteTo(handle, DoubleToString(stop_loss)+"&");     // ��������� stop loss  
 // ���� ������������ �����������, �� ���� ����������
 if (order_price != -1 )
  {
   WriteTo(handle, DoubleToString(order_price)+"&"); // ��������� ���� ����������� ������ 
  }
   
 return true;
}

// ��������� ������ � ����
void WriteTo(int handle, string buffer) 
{
  int    nBytesRead[1]={1};
  char   buff[]; 
  StringToCharArray(buffer,buff);
  if(handle>0) 
  {
    Comment(" ");
    WriteFile(handle, buff, StringLen(buffer), nBytesRead, NULL);
    
  } 
  else
   Print("�������. ������ ����� ��� ����� ��������");
}


int OnInit()
{
 // ��������� ����� ��������� ����� ����������� �������
 full_path_instant = path + file_instant+"_"+_Symbol+".txt";
 // ��������� ����� ��������� ����� ���������� �������
 full_path_pending = path + file_pending+"_"+_Symbol+".txt"; 
 // ��������� ������� ���������� ������� � �������
 if(HistorySelect(0,TimeCurrent()))
 {
  //--- ������� ���������� ����������� ������� � ���������� ������
  total_instant_orders = HistoryOrdersTotal();     
 }
 
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
}



void OnTrade()
{
 int total; 
 // �������� �� ��������� � ������� �������
 if(HistorySelect(0,TimeCurrent()))
  {
   // ��������� ���������� ������� � �������
   total = HistoryOrdersTotal(); 
   // ���� ������� ���������� ������� ������, ��� ����������  
   if (total > total_instant_orders)
    SaveNewInstantOrders (total);  
  }
 // �������� �� ��������� � ������ ������������
}