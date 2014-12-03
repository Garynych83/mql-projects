//+------------------------------------------------------------------+
//|                                                      Volumes.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2009, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//---- indicator settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  Green,Red
#property indicator_style1  0
#property indicator_width1  1
#property indicator_minimum 0.0

//---- indicator buffers
double                    ExtVolumesBuffer[];
double                    ExtColorsBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {   
   SetIndexBuffer(0,ExtVolumesBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtColorsBuffer,INDICATOR_COLOR_INDEX);

   IndicatorSetString(INDICATOR_SHORTNAME,"Volumes");

   IndicatorSetInteger(INDICATOR_DIGITS,0);
   
   //������� ���� � �������� � �������� ������ ���� ��� ���
   bool chart = true;
   long z = ChartFirst();
   while (chart && z>=0)
   {
   if (ChartSymbol(z)== _Symbol && ChartPeriod(z)==_Period)  // ���� ������ ������ � ������� �������� � �������� 
      {
       // ���� �� ���� ������� ����� ��������� IsNewBar
       if (ChartIndicatorGet(z,0,"IsNewBar") != INVALID_HANDLE)
        {
         chart=false;
         break;
        }
      }
   z = ChartNext(z);
   }
   // ���� �� �� ����� ������� ������� ������� � �� �� ������ IsNewBar, �� ������� ��� �� ����� �������
   if (chart) 
    {
     z = ChartOpen(_Symbol, _Period);
     if (z>0)
      {
       int handleIsNewBar = iCustom(_Symbol,_Period,"IsNewBar");
       // ���� ������� ������� �����
       if (handleIsNewBar != INVALID_HANDLE)         
        ChartIndicatorAdd(z,0,handleIsNewBar);
      }
    }
   
  }
//+------------------------------------------------------------------+
//|  Volumes                                                         |
//+------------------------------------------------------------------+
bool couldCalc = true; // ���� ���������� ��������� ����������
int count=0;
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
  // ���� ��������� ������ �������� ����������
  if (couldCalc)
   {
    //---check for rates total
    if(rates_total<3)
     return(0);
    
    //--- starting work
    int start=prev_calculated-1;
    //--- correct position
    if(start<2) start = 2;
     CalculateVolume(start,rates_total,tick_volume);
   }
  couldCalc = false;
  return(rates_total);
 }
 
 int countEvent = 0;
  
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string
  )
   {
    
    // ���� �������� ������� � ���, ��� ������ ����� ��� �� �������� ����������
    if (id==CHARTEVENT_CUSTOM+1)
     {
     Comment("���������� ������� = ",countEvent++);
      couldCalc = true; // �������� ���� ����������� ��������� ����������
     }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateVolume(const int nPosition,
                     const int nRatesCount,
                     const long &SrcBuffer[])
  {
   ExtVolumesBuffer[0]=(double)SrcBuffer[0];
   ExtColorsBuffer[0]=0.0;
   
   for(int i=nPosition;i<nRatesCount && !IsStopped();i++)
     {
      double dCurrVolume=(double)SrcBuffer[i];
      double dPrevVolume=(double)SrcBuffer[i-1];
      double dPrePreVolume=(double)SrcBuffer[i-2];
      ExtVolumesBuffer[i-1]=dPrevVolume;
      if(dPrevVolume>dPrePreVolume)
         ExtColorsBuffer[i-1]=0.0;
      else
         ExtColorsBuffer[i-1]=1.0;
     }
  }