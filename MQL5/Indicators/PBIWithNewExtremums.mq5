//+------------------------------------------------------------------+
//|                                                    PBI_SHARP.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.01"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   1
#property indicator_label1  "ColoredTrend"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrNONE,clrBlue,clrPurple,clrRed,clrSaddleBrown,clrSalmon,clrMediumSlateBlue,clrYellow
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
#property indicator_type4   DRAW_ARROW
#property indicator_type5   DRAW_ARROW

// ���������� ����������� ����������
#include <CompareDoubles.mqh>                             // ��� ��������� ������������ �����
#include <Lib CisNewBarDD.mqh>                            // ��� ��������� ������ ����
#include <ColoredTrend/ColoredTrendWithNewExtremums.mqh>  // ����� CColoredTrend
#include <ColoredTrend/ColoredTrendUtilities.mqh>         // ��������� � ������������ CColoredTrend
#include <DrawExtremums/CExtrContainer.mqh>               // ��������� �����������
#include <SystemLib/IndicatorManager.mqh>                 // ���������� �� ������ � ������������
#include <CEventBase.mqh>                                 // ��� ��������� �������   
#include <CLog.mqh>                                       // ��� ����

// ������� ���������
input int  depth_history = 100;                           // ������� �������      
input bool show_top  = false;                             // ���������� ������� ��������� ��� �������
input bool is_it_top = false;                             // ���� true ����������� ������ ������� ���������; false ����������� �������������� ��������� ��� �������� ����������

// ������������ ������
double ColorCandlesBuffer1[];
double ColorCandlesBuffer2[];
double ColorCandlesBuffer3[];
double ColorCandlesBuffer4[];
double ColorCandlesColors[];
double ColorCandlesColorsTop[];

int i,count;
string str="";
SExtremum extr;

// ��������� ���������� ����������               
int  depth = depth_history;           // ���������� ��� �������� ������� �������
int  extrCount;                       // ���������� ����������� �� �������
bool uploadedSuc=false;               // ���� �������� �������� �����������
bool trendCalculated=false;           // ���� ����������� ������
// ������ �����������
int handleDE;                         // ����� DrawExtremums
int handle_top_trend;                 // ����� �������� ����������
int handle_atr;                       // ����� ATR
// �������������� ����������
double last_move;                     // ��������� ��������
// ������� �������
CExtrContainer *container;            // ��������� �����������
CisNewBar NewBarCurrent;              // ��� ������������ ������ ����
CColoredTrend *trend;                 // ��� �������� ��������
CEventBase *event;                    // ��� ��������� ������� 
SEventData eventData;                 // ��������� ����� �������

int OnInit()
  {      
   // �������� ���������� DrawExtremums 
   handleDE = DoesIndicatorExist(_Symbol,_Period,"DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     handleDE = iCustom(_Symbol,_Period,"DrawExtremums");
     if (handleDE == INVALID_HANDLE)
      {
       Print("�� ������� ������� ����� ���������� DrawExtremums");
       return (INIT_FAILED);
      }
     SetIndicatorByHandle(_Symbol,_Period,handleDE);
    }   
   // �������� ������ ��� ������ ������ ��� �������     
   container = new CExtrContainer(_Symbol,_Period,handleDE);
   if ( container == NULL )
    {
     Print("������ ��� ������������� ���������� PriceBasedIndicator. �� ������� ������� ������ ������ CExtrContainer");
     return (INIT_FAILED);
    }

   // ������� ������ ��������� ������� 
   event = new CEventBase(300);
   if (event == NULL)
    {
     Print("������ ��� ������������� ���������� PriceBasedIndicator. �� ������� ������� ������ ������ CEventBase");
     return (INIT_FAILED);
    }
   // ������� �������
   event.AddNewEvent(_Symbol,_Period,"����� ��������"); 
  
   if(Bars(_Symbol,_Period) < depth) depth = Bars(_Symbol,_Period)-1;
   PrintFormat("������� ������ �����: %d", depth);
   
   NewBarCurrent.SetPeriod(_Period);
   handle_atr = iMA(_Symbol,_Period, 100, 0, MODE_EMA, iATR(_Symbol,_Period, 30));
   trend = new CColoredTrend(_Symbol,_Period, handle_atr, depth,container);
   if(!is_it_top) handle_top_trend = iCustom(_Symbol, GetTopTimeframe(_Period), "PBIWithNewExtremums", depth, false, true);

   SetIndexBuffer(0, ColorCandlesBuffer1, INDICATOR_DATA);
   SetIndexBuffer(1, ColorCandlesBuffer2, INDICATOR_DATA);
   SetIndexBuffer(2, ColorCandlesBuffer3, INDICATOR_DATA);
   SetIndexBuffer(3, ColorCandlesBuffer4, INDICATOR_DATA);
   
   if(show_top)    //����� ��������� � ������ ���������� �� ����������: current ��� top
   {
    SetIndexBuffer(4, ColorCandlesColorsTop, INDICATOR_DATA);
    SetIndexBuffer(5, ColorCandlesColors,    INDICATOR_CALCULATIONS);
   }
   else
   {
    SetIndexBuffer(4, ColorCandlesColors,    INDICATOR_DATA);
    SetIndexBuffer(5, ColorCandlesColorsTop, INDICATOR_CALCULATIONS);
   }

   InitializeIndicatorBuffers();
   
   PlotIndexSetInteger(1, PLOT_ARROW, 218);
   PlotIndexSetInteger(2, PLOT_ARROW, 217);
   PlotIndexSetInteger(3, PLOT_ARROW, 234);
   PlotIndexSetInteger(4, PLOT_ARROW, 233);
   
   ArraySetAsSeries(ColorCandlesBuffer1,   true);
   ArraySetAsSeries(ColorCandlesBuffer2,   true);
   ArraySetAsSeries(ColorCandlesBuffer3,   true);
   ArraySetAsSeries(ColorCandlesBuffer4,   true);
   ArraySetAsSeries(ColorCandlesColors,    true);
   ArraySetAsSeries(ColorCandlesColorsTop, true);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
{
   Print(__FUNCTION__,"_��� ������� ��������������� = ",reason," ������ =  ",PeriodToString(_Period));
   ArrayFree(ColorCandlesBuffer1);
   ArrayFree(ColorCandlesBuffer2);
   ArrayFree(ColorCandlesBuffer3);
   ArrayFree(ColorCandlesBuffer4);
   ArrayFree(ColorCandlesColors);
   ArrayFree(ColorCandlesColorsTop);
   if(!is_it_top) IndicatorRelease(handle_top_trend);
   IndicatorRelease(handleDE);
   IndicatorRelease(handle_atr);
   delete trend;
   delete container;
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
   static int buffer_index = 0;
   double buffer_top_trend[1] = {MOVE_TYPE_UNKNOWN};  // ������� ��� �������� ���� �������� �� ������� ���������
   int countMoveTypeEvent;
   
   // �������������� ���������� �������� ��� � ���������
   ArraySetAsSeries(open , true);
   ArraySetAsSeries(high , true);
   ArraySetAsSeries(low  , true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(time , true);
   
   if(prev_calculated == 0) // ������ ��������� �� �������
   {
    PrintFormat("%s ������ ������ ����������", MakeFunctionPrefix(__FUNCTION__));
    buffer_index = 0;
    trend.Zeros();
    InitializeIndicatorBuffers();
    //depth = rates_total;
    NewBarCurrent.isNewBar(time[depth]);
      
    for(int i = depth-1; i >= 0;  i--)    
    {
     if(!is_it_top) 
      if(CopyBuffer(handle_top_trend, 4, time[i], 1, buffer_top_trend) < 1)
      {
       PrintFormat("%s �� ������� ���������� �������� TOP TREND. %d", EnumToString((ENUM_TIMEFRAMES)_Period), GetLastError());
       return(0);
      }       
       
       // �������� �������� ���������� ���� ��� ��������
       container.AddNewExtr(time[i]);    
       // �������� ������� �� ������ ���������� ��������
       trend.CountMoveType(buffer_index, time[i], (ENUM_MOVE_TYPE)buffer_top_trend[0]);
       
       ColorCandlesBuffer1[i]   = open[i];
       ColorCandlesBuffer2[i]   = high[i];
       ColorCandlesBuffer3[i]   = low[i];
       ColorCandlesBuffer4[i]   = close[i];       
       ColorCandlesColors[i]    = trend.GetMoveType(buffer_index); 
       ColorCandlesColorsTop[i] = buffer_top_trend[0];   
                                                                                                
     if(NewBarCurrent.isNewBar(time[i])) 
     {
      buffer_index++;     //��� ���� ��� �� ������� �� �������
     }     
    }
    // ��������� ��������� ��������
    last_move = ColorCandlesColors[0]; 
    PrintFormat("%s ������ ������ ���������� �������", MakeFunctionPrefix(__FUNCTION__));
   }  
   // ������� ���������� � �������� �������
          
      // ���������� ���� �������� � ������� ������
      if(!is_it_top && CopyBuffer(handle_top_trend, 4, time[0], 1, buffer_top_trend) < 1)
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s/%s �� ������� ���������� �������� TOP TREND. %d", EnumToString((ENUM_TIMEFRAMES)_Period), EnumToString((ENUM_TIMEFRAMES)GetTopTimeframe(_Period)), GetLastError()));
      } 
      
      // ���� ����� �� ��� ��������
      if (!trendCalculated)
          trend.ZeroTrend();  // �� �������� �����
        
     /* if (container.AddNewExtr(TimeCurrent()))   
        {         
         // ��������� ����������         
         if (trend.UpdateExtremums()==1)
          {
           trend.CountTrend();   
          }
        } 
     */  
           
      // ��������� ������� �������� � �������� ������� 
      trend.CountMoveTypeA(buffer_index, time[0], (ENUM_MOVE_TYPE)buffer_top_trend[0]);
      // ���������� ���� ����, ��� ����� ����������
      trendCalculated = false;
      // ��������� ������
      ColorCandlesBuffer1[0]   = open[0];
      ColorCandlesBuffer2[0]   = high[0];
      ColorCandlesBuffer3[0]   = low [0];
      ColorCandlesBuffer4[0]   = close[0]; 
      ColorCandlesColors[0]    = trend.GetMoveType(buffer_index);
      ColorCandlesColorsTop[0] = buffer_top_trend[0];
      
      // ���� �������� ����������, ������� ��������������� �������
      if (ColorCandlesColors[0] != last_move)
       {
        // �� ��������� ��������� ��������
        last_move = ColorCandlesColors[0];
        eventData.dparam = last_move;
        Generate("����� ��������",eventData,true);
       }
       
      if(NewBarCurrent.isNewBar() && prev_calculated != 0)
      {
       buffer_index++; 
      }
       
   return (rates_total);
  }

void InitializeIndicatorBuffers()
{
 Print("�������� ������");
 ArrayInitialize(ColorCandlesBuffer1, 0);
 ArrayInitialize(ColorCandlesBuffer2, 0);
 ArrayInitialize(ColorCandlesBuffer3, 0);
 ArrayInitialize(ColorCandlesBuffer4, 0);
 ArrayInitialize(ColorCandlesColors , 0);
 ArrayInitialize(ColorCandlesColorsTop, 0);
}

// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
  {
   // ������ ������� "������ ����� ���������"
   if (sparam == "���������")
    {
     // ��������� ��������� ������ ������������. � ���� ������� ��������� ����������
     container.AddExtrToContainer(lparam,dparam,TimeCurrent());
     //if (container.AddNewExtr(TimeCurrent() ))
      //{
       // ���� ������� �������� ����������
       if (trend.UpdateExtremums()==1)
        {
         // ������������ �����
         trend.CountTrend();
         // ���������� ���� ����, ��� ����� ��� ����������
         trendCalculated = true;
        }
      ///}
    }
   
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
  