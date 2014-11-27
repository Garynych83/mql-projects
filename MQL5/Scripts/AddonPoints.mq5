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

int fileHandle;                          // ����� ����� ����������

void OnStart()
  {
  
    // ������� ����� ����� ������������ ���������� ����������� �������
    fileHandle = FileOpen("MY_REVOLUTION.txt",FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
    if (fileHandle == INVALID_HANDLE) //�� ������� ������� ����
     {
      Print("�� ������� ������� ���� ������������ ���������� ����������� �������");
      return;
     }   
  
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
   handlePBI = iCustom(_Symbol,_Period,"PriceBasedIndicator");
   if (handlePBI == INVALID_HANDLE)
    {
     Alert("������ ������� AddingPoint.mq5: �� ������� ������� ����� PriceBasedIndicator");
     FileClose(fileHandle);
     return;
    }
   // �������� ��������� ����� PriceBasedIndicator
   for (int attempts=0;attempts<25;attempts++)
    {
     copiedHigh = CopyHigh(_Symbol,_Period,0,pbiDepth,high);
     copiedLow  = CopyLow(_Symbol,_Period,0,pbiDepth,low);
     copiedPBI  = CopyBuffer(handlePBI,4,0,pbiDepth,bufferPBI);
     copiedTime = CopyTime(_Symbol,_Period,0,pbiDepth,time);
    }
   if (copiedHigh < pbiDepth || copiedLow < pbiDepth || copiedPBI < pbiDepth || copiedTime < pbiDepth)
    {
     Alert("������ ������� AddingPoint.mq5: �� ������� ���������� ������");
     FileClose(fileHandle);
     return;
    }
   // ��������� ������ ���������� �����
   FirstCalculate();
   
   FileClose(fileHandle);
  }
 // ������� ������� ������� �������������� �����
 void FirstCalculate ()
  {
   double min,max;
   int    indMin=-1,indMax=-1;
   int    prevMove=-1,curMove=-1; // ��������� � ������� ��������
   // �������� � ����� ������� � ��������� �������������� �����
   for (int ind=pbiDepth-1;ind>=0;ind--)
    {
     
     FileWriteString(fileHandle,"\n��� �������� = "+DoubleToString(bufferPBI[ind],0)+" ����� = "+TimeToString(time[ind])+" ind = "+ind+" pbiDepth = "+pbiDepth );    
     //Alert("�������� = ",DoubleToString(bufferPBI[ind]) ," ����� = ",TimeToString(time[ind]) );
     // ���� �������� ��������� �����
     if ( bufferPBI[ind] == MOVE_TYPE_CORRECTION_UP )
      {
       if ( indMax == -1 )
        {
         indMax = ind;
         max = high[ind];
    /*     Alert("������ ��������� �����. ����� = ",TimeToString(time[ind]),
               " ���� = ",DoubleToString(max)
              );   */
        }
       else 
        {
         if ( GreatDoubles(high[ind],max) )
           {
            indMax = ind;
            max = high[ind];
        /*      Alert("��������� ����� ������������. ����� = ",TimeToString(time[ind]),
               " ���� = ",DoubleToString(max)
              );*/
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
      /*   Alert("������ ��������� ����. ����� = ",TimeToString(time[ind]),
               " ��� = ",DoubleToString(min)
              );    */     
        }
       else 
        {
         if ( LessDoubles(low[ind],min) )
           {
            indMin = ind;
            min = low[ind];
        /*      Alert("��������� ���� ������������. ����� = ",TimeToString(time[ind]),
               " ��� = ",DoubleToString(min)
              );      */      
           }
        }
      }
     // ����� ������ ��������, �������� �� ���������
     else
      {
       //Alert("������ ��������");
       curMove = int(bufferPBI[ind]);   // ��������� ������� ��������
     //  Alert("�������� = ",curMove," ����� = ",TimeToString(time[ind]) );
       // ���� ������� �������� - ����� �����, ���������� - ��������� ���� � �� ���� - ����� �����, �� ��������� ����� 
       if ( (curMove == MOVE_TYPE_TREND_UP  || curMove == MOVE_TYPE_TREND_UP_FORBIDEN ) &&
            (prevMove == MOVE_TYPE_TREND_UP || prevMove == MOVE_TYPE_TREND_UP_FORBIDEN) &&
            indMin != -1
          )
           {
          //  Alert("��������� ����� min ����� = ",TimeToString(time[indMin]));
            // �� ��������� �����
            buffer[indMin] = min;
            vertLine.Color(clrRed);
            // ������� ������������ �����, ������������ ������ ��������� ����������� MACD
            vertLine.Create(0,"MIN_"+IntegerToString(indMin),0,time[indMin]);
           }
       // ���� ������� �������� - ����� ����, ���������� - ��������� ����� � �� ���� - ����� ����, �� ��������� ����� 
       if ( (curMove == MOVE_TYPE_TREND_DOWN  || curMove == MOVE_TYPE_TREND_DOWN_FORBIDEN ) &&
            (prevMove == MOVE_TYPE_TREND_DOWN || prevMove == MOVE_TYPE_TREND_DOWN_FORBIDEN) &&
            indMax != -1
          )
           {
          //  Alert("��������� ����� max ����� = ",TimeToString(time[indMax]));
            // �� ��������� �����
            buffer[indMax] = max;
            vertLine.Color(clrRed);
            // ������� ������������ �����, ������������ ������ ��������� ����������� MACD
            vertLine.Create(0,"MAX_"+IntegerToString(indMax),0,time[indMax]);            
           }
       // ���������� ������� Min � max
       indMax = -1;    
       indMin = -1;    
       // ��������� ������� ��������, ��� ����������
       prevMove = curMove;       
      }
      
    }
  }