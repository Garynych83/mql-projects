//+------------------------------------------------------------------+
//|                                                  GetBackTest.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
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
 };
 
input EXPERT_NAME expert_name=0;                 //��� �������� 
input string symbol="EURUSD";                    //������
input ENUM_TIMEFRAMES InpLoadedPeriod=PERIOD_H1; //������
input datetime time_from=0;                      //����� � �������� ��������� ��������� ��������
input datetime time_to=0;                        //�����, �� ����� ���������� ��������� ��������

string historyList[]; //������ ��� �������� ���� ������ ������� 

BackTest backtest;   //������ ������ ��������

Panel * panel;

//---- ������� ���������� ����� ����� �������

string GetHistoryFileName ()
 {
  string str;
  str = StringFormat("%s\\%s\\%s_%s_%s.csv", MQL5InfoString(MQL5_PROGRAM_NAME), name, EXPERT_NAME, StringSubstr(Symbol(),0,6), PeriodToString(InpLoadedPeriod));
  return str;
 }
 
//---- ������� ���������� ������ ������ �������

bool  ReadHistoryList ()
 {
   
 }


void OnStart()
  {
   //---- ���������� ������
   uint index;
   //---- ���� ������� ��������� ����� �� ������� ������ ������� 
   if (ReadHistoryList () )
    {
     //---- �������� �� ����� ������ ���� ������
     for(index=0;index<ArraySize(historyList);index++)
      {
       //---- ��������� ���� ������� � �������
       if (backtest.LoadHistoryFromFile(historyList[index]) )
        {
         //---- ���� �������� ������ �������
         //---- �� ��������� �������� ��������
         //---- � ��������� ���� �����������
         backtest.SaveBackTestToFile();
        }
       else
        return;
      }
    }
    
  }