//+------------------------------------------------------------------+
//|                                                  RunBackTest.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <TradeManager\BackTest.mqh>    //���������� ���������� ��������
#include <StringUtilities.mqh>         
//+------------------------------------------------------------------+
//| ������ ��������� ���������� ���������� ����������                |
//+------------------------------------------------------------------+

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
  int  WinExec(uchar &NameEx[], int dwFlags);  // ��������� ���������� BackTest
    
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

// ���������, �������� �������������

input string   file_catalog = "C:\\Taki";           // ����� �������� � ���������� TAKI
input string   expert_name  = "";                   // ��� �������� 
input datetime time_from = 0;                       // � ������ �������
input datetime time_to   = 0;                       // �� ����� �����

//---- ������� ���������� ����� ����� �������

string GetHistoryFileName ()
 {
  string str="";
   str = expert_name + "\\" + "History"+"\\"+expert_name+"_"+_Symbol+"_"+PeriodToString(_Period)+".csv";
  return str;
 }
 
//---- ������� ���������� ����� ����� ����������� ���������� �������� 
 
string GetBackTestFileName ()
 {
  string str="";
  str = StringFormat("\dat\%s_%s_%s[%s,%s].dat", expert_name, _Symbol, PeriodToString(_Period), TimeToString(time_from),TimeToString(time_to));
  StringReplace(str," ","_");
  StringReplace(str,":",".");  
  str = file_catalog+str;
  return str;
 } 
 
//---- ������� ���������� ����� ����� ������ URL �������

string GetBacktestUrlList ()
 {
   return "C:\\"+"_backtest_.dat";
 }
 
//---- ������� ���������� ����� ���������� TAKI

string GetTAKIUrl ()
 {
   return "cmd /C start "+file_catalog+"/"+"TAKI.exe";
 }

void OnStart()
{
 uchar    val[];
 string   backtest_file;    // ���� ����������
 string   history_url;      // ����� ����� �������
 string   url_list;         // ����� ����� ������ url � ������ ��������
 string   url_TAKI;         // ����� TAKI ����������
 bool     flag;             
 int      file_handle;      // ����� ����� ������ URL ������ ���������
 BackTest backtest;         // ������ ������ ��������
 //---- ��������� ���� �������
 history_url = GetHistoryFileName ();
 //---- ��������� ���� ���������� 
 backtest_file = GetBackTestFileName ();
 //---- ��������� ���� ������ url �������  ������ ��������
 url_list = GetBacktestUrlList ();
 //---- ��������� ������ ���������� TAKI
 url_TAKI = GetTAKIUrl();
 //---- �������� ������� ������� �� ����� 
 flag = backtest.LoadHistoryFromFile(history_url,time_from,time_to);
 //---- ���� ������� ������������ ��������
 if (flag)
 {
  //---- ��������� ���� ������ URL ������� ���������
  file_handle = CreateFileW(url_list, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);
  //---- ��������� ���� ��������
  backtest.SaveBackTestToFile(backtest_file,_Symbol,_Period,expert_name);
  //---- ��������� URL � ���� ������ URL ��������
  Comment("");
  WriteTo(file_handle,file_catalog+"\ ");  
  //---- ��������� ��� ��������, ������ � ������ � ���� ������ 
 // Comment("");
 // WriteTo(file_handle,expert_name+"-"+_Symbol+"-"+PeriodToString(_Period)+" ");     
  Comment("");
  WriteTo(file_handle,backtest_file+" ");
  //---- ��������� ���� ������ URL
  CloseHandle(file_handle);
  //---- ��������� ���������� ����������� ����������� ��������
  StringToCharArray ( url_TAKI,val);
  WinExec(val, 1);
 }
 else
 {
  Comment("�� ������� ������� ������� �� �����");
 }
}
  /*
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
}  */