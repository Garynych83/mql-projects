//+------------------------------------------------------------------+
//|                                                     EXPECTOR.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <Constants.mqh>
#include <TradeManager\Backtest.mqh>
//+------------------------------------------------------------------+
//| �����, ����������� ������ ���������� ��������� �� ��������       |
//+------------------------------------------------------------------+

// �������� ������������� ���������
input double max_drawdown = 1;  // ������������ ������� ��������

// ���������� ���������� ����������
datetime time_from; // �����, � �������� ������ ��������� ������� �� �����
BackTest backtest;  // ������ ��������


//---- ������� ���������� ������ ����� ������� 
string GetFileHistory (string from_var)
 {
  string expertName = StringSubstr(from_var,1,StringFind(from_var,"_")-1);
  return expertName+"//"+"History"+"//"+StringSubstr(from_var,1)+".csv";
 } 

int OnInit()
  {
   // ��������� ����� ��� ������� ����������
   time_from = TimeCurrent();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   
  }

void OnTick()
  {
   int index;                             // ������ ����� �� ���������� ����������
   int totalVar = GlobalVariablesTotal(); // ���������� ���������� ����������
   string file_history;                   // ������, ���������� ��� ����� �������
   datetime  current_time;                // ������� ����� 
   double    current_profit;              // ������� �������
   double    current_drawdown;            // ������� �������� �� �������
   // �������� �� ���� ���������� ����������
   for (index = 0; index < totalVar; index++)
    {
     // ���� ���������� ����������-���� ������ ���� ��������
     if (StringSubstr(GlobalVariableName(index), 0, 1) == "&")
      {      
        // ���� ������� ������� ���-�� � ������� �������
        if (GlobalVariableGet(GlobalVariableName(index)) == TradeModeToInt(TM_DEAL_DONE) )
         {
           // ���������� ��� ����� �������
           file_history = GetFileHistory(GlobalVariableName(index));
           // ��������� ������� ������� �� �����  
           backtest.LoadHistoryFromFile(file_history,time_from,TimeCurrent());
           // ��������� ������� �������� �� �������
           current_drawdown = backtest.GetMaxDrawdown();
           // ���� ��������� ��������� ���������� ��������� 
           if (current_drawdown > max_drawdown)
            {
             // �� ���������� ���������� � CANNOT_TRADE, �.�. ��������� �������� ��������
             GlobalVariableSet(GlobalVariableName(index), TradeModeToInt(TM_CANNOT_TRADE) );
            }
           else
            {
             // �� ���������� ���������� � ����� "�� ���� ����� ������"
             GlobalVariableSet(GlobalVariableName(index), TradeModeToInt(TM_NO_DEALS) );            
            }
         }
      }  
    } 
 
  }
