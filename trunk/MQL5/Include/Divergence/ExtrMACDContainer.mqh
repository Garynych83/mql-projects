//+------------------------------------------------------------------+
//|                                            ExtrMACDContainer.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>     // ��� ��������� ������������ ����������
#include <Constants.mqh>          // ���������� ���������� ��������
#include <CLog.mqh>               // log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� rescue-����: %s", MakeFunctionPrefix(__FUNCTION__), rescueDataFileName)); 
#include <Arrays/ArrayObj.mqh>
#include <Divergence/CExtremumMACD.mqh>

#define ARRAY_SIZE 130           



//+----------------------------------------------------------------------------------------------+
//|            ����� CExtrMACDContainer ������������ ��� �������� � ���������� ����������� MACD  |
//                                                          �� ������������ ������� ARRAY_SIZE.  |
//+----------------------------------------------------------------------------------------------+
class CExtrMACDContainer
{
private: 
 CArrayObj extremums;                        // ������ ����������� MACD
 double valueMACDbuffer[ARRAY_SIZE];         // ������ �������� MACD �� ������� ARRAY_SIZE
 bool _flagFillSucceed;                      // ���� ��������� ���������� ����������
 int count;                                  // ���������� �������� ����������� MACD
 int _depth;                                 
 int _handle;
 
public: 
 
 CExtrMACDContainer();
 ~CExtrMACDContainer();
 CExtrMACDContainer(int handleMACD,int startIndex,int depth);  //��������� ������� - startIndex, 
                                                               //��������  - DEPTH, Handle
  
 //---------------������ ��� ������ � �������-------------------
 int isMACDExtremum(int startIndex);                         // ������� ���� �� ���������� �� ������ ���
 void FilltheExtremums(int startIndex);                      // ��������� ���������                                    
    //--------------����������� ������-----------------------------------------------
 CExtremumMACD *getExtr(int i);                              // ���������� i-�� ������� �������
 bool RecountExtremum(int startIndex, bool fill = false);    // ���������� ������ �����������
 CExtremumMACD *maxExtr();                                   // ���������� ��������� MACD � ������������ ���������
 CExtremumMACD *minExtr();                                   // ���������� ��������� MACD � �����������  ���������
 int getCount();
 //void maxExtr(int indexStart, int indexFinish, CExtremumMACD &extr);                               //���������� ������������ ������� ���������
 //void minExtr(int indexStart, int indexFinish, CExtremumMACD &extr);                               //���������� ����������� ������ ���������
};  
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrMACDContainer::CExtrMACDContainer(int handle, int startIndex, int depth)    //���������� ������� ������, �����
{
 _handle = handle;
 _depth = depth;
 FilltheExtremums(startIndex);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrMACDContainer::~CExtrMACDContainer()
{
}
  
//+------------------------------------------------------------------+
//                                                                   |
//            FilltheExtremums ��������� ��������� ������������ MACD |
//                           ������� � startIndex �� ������� _depth. |
//+------------------------------------------------------------------+

void CExtrMACDContainer::FilltheExtremums(int startIndex)
{
 int copied = 0;
 //----------����������� �������� MACD � ����� valueMACDbuffer-------
 for(int attemps = 0; attemps < 25 && copied <= 0; attemps++)
 {
  copied = CopyBuffer(_handle, 0, startIndex , _depth, valueMACDbuffer);
  Sleep(100);
 }
 if(copied != _depth)
 {
  int err = GetLastError();
  Print(__FUNCTION__, " �� ������� ����������� ������ ���������.", copied, "/. Error = ", err);
  _flagFillSucceed = false;
  return;
 }
 //-----------------------���������� ����������---------------------
 count = 0;
 int indexForExtremum = startIndex + 1;                       
 int extremRslt = 0;
 int i, j = 2 , ind = _depth - 3;
 for(i = 0; indexForExtremum - startIndex  < _depth - 5; indexForExtremum++) //�� 1��� �� 126���
 {
  extremRslt = isMACDExtremum(indexForExtremum);  // �������� �� ��������� MACD
  if(extremRslt != 0)                             // ���� ������� ������� ��������� 
  {
   CExtremumMACD *new_extr = new CExtremumMACD(); // ����� ��������� 
   new_extr.direction = extremRslt;               // ��������� �����������
   new_extr.index = j;                            // ��������� ������ ������������� _depth (�.� ������� ������� - [0 + 2])
   new_extr.value = valueMACDbuffer[ind];         // �������� ����������
   extremums.Add(new_extr);                       // ���������� ���������� � ������ 
   i++;
  }
  j++; 
  ind--;
 }
 count = i;
 _flagFillSucceed = true; 
 return;
} 
//+-------------------------------------------------------------------------------+
//                                                                                |
//            RecountExtremum ������������� �������� ��� ����������� ������ ����, | 
//                                             � ����� ��� ���������� ����������. |
//                        ����� �������, RecountExtremum �������� � ���� �������: |
//                        � ����������� �� ����� fill ����� ��������� ����������, |
//        � ����� ����������� ������� ����������� MACD � �������� ����� � ������. |
//+-------------------------------------------------------------------------------+

bool CExtrMACDContainer::RecountExtremum(int startIndex, bool fill = false)
{
 if(!_flagFillSucceed || fill)       
 {
  FilltheExtremums(startIndex);
  return (_flagFillSucceed);
 }
 
 CExtremumMACD *new_extr  = new CExtremumMACD(0, -1, 0.0);         // ��������� ���������� � ������� isMACDExtremum 
                                                                   // ������� ������� ��������� (���� �� ����)
 //--------����������� �������� ��������������� ����������------------
 double buf_Value[1];                                       
 int copied = 0;  
 for(int attemps = 0; attemps < 25 && copied <= 0; attemps++)
 {
  copied = CopyBuffer(_handle, 0, startIndex + 2, 1, buf_Value);        
  Sleep(100);                   
 }
 if(copied != 1)                   
 {
  int err = GetLastError();
  Print(__FUNCTION__, "�� ������� �������� ��������� �������", copied, "/1. Error = ", err);
  return(false);
 }
 
 //-------------------���������� ��������--------------------------
 CExtremumMACD *tmp;  
 count = extremums.Total() - 1;
 for(int i = 0; i <= count; i++)
 {
  tmp = extremums.At(i);
  tmp.index++;
  if(tmp.index >= 130)   
  {
   extremums.Delete(i);
   count--;
  }
 } 
 //-------���������� ���������� MACDE � ������ �������------------
 int is_extr_exist = isMACDExtremum(startIndex + 1); 
 if (is_extr_exist != 0)
 { 
  new_extr.direction = is_extr_exist;
  new_extr.index = 2;    
  new_extr.value = buf_Value[0];
  extremums.Insert(new_extr, 0);             
 }   
 return(true);
}            


//+------------------------------------------------------------------+
//|    getCount() - ���������� ���������� ����������� MACD � ������� |
//+------------------------------------------------------------------+
int CExtrMACDContainer::getCount()
{
 return (extremums.Total());
}

CExtremumMACD *CExtrMACDContainer::getExtr(int i)
{
 return extremums.At(i);
}

//+------------------------------------------------------------------+
//|         maxExtr() - ���������� ������������ ��������� � ������� |
//+------------------------------------------------------------------+
CExtremumMACD *CExtrMACDContainer::maxExtr()   //--- ArrayMaximum(extrems,0,whole_array)
{
 CExtremumMACD *temp_Extr = new CExtremumMACD(0, -1, 0);
 int indexMax = 0;
 if(_flagFillSucceed && count > 0)
 {
  int j = 0; 
  double extrMax = -1;
  for(int i = 0; i < count; i++)
  {
   temp_Extr = extremums.At(i);
   if(temp_Extr.direction == 1)
   {
    if(extrMax < temp_Extr.value)
    {
     extrMax = temp_Extr.value;
     indexMax = i;
    }
   }
  }
  return extremums.At(indexMax);
 }
 return temp_Extr;  
}


//+------------------------------------------------------------------+
//|           minExtr() - ���������� ����������� ��������� � ������� |
//+------------------------------------------------------------------+
CExtremumMACD *CExtrMACDContainer::minExtr()  
{
 CExtremumMACD *temp_Extr = new CExtremumMACD(0, -1, 0);
 int indexMin = 0;
 if(_flagFillSucceed && count > 0)
 {
  int j = 0; 
  double extrMin = 1;
  for(int i = 0; i < count; i++)
  {
   temp_Extr = extremums.At(i);
   if(temp_Extr.index < _depth && temp_Extr.direction == -1)
   {
    if(extrMin > temp_Extr.value)
    {
     extrMin = temp_Extr.value;
     indexMin = i;
    }
   }
  }
  return extremums.At(indexMin);
 }
 return temp_Extr;  
}

//+------------------------------------------------------------------+
//             isMACDExtremum - ��������� �������  ���������� MACD.  | 
//                           ���������� 1/-1 ���� ��������� ������   |
//                                            � ��������� ������ 0.  |
//+------------------------------------------------------------------+
int CExtrMACDContainer::isMACDExtremum(int startIndex)
{
 double iMACD_buf[4];
 int copied = 0;
 for(int attemps = 0; attemps < 25 && copied <= 0; attemps++)
 {
  copied = CopyBuffer(_handle, 0, startIndex, 4, iMACD_buf);
  Sleep(100);
 }
 if(copied != 4)
 {
  int err = GetLastError();
  Print(__FUNCTION__, "�� ������� ����������� ������ ���������.", copied, "/4. Error = ", err);
  return(0);
 }

   if ( GreatDoubles(iMACD_buf[2], iMACD_buf[0]) && GreatDoubles(iMACD_buf[2], iMACD_buf[1]) &&
         GreatDoubles(iMACD_buf[2], iMACD_buf[3]) && iMACD_buf[2] > 0)
   {
      return(1);
   }
   else if ( LessDoubles(iMACD_buf[2], iMACD_buf[0]) && LessDoubles(iMACD_buf[2], iMACD_buf[1]) && 
           LessDoubles(iMACD_buf[2], iMACD_buf[3]) && iMACD_buf[2] < 0) 
   {
      return(-1);     
   }
 return(0);
}
