//+------------------------------------------------------------------+
//|                                                   TALES_STAT.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
#include <CompareDoubles.mqh>                                           // ��� ��������� ������������ �����
#include <StringUtilities.mqh> 

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+


input datetime  start_time  = 0;   // ����� ������ �������� �������
input datetime  finish_time = 0;   // ����� ���������� �������� �������

MqlRates rates_array[];  // ������������ ������ ���������

int    copiedRates;      

// ������ ��������
string symbolArray[6] =
 {
  "EURUSD",
  "GBPUSD",
  "USDCHF",
  "USDJPY",
  "USDCAD",
  "AUDUSD"
 };
// ������ ��������
ENUM_TIMEFRAMES periodArray[20] =
 {
   PERIOD_M1,
   PERIOD_M2,
   PERIOD_M3,
   PERIOD_M4,
   PERIOD_M5,
   PERIOD_M6,
   PERIOD_M10,
   PERIOD_M12,
   PERIOD_M15,
   PERIOD_M20,
   PERIOD_M30,
   PERIOD_H1,
   PERIOD_H2,
   PERIOD_H3,
   PERIOD_H4,
   PERIOD_H6,
   PERIOD_H8,
   PERIOD_D1,
   PERIOD_W1,
   PERIOD_MN1  
 };
 
void OnStart()
  {
     int i_per;              // ������� ������� �� ��������
     int i_sym;              // ������� ������� �� ��������
     int i_spread;           // ������� ������� �� ���������� ������� 
     int index;              // ������� ������� �� �����
     int n_stat = 0;         // ���������� ���������
     int file_handle;        // ����� ����� ����������

     
     double countA      = 0;       // ������� ���������� ��������� �������� 1-�� ����
     double countB      = 0;       // ������� ���������� ��������� �������� 2-�� ����
     double countWin    = 0;       // ������� ���������� ���������� ��������
     double averLossSpreads = 0;   // ������� ������ ������� � �������
     double averWinSpreads  = 0;   // ������� ������ ������� � �������
     double spreadsLoss     = 0;   // �������� �� �������
     
     double win;                   // ��������� �������
     double lose;                  // ���������� ������
     double percent;               // ��������� ������� � �����
     
     int countCount = 0;
     
      // ������� ���� ���������� 
      file_handle = FileOpen("TAKIE_DELA.txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, " ");
      if (file_handle == INVALID_HANDLE) //�� ������� ������� ����
        {
         Alert("������ �������� �����");
         return;
        }  
         
    for (i_spread = 1; i_spread <= 50; i_spread++)
     {
     n_stat  = 0;
     for (i_sym=0;i_sym<6;i_sym++)
      { 
       for (i_per=0;i_per<20;i_per++)
        {     
          // ������� ������
          ArrayFree(rates_array);
          
          // ��������� ����         
          copiedRates  = CopyRates(symbolArray[i_sym], periodArray[i_per],start_time, finish_time, rates_array);
  
          spreadsLoss = 0;  // �������� ���������� ����������� �������
          
          for (index=0;index<copiedRates;index++)
           {
              if (GreatDoubles(rates_array[index].high, rates_array[index].open+i_spread*rates_array[index].spread*_Point) )
               {          
                countA  = countA  + 1;  // ����������� ���������� ��������� 
                spreadsLoss = spreadsLoss + rates_array[index].spread*_Point; // ����������� ������ �� �����
               }
              else
               {
                if (GreatDoubles(rates_array[index].close, rates_array[index].open) )
                 {
                  countB = countB + 1; // ����������� ���������� ���������
                  spreadsLoss = spreadsLoss + rates_array[index].spread*_Point;  // ����������� ������ � �������
                  if (rates_array[index].spread > 0)
                   averLossSpreads = averLossSpreads + (rates_array[index].close-rates_array[index].open/*+rates_array[index].spread*_Point*/)/(rates_array[index].spread*_Point);      
                 }
                if (LessDoubles(rates_array[index].close, rates_array[index].open)  )
                 {
                  countWin = countWin + 1;     // ����������� ���������� ����������
                  spreadsLoss = spreadsLoss + rates_array[index].spread*_Point;  // ����������� ������ � �������            
                  if (rates_array[index].spread > 0)
                    averWinSpreads = averWinSpreads + (rates_array[index].open/*+rates_array[index].spread*_Point*/ - rates_array[index].close)/(rates_array[index].spread*_Point);                 
                 }
               } 
               
                                  
                          
           }  
           
           
            
           win             = averWinSpreads;  // ���������� ����� ������
           
           lose            = countA*i_spread + spreadsLoss + averLossSpreads;   // ��������� �����
            
            
           Comment("�����������: ",countCount,"/6000");
           countCount++;
           if (lose > 0)
            percent =  win / lose; // �������� ����������� ������� � ������
           
if (GreatOrEqualDoubles(averLossSpreads,1.5) )
 {           
  FileWriteString(file_handle,"["+symbolArray[i_sym]+","+PeriodToString(periodArray[i_per])+"]\n");
  FileWriteString(file_handle,"SPREAD = "+i_spread+"\n");       
  FileWriteString(file_handle,"��������� ������� � ������: "+DoubleToString(percent) + "\n\n");   
 }
     // �������� ��������
     countA = 0;
     countB = 0;
     countWin = 0;
     averLossSpreads = 0;
     averWinSpreads  = 0;         
           
           n_stat ++; // ����������� ���������� ���������
         
         }    
    
        }
        
       
      
      }   
   
      FileClose(file_handle);
  }