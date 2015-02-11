//+------------------------------------------------------------------+
//|                                               CDivergenceMACD.mqh |
//|                                              Copyright 2013, GIA |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <CompareDoubles.mqh>                // ��� ��������� ������������ ����������
#include <Constants.mqh>                     // ���������� ���������� ��������
#include <Divergence/ExtrMACDContainer.mqh>  // ���������� ����� ����������


#define DEPTH_MACD 130            // ���������� ����� �� ��������������� �������
#define BORDER_DEPTH_MACD 15      //
#define REMAINS_MACD 115          //DEPTH_MACD - BORDER_DEPTH_MACD 130-15

#define _Buy 1
#define _Sell -1

//+------------------------------------------------------------------+
//                 ����� CDivergenceMACD ������������ ��� ���������� | 
//                �����������/��������� MACD �� ������������ ������� |
//+------------------------------------------------------------------+

class CDivergenceMACD
{
   
private:
   CExtrMACDContainer *extremumsMACD; 
   string _symbol;
   ENUM_TIMEFRAMES _timeframe;
   int _handleMACD;
public:
   datetime timeExtrMACD1;  // ����� ��������� ������� ���������� MACD
   datetime timeExtrMACD2;  // ����� ��������� ������� ���������� MACD
   datetime timeExtrPrice1; // ����� ��������� ������� ���������� ���
   datetime timeExtrPrice2; // ����� ��������� ������� ���������� ���
   double   valueExtrMACD1; // �������� ������� ���������� MACD
   double   valueExtrMACD2; // �������� ������� ���������� MACD
   double   valueExtrPrice1;// �������� ������� ���������� �� �����
   double   valueExtrPrice2;// �������� ������� ���������� �� �����
   double   closePrice;     // ���� �������� ���� (�� ������� ������ ������ ���������\�����������)
   int      divconvIndex;   // ������ ������������� ���������\�����������

   CDivergenceMACD();
   CDivergenceMACD(const string symbol, ENUM_TIMEFRAMES timeframe, int handleMACD, int startIndex, int depth);
   ~CDivergenceMACD();
   int countDivergence(int startIndex = 0);
   bool RecountExtremums(int startIndex, bool fill = false);
};

CDivergenceMACD::CDivergenceMACD(const string symbol, ENUM_TIMEFRAMES timeframe, int handle, int startIndex, int depth)
{
 _timeframe = timeframe;
 _symbol = symbol;
 _handleMACD = handle;
 extremumsMACD = new CExtrMACDContainer(_handleMACD, startIndex, DEPTH_MACD);  //������� ��������� ����������� MACD
}
CDivergenceMACD::~CDivergenceMACD()
{
 delete extremumsMACD;
}

//+---------------------------------------------------------------------------------------------------------+
//                                     ���������� ������� ������������/��������� � ������� countDivergence. | 
//    ����������� ��������� �� ������� � 130 �����, ������������ � ���� ������� �� ������� � 115 � 15 ����� |
//                  �������� ���� ������� �������/������ ����������� ��� ���� � MACD �� ������ �� ��������, |
//                      ��� ���������� ������� �����������/��������� ���������� _Sell / _Buy �������������. |
//+---------------------------------------------------------------------------------------------------------+

int CDivergenceMACD::countDivergence(int startIndex = 0)
{
 //�������
 double iMACD_buf [DEPTH_MACD]  = {0};
 double iHigh_buf [DEPTH_MACD]  = {0};
 double iLow_buf  [DEPTH_MACD]  = {0};
 datetime date_buf[DEPTH_MACD]  = {0};
 double iClose_buf[DEPTH_MACD]  = {0};
 
 int index_MACD_global_max;
 int index_MACD_local_max;
 int index_Price_global_max;
 int index_Price_local_max;
 int index_MACD_global_min;
 int index_MACD_local_min;
 int index_Price_global_min;
 int index_Price_local_min;
 
 bool under_zero = false;
 bool over_zero = false;
 bool is_extr_exist = false;
 int i;
 
 int copiedMACD  = -1;
 int copiedHigh  = -1;
 int copiedLow   = -1;
 int copiedDate  = -1;
 int copiedClose = -1;
 
 for(int attemps = 0; attemps < 25 && copiedMACD < 0
                                   && copiedHigh < 0
                                   && copiedLow  < 0
                                   && copiedDate < 0; attemps++)
 {
  Sleep(100);
  copiedMACD  = CopyBuffer(_handleMACD, 0, startIndex, DEPTH_MACD, iMACD_buf);
  copiedHigh  = CopyHigh(_symbol, _timeframe, startIndex, DEPTH_MACD, iHigh_buf);
  copiedLow   = CopyLow (_symbol, _timeframe, startIndex, DEPTH_MACD, iLow_buf);
  copiedDate  = CopyTime(_symbol, _timeframe, startIndex, DEPTH_MACD, date_buf); 
  copiedClose = CopyClose(_symbol, _timeframe, startIndex, DEPTH_MACD, iClose_buf);
 }
 if (copiedMACD != DEPTH_MACD || copiedHigh != DEPTH_MACD || copiedLow != DEPTH_MACD || copiedDate != DEPTH_MACD || copiedClose != DEPTH_MACD)
 {
  int err;
  err = GetLastError();        
  Print(__FUNCTION__, "�� ������� ����������� ������ ���������. Error = ", err);
  return(-2);
 } 
 index_Price_global_max = ArrayMaximum(iHigh_buf, 0, WHOLE_ARRAY);   //���������� ������� ����������� ���� �� �������
 index_Price_global_min = ArrayMinimum(iLow_buf,  0, WHOLE_ARRAY);   //���������� ������� ����������� ���� �� �������
 CExtremumMACD *extr_local_max = extremumsMACD.maxExtr();
 CExtremumMACD *extr_global_max;
 CExtremumMACD *extr_local_min = extremumsMACD.minExtr();
 CExtremumMACD *extr_global_min;
 
//  +----------------------------------------------------------------------------+
//  |                         *** ����������� ***                                |                   
//  +----------------------------------------------------------------------------+ 

 i = 0;
 if(DEPTH_MACD >= index_Price_global_max && index_Price_global_max > REMAINS_MACD)  //���� ������ ����������� ���� �� ��������� 15 �����
 {
  if(extr_local_max.index < DEPTH_MACD && extr_local_max.index > BORDER_DEPTH_MACD) //���� ������ ������������� MACD �� ������� REMAINS
  {
   CExtremumMACD *tmpExtr;
   //��������� ������ ������������� MACD ��� ������ ���������� ��������� MACD
   index_MACD_local_max = extr_local_max.index;
   for (is_extr_exist = false; i < extremumsMACD.getCount()/2; i++)   //���� ������� ��������� MACD �� ������� �� 0 �� 15 
   {  
    tmpExtr = extremumsMACD.getExtr(i);
    if(tmpExtr.direction == 1 && tmpExtr.index <= BORDER_DEPTH_MACD)  //���� ����� ��������� MACD �� ��������� 15 �����
    {
     //��������� ������ MACD ��� ������ ����������� ����������
     extr_global_max = tmpExtr;
     index_MACD_global_max = extr_global_max.index;
     is_extr_exist = true;
     i++;                     
     break;
    }
   }
      
   if(!is_extr_exist) return(0);            //���� �� ��������� 15 ����� ��� �������� ���������� MACD
  
   for(under_zero = false; tmpExtr.index < index_MACD_local_max; i++) //���� ������ ��������� MACD ����� ��������� � ���������� �� �������
   {
    tmpExtr = extremumsMACD.getExtr(i);
    if(tmpExtr.direction == -1)
    {
     under_zero = true;
     break;
    }
   }
   if(!under_zero) return(0);      // ���� ��� �������� �� ������ ���������
   //��������� ������ ���������� ��������� ����
   index_Price_local_max = ArrayMaximum(iHigh_buf, 0, REMAINS_MACD); 
   if (index_Price_local_max == 0 || index_Price_local_max == (REMAINS_MACD - 1) )
    return (0);
    
   //����������� ������� �� ������ date_buf   
   index_MACD_local_max = DEPTH_MACD - 1 - index_MACD_local_max;
   index_MACD_global_max = DEPTH_MACD - 1 - index_MACD_global_max;  
    
   //��������� ���� ������ CDivergenceMACD
   timeExtrPrice1  = date_buf [index_Price_local_max];
   timeExtrPrice2  = date_buf [index_Price_global_max];    
   timeExtrMACD1   = date_buf [index_MACD_local_max];
   timeExtrMACD2   = date_buf [index_MACD_global_max];          
   valueExtrMACD1  = extr_local_max.value;
   valueExtrMACD2  = extr_global_max.value; 
   valueExtrPrice1 = iHigh_buf[index_Price_local_max];
   valueExtrPrice2 = iHigh_buf[index_Price_global_max];
   closePrice      = iClose_buf[index_Price_global_max];
   divconvIndex    = index_Price_global_max;
   
   return(_Sell);
  }
 }
 
 
// +----------------------------------------------------------------------------+
// |                         *** ��������� ***                                  |                   
// +----------------------------------------------------------------------------+ 
 
 i = 0;
 if(DEPTH_MACD >= index_Price_global_min && index_Price_global_min > REMAINS_MACD)  //���� ������ ����������� ���� �� ��������� 15 �����
 {
  if(extr_local_min.index < DEPTH_MACD && extr_local_min.index > BORDER_DEPTH_MACD) //���� ������ ����������� MACD �� ������� REMAIN
  {
   CExtremumMACD *tmpExtr;
   //��������� ������ ���������� �������� MACD
   index_MACD_local_min = extr_local_min.index;
   for (is_extr_exist = false; i < extremumsMACD.getCount()/2; i++)   //���� ������ ��������� MACD �� ������� �� 0 �� 15 
   {  
    tmpExtr = extremumsMACD.getExtr(i);
    if(tmpExtr.direction == -1 && tmpExtr.index <= BORDER_DEPTH_MACD)  //���� ����� ��������� �� ��������� 15 �����
    {
    //��������� ������ MACD ��� ������ ����������� ����������
    extr_global_min = tmpExtr;
    index_MACD_global_min = extr_global_min.index;
    is_extr_exist = true;
    i++;                     
    break;
   }
  }
     
  if(!is_extr_exist) return(0);    //���� �� ��������� 15 ����� ��� ������� ���������� 

  for(under_zero = false; tmpExtr.index < index_MACD_local_min; i++) //���� ������� ��������� MACD ����� ��������� � ���������� �� �������
  {
   tmpExtr = extremumsMACD.getExtr(i);
   if(tmpExtr.direction == -1)
   {
    under_zero = true;
    break;
   }
  }
  if(!under_zero) return(0);      // ���� ��� �������� �� ������� ���������
  //��������� ������ ���������� �������� ����
  index_Price_local_min = ArrayMinimum(iLow_buf, 0, REMAINS_MACD); 
  if (index_Price_local_min == 0 || index_Price_local_min == (REMAINS_MACD - 1) )
  return (0);
  
  //����������� ������� �� ������ date_buf    
  index_MACD_local_min = DEPTH_MACD - 1 - index_MACD_local_min;
  index_MACD_global_min = DEPTH_MACD - 1 - index_MACD_global_min;   
  
  //��������� ���� ������ CDivergenceMACD
  timeExtrPrice1  = date_buf [index_Price_local_min];
  timeExtrPrice2  = date_buf [index_Price_global_min];    
  timeExtrMACD1   = date_buf [index_MACD_local_min];
  timeExtrMACD2   = date_buf [index_MACD_global_min];        
  valueExtrMACD1  = extr_local_min.value;
  valueExtrMACD2  = extr_global_min.value;
  valueExtrPrice1 = iLow_buf[index_Price_local_min];
  valueExtrPrice2 = iLow_buf[index_Price_global_min];
  closePrice      = iClose_buf[index_Price_global_min];
  divconvIndex    = index_Price_global_min;
  /*
   PrintFormat("PriceExtr1 = %s; PriceExtr2 = %s; MACDExtr1 = %s; MACDExtr2 = %s", TimeToString(div_point.timeExtrPrice1),
                                                                                   TimeToString(div_point.timeExtrPrice2),
                                                                                   TimeToString(div_point.timeExtrMACD1),
                                                                                   TimeToString(div_point.timeExtrMACD2));
                                                                                   */
  return(_Buy);
 }
}
 return(0); 
}
//+----------------------------------------------------------------------------------------+
//|              RecountExtremums �������� ������� RecountExtremums �� ������� ����������� |                                                  |
//+----------------------------------------------------------------------------------------+

bool CDivergenceMACD::RecountExtremums(int startIndex, bool fill = false)
{
 return (extremumsMACD.RecountExtremum(startIndex, fill));
} 