//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2012, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
/*����������� ����������� ���������*/
#include <CompareDoubles.mqh>    //��� ��������� �������������� ����������
#include <Lib CisNewBar.mqh>     //��� �������� �����
#include<TradeManager/TradeManager.mqh>

/*�������� ��������� ��� ����� �������������*/
input int      TakeProfit=100;   //take profit
input int      StopLoss=100;     //stop loss
input double   orderVolume = 1;  //����� ������
input ulong    magic = 111222;   //���������� �����
input uint MACDSlowPeriod = 26;  //���� ������� ���������� EMA
input uint MACDFastPeriod = 12;  //���� ������� �������� ���
/*��������� ��� ����� ������������� �������������� ���������� ��������*/
input uint N=20;                 //������� ����������
input uint n=5;                  //����� ����������

/*������������ ������� ��� ��������  iMA, ������� ������� ��� ���������� MACD*/
double _macd[];                  //������ MACD
/*������������ ������� ������� � ������ ���*/
double high[];                   //������� ����
double low[];                    //������ ����
datetime date_buffer[];          //����� �������
/*����� MACD*/
int imacd;
/*������ ��� ������ � ����������*/
CisNewBar newCisBar;             //����� ��� �������� ����� 
CTrade newTrade;                 //����� ��� ������ � ���������
/*��������� ����������*/
int takeProfit;                  //���� ����
int stopLoss;                    //���� ������
int tN;                          //�������������� N
int tn;                          //�������������� n
double point = _Point;           //������ ������
string sym = _Symbol;            //������� ������
ENUM_TIMEFRAMES timeFrame=_Period;   //���������
/*���������� ��� �������� ������� �����������*/
uint index_maxhigh; //������������ ������� � n ����������
uint index_minlow;  //����������� ������ � n ����������
uint index_maxMACD_1; //������������ MACD � n ����������
uint index_minMACD_1; //����������� MACD � n ����������
/*������ ���������� ����������*/
uint index;     //������� 
uint minus_zone; //��������� ����� ��� high
uint plus_zone; //��������� ����� ��� low
int mode;
CTradeManager new_trade; //����� �������

uint slowper; //��������� ������
uint fastper; //������� ������
uint elem[2]={0,0};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*unum*/

enum SCAN_EXTR_TYPE {
MAX_EXTR=0,
MIN_EXTR
};

/*�������������� �������*/

void PrintDeal(SCAN_EXTR_TYPE mytype) //������� ��� �������� ���������� ��� ���������� ������
  {
  if (mytype == MAX_EXTR)
   {
   Print("Max = ",high[index_maxhigh]);
   Print("������ ��������� = ",index_maxhigh);
   PrintFormat("������ Max MACD = %.06f",_macd[elem[0]]);
   Print("������ ������� MAX MACD = ",elem[0]);
   PrintFormat("����� �ax MACD = %.06f",_macd[elem[1]]);
   Print("������ ������ MAX MACD = ",elem[1]);               
    }
   if (mytype == MIN_EXTR)
    {
   Print("Min = ",low[index_minlow]);
   Print("������ �������� = ",index_minlow);
   PrintFormat("������ Min MACD = %.06f",_macd[elem[0]]);
   Print("������ ������� MIN MACD = ",elem[0]);
   PrintFormat("����� �in MACD = %.06f",_macd[elem[1]]);
   Print("������ ������ MIN MACD = ",elem[1]);               
    }    
  }  

uint SearchForExtra (SCAN_EXTR_TYPE scanType,uint current_index)
  {
  switch (scanType)
  {
   case MAX_EXTR:
    if(GreatDoubles(_macd[current_index],_macd[current_index-1]) && GreatDoubles(_macd[current_index],_macd[current_index+1]) && _macd[current_index]>0)
     return  current_index; 
     break;
   case MIN_EXTR:
    if(GreatDoubles(_macd[current_index-1],_macd[current_index]) && GreatDoubles(_macd[current_index+1],_macd[current_index]) && _macd[current_index]<0)
     return current_index; 
     break;              
  }
    return elem[0];
  }
////////
//--------
/////////
bool WhatIsLarger (SCAN_EXTR_TYPE mytype,double val1,double val2) 
 {
 switch (mytype)
  {
   case MAX_EXTR:
    if(GreatDoubles(val1,val2))
     return false;
   break;
   case MIN_EXTR:
    if (GreatDoubles(val2,val1))
     return false;
   break;
  }
  return true;
 }
 


uint  GetDiscrepancy (SCAN_EXTR_TYPE scanType,uint top_index) //�������� �� ���������
 {
  bool sign=false;        //���� ������������� �������
  elem[0] = 0;
  elem[1] = 0;     
  if (top_index<tn)  //���� ������ ������������ ��� ����������� ���� ����� � n 
    {       
    for(index=1;index<tn && (elem[0]=SearchForExtra(scanType,index))==0;)
     index++;
           //���� ��������� � n            
  if (elem[0]) //���� ��������� ������ � n
    {
    for(index=index+1; index<(tN-1) && (WhatIsLarger (scanType,_macd[SearchForExtra(scanType,index)],_macd[elem[0]]) ||  !sign) ;index++)
     {    
      if (scanType == MAX_EXTR && _macd[index]<0) sign=true;
      if (scanType == MIN_EXTR &&_macd[index]>0) sign=true; 
     }   
   if (index<(tN-1) && sign) 
     { 
     elem[1] = index;
     PrintDeal(scanType);                
     return index;
     }
  } 
}   
  return 0;
}  

/*������� �������� ������� */

  
//+------------------------------------------------------------------+
//|/*������� �������������*/                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
/*�������� ��������� ���������� �� ����������������*/
 new_trade.Initialization(); //������������� 
 
  if ( MACDSlowPeriod <= MACDFastPeriod || MACDFastPeriod < 3 )
   {
      Alert("����������� ������� �������! ���������� �� ��������� 26 � 12 ");   
      slowper = 26;
      fastper = 12;
   }
  else 
   {
      slowper = MACDSlowPeriod;
      fastper = MACDFastPeriod;   
   } 

   if(n>=N || N<6) //���� ����� ���������� ������ ��� ����� ����� ����������
     {
      tn=5;
      tN=20;
      Alert("����������� ������� N � n! N ������ ���� ������ n. N=20 � n=5 �� ���������");
     }
   else
     {
      tn=n;
      tN=N;
     }
/*������������� ���������� MACD*/
   imacd=iMACD(sym,timeFrame,fastper,slowper,9,PRICE_CLOSE);
   if(imacd<0)
      return INIT_FAILED;

/*��������������� ��������*/
   ArraySetAsSeries(_macd,true);       //���������������� ������ iMA(26) 
   ArraySetAsSeries(high, true);         //���������������� ������ high
   ArraySetAsSeries(low, true);          //���������������� ������ low
   ArraySetAsSeries(date_buffer,true);
/*���������� ��������� ����������*/

   stopLoss=StopLoss;
   takeProfit=TakeProfit;
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| /*������� ���������������*/                                      |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
/*������������ ������ ��� ������������ �������*/
   ArrayFree(_macd);
   ArrayFree(high);
   ArrayFree(low);
   ArrayFree(date_buffer);
     new_trade.Deinitialization();
  }


//+------------------------------------------------------------------+
//|/*�������,���������� ��� ��������� ���������*/                    |
//+------------------------------------------------------------------+
void OnTick()
  {
 uint tmp_val;
 if(Bars(sym,timeFrame)>=tN && newCisBar.isNewBar()>0) //���� ���������� ����� ������ N � ������ ����� ���
  {        
   if (CopyBuffer(imacd,0,1,tN,_macd)<=0 ) 
     {
      Alert("�� �������� ����������� ����� MACD");
      return;
     }
   if (CopyHigh(sym,0,1,tN,high)<=0 ) 
     {
      Alert("�� �������� ����������� ����� HIGH");
      return;
     }      
    if (CopyLow(sym,0,1,tN,low)<=0 ) 
     {
      Alert("�� �������� ����������� ����� LOW");
      return;
     }      
    if (CopyTime(sym,0,1,tN,date_buffer)<=0 ) 
     {
      Alert("�� �������� ����������� ����� ���� � �������");
      return;
     }                  
/*��������� ����������*/
  index_maxhigh=0; //������������ ������� � n ����������
  index_minlow=0;  //����������� ������ � n ����������
  index_maxMACD_1=0; //������������ MACD � n ����������
  index_minMACD_1=0; //����������� MACD � n ���������� 
      // ���� ��������� ������������ �������� ����
  for(index=1;index<tN;index++) //����� �������� ��������� � ��������
   {
    if(GreatDoubles(high[index],high[index_maxhigh]))index_maxhigh=index;
    if(GreatDoubles(low[index_minlow],low[index])) index_minlow=index; 
   }     
    //����� ���������� ��������� � �������� MACD     
     index_maxMACD_1 = GetDiscrepancy(MAX_EXTR,index_maxhigh);
     index_minMACD_1 = GetDiscrepancy(MIN_EXTR,index_minlow);         
    if (index_maxMACD_1>0 && index_minMACD_1>0)
      {
      if(index_maxMACD_1<index_minMACD_1)
       new_trade.OpenPosition(sym,OP_SELL,orderVolume,stopLoss,takeProfit,0,0,0);
    else
       new_trade.OpenPosition(sym,OP_BUY,orderVolume,stopLoss,takeProfit,0,0,0);
      }
    else if (index_maxMACD_1>0) 
      {
       new_trade.OpenPosition(sym,OP_BUY,orderVolume,stopLoss,takeProfit,0,0,0);
      }
    else if (index_minMACD_1>0)
      {
       new_trade.OpenPosition(sym,OP_SELL,orderVolume,stopLoss,takeProfit,0,0,0);
      } 
     }
  }
//+------------------------------------------------------------------+
