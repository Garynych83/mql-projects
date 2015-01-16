//+------------------------------------------------------------------+
//|                                         divergenceStochastic.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                                            Pugachev Kirill       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CompareDoubles.mqh>          // ��� ��������� ������������ �����
#include <Constants.mqh>               // ���������� ��������
#include <CLog.mqh>

#define DEPTH_BLAU 10                  // ������� �� ������� ���� ����������� Blau_Mtm
#define ALLOW_DEPTH_FOR_PRICE_EXTR 3   // ���������� ����� ��� ������� �� ������� ������ ���������� 

struct PointDivBlau        
{                           
   datetime timeExtrBlau1;  // ����� ��������� ������� ���������� ����������
   datetime timeExtrBlau2;  // ����� ��������� ������� ���������� ����������
   datetime timeExtrPrice1; // ����� ��������� ������� ���������� ���
   datetime timeExtrPrice2; // ����� ��������� ������� ���������� ���
   double   valueExtrBlau1; // �������� ������� ���������� ����������
   double   valueExtrBlau2; // �������� ������� ���������� ����������
   double   valueExtrPrice1;// �������� ������� ���������� �� �����
   double   valueExtrPrice2;// �������� ������� ���������� �� �����
   double   closePrice;     // ���� �������� ����, �� ������� ������ ������ �����������\���������
};

PointDivBlau nullBlau = {0};

int divergenceBlau(int handleBlau, const string symbol, ENUM_TIMEFRAMES timeframe, PointDivBlau& div_point,datetime dt, int startIndex = 0)
{
 double iBlau_buf[];                         
 double iHigh_buf[];
 double iLow_buf[];
 datetime date_buf[];
 int index_Blau_global_max;
 int index_Price_global_max;
 int index_Blau_global_min;
 int index_Price_global_min;
 int index_Price_local_max;
 int index_Price_local_min;
 
 ArrayResize(iBlau_buf, DEPTH_BLAU);
 ArrayResize(iHigh_buf, DEPTH_BLAU);
 ArrayResize( iLow_buf, DEPTH_BLAU);
 ArrayResize( date_buf, DEPTH_BLAU);
 ArraySetAsSeries(iBlau_buf, true);
 ArraySetAsSeries(iHigh_buf, true);
 ArraySetAsSeries( iLow_buf, true);
 ArraySetAsSeries( date_buf, true);
 //Print("����� �� Div = ",TimeToString(dt) );
 //log_file.Write(LOG_DEBUG, StringFormat("����� �� Div = %s", TimeToString(dt) ) ); 
 int copiedBlau = -1;
 int copiedHigh = -1;
 int copiedLow  = -1;
 int copiedDate = -1;
 
 for(int attemps = 0; attemps < 25 && copiedBlau < 0
                                   && copiedHigh < 0
                                   && copiedLow  < 0
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedBlau = CopyBuffer(handleBlau, 0, startIndex, DEPTH_BLAU, iBlau_buf);
  copiedHigh = CopyHigh  (symbol, timeframe, startIndex, DEPTH_BLAU, iHigh_buf);
  copiedLow  = CopyLow   (symbol, timeframe, startIndex, DEPTH_BLAU, iLow_buf);
  copiedDate = CopyTime  (symbol, timeframe, startIndex, DEPTH_BLAU, date_buf); 
 }
 if (copiedBlau != DEPTH_BLAU || copiedHigh != DEPTH_BLAU || copiedLow != DEPTH_BLAU || copiedDate != DEPTH_BLAU)
 {
  Print(__FUNCTION__, "�� ������� ����������� ������ ���������. Error = ", GetLastError());
  return(-2);
 }
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);
 index_Blau_global_max =  ArrayMaximum(iBlau_buf, 0, WHOLE_ARRAY);
 
 index_Price_global_min = ArrayMinimum( iLow_buf, 0, WHOLE_ARRAY);
 index_Blau_global_min =  ArrayMinimum(iBlau_buf, 0, WHOLE_ARRAY);
 

 
 if(index_Price_global_max > 0 && index_Price_global_max < ALLOW_DEPTH_FOR_PRICE_EXTR)  
 { //���� �������� ���� ����������� ��������� ���� �����
  if(index_Blau_global_max > 0 && isBlauExtremum(handleBlau, (index_Blau_global_max-1)+startIndex) == 1 )
  { //���� ������������ �������� Blau �������� ����������� 
   for(int i = index_Blau_global_max - 3; i >= 0; i--)
   { //���� ������� � ����������� ����������(-3 ��� �� ��������� �� ������ � ����������)
    if(isBlauExtremum(handleBlau, i+startIndex) == 1)
    { //��� ��������� ���� ������ top_level(+1 ������ ��� isSTOCExtremum ���������� �������� ��� ����������� ����)   
     // ��������� ������ ��������� ���������� ��������� ����������
     index_Price_local_max      =  ArrayMaximum (iHigh_buf,ALLOW_DEPTH_FOR_PRICE_EXTR,WHOLE_ARRAY);
     if (index_Price_local_max == ALLOW_DEPTH_FOR_PRICE_EXTR || index_Price_local_max == (DEPTH_BLAU-1) )
      return (0);
     div_point.timeExtrPrice1   =  date_buf[index_Price_global_max];
     div_point.timeExtrPrice2   =  date_buf[index_Price_local_max];
     div_point.timeExtrBlau1    =  date_buf[index_Blau_global_max];
     div_point.timeExtrBlau2    =  date_buf[i+1];
     div_point.valueExtrPrice1  =  iHigh_buf[index_Price_global_max];
     div_point.valueExtrPrice2  =  iHigh_buf[index_Price_local_max];
     div_point.valueExtrBlau1   =  iBlau_buf[index_Blau_global_max];
     div_point.valueExtrBlau2   =  iBlau_buf[i+1];      
     return(-1);
    }   
   }
  }
 }

 //log_file.Write(LOG_DEBUG, StringFormat("����� ������� ���� = %s  ����� = %s ����� ��������� ������� = %s",DoubleToString(iLow_buf[index_Price_global_min]),TimeToString(date_buf[index_Price_global_min]),TimeToString(dt) ) ); 
 
 if(index_Price_global_min > 0 && index_Price_global_min < ALLOW_DEPTH_FOR_PRICE_EXTR)
 { //���� ������� ���� ����������� ��������� ���� �����
 // log_file.Write(LOG_DEBUG, StringFormat("����� ������� ���� = %s ����� = %s  ����� = %s ",DoubleToString(iLow_buf[index_Price_global_min]),TimeToString(date_buf[index_Price_global_min]),TimeToString(dt) )  );
  if(index_Blau_global_min > 0 && isBlauExtremum(handleBlau, (index_Blau_global_min-1)+startIndex) == -1 )
  { //���� ������������ �������� ���������� �������� ����������� � ����� ���� bottom_level
  //log_file.Write(LOG_DEBUG, StringFormat("����� ������� Blau ����� = %s",TimeToString(dt) ) );   
   for(int i = index_Blau_global_min - 3; i >= 0; i--)
   { //���� ������� � ����������� ����������(-3 ��� �� ��������� �� ������ � ����������)
    if(isBlauExtremum(handleBlau, i+startIndex) == -1)
    { //��� ��������� ���� ������ top_level(+1 ������ ��� isSTOCExtremum ���������� �������� ��� ����������� ����)
    // log_file.Write(LOG_DEBUG, StringFormat("isBlauExtremum(handleBlau, i+startIndex) == -1 ����� = %s",TimeToString(dt) ) );    
     // ��������� ������ ��������� ���������� �������� ����������
     index_Price_local_min      =  ArrayMinimum (iLow_buf,ALLOW_DEPTH_FOR_PRICE_EXTR,WHOLE_ARRAY);     
     if (index_Price_local_min == ALLOW_DEPTH_FOR_PRICE_EXTR || index_Price_local_min == (DEPTH_BLAU-1) )
      {
      /* log_file.Write(LOG_DEBUG, StringFormat("index_Price_local_min == ALLOW_DEPTH_FOR_PRICE_EXTR || index_Price_local_min == (DEPTH_BLAU-1) ����� = %s ",TimeToString(dt) ) );
       log_file.Write(LOG_DEBUG, StringFormat("index_Price_local_min = %i ALLOW_DEPTH_FOR_PRICE_EXTR = %i index_Price_local_min = %i  DEPTH_BLAU-1 = %i",index_Price_local_min,
                                                                                                                                                         ALLOW_DEPTH_FOR_PRICE_EXTR,
                                                                                                                                                         index_Price_local_min,
                                                                                                                                                        DEPTH_BLAU-1 ) ); */
       return 0;    
      }
     div_point.timeExtrPrice1   =  date_buf[index_Price_global_min];
     div_point.timeExtrPrice2   =  date_buf[index_Price_local_min];
     div_point.timeExtrBlau1    =  date_buf[index_Blau_global_min];
     div_point.timeExtrBlau2    =  date_buf[i+1];
     div_point.valueExtrPrice1  =  iLow_buf[index_Price_global_min];
     div_point.valueExtrPrice2  =  iLow_buf[index_Price_local_min];
     div_point.valueExtrBlau1   =  iBlau_buf[index_Blau_global_min];
     div_point.valueExtrBlau2   =  iBlau_buf[i+1];  
     return(1);
    }
   }
  }
 }   
 
 return(0); 
}

/////-------------------------------
/////-------------------------------
int isBlauExtremum(int handleBlau, int startIndex = 0)
{
 if (startIndex < 1) return 0;
 double iBlau_buf[3];
 int copiedBlau = 0;
 for(int attemps = 0; attemps < 25 && copiedBlau <= 0; attemps++)
 {
  Sleep(100);
  copiedBlau = CopyBuffer(handleBlau, 0, startIndex, 3, iBlau_buf);
 }
 if (copiedBlau < 3)
 {
  Print(__FUNCTION__, "�� ������� ����������� ������ ���������. Error = ", GetLastError());
  return(0);
 }
 
 if (GreatDoubles(iBlau_buf[1], iBlau_buf[0]) && GreatDoubles(iBlau_buf[1], iBlau_buf[2]))
 {
  return(1);
 }
 else if (LessDoubles(iBlau_buf[1], iBlau_buf[0]) && LessDoubles(iBlau_buf[1], iBlau_buf[2]))
 {
  return(-1);
 }
 
 return(0);
}