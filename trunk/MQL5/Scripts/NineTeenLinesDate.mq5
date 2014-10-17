//+------------------------------------------------------------------+
//|                                            NineTeenLinesDate.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
// ������ ���������� ������ �������� ����

// ���������� ����������� ����������
#include <NineTeenLines\CDrawLevel.mqh>
// ������� ��������� �������
input datetime date   = "";        // ����
input bool     useH1  = true;      // ������������ ������� ������
input bool     useH4  = true;      // ������������ 4-� ������� ������
input bool     useD1  = true;      // ������������ ������� ������
input bool     useW1  = true;      // ������������ ��������� ������
input bool     useMN1 = true;      // ������������ �������� ������
// ���������� ���������� �������
int handle_19Lines;                // ����� ���������� NineTeenLines
// ������� ������ ������� 
CDrawLevel *levelH1;               // ������� ������
CDrawLevel *levelH4;               // 4-x ������� ������
CDrawLevel *levelD1;               // ������� ������
CDrawLevel *levelW1;               // ��������� ������
CDrawLevel *levelMN1;              // �������� ������
// ������������ ������
// ������� ������
double priceH1_1[];                 
double atrH1_1[];  
double priceH1_2[];                 
double atrH1_2[]; 
double priceH1_3[];                 
double atrH1_3[]; 
double priceH1_4[];                 
double atrH1_4[];     
// 4-� ������� ������
double priceH4_1[];                 
double atrH4_1[];  
double priceH4_2[];                 
double atrH4_2[]; 
double priceH4_3[];                 
double atrH4_3[]; 
double priceH4_4[];                 
double atrH4_4[]; 
// ������� ������
double priceD1_1[];                 
double atrD1_1[];  
double priceD1_2[];                 
double atrD1_2[]; 
double priceD1_3[];                 
double atrD1_3[]; 
double priceD1_4[];                 
double atrD1_4[]; 
// ��������� ������
double priceW1_1[];                 
double atrW1_1[];  
double priceW1_2[];                 
double atrW1_2[]; 
double priceW1_3[];                 
double atrW1_3[]; 
double priceW1_4[];                 
double atrW1_4[]; 
// �������� ������
double priceMN1_1[];                 
double atrMN1_1[];  
double priceMN1_2[];                 
double atrMN1_2[]; 
double priceMN1_3[];                 
double atrMN1_3[]; 
double priceMN1_4[];                 
double atrMN1_4[];                
      
void OnStart()
  {    
   handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines",
                            "",3,3,
                            "","",useMN1,0.1,
                            "",useW1,0.15,
                            "",useD1,0.25,
                            "",useH4,0.25,
                            "",useH1,0.25,
                            "",false
                           );     
   if (handle_19Lines == INVALID_HANDLE)
   {
    Print("������ ��� ������������� �������� SimpleTrend. �� ������� �������� ����� NineteenLines");
    return;
   }    
   // ������� �������������� ����� ��� ������� ������  
   if(useMN1)  levelMN1 = new CDrawLevel(0,0,true); 
   if(useW1)   levelW1  = new CDrawLevel(0,0,true);
   if(useD1)   levelD1  = new CDrawLevel(0,0,true); 
   if(useH4)   levelH4  = new CDrawLevel(0,0,true);
   if(useH1)   levelH1  = new CDrawLevel(0,0,true); 
   // ��������� ������ �������
   
   // ���� ������������ ������� ������
   if (useD1)
    {
     // ���� ������� ���������� ������� ������
     if ( (CopyBuffer(handle_19Lines,16,date,1,priceD1_1) < 1 ) ||
          (CopyBuffer(handle_19Lines,17,date,1,priceD1_2) < 1 ) ||
          (CopyBuffer(handle_19Lines,18,date,1,priceD1_3) < 1 ) ||
          (CopyBuffer(handle_19Lines,19,date,1,priceD1_4) < 1 ) ||
          (CopyBuffer(handle_19Lines,20,date,1,atrD1_1) < 1 )   ||
          (CopyBuffer(handle_19Lines,21,date,1,atrD1_2) < 1 )   ||
          (CopyBuffer(handle_19Lines,22,date,1,atrD1_3) < 1 )   ||
          (CopyBuffer(handle_19Lines,23,date,1,atrD1_4) < 1 )   )
        
        {
         Print("�� ������� ���������� ������� ������");
         return;
        }
    }
   // ���� ������������ ������� ������
   if (useH1)
    {
     // ���� ������� ���������� ������� ������
     if ( (CopyBuffer(handle_19Lines,32,date,1,priceH1_1) < 1 ) ||
          (CopyBuffer(handle_19Lines,33,date,1,priceH1_2) < 1 ) ||
          (CopyBuffer(handle_19Lines,34,date,1,priceH1_3) < 1 ) ||
          (CopyBuffer(handle_19Lines,35,date,1,priceH1_4) < 1 ) ||
          (CopyBuffer(handle_19Lines,36,date,1,atrH1_1) < 1 )   ||
          (CopyBuffer(handle_19Lines,37,date,1,atrH1_2) < 1 )   ||
          (CopyBuffer(handle_19Lines,38,date,1,atrH1_3) < 1 )   ||
          (CopyBuffer(handle_19Lines,39,date,1,atrH1_4) < 1 )   )
        
        {
         Print("�� ������� ���������� ������� ������");
         return;
        }
    }
   // ���� ������������ ������� ������
   if (useH4)
    {
     // ���� ������� ���������� 4-� ������� ������
     if ( (CopyBuffer(handle_19Lines,24,date,1,priceH4_1) < 1 ) ||
          (CopyBuffer(handle_19Lines,25,date,1,priceH4_2) < 1 ) ||
          (CopyBuffer(handle_19Lines,26,date,1,priceH4_3) < 1 ) ||
          (CopyBuffer(handle_19Lines,27,date,1,priceH4_4) < 1 ) ||
          (CopyBuffer(handle_19Lines,28,date,1,atrH4_1) < 1 )   ||
          (CopyBuffer(handle_19Lines,29,date,1,atrH4_2) < 1 )   ||
          (CopyBuffer(handle_19Lines,30,date,1,atrH4_3) < 1 )   ||
          (CopyBuffer(handle_19Lines,31,date,1,atrH4_4) < 1 )   )
        
        {
         Print("�� ������� ���������� 4-� ������� ������");
         return;
        }
    }
   // ���� ������������ �������� ������
   if (useMN1)
    {
     // ���� ������� ���������� �������� ������
     if ( (CopyBuffer(handle_19Lines,0,date,1,priceMN1_1) < 1 ) ||
          (CopyBuffer(handle_19Lines,1,date,1,priceMN1_2) < 1 ) ||
          (CopyBuffer(handle_19Lines,2,date,1,priceMN1_3) < 1 ) ||
          (CopyBuffer(handle_19Lines,3,date,1,priceMN1_4) < 1 ) ||
          (CopyBuffer(handle_19Lines,4,date,1,atrMN1_1) < 1 )   ||
          (CopyBuffer(handle_19Lines,5,date,1,atrMN1_2) < 1 )   ||
          (CopyBuffer(handle_19Lines,6,date,1,atrMN1_3) < 1 )   ||
          (CopyBuffer(handle_19Lines,7,date,1,atrMN1_4) < 1 )   )
        
        {
         Print("�� ������� ���������� �������� ������");
         return;
        }
    }
   // ���� ������������ ��������� ������
   if (useW1)
    {
     // ���� ������� ���������� ��������� ������
     if ( (CopyBuffer(handle_19Lines,8,date,1,priceW1_1) < 1 ) ||
          (CopyBuffer(handle_19Lines,9,date,1,priceW1_2) < 1 ) ||
          (CopyBuffer(handle_19Lines,10,date,1,priceW1_3) < 1 ) ||
          (CopyBuffer(handle_19Lines,11,date,1,priceW1_4) < 1 ) ||
          (CopyBuffer(handle_19Lines,12,date,1,atrW1_1) < 1 )   ||
          (CopyBuffer(handle_19Lines,13,date,1,atrW1_2) < 1 )   ||
          (CopyBuffer(handle_19Lines,14,date,1,atrW1_3) < 1 )   ||
          (CopyBuffer(handle_19Lines,15,date,1,atrW1_4) < 1 )   )
        
        {
         Print("�� ������� ���������� ��������� ������");
         return;
        }
    }    
   // ���� �� ������� ���������� 
   if (useD1)            
    {
     levelD1.SetLevel("D1_1",priceD1_1[0],atrD1_1[0],clrRed);
     levelD1.SetLevel("D1_2",priceD1_2[0],atrD1_2[0],clrRed);
     levelD1.SetLevel("D1_3",priceD1_3[0],atrD1_3[0],clrRed);
     levelD1.SetLevel("D1_4",priceD1_4[0],atrD1_4[0],clrRed);               
    }
   // ���� �� ������� ���������� 
   if (useH1)            
    {
     levelH1.SetLevel("H1_1",priceH1_1[0],atrH1_1[0],clrBlue);
     levelH1.SetLevel("H1_2",priceH1_2[0],atrH1_2[0],clrBlue);
     levelH1.SetLevel("H1_3",priceH1_3[0],atrH1_3[0],clrBlue);
     levelH1.SetLevel("H1_4",priceH1_4[0],atrH1_4[0],clrBlue);  
     Comment ( 
               "priceH1_1 = ",DoubleToString(priceH1_1[0]),
               "atrH1_1 = ",DoubleToString(atrH1_1[0]),   
               "priceH1_2 = ",DoubleToString(priceH1_2[0]),
               "atrH1_2 = ",DoubleToString(atrH1_2[0]),   
               "priceH1_3 = ",DoubleToString(priceH1_3[0]),
               "atrH1_3 = ",DoubleToString(atrH1_3[0]),   
               "priceH1_4 = ",DoubleToString(priceH1_4[0]),
               "atrH1_4 = ",DoubleToString(atrH1_4[0])                                                            
             );             
    }
   // ���� �� ������� ���������� 
   if (useH4)            
    {
     levelH4.SetLevel("H4_1",priceH4_1[0],atrH4_1[0],clrYellow);
     levelH4.SetLevel("H4_2",priceH4_2[0],atrH4_2[0],clrYellow);
     levelH4.SetLevel("H4_3",priceH4_3[0],atrH4_3[0],clrYellow);
     levelH4.SetLevel("H4_4",priceH4_4[0],atrH4_4[0],clrYellow);               
    }
   // ���� �� ������� ���������� 
   if (useMN1)            
    {
     levelMN1.SetLevel("MN1_1",priceMN1_1[0],atrMN1_1[0],clrGreen);
     levelMN1.SetLevel("MN1_2",priceMN1_2[0],atrMN1_2[0],clrGreen);
     levelMN1.SetLevel("MN1_3",priceMN1_3[0],atrMN1_3[0],clrGreen);
     levelMN1.SetLevel("MN1_4",priceMN1_4[0],atrMN1_4[0],clrGreen);               
    }
   // ���� �� ������� ���������� 
   if (useW1)            
    {
     levelW1.SetLevel("W1_1",priceW1_1[0],atrW1_1[0],clrOrange);
     levelW1.SetLevel("W1_2",priceW1_2[0],atrW1_2[0],clrOrange);
     levelW1.SetLevel("W1_3",priceW1_3[0],atrW1_3[0],clrOrange);
     levelW1.SetLevel("W1_4",priceW1_4[0],atrW1_4[0],clrOrange);               
    }                
   // ����������� ������ ����������� 
   IndicatorRelease(handle_19Lines);      

   // ����������� ������
   ArrayFree(priceD1_1);
   ArrayFree(priceD1_2);   
   ArrayFree(priceD1_3);
   ArrayFree(priceD1_4); 
   ArrayFree(atrD1_1);   
   ArrayFree(atrD1_2); 
   ArrayFree(atrD1_3); 
   ArrayFree(atrD1_4); 

   ArrayFree(priceH1_1);
   ArrayFree(priceH1_2);   
   ArrayFree(priceH1_3);
   ArrayFree(priceH1_4); 
   ArrayFree(atrH1_1);   
   ArrayFree(atrH1_2); 
   ArrayFree(atrH1_3); 
   ArrayFree(atrH1_4);
   
   ArrayFree(priceH4_1);
   ArrayFree(priceH4_2);   
   ArrayFree(priceH4_3);
   ArrayFree(priceH4_4); 
   ArrayFree(atrH4_1);   
   ArrayFree(atrH4_2); 
   ArrayFree(atrH4_3); 
   ArrayFree(atrH4_4);
   
   ArrayFree(priceW1_1);
   ArrayFree(priceW1_2);   
   ArrayFree(priceW1_3);
   ArrayFree(priceW1_4); 
   ArrayFree(atrW1_1);   
   ArrayFree(atrW1_2); 
   ArrayFree(atrW1_3); 
   ArrayFree(atrW1_4);
   
   ArrayFree(priceMN1_1);
   ArrayFree(priceMN1_2);   
   ArrayFree(priceMN1_3);
   ArrayFree(priceMN1_4); 
   ArrayFree(atrMN1_1);   
   ArrayFree(atrMN1_2); 
   ArrayFree(atrMN1_3); 
   ArrayFree(atrMN1_4);                          
   // ������� ������� �������
   delete levelD1;
   delete levelH1;
   delete levelH4;
   delete levelMN1;
   delete levelW1;
  }