//+------------------------------------------------------------------+
//|                                                  QualityMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

#include <divergenceStochastic.mqh>

input int check_depth = 100;    //������� �������� � �����
input int kPeriod = 5;          // �-������ Stochastic
input int dPeriod = 3;          // D-������ Stochastic
input int slow  = 3;            // ����������� �������. ��������� �������� �� 1 �� 3. Stochastic
input int top_level = 80;       // top ������� Stochastic
input int bottom_level = 20;    // bottom ������� Stochastic
//input string filename = "qualityMACD.txt";

string symbol = _Symbol;
ENUM_TIMEFRAMES period = _Period;

void OnStart()
{

 //int filehandle=FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_COMMON);
 //if(filehandle == INVALID_HANDLE) {Print("Error");}
 int handleSTOC  = iStochastic(symbol, period, kPeriod, dPeriod, slow, MODE_SMA, STO_LOWHIGH);;
 int direction = 0;
 
 Print("BEGIN");
 for (int i = check_depth + 5; i > 5; i--)
 {
  direction = divergenceSTOC(handleSTOC, symbol, period, top_level, bottom_level, i);
  if(direction != 0) 
  {
   //PrintFormat("index = %d; direction = %d", i, direction);
   Quality(i-5);
  }
 } 
 Print("END");
 //FileClose(filehandle);  
}
//+------------------------------------------------------------------+
bool Quality(int start_pos)
{
 double buffer_high[5] = {0};
 double buffer_low[5] = {0};
 datetime date_buf[5] = {0};
 int copiedHigh = -1;
 int copiedLow = -1;
 int copiedDate = -1;
 for(int attemps = 0; attemps < 25 && copiedHigh < 0
                                   && copiedLow  < 0 
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedHigh = CopyHigh(symbol, period, start_pos, 5, buffer_high); 
  copiedLow  = CopyLow (symbol, period, start_pos, 5, buffer_low);
  copiedDate = CopyTime(symbol, period, start_pos, 5, date_buf); 
 }
 if (copiedHigh != 5 || copiedLow != 5)
 {
   int err = GetLastError();
   Alert(__FUNCTION__, "�� ������� ����������� ������ ��������� ���������. Error = ", err);
   return(false);
 }
 
 double highhigh = buffer_high[ArrayMaximum(buffer_high)];
 double lowlow = buffer_low[ArrayMinimum(buffer_low)];
 PrintFormat("%d | ���������� �� ����� �  %s �� %s: HighHigh = %f; LowLow = %f", start_pos, TimeToString(date_buf[0]), TimeToString(date_buf[4]), highhigh, lowlow);
 return(true);
}