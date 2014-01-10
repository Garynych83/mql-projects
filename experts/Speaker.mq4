//+------------------------------------------------------------------+
//|                                                      Speaker.mq4 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#import "kernel32.dll"
  bool CloseHandle                // �������� �������
       ( int hObject );                // ����� �������
  int CreateFileA                 // �������� �������� �������
      ( string lpFileName,               // ������ ���� ������� � �������
        int    dwDesiredAccess,          // ��� ������� � �������
        int    dwShareMode,              // ����� ������ �������
        int    lpSecurityAttributes,     // ��������� ������������
        int    dwCreationDisposition,    // ��������� ��������
        int    dwFlagsAndAttributes,     // ����� ����������
        int    hTemplateFile );          //
  bool ReadFile                   // ������ ������ �� �����
       ( int    hFile,                 // handle of file to read
         string lpBuffer,              // address of buffer that receives data 
         int    nNumberOfBytesToRead,  // number of bytes to read
         int&   lpNumberOfBytesRead[], // address of number of bytes read
         int    lpOverlapped );        // address of structure for data
  bool WriteFile                  // ������ ������ � ����
       ( int    hFile,                      // handle to file to write to
         string lpBuffer,                   // pointer to data to write to file
         int    nNumberOfBytesToWrite,      // number of bytes to write
         int&   lpNumberOfBytesWritten[],   // pointer to number of bytes written
         int    lpOverlapped );             // pointer to structure needed for overlapped I/O        
  int  RtlGetLastWin32Error ();
  int  RtlSetLastWin32Error (int dwErrCode);  
#import
//---------------------------------------------------------------------------------------------
// CONST
// ��� ������� � �������
#define GENERIC_READ    0x80000000
#define GENERIC_WRITE   0x40000000
#define GENERIC_EXECUTE 0x20000000
#define GENERIC_ALL     0x10000000
// ����� ������ �������
#define FILE_SHARE_READ   0x00000001
#define FILE_SHARE_WRITE  0x00000002
#define FILE_SHARE_DELETE 0x00000004
// ��������� ��������
#define CREATE_NEW        1
#define CREATE_ALWAYS     2
#define OPEN_EXISTING     3
#define OPEN_ALWAYS       4
#define TRUNCATE_EXISTING 5

extern string   path         = "C:\\speaker\\$";  // ���� � ������, ��������� ���������� � ��������� ������� 
extern string   file_instant = "ORDERS_INSTANT";  // �����  ����� �����, ��������� ������� �������
extern string   file_pending = "ORDERS_PENDING";  // �����  ����� �����, ��������� ������� ������

string   full_path_instant;                       // ������ ���� � ����� ������� �������
string   full_path_pending;                      // ������ ���� � ����� ������� �������

// ���������� ��� �������� ���������� �������
int      total_orders = 0;              // ����� ������� � �������
int      count_instant = 0;             // ������� ������� 

// ��������� ��� ���� ����� ������
int      order_type     = -1;     //��� ������
int      order_status   = -1;     //������ ������
double   order_volume   = -1;     //����� ������
double   take_profit    = -1;     //���� ������
double   stop_loss      = -1;     //���� ����
string   comment        = "empty";    //����������� � ������
int      order_ticket   = -1;     //����� 
// ��������� ��� ������������
double   order_price    = -1;    //���� ������ 
//---------------------------------------------------------------------------------------------
void start() 
{
  // ��������� ������ �������� ������
  full_path_instant = StringConcatenate(path, file_instant, "_", Symbol(), ".txt");
  full_path_pending = StringConcatenate(path, file_pending, "_", Symbol(), ".txt");
  Print("imagine =", total_orders, "; real = ", OrdersTotal(), "; instant = ", count_instant);
  if(CheckCountInstant() > 0)
  {
   SaveOrder();
  }
  else if(CheckCountInstant() > 0)
  {
   SaveOrderFromHistory();
  }
 
  //if(total_orders > OrdersTotal())
  //{
   //Print(total_orders, " > ", OrdersTotal());
   //SaveInstantOrders();
   SavePendingOrders();
  //}
  total_orders = OrdersTotal();
}
//---------------------------------------------------------------------------------------------
int CheckCountInstant()
{
 int count = 0;
 int result = 0;
 int total = OrdersTotal();       // �������� ���������� �������� �������
  //--- ������� �� ���� ������� � ���������� ������ �� ���������� ������ � ������ � ���������� ������ ���������� ��������
 for(int i = total-1; i >= 0; i--)
 {
  if (OrderSelect(i, SELECT_BY_POS))
  {
    // ���� ������ ������ ����� �������� �������
    if (OrderSymbol() == Symbol())
    {
      if(OrderType() == OP_BUY || OrderType() == OP_SELL) 
         count++;      
    }
  }
 }
 if(count > count_instant) 
  result = 1;
 else if(count < count_instant) 
  result = -1;
 count_instant = count;
 return(result);
}
//+----------------------------------------------------------------------------+
//|  ����������� ����� ��� ��� ���������� �� ������ ������                     |
//|  ���������:                                                                |
//|    nf1 - ��� ����� ���������                                               |
//|    nf2 - ��� ����� ����������                                              |
//+----------------------------------------------------------------------------+
void WriteTo(int handle, string buffer) 
{
  int nBytesRead[1]={1};
  if(handle>0) 
  {
    //Print("�����"); 
    WriteFile(handle, buffer, StringLen(buffer), nBytesRead, NULL);
  } 
  else
   Print("�������. ������ ����� ��� ����� ��������");
}

//+------------------------------------------------------------------+

void SaveOrder() 
{
 bool openFileFlag = true;
 int  file_handle  = -1;    // ����� �����  
 int  total        = 0;     // ������ ������ �������
 total = OrdersTotal();       // �������� ������ ������ �������
  //--- ������� �� ���� ������� � ���������� ������ �� ���������� ������ � ������ � ���������� ������ ���������� ��������
 for(int i = total-1; i >= 0; i--)
  {
   if (OrderSelect(i, SELECT_BY_POS))
   {
     // ���� ������ ������ ����� �������� �������
     if (OrderSymbol() == Symbol() && (OrderType() == OP_BUY || OrderType() == OP_SELL))
     {
        order_ticket = OrderTicket();
        order_type   = OrderType();           // ��������� ��� ������
        //order_status =  OrderGetInteger(ORDER_STATE);          // ��������� ������ ������
        order_volume = OrderLots();           // ��������� ����� ������ (���) 
        take_profit  = OrderTakeProfit();     // ���� ������ ������
        stop_loss    = OrderStopLoss();       // ���� ���� ������  
        comment      = OrderComment();        // ����������� � ������
        order_price  = OrderOpenPrice();      // ����, ��������� � ������
        
        // ���� ����� ������ ����� � ������� ��������
        if (openFileFlag)               
        {
         // ��������� ���� �� ������
         file_handle = CreateFileA(full_path_instant, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, 128, NULL);
         openFileFlag = false;
         SaveOrderToFile(file_handle); // ���������� ����� � ����
        }       
     }
   }
 }
 if (!openFileFlag) CloseHandle(file_handle);
}

void SaveOrderFromHistory() 
{
 bool openFileFlag = true;
 int  file_handle  = -1;    // ����� �����  
 int  total        = 0;     // ������ ������ �������
 total = OrdersHistoryTotal();       // �������� ������ ������ �������
  //--- ������� �� ���� ������� � ���������� ������ �� ���������� ������ � ������ � ���������� ������ ���������� ��������
 for(int i = total-1; i >= 0; i--)
  {
   if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
   {
     // ���� ������ ������ ����� �������� �������
     if (OrderSymbol() == Symbol() && (OrderType() == OP_BUY || OrderType() == OP_SELL))
     {
        order_ticket = OrderTicket();
        order_type   = (OrderType() + 1)%2;           // ��������� ��� ������
        //order_status =  OrderGetInteger(ORDER_STATE);          // ��������� ������ ������
        order_volume = OrderLots();           // ��������� ����� ������ (���) 
        take_profit  = OrderTakeProfit();     // ���� ������ ������
        stop_loss    = OrderStopLoss();       // ���� ���� ������  
        comment      = OrderComment();        // ����������� � ������
        order_price  = OrderOpenPrice();      // ����, ��������� � ������
        
        // ���� ����� ������ ����� � ������� ��������
        if (openFileFlag)               
        {
         // ��������� ���� �� ������
         file_handle = CreateFileA(full_path_instant, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, 128, NULL);
         openFileFlag = false;
         SaveOrderToFile(file_handle); // ���������� ����� � ����
        }       
     }
   }
 }
 if (!openFileFlag) CloseHandle(file_handle);
}

void SavePendingOrders  () 
{
 bool   openFileFlag = true;  // ���� �������� ����� 
 int    file_handle  = -1;    // ����� �����  
 int    total        =  OrdersTotal();       // �������� ������ ������ �������
  //--- ������� �� ���� ������� � ���������� ������ �� ���������� ������ � ������ � ���������� ������ ���������� ��������
 for(int i = total-1; i >= 0; i--)
  {
   // ��������� ����� 
   if (OrderSelect(i, SELECT_BY_POS))
   {
     // ���� ������ ������ ����� �������� �������
     if ( OrderSymbol() == Symbol() && 
         (OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLSTOP || OrderType() == OP_BUYSTOP || OrderType() == OP_SELLLIMIT))
     {
        order_ticket = OrderTicket();
        order_type   = OrderType();           // ��������� ��� ������
        //order_status =  OrderGetInteger(ORDER_STATE);          // ��������� ������ ������
        order_volume = OrderLots();           // ��������� ����� ������ (���) 
        take_profit  = OrderTakeProfit();     // ���� ������ ������
        stop_loss    = OrderStopLoss();       // ���� ���� ������  
        comment      = OrderComment();        // ����������� � ������
        order_price  = OrderOpenPrice();      // ����, ��������� � ������
        
        // ���� ����� ������ ����� � ������� ��������
        if (openFileFlag)               
        {
         // ��������� ���� �� ������
         file_handle = CreateFileA(full_path_pending, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, 128, NULL);
         openFileFlag = false;
        }
        // ���������� ����� � ����  
        SaveOrderToFile(file_handle);
     }
   }
 }
 if (!openFileFlag) CloseHandle(file_handle);
}

bool SaveOrderToFile(int handle)  //��������� ���������� �� ������ � ���� 
{
 if(handle < 0 )
 {
  Print("�� ������� �������� ����� � ����");
  return(false);
 }
 WriteTo(handle, DoubleToStr(order_ticket, 0)+"&");       // ��������� ����� ������
 WriteTo(handle, DoubleToStr(  order_type, 0)+"&");       // ��������� ��� ������
 WriteTo(handle, DoubleToStr(order_status, 0)+"&");       // ������ ������
 WriteTo(handle, DoubleToStr(order_volume, Digits)+"&");  // ��������� ����� ������
 WriteTo(handle, DoubleToStr( take_profit, Digits)+"&");  // ��������� take profit
 WriteTo(handle, DoubleToStr(   stop_loss, Digits)+"&");  // ��������� stop loss
 WriteTo(handle, comment+"&");                            // ����������� � ������  
 WriteTo(handle, DoubleToStr( order_price, Digits)+"&");  // �������� ���� ������
 WriteTo(handle, "\r\n");
 // ���� ������������ �����������, �� ���� ����������
 
 return(true);
}