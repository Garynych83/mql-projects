//+------------------------------------------------------------------+
//|                                                  GetBackTest.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <TradeManager\BackTest.mqh>    //���������� ���������� ��������
#include <StringUtilities.mqh>          //���������� ���������� ��������
#include <Charts\Chart.mqh>
#include <Expertoscop\CExpertoScop.mqh> //���������� ����� �������������

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
//| ������� ���������� ����������� �������� ��� ���������� ��������� |
//+------------------------------------------------------------------+


BackTest backtest;                               // ������ ������ ��������

CExpertoscop * expscop  = new CExpertoscop();    // ������ ������ �������������

//---- ������� ���������� ����� ����� �������

string GetHistoryFileName (string exp_name,string sym,string  tf)
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv",exp_name, "History",exp_name, sym, tf);
  return str;
 }
 
//---- ������� ���������� ����� ����� ����������� ���������� �������� 
 
string GetBackTestFileName (string exp_name,string sym,string  tf)
 {
  string str="";
  str = StringFormat("C:\%s_%s_%s.txt", exp_name, sym, tf);
  return str;
 } 
 
//---- ������� ���������� ������ ������ �������

bool  ReadHistoryList ()
 {
  return (true);  
 }
 

//---- ������� ��������� ��������� ���������

void CalculateBackTest (datetime time_from,datetime time_to)
  {
   string historyFile;   // ����� ����� �������
   string backtestFile;  // ����� ����� ��������
   bool   flag;          // ���� �������� ������������� ����� �������
   uint   n_experts;     // ���������� ���������� ��������� 
   uint   index;         // ������� ��� ����������� � ����� �� �������
   
   string expert_name;   // ��� ����������� ��������
   string expert_symbol; // ������, �� �������� ������� �������
   string expert_period; // ������ (���������) �� �������� ������� �������
   
   int file_handle;      // ����� ���� ������ URL ������� ��������
   
    //---- �������� ������������ � �������� ������ ���������� ���������� ���������
    expscop.DoExpertoScop();
    //---- �������� ���������� ���������� ���������
    n_experts = expscop.GetParamLength();
    
    //---- ���� ���� ���������� ��������
    
    if (n_experts > 0)
    {
    //---- ��������� ���� ������ URL ������� ���������
    file_handle = CreateFileW("C:\\_backtest_.dat", _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);
    //---- �������� �� ���� ���������� ���������� ��������� � �������� ���������
    
    for (index=0;index < n_experts; index++)
     {
      expert_name   = expscop.GetExpertName(index);                 // �������� ��� ��������
      expert_symbol = expscop.GetSymbol(index);                     // �������� ������
      expert_period = PeriodToString(expscop.GetTimeFrame(index));  // �������� ���������
      Print("_____________________________");
      Print("��� �������� = ", expert_name);
      Print("������ = ", expert_symbol);
      Print("������ = ",expert_period);
      Print("_____________________________");      
      //---- �������� ��� ����� �������
      historyFile   = GetHistoryFileName  (expert_name,expert_symbol,expert_period);
      //---- �������� ��� ����� ��������
      backtestFile  = GetBackTestFileName (expert_name,expert_symbol,expert_period);
      Alert("����� ������ = ", backtestFile);
      //---- ��������� ���� �������
      flag = backtest.LoadHistoryFromFile(historyFile,time_from,time_to);
      //---- ��������� ���� �������
      if (flag)
      //---- ���� ���� ������� ������� ���������
       {
       //---- �� ��������� ��������� �������� � ��������� �� � ����
       //backtest.SaveBackTestToFile(backtestFile,expert_symbol);
       backtest.SaveBackTestToFile(backtestFile,expert_symbol);
       //---- ��������� URL � ���� ������ URL ��������
       Comment("");
       WriteTo(file_handle,backtestFile+" ");
       }
     }
     //---- ��������� ���� ������ URL ������
     CloseHandle(file_handle);
     }
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
   Print("�������. ������ ����� ��� ����� ");
}