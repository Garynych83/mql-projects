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
double sl, tp;
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
MqlTick tick;
//����� � �������� ������ ��������� � �������� ����� N ������� �����
bool flagMax = true;  //���� � ������ ��������� 
bool flagMin = true;  //���� � ������ ��������
//
bool sellTest = false;
bool buyTest = false;

bool proboy_max = true;  //������� ������ ���������
bool proboy_min = true;  //������� ������ ��������



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
  //����� ��������� �����
  if (  newCisBar.isNewBar()>0 )  //���� ������������� ����� ���
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
          if (flagMax)  //���� ��������� ����� ��������
           {
            MaxPos = ArrayMaximum(high);
            max_value = high[MaxPos];
            flagMax = false; //������ �������� ������
            proboy_max = true; //������ ������ ��� �� ������
            MaxPos--;
           }
          if (flagMin) //���� ��������� ����� �������
           {
            MinPos = ArrayMinimum(low);
            min_value = low[MinPos];
            flagMin = false; //������ ������� ������
            proboy_min = true;  //������ ������ ��� �� ������
            MinPos--;
           }             
         }

       if (!flagMax && proboy_max)  //���� �������� ������ � ������ ��� �� ����
        {
        MaxPos++; //������� ������� ��������� ��������� �����
        if (MaxPos > tN) //���� ��������� ��������� �� �������� ���� ��������� N
          flagMax = true; //�� ��������� � ����� ������ ������ ���������
        }
        
       if (!flagMin && proboy_min)  //���� ������� ������ � ������ ��� �� ����
        {
        MinPos++; //������� ������� ��������� �������� �����
        if (MinPos > tN) //���� ��������� ��������� �� �������� ���� ��������� N
          flagMin = true; //�� ��������� � ����� ������ ������ ���������
        }        
        
     }
    //����� ��������� �����
    //����� �������  
      
      if (!proboy_max) //���� ��� ������ ���������
       {      
        if (diff >= (max_value-tick.ask) ) //��������, ��� ���� �� ��������� ������ ������
         {
            if (!sellTest && tick.ask > max_value) //���� ���� ��������� �����
             {
           //   Alert("��������");
              tp = 0;
              
              sl = NormalizeDouble(MathMax(SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         max_value-tick.ask) / _Point, SymbolInfoInteger(sym, SYMBOL_DIGITS));
               
              trade.OpenPosition(symbol, OP_SELL, volume, sl, tp, 0.0, 0.0, 0.0))
            
                 Alert("���������");
            
             }
            if (sellTest && tick.ask < max_value) //���� ���� ����������
                sellTest = false; //��������� � ����� �������� ����, ��� ���� ���������
             
         }
        else
         {
          flagMax = true;
         }       
       }
       
      if (!proboy_min) //���� ��� ������ ��������
       {      
        if (diff >= (tick.bid-min_value) ) //��������, ��� ���� �� ��������� ������ ������
         {
            if (!buyTest && tick.bid < min_value) //���� ���� ��������� �����
             {
            //   Alert("��������");
              tp = 0;
              sl = NormalizeDouble(MathMax(SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*_Point,
                         tick.bid - min_value) / _Point, SymbolInfoInteger(sym, SYMBOL_DIGITS)); 
                         
              trade.OpenPosition(symbol, OP_BUY, volume, sl, tp, 0.0, 0.0, 0.0))           
             Alert("��������");
             }
            if (buyTest && tick.bid > min_value) //���� ���� ���������
             buyTest = false; //��������� � ����� �������� ����, ��� ���� ���������
         }
        else
         {
          flagMin = true;
         }       
       }       
      
      if (!flagMax && proboy_max) //���� �������� ������
       {
        //�� ���� ������ �� �������
         if (MaxPos>=tn && tick.ask > max_value ) //���� ������ ������
          {
           proboy_max = false;
           sellTest = true;
          }
       } 
      if (!flagMin && proboy_min) //���� ������� ������
       {
        //�� ���� ������ �� ��������
         if (MinPos>=tn && tick.bid < min_value ) //���� ������ ������
          {
           proboy_min = false;
           buyTest = true;
          }
       }        
  }

