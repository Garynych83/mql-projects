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
#include <kernel32.mqh>     
//+------------------------------------------------------------------+
//| ������ ��������� ���������� ���������� ����������                |
//+------------------------------------------------------------------+

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
  //---- ��������� ���������� URL ������� 
  Comment("");
  WriteTo(file_handle,"1 ");    
  //---- ��������� ��� ��������, ������ � ������ � ���� ������ 
  Comment("");
  WriteTo(file_handle,expert_name+"-"+_Symbol+"-"+PeriodToString(_Period)+" ");     
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
