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
  "GPBUSD",
  "USDCHF",
  "USDJPY",
  "USDCAD",
  "AUDUSD"
 };

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