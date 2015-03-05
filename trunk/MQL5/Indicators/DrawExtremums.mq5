//+------------------------------------------------------------------+
//|                                                           DE.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6   // ������������� 6 �������
#property indicator_plots   2   // ��� �� ������� �������������� �� �������

#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW

//+------------------------------------------------------------------+
//| ���������, ������������ ����������                               |
//+------------------------------------------------------------------+
#include <DrawExtremums/CExtremum.mqh> // ���������� �����������
#include <CLog.mqh>                        // ��� ���������� � ���
#include <CompareDoubles.mqh>              // ��� ��������� �������������� �����
#include <CEventBase.mqh>                  // ��� ��������� �������     

// ����������� ����������� ���������

// ������������ ������
double bufferFormedExtrHigh[];  // ����� �������������� ������� �����������
double bufferFormedExtrLow[];   // ����� �������������� ������ �����������
double bufferAllExtrHigh[];     // �����, �������� ��� ������� ���������� �� �������
double bufferAllExtrLow[];      // �����, �������� ��� ������ ���������� �� �������
double bufferTimeExtrHigh[];    // ����� ������� �������������� ������� �����������
double bufferTimeExtrLow[];     // ����� ������� �������������� ������ �����������
 
// ��������� ����������

// ������ �����������
int handleForAverBar;      // ����� ���������� ��� ���������� �������� ���� 
int handleIsNewBar;        // ����� ���������� IsNewBar
// ������ ����������
int indexPrevUp   = -1;    // ������ ���������� �������� ����������, �������� ����� ��������
int indexPrevDown = -1;    // ������ ���������� ������� ����������, �������� ����� ��������
int depth;                 // ������� �������
int jumper=0;              // ���������� ��� ����������� �����������
int prevJumper=0;          // ���������� �������� jumper
double lastExtrUpValue;    // �������� ���������� ����������
double lastExtrDownValue;  // �������� ���������� ���������   
datetime lastExtrUpTime;   // ����� ���������� ���������� HIGH
datetime lastExtrDownTime; // ����� ���������� ���������� LOW
datetime lastBarTime = 0;  // ����� ���������� ����
// ������� 
CExtremum  *extr;          // ������ ������ ���������� ����������� 
CEventBase *event;         // ��� ��������� ������� 
SEventData eventData;      // ��������� ����� �������
// ��������� �����������
SExtremum extrHigh = {0,-1,0};      // ��������� ��� �������� �������� ����������
SExtremum extrLow  = {0,-1,0};      // ��������� ��� �������� ������� ����������

ENUM_CAME_EXTR came_extr;  // ���������� ��� �������� ���� ���������� ����������

int OnInit()
  {
   // ������ ������������ ������� �� ��� ����
   depth = Bars(_Symbol,_Period);
   // ������� ����� ���������� ��� ���������� �������� ����
   handleForAverBar = iMA(_Symbol, _Period, 100, 0, MODE_EMA, iATR(Symbol(), _Period, 30));
   if (handleForAverBar == INVALID_HANDLE)
    {
     Print("������ ��� ������������� ���������� DrawExtremums. �� ������� ������� ����� ���������� AverageATR");
     return (INIT_FAILED);
    }
   // ������� ������ ������ ���������� �����������
   extr = new CExtremum(_Symbol, _Period, handleForAverBar);
   if (extr == NULL)
    {
     Print("������ ��� ������������� ���������� DrawExtremums. �� ������� ������� ������ ������ CExtremum");
     return (INIT_FAILED);
    }   
   // ������� ������ ��������� ������� 
   event = new CEventBase(100);
   if (event == NULL)
    {
     Print("������ ��� ������������� ���������� DrawExtremums. �� ������� ������� ������ ������ CEventBase");
     return (INIT_FAILED);
    }
   // ������� �������
   event.AddNewEvent(_Symbol,_Period,"����� ���������");
   event.AddNewEvent(_Symbol,_Period,"���������");

   // ������ ���������� ������������ �������
   SetIndexBuffer(0, bufferFormedExtrHigh, INDICATOR_DATA);
   SetIndexBuffer(1, bufferFormedExtrLow, INDICATOR_DATA);
   SetIndexBuffer(2, bufferAllExtrHigh,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3, bufferAllExtrLow,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4, bufferTimeExtrHigh,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5, bufferTimeExtrLow,INDICATOR_CALCULATIONS);
   
   // ���������� ���������� �������
   ArraySetAsSeries(bufferAllExtrHigh,false);
   ArraySetAsSeries(bufferAllExtrLow,false);
   ArraySetAsSeries(bufferFormedExtrHigh,false);
   ArraySetAsSeries(bufferFormedExtrLow,false);
   ArraySetAsSeries(bufferTimeExtrHigh,false);
   ArraySetAsSeries(bufferTimeExtrLow,false);
    
   // ������ ��� ���������
   PlotIndexSetInteger(0, PLOT_ARROW, 218);
   PlotIndexSetInteger(1, PLOT_ARROW, 217); 
   //
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit (const int reason)
  {   
   //--- ������ ������ �������� ��� ������� ���������������
   Print(__FUNCTION__,"_��� ������� ��������������� = ",reason);  
   // ����������� ������������ ������
   ArrayFree(bufferFormedExtrHigh);
   ArrayFree(bufferFormedExtrLow);
   ArrayFree(bufferAllExtrHigh);
   ArrayFree(bufferAllExtrLow);
   ArrayFree(bufferTimeExtrHigh);
   ArrayFree(bufferTimeExtrLow);
   // ����������� ������������ �����
   IndicatorRelease(handleForAverBar);
   // ������� �������
   delete extr;
  }  
  
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   // ���� ��� ������ ������ ����������
   if(prev_calculated == 0) 
   {   
   if (BarsCalculated(handleForAverBar) < 1)
    {
     return (0);
    }
    // �������� �� ���� ������� � ��������� ���������\����������
    for(int i = 0; i < rates_total;  i++)    
      {
       // �������� �������� �����������
       bufferAllExtrHigh[i]    = 0;
       bufferAllExtrLow[i]     = 0;
       bufferFormedExtrHigh[i] = 0;
       bufferFormedExtrLow[i]  = 0;
       // �������� ��� ������������ ����������
       came_extr = extr.isExtremum(extrHigh,extrLow,time[i],false);
     
          // ���� ���������� ��� ����������
          if (came_extr == CAME_BOTH)
           {
            bufferAllExtrHigh[i] = extrHigh.price;
            bufferAllExtrLow[i] = extrLow.price;
            bufferTimeExtrHigh[i] = double(extrHigh.time);
            bufferTimeExtrLow[i] = double(extrLow.time);
            // ���� ������� ��������� ������ ������ �������
            if (extrHigh.time > extrLow.time)
             {
              // ��������� ��������� �������� ������� ����������
              lastExtrDownValue = extrLow.price;
              lastExtrDownTime  = extrLow.time;
              indexPrevDown = i;
              // ���� �� ����� ��� ������� ���������
              if (jumper == 1)
               {
                jumper = -1;             
               }  
             }
            // ���� ������ ��������� ������ ������ ��������
            if (extrLow.time > extrHigh.time)
             {
              // ��������� ��������� �������� ������� ����������
              lastExtrUpValue = extrHigh.price;
              lastExtrUpTime  = extrHigh.time;
              indexPrevUp = i;
              // ���� �� ����� ��� ������ ���������
              if (jumper == -1)
               {
                jumper = 1;             
               }  
             }             
           }    
              
          // ���� ��������� ������� ��������� 
          if (came_extr == CAME_HIGH)
           {
            bufferAllExtrHigh[i] = extrHigh.price;       // ��������� � ����� �������� ����������� ����������
            bufferTimeExtrHigh[i] = double(extrHigh.time);
            
            lastExtrUpValue = extrHigh.price;
            lastExtrUpTime  = extrHigh.time;
            
            if (jumper == -1)
              {
               bufferFormedExtrLow[indexPrevDown] = lastExtrDownValue; // ��������� �������������� ���������         
               bufferTimeExtrLow[indexPrevDown] = double(lastExtrDownTime);    // ��������� ����� ��������������� ����������             
               prevJumper = jumper;   
              } 
              
            jumper = 1;
            indexPrevUp = i;  // ��������� ���������� ������             
           }
          // ���� ��������� ������ ���������
          if (came_extr == CAME_LOW)
           {        
            bufferAllExtrLow[i] = extrLow.price;
            bufferTimeExtrLow[i] = double(extrLow.time);
            lastExtrDownValue = extrLow.price;
            lastExtrDownTime  = extrLow.time;
            
            if (jumper == 1)
             {
              bufferFormedExtrHigh[indexPrevUp] = lastExtrUpValue; // ��������� �������������� ���������
              bufferTimeExtrHigh[indexPrevUp] = double(lastExtrUpTime);  // ��������� ����� ��������������� ����������                    
              prevJumper = jumper;
             }
            jumper = -1;
            indexPrevDown = i; // ��������� ���������� ������
           }
                 
      }
      lastBarTime = time[rates_total-1];   // ��������� ����� ���������� ����
     }
    // ���� � �������� �������
    else
     {              
      // �������� ��� ���������� ����������
      came_extr = extr.isExtremum(extrHigh,extrLow,time[rates_total-1],true);
      
        // ���� ��������� ������� ���������
        if (came_extr == CAME_HIGH )
         {                
          bufferAllExtrHigh[rates_total-1] = extrHigh.price;
          bufferTimeExtrHigh[rates_total-1] = double(extrHigh.time);
          lastExtrUpValue = extrHigh.price;
          lastExtrUpTime = extrHigh.time;
          // ������ ���������� �� ����������
          eventData.dparam = extrHigh.price;
          eventData.lparam = 1;
          Generate("����� ���������",eventData,true);
          if (jumper == -1)
           {   
            bufferFormedExtrLow[indexPrevDown] = lastExtrDownValue;        // ��������� �������������� ���������
            bufferTimeExtrLow[indexPrevDown] = long(lastExtrDownTime);     // ��������� ����� ��������������� ����������
            // ������ ���������� �� ����������
            eventData.dparam = lastExtrDownValue;
            eventData.lparam = -1;  
            prevJumper = jumper;
            Generate("���������",eventData,true);
           }
          jumper = 1;
          indexPrevUp = rates_total-1;
         }
        // ���� ��������� ������ ���������
        if (came_extr == CAME_LOW)
         {
          
          bufferAllExtrLow[rates_total-1] = extrLow.price;
          bufferTimeExtrLow[rates_total-1] = double(extrLow.time);
          lastExtrDownValue = extrLow.price;
          lastExtrDownTime = extrLow.time;   
          // ������ ���������� �� ����������
          eventData.dparam = extrLow.price;
          eventData.lparam = -1;
          Generate("����� ���������",eventData,true);               
          if (jumper == 1)
           {             
            bufferFormedExtrHigh[indexPrevUp] = lastExtrUpValue;        // ���������� �������������� ���������
            bufferTimeExtrHigh[indexPrevUp] = long(lastExtrUpTime);     // ��������� ����� ��������������� ����������
            // ������ ���������� �� ����������
            eventData.dparam = lastExtrUpValue;  
            eventData.lparam = 1;      
            prevJumper = jumper;          
            Generate("���������",eventData,true);         
           }
          jumper = -1;
          indexPrevDown = rates_total-1;
         }      
     }
     
   return(rates_total);
  }
   
// �������������� ������� ���������� 

// �������� �� ���� �������� � ������� ������� ��� ���
void Generate(string id_nam,SEventData &_data,const bool _is_custom=true)
  {
   // �������� �� ���� �������� �������� � ������� �������� � �� � ���������� ��� ��� �������
   long z = ChartFirst();
   while (z>=0)
     {
      if (ChartSymbol(z) == _Symbol && ChartPeriod(z)==_Period)  // ���� ������ ������ � ������� �������� � �������� 
        {
         // ������� ������� ��� �������� �������
         event.Generate(z,id_nam,_data,_is_custom);
        }
      z = ChartNext(z);      
     }     
  }