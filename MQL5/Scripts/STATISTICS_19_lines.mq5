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
input string   file_name  = "STAT_19_LINES.txt"; // ��� ����� ����������

sinput string atr_str = "";                      // ��������� ���������� ��R
input int    period_ATR = 100;                   // ������ ATR ��� ������
input double percent_ATR = 0.03;                 // ������ ������ ������ � ��������� �� ATR
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
   int start_index_buffer = 0; // ������ ����� ������ ������� ��� 3 ����� ������ 
   int bars;                   // ���������� ����� ����� 
   
   handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, true, clrRed, true, clrRed, true, clrRed, true, clrRed, true, clrRed, true, clrRed); 
   if (handle_19Lines == INVALID_HANDLE)
     {
      PrintFormat("�� ������� ������� ����� ����������");
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
    prevLocLevel1 = GetCurrentPriceLocation(buffer_price[0].open,buffer_19Lines_price1[0],buffer_19Lines_atr1[0]);  
    // ���������� ����� ���������� � ���� ������ � false
    standOnLevel1  = false;
          Print("���� �� ������ = ",buffer_19Lines_price2[1]);   
    // �������� �� ���� ����� ����  � ������� ���������� �������� ����� ������
    for (int index=1;index < bars; index++)
       {
       
        curLocLevel1 = GetCurrentPriceLocation(buffer_price[index].close,buffer_19Lines_price1[index],buffer_19Lines_atr1[index]);
        if (curLocLevel1 == LOCATION_INSIDE) standOnLevel1 = true;
        else 
         {
           if (curLocLevel1 == LOCATION_ABOVE && prevLocLevel1 == LOCATION_BELOW)
              {
               countDownUp ++;
               Print("���� ������ ����� ����� � ",buffer_price[index].time);
              }
           if (curLocLevel1 == LOCATION_BELOW && prevLocLevel1 == LOCATION_ABOVE)
              {
               countUpDown ++;
               Print("���� ������ ������ ���� � ",buffer_price[index].time); 
              }
           if (curLocLevel1 == LOCATION_ABOVE && prevLocLevel1 == LOCATION_ABOVE && standOnLevel1)
              {
               countUpUp ++;
               Print("���� �������� ������ �����",buffer_price[index].time); 
              }
           if (curLocLevel1 == LOCATION_BELOW && prevLocLevel1 == LOCATION_BELOW && standOnLevel1)
              {
               countDownDown ++;
               
               Print("���� �������� ����� ����",buffer_price[index].time);                
              }
           prevLocLevel1 = curLocLevel1;
           standOnLevel1 = false;
         }        
       }
Print("���������� �������� ����� ����� = ",countDownUp);
Print("���������� �������� ������ ���� = ",countUpDown);
Print("���������� ������� ������ ����� = ",countUpUp);
Print("���������� ������� ����� ���� = ",countDownDown);

  }
  
  
  
 // �������, ������������ ��������� ���� ������������ ��������� ������
 
 ENUM_LOCATION_TYPE GetCurrentPriceLocation (double dPrice,double price19Lines,double atr19Lines)
  {
    ENUM_LOCATION_TYPE locType;  // ���������� ��� �������� ��������� ���� ������������ ������
     //if (dPrice 
    return(locType);
  }
  
  
 // ������� ���������� ����������� ���������� �� ������������ 19 lines
 
 void SaveStatisticsToFile ()
  {
    
  }