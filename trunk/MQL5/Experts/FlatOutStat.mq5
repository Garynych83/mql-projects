//+------------------------------------------------------------------+
//|                                                      FlatOut.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ����� ������ �� �����                                            |
//+------------------------------------------------------------------+
// ����������� ���������
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����
#include <TradeManager/TradeManager.mqh> // �������� ����������
#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <SystemLib/IndicatorManager.mqh>  // ���������� �� ������ � ������������
#include <StringUtilities.mqh> // ��������� ���������

#include <CTrendChannel.mqh> 
// ������� ���������
input double percent = 0.1; // �������
input double volume = 1.0; // ���

struct statElem
 {
  int count;    // ���������� ����� ������� � �������
  int trend;    // ��� ������ 
  int flat;     // ��� �����
  int lastExtr; // ��� ���������� ����������
 };

CTradeManager *ctm;
CExtrContainer *container;
CTrendChannel *trend;

int handleDE;
bool firstUploaded = false;
bool firstUploadedTrend = false;
string formedExtrHighEvent;
string formedExtrLowEvent;
int mode = 0;
int trendType;
int countFlat = 0;
double H; // ������ �����
double top_point; // ������� �����, ������� ����� �������
double bottom_point; // ������ �����, ������� ����� �������
double extrUp0,extrUp1;
double extrDown0,extrDown1;
datetime extrUp0Time;
datetime extrDown0Time;
datetime extrUp1Time;
datetime extrDown1Time;

CChartObjectTrend flatLine; // ������ ������ �������� �����
CChartObjectHLine topLevel; // ������� �������
CChartObjectHLine bottomLevel; // ������ �������


// ������ ��������
statElem elem[28];

// ��������� ������� � ���������
SPositionInfo pos_info;      // ��������� ���������� � �������
STrailing     trailing;      // ��������� ���������� � ���������

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
   ctm = new CTradeManager();
   if (ctm == NULL)
    {
     Print("�� ������� ������� �������� ����������");
     return (INIT_FAILED);
    }
   container = new CExtrContainer(handleDE,_Symbol,_Period);
   if (container == NULL)
    {
     Print("�� ������� ������� ��������� �����������");
     return (INIT_FAILED);
    }
   trend = new CTrendChannel(0,_Symbol,_Period,handleDE,percent);
   if (trend == NULL)
    {
     Print("�� ������� ������� ��������� �������");
     return (INIT_FAILED);
    }    
   // ��������� ����� �������
   formedExtrHighEvent = GenUniqEventName("EXTR_UP_FORMED");
   formedExtrLowEvent = GenUniqEventName("EXTR_DOWN_FORMED");
   // ���������� ��������� ��������
   ResetAllElems (); 
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete ctm;
   delete container;
   delete trend;
  }

void OnTick()
  {
   ctm.OnTick();
   if (ctm.GetPositionCount()>0)
    mode = 0;
   if (!firstUploaded)
    {
     firstUploaded = container.Upload();
    }
   if (!firstUploadedTrend)
    {
     firstUploadedTrend = trend.UploadOnHistory();
    }
   if (!firstUploaded || !firstUploadedTrend)
    return;   
  }

// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
  {
   int flatNow;   
   // �� ��������� ������ � ��������� ����������� � �������
   trend.UploadOnEvent(sparam,dparam,lparam);
   container.UploadOnEvent(sparam,dparam,lparam); 
   // ���� ������ ������� "������������� ���������"
   if (sparam == formedExtrHighEvent || sparam == formedExtrLowEvent)
    { 
     // ���� ��� �� ������ �����
     if (mode == 0)
      {
       // ���� �� ����� �����
       trendType = trend.GetTrendByIndex(0).GetDirection();
       if (trendType != 0)
        {
         // ��������� � ����� ������������ �����
         mode = 1;
        }
      }
     else if (mode == 1)
      {
       // ���� ������ �� �����
       if (!trend.IsTrendNow())
        { 
         // ��������� ����������
         extrUp0 = container.GetFormedExtrByIndex(0,EXTR_HIGH).price;
         extrUp1 = container.GetFormedExtrByIndex(1,EXTR_HIGH).price;
         extrDown0 = container.GetFormedExtrByIndex(0,EXTR_LOW).price;
         extrDown1 = container.GetFormedExtrByIndex(1,EXTR_LOW).price;
         extrUp0Time = container.GetFormedExtrByIndex(0,EXTR_HIGH).time;
         extrUp1Time = container.GetFormedExtrByIndex(1,EXTR_HIGH).time;
         extrDown0Time = container.GetFormedExtrByIndex(0,EXTR_LOW).time;
         extrDown1Time = container.GetFormedExtrByIndex(1,EXTR_LOW).time;
         
         //---------- ��������� ���� �������

         // ���� ������ ���� � � ��������� ��������� - �������, ����� �����
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(0,1,1,1);
          }
         // ���� ������ ���� � � ��������� ��������� - �������, ����� ����
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(1,1,1,-1);
          }   
         // ���� ������ ���� � � ��������� ��������� - ������, ����� �����
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(2,1,-1,1);
          }                    
         // ���� ������ ���� � � ��������� ��������� - ������, ����� ����
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(3,1,-1,-1);
          }            
           
        
        }
      }
    }
  }
  
// ���������� ���������� ��� �������
string GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 } 
 
// ������� ��������� ����� ������

bool IsFlatA ()
 {
  //  ���� 
  if ( LessOrEqualDoubles (MathAbs(extrUp1-extrUp0),percent*H) &&
       GreatOrEqualDoubles (extrDown0 - extrDown1,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatB ()
 {
  //  ���� 
  if ( GreatOrEqualDoubles (extrUp1-extrUp0,percent*H) &&
       LessOrEqualDoubles (MathAbs(extrDown0 - extrDown1),percent*H)
     )
    {
     return (true);
    }
  return (false);
 }

bool IsFlatC ()
 {
  //  ���� 
  if ( LessOrEqualDoubles (MathAbs(extrUp1-extrUp0),percent*H) &&
       LessOrEqualDoubles (MathAbs(extrDown0 - extrDown1),percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatD ()
 {
  //  ���� 
  if ( GreatOrEqualDoubles (extrUp1-extrUp0,percent*H) &&
       GreatOrEqualDoubles (extrDown0 - extrDown1,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatE ()
 {
  //  ���� 
  if ( GreatOrEqualDoubles (extrUp0-extrUp1,percent*H) &&
       GreatOrEqualDoubles (extrDown1 - extrDown0,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
void ResetAllElems ()
 {
  for (int i = 0;i<28;i++)
   {
    elem[i].count = 0;
    elem[i].flat = 0;
    elem[i].lastExtr = 0;
    elem[i].trend = 0;
   }
 }
 
 // �������������� �������
 void DrawFlatLines ()  // ������� ����� �����
  {
   flatLine.Create(0, "flatUp_" + countFlat, 0, extrUp0Time, extrUp0, extrUp1Time, extrUp1); // ������� �����  
   flatLine.Color(clrYellow);
   flatLine.Width(1);
   flatLine.Create(0,"flatDown_" + countFlat, 0, extrDown0Time, extrDown0, extrDown1Time, extrDown1); // ������ �����
   flatLine.Color(clrYellow);
   flatLine.Width(1);
   countFlat ++;   
   topLevel.Delete();
   topLevel.Create(0, "topLevel", 0, top_point);
   bottomLevel.Delete();
   bottomLevel.Create(0, "bottomLevel", 0, bottom_point);   
  } 
  
 // ���������� ���������� �������� ����� ��� ��� ������������
 void CalcFlat (int index,int flatType,int lastExtr,int trend)
  {
   H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
   top_point = extrUp0 + H*0.75;
   bottom_point = extrDown0 - H*0.75;
   DrawFlatLines ();
   elem[index].flat = 1;
   elem[index].lastExtr = 1;
   elem[index].trend = 1;
  }