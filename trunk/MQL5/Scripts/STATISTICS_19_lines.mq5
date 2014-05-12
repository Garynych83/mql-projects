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
#include <CheckHistory.mqh>


//+------------------------------------------------------------------+
//| ������ �������� ���������� 19 �����                              |
//+------------------------------------------------------------------+

// ������������ ������ ���������� ���������� (�� �������)

enum ENUM_CALCULATE_TYPE
 {      
  CALC_H1 = 0,                                   // ������� ������
  CALC_H4,                                       // 4-� ������� ������
  CALC_D1,                                       // ������� ������ 
  CALC_W1,                                       // ��������� ������
  CALC_MN1                                       // �������� ������
 };

// ������������ ����� ��������� ���� ������������ ������
enum ENUM_LOCATION_TYPE
 {
  LOCATION_ABOVE=0,                              // ���� ������
  LOCATION_BELOW,                                // ���� ������
  LOCATION_INSIDE                                // ������ ������
 };

// �������� ��������� �������
sinput string  stat_str="";                      // ��������� ���������� ����������
input datetime start_time = D'2012.01.01';       // ��������� ����
input datetime end_time   = D'2014.04.01';       // �������� ����
input ENUM_CALCULATE_TYPE calc_type = CALC_W1;   // ������, �� ������� ��������� ����������
input string   file_name  = "STAT_19_LINES";     // ��� ����� ����������

sinput string atr_str = "";                      // ��������� ���������� ��R
input int    period_ATR = 30;                    // ������ ATR ��� ������
input double percent_ATR = 0.5;                  // ������ ������ ������ � ��������� �� ATR

int  countDownUp   = 0;                          // ���������� �������� ����� �����
int  countUpDown   = 0;                          // ���������� �������� ������ ����
int  countUpUp     = 0;                          // ���������� �� �������� ������
int  countDownDown = 0;                          // ���������� �� �������� �����
int  countDone     = 0;                          // ���������� ����������� �������
int  countUnDone   = 0;                          // ���������� �� ����������� �������
 
// ����� ���������� 19 lines
int      handle_19Lines;

// ������������ ������
double   buffer_19Lines_price4[];
double   buffer_19Lines_price3[];
double   buffer_19Lines_atr4  [];
double   buffer_19Lines_atr3  [];
// ����� ��� �� ��������� ����������
MqlRates buffer_price[];  
       
// ������ ���������� ��������� ���� ������������ �������
ENUM_LOCATION_TYPE  prevLocLevel4;    // ���������� ��������� ���� ������������ 4-�� ������
ENUM_LOCATION_TYPE  prevLocLevel3;    // ���������� ��������� ���� ������������ 3-�� ������
// ������ ������� ��������� ���� ������������ �������
ENUM_LOCATION_TYPE  curLocLevel4;     // ������� ��������� ���� ������������ 4-�� ������
ENUM_LOCATION_TYPE  curLocLevel3;     // ������� ��������� ���� ������������ 3-�� ������
// ����� ��������� ���� � �������
bool standOnLevel4;                   // ���� ��������� � ������� 4
bool standOnLevel3;                   // ���� ��������� � ������� 3
// �������� �������� ���������� ����� ������ �������
int countBarsInsideLevel4=0;          // ������ ���������� ������
int countBarsInsideLevel3=0;          // ������ �������� ������

// ������ ������ ����������
int fileHandle;                       // ����� ����� ����������
int fileTestStat;                     // ����� ����� �������� ���������� ����������� �������

// ������� �������� �������
double curBuf4;                       // ������� �������� 4-�� ������
double curBuf3;                       // ������� �������� 3-�� ������

void OnStart()
  {
   // ���������� ��� ���������� �������� �������� ������� �����������
   int size3;
   int size4;
   int size5;
   int size6;
   int size_price;
   int start_index_buffer;            // ������ ����� ������ ������� ��� 3 ����� ������ 
   int bars;                          // ���������� ����� ����� 
    
   // ������� ����� ���������� 19 ����� (� ����������� �� ��������� calc_type)  
   
   switch (calc_type)
    {
     case CALC_D1:   // �������
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      false, clrRed, false, clrRed, true, clrRed, false, clrRed, false, clrRed, false, clrRed);   
      start_index_buffer = 12;  
     break;
     case CALC_H1:   // �������
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      false, clrRed, false, clrRed, false, clrRed, false, clrRed, true, clrRed, false, clrRed);
      start_index_buffer = 24;      
     break;
     case CALC_H4:   // ������� �������
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      false, clrRed, false, clrRed, false, clrRed, true, clrRed, false, clrRed, false, clrRed);  
      start_index_buffer = 18;   
     break;
     case CALC_MN1:  // �����
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      true, clrRed, false, clrRed, false, clrRed, false, clrRed, false, clrRed, false, clrRed);  
      start_index_buffer = 0;    
     break;
     case CALC_W1:   // ��������
      handle_19Lines = iCustom(Symbol(), PERIOD_M1, "NineteenLines_BB", period_ATR, percent_ATR, 
      false, clrRed, true, clrRed, false, clrRed, false, clrRed, false, clrRed, false, clrRed); 
      start_index_buffer = 6;    
     break;
    }
            

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
     size3 = CopyBuffer(handle_19Lines, start_index_buffer + 2, start_time, end_time, buffer_19Lines_price4);
     size4 = CopyBuffer(handle_19Lines, start_index_buffer + 3, start_time, end_time, buffer_19Lines_atr4);
     size5 = CopyBuffer(handle_19Lines, start_index_buffer + 4, start_time, end_time, buffer_19Lines_price3);
     size6 = CopyBuffer(handle_19Lines, start_index_buffer + 5, start_time, end_time, buffer_19Lines_atr3);
     size_price = CopyRates(_Symbol,PERIOD_M1,start_time,end_time,buffer_price);
     PrintFormat("bars = %d |  size3=%d / size4=%d / size5=%d / size6=%d / sizePrice=%d", BarsCalculated(handle_19Lines), size3, size4, size5, size6,size_price);
    }   
    // �������� ���������� ����� �����������
    bars = Bars(_Symbol,PERIOD_M1,start_time,end_time);
    
    // �������� �� �������� ���� ������� 
    if ( size3!=bars ||size4!=bars||size5!=bars||size6!=bars||size_price!=bars)
      {
       Print("�� ������� ���������� ��� ������ ����������");
       return;
      }
    // ��������� ������� ��������� ���� ������������ �������
    prevLocLevel4  =  GetCurrentPriceLocation(buffer_price[0].open,buffer_19Lines_price4[0],buffer_19Lines_atr4[0]);  
    prevLocLevel3  =  GetCurrentPriceLocation(buffer_price[0].open,buffer_19Lines_price3[0],buffer_19Lines_atr3[0]);               
    // ���������� ����� ���������� � ���� ������ � false
    standOnLevel4  = false;
    standOnLevel3  = false;
    // �������� ������� ���� �� �������
    curBuf4        = buffer_19Lines_price4[0];
    curBuf3        = buffer_19Lines_price3[0];
  
    // �������� �� ���� ����� ����  � ������� ���������� �������� ����� ������
    for (int index=1;index < bars; index++)
       {
  
        /////��� ���������� ������//////  
      
        if ( curBuf4 != buffer_19Lines_price4[index] ) // ���� �������� ������� ����������
         {
           // �� �������� ������� ���� ������
           curBuf4 = buffer_19Lines_price4[index];
           // � ���������� ��������� ���� ������������ ������
           prevLocLevel4  = GetCurrentPriceLocation(buffer_price[index].open,buffer_19Lines_price4[index],buffer_19Lines_atr4[index]);  
           // �������� ���� ���������� � ���� ������ 
           standOnLevel4 = false;
           // �������� ������� ����� ������ ������
           countBarsInsideLevel4 = 0;        
         }  
        else   // ���� ����� �� ������� ������ ����������� ���������
        {       
          curLocLevel4 = GetCurrentPriceLocation(buffer_price[index].close,buffer_19Lines_price4[index],buffer_19Lines_atr4[index]);
        
          if (curLocLevel4 == LOCATION_INSIDE) 
            {
             // ���� ��� � Open ��������� ������ ������
             if (GetCurrentPriceLocation(buffer_price[index].open,buffer_19Lines_price4[index],buffer_19Lines_atr4[index])  == LOCATION_INSIDE)
                 countBarsInsideLevel4++;  // �� ����������� ���������� ����� ������ ������
             standOnLevel4 = true;
            }
          else 
            {   
             if (curLocLevel4 == LOCATION_ABOVE && prevLocLevel4 == LOCATION_BELOW)
               {
                countDownUp ++;
                if (standOnLevel4)  // ���� ���� ���������� ������ ������. �� ������� �����������
                 countDone ++;
                else
                 countUnDone ++;
                if (standOnLevel4)
                 FileWriteString(fileTestStat,"\n(4) �������� ���� ������ ����� ����� � "+TimeToString(buffer_price[index].time)+" ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index]));
                else
                 FileWriteString(fileTestStat,"\n(4) �� �������� ���� ������ ����� ����� � "+TimeToString(buffer_price[index].time)+" ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index]));                 
               }
             if (curLocLevel4 == LOCATION_BELOW && prevLocLevel4 == LOCATION_ABOVE)
               {
                countUpDown ++;
                if (standOnLevel4)  // ���� ���� ���������� ������ ������. �� ������� �����������
                 countDone ++;
                else
                 countUnDone ++;
                 if (standOnLevel4)                
                  FileWriteString(fileTestStat,"\n(4) �������� ���� ������ ������ ���� � "+TimeToString(buffer_price[index].time)+" ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index])); 
                 else
                  FileWriteString(fileTestStat,"\n(4) �� �������� ���� ������ ������ ���� � "+TimeToString(buffer_price[index].time)+" ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index]));                  
               }
             if (curLocLevel4 == LOCATION_ABOVE && prevLocLevel4 == LOCATION_ABOVE && standOnLevel4)
               {
                countUpUp ++;
                countDone ++; 
                FileWriteString(fileTestStat,"\n(4) �������� ���� �������� ������ ����� � "+TimeToString(buffer_price[index].time)+" ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index])); 
               }
             if (curLocLevel4 == LOCATION_BELOW && prevLocLevel4 == LOCATION_BELOW && standOnLevel4)
               {
                countDownDown ++;
                countDone     ++;  
                FileWriteString(fileTestStat,"\n(4) �������� ���� �������� ����� ���� � "+TimeToString(buffer_price[index].time)+" ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel4)+" ATR = "+DoubleToString(buffer_19Lines_atr4[index])+" PRICE = "+DoubleToString(buffer_19Lines_price4[index]));                
               }
             // �������� ������� ����� ������ ������
             countBarsInsideLevel4 = 0;   
             prevLocLevel4 = curLocLevel4;
             standOnLevel4 = false;
            }  
           } ///END ��� ���������� ������
        
        
        
         /////��� �������� ������//////        
        if ( curBuf3 != buffer_19Lines_price3[index]  ) // ���� �������� ������� ����������
         {
           // �� �������� ������� ���� ������
           curBuf3 = buffer_19Lines_price3[index];
           // � ���������� ��������� ���� ������������ ������
           prevLocLevel3  = GetCurrentPriceLocation(buffer_price[index].open,buffer_19Lines_price3[index],buffer_19Lines_atr3[index]);  
           // �������� ���� ���������� � ���� ������ 
           standOnLevel3 = false;
           // �������� ������� ����� ������ ������
           countBarsInsideLevel3 = 0;                        
         }     
        else // �����
         { 
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
                if (standOnLevel3)  // ���� ���� ���������� ������ ������. �� ������� �����������
                 countDone ++;
                else
                 countUnDone ++;  
                 if (standOnLevel3)               
                  FileWriteString(fileTestStat,"\n(3) �������� ���� ������ ����� ����� � "+TimeToString(buffer_price[index].time)+"; ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index]));
                 else
                  FileWriteString(fileTestStat,"\n(3) �� �������� ���� ������ ����� ����� � "+TimeToString(buffer_price[index].time)+"; ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index]));                  
                }
             if (curLocLevel3 == LOCATION_BELOW && prevLocLevel3 == LOCATION_ABOVE)
                {
                 countUpDown ++;
                if (standOnLevel3)  // ���� ���� ���������� ������ ������. �� ������� �����������
                 countDone ++;
                else
                 countUnDone ++;
                 if (standOnLevel3)                 
                  FileWriteString(fileTestStat,"\n(3) �������� ���� ������ ������ ���� � "+TimeToString(buffer_price[index].time)+";���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index])); 
                 else
                  FileWriteString(fileTestStat,"\n(3) �� �������� ���� ������ ������ ���� � "+TimeToString(buffer_price[index].time)+";���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index]));                  
                }
             if (curLocLevel3 == LOCATION_ABOVE && prevLocLevel3 == LOCATION_ABOVE && standOnLevel3)
                {
                 countUpUp ++;
                 countDone ++;  
                 FileWriteString(fileTestStat,"\n(3) �������� ���� �������� ������ ����� � "+TimeToString(buffer_price[index].time)+"; ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index])); 
                }
             if (curLocLevel3 == LOCATION_BELOW && prevLocLevel3 == LOCATION_BELOW && standOnLevel3)
                {
                 countDownDown ++;
                 countDone     ++;  
                 FileWriteString(fileTestStat,"\n(3) �������� ���� �������� ����� ���� � "+TimeToString(buffer_price[index].time)+"; ���������� ����� ������ ������ = "+IntegerToString(countBarsInsideLevel3)+" ATR = "+DoubleToString(buffer_19Lines_atr3[index])+" PRICE = "+DoubleToString(buffer_19Lines_price3[index]));                
                }
            // �������� ������� ����� ������ ������
            countBarsInsideLevel3 = 0;   
            prevLocLevel3 = curLocLevel3;
            standOnLevel3 = false;
           } 
          }  ///END ��� �������� ������        
          
           
       }

   // ��������� ���� ������������ ���������� ����������� �������
   FileClose(fileTestStat);
   // �������� ���������� ���������� � ����
   SaveStatisticsToFile ();
 
  }
  
  
  
 // �������, ������������ ��������� ���� ������������ ��������� ������
 
 ENUM_LOCATION_TYPE GetCurrentPriceLocation (double dPrice,double price19Lines,double atr19Lines)
  {
    ENUM_LOCATION_TYPE locType = LOCATION_INSIDE;  // ���������� ��� �������� ��������� ���� ������������ ������
     if ( GreatDoubles (dPrice,(price19Lines+atr19Lines) ) )
      locType = LOCATION_ABOVE;
     if ( LessDoubles (dPrice,(price19Lines-atr19Lines) ) )     
      locType = LOCATION_BELOW;
     
    return(locType);
  }
  
 // ������� ���������� ������ �� 
 
 string GetLevelString ()
  {
   string str;
   switch (calc_type)
    {
     case CALC_D1:
      str = "D1";
     break;
     case CALC_H1:
      str = "H1";
     break;
     case CALC_H4:
      str = "H4";
     break;
     case CALC_MN1:
      str = "MN1";
     break;
     case CALC_W1:
      str = "W1";
     break; 
     
    }
   return (str);
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
    FileWriteString(fileHandle,"���������� �� ������� (������ �� "+GetLevelString ()+"):\n\n");
    FileWriteString(fileHandle,"���������� ����������� ����� ������� ������ ����: "+IntegerToString(countUpDown));
    FileWriteString(fileHandle,"\n���������� ����������� ����� ������� ����� �����: "+IntegerToString(countDownUp));
    FileWriteString(fileHandle,"\n���������� ������� �� ������ ������ ����� : "+IntegerToString(countUpUp));
    FileWriteString(fileHandle,"\n���������� ������� �� ������ ����� ����: "+IntegerToString(countDownDown));
    FileWriteString(fileHandle,"\n���������� ����������� �������: "+IntegerToString(countDone));  
    FileWriteString(fileHandle,"\n���������� �� ����������� �������: "+IntegerToString(countUnDone));  
    // ��������� ���� ����������
    FileClose(fileHandle);            
  }