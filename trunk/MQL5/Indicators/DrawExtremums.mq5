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
// ����������� ����������� ���������
//#include <DrawExtremums/CCalcExtremums.mqh>// ���������� �����������
#include <CLog.mqh>                        // ��� ���������� � ���
#include <CompareDoubles.mqh>              // ��� ��������� �������������� �����
#include <CEventBase.mqh>                  // ��� ��������� �������     
#include <DrawExtremums\CExtremum.mqh>      // ����� �����������
#include <StringUtilities.mqh>             
#include <CLog.mqh>                        // ��� ����

#define DEFAULT_PERCENTAGE_ATR 1.0   // �� ��������� ����� ��������� ���������� ����� ������� ������ �������� ����

// ������������ ��� ���� ���������� ����������
enum ENUM_CAME_EXTR
{
 CAME_HIGH = 0,
 CAME_LOW = 1,
 CAME_BOTH = 2,
 CAME_NOTHING = 3
};

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
double averageATR;        // ������� �������� ����
double percentage_ATR;     // ���������� ���������� �� �� �� ������� ��� �������� ���� ������
                           // ��������� ������� ��� ��� �� �������� ����� ��������� 
                           
double lastExtrUpValue;    // �������� ���������� ����������
double lastExtrDownValue;  // �������� ���������� ���������   
datetime lastExtrUpTime;   // ����� ���������� ���������� HIGH
datetime lastExtrDownTime; // ����� ���������� ���������� LOW
datetime lastBarTime = 0;  // ����� ���������� ����

// ������� 
CEventBase *event;         // ��� ��������� ������� 
SEventData eventData;      // ��������� ����� �������
// ��������� �����������
CExtremum *extrHigh;       // ��������� ��� �������� �������� ����������
CExtremum *extrLow;        // ��������� ��� �������� ������� ����������

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
 //��������� ����������� ATR � ����������� �� �������
 GetATRCoefficient(_Period);
 
 // ���������� �������� �������� ����
 averageATR = AverageBar(TimeCurrent());

 // ������� ������ ��������� ������� 
 extrHigh = new CExtremum(0,-1);
 extrLow = new CExtremum(0,-1);
 event = new CEventBase(_Symbol, _Period, 100);
 if (event == NULL)
 {
  Print("������ ��� ������������� ���������� DrawExtremums. �� ������� ������� ������ ������ CEventBase");
  return (INIT_FAILED);
 }
 // ������� �������
 event.AddNewEvent("EXTR_UP");
 event.AddNewEvent("EXTR_UP_FORMED");
 event.AddNewEvent("EXTR_DOWN");
 event.AddNewEvent("EXTR_DOWN_FORMED");      
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
   delete event;
   delete extrHigh;
   delete extrLow;
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
     came_extr = isExtremum(time[i],false);
    
     // ���� ���������� ��� ����������
     if (came_extr == CAME_BOTH)
     {
      bufferAllExtrHigh[i] = extrHigh.price;
      bufferAllExtrLow[i]  = extrLow.price;            
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
    came_extr = isExtremum(time[rates_total-1],true);
      
    // ���� ��������� ������� ���������
    if (came_extr == CAME_HIGH )
    {            
     bufferAllExtrHigh[rates_total-1] = extrHigh.price;
     bufferTimeExtrHigh[rates_total-1] = double(extrHigh.time);
          
     lastExtrUpValue = extrHigh.price;
     lastExtrUpTime = extrHigh.time;
     // ������ ���������� �� ����������
     eventData.dparam = extrHigh.price;
     eventData.lparam = long(extrHigh.time);
     event.Generate("EXTR_UP",eventData,true);
     if (jumper == -1)
     {   
      bufferFormedExtrLow[indexPrevDown] = lastExtrDownValue;        // ��������� �������������� ���������
      bufferTimeExtrLow[indexPrevDown] = long(lastExtrDownTime);     // ��������� ����� ��������������� ����������
      // ������ ���������� �� ����������
      eventData.dparam = lastExtrDownValue;
      eventData.lparam = long(lastExtrDownTime);  
      prevJumper = jumper;
      event.Generate("EXTR_DOWN_FORMED",eventData,true);
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
     eventData.lparam = long(extrLow.time);
     event.Generate("EXTR_DOWN",eventData,true);               
     if (jumper == 1)
     {             
      bufferFormedExtrHigh[indexPrevUp] = lastExtrUpValue;        // ���������� �������������� ���������
      bufferTimeExtrHigh[indexPrevUp] = long(lastExtrUpTime);     // ��������� ����� ��������������� ����������
      // ������ ���������� �� ����������
      eventData.dparam = lastExtrUpValue;  
      eventData.lparam = long(lastExtrUpTime);      
      prevJumper = jumper;          
      event.Generate("EXTR_UP_FORMED",eventData,true);         
     }
     jumper = -1;
     indexPrevDown = rates_total-1;
    }      
   }
   return(rates_total);
  } 
   
//+------------------------------------------------------------------+
//|       �������������� ������� ����������                          |
//+------------------------------------------------------------------+
 
// ����� ������ ATR ��� �������������
// �������� ���������� � ����������� �� �� 
void GetATRCoefficient(ENUM_TIMEFRAMES period)
{
 switch(period)
 {
  case(PERIOD_M1):
    percentage_ATR = 3.0;
    break;
  case(PERIOD_M5):
    percentage_ATR = 3.0;
    break;
  case(PERIOD_M15):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_H1):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_H4):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_D1):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_W1):
    percentage_ATR = 2.2;
    break;
  case(PERIOD_MN1):
    percentage_ATR = 2.2;
    break;
  default:
    percentage_ATR = DEFAULT_PERCENTAGE_ATR;
    break;
 }  
} 

// ����� ���������� ���������� �� ������� ����
ENUM_CAME_EXTR isExtremum(datetime start_pos_time=__DATETIME__,bool now=true)
{
 double high = 0, low = 0;                     // ��������� ���������� � ������� ����� �������� ���� ��� ������� max � min ��������������
 double averageBarNow;                         // ��� �������� �������� ������� ����
 double difToNewExtremum;                      // ��� �������� ������������ ���������� ����� ������������
 datetime extrHighTime = 0;                    // ����� ������� �������� ���������� 
 datetime extrLowTime = 0;                     // ����� ������� ������� ����������
 MqlRates bufferRates[2];                      // ���������
 came_extr = CAME_NOTHING;      // ��� ���������� ���������� (������������ ��������)
 // �������� ����������� ��� ���� 
 if(CopyRates(_Symbol, _Period, start_pos_time, 2, bufferRates) < 2)
  {
   log_file.Write(LOG_CRITICAL, StringFormat("%s �� ������� ����������� ���������. symbol = %s, Period = %s, time = %s"
                                            ,MakeFunctionPrefix(__FUNCTION__), _Symbol, PeriodToString(_Period), TimeToString(start_pos_time)));
   return(came_extr); 
  }
 // ��������� ������� ������ ����
 averageBarNow = AverageBar(start_pos_time);
 // ���� ������� ��������� ������� �������� �
 if (averageBarNow > 0) averageATR = averageBarNow; 
 // ��������� ����������� ���������� ����� ������������
 difToNewExtremum = averageATR * percentage_ATR;  
 
 if (extrHigh.time > extrLow.time && bufferRates[1].time < extrHigh.time && !now) return (came_extr); 
 if (extrHigh.time < extrLow.time && bufferRates[1].time < extrLow.time && !now) return (came_extr); 
 
 if (now) // �� ����� ����� ���� ���� close �������� ��� ��� �������� �� low �� high
 {        // ������������ ���� �� ������ ���� ���� ������� ��������� �� �� ����� ��������� ����� close ����� max  � �������� � low
  high = bufferRates[1].close;
  low = bufferRates[1].close;
 }
 else    // �� ����� ������ �� ������� �� ������� �� ��� ���� ��� ������������� ��� ����� ����� ������ ��� �������� � �������
 {
  high = bufferRates[1].high;
  low = bufferRates[1].low;
 }
 
 if ( (extrHigh.direction == 0  && extrLow.direction == 0)                         // ���� ����������� ��� ��� �� ������� ��� ������ ���������
   || ((extrHigh.time > extrLow.time) && (GreatDoubles(high, extrHigh.price) ))    // ���� ��������� ��������� - High, � ���� ������� ��������� � �� �� ������� 
   || ((extrHigh.time < extrLow.time) && (GreatDoubles(high,extrLow.price + difToNewExtremum) && GreatDoubles(high,bufferRates[0].high) )  )  ) // ���� ��������� ��������� - Low, � ���� ������ �� ���������� �� ���. ���������� � �������� �������  
 {
  // ��������� ����� ������� �������� ����������
  if (now) // ���� ���������� ����������� � �������� �������
   extrHighTime = TimeCurrent();
  else  // ���� ���������� ����������� �� �������
   extrHighTime = bufferRates[1].time;
  came_extr = CAME_HIGH;  // ���� ������ ������� ���������   
 }
 
 if ( ( extrLow.direction == 0 && extrHigh.direction == 0)                      // ���� ����������� ��� ��� �� ������� ��� ������ ���������
   || ((extrLow.time > extrHigh.time) && (LessDoubles(low,extrLow.price)))    // ���� ��������� ��������� - Low, � ���� ������� ��������� � �� �� �������
   || ((extrLow.time < extrHigh.time) && (LessDoubles(low,extrHigh.price - difToNewExtremum) && LessDoubles(low,bufferRates[0].low) ) ) )  // ���� ��������� ��������� - High, � ���� ������ �� ���������� �� ���. ���������� � �������� �������
 {
  // ���� �� ���� ���� ������ ������� ���������
  if (extrHighTime > 0)
  {
   // ���� close ���� open, �� �������, ��� ������� ��������� ������ ������ �������
   if(bufferRates[1].close <= bufferRates[1].open) 
   {
    extrLowTime = bufferRates[1].time + datetime(100);
   }
   else // ����� ��������, ��� ������ ������ ������ ��������
   {
    extrHighTime = bufferRates[1].time + datetime(100);
    extrLowTime  = bufferRates[1].time;
   }
   came_extr = CAME_BOTH;   // ���� ������ ��� ����������     
  }
  else // ����� ������ ��������� ����� ������� ������� ����������
  {
   if (now) // ���� ���������� ����������� � �������� �������
    extrLowTime = TimeCurrent();
   else // ���� ���������� ����������� �� �������
    extrLowTime = bufferRates[1].time;
   came_extr = CAME_LOW; // ���� ������ ������ ���������     
  }
 }

 // ��������� ���� �������� �����������
 
 // ���� ������ ����� ������� ���������
 if (extrHighTime > 0)
 {
  // ��������� ���� ����������
  extrHigh.direction = 1;
  extrHigh.price = high;
  extrHigh.time = extrHighTime;
 }
 // ���� ������ ����� ������ ���������
 if (extrLowTime > 0)
 {
  // ��������� ���� ����������
  extrLow.direction = -1;
  extrLow.price = low;
  extrLow.time = extrLowTime;
 }  
 return (came_extr);
}

// ����� ���������� �������� ������� ����
double AverageBar(datetime start_pos)
{
 int copied = 0;
 double buffer_atr[1];
 if (handleForAverBar == INVALID_HANDLE)
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ERROR %d. INVALID HANDLE ATR %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), EnumToString((ENUM_TIMEFRAMES)_Period)));
  return (-1);
 }
 copied = CopyBuffer(handleForAverBar, 0, start_pos, 1, buffer_atr);
 if (copied < 1) 
 {
  log_file.Write(LOG_CRITICAL, StringFormat("%s ERROR %d. Period = %s. copied = %d, calculated = %d, start time = %s"
                                           , MakeFunctionPrefix(__FUNCTION__)
                                           , GetLastError()
                                           , EnumToString((ENUM_TIMEFRAMES)_Period), copied
                                           , BarsCalculated(handleForAverBar), TimeToString(start_pos)));
  return(-1);
 }
 return (buffer_atr[0]);
}
