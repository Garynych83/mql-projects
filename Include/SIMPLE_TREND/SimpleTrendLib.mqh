//+------------------------------------------------------------------+
//|                                               SimpleTrendLib.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ���������� ��� �������� ������ ������ Simple Trend               |
//+------------------------------------------------------------------+

// ������������ � ���������
enum ENUM_TENDENTION
 {
  TENDENTION_NO = 0,     // ��� ���������
  TENDENTION_UP,         // ��������� �����
  TENDENTION_DOWN        // ��������� ����
 };
// ��������� ��������
#define BUY   1    
#define SELL -1 
#define NO_POSITION 0