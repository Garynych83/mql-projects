//+------------------------------------------------------------------+
//|                                                  AddonPoints.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property script_show_inputs 
//����������� ����������� ���������
#include <ColoredTrend\ColoredTrendUtilities.mqh>
#include <CompareDoubles.mqh>
#include <ChartObjects/ChartObjectsLines.mqh>     
//+------------------------------------------------------------------+
//| ������, ������������ ������������� �����                         |
//+------------------------------------------------------------------+
// ������� ��������� �������
input int pbiDepth = 1000;     // �������, �� ������� ����������� 
// ���������� ���������� �������
int handlePBI; // ����� PBI
double bufferPBI[];  // ����� PBI
double high[]; // ����� ������� ���
double low[]; // ����� ������ ���
double buffer[]; // ����� �������������� ����� 
datetime time[]; // ����� �������
int copiedPBI;
int copiedHigh;
int copiedLow;
int copiedTime;
CChartObjectVLine  vertLine;                       // ������ ������ ������������ �����
void OnStart()
  { 
   // ���������� ������������������ ��������� � ��������, ��� � ���������
   ArraySetAsSeries(bufferPBI,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(buffer,true);
   ArraySetAsSeries(time,true);
   // �������� ����� �������������� �����
   ArrayResize(buffer,pbiDepth);
   ArrayInitialize(buffer,0);
   // ������� ����� PBI
   handlePBI = iCustom(_Symbol,_Period,"PriceBasedIndicator",pbiDepth);
   if (handlePBI == INVALID_HANDLE)
    {
     Alert("������ ������� AddingPoint.mq5: �� ������� ������� ����� PriceBasedIndicator");
     return;
    }
   // �������� ��������� ����� PriceBasedIndicator
   for (int attempts=0;attempts<25;attempts++)
    {
     copiedHigh = CopyHigh(_Symbol,_Period,TimeCurrent(),pbiDepth,high);
     copiedLow  = CopyLow(_Symbol,_Period,TimeCurrent(),pbiDepth,low);
     copiedPBI  = CopyBuffer(handlePBI,4,TimeCurrent(),pbiDepth,bufferPBI);
     copiedTime = CopyTime(_Symbol,_Period,TimeCurrent(),pbiDepth,time);
    }
   if (copiedHigh < pbiDepth || copiedLow < pbiDepth || copiedPBI < pbiDepth || copiedTime < pbiDepth)
    {
     Alert("������ ������� AddingPoint.mq5: �� ������� ���������� ������");
     return;
    }
   // ��������� ������ ���������� �����
   FirstCalculate();
  }
 // ������� ������� ������� �������������� �����
 void FirstCalculate ()
  {
   double min,max;
   int    indMin=-1,indMax=-1;
   int    prevMove=-1; // ��������� ��������
   // �������� � ����� ������� � ��������� �������������� �����
   for (int ind=pbiDepth-1;ind>=0;ind--)
    {
     // ���� �������� ��������� �����
     if ( bufferPBI[ind] == MOVE_TYPE_CORRECTION_UP )
      {
       if ( indMax == -1 )
        {
         indMax = ind;
         max = high[ind];
        }
       else 
        {
         if ( GreatDoubles(high[ind],max) )
           {
            indMax = ind;
            max = high[ind];
           }
        }
      }
     // ����� ���� �������� ��������� ����
     else if ( bufferPBI[ind] == MOVE_TYPE_CORRECTION_DOWN )
      {
       if ( indMin == -1 )
        {
         indMin = ind;
         min = low[ind];   
        }
       else 
        {
         if ( LessDoubles(low[ind],min) )
           {
            indMin = ind;
            min = low[ind];     
           }
        }
      }
     // ����� ������ ��������, �������� �� ���������
     else
      {
     //  curMove = int(bufferPBI[ind]);   // ��������� ������� ��������
       // ���� ������� �������� - ����� �����, ���������� - ��������� ���� � �� ���� - ����� �����, �� ��������� ����� 
       if ( (bufferPBI[ind] == MOVE_TYPE_TREND_UP  ||  bufferPBI[ind] == MOVE_TYPE_TREND_UP_FORBIDEN ) &&
            (prevMove == MOVE_TYPE_TREND_UP || prevMove == MOVE_TYPE_TREND_UP_FORBIDEN) &&
            indMin != -1
          )
           {
            // �� ��������� �����
            buffer[indMin] = min;
            vertLine.Color(clrRed);
            // ������� ������������ �����, ������������ ������ ��������� ����������� MACD
            vertLine.Create(0,"MIN_"+IntegerToString(ind),0,time[indMin]);
            vertLine.Color(clrRed);
           }
       // ���� ������� �������� - ����� ����, ���������� - ��������� ����� � �� ���� - ����� ����, �� ��������� ����� 
       if ( (bufferPBI[ind] == MOVE_TYPE_TREND_DOWN  || bufferPBI[ind] == MOVE_TYPE_TREND_DOWN_FORBIDEN ) &&
            (prevMove == MOVE_TYPE_TREND_DOWN || prevMove == MOVE_TYPE_TREND_DOWN_FORBIDEN) &&
            indMax != -1
          )
           {
            // �� ��������� �����
            buffer[indMax] = max;
            vertLine.Color(clrRed);
            // ������� ������������ �����, ������������ ������ ��������� ����������� MACD
            vertLine.Create(0,"MAX_"+IntegerToString(ind),0,time[indMax]);   
            vertLine.Color(clrRed);      
           }
       // ���������� ������� Min � max
       indMax = -1;    
       indMin = -1;    
       // ��������� ������� ��������, ��� ����������
       prevMove = int(bufferPBI[ind]);       
      }
           
    }
  }