//+------------------------------------------------------------------+
//|                                            ANOTHER_FLAT_STAT.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| �������� ���������� �� ������                                    |
//+------------------------------------------------------------------+
#include <CMoveContainer.mqh> // ��������� ������� �������� 
#include <SystemLib/IndicatorManager.mqh>  // ���������� �� ������ � ������������
#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����

// ������� ���������
input double percent = 0.1; // �������

// ��������� ��� �������� ����������
struct stat_elem
 {
  string flat_type; // ��� �����
  int last_extr; // ����������� ���������� ����������
  int trend_direction; // ����������� ���������� ������
  int countUp; // ���������� ���������� ������� ������� ������
  int countDown; // ���������� ���������� ������ ������� ������
 };
 
// ���������� 
bool firstUploadedMovements = false; // ���� ������ �������� ��������
bool firstUploadedExtremums = false; // ���� ������ �������� �����������
string eventExtrUpFormed; // ��� ������� "������ �������������� ������� ���������"
string eventExtrDownFormed; // ��� ������� "������ �������������� ������ ���������"
int handleDE; // ����� DrawExtremums
double extrUp0,extrUp1;     
double extrDown0,extrDown1;
datetime extrUp0Time, extrUp1Time;
datetime extrDown0Time, extrDown1Time;
CMoveContainer *moveContainer;
CExtrContainer *extrContainer;

CChartObjectHLine topLine; // ������� �������
CChartObjectHLine bottomLine; // ������ �������

// ��������� ���������� ����������
double topLevel;   // ������� �������, ������� ����� �������
double bottomLevel; // ������ �������, ������� ����� �������
double H;  // ������ ������
int lastTrendDirection = 0; // ����������� ���������� ������
int flatType = 0; // ��� �����
int mode = 0; // �����

stat_elem stat[]; // ����� ����������
int countSit = 0; // ���������� ��������

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
   extrContainer = new CExtrContainer(handleDE,_Symbol,_Period);
   moveContainer = new CMoveContainer(0,_Symbol,_Period,handleDE,percent);
   // ���������� ���������� ����� ������� ������� ����� �������������� �����������
   eventExtrDownFormed = GenUniqEventName("EXTR_UP_FORMED");
   eventExtrUpFormed = GenUniqEventName("EXTR_DOWN_FORMED");
   if (!firstUploadedMovements)
    {
     firstUploadedMovements = moveContainer.UploadOnHistory();
    }
   if (!firstUploadedExtremums)
    {
     firstUploadedExtremums = extrContainer.Upload();
    }   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete extrContainer;
   delete moveContainer;
  }

void OnTick()
  {
   if (!firstUploadedMovements)
    {
     firstUploadedMovements = moveContainer.UploadOnHistory();
    }
   if (!firstUploadedExtremums)
    {
     firstUploadedExtremums = extrContainer.Upload();
    }
   if (!firstUploadedMovements || !firstUploadedExtremums)
    return;   
   // ���� ������ ����� mode = 1, �� ��������� �������� 
   if (mode == 1)
    {
     // ���� ���� �������� ������� �����
     if (GreatOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_BID),topLevel))
      {
       // ��������� � ����� ������ ������
       mode = 0;
       // ������� ����� ������ 
       DeleteChannel();
      }
     // ���� ���� �������� ������ �����
     if (LessOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_ASK),bottomLevel))
      {
       // ��������� ��������� �������� ����������
       stat[countSit-1].countDown ++;
       stat[countSit-1].flat_type =        
       // ��������� � ����� ������ ������
       mode = 0;
       // ������� ����� ������
       DeleteChannel();
      }
    }
  }
  
// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
  {
   int flatNow;  
   int countMove;
   // �� ��������� ������ � ��������� ����������� � �������
   moveContainer.UploadOnEvent(sparam,dparam,lparam);
   extrContainer.UploadOnEvent(sparam,dparam,lparam); 
   // ���� ������ ������� "������������� ���������"
   if (sparam == eventExtrUpFormed || sparam == eventExtrDownFormed)
    { 
      // ��������� ����������
      
      extrUp0 = extrContainer.GetFormedExtrByIndex(0,EXTR_HIGH).price;
      extrUp1 = extrContainer.GetFormedExtrByIndex(1,EXTR_HIGH).price;
      extrDown0 = extrContainer.GetFormedExtrByIndex(0,EXTR_LOW).price;
      extrDown1 = extrContainer.GetFormedExtrByIndex(1,EXTR_LOW).price;
      extrUp0Time = extrContainer.GetFormedExtrByIndex(0,EXTR_HIGH).time;
      extrUp1Time = extrContainer.GetFormedExtrByIndex(1,EXTR_HIGH).time;      
      extrDown0Time = extrContainer.GetFormedExtrByIndex(0,EXTR_LOW).time;
      extrDown1Time = extrContainer.GetFormedExtrByIndex(1,EXTR_LOW).time;
      
      // ���� ������ ����� �����
      if (moveContainer.GetMoveByIndex(0).GetMoveType() == 1)
       {
        lastTrendDirection = 1;
       }
      // ���� ������ ����� ����
      if (moveContainer.GetMoveByIndex(0).GetMoveType() == -1)
       {
        lastTrendDirection = -1;
       }      
      // ���� ������ �� ����� �������� ������ � �� ������ ����� �������� ��� ���������� ������ ��� ���������� ����������
      if (mode == 0)
       {
        // ���� ������ � ���������� �������� - 3 ��������, ������ ����� ����� ��������� ��������� ������
        if (moveContainer.GetTotal()==3)
         {
          flatType = moveContainer.GetMoveByIndex(0).GetMoveType();
          // �� ��������� ��������� �������
          H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
          topLevel = extrUp0 + H*0.75;
          bottomLevel = extrDown0 - H*0.75;
          // �������� ������ ��� ����� ��������
          countSit ++;
          ArrayResize(stat,countSit);
          // ������ �����  
          DrawChannel();
          // ���������� ����� mode � 1, ��� ��������, ��� �� ���� �������� ����� ������ ��� ������� ������
          mode = 1;
         }
       }
      // ���� ������ ����� �������� ����� �������
      else 
       {
        // ���� ������ ������ �����
        if (moveContainer.GetMoveByIndex(0).GetMoveType() == 1 || moveContainer.GetMoveByIndex(0).GetMoveType() == -1)
         {
          mode = 0;
          DeleteChannel ();
         }
       }
     
    }
  }
  
// ���������� ���������� ��� �������
string GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 }   

// ������ ����� 
void DrawChannel ()
 {
  topLine.Create(0,"topLevel",0,topLevel);
  bottomLine.Create(0,"bottomLevel",0,bottomLevel);
 }

// ������� �����
void DeleteChannel ()
 {
  topLine.Delete();
  bottomLine.Delete();
 }

// ��������� ��������� ����� 
void SaveFlatParams (int trend,int flat,int extr,int up,int down)
 {
  stat[countSit-1].countDown = down;
  stat[countSit-1].countUp = up;
  stat[countSit-1].flat_type = flat;
  stat[countSit-1].last_extr = extr;
  stat[countSit-1].trend_direction = trend;
 }
 
// ������� ���������� ������ � ������������� ������� ��� ���� ������
string GetFlatTypeStat (string flatType,int trend,int flat,int extr)
 {
  string str="";
  int countUp=0; // ���������� ���������� ������� �����
  int countDown=0; // ���������� ���������� ������ �����
  // �������� �� ����� ������ � ������������ ����������
  for (int i=0;i<countSit;i++)
   {
    // ���� ����� ���� ��������
    if (trend == stat[i].trend_direction && 
        flat == stat[i].flat_type &&
        extr == stat[i].last_extr)
         {
          if (stat[i].countUp == 1)
           countUp++;
          if (stat[i].countDown == 1)
           countDown++;
         }
   }
  // ��������� ������
  str = "��� �����: "+flatType+" �����: "+trend+" flat: "+flat+" extr: "+extr+" �����: "+countUp+" ����: "+countDown;
  return str;
 }