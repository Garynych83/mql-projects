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
#include <Charts\Chart.mqh>


//+------------------------------------------------------------------+
//| ������ ���������� ����������� ��������                           |
//+------------------------------------------------------------------+

//---- ������ ���� ���������

string expert_array[5] =
{
"FollowWhiteRabbit",
"condom",
"Dinya",
"Sanya",
"TIHIRO"
}; 
 
//---- ������ ��������

string symbol_array[6] = 
{
"EURUSD",
"GBPUSD",
"USDCHF",
"USDJPY",
"USDCAD",
"AUDUSD"
};
 
input datetime time_from=0;                      //����� � �������� ��������� ��������� ��������
input datetime time_to=0;                        //�����, �� ����� ���������� ��������� ��������

string historyList[]; //������ ��� �������� ���� ������ ������� 

BackTest backtest;   //������ ������ ��������

CChart obj = new CChart();

//---- ������� ���������� ��� ��������

string GetExpertName(uint num)
 {
  return expert_array[num];
 }
 
//---- ������� ���������� ������

string GetSymbolName(uint num)
 {
  return symbol_array[num];
 }

//---- ������� ���������� ����� ����� �������

string GetHistoryFileName (uint exp_num,uint sym_num,ENUM_TIMEFRAMES  tf_num)
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(exp_num), "History", GetExpertName(exp_num), GetSymbolName(sym_num), PeriodToString(tf_num));
  return str;
 }
 
//---- ������� ���������� ����� ����� ����������� ���������� �������� 
 
string GetBackTestFileName (uint exp_num,uint sym_num,ENUM_TIMEFRAMES tf_num)
 {
  string str="";
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(exp_num), "Backtest", GetExpertName(exp_num), GetSymbolName(sym_num), PeriodToString(tf_num));
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
   uint expert_num;     //���������� ��� �������� ���� ���������
   uint symbol_num;     //���������� ��� �������� ��������
   ENUM_TIMEFRAMES timeframe_num;  //���������� ��� �������� �����������
   //---- �������� �� ������ � ���������� ��������� �������� ������
   
   Alert("��� ��������� = ",MQL5InfoString(MQL5_PROGRAM_NAME));   
   
   obj.GetString(
   
   //---- �������� �� ������ ���������
    for (expert_num=0; expert_num < 5; expert_num++)
     {
      //---- �������� �� ��������
      for (symbol_num=0; symbol_num < 6; symbol_num++)
       {
        //---- �������� �� ���� �������
        for (timeframe_num=0; timeframe_num < 20; timeframe_num++)
         {
 
          //---- �������� ��� ����� �������
          historyFile  = GetHistoryFileName (expert_num,symbol_num,timeframe_num);
          //---- �������� ��� ����� ��������
          backtestFile = GetBackTestFileName (expert_num,symbol_num,timeframe_num);
          //---- ��������� ���� �������
          flag = backtest.LoadHistoryFromFile(historyFile,time_from,time_to);
          //---- ��������� ���� �������
          if (flag == true )
          //---- ���� ���� ������� ������� ���������
           {
            //---- �� ��������� ��������� �������� � ��������� �� � ����
            backtest.SaveBackTestToFile(backtestFile,GetSymbolName(symbol_num));
         //   backtest.SaveArray("new_history.csv");
           }
          
         }    
       } 
     }
  }