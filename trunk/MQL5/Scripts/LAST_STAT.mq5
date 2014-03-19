//+------------------------------------------------------------------+
//|                                                   TALES_STAT.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>                                           // ��� ��������� ������������ �����

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

MqlRates rates_array[];  // ������������ ������ ���������

long   countBars;        // ���������� �����
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
     int countTales;         // ������� ����� � ��������
     int n_stat = 0;         // ���������� ���������
     double percent = 0;     // ������� ������� ��� ���� ���������
     int file_handle;        // ����� ����� ����������
     double aver_spread = 0; // ������� ������ ������
     
     int countProfitA = 0;       // ���������� ���������� �������� 1-�� ����
     int countProfitB = 0;       // ���������� ���������� �������� 2-�� ����
     int countLoss    = 0;          // ���������� ��������� ��������  
     
     bool  openedPosition = false;   // ����, ����������� ��������\�������� �������
     
     
      // ������� ���� ���������� 
      file_handle = FileOpen("OGON.txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, " ");
      if (file_handle == INVALID_HANDLE) //�� ������� ������� ����
        {
         Alert("������ �������� �����");
         return;
        }  
   
    for (i_spread = 1; i_spread <= 1000; i_spread+=10)
     {
     percent = 0;
     n_stat  = 0;
     aver_spread = 0;
     countTales = 0;

     for (i_sym=0;i_sym<6;i_sym++)
      { 
       for (i_per=0;i_per<20;i_per++)
        {
          // ��������� ���������� �����
          countBars = Bars(symbolArray[i_sym],periodArray[i_per]);         
          // ������� ������
          ArrayFree(rates_array);
          // ��������� ����     
          copiedRates  = CopyRates(symbolArray[i_sym], periodArray[i_per],0, countBars, rates_array);
          if ( copiedRates < countBars)
           { // ���� �� ������� ���������� ��� ���� �������
            Alert("�� ������� ���������� ��� ���� �������");
            return;
           }   
          
          openedPosition = false;  // ���������� �������, ��� �� �������� 
          
          for (index=0;index<countBars;index++)
           {
  
              if (  GreatDoubles(rates_array[index].high, i_spread*rates_array[index].spread*_Point+rates_array[index].open) == true  )
               {
                countProfitA ++;  // ����������� ���������� �������           
               }
              

           }  
         
         }    
    
        }
   
           if (countTales > 0)
            {
             FileWriteString(file_handle,"����� = ",IntegerToString(i_spread)+"\n");
             FileWriteString(file_handle,""+DoubleToString(aver_spread/countTales)+"\n\n");
            }
             
   
      
      }   
   
      FileClose(file_handle);
  }