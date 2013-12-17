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
//| ������ ���������� ����������� �������� ��� ���������� ���������  |
//+------------------------------------------------------------------+

 
input datetime time_from=0;                      // ����� � �������� ��������� ��������� ��������
input datetime time_to=0;                        // �����, �� ����� ���������� ��������� ��������

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
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", exp_name, "Backtest", exp_name, sym, tf);
  return str;
 } 
 
//---- ������� ���������� ������ ������ �������

bool  ReadHistoryList ()
 {
  return (true);  
 }


void OnStart()
  {
   string historyFile;   // ����� ����� �������
   string backtestFile;  // ����� ����� ��������
   bool   flag;          // ���� �������� ������������� ����� �������
   uint   n_experts;     // ���������� ���������� ��������� 
   uint   index;         // ������� ��� ����������� � ����� �� �������
   
   string expert_name;   // ��� ����������� ��������
   string expert_symbol; // ������, �� �������� ������� �������
   string expert_period; // ������ (���������) �� �������� ������� �������
   
    //---- �������� ������������ � �������� ������ ���������� ���������� ���������
    expscop.DoExpertoScop();
    //---- �������� ���������� ���������� ���������
    n_experts = expscop.GetParamLength();
    
    //---- �������� �� ���� ���������� ���������� ��������� � �������� ���������
    
    for (index=0;index < n_experts; index++)
     {
      expert_name   = expscop.GetExpertName(index); // �������� ��� ��������
      expert_symbol = expscop.GetSymbol(index);     // �������� ������
      expert_period = PeriodToString(expscop.GetTimeFrame(index));  // �������� ���������
      Alert("��� �������� = ", expert_name);
      Alert("������ = ", expert_symbol);
      Alert("������ = ",expert_period);
      //---- �������� ��� ����� �������
      historyFile   = GetHistoryFileName  (expert_name,expert_symbol,expert_period);
      //---- �������� ��� ����� ��������
      backtestFile  = GetBackTestFileName (expert_name,expert_symbol,expert_period);
      //---- ��������� ���� �������
      flag = backtest.LoadHistoryFromFile(historyFile,time_from,time_to);
      //---- ��������� ���� �������
      if (flag == true )
      //---- ���� ���� ������� ������� ���������
       {
       //---- �� ��������� ��������� �������� � ��������� �� � ����
       backtest.SaveBackTestToFile(backtestFile,expert_symbol);
       }
     }
  }