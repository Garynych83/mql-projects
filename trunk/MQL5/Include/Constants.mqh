//+------------------------------------------------------------------+
//|                                                    Constants.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ���� � ����������� � ������� ����������                          |
//+------------------------------------------------------------------+

// ������������� �������� 

// ��������� ��������
#define BUY   1    
#define SELL -1

// ������� ���� ��� ������ �����
double lotsArray[6] =
 {
  100000,
  100000,
  100000,
  100000,
  100000,
  100000
 };
// ������ ��������
string symArray[6] = 
 {
  "EURUSD",
  "GBPUSD",
  "USDCHF",
  "USDJPY",
  "USDCAD",
  "AUDUSD"
 };
 
// ������������ ������� �������� ��������
enum  TRADE_MODE 
 {
  TM_NO_DEALS     = 0,
  TM_DEAL_DONE    = 1,
  TM_CANNOT_TRADE = 2
 };
 
// ������� �������� TRADE_MODE � int
int  TradeModeToInt (TRADE_MODE tm)
 {
  switch (tm)
   {
    case TM_NO_DEALS:
     return 0;
    break;
    case TM_DEAL_DONE:
     return 1;
    break;
    case TM_CANNOT_TRADE:
     return 2;
    break;
   }
  return -1;
 }  

// ������� ������ ������ � �������
int ArraySearchString (string  &strArray[],string str)
 {
  int index;
  int length = ArraySize(strArray); // ����� �������
  for (index=0;index<length;index++)
   {
    // ���� ����� ������� ���������� �������
    if (strArray[index] == str)
     {
      // ���������� ������ ����� ��������
      return index;
     }
   }
  return -1; // �� ������ ������� �������
 }
 
// ���������� ��� �� �������
double GetLotBySymbol (string symbol)
 {
   return lotsArray[ArraySearchString(symArray,symbol)];
 } 