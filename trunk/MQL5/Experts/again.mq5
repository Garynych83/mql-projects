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

double high[];   // ������ ������� ��� 
double low[];   // ������ ������ ���
double cur_color[]; //������ ������� ������ ������ 
double max_value=DBL_MIN;   //������������ �������� � ������� high
double min_value=DBL_MAX;   //����������� �������� � ������� low
datetime date_buffer[];          //����� �������
int handle_PBI;     //����� PriceBasedIndicator
int tn; //�������������� �������� ������ ���������� �����
int tN; //�������������� �������� �������� ���������� �����
uint MaxPos;     //������� ��������� � ������� high
uint MinPos;     //������� �������� � ������� low
CisNewBar newCisBar;     //������ �� ��������� �����
CTradeManager new_trade; //����� ���������� ������

string sym  =  _Symbol;
ENUM_TIMEFRAMES timeFrame=_Period;   //���������

uint mode = 0; //����� �������

MqlTick tick;


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
    ArraySetAsSeries(cur_color,true);
    ArraySetAsSeries(date_buffer,true);    
    
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
  if (  newCisBar.isNewBar()>0 )  //���� ������������� ����� ���
    {
    if (mode == 0) //����� �������� �����
     {
     if( CopyBuffer(handle_PBI, 4, 1, 1, cur_color) <= 0)
        return;  
     if (cur_color[0]==MOVE_TYPE_FLAT ||    //���� ���� ������ � ������������
         cur_color[0]==MOVE_TYPE_CORRECTION_UP || 
         cur_color[0]==MOVE_TYPE_CORRECTION_DOWN)
         {
         
      if (CopyBuffer(handle_PBI, 1, 1, tN, high) <= 0 || //���� �������� ������ �� �������
          CopyBuffer(handle_PBI, 2, 1, tN, low) <= 0)
          return;
          mode=1;
          MaxPos = ArrayMaximum(high);
          MinPos = ArrayMaximum(low);
          max_value = high[MaxPos];
          min_value = low[MinPos];
          MaxPos--;
          MinPos--;
         }
     } 
     else if (mode == 1) //����� ��������
      {
        MaxPos++;
        MinPos++;
        if (MaxPos > tN && MinPos>tN)
          mode = 0; 
      }    
    }
  //����� �����
    switch (mode)
     {
      case 1:
      if (MaxPos>=tn && MaxPos<=tN && tick.bid > max_value) //������ ���������
        {
         mode=2; //������� � ����� �������� �������
        }
      
      if (MinPos>=tn && MinPos<=tN && tick.ask < min_value) //������ �������� 
        {
         mode=3; //������� � ����� �������� �������
        }    
      break;
      case 2: //�������� �������
      
      if (tick.bid < max_value)  //���� ���� ��������� �����
        {
          //������ � ������� ���������     
        }
      if (diff < MathAbs(max_value-tick.bid) && max_value < tick.bid)
        {
          mode = 0;
          //������� � ��������� �����. ������ �� ���������
        }
      
      break;   
      case 3: //�������� �������
      
      if (tick.ask > min_value) //���� ���� ��������� �����
        {
          //������ � ������� ���������
        }
      if (diff < MathAbs(min_value-tick.ask) && min_value < tick.ask)
        {
          mode = 0;
          //������� � ��������� �����. ������ �� ���������
        }   
      
      break;
       
     }  
    
  
  }

