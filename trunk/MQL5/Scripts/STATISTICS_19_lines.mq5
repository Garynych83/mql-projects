//+------------------------------------------------------------------+
//|                                          STATISTICS_19_lines.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 

#include <ExtrLine\CExtremumCalc_NE.mqh>
#include <Lib CisNewBar.mqh>
#include <CheckHistory.mqh>


//+------------------------------------------------------------------+
//| ������ �������� ���������� 19 �����                              |
//+------------------------------------------------------------------+


// ��� ������
enum ENUM_LEVEL_TYPE
{
 EXTR_MN, 
 EXTR_W1,
 EXTR_D1,
 EXTR_H4,
 EXTR_H1
};

// ������������ ����� ��������� ���� ������������ ������
enum ENUM_LOCATION_TYPE
 {
  LOCATION_ABOVE=0,  // ���� ������
  LOCATION_BELOW,    // ���� ������
  LOCATION_INSIDE    // ������ ������
 };

// �������� ��������� �������
sinput string  stat_str="";                      // ��������� ���������� ����������
input datetime start_time = D'2012.01.01';       // ��������� ����
input datetime end_time   = D'2014.04.01';       // �������� ����
input string   file_name  = "STAT_19_LINES"; // ��� ����� ����������

sinput string atr_str = "";                      // ��������� ���������� ��R
input int    period_ATR = 30;                    // ������ ATR ��� ������
input double percent_ATR = 0.5;                  // ������ ������ ������ � ��������� �� ATR
input double precentageATR_price = 1;            // �������� ATR ��� ������ ����������
input ENUM_LEVEL_TYPE level = EXTR_H4;           // ��� ������

// ��������� ���������� �������
SExtremum estruct[3];
ENUM_TIMEFRAMES period_current = Period(); // ������� ������
ENUM_TIMEFRAMES period_level;
CisNewBar is_new_level_bar;

int  countDownUp   = 0;                          // ���������� �������� ����� �����
int  countUpDown   = 0;                          // ���������� �������� ������ ����
int  countUpUp     = 0;                          // ���������� �� �������� ������
int  countDownDown = 0;                          // ���������� �� �������� �����
 
// ����� ���������� 19 lines
int      handle_19Lines;

// ������������ ������
double   buffer_19Lines_price1[];
double   buffer_19Lines_price2[];
double   buffer_19Lines_price3[];
double   buffer_19Lines_atr1  [];
double   buffer_19Lines_atr2  [];
double   buffer_19Lines_atr3  [];
// ����� ��� �� ��������� ����������
MqlRates buffer_price[];  
       
// ������ ���������� ��������� ���� ������������ �������
ENUM_LOCATION_TYPE  prevLocLevel1;    // ���������� ��������� ���� ������������ 1-�� ������
ENUM_LOCATION_TYPE  prevLocLevel2;    // ���������� ��������� ���� ������������ 2-�� ������
ENUM_LOCATION_TYPE  prevLocLevel3;    // ���������� ��������� ���� ������������ 3-�� ������
// ������ ������� ��������� ���� ������������ �������
ENUM_LOCATION_TYPE  curLocLevel1;     // ������� ��������� ���� ������������ 1-�� ������
ENUM_LOCATION_TYPE  curLocLevel2;     // ������� ��������� ���� ������������ 2-�� ������
ENUM_LOCATION_TYPE  curLocLevel3;     // ������� ��������� ���� ������������ 3-�� ������
// ����� ��������� ���� � �������
bool standOnLevel1;                   // ���� ��������� � ������� 1
bool standOnLevel2;                   // ���� ��������� � ������� 2
bool standOnLevel3;                   // ���� ��������� � ������� 3
// �������� �������� ���������� ����� ������ �������
int countBarsInsideLevel1=0;          // ������ ������� ������
int countBarsInsideLevel2=0;          // ������ ������� ������
int countBarsInsideLevel3=0;          // ������ �������� ������

// ������ ������ ����������
int fileHandle;                       // ����� ����� ����������
int fileTestStat;                     // ����� ����� �������� ���������� ����������� �������

void OnStart()
  {
   // ���������� ��� ���������� �������� �������� ������� �����������
   int size1;
   int size2;
   int size3;
   int size4;
   int size5;
   int size6;
   int size_price;
   int start_index_buffer = 6; // ������ ����� ������ ������� ��� 3 ����� ������ 
   int bars;                    // ���������� ����� ����� 
   

   // ��������� ���������� ��� �������� �� ������
   double   tmpPrice1 = 1.38660;      // ��������� ���� ������ 1 (�������)
   double   tmpZone1  = 5;            // ��������� �������� �� ����   
   double   tmpPrice2 = 1.38640;      // ��������� ���� ������ 2 (�������)
   double   tmpZone2  = 5;            // ��������� �������� �� ����     
   double   tmpPrice3 = 1.38625;      // ��������� ���� ������ 3 (������)
   double   tmpZone3  = 5;            // ��������� �������� �� ����       
   // ������� ����� ���������� 19 �����            
   handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, false, clrRed, true, clrRed, false, clrRed, false, clrRed, false, clrRed, false, clrRed); 
   if (handle_19Lines == INVALID_HANDLE)
     {
      PrintFormat("�� ������� ������� ����� ����������");
      return;
     }
    // ������� ����� ����� ������������ ���������� ����������� �������
    fileTestStat = FileOpen(file_name+"_test.txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
    if (fileTestStat == INVALID_HANDLE) //�� ������� ������� ����
     {
      Print("�� ������� ������� ���� ������������ ���������� ����������� �������");
      return;
     }       
 
   for (int i = 0; i < 5; i++)
    {
     Sleep(1000);
     size1 = CopyBuffer(handle_19Lines, start_index_buffer    , start_time, end_time, buffer_19Lines_price1);
     size2 = CopyBuffer(handle_19Lines, start_index_buffer + 1, start_time, end_time, buffer_19Lines_atr1);
     size3 = CopyBuffer(handle_19Lines, start_index_buffer + 2, start_time, end_time, buffer_19Lines_price2);
     size4 = CopyBuffer(handle_19Lines, start_index_buffer + 3, start_time, end_time, buffer_19Lines_atr2);
     size5 = CopyBuffer(handle_19Lines, start_index_buffer + 4, start_time, end_time, buffer_19Lines_price3);
     size6 = CopyBuffer(handle_19Lines, start_index_buffer + 5, start_time, end_time, buffer_19Lines_atr3);
     size_price = CopyRates(_Symbol,PERIOD_M1,start_time,end_time,buffer_price);
     PrintFormat("bars = %d | size1=%d / size2=%d / size3=%d / size4=%d / size5=%d / size6=%d / sizePrice=%d", BarsCalculated(handle_19Lines), size1, size2, size3, size4, size5, size6,size_price);
    }   
    // �������� ���������� ����� �����������
    bars = Bars(_Symbol,PERIOD_M1,start_time,end_time);
    // �������� �� �������� ���� ������� 
    if ( size1!=bars || size2!=bars || size3!=bars ||size4!=bars||size5!=bars||size6!=bars||size_price!=bars)
      {
       Print("�� ������� ���������� ��� ������ ����������");
       return;
      }
    // ��������� ������� ��������� ���� ������������ �������
    prevLocLevel2 = GetCurrentPriceLocation(buffer_price[0].open,buffer_19Lines_price2[0],buffer_19Lines_atr2[0]);  
    prevLocLevel3 = GetCurrentPriceLocation(buffer_price[0].open,buffer_19Lines_price3[0],buffer_19Lines_atr3[0]);            
    // ���������� ����� ���������� � ���� ������ � false
    standOnLevel2  = false;
    standOnLevel3  = false;
          Comment("���� �� ������ 1 = ",buffer_19Lines_price1[bars-1]," ����� �� ������ 1 = ",buffer_19Lines_atr1[bars-1],
                  "\n���� �� ������ 2 = ",buffer_19Lines_price2[bars-1]," ����� �� ������ 2 = ",buffer_19Lines_atr2[bars-1],
                  "\n���� �� ������ 3 = ",buffer_19Lines_price3[bars-1]," ����� �� ������ 3 = ",buffer_19Lines_atr3[bars-1]);   
    // �������� �� ���� ����� ����  � ������� ���������� �������� ����� ������
    for (int index=1;index < bars; index++)
       {
        
        /////��� ������� ������//////        
      /*         
        curLocLevel2 = GetCurrentPriceLocation(buffer_price[index].close,buffer_19Lines_price2[index],buffer_19Lines_atr2[index]);
        
        if (curLocLevel2 == LOCATION_INSIDE) 
         {
           // ���� ��� � Open ��������� ������ ������
           if (GetCurrentPriceLocation(buffer_price[index].open,buffer_19Lines_price2[index],buffer_19Lines_atr2[index])  == LOCATION_INSIDE)
             countBarsInsideLevel2++;  // �� ����������� ���������� ����� ������ ������
           standOnLevel2 = true;
         }
        else 
         {   
           if (curLocLevel2 == LOCATION_ABOVE && prevLocLevel2 == LOCATION_BELOW)
              {
               countDownUp ++;
               Print("������� ������ ����� ����� � ",buffer_price[index].time," ���������� ����� ������ ������ = ",countBarsInsideLevel2);
              }
           if (curLocLevel2 == LOCATION_BELOW && prevLocLevel2 == LOCATION_ABOVE)
              {
               countUpDown ++;
               Print("������� ������ ������ ���� � ",buffer_price[index].time," ���������� ����� ������ ������ = ",countBarsInsideLevel2); 
              }
           if (curLocLevel2 == LOCATION_ABOVE && prevLocLevel2 == LOCATION_ABOVE && standOnLevel2)
              {
               countUpUp ++;
               Print("������� �������� ������ �����",buffer_price[index].time," ���������� ����� ������ ������ = ",countBarsInsideLevel2); 
              }
           if (curLocLevel2 == LOCATION_BELOW && prevLocLevel2 == LOCATION_BELOW && standOnLevel2)
              {
               countDownDown ++;
               
               Print("������� �������� ����� ����",buffer_price[index].time," ���������� ����� ������ ������ = ",countBarsInsideLevel2);                
              }
           // �������� ������� ����� ������ ������
           countBarsInsideLevel2 = 0;   
           prevLocLevel2 = curLocLevel2;
           standOnLevel2 = false;
         }   ///END ��� ������� ������
         
         */
         /////��� �������� ������//////        
              
        curLocLevel3 = GetCurrentPriceLocation(buffer_price[index].close,buffer_19Lines_price3[index],buffer_19Lines_atr3[index]);
        
        if (curLocLevel3 == LOCATION_INSIDE) 
         {
           // ���� ��� � Open ��������� ������ ������
           if (GetCurrentPriceLocation(buffer_price[index].open,buffer_19Lines_price3[index],buffer_19Lines_atr3[index])  == LOCATION_INSIDE)
             countBarsInsideLevel3++;  // �� ����������� ���������� ����� ������ ������
           standOnLevel3 = true;
         }
        else 
         {   
           if (curLocLevel3 == LOCATION_ABOVE && prevLocLevel3 == LOCATION_BELOW)
              {
               countDownUp ++;
               FileWriteString(fileTestStat,"\n���� ������ ����� ����� � "+TimeToString(buffer_price[index].time)+"; ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3));
              }
           if (curLocLevel3 == LOCATION_BELOW && prevLocLevel3 == LOCATION_ABOVE)
              {
               countUpDown ++;
               FileWriteString(fileTestStat,"\n���� ������ ������ ���� � "+TimeToString(buffer_price[index].time)+";���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3)); 
              }
           if (curLocLevel3 == LOCATION_ABOVE && prevLocLevel3 == LOCATION_ABOVE && standOnLevel3)
              {
               countUpUp ++;
               FileWriteString(fileTestStat,"\n���� �������� ������ ����� � "+TimeToString(buffer_price[index].time)+"; ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3)); 
              }
           if (curLocLevel3 == LOCATION_BELOW && prevLocLevel3 == LOCATION_BELOW && standOnLevel3)
              {
               countDownDown ++;
               
               FileWriteString(fileTestStat,"\n���� �������� ����� ���� � "+TimeToString(buffer_price[index].time)+"; ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3));                
              }
           // �������� ������� ����� ������ ������
           countBarsInsideLevel3 = 0;   
           prevLocLevel3 = curLocLevel3;
           standOnLevel3 = false;
         }   ///END ��� �������� ������        
                
         
                
       }
   Print("���������� �������� ����� ����� = ", countDownUp  );
   Print("���������� �������� ������ ���� = ", countUpDown  );
   Print("���������� ������� ������ ����� = ", countUpUp    );
   Print("���������� ������� ����� ����   = ", countDownDown);
   // ��������� ���� ������������ ���������� ����������� �������
   FileClose(fileTestStat);
   // �������� ���������� ���������� � ����
   SaveStatisticsToFile ();
 
  }
  
  
  
 // �������, ������������ ��������� ���� ������������ ��������� ������
 
 ENUM_LOCATION_TYPE GetCurrentPriceLocation (double dPrice,double price19Lines,double atr19Lines)
  {
    ENUM_LOCATION_TYPE locType = LOCATION_INSIDE;  // ���������� ��� �������� ��������� ���� ������������ ������
     if (dPrice > (price19Lines+atr19Lines))
      locType = LOCATION_ABOVE;
     if (dPrice < (price19Lines-atr19Lines))
      locType = LOCATION_BELOW;
     
    return(locType);
  }
  
  
 // ������� ���������� ����������� ���������� �� ������������ 19 lines
 
 void SaveStatisticsToFile ()
  {
    // ������� ����� ����� ����������
    fileHandle = FileOpen(file_name+".txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
    if (fileHandle == INVALID_HANDLE) //�� ������� ������� ����
     {
      Print("�� ������� ������� ���� ����������");
      return;
     }  
    FileWriteString(fileHandle,"���������� �� �������:\n\n");
    FileWriteString(fileHandle,"���������� ����������� ����� ������� ������ ����: "+IntegerToString(countUpDown));
    FileWriteString(fileHandle,"\n���������� ����������� ����� ������� ����� �����: "+IntegerToString(countDownUp));
    FileWriteString(fileHandle,"\n���������� ������� �� ������ ������ ����� : "+IntegerToString(countUpUp));
    FileWriteString(fileHandle,"\n���������� ������� �� ������ ����� ����: "+IntegerToString(countDownDown));
    // ��������� ���� ����������
    FileClose(fileHandle);            
  }