//+------------------------------------------------------------------+
//|                                                   divergence.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                                            Pugachev Kirill       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CompareDoubles.mqh>

#define DEPTH_MACD 100
#define BORDER_DEPTH_MACD 15

/////-------------------------------
/////-------------------------------
int isMACDExtremum(int handleMACD, int startIndex, int precision = 6, bool LOG = false)
{ 
 double iMACD_buf[5];
 
 int copied = 0;
 for(int attemps = 0; attemps < 25 && (copied = CopyBuffer(handleMACD, 0, startIndex, 5, iMACD_buf)) < 0; attemps++)
 {
  Sleep(100);
 }
 if(copied != 5)
 {
  int err = GetLastError();
  Alert(__FUNCTION__, "�� ������� ����������� ������ ���������.", copied, "/5. Error = ", err);
  return(0);
 }

 if (LOG) Alert("0[", (startIndex-4), "]=", iMACD_buf[0], "; 1[", (startIndex-3), "]=", iMACD_buf[1], "; 2[", (startIndex-2), "]=",  iMACD_buf[2], "; 3[", (startIndex-1), "]=",  iMACD_buf[3]);

 if ( GreatDoubles(iMACD_buf[2], iMACD_buf[0], precision) && GreatDoubles(iMACD_buf[2], iMACD_buf[1], precision) &&
      GreatDoubles(iMACD_buf[2], iMACD_buf[3], precision) && GreatDoubles(iMACD_buf[2], 0, precision) )
 {
  if (LOG) Alert("����� ����� �������� �� MACD. 0[", (startIndex-4), "]=", NormalizeDouble(iMACD_buf[0], 8), "; 1[", (startIndex-3), "]=", NormalizeDouble(iMACD_buf[1], 8), "; 2[", (startIndex-2), "]=",  NormalizeDouble(iMACD_buf[2], 8), "; 3[", (startIndex-1), "]=",  NormalizeDouble(iMACD_buf[3], 8));
  return(1);
 }
 else if ( LessDoubles(iMACD_buf[2], iMACD_buf[0], precision) && LessDoubles(iMACD_buf[2], iMACD_buf[1], precision) && 
           LessDoubles(iMACD_buf[2], iMACD_buf[3], precision) && LessDoubles(iMACD_buf[2], 0, precision)) 
      {
       if (LOG) Alert("����� ����� ������� �� MACD. 1(", (startIndex+1), ")=", iMACD_buf[1], "; 2(", (startIndex+2), ")=", iMACD_buf[2], "; 3(", (startIndex+3), ")=",  iMACD_buf[3], "; 4(", (startIndex+4), ")=",  iMACD_buf[4]);
       return(-1);     
      }
 if (LOG) Alert("�� ������� �����������");
 return(0);
}
/////-------------------------------
/////-------------------------------
int divergenceMACD(int handleMACD, const string symbol, ENUM_TIMEFRAMES timeframe, int startIndex = 0)
{
 double iMACD_buf[DEPTH_MACD] = {0};
 double iHigh_buf[DEPTH_MACD] = {0};
 double iLow_buf[DEPTH_MACD] = {0};
 datetime date_buf[DEPTH_MACD] = {0};
 int index_MACD_global_max;
 int index_Price_global_max;
 int index_MACD_global_min;
 int index_Price_global_min;
 bool under_zero = false;
 bool over_zero = false;
 bool is_extr_exist = false;
 int i;
 
 int copiedMACD = -1;
 int copiedHigh = -1;
 int copiedLow = -1;
 int copiedDate = -1;
 for(int attemps = 0; attemps < 25 && copiedMACD < 0
                                   && copiedHigh < 0
                                   && copiedLow  < 0
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedMACD = CopyBuffer(handleMACD, 0, startIndex, DEPTH_MACD, iMACD_buf);
  copiedHigh = CopyHigh(symbol, timeframe, startIndex, DEPTH_MACD, iHigh_buf);
  copiedLow  = CopyLow (symbol, timeframe, startIndex, DEPTH_MACD, iLow_buf);
  copiedDate = CopyTime(symbol, timeframe, startIndex, DEPTH_MACD, date_buf); 
 }
 if (copiedMACD != DEPTH_MACD || copiedHigh != DEPTH_MACD || copiedLow != DEPTH_MACD || copiedDate != DEPTH_MACD)
 {
   int err = GetLastError();
   Alert(__FUNCTION__, "�� ������� ����������� ������ ���������. Error = ", err);
   return(0);
 }
 
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);
 index_Price_global_min = ArrayMinimum(iLow_buf, 0, WHOLE_ARRAY);


 if ((DEPTH_MACD-BORDER_DEPTH_MACD) <= index_Price_global_max && index_Price_global_max < DEPTH_MACD)       //����� ������� ���� ��������� � ��������� 15 �����
 {
  if(isMACDExtremum(handleMACD, 0) == 1) //���� � ������� ������ ���� ���������
  {
   is_extr_exist = false;
   for (i = 0; i <= (DEPTH_MACD-BORDER_DEPTH_MACD); i++)           //����� ������ ����� ������� ���������� ��� ���� ��� �� MACD_global_max ��� �����������
   {
    if (isMACDExtremum(handleMACD, ((DEPTH_MACD-1)-i)) == 1) 
    {
     is_extr_exist = true;
     break; 
    }
   }  
   if (!is_extr_exist) 
    return(0);  //���� �� ���� ������� ������� � DEPTH �� ��������� 15 ����� �� ���� ����������
   
   index_MACD_global_max = ArrayMaximum(iMACD_buf, i, WHOLE_ARRAY);  
   for(i = index_MACD_global_max; i < DEPTH_MACD; i++)  //���� ���� �� ����������� ����� 0 � ����������� ����� 
   {
    if(iMACD_buf[i] < 0) 
    {
     under_zero = true;
     break;
    }//�� ��������� �� ����� �� 0 ��� ��� � ������� ������ ���� ������������� ���������
   }
   if(!under_zero)                       
    return(0); //���� �� ���� ����������� ����� 0 �� ��� ������ �������� ��� �� ����������
   
   if(LessDoubles(iMACD_buf[DEPTH_MACD-1], iMACD_buf[index_MACD_global_max]))  //�� MACD: ��������� � ������� ������ ������ �����������
   {
    /*Alert("BEGIN: ", date_buf[0]);
    Alert(__FUNCTION__, ": ������� �����������");
    Alert("index_global_MACD = ", index_MACD_global_max);
    Alert("index_highest_price = ", index_Price_global_max, "; highest_price = ", iHigh_buf[index_Price_global_max]);
    Alert("END: ", date_buf[DEPTH_MACD-1]);*/  
    return(1);
   }
  }
  else
   return(0);
 }
 
 if ((DEPTH_MACD-BORDER_DEPTH_MACD) <= index_Price_global_min && index_Price_global_min < DEPTH_MACD)       //����� ������ ���� ��������� � ��������� 15 �����
 {
  if(isMACDExtremum(handleMACD, 0) == -1) //���� � ������� ������ ���� ���������
  {
   is_extr_exist = false;
   for (i = 0; i <= (DEPTH_MACD-BORDER_DEPTH_MACD); i++)           //����� ������ ����� ������� ���������� ��� ���� ��� �� MACD_global_max ��� �����������
   {
    if (isMACDExtremum(handleMACD, ((DEPTH_MACD-1)-i)) == -1) 
    {
     is_extr_exist = true;
     break;
    }
   }
   if (!is_extr_exist) 
    return(0);  //���� �� ���� ������� ������� � DEPTH �� ��������� 15 ����� �� ���� ����������
 
   index_MACD_global_min = ArrayMinimum(iMACD_buf, i, WHOLE_ARRAY);  
   for(i = index_MACD_global_min; i < DEPTH_MACD; i++)  //���� ���� �� ����������� ����� 0 
   {
    if(iMACD_buf[i] > 0) 
    {
     over_zero = true;
     break;
    }
   }
   if(!over_zero)
    return(0); //���� �� ���� ����������� ����� 0 �� ��� ������ �������� ��� �� ����������
 
   if(GreatDoubles(iMACD_buf[DEPTH_MACD-1], iMACD_buf[index_MACD_global_min]))  //�� MACD: ��������� � ������� ������ ������ �����������
   {
    /*Alert("BEGIN: ", date_buf[0]);
    Alert(__FUNCTION__, ": ������� ���������");
    Alert("index_global_MACD = ", index_MACD_global_min);
    Alert("index_lowest_price = ", index_Price_global_min, "; lowest_price = ", iLow_buf[index_Price_global_min]);
    Alert("END: ", date_buf[DEPTH_MACD-1]);*/
    return(-1);
   }
  }
  else
   return(0);
 }
    
 return(0); 
}