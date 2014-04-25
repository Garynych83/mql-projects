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

bool level_one_UD   = false;
bool level_one_DU   = false;

bool level_two_UD   = false;
bool level_two_DU   = false;

bool level_three_UD = false;
bool level_three_DU = false;

double count_DUU = 0;   // ���������� �������� ����� �����
double count_DUD = 0;   // ���������� �� �������� ����� �����
double count_UDD = 0;   // ���������� �������� ������ ����
double count_UDU = 0;   // ���������� �� �������� ������ ����
 
// ����� ���������� 19 lines
int      handle_19Lines;

// ������������ ������
datetime buffer_time[];
double   buffer_19Lines_price1[];
double   buffer_19Lines_price2[];
double   buffer_19Lines_price3[];
double   buffer_19Lines_atr1  [];
double   buffer_19Lines_atr2  [];
double   buffer_19Lines_atr3  [];
// ����� ��� �� ��������� ����������
MqlRates buffer_price[];  
// ���������� ������� � �������� ���������� (��� ������� ������)
int      nBarsOfM1;         

//+------------------------------------------------------------------+
//| ������ �������� ���������� 19 �����                              |
//+------------------------------------------------------------------+

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
   int bars;                   // ���������� ����� ����� (�� �����������)
   int barsPrice;              // ���������� ����� ���� �� �������� ����������
   
   handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, true, clrRed, true, clrRed, true, clrRed, true, clrRed, true, clrRed, true, clrRed); 
   if (handle_19Lines == INVALID_HANDLE)
     {
      PrintFormat("�� ������� ������� ����� ����������");
      return;
     }
      PrintFormat("����� ������. �������");
 
   for (int i = 0; i < 5; i++)
    {
     Sleep(1000);
     size1 = CopyBuffer(handle_19Lines, start_index_buffer     , start_time, end_time, buffer_19Lines_price1);
     size2 = CopyBuffer(handle_19Lines, start_index_buffer + 1, start_time, end_time, buffer_19Lines_atr1);
     size3 = CopyBuffer(handle_19Lines, start_index_buffer + 2, start_time, end_time, buffer_19Lines_price2);
     size4 = CopyBuffer(handle_19Lines, start_index_buffer + 3, start_time, end_time, buffer_19Lines_atr2);
     size5 = CopyBuffer(handle_19Lines, start_index_buffer + 4, start_time, end_time, buffer_19Lines_price3);
     size6 = CopyBuffer(handle_19Lines, start_index_buffer + 5, start_time, end_time, buffer_19Lines_atr3);
     size_price = CopyRates(_Symbol,PERIOD_M1,start_time,end_time,buffer_price);
     PrintFormat("bars = %d | size1=%d / size2=%d / size3=%d / size4=%d / size5=%d / size6=%d", BarsCalculated(handle_19Lines), size1, size2, size3, size4, size5, size6);
    }
    // �������� ���������� ����� �����������
    bars = BarsCalculated(handle_19Lines);
    // ������� ���������� ����� ���� ��������� ����������
    barsPrice = Bars(_Symbol,PERIOD_M1,start_time,end_time);
    // �������� �� �������� ���� ������� 
    if ( size1!=bars || size2!=bars || size3!=bars ||size4!=bars||size5!=bars||size6!=bars||size_price!=barsPrice)
      {
       Print("�� ������� ���������� ��� ������ ����������");
       return;
      }

    // �������� �� ���� ����� ���� � ������� ����������
    for (int index=0;index < barsPrice; index++)
       {
        
       }
    PrintFormat("%s END ����� ����� ����� ����� ����� = %.0f; ����� ����� ����� ����� ���� = %.0f; ����� ������ ���� ����� ����� = %.0f; ����� ������ ���� ����� ���� = %.0f", __FUNCTION__, count_DUU, count_DUD, count_UDU, count_UDD);
  }
  
 // �������, ������������ ��������� ���� ������������ ��������� ������
 
 ENUM_LOCATION_TYPE GetCurrentPriceLocation (double dPrice,SExtremum &sLevel)
  {
    ENUM_LOCATION_TYPE locType;  // ���������� ��� �������� ��������� ���� ������������ ������
   
    return(locType);
  }
  
 // ������� ���������� ����������� ���������� �� ������������ 19 lines
 
 void SaveStatisticsToFile ()
  {
    
  }