//+------------------------------------------------------------------+
//|                                         ThrowMeOnChartPlease.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <TradeManager\BackTest.mqh>  // ���������� ���������� ��������
#include <StringUtilities.mqh>        // ���������� ���������� ������ 

//+------------------------------------------------------------------+
//| ������ �������� �� ������ � ������� ��������� ����������:        |
//| - �� ���� �� �� ����� ���� ������������                          |
//| - �� ���� �� �������� �������� �����                             |
//+------------------------------------------------------------------+

//---- ������� ��������� �������

input double   min_profit=0;   // ���������� ���������� ������� ������������
input double   max_drawdown=0; // ����������� ���������� ������� �������� ������� 
input datetime from=0;         // ������ � ������
input datetime to=0;           // �� �����


//---- ������� ���������� ��� ������� �� ������ �������

string  GetExpertName ()
 {
  return "TIHIRO";
 }

//---- ������� ���������� ����� ����� �������

string GetHistoryFileName ()
 {
  string str="";
  
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", GetExpertName(), "History", GetExpertName(), _Symbol, PeriodToString(_Period));
  return str;
 }

void OnStart()
  {
   BackTest backtest;          // ������ ������ ��������
   double  drawdown;           // �������� �� �������
   double  full_profit;        // ������� 
   // �������� ��������� ������� �� �����
   
   if (backtest.LoadHistoryFromFile(GetHistoryFileName(),from,to) )
    {    
     // �������� �������� �� ������� � �������� ������� 
     drawdown = backtest.GetMaxDrawdown(_Symbol);
     // �������� �������� �������
     full_profit = backtest.GetTotalProfit(_Symbol);
     // ���� ������� ��������� ���������� ����� ��� �������� ������� ������ ����������� ��������  
     if (drawdown > max_drawdown || full_profit < min_profit)
      {
       Alert("�������� ���������� ����������");
      }
     else
      {
       Alert("������� ����� ���������� ��������");
      }
    }
  }
