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


input datetime  start_time = 0;    // ����� ������ �������� �������
input datetime  finish_time = 0;   // ����� ���������� �������� �������

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
     int n_stat = 0;         // ���������� ���������
     int file_handle;        // ����� ����� ����������

     
     double averCountA      = 0;   // ������� ���������� ���������� �������� 1-�� ����
     double averCountB      = 0;   // ������� ���������� ��������� �������� 2-�� ����
     double averCountLoss   = 0;   // ������� ���������� ��������� ��������
     double averWinSpreads  = 0;   // ������� ���������� ��������� � �������
     double averLossSpreads = 0;   // ������� ���������� ������� � �������
         
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
          // ��������� ���������� �����
          countBars = Bars(symbolArray[i_sym],periodArray[i_per],start_time,finish_time);  
         /// Alert("���������� ����� = ",countBars);       
          // ������� ������
          ArrayFree(rates_array);
          // ��������� ����     
          copiedRates  = CopyRates(symbolArray[i_sym], periodArray[i_per],start_time, finish_time, rates_array);
          if ( copiedRates < countBars)
           { // ���� �� ������� ���������� ��� ���� �������
            Alert("�� ������� ���������� ��� ���� �������");
            return;
           }   
           
          
          for (index=0;index<countBars;index++)
           {
              
             // Comment("���� = ",rates_array[index].open+i_spread*rates_array[index].spread*_Point);
              if (GreatDoubles(rates_array[index].high, rates_array[index].open+i_spread*rates_array[index].spread*_Point) )
               {
                averCountA = averCountA + 1;  // ����������� ���������� ����������     
               }
              else
               {
                if (GreatDoubles(rates_array[index].close, rates_array[index].open+rates_array[index].spread*_Point) )
                 {
                  averCountB = averCountB + 1; // ����������� ���������� ����������
                  if (rates_array[index].spread > 0)
                   averWinSpreads = averWinSpreads + (rates_array[index].close-rates_array[index].open+rates_array[index].spread*_Point)/(rates_array[index].spread*_Point);
                 
                 }
                if (LessDoubles(rates_array[index].close, rates_array[index].open+rates_array[index].spread*_Point)  )
                 {
                  averCountLoss = averCountLoss + 1;     // ����������� ���������� ���������
                  if (rates_array[index].spread > 0)
                    averLossSpreads = averLossSpreads + (rates_array[index].open+rates_array[index].spread*_Point - rates_array[index].close)/(rates_array[index].spread*_Point);                 
                 }
               } 
               
                                  
                          
           }  
           
           averCountA = averCountA*i_spread;  // �������� ���������� ��������� �������
           averCountB = averCountA + averWinSpreads; // ������� ���������
           if (averLossSpreads > 0)
            averLossSpreads =  averLossSpreads / averCountB; // �������� ����������� ������� � ������
           
if (GreatOrEqualDoubles(averLossSpreads,1.5) )
 {           
  FileWriteString(file_handle,"["+symbolArray[i_sym]+","+PeriodToString(periodArray[i_per])+"]\n");
  FileWriteString(file_handle,"SPREAD = "+i_spread+"\n");       
  FileWriteString(file_handle,"��������� ������� � ������: "+DoubleToString(averLossSpreads) + "\n\n");   
 }
     averCountA = 0;
     averCountB = 0;
     averCountLoss = 0;
     averLossSpreads = 0;
     averWinSpreads  = 0;         
           
           n_stat ++; // ����������� ���������� ���������
         
         }    
    
        }
        
        /*
         if (n_stat > 0)
           {
            averCountA = 1.0*averCountA / n_stat;
            
           }
         else
           averCountA = 0;
         if (n_stat > 0)
           {
            averCountB = 1.0*averCountB / n_stat;
            if (averCountB > 0)
             averWinSpreads = averWinSpreads / averCountB;
           }
         else
           averCountB = 0;
         if (n_stat > 0)
           {
            averCountLoss = averCountLoss / n_stat;
             if (averCountLoss > 0)
              averLossSpreads = averLossSpreads / averCountLoss;
           }
         else
           averCountLoss = 0;      
                         

        FileWriteString(file_handle,"����� = "+IntegerToString(i_spread)+"\n");
        FileWriteString(file_handle,"C������ ���������� ��������� A: "+DoubleToString(averCountA,0)+"\n");
        FileWriteString(file_handle,"C������ ���������� ��������� B: "+DoubleToString(averCountB,0)+"\n");
        FileWriteString(file_handle,"C������ ���������� �������: "+DoubleToString(averCountLoss,0)+"\n");
        FileWriteString(file_handle,"������� ���-�� ������� �������: "+DoubleToString(averWinSpreads,0)+"\n");
        FileWriteString(file_handle,"������� ���-�� ������� ������: "+DoubleToString(averLossSpreads,0)+"\n");  
        FileWriteString(file_handle,"������� ������� � ������� A: "+DoubleToString(averCountA*i_spread,0)+"\n");
        FileWriteString(file_handle,"������� ������� � ������� B: "+DoubleToString(averCountB*averWinSpreads,0)+"\n");
        FileWriteString(file_handle,"������� ������ � �������: "+DoubleToString(averCountLoss*averLossSpreads,0)+"\n");
        FileWriteString(file_handle,"��������� ������� � ������: "+DoubleToString( (averCountA*i_spread+averCountB*averWinSpreads)/(averCountLoss*averLossSpreads)) + "\n\n");              
             
   */
      
      }   
   
      FileClose(file_handle);
  }