//+------------------------------------------------------------------+
//|                                                  GetBackTest.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <TradeManager\BackTest.mqh> //���������� ���������� ��������
#include <StringUtilities.mqh>       //���������� ���������� ��������

//+------------------------------------------------------------------+
//| ������ ���������� ����������� ��������                           |
//+------------------------------------------------------------------+

//---- ������� ��������� �������

//---- ������������ ���������

enum EXPERT_NAME
 {
  FollowWhiteRabbit=0, //������
  Condom,              //������
  Dinya,               //�����
  Sanya,               //����
  TIHIRO,              //������
 };
 
input EXPERT_NAME expert_name=0;                 //��� �������� 
input string symbol="EURUSD";                    //������
input ENUM_TIMEFRAMES InpLoadedPeriod=PERIOD_H1; //������
input datetime time_from=0;                      //����� � �������� ��������� ��������� ��������
input datetime time_to=0;                        //�����, �� ����� ���������� ��������� ��������

BackTest backtest;   //������ ������ ��������

string GetExpertName()
 {
  switch (expert_name)
   {
    case FollowWhiteRabbit:
     return "FollowWhiteRabbit";
    break;
    case Condom:
     return "Condom";
    break;
    case Dinya:
     return "Dinya";
    break;
    case Sanya:
     return "Sanya";
    break;
    case TIHIRO:
     return "TIHIRO";
    break;
   }
  return "";
 }

//---- ������� ���������� ����� ����� �������

string GetHistoryFileName ()
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(), "History", GetExpertName(), StringSubstr(symbol,0,6), PeriodToString(InpLoadedPeriod));
  return str;
 }
 
//---- ������� ���������� ����� ����� ����������� ���������� �������� 
 
string GetBackTestFileName ()
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(), "Backtest", GetExpertName(), StringSubstr(symbol,0,6), PeriodToString(InpLoadedPeriod));
  return str;
 } 
 
//---- ������� ���������� ������ ������ �������

bool  ReadHistoryList ()
 {
  return (true);  
 }


void OnStart()
  {
   string historyFile;
   string backtestFile;
   bool flag;
   //---- �������� ��� ����� �������
   historyFile  = GetHistoryFileName ();
   //---- �������� ��� ����� ��������
   backtestFile = GetBackTestFileName ();
   //---- ��������� ���� �������
   flag = backtest.LoadHistoryFromFile(historyFile,time_from,time_to);
   //---- ��������� ���� �������
   if (flag == true )
   //---- ���� ���� ������� ������� ���������
    {
     //---- �� ��������� ��������� �������� � ��������� �� � ����
     backtest.SaveBackTestToFile(backtestFile,symbol);
    }
  }