#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include  <ColoredTrend/ColoredTrendUtilities.mqh> //�������� ����������� ������
#include <CompareDoubles.mqh>    //��� ��������� �������������� ����������
#include <Lib CisNewBar.mqh>     //��� �������� �����
#include<TradeManager/TradeManager.mqh> //��� ���������� ������

input uint n=4; //���������� �����, ����� ������� ���� �������� ������
input uint N=20; //���������� �����, �� ������� ���� �������� ������
input double diff=0.3; //������� ����� ������
input double   volume = 1;

double high[];   // ������ ������� ��� 
double low[];   // ������ ������ ���
double cur_color[]; //������ ������� ������ ������ 
double max_value=DBL_MAX;   //������������ �������� � ������� high
double min_value=DBL_MIN;   //����������� �������� � ������� low
double new_max_value;
double new_min_value;
double sl, tp;
datetime date_buffer[];          //����� �������
int handle_PBI;     //����� PriceBasedIndicator
int tn; //�������������� �������� ������ ���������� �����
int tN; //�������������� �������� �������� ���������� �����
uint maxPos;     //������� ��������� � ������� high
uint minPos;     //������� �������� � ������� low
CisNewBar newCisBar;     //������ �� ��������� �����
CTradeManager new_trade; //����� ���������� ������

string sym  =  _Symbol;
ENUM_TIMEFRAMES timeFrame=_Period;   //���������
MqlTick tick;
//����� � �������� ������ ��������� � �������� ����� N ������� �����
bool flagMax = false;  //���� � ������ ��������� 
bool flagMin = false;  //���� � ������ ��������


bool proboy_max = false;  //������� ������ ���������
bool proboy_min = false;  //������� ������ ��������



int OnInit()
  {

   handle_PBI = iCustom(sym,timeFrame,"PriceBasedIndicator"); //��������� ����� ���������� PriceBasedIndicator
     
   if(handle_PBI<0)
    {
     Print("�� �������� ������������������� �������� PriceBasedIndicator");
     return INIT_FAILED;
    }
    
   new_trade.Initialization(); //������������� ������� ������ ���������� TradeManeger  
    
   if (n>=N) //���� ��������� �� ���������, �� ���������� �� �� ���������
    {
     tn = 4;
     tN = 20;
    }
   else  //����� ��������� ��������� �������������
    {
     tn = n;
     tN = N;
    }     
    //��������������� ��������
    ArraySetAsSeries(high,true); 
    ArraySetAsSeries(low,true);  
    
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ArrayFree(high); 
   ArrayFree(low);
   ArrayFree(cur_color);
   ArrayFree(date_buffer);   
   new_trade.Deinitialization();  //��������������� ������� ������ ���������� TradeManager
  }
  

void OnTick()
  {
  new_trade.OnTick();
  SymbolInfoTick(sym, tick);
  //����� ��������� �����
  if (  newCisBar.isNewBar()>0 )  //���� ������������� ����� ���
    {
    
    if (!proboy_max) max_value = DBL_MAX;
    if (!proboy_min) min_value = DBL_MIN;
     if( CopyBuffer(handle_PBI, 4, 1, 1, cur_color) <= 0)
        return; 

     if (cur_color[0]==MOVE_TYPE_FLAT ||    //���� ���� ������ � ������������
         cur_color[0]==MOVE_TYPE_CORRECTION_UP || 
         cur_color[0]==MOVE_TYPE_CORRECTION_DOWN)
         {      
            
      if (CopyBuffer(handle_PBI, 1, tn, tN, high) <= 0 || //���� �������� ������ �� �������
          CopyBuffer(handle_PBI, 2, tn, tN, low) <= 0)
          return;
           if (!proboy_max)    //���� ������ ��������� �� ������
            {
            maxPos = ArrayMaximum(high);
            max_value = high[maxPos];
            }
           if (!proboy_min)   //���� ������ �������� �� ������
            {
            minPos = ArrayMinimum(low,1);
            min_value = low[minPos];
            }
         }       
     }
    //����� ��������� �����
      if (!proboy_max) //���� ������ ��������� ��� �� ������
       {
        //�� ���� ������ �� �������
         if (maxPos < tN && tick.bid > max_value ) //���� ������ ������
          {
           proboy_max = true;
           new_max_value = tick.bid;
          }
       } 
     else
       {
         if (diff < (tick.bid-new_max_value) ) //���� ���� ����������� ��������� �����
           {
             proboy_max = false; //�� ��������� � ����� ������ ���������
             max_value = DBL_MAX;
           }
         if (tick.ask < max_value) //���� ���� ��������� �� max_value
           {
             Alert("������ ���������");
           }  
       }  
      if (!proboy_min) //���� ������ �������� ��� �� ������
       {
        //�� ���� ������ �� ��������
         if (minPos>=tn && tick.ask < min_value ) //���� ������ ������
          {
           proboy_min = false;
           new_min_value = tick.bid;
          }
       }    
      else
        {
         if (diff > (new_min_value-tick.ask) ) //���� ���� ����������� ��������� ����
          {
            proboy_min = false; //�� ��������� � ����� ������ ��������
            min_value = DBL_MIN;
          }
         if (tick.bid > min_value)  //���� ���� ��������� �� �������
          {
            Alert("������ ���������");
          } 
        }     
  }

