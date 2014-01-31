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
#include <kernel32.mqh>                 //��� WIN API �������
 
//+------------------------------------------------------------------+
//| ������ ��������� ���������� ���������� ����������                |
//+------------------------------------------------------------------+

// ���������, �������� �������������

input string   file_catalog = "C:\\Taki";              // ����� �������� � ���������� TAKI
input string   catalog_url  = "";                      // ����� �������� � ������� �������
input datetime time_from    = 0;                       // � ������ �������
input datetime time_to      = 0;                       // �� ����� �����
 
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
   return file_catalog+"/"+"_backtest_.dat";
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


// ����� ��������� ���� ������ ������� � �������� 
void GetAllCatalog()
{
 int win32_DATA[79];
 int handle;
 int url_handle;     // ����� �����, ����������� url ������ ����������� ��������
 string file_url;    // url ����� �����
 //��������� ����  
 ArrayInitialize(win32_DATA,0); 
 //---- ���� ������ ���� 
 handle = FindFirstFileW(catalog_url+"*.csv", win32_DATA);
 //---- ��������� ���� ������ URL ������� ���������  
 url_handle  = CreateFileW(GetBacktestUrlList(), _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);
 
 if(handle!=-1)
 {
  file_url = bufferToString(win32_DATA);
  //---- ���� ���� ������
  if (CreateBackTestFile(file_url) )  // ��������� ������� �� ����� 
   {
    Comment("");
    WriteTo(file_handle,backtest_file+" ");
   }
  ArrayInitialize(win32_DATA,0);
 // ��������� ��������� �����
 while(FindNextFileW(handle, win32_DATA))
 {
  file_url = bufferToString(win32_DATA); 
  CreateBackTestFile(file_url);
  ArrayInitialize(win32_DATA,0);
 }
 if (handle > 0) FindClose(handle);
 }
 // ��������� ���� ������ url ������
 CloseHandle(url_handle);
}

// ����� ��������� ����� �������

bool CreateBackTestFile (string fileHandle)
{
 bool flag;
 //---- �������� ������� ������� �� ����� 
 flag = backtest.LoadHistoryFromFile(fileHandle,time_from,time_to);
//---- ���� ������� ������������ ��������
 if (flag)
 {
  //---- ��������� ���� ������ URL ������� ���������
  file_handle = CreateFileW(url_list, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);
  //---- ��������� ���� ��������
  backtest.SaveBackTestToFile(backtest_file,_Symbol,_Period,expert_name);
  //---- ��������� URL � ���� ������ URL ��������
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

//+------------------------------------------------------------------+
//|  ��������� int ������ � ������                                   |
//+------------------------------------------------------------------+ 
string bufferToString(int &fileContain[])
   {
   string text="";
   
   int pos = 10;
   for (int i = 0; i < 64; i++)
      {
      pos++;
      int curr = fileContain[pos];
      text = text + CharToString(curr & 0x000000FF)
         +CharToString(curr >> 8 & 0x000000FF)
         +CharToString(curr >> 16 & 0x000000FF)
         +CharToString(curr >> 24 & 0x000000FF);
      }
   return (text);
