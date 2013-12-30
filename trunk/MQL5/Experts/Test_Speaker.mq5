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
input string   path          = "D:\\";            // ���� � ������, ��������� ���������� � ��������� ������� 
input string   file_history  = "ORDERS_HISTORY";  // �����  ����� �����, ��������� ������� �������
input string   file_terminal = "ORDERS_TERMINAL"; // �����  ����� �����, ��������� ������� ������

string   full_path_history;                       // ������ ���� � ����� ������� �������
string   full_path_terminal;                      // ������ ���� � ����� ������� �������

// ���������� ��� �������� ���������� ������� 
int      total_orders_history   = 0;              // ����� ������� � �������

// ��������� ��� ���� ����� ������
long     order_type     = 0;     //��� ������
long     order_status   = 0;     //������ ������
double   order_volume   = 0;     //����� ������
double   take_profit    = 0;     //���� ������
double   stop_loss      = 0;     //���� ����
string   comment        = "";    //����������� � ������
ulong    ticket         = 0;     //����� 
// ��������� ��� ������������
double   order_price    = -1;    //���� ������ 


//+------------------------------------------------------------------+
//| ������� �������                                                  |
//+------------------------------------------------------------------+

// �������� �� ���� ��������� ���������� � ������� � ��������� �� � ���� 

void SaveOrdersFromHistory  (int total) 
{
 bool   openFileFlag = true;  // ���� �������� ����� 
 int    file_handle  = -1;    // ����� �����  
 Alert("TOTAL = ",total," OLD TOTAL = ",total_orders_history);
  //--- ������� �� ���� ������� � ���������� ������ �� ���������� ������ � ������ � ���������� ������ ���������� ��������
 for(int i = total-1; i >= total_orders_history; i--)
  {
   // �������� ����� 
   ticket = HistoryOrderGetTicket(i);
   // ���� ������ ������ ����� �������� �������
   if (HistoryOrderGetString(ticket, ORDER_SYMBOL) == _Symbol)
     {
        order_type   =  HistoryOrderGetInteger(ticket, ORDER_TYPE);          // ��������� ��� ������
        order_status =  HistoryOrderGetInteger(ticket, ORDER_STATE);         // ��������� ������ ������
        order_volume =  HistoryOrderGetDouble(ticket,ORDER_VOLUME_INITIAL);  // ��������� ����� ������ (���) 
        take_profit  =  HistoryOrderGetDouble(ticket, ORDER_TP);             // ���� ������ ������
        stop_loss    =  HistoryOrderGetDouble(ticket, ORDER_SL);             // ���� ���� ������  
        comment      =  HistoryOrderGetString(ticket, ORDER_COMMENT);        // ����������� � ������
        
    // ���� ����� ������ ����� � ������� ��������
    if (openFileFlag)               
     {
      // ��������� ���� �� ������
      file_handle = CreateFileW(full_path_history, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
      // ������ ���� 
      openFileFlag = false;
     }
    // ���������� ����� � ����  
     SaveOrderToFile(file_handle);
     } 
  
 }
  // ��������� ����� ���������� ������� �������
  total_orders_history = total;
  // ��������� ����
  CloseHandle(file_handle);
}


// �������� �� ���� ��������� ���������� � ������� � ��������� �� � ���� 

void SaveOrdersFromTerminal  () 
{
 bool   openFileFlag = true;  // ���� �������� ����� 
 int    file_handle  = -1;    // ����� �����  
 int    total        = 0;     // ������ ������ �������
 total = OrdersTotal();       // �������� ������ ������ �������
  //--- ������� �� ���� ������� � ���������� ������ �� ���������� ������ � ������ � ���������� ������ ���������� ��������
 for(int i = total-1; i >= 0; i--)
  {
   // ��������� ����� 
   ticket = OrderGetTicket(i);
   // ���� ����� ������ ���� 
   if (ticket > 0)
    {
     // ���� ������ ������ ����� �������� �������
   if (OrderGetString(ORDER_SYMBOL) == _Symbol)
     {
        order_type   =  OrderGetInteger(ORDER_TYPE);           // ��������� ��� ������
        order_status =  OrderGetInteger(ORDER_STATE);          // ��������� ������ ������
        order_volume =  OrderGetDouble(ORDER_VOLUME_INITIAL);  // ��������� ����� ������ (���) 
        take_profit  =  OrderGetDouble(ORDER_TP);              // ���� ������ ������
        stop_loss    =  OrderGetDouble(ORDER_SL);              // ���� ���� ������  
        comment      =  OrderGetString(ORDER_COMMENT);         // ����������� � ������
        order_price  =  OrderGetDouble(ORDER_PRICE_OPEN);      // ����, ��������� � ������
        
    // ���� ����� ������ ����� � ������� ��������
    if (openFileFlag)               
     {
      // ��������� ���� �� ������
      file_handle = CreateFileW(full_path_terminal, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
      // ������ ���� 
      openFileFlag = false;
     }
    // ���������� ����� � ����  
     SaveOrderToFile(file_handle);
     } 
   }
 }
  // ��������� ����
  CloseHandle(file_handle);
}

bool SaveOrderToFile(int handle)  //��������� ���������� �� ������ � ���� 
{
 if(handle < 0 )
 {
  Alert("�� ������� �������� ����� � ����");
  return false;
 }
 WriteTo(handle, IntegerToString(ticket)+"&");       // ��������� ����� ������
 WriteTo(handle, IntegerToString(order_type)+"&");   // ��������� ��� ������
 WriteTo(handle, IntegerToString(order_status)+"&"); // ������ ������
 WriteTo(handle, DoubleToString(order_volume)+"&");  // ��������� ����� ������
 WriteTo(handle, DoubleToString(take_profit)+"&");   // ��������� take profit
 WriteTo(handle, DoubleToString(stop_loss)+"&");     // ��������� stop loss
 WriteTo(handle, comment+"&");                       // ����������� � ������  
 WriteTo(handle, DoubleToString(order_price)+"&");   // �������� ���� ������
 // ���� ������������ �����������, �� ���� ����������
 
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
   Print("�������. ������ ����� ��� ����� SPEAKER");
}


int OnInit()
{
 // ��������� ����� ��������� ����� ������� � �������
 full_path_history = path + file_history+"_"+_Symbol+".txt";
 // ��������� ����� ��������� ����� �������
 full_path_terminal = path + file_terminal+"_"+_Symbol+".txt"; 
 // ��������� ������� ���������� ������� � �������
 if(HistorySelect(0,TimeCurrent()))
 {
  //--- ������� ���������� ����������� ������� � ���������� ������
  total_orders_history = HistoryOrdersTotal();     
 }
 
 return(INIT_SUCCEEDED);
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
   if (total > total_orders_history)
    SaveOrdersFromHistory (total);  
  }
 // �������� �� ��������� � ������ ������������
  SaveOrdersFromTerminal();
}