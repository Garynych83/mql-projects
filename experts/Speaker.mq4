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
  int CreateFileW                 // �������� �������� �������
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

extern string   path         = "C:\\speaker\\A";            // ���� � ������, ��������� ���������� � ��������� ������� 
extern string   file_instant = "ORDERS_INSTANT";  // �����  ����� �����, ��������� ������� �������
extern string   file_pending = "ORDERS_PENDING"; // �����  ����� �����, ��������� ������� ������

string   full_path_instant;                       // ������ ���� � ����� ������� �������
string   full_path_pending;                      // ������ ���� � ����� ������� �������

// ���������� ��� �������� ���������� ������� 
int      total_orders = 0;              // ����� ������� � �������
bool check = true;

// ��������� ��� ���� ����� ������
int      order_type     = 0;     //��� ������
int      order_status   = 0;     //������ ������
double   order_volume   = 0;     //����� ������
double   take_profit    = 0;     //���� ������
double   stop_loss      = 0;     //���� ����
string   comment        = "";    //����������� � ������
int      ticket         = 0;     //����� 
// ��������� ��� ������������
double   order_price    = -1;    //���� ������ 
//---------------------------------------------------------------------------------------------
void start() 
{
  // ��������� ������ �������� ������
  full_path_instant = StringConcatenate(path, file_instant, "_", Symbol(), ".txt");
  full_path_pending = path + file_pending + "_" + Symbol() + ".txt"; 
/*  if(total_orders != OrdersTotal())
  {
   Print(total_orders, " = ", OrdersTotal());
   SaveOrdersFromTerminal();
   total_orders = OrdersTotal();
  }*/
  if(check)
  {
   check = false;
   int file_handle = CreateFileW(full_path_instant, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, 128, NULL); 
   Print("������ ����. handle = ", file_handle, " name = ", full_path_instant);   
   SaveOrderToFile(file_handle);
   
   CloseHandle(file_handle);
  }
}
//---------------------------------------------------------------------------------------------
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
   if (OrderSelect(i, SELECT_BY_POS))
   {
     // ���� ������ ������ ����� �������� �������
     if (OrderSymbol() == Symbol())
     {
        Print("������ ������");
        order_type   =  OrderType();           // ��������� ��� ������
        //order_status =  OrderGetInteger(ORDER_STATE);          // ��������� ������ ������
        order_volume =  OrderLots();           // ��������� ����� ������ (���) 
        take_profit  =  OrderTakeProfit();     // ���� ������ ������
        stop_loss    =  OrderStopLoss();       // ���� ���� ������  
        comment      =  OrderComment();        // ����������� � ������
        order_price  =  OrderOpenPrice();      // ����, ��������� � ������
        
        // ���� ����� ������ ����� � ������� ��������
        if (openFileFlag)               
        {
         // ��������� ���� �� ������
         file_handle = CreateFileW(full_path_instant, GENERIC_WRITE, FILE_SHARE_WRITE, 0, CREATE_ALWAYS, 128, NULL);  
         // ������ ���� 
         openFileFlag = false;
        }
        // ���������� ����� � ����  
        SaveOrderToFile(file_handle);
     }
     Print("������ ����� ", i); 
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
 WriteTo(handle, DoubleToStr(      ticket, 0)+"&");       // ��������� ����� ������
 WriteTo(handle, DoubleToStr(  order_type, 0)+"&");       // ��������� ��� ������
 WriteTo(handle, DoubleToStr(order_status, 0)+"&");       // ������ ������
 WriteTo(handle, DoubleToStr(order_volume, Digits)+"&");  // ��������� ����� ������
 WriteTo(handle, DoubleToStr( take_profit, Digits)+"&");  // ��������� take profit
 WriteTo(handle, DoubleToStr(   stop_loss, Digits)+"&");  // ��������� stop loss
 WriteTo(handle, comment+"&");                            // ����������� � ������  
 WriteTo(handle, DoubleToStr( order_price, Digits)+"&");  // �������� ���� ������
 // ���� ������������ �����������, �� ���� ����������
 
 return(true);
}