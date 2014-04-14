//+------------------------------------------------------------------+
//|                                                      DisMACD.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#include <Lib CisNewBar.mqh>                  // ��� �������� ������������ ������ ����
#include <Divergence/divergenceStochastic.mqh>           // ���������� ���������� ��� ������ ��������� � ����������� ����������
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ���������\�����������
#include <CompareDoubles.mqh>                 // ��� �������� �����������  ���

 // ��������� ����������
 
//---- ����� ������������� 3 ������
#property indicator_buffers 2
//---- ������������ 2 ����������� ����������
#property indicator_plots   2

//---- � �������� ���������� �������  ������������ �����
#property indicator_type1 DRAW_LINE
//---- ���� ����������
#property indicator_color1  clrWhite
//---- ������� ����� ����������
#property indicator_width1  1
//---- ����� �����
#property indicator_style1 STYLE_SOLID
//---- ����������� ����� ����� ����������
#property indicator_label1  "StochasticTopLevel"

//---- � �������� ���������� �������  ������������ �����
#property indicator_type2 DRAW_LINE
//---- ���� ����������
#property indicator_color2  clrRed
//---- ������� ����� ����������
#property indicator_width2  1
//---- ����� �����
#property indicator_style2  STYLE_DASHDOT
//---- ����������� ����� ����� ����������
#property indicator_label2  "StochasticBottomLevel"

 // ������������ ������ �������� ����� �������
 enum BARS_MODE
 {
  ALL_HISTORY=0, // ��� �������
  INPUT_BARS     // �������� ���������� ����� ������������
 };
 // ������ ������ ����� �����
 color lineColors[5]=
  {
   clrRed,
   clrBlue,
   clrYellow,
   clrGreen,
   clrGray
  };
//+------------------------------------------------------------------+
//| �������� ��������� ����������                                    |
//+------------------------------------------------------------------+
input BARS_MODE           bars_mode=ALL_HISTORY;        // ����� �������� �������
input short               bars=20000;                   // ��������� ���������� ����� ������� (K-������)
input ENUM_MA_METHOD      ma_method=MODE_SMA;           // ��� �����������
input ENUM_STO_PRICE      price_field=STO_LOWHIGH;      // ������ ������� ����������           
input int                 top_level=80;                 // ������� ������� 
input int                 bottom_level=20;              // ������ ������� 
input int                 depth=3;                     // ������� ���������� ������������
input string              file_url="STAT_STOC.txt";     // url ����� ����� ���������� 
input double              averPotLossDiv = 0.00175;  // ������� ������������� ������ �����������
input double              averPotLossConv = 0.00163; // ������� ������������� ������ ���������


//+------------------------------------------------------------------+
//| ���������� ����������                                            |
//+------------------------------------------------------------------+

bool               first_calculate;        // ���� ������� ������ OnCalculate
int                handleStoc;             // ����� ����������
int                lastBarIndex;           // ������ ���������� ����   
long               countTrend;             // ������� ����� �����

PointDivSTOC       divergencePoints;       // ��������� � ����������� ����������
CChartObjectTrend  trendLine;              // ������ ������ ��������� �����
CisNewBar          isNewBar;               // ��� �������� ������������ ������ ����

double             bufferStoc[];           // ����� ���������� 1
double             bufferStoc2[];          // ����� ���������� 2


int countConvPos = 0;                      // ���������� ������������� �������� ���������
int countConvNeg = 0;                      // ���������� ���������� �������� ���������
int countDivPos  = 0;                      // ���������� ������������� �������� �����������
int countDivNeg  = 0;                      // ���������� ���������� �������� ����������� 

double averConvPos = 0;      // ������� ���������� ���������
double averConvNeg = 0;      // ������� �� ���������� ���������
double averDivPos  = 0;      // ������� ���������� �����������
double averDivNeg  = 0;      // ������� �� ���������� �����������
double averPos     = 0;      // ������� ���������� ������
double averNeg     = 0;      // ������� �� ���������� ������   

double averLoseDivAtWin  = 0;  // ������� ������������� �������� ��� ��������� �����������  
double averLoseConvAtWin = 0;  // ������� ������������� �������� ��� ���������� ���������
 
// ��������� ���������� ��� �������� ��������� ��������� � ����������
 double localMax;
 double localMin;

// ���������� ����������� � ������� �������� �������������� ������
 int countDivAAA  = 0;
// ���������� ��������� � ������� �������� �������������� ������
 int countConvAAA = 0;

// ������� � ����� �� ������� ���������� ���������\�����������

int count;

// ����� ����� ���������� ��������� \ ����������� 
 int file_handle;   

//+------------------------------------------------------------------+
//| ������� ������� ����������                                       |
//+------------------------------------------------------------------+

int OnInit()
  {
   // ������� ���� ���������� 
   file_handle = FileOpen(file_url, FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
   if (file_handle == INVALID_HANDLE) //�� ������� ������� ����
    {
     Alert("������ �������� �����");
     return (INIT_FAILED);
    }  
   // ������� ��� ����������� �������     
   ObjectsDeleteAll(0,0,OBJ_TREND);
   ObjectsDeleteAll(0,1,OBJ_TREND);   
   // ��������� ��������� � �������
   SetIndexBuffer(0,bufferStoc,INDICATOR_DATA);
   SetIndexBuffer(1,bufferStoc2,INDICATOR_DATA);   

    
   // ������������� ����������  ����������
   first_calculate = true;
   countTrend = 1;
   // ��������� ����� ���������� ����������
   handleStoc = iStochastic(_Symbol,_Period,5,3,3,ma_method,price_field);
   return(INIT_SUCCEEDED);
  }

void OnDeinit ()
  {

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
    int retCode;  // ��������� ���������� ��������� � �����������
    // ���� ��� ������ ������ ������ ��������� ����������
    if (first_calculate)
     {
      if (bars_mode == ALL_HISTORY)
       {
        lastBarIndex = rates_total - 101;
       }
      else
       {
       if (bars < 100)
        {
         lastBarIndex = 1;
        }
       else if (bars > rates_total)
        {
         lastBarIndex = rates_total-101;
        }
       else
        {
         lastBarIndex = bars-101;
        }
       }
       // �������� ������ ����������
       if ( CopyBuffer(handleStoc,0,0,bars,bufferStoc) < 0 ||
            CopyBuffer(handleStoc,1,0,bars,bufferStoc2) < 0 )
           {
             // ���� �� ������� ��������� ������ ����������
             return (0);
           }    
       for (;lastBarIndex > 0; lastBarIndex--)
        {
          // ��������� ������� �� ������ �� ������� �����������\��������� 
          retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,divergencePoints,lastBarIndex);
          // ���� �� ������� ��������� �����
          if (retCode == -2)
           return (0);
          // ���� ���������\����������� ����������
          if (retCode)
           {                                     
            //������� ����� ���������\�����������                    
            trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2);                        
            //������� ����� ���������\����������� �� ����������
            trendLine.Create(0,"StocLine_"+countTrend,1,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);            
            //����������� ���������� ����� �����
            countTrend++;
            
            localMax = high[rates_total-1-lastBarIndex];
            localMin = low[rates_total-1-lastBarIndex];
            for (count=1;count<=depth;count++)
             {
              if (GreatDoubles(high[rates_total-1-lastBarIndex+count],localMax) )
               localMax = high[rates_total-1-lastBarIndex+count];
              if (LessDoubles (low[rates_total-1-lastBarIndex+count],localMin) )
               localMin = low[rates_total-1-lastBarIndex+count];
             } 
              
            if (retCode == 1)
             {

               FileWriteString(file_handle,"\n "+TimeToString(time[rates_total-2-lastBarIndex])+" (�����������): " );   
               FileWriteString(file_handle,"\n�������: "+DoubleToString(close[rates_total-2-lastBarIndex]-localMin)+" ������: "+DoubleToString(localMax - close[rates_total-2-lastBarIndex])+"\n");    
               if ( LessDoubles ( (localMax - close[rates_total-2-lastBarIndex]), (close[rates_total-2-lastBarIndex] - localMin) ) )
                 {
               
                   averDivPos  = averDivPos + close[rates_total-2-lastBarIndex] - localMin;
                   averPos     = averPos + close[rates_total-2-lastBarIndex] - localMin; 
                   averLoseDivAtWin = averLoseDivAtWin + localMax - close[rates_total-2-lastBarIndex];
                   countDivPos ++; // ����������� ������� ������������� ���������
                   if (LessOrEqualDoubles(localMax - close[rates_total-2-lastBarIndex],averPotLossDiv) )
                    {
                     countDivAAA ++;   // ����������� ���������� ����� �����������
                    }                   
                 }
               else
                 {
                   averDivNeg  = averDivNeg + close[rates_total-2-lastBarIndex] - localMax;  
                   averNeg     = averNeg + close[rates_total-2-lastBarIndex] - localMax; 
                   countDivNeg ++; // ����� ����������� ������� ������������� ���������
                 }
             }
            if (retCode == -1)
             {
               FileWriteString(file_handle,"\n "+TimeToString(time[rates_total-2-lastBarIndex])+" (���������): " );   
               FileWriteString(file_handle,"\n�������: "+DoubleToString(localMax - close[rates_total-2-lastBarIndex])+" ������: "+DoubleToString(close[rates_total-2-lastBarIndex]-localMin)+"\n");                
               if (GreatDoubles ( (localMax - close[rates_total-2-lastBarIndex]), (close[rates_total-2-lastBarIndex] - localMin) ) )
                 {
                  averConvPos = averConvPos + localMax - close[rates_total-2-lastBarIndex];
                  averPos     = averPos + localMax - close[rates_total-2-lastBarIndex];  
                  averLoseConvAtWin = averLoseConvAtWin + close[rates_total-2-lastBarIndex]-localMin;
                  countConvPos ++; // ����������� ������� ������������� �����������
                   if (LessOrEqualDoubles(close[rates_total-2-lastBarIndex]-localMin,averPotLossConv) )
                   {
                    countConvAAA ++;   // ����������� ���������� ����� �����������
                   }                  
                 }
               else
                 {
                  averConvNeg = averConvNeg + localMin - close[rates_total-2-lastBarIndex];  
                  averNeg     = averNeg + localMin - close[rates_total-2-lastBarIndex];
                  countConvNeg ++; // ����� ����������� ������� ������������� �����������
                 }   
             }            
            
           }
        }
        
           // ���������� ������� ��������
   if (countConvNeg > 0)
    averConvNeg = averConvNeg / countConvNeg;
   if (countConvPos > 0) 
    averConvPos = averConvPos / countConvPos;
   if (countDivNeg > 0)
    averDivNeg  = averDivNeg  / countDivNeg;
   if (countDivPos > 0)
    averDivPos  = averDivPos  / countDivPos;
   if (countConvNeg > 0 || countDivNeg > 0)
    averNeg     = averNeg     / (countConvNeg + countDivNeg);
   if (countConvPos > 0 || countDivPos > 0)
    averPos     = averPos     / (countConvPos + countDivPos);  
   if (countConvPos > 0)
    averLoseConvAtWin = averLoseConvAtWin / countConvPos;
   if (countDivPos > 0)
    averLoseDivAtWin = averLoseDivAtWin / countDivPos;          
        
    
    // ��������� � ���� ���������� �������������� �������� ���� ��������� \ �����������
 
   FileWriteString(file_handle,"\n\n������ ���������: "+IntegerToString(countConvPos) );   
   FileWriteString(file_handle,"\n�� ������ ���������: "+IntegerToString(countConvNeg) );
   FileWriteString(file_handle,"\n����� ���������: "+IntegerToString(countConvNeg+countConvPos) );  
   FileWriteString(file_handle,"\n������ �����������: "+IntegerToString(countDivPos) );   
   FileWriteString(file_handle,"\n�� ������ �����������: "+IntegerToString(countDivNeg) );
   FileWriteString(file_handle,"\n����� �����������: "+IntegerToString(countDivNeg+countDivPos) ); 
    
   FileWriteString(file_handle,"\n������� ���������� ���������: "+DoubleToString(averConvPos,_Digits));  
   FileWriteString(file_handle,"\n������� �� ���������� ���������: "+DoubleToString(averConvNeg,_Digits));
   FileWriteString(file_handle,"\n������� ���������� �����������: "+DoubleToString(averDivPos,_Digits)); 
   FileWriteString(file_handle,"\n������� �� ���������� �����������: "+DoubleToString(averDivNeg,_Digits));
   FileWriteString(file_handle,"\n������� ����������: "+DoubleToString(averPos,_Digits));            
   FileWriteString(file_handle,"\n������� �� ����������: "+DoubleToString(averNeg,_Digits));
   
   FileWriteString(file_handle,"\n������� ������������� ������ ��� �����������: "+DoubleToString(averLoseDivAtWin,_Digits));            
   FileWriteString(file_handle,"\n������� ������������� ������ ��� ���������: "+DoubleToString(averLoseConvAtWin,_Digits));    
   
   FileWriteString(file_handle,"\n������ �������� ������ ��� �����������: "+IntegerToString(countDivAAA)+"/"+IntegerToString(countDivPos));
   FileWriteString(file_handle,"\n������ �������� ������ ��� ���������: "+IntegerToString(countConvAAA)+"/"+IntegerToString(countConvPos));     
   
   if (GreatDoubles(averNeg,0))
    FileWriteString(file_handle,"\n��������� ������� ������� � ������: "+DoubleToString(averPos/averNeg,_Digits));     
   if (GreatDoubles(averDivNeg,0))  
    FileWriteString(file_handle,"\n��������� ������� ������� � ������ �����������: "+DoubleToString(averDivPos/averDivNeg,_Digits));         
   if (GreatDoubles(averConvNeg,0))
    FileWriteString(file_handle,"\n��������� ������� ������� � ������ ���������: "+DoubleToString(averConvPos/averConvNeg,_Digits)); 
     
                      
      
    FileClose(file_handle);          //��������� ���� ����������
        
       first_calculate = false;
     }
    else  // ���� ������� �� ������
     { 
       // �������� ����� ����������
       if ( CopyBuffer(handleStoc,0,0,rates_total,bufferStoc) < 0 ||
            CopyBuffer(handleStoc,1,0,rates_total,bufferStoc2) < 0 )
           {
             // ���� �� ������� ��������� ������ ����������
             return (0);
           }                 
       // ���� ����������� ����� ���
       if (isNewBar.isNewBar() > 0)
        {        
         // ���������� ���������\����������� ����������
         retCode = divergenceSTOC (handleStoc,_Symbol,_Period,top_level,bottom_level,divergencePoints,1);         
         // ���� ���������\����������� ����������
         if (retCode)
          {   
          // trendLine.Color(lineColors[countTrend % 5] );     
           // ������� ����� ���������\�����������              
           trendLine.Create(0,"PriceLine_"+countTrend,0,divergencePoints.timeExtrPrice1,divergencePoints.valueExtrPrice1,divergencePoints.timeExtrPrice2,divergencePoints.valueExtrPrice2); 
          // trendLine.Color(lineColors[countTrend % 5] );           
           //������� ����� ���������\����������� �� MACD
           trendLine.Create(0,"StocLine_"+countTrend,1,divergencePoints.timeExtrSTOC1,divergencePoints.valueExtrSTOC1,divergencePoints.timeExtrSTOC2,divergencePoints.valueExtrSTOC2);    
           // ����������� ���������� ����� �����
           countTrend++;
          }      
        }
     } 
       
    return(rates_total);
  }
