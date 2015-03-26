//+------------------------------------------------------------------+
//|                                                     Blau_Mtm.mq5 |
//|                        Copyright 2011, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011, MetaQuotes Software Corp." // �������� ��������-�������������
#property link      "http://www.mql5.com"                       // ������ �� ���� ��������-�������������
#property description "q-period Momentum (William Blau)"        // ������� �������� mql5-���������
#include <WilliamBlau.mqh>              // ���������� ���� (����� � ����������� ��������)
//--- ��������� ����������
#property indicator_separate_window     // �������� ��������� � ��������� ����
#property indicator_buffers 5           // ���������� ������� ��� ������� ����������
#property indicator_plots   1           // ���������� ����������� ���������� � ����������
//--- ����������� ���������� #0 (Main)
#property indicator_label1  "Mtm"       // ����� ��� ������������ ���������� #0
#property indicator_type1   DRAW_LINE   // ������ �����������: DRAW_LINE - �����
#property indicator_color1  Blue        // ���� ��� ������ �����: Blue - �����
#property indicator_style1  STYLE_SOLID // ����� �����: STYLE_SOLID - �������� �����
#property indicator_width1  1           // ������� �����
//--- ������� ���������
input int    q=2;  // q - ������, �� �������� ����������� ��������
input int    r=20; // r - ������ 1-� EMA, ������������� � ���������
input int    s=5;  // s - ������ 2-� EMA, ������������� � ���������� ������� �����������
input int    u=3;  // u - ������ 3-� EMA, ������������� � ���������� ������� �����������
input ENUM_APPLIED_PRICE AppliedPrice=PRICE_CLOSE; // AppliedPrice - ��� ����
//--- ������������ ������� ��� ������� ����������
double MainBuffer[];     // u-��������� 3-� EMA (��� ������������ ���������� #0)
double PriceBuffer[];    // ������ ���
double MtmBuffer[];      // q-��������� ��������
double EMA_MtmBuffer[];  // r-��������� 1-� EMA
double DEMA_MtmBuffer[]; // s-��������� 2-� EMA
//--- ���������� ����������
int    begin1, begin2, begin3, begin4; // ������ ���������, � ������� ���������� �������� ������
int    rates_total_min; // ����������� ������ ������� ��������� ����������
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- ����� ������������ ������� � ���������������� ������������� ��������� 
   // �������� ������������� ����������; ������������� ��� ��������� ����������� ����������
   // ����������� ���������� #0
   SetIndexBuffer(0,MainBuffer,INDICATOR_DATA);             // u-��������� 3-� EMA
   // ������ ��� ������������� �������� ����������; �� ������������� ��� ���������
   SetIndexBuffer(1,PriceBuffer,INDICATOR_CALCULATIONS);    // ������ ���
   SetIndexBuffer(2,MtmBuffer,INDICATOR_CALCULATIONS);      // q-��������� ��������
   SetIndexBuffer(3,EMA_MtmBuffer,INDICATOR_CALCULATIONS);  // r-��������� 1-� EMA
   SetIndexBuffer(4,DEMA_MtmBuffer,INDICATOR_CALCULATIONS); // s-��������� 2-� EMA
/*
//--- ����������� ���������� #0 (Main)
   PlotIndexSetString(0,PLOT_LABEL,"Mtm");             // ����� ��� ������������ ���������� #0
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);    // ������ �����������: DRAW_LINE - �����
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,Blue);        // ���� ��� ������ �����: Blue - �����
   PlotIndexSetInteger(0,PLOT_LINE_STYLE,STYLE_SOLID); // ����� �����: STYLE_SOLID - �������� �����
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,1);           // ������� �����
*/
//--- �������� ����������� �������� ����������
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---
   begin1=q-1;        //                             - �������� ������: MtmBuffer[]
   begin2=begin1+r-1; // or =(q-1)+(r-1)             - �������� ������: EMA_MtmBuffer[]
   begin3=begin2+s-1; // or =(q-1)+(r-1)+(s-1)       - �������� ������: DEMA_MtmBuffer[]
   begin4=begin3+u-1; // or =(q-1)+(r-1)+(s-1)+(u-1) - �������� ������: MainBuffer[]
   //
   rates_total_min=begin4+1; // ����������� ������ ������� ��������� ����������
//--- ���������� ��������� ����� ��� ��������� ������������ ���������� #0
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,begin4);
//--- ������� ��� ����������
   string shortname=PriceName(AppliedPrice)+","+string(q)+","+string(r)+","+string(s)+","+string(u);
   IndicatorSetString(INDICATOR_SHORTNAME,"Blau_Mtm("+shortname+")");
//--- OnInit done
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
                const int rates_total,     // ������ ������� ���������
                const int prev_calculated, // ���������� ����� �� ���������� ������
                const datetime &Time[],    // Time
                const double &Open[],      // Open
                const double &High[],      // High
                const double &Low[],       // Low
                const double &Close[],     // Close
                const long &TickVolume[],  // Tick Volume
                const long &Volume[],      // Real Volume
                const int &Spread[]        // Spread
               )
  {
   int i,pos;
//--- ���������� �� ������ ��� ������� ����������
   if(rates_total<rates_total_min) return(0);
//--- ������ ������� ��� PriceBuffer[]
   CalculatePriceBuffer(
                        AppliedPrice,        // ��� ����
                        rates_total,         // ������ ������� ���������
                        prev_calculated,     // ���������� ����� �� ���������� ������
                        Open,High,Low,Close, // ������� Open[], High[], Low[], Close[]
                        PriceBuffer          // �������������� ������ ���
                       );
//--- ������ q-���������� ���������
   // ����������� ������� (pos), � �������� ������/���������� ������ q-���������� ���������
   // ��������� ���������� ��������� ������� MtmBuffer[]
   if(prev_calculated==0)      // ���� ������ �����
     {
      pos=begin1;              // �� ���c�������� ��� ��������, ������� �� ��������� �������
      for(i=0;i<pos;i++)       // �� ��������� �������
         MtmBuffer[i]=0.0;     // �������� ��������
     }
   else pos=prev_calculated-1; // ����� ������������ ������ ��������� ��������
   // ������ �������� ��������� ������� MtmBuffer[]
   for(i=pos;i<rates_total;i++)
      MtmBuffer[i]=PriceBuffer[i]-PriceBuffer[i-(q-1)];
//--- ����������� ������� EMA
   // r-��������� 1-� EMA
   ExponentialMAOnBufferWB(
                           rates_total,     // ������ ������� ���������
                           prev_calculated, // ���������� ����� �� ���������� ������
                           begin1,          // � ������ ������� ���������� �������� ������ �� ������� �������
                           r,               // ������ �����������
                           MtmBuffer,       // ������� ������
                           EMA_MtmBuffer    // �������� ������
                          );
   // s-��������� 2-� EMA
   ExponentialMAOnBufferWB(rates_total,prev_calculated,begin2,s,EMA_MtmBuffer,DEMA_MtmBuffer);
   // u-��������� 3-� EMA (��� ������������ ���������� #0)
   ExponentialMAOnBufferWB(rates_total,prev_calculated,begin3,u,DEMA_MtmBuffer,MainBuffer);
//--- OnCalculate done. Return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+