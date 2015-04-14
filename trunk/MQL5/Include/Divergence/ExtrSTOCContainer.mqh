//+------------------------------------------------------------------+
//|                                            ExtrSTOCContainer.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>     // ��� ��������� ������������ ����������
#include <Constants.mqh>          // ���������� ���������� ��������
#include <Arrays/ArrayObj.mqh>
#include <Divergence/CExtremumSTOC.mqh>

#define DEPTH_STOC 20                  // ������� �� ������� ���� ����������� ����������
#define BORDER_DEPTH 3                 // ���������� ����� ��� ������� �� ������� ������ ��������� ����         

//+----------------------------------------------------------------------------------------------+
//|            ����� CExtrSTOCContainer ������������ ��� �������� � ���������� ����������� MACD  |
//                                                          �� ������������ ������� DEPTH_MACD.  |
//+----------------------------------------------------------------------------------------------+

class CExtrSTOCContainer
{
private:
 CArrayObj        extremums;                        // ������ ����������� STOC
 double           valueSTOCbuffer[DEPTH_STOC];      // ������ �������� STOC �� ������� DEPTH_STOC
 datetime         date_buf[DEPTH_STOC];             // ������ ���� ��������� ����������
 bool             _flagFillSucceed;                 // ���� ��������� ���������� ����������
 int              _handle;
 string           _symbol;
 ENUM_TIMEFRAMES  _period;
 
public:
 CExtrSTOCContainer();
 ~CExtrSTOCContainer();
 CExtrSTOCContainer(string symbol, ENUM_TIMEFRAMES period, int handleMACD, int startIndex);
 
 //---------------������ ��� ������ � �������-------------------
 int isSTOCExtremum(int startIndex);                         // ������� ���� �� ���������� �� ������ ����
 void FilltheExtremums(int startIndex);                      // ��������� ���������                                    
    //--------------����������� ������-----------------------------------------------
 CExtremumSTOC *getExtr(int i);                              // ���������� i-�� ������� �������
 bool RecountExtremum(int startIndex, bool fill = false);    // ���������� ������ �����������
 CExtremumSTOC *maxExtr();                                   // ���������� ��������� STOC � ������������ ���������
 CExtremumSTOC *minExtr();                                   // ���������� ��������� STOC � �����������  ���������
 int getCount();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrSTOCContainer::CExtrSTOCContainer(string symbol, ENUM_TIMEFRAMES period, int handle, int startIndex)    
{
 _symbol = symbol;
 _period = period;
 _handle = handle;
 FilltheExtremums(startIndex);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtrSTOCContainer::~CExtrSTOCContainer()
{
 extremums.Clear();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

  
//+------------------------------------------------------------------+
//                                                                   |
//            FilltheExtremums ��������� ��������� ������������ STOC |
//                           ������� � startIndex �� ������� _depth. |
//+------------------------------------------------------------------+

void CExtrSTOCContainer::FilltheExtremums(int startIndex)
{
 int copiedSTOC = 0;
 int copiedDate = 0;
 //extremums.Clear();
 Print(__FUNCTION__," was here");
 //----------����������� �������� STOC � ����� valueSTOCbuffer-------
 for(int attemps = 0; attemps < 25 && copiedSTOC <= 0; attemps++)
 {
  copiedSTOC = CopyBuffer(_handle, 0, startIndex , DEPTH_STOC, valueSTOCbuffer); //DEPTH_STOC-1 ������ ��� �� �������� �� ���������� ����� ��������   
  copiedDate = CopyTime(_symbol, _period, startIndex, DEPTH_STOC, date_buf); 
  Sleep(100);
 }
 
 if(copiedSTOC != DEPTH_STOC || copiedDate != DEPTH_STOC)
 {
  int err = GetLastError();
  Print(__FUNCTION__, " �� ������� ����������� ������ ���������. /. Error = ", err);
  _flagFillSucceed = false;
  return;
 }
 //-----------------------���������� ����������---------------------
 int indexForExtremum = startIndex;                       
 int extremRslt = 0;
 int i, j = 2 , ind = DEPTH_STOC - 2;
 for(i = 0; indexForExtremum - startIndex  <= DEPTH_STOC - 3 ; indexForExtremum++) //�� 0��� �� 17
 {
  extremRslt = isSTOCExtremum(indexForExtremum);  // �������� �� ��������� STOC
  if(extremRslt != 0)                             // ���� ������� ������� ��������� 
  {
   CExtremumSTOC *new_extr = new CExtremumSTOC(); // ����� ��������� 
   new_extr.direction = extremRslt;               // ��������� �����������
   new_extr.index = j;                            // ��������� ������ ������������� _depth (�.� ������� ������� - [0 + 2])
   new_extr.value = valueSTOCbuffer[ind];         // �������� ����������
   new_extr.time  = date_buf[ind];
   extremums.Add(new_extr);                       // ���������� ���������� � ������ 
   i++;
  }
  j++; 
  ind--;
 }
 _flagFillSucceed = true; 
 return;
} 
//+-------------------------------------------------------------------------------+
//                                                                                |
//            RecountExtremum ������������� �������� ��� ����������� ������ ����, | 
//                                             � ����� ��� ���������� ����������. |
//                        ����� �������, RecountExtremum �������� � ���� �������: |
//                        � ����������� �� ����� fill ����� ��������� ����������, |
//        � ����� ����������� ������� ����������� STOC � �������� ����� � ������. |
//                                     �����: ���� ������� ����������� ���������� |
//                                � �������� �������� ���� (�������� startIndex), |
//                             �� RecountExtremum �� ���� ����� (startIndex + 1). |
//+-------------------------------------------------------------------------------+

bool CExtrSTOCContainer::RecountExtremum(int startIndex, bool fill = false)
{
 if(!_flagFillSucceed || fill)       
 {
  FilltheExtremums(startIndex);
  return (_flagFillSucceed);
 }

 //--------����������� �������� ��������������� ����������------------
 double buf_Value[1];                                       
 int copiedSTOC = 0; 
 int copiedDate = 0; 
 for(int attemps = 0; attemps < 25 && copiedSTOC <= 0; attemps++)
 {
  copiedSTOC = CopyBuffer(_handle, 0, startIndex + 1, 1, buf_Value);   
  copiedDate = CopyTime(_symbol, _period, startIndex + 2, 1, date_buf); 
  Sleep(100);                   
 }
 if(copiedSTOC != 1 || copiedDate != 1)                   
 {
  int err = GetLastError();
  Print(__FUNCTION__, "�� ������� �������� ��������� �������. Error = ", err);
  return(false);
 }
 
 //-------------------���������� ��������--------------------------
 CExtremumSTOC *tmp;  
 for(int i = extremums.Total() - 1; i >= 0; i--)
 {
  tmp = extremums.At(i);
  tmp.index++;
  if(tmp.index >= DEPTH_STOC)   
  {
   extremums.Delete(i);
  }
 }
 //tmp = extremums.At(0);
 //if(buf_Value[0]==tmp.value) 
 //-------���������� ���������� STOC � ������ �������------------
 int is_extr_exist = isSTOCExtremum(startIndex); 
 if(is_extr_exist != 0)
 {
  CExtremumSTOC *new_extr = new CExtremumSTOC();                                                    
  new_extr.direction = is_extr_exist;
  new_extr.index = 2;    
  new_extr.value = buf_Value[0];
  new_extr.time = date_buf[0];
  extremums.Insert(new_extr, 0);             
 }  
 //Print("New extremum  index = ", new_extr.index, " value = ", new_extr.value, " time = ",date_buf[0]);
 return(true);
}            


//+------------------------------------------------------------------+
//|    getCount() - ���������� ���������� ����������� STOC � ������� |
//+------------------------------------------------------------------+
int CExtrSTOCContainer::getCount()
{
 return (extremums.Total());
}

CExtremumSTOC *CExtrSTOCContainer::getExtr(int i)
{
 return extremums.At(i);
}

//+------------------------------------------------------------------+
//|         maxExtr() - ���������� ������������ ��������� � �������  |
//+------------------------------------------------------------------+
CExtremumSTOC *CExtrSTOCContainer::maxExtr()   
{
 CExtremumSTOC *temp_Extr;
 int indexMax = 0;
 if(_flagFillSucceed && extremums.Total() > 0)
 {
  int j = 0; 
  double extrMax = -1;
  for(int i = 0; i < extremums.Total(); i++)
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
 return  new CExtremumSTOC(0, -1, 0, 0);  
}


//+------------------------------------------------------------------+
//|           minExtr() - ���������� ����������� ��������� � ������� |
//+------------------------------------------------------------------+
CExtremumSTOC *CExtrSTOCContainer::minExtr()  
{
 CExtremumSTOC *temp_Extr;
 int indexMin = 0;
 if(_flagFillSucceed && extremums.Total() > 0)
 {
  int j = 0; 
  double extrMin = 1000;
  for(int i = 0; i < extremums.Total(); i++)
  {
   temp_Extr = extremums.At(i);
   if(temp_Extr.direction == -1)
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
 return  new CExtremumSTOC(0, 1, 0, 0);  
}

//+------------------------------------------------------------------+
//             isMACDExtremum - ��������� �������  ���������� MACD.  | 
//                           ���������� 1/-1 ���� ��������� ������   |
//                                            � ��������� ������ 0.  |
//+------------------------------------------------------------------+
int CExtrSTOCContainer::isSTOCExtremum(int startIndex)
{
 //if (startIndex < 1) return 0;
 double iSTOC_buf[3];
 int copiedSTOC = 0;
 for(int attemps = 0; attemps < 25 && copiedSTOC <= 0; attemps++)
 {
  Sleep(100);
  copiedSTOC = CopyBuffer(_handle, 0, startIndex, 3, iSTOC_buf);
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
