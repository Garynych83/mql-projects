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
  int count;     // ���������� ����� ������� � �������
  int countUp;   // ���������� ���������� ������� �������
  int countDown; // ���������� ���������� ������ �������
  int trend;     // ��� ������ 
  string flat;   // ��� �����
  int lastExtr;  // ��� ���������� ����������
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
int fileTestStat; // ����� �����
int indexOfElemNow = 0; // ������ ������� �������� � ������� �������� 
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
   // ������� ����� ����� ������������ ���������� ����������� �������
   fileTestStat = FileOpen("FlatOutStat/FlatOutStat 8.5.15/FlatStat_" + _Symbol+"_" + PeriodToString(_Period) + ".txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
   if (fileTestStat == INVALID_HANDLE) //�� ������� ������� ����
    {
     Print("�� ������� ������� ���� ������������ ���������� ����������� �������");
     return (INIT_FAILED);
    }      
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
   SaveStatToFile (); // ��������� ���������� � ����
   FileClose(fileTestStat);
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
   // ���� ������ ����� �������� �������� �������
   if (mode == 2)
    {
     // ���� ���� �������� ������� �����
     if (GreatOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_BID),top_point))
      {
       elem[indexOfElemNow].countUp ++; // ����������� ���������� ��������
       mode = 0; // ��������� � ����������� ����� ������ ������
       topLevel.Delete(); // ������� ������� �����
       bottomLevel.Delete(); // ������� ������ �����
      }
     // ���� ���� �������� ������ �����
     if (LessOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_ASK),bottom_point))
      {
       elem[indexOfElemNow].countDown ++; // ����������� ���������� ��������
       mode = 0; // ��������� � ����������� ����� ������ ������
       topLevel.Delete(); // ������� ������� �����
       bottomLevel.Delete(); // ������� ������ �����
      }      
    } 
    
   
    Comment("����� = ",trendType,
            "��������� ��������� = "
    
            "\n\n��� �, ����� �����, ����. ����� - �����, ���������� �������� ����� = ",elem[0].countUp,
            "\n��� �, ����� �����, ����. ����� - �����, ���������� �������� ���� = ",elem[0].countDown,
            
            "\n\n��� �, ����� ����, ����. ����� - �����, ���������� �������� ����� = ",elem[1].countUp,
            "\n��� �, ����� ����, ����. ����� - �����, ���������� �������� ���� = ",elem[1].countDown,    
            
            "\n\n��� �, ����� �����, ����. ����� - ����, ���������� �������� ����� = ",elem[2].countUp,
            "\n��� �, ����� �����, ����. ����� - ����, ���������� �������� ���� = ",elem[2].countDown,    
            
            "\n\n��� �, ����� ����, ����. ����� - ����, ���������� �������� ����� = ",elem[3].countUp,
            "\n��� �, ����� ����, ����. ����� - ����, ���������� �������� ���� = ",elem[3].countDown                        
                    
            );
    
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
       // ���� ������ �����
       if (trend.IsTrendNow() != 0)
        {
         // ���� �� ����� �����
         trendType = trend.GetTrendByIndex(0).GetDirection();
         if (trendType != 0)
          {
           // ��������� � ����� ������������ �����
           mode = 1;
          }
         }
      }
     else if (mode == 1)
      {
       // ���� ������ ����� �����
       if (trend.IsTrendNow())
        {
         trendType = trend.GetTrendByIndex(0).GetDirection();
        }
       // ���� ������ �� �����
       else
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

 // ��� ����� �

         // ���� ������ ���� � � ��������� ��������� - �������, ����� �����
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(0,"A",1,1);
           mode = 2;
          }
         // ���� ������ ���� � � ��������� ��������� - �������, ����� ����
         if (IsFlatA() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(1,"A",1,-1);
           mode = 2;
          }   
         // ���� ������ ���� � � ��������� ��������� - ������, ����� �����
         if (IsFlatA() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(2,"A",-1,1);
           mode = 2;
          }                    
         // ���� ������ ���� � � ��������� ��������� - ������, ����� ����
         if (IsFlatA() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(3,"A",-1,-1);
           mode = 2;
          } 
                    
 // ��� ����� B

         // ���� ������ ���� B � ��������� ��������� - �������, ����� �����
         if (IsFlatB() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(4,"B",1,1);
           mode = 2;
          }
         // ���� ������ ���� B � ��������� ��������� - �������, ����� ����
         if (IsFlatB() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(5,"B",1,-1);
           mode = 2;
          }   
         // ���� ������ ���� B � ��������� ��������� - ������, ����� �����
         if (IsFlatB() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(6,"B",-1,1);
           mode = 2;
          }                    
         // ���� ������ ���� B � ��������� ��������� - ������, ����� ����
         if (IsFlatB() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(7,"B",-1,-1);
           mode = 2;
          }  
           
 // ��� ����� C

         // ���� ������ ���� B � ��������� ��������� - �������, ����� �����
         if (IsFlatC() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(8,"C",1,1);
           mode = 2;
          }
         // ���� ������ ���� C � ��������� ��������� - �������, ����� ����
         if (IsFlatB() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(9,"C",1,-1);
           mode = 2;
          }   
         // ���� ������ ���� C � ��������� ��������� - ������, ����� �����
         if (IsFlatC() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(10,"C",-1,1);
           mode = 2;
          }                    
         // ���� ������ ���� C � ��������� ��������� - ������, ����� ����
         if (IsFlatC() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(11,"C",-1,-1);
           mode = 2;
          }     

 // ��� ����� D

         // ���� ������ ���� D � ��������� ��������� - �������, ����� �����
         if (IsFlatD() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(12,"D",1,1);
           mode = 2;
          }
         // ���� ������ ���� D � ��������� ��������� - �������, ����� ����
         if (IsFlatD() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(13,"D",1,-1);
           mode = 2;
          }   
         // ���� ������ ���� D � ��������� ��������� - ������, ����� �����
         if (IsFlatC() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(14,"D",-1,1);
           mode = 2;
          }                    
         // ���� ������ ���� D � ��������� ��������� - ������, ����� ����
         if (IsFlatD() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(15,"D",-1,-1);
           mode = 2;
          }     

 // ��� ����� E

         // ���� ������ ���� E � ��������� ��������� - �������, ����� �����
         if (IsFlatE() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(16,"E",1,1);
           mode = 2;
          }
         // ���� ������ ���� E � ��������� ��������� - �������, ����� ����
         if (IsFlatE() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(17,"E",1,-1);
           mode = 2;
          }   
         // ���� ������ ���� E � ��������� ��������� - ������, ����� �����
         if (IsFlatE() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(18,"E",-1,1);
           mode = 2;
          }                    
         // ���� ������ ���� E � ��������� ��������� - ������, ����� ����
         if (IsFlatE() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(19,"E",-1,-1);
           mode = 2;
          } 

 // ��� ����� F

         // ���� ������ ���� F � ��������� ��������� - �������, ����� �����
         if (IsFlatF() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(20,"F",1,1);
           mode = 2;
          }
         // ���� ������ ���� F � ��������� ��������� - �������, ����� ����
         if (IsFlatF() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(21,"F",1,-1);
           mode = 2;
          }   
         // ���� ������ ���� F � ��������� ��������� - ������, ����� �����
         if (IsFlatF() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(22,"F",-1,1);
           mode = 2;
          }                    
         // ���� ������ ���� F � ��������� ��������� - ������, ����� ����
         if (IsFlatF() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(23,"F",-1,-1);
           mode = 2;
          }      
                      
 // ��� ����� G

         // ���� ������ ���� G � ��������� ��������� - �������, ����� �����
         if (IsFlatG() && extrUp0Time > extrDown0Time && trendType == 1 )
          {
           CalcFlat(24,"G",1,1);
           mode = 2;
          }
         // ���� ������ ���� G � ��������� ��������� - �������, ����� ����
         if (IsFlatG() && extrUp0Time > extrDown0Time && trendType == -1 )
          {
           CalcFlat(25,"G",1,-1);
           mode = 2;
          }   
         // ���� ������ ���� G � ��������� ��������� - ������, ����� �����
         if (IsFlatG() && extrUp0Time < extrDown0Time && trendType == 1 )
          {
           CalcFlat(26,"G",-1,1);
           mode = 2;
          }                    
         // ���� ������ ���� G � ��������� ��������� - ������, ����� ����
         if (IsFlatG() && extrUp0Time < extrDown0Time && trendType == -1 )
          {
           CalcFlat(27,"G",-1,-1);
           mode = 2;
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
 
bool IsFlatF ()
 {
  //  ���� 
  if ( LessOrEqualDoubles (MathAbs(extrUp1-extrUp0), percent*H) &&
       GreatOrEqualDoubles (extrDown1 - extrDown0 , percent*H)
     )
    {
     return (true);
    }
  return (false);
 } 

bool IsFlatG ()
 {
  //  ���� 
  if ( GreatOrEqualDoubles (extrUp0 - extrUp1, percent*H) &&
       LessOrEqualDoubles (MathAbs(extrDown0 - extrDown1), percent*H)
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
    elem[i].countDown = 0;
    elem[i].countUp = 0;
    elem[i].flat = "-";
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
 void CalcFlat (int index,string flatType,int lastExtr,int trend)
  {
   H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
   top_point = extrUp0 + H*0.75;
   bottom_point = extrDown0 - H*0.75;
   DrawFlatLines ();
   elem[index].flat = flatType;
   elem[index].lastExtr = lastExtr;
   elem[index].trend = trend;
   elem[index].count ++; 
   indexOfElemNow = index;
  }
 
 // ��������� ���������� � ����
 void SaveStatToFile ()
  {
   FileWriteString(fileTestStat,"����������: \n\n");
   for (int i=0;i<28;i++)
    {
     FileWriteString(fileTestStat,"��� �����: "+elem[i].flat+" | �����: "+IntegerToString(elem[i].trend)+" | ����. �����: "+
                                  " | "+IntegerToString(elem[i].lastExtr)+" | �������� �����: "+IntegerToString(elem[i].countUp)+" | �������� ����: "+IntegerToString(elem[i].countDown)+"\n\n");
    }
  }