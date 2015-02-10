//+------------------------------------------------------------------+
//|                                                           DE.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6   // ������������� 4 ������
#property indicator_plots   2   // ��� �� ������� �������������� �� �������

#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW

//+------------------------------------------------------------------+
//| ���������, ������������ ����������                               |
//+------------------------------------------------------------------+
#include <DrawExtremums/TempCExtremum.mqh> // ���������� �����������
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
  // event.AddNewEvent(_Symbol,_Period,event.GenUniqEventName("������������� ���������",_Symbol,_Period) );
   
   event.PrintAllNames();
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
       // ���� ������� ��������� ����������
       if ( extr.isExtremum(extrHigh,extrLow,time[i],false) )
        {
          // ���� ��������� ������� ��������� 
          if (extrHigh.time >= time[i])
           {
            bufferAllExtrHigh[i] = extrHigh.price;       // ��������� � ����� �������� ����������� ����������
            bufferFormedExtrHigh[i] = extrHigh.price; 
            bufferTimeExtrHigh[i] = double(extrHigh.time);
            
            lastExtrUpValue = extrHigh.price;
            lastExtrUpTime  = extrHigh.time;
            //Comment("����� HIGH ����� = ",TimeToString(extrHigh.time) );
            //Generate("����� ���������"                 // ����� ����� ������������ ������� ��������� ������ ����������
            
            if (jumper == -1)
              {
               bufferFormedExtrLow[indexPrevDown] = lastExtrDownValue; // ��������� �������������� ���������         
               bufferTimeExtrLow[indexPrevDown] = double(lastExtrDownTime);    // ��������� ����� ��������������� ����������   
               prevJumper = jumper;   
              //  Generate                               // ����� ����� �������� �������, ��� ������������� ����� ���������
              } 
            jumper = 1;
            indexPrevUp = i;  // ��������� ���������� ������             
           }
          // ���� ��������� ������ ���������
          if (extrLow.time >= time[i])
           {        
            bufferAllExtrLow[i] = extrLow.price;
            bufferFormedExtrLow[i] = extrLow.price;  
            bufferTimeExtrLow[i] = double(extrLow.time);
            lastExtrDownValue = extrLow.price;
            lastExtrDownTime  = extrLow.time;
            //Comment("����� LOW ����� = ",TimeToString(extrLow.time) );            
            //Generate                                   // ����� ����� �������� ������� ��������� ������ ����������
            if (jumper == 1)
             {
              bufferFormedExtrHigh[indexPrevUp] = lastExtrUpValue; // ��������� �������������� ���������
              bufferTimeExtrHigh[indexPrevUp] = double(lastExtrUpTime);  // ��������� ����� ��������������� ����������        
              prevJumper = jumper;
              //Generate                                 // ����� ����� �������� �������, ��� ������������� ����� ���������
             }
            jumper = -1;
            indexPrevDown = i; // ��������� ���������� ������
           }
           
        }
      }
      lastBarTime = time[rates_total-1];   // ��������� ����� ���������� ����
     }
    // ���� � �������� �������
    else
     {              
      // ���� ������� ��������� ���������\����������
      if (  extr.isExtremum(extrHigh,extrLow,time[rates_total-1],true) )
       {
        // ���� ��������� ������� ���������
        if (extrHigh.time >= time[rates_total-1]   )
         {        
          bufferAllExtrHigh[rates_total-1] = extrHigh.price;
          bufferFormedExtrHigh[rates_total-1] = extrHigh.price;  // ����� �������
          bufferTimeExtrHigh[rates_total-1] = double(extrHigh.time);
          lastExtrUpValue = extrHigh.price;
          lastExtrUpTime = extrHigh.time;
          //Comment("����� HIGH ����� = ",TimeToString(extrHigh.time) );          
          // ������� ������� ��� ���� ��������
          Generate("����� ���������",eventData,true); 
          
        //  Print("����� = ",TimeToString(lastExtrUpTime)," ���� = ",DoubleToString(lastExtrUpValue) );
          if (jumper == -1)
           {
            bufferFormedExtrLow[indexPrevDown] = lastExtrDownValue;        // ��������� �������������� ���������
            bufferTimeExtrLow[indexPrevDown] = long(lastExtrDownTime);     // ��������� ����� ��������������� ����������
            prevJumper = jumper;
           }
          jumper = 1;
          indexPrevUp = rates_total-1;
         }
        // ���� ��������� ������ ���������
        if (extrLow.time >= time[rates_total-1])
         {
          bufferAllExtrLow[rates_total-1] = extrLow.price;
          bufferFormedExtrLow[rates_total-1] = extrLow.price;   // ����� �������
          bufferTimeExtrLow[rates_total-1] = double(extrLow.time);
          lastExtrDownValue = extrLow.price;
          lastExtrDownTime = extrLow.time;
          //Comment("����� LOW ����� = ",TimeToString(extrLow.time) );             
          // ������� ������� ��� ���� ��������
          Generate("����� ���������",eventData,true);  
         // Print("����� = ",TimeToString(lastExtrDownTime)," ���� = ",DoubleToString(lastExtrDownValue) );           
          if (jumper == -1)
           {
            bufferFormedExtrHigh[indexPrevUp] = lastExtrUpValue;        // ���������� �������������� ���������
            bufferTimeExtrHigh[indexPrevUp] = long(lastExtrUpTime);     // ��������� ����� ��������������� ����������
            prevJumper = jumper;
           }
          jumper = -1;
          indexPrevDown = rates_total-1;
         }
       }       
     }
     
  /*   if (bufferFormedExtrLow[rates_total-1] == 1.31571)
      Comment(" ������� ��������� = ",DoubleToString(bufferFormedExtrHigh[rates_total-1])," ",TimeToString(datetime(bufferTimeExtrHigh[rates_total-1]) ),
              "\n ������ ��������� = ",DoubleToString(bufferFormedExtrLow[rates_total-1])," ",TimeToString(datetime(bufferTimeExtrLow[rates_total-1]) )  
             );
    */ 
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