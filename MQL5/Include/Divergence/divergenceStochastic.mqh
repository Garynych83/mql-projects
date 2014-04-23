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

#define DEPTH_STOC 10                  // ������� �� ������� ���� ����������� ����������
#define ALLOW_DEPTH_FOR_PRICE_EXTR 3   // ���������� ����� ��� ������� �� ������� ������ ���������� 

struct PointDivSTOC        
{                           
   datetime timeExtrSTOC1;  // ����� ��������� ������� ���������� ����������
   datetime timeExtrSTOC2;  // ����� ��������� ������� ���������� ����������
   datetime timeExtrPrice1; // ����� ��������� ������� ���������� ���
   datetime timeExtrPrice2; // ����� ��������� ������� ���������� ���
   double   valueExtrSTOC1; // �������� ������� ���������� ����������
   double   valueExtrSTOC2; // �������� ������� ���������� ����������
   double   valueExtrPrice1;// �������� ������� ���������� �� �����
   double   valueExtrPrice2;// �������� ������� ���������� �� �����
   double   closePrice;     // ���� �������� ����, �� ������� ������ ������ �����������\���������
};

PointDivSTOC nullSTOC = {0};

int divergenceSTOC(int handleSTOC, const string symbol, ENUM_TIMEFRAMES timeframe, int top_level, int bottom_level, int startIndex = 0)
{
 double iSTOC_buf[];                         
 double iHigh_buf[];
 double iLow_buf[];
 int index_STOC_global_max;
 int index_Price_global_max;
 int index_STOC_global_min;
 int index_Price_global_min;
 int index_Price_local_max;
 int index_Price_local_min;
 
 ArrayResize(iSTOC_buf, DEPTH_STOC);
 ArrayResize(iHigh_buf, DEPTH_STOC);
 ArrayResize( iLow_buf, DEPTH_STOC);
 ArraySetAsSeries(iSTOC_buf, true);
 ArraySetAsSeries(iHigh_buf, true);
 ArraySetAsSeries( iLow_buf, true);

 int copiedSTOC = -1;
 int copiedHigh = -1;
 int copiedLow  = -1;
 int copiedDate = -1;
 for(int attemps = 0; attemps < 25 && copiedSTOC < 0
                                   && copiedHigh < 0
                                   && copiedLow  < 0; attemps++)
 {
  Sleep(100);
  copiedSTOC = CopyBuffer(handleSTOC, 0, startIndex, DEPTH_STOC, iSTOC_buf);
  copiedHigh = CopyHigh(symbol, timeframe, startIndex, DEPTH_STOC, iHigh_buf);
  copiedLow  =  CopyLow(symbol, timeframe, startIndex, DEPTH_STOC, iLow_buf);
 }
 if (copiedSTOC != DEPTH_STOC || copiedHigh != DEPTH_STOC || copiedLow != DEPTH_STOC)
 {
  Print(__FUNCTION__, "�� ������� ����������� ������ ���������. Error = ", GetLastError());
  return(0);
 }
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);
 index_STOC_global_max =  ArrayMaximum(iSTOC_buf, 0, WHOLE_ARRAY);
 
 index_Price_global_min = ArrayMinimum( iLow_buf, 0, WHOLE_ARRAY);
 index_STOC_global_min =  ArrayMinimum(iSTOC_buf, 0, WHOLE_ARRAY);
 
 if(index_Price_global_max > 0 && index_Price_global_max < ALLOW_DEPTH_FOR_PRICE_EXTR)  
 { //���� �������� ���� ����������� ��������� ���� �����
  if(index_STOC_global_max > 0 && isSTOCExtremum(handleSTOC, (index_STOC_global_max-1)+startIndex) == 1 && iSTOC_buf[index_STOC_global_max] > top_level)
  { //���� ������������ �������� ���������� �������� ����������� � ����� ���� top_level
   for(int i = index_STOC_global_max - 3; i > 0; i--)
   { //���� ������� � ����������� ����������(-3 ��� �� ��������� �� ������ � ����������)
    if(isSTOCExtremum(handleSTOC, i+startIndex) == 1 && iSTOC_buf[i+1] < top_level)
    { //���� ��������� ���� ������ top_level(+1 ������ ��� isSTOCExtremum ���������� �������� ��� ����������� ����)   
     // ��������� ������ ��������� ���������� ��������� ����������
     index_Price_local_max = ArrayMaximum (iHigh_buf,ALLOW_DEPTH_FOR_PRICE_EXTR,WHOLE_ARRAY);
     if (index_Price_local_max == ALLOW_DEPTH_FOR_PRICE_EXTR || index_Price_local_max == (DEPTH_STOC-1) )
      return (0); 
     Print("����������� ���������� �� �������");   
     return(_Sell);
    }   
   }
  }
 }
 
 if(index_Price_global_min > 0 && index_Price_global_min < ALLOW_DEPTH_FOR_PRICE_EXTR)
 { //���� ������� ���� ����������� ��������� ���� �����
  if(index_STOC_global_min > 0 && isSTOCExtremum(handleSTOC, (index_STOC_global_min-1)+startIndex) == -1 && iSTOC_buf[index_STOC_global_min] < bottom_level)
  { //���� ������������ �������� ���������� �������� ����������� � ����� ���� bottom_level
   for(int i = index_STOC_global_min - 3; i > 0; i--)
   { //���� ������� � ����������� ����������(-3 ��� �� ��������� �� ������ � ����������)
    if(isSTOCExtremum(handleSTOC, i+startIndex) == -1 && iSTOC_buf[i+1] > bottom_level)
    { //���� ��������� ���� ������ bottom_level(+1 ������ ��� isSTOCExtremum ���������� �������� ��� ����������� ����)
      // ��������� ������ ��������� ���������� �������� ����������
     index_Price_local_min = ArrayMinimum (iLow_buf,ALLOW_DEPTH_FOR_PRICE_EXTR,WHOLE_ARRAY);     
     if (index_Price_local_min == ALLOW_DEPTH_FOR_PRICE_EXTR || index_Price_local_min == (DEPTH_STOC-1) )
      return (0);  
     Print("����������� ���������� �� �������");   
     return(_Buy);
    }
   }
  }
 }   
 return(0); 
}

int divergenceSTOC(int handleSTOC, const string symbol, ENUM_TIMEFRAMES timeframe, int top_level, int bottom_level, PointDivSTOC& div_point, int startIndex = 0)
{
 double iSTOC_buf[];                         
 double iHigh_buf[];
 double iLow_buf[];
 datetime date_buf[];
 int index_STOC_global_max;
 int index_Price_global_max;
 int index_STOC_global_min;
 int index_Price_global_min;
 int index_Price_local_max;
 int index_Price_local_min;
 
 ArrayResize(iSTOC_buf, DEPTH_STOC);
 ArrayResize(iHigh_buf, DEPTH_STOC);
 ArrayResize( iLow_buf, DEPTH_STOC);
 ArrayResize( date_buf, DEPTH_STOC);
 ArraySetAsSeries(iSTOC_buf, true);
 ArraySetAsSeries(iHigh_buf, true);
 ArraySetAsSeries( iLow_buf, true);
 ArraySetAsSeries( date_buf, true);

 int copiedSTOC = -1;
 int copiedHigh = -1;
 int copiedLow  = -1;
 int copiedDate = -1;
 for(int attemps = 0; attemps < 25 && copiedSTOC < 0
                                   && copiedHigh < 0
                                   && copiedLow  < 0
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedSTOC = CopyBuffer(handleSTOC, 0, startIndex, DEPTH_STOC, iSTOC_buf);
  copiedHigh = CopyHigh(symbol, timeframe, startIndex, DEPTH_STOC, iHigh_buf);
  copiedLow  =  CopyLow(symbol, timeframe, startIndex, DEPTH_STOC, iLow_buf);
  copiedDate = CopyTime(symbol, timeframe, startIndex, DEPTH_STOC, date_buf); 
 }
 if (copiedSTOC != DEPTH_STOC || copiedHigh != DEPTH_STOC || copiedLow != DEPTH_STOC || copiedDate != DEPTH_STOC)
 {
  Print(__FUNCTION__, "�� ������� ����������� ������ ���������. Error = ", GetLastError());
  return(-2);
 }
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);
 index_STOC_global_max =  ArrayMaximum(iSTOC_buf, 0, WHOLE_ARRAY);
 
 index_Price_global_min = ArrayMinimum( iLow_buf, 0, WHOLE_ARRAY);
 index_STOC_global_min =  ArrayMinimum(iSTOC_buf, 0, WHOLE_ARRAY);
 
 if(index_Price_global_max > 0 && index_Price_global_max < ALLOW_DEPTH_FOR_PRICE_EXTR)  
 { //���� �������� ���� ����������� ��������� ���� �����
  if(index_STOC_global_max > 0 && isSTOCExtremum(handleSTOC, (index_STOC_global_max-1)+startIndex) == 1 && iSTOC_buf[index_STOC_global_max] > top_level)
  { //���� ������������ �������� ���������� �������� ����������� � ����� ���� top_level
   for(int i = index_STOC_global_max - 3; i > 0; i--)
   { //���� ������� � ����������� ����������(-3 ��� �� ��������� �� ������ � ����������)
    if(isSTOCExtremum(handleSTOC, i+startIndex) == 1 && iSTOC_buf[i+1] < top_level)
    { //��� ��������� ���� ������ top_level(+1 ������ ��� isSTOCExtremum ���������� �������� ��� ����������� ����)   
     // ��������� ������ ��������� ���������� ��������� ����������
     index_Price_local_max      =  ArrayMaximum (iHigh_buf,ALLOW_DEPTH_FOR_PRICE_EXTR,WHOLE_ARRAY);
     if (index_Price_local_max == ALLOW_DEPTH_FOR_PRICE_EXTR || index_Price_local_max == (DEPTH_STOC-1) )
      return (0);
     div_point.timeExtrPrice1   =  date_buf[index_Price_global_max];
     div_point.timeExtrPrice2   =  date_buf[index_Price_local_max];
     div_point.timeExtrSTOC1    =  date_buf[index_STOC_global_max];
     div_point.timeExtrSTOC2    =  date_buf[i+1];
     div_point.valueExtrPrice1  =  iHigh_buf[index_Price_global_max];
     div_point.valueExtrPrice2  =  iHigh_buf[index_Price_local_max];
     div_point.valueExtrSTOC1   =  iSTOC_buf[index_STOC_global_max];
     div_point.valueExtrSTOC2   =  iSTOC_buf[i+1];      
     return(_Sell);
    }   
   }
  }
 }
 
 if(index_Price_global_min > 0 && index_Price_global_min < ALLOW_DEPTH_FOR_PRICE_EXTR)
 { //���� ������� ���� ����������� ��������� ���� �����
  if(index_STOC_global_min > 0 && isSTOCExtremum(handleSTOC, (index_STOC_global_min-1)+startIndex) == -1 && iSTOC_buf[index_STOC_global_min] < bottom_level)
  { //���� ������������ �������� ���������� �������� ����������� � ����� ���� bottom_level
   for(int i = index_STOC_global_min - 3; i > 0; i--)
   { //���� ������� � ����������� ����������(-3 ��� �� ��������� �� ������ � ����������)
    if(isSTOCExtremum(handleSTOC, i+startIndex) == -1 && iSTOC_buf[i+1] > bottom_level)
    { //��� ��������� ���� ������ top_level(+1 ������ ��� isSTOCExtremum ���������� �������� ��� ����������� ����)
     // ��������� ������ ��������� ���������� �������� ����������
     index_Price_local_min      =  ArrayMinimum (iLow_buf,ALLOW_DEPTH_FOR_PRICE_EXTR,WHOLE_ARRAY);     
     if (index_Price_local_min == ALLOW_DEPTH_FOR_PRICE_EXTR || index_Price_local_min == (DEPTH_STOC-1) )
      return 0;    
     div_point.timeExtrPrice1   =  date_buf[index_Price_global_min];
     div_point.timeExtrPrice2   =  date_buf[index_Price_local_min];
     div_point.timeExtrSTOC1    =  date_buf[index_STOC_global_min];
     div_point.timeExtrSTOC2    =  date_buf[i+1];
     div_point.valueExtrPrice1  =  iLow_buf[index_Price_global_min];
     div_point.valueExtrPrice2  =  iLow_buf[index_Price_local_min];
     div_point.valueExtrSTOC1   =  iSTOC_buf[index_STOC_global_min];
     div_point.valueExtrSTOC2   =  iSTOC_buf[i+1];  
     return(_Buy);
    }
   }
  }
 }   
 return(0); 
}

/////-------------------------------
/////-------------------------------
int isSTOCExtremum(int handleSTOC, int startIndex = 0)
{
 if (startIndex < 1) return 0;
 double iSTOC_buf[3];
 int copiedSTOC = 0;
 for(int attemps = 0; attemps < 25 && copiedSTOC <= 0; attemps++)
 {
  Sleep(100);
  copiedSTOC = CopyBuffer(handleSTOC, 0, startIndex, 3, iSTOC_buf);
 }
 if (copiedSTOC < 3)
 {
  Print(__FUNCTION__, "�� ������� ����������� ������ ���������. Error = ", GetLastError());
  return(0);
 }
 
 if (GreatDoubles(iSTOC_buf[1], iSTOC_buf[0]) && GreatDoubles(iSTOC_buf[1], iSTOC_buf[2]))
 {
  return(1);
 }
 else if (LessDoubles(iSTOC_buf[1], iSTOC_buf[0]) && LessDoubles(iSTOC_buf[1], iSTOC_buf[2]))
 {
  return(-1);
 }
 
 return(0);
}