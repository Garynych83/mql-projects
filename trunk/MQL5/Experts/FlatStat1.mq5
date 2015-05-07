//+------------------------------------------------------------------+
//|                                                     FlatStat.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ����� ���������� �� ������                                       |
//+------------------------------------------------------------------+
// ����������
#include <SystemLib/IndicatorManager.mqh>       // ���������� �� ������ � ������������
#include <ChartObjects/ChartObjectsLines.mqh>   // ��� ��������� ����� ������
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <DrawExtremums/CExtrContainer.mqh>     // ��������� �����������
#include <CTrendChannel.mqh>                    // ��������� ���������
#include <CompareDoubles.mqh>                   // ��� ��������� ������������ �����
#include <StringUtilities.mqh>                  // ��������� ���������
// ���������
input double percent = 0.1; // �������
// ������� ����������
bool trendNow = false;
bool firstUploaded = false; // ���� �������� ������� �����������
bool firstUploadedTrend = false; // ���� �������� ������� �������
int  calcMode = 0;  // ����� ����������
int  flatType = 0;
int  trendType = 0;
int  tempTrendType = 0;
int  countDrawedFlat = 0; 
// ������
int handleDE;
// �������� �������� ��� �������, ����� ��������� ��������� - �������
int flat_a_up_tup = 0,flat_a_down_tup = 0; 
int flat_a_up_tdown = 0,flat_a_down_tdown = 0; 

int flat_b_up_tup = 0,flat_b_down_tup = 0; 
int flat_b_up_tdown = 0,flat_b_down_tdown = 0; 

int flat_c_up_tup = 0,flat_c_down_tup = 0; 
int flat_c_up_tdown = 0,flat_c_down_tdown = 0; 

int flat_d_up_tup = 0,flat_d_down_tup = 0; 
int flat_d_up_tdown = 0,flat_d_down_tdown = 0; 

int flat_e_up_tup = 0,flat_e_down_tup = 0; 
int flat_e_up_tdown = 0,flat_e_down_tdown = 0;

int flat_f_up_tup = 0,flat_f_down_tup = 0; 
int flat_f_up_tdown = 0,flat_f_down_tdown = 0;

int flat_g_up_tup = 0,flat_g_down_tup = 0; 
int flat_g_up_tdown = 0,flat_g_down_tdown = 0;   

// �������� �������� ��� �������, ����� ��������� ��������� - ������
int flat_a_up_tup2 = 0,flat_a_down_tup2 = 0; 
int flat_a_up_tdown2 = 0,flat_a_down_tdown2 = 0; 

int flat_b_up_tup2 = 0,flat_b_down_tup2 = 0; 
int flat_b_up_tdown2 = 0,flat_b_down_tdown2 = 0; 

int flat_c_up_tup2 = 0,flat_c_down_tup2 = 0; 
int flat_c_up_tdown2 = 0,flat_c_down_tdown2 = 0; 

int flat_d_up_tup2 = 0,flat_d_down_tup2 = 0; 
int flat_d_up_tdown2 = 0,flat_d_down_tdown2 = 0; 

int flat_e_up_tup2 = 0,flat_e_down_tup2 = 0; 
int flat_e_up_tdown2 = 0,flat_e_down_tdown2 = 0;   

int flat_f_up_tup2 = 0,flat_f_down_tup2 = 0; 
int flat_f_up_tdown2 = 0,flat_f_down_tdown2 = 0;   

int flat_g_up_tup2 = 0,flat_g_down_tup2 = 0; 
int flat_g_up_tdown2 = 0,flat_g_down_tdown2 = 0;   

// ���������� ��� �������� ���� � ������
double extrUp0,extrUp1;
datetime timeUp0,timeUp1;
double extrDown0,extrDown1;
datetime timeDown0,timeDown1;
datetime tempLastExtrTime; 
//������ ������������ 
datetime timeStart;
datetime timeFinish;

double H; // ������ �����
double top_point; // ������� �����, ������� ����� �������
double bottom_point; // ������ �����, ������� ����� �������
// ������� �������
CExtrContainer *container;
CTrendChannel *trend;
CChartObjectTrend flatLine; // ������ ������ �������� �����
CChartObjectHLine topLevel; // ������� �������
CChartObjectHLine bottomLevel; // ������ �������

int fileTestStat; // ����� �����


int OnInit()
  {
   // �������� ���������� DrawExtremums
   handleDE = DoesIndicatorExist(_Symbol, _Period, "DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     handleDE = iCustom(_Symbol, _Period, "DrawExtremums");
     if (handleDE == INVALID_HANDLE)
      {
       Print("�� ������� ������� ����� ���������� DrawExtremums");
       return (INIT_FAILED);
      }
     SetIndicatorByHandle(_Symbol, _Period, handleDE);
    }  
    // ������� ����� ����� ������������ ���������� ����������� �������
    fileTestStat = FileOpen("FlatStat1/FlatStat_" + _Symbol+"_" + PeriodToString(_Period) + ".txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
    if (fileTestStat == INVALID_HANDLE) //�� ������� ������� ����
     {
      Print("�� ������� ������� ���� ������������ ���������� ����������� �������");
      return (INIT_FAILED);
     }           
   // ������� ������� �������
   container = new CExtrContainer(handleDE, _Symbol, _Period);
   trend = new CTrendChannel(0, _Symbol, _Period, handleDE, percent);
   timeStart = TimeCurrent();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   timeFinish = TimeCurrent();
   FileWriteString(fileTestStat,"������ ������������ � " + TimeToString(timeStart) + " �� " + TimeToString(timeFinish) + " \n");
   FileWriteString(fileTestStat,"����� ��������� ��������� - �������: \n");  
   
   FileWriteString(fileTestStat,"����� �����: \n");
   FileWriteString(fileTestStat,"���� �: " + " ����: " + IntegerToString(flat_a_up_tup) + " ���: "+IntegerToString(flat_a_up_tdown)+"\n");
   FileWriteString(fileTestStat,"���� b: " + " ����: " + IntegerToString(flat_b_up_tup) + " ���: "+IntegerToString(flat_b_up_tdown)+"\n");                                
   FileWriteString(fileTestStat,"���� c: " + " ����: " + IntegerToString(flat_c_up_tup) + " ���: "+IntegerToString(flat_c_up_tdown)+"\n");
   FileWriteString(fileTestStat,"���� d: " + " ����: " + IntegerToString(flat_d_up_tup) + " ���: "+IntegerToString(flat_d_up_tdown)+"\n");   
   FileWriteString(fileTestStat,"���� e: " + " ����: " + IntegerToString(flat_e_up_tup) + " ���: "+IntegerToString(flat_e_up_tdown)+"\n");   
   FileWriteString(fileTestStat,"���� f: " + " ����: " + IntegerToString(flat_f_up_tup) + " ���: "+IntegerToString(flat_f_up_tdown)+"\n");   
   FileWriteString(fileTestStat,"���� g: " + " ����: " + IntegerToString(flat_g_up_tup) + " ���: "+IntegerToString(flat_g_up_tdown)+"\n");   
   FileWriteString(fileTestStat,"����� ����: \n");
   FileWriteString(fileTestStat,"���� �: " + " ����: " + IntegerToString(flat_a_down_tup) + " ���: "+IntegerToString(flat_a_down_tdown)+"\n");
   FileWriteString(fileTestStat,"���� b: " + " ����: " + IntegerToString(flat_b_down_tup) + " ���: "+IntegerToString(flat_b_down_tdown)+"\n");                                
   FileWriteString(fileTestStat,"���� c: " + " ����: " + IntegerToString(flat_c_down_tup) + " ���: "+IntegerToString(flat_c_down_tdown)+"\n");
   FileWriteString(fileTestStat,"���� d: " + " ����: " + IntegerToString(flat_d_down_tup) + " ���: "+IntegerToString(flat_d_down_tdown)+"\n");   
   FileWriteString(fileTestStat,"���� e: " + " ����: " + IntegerToString(flat_e_down_tup) + " ���: "+IntegerToString(flat_e_down_tdown)+"\n");   
   FileWriteString(fileTestStat,"���� f: " + " ����: " + IntegerToString(flat_f_down_tup) + " ���: "+IntegerToString(flat_f_down_tdown)+"\n");
   FileWriteString(fileTestStat,"���� g: " + " ����: " + IntegerToString(flat_g_down_tup) + " ���: "+IntegerToString(flat_g_down_tdown)+"\n");
   
   FileWriteString(fileTestStat,"����� ��������� ��������� - ������: \n");  
   
   FileWriteString(fileTestStat,"����� �����: \n");
   FileWriteString(fileTestStat,"���� �: " + " ����: " + IntegerToString(flat_a_up_tup2) + " ���: "+IntegerToString(flat_a_up_tdown2)+"\n");
   FileWriteString(fileTestStat,"���� b: " + " ����: " + IntegerToString(flat_b_up_tup2) + " ���: "+IntegerToString(flat_b_up_tdown2)+"\n");                                
   FileWriteString(fileTestStat,"���� c: " + " ����: " + IntegerToString(flat_c_up_tup2) + " ���: "+IntegerToString(flat_c_up_tdown2)+"\n");
   FileWriteString(fileTestStat,"���� d: " + " ����: " + IntegerToString(flat_d_up_tup2) + " ���: "+IntegerToString(flat_d_up_tdown2)+"\n");   
   FileWriteString(fileTestStat,"���� e: " + " ����: " + IntegerToString(flat_e_up_tup2) + " ���: "+IntegerToString(flat_e_up_tdown2)+"\n");
   FileWriteString(fileTestStat,"���� f: " + " ����: " + IntegerToString(flat_f_up_tup2) + " ���: "+IntegerToString(flat_f_up_tdown2)+"\n");
   FileWriteString(fileTestStat,"���� g: " + " ����: " + IntegerToString(flat_g_up_tup2) + " ���: "+IntegerToString(flat_g_up_tdown2)+"\n");   
   FileWriteString(fileTestStat,"����� ����: \n");
   FileWriteString(fileTestStat,"���� �: " + " ����: " + IntegerToString(flat_a_down_tup2)+" ���: "+IntegerToString(flat_a_down_tdown2)+"\n");
   FileWriteString(fileTestStat,"���� b: " + " ����: " + IntegerToString(flat_b_down_tup2)+" ���: "+IntegerToString(flat_b_down_tdown2)+"\n");                                
   FileWriteString(fileTestStat,"���� c: " + " ����: " + IntegerToString(flat_c_down_tup2)+" ���: "+IntegerToString(flat_c_down_tdown2)+"\n");
   FileWriteString(fileTestStat,"���� d: " + " ����: " + IntegerToString(flat_d_down_tup2)+" ���: "+IntegerToString(flat_d_down_tdown2)+"\n");   
   FileWriteString(fileTestStat,"���� e: " + " ����: " + IntegerToString(flat_e_down_tup2)+" ���: "+IntegerToString(flat_e_down_tdown2)+"\n");
   FileWriteString(fileTestStat,"���� f: " + " ����: " + IntegerToString(flat_f_down_tup2)+" ���: "+IntegerToString(flat_f_down_tdown2)+"\n");
   FileWriteString(fileTestStat,"���� g: " + " ����: " + IntegerToString(flat_g_down_tup2)+" ���: "+IntegerToString(flat_g_down_tdown2)+"\n");    
    
   FileClose(fileTestStat); 
   
   // ������� �������
   delete trend; 
   delete container;

  }
  
  bool flag = true;

void OnTick()
  {
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
  
  /*Comment("����� = ",calcMode,
          "\n flatType = ", flatType,
          "\n ���� = ",SymbolInfoDouble(_Symbol,SYMBOL_BID),
          "\n ������� UP = ",top_point, 
          "\n ������� DOWN = ",bottom_point,
          "\n percent*H = ", percent*H,
          "\n extrUp0 = ", extrUp0,
          "\n extrUp1 = ", extrUp1,
          "\n extrDown0 = ", extrDown0,
          "\n extrDown1 = ", extrDown1
          );*/
    
 if (calcMode == 3)
    {

   
        
      /*Comment("���� = ",SymbolInfoDouble(_Symbol,SYMBOL_BID),
              "\n ������� = ",top_point );  
    */
    if (flag)
     {
      flag = false;
      Print("��������� ��������� ������");
     }
    
    
      if ( GreatOrEqualDoubles (SymbolInfoDouble(_Symbol,SYMBOL_BID),top_point) )
       {
        switch (flatType)
         {
          case 1: 
           if (trendType == 1) 
            {
             Print ("������� ������� ������� �� ����� � trendType = ", trendType);
             if (timeUp0 > timeDown0)
             {
              flat_a_up_tup ++;
             }
             else
              flat_a_up_tup2 ++;
              Print ("flat_a_up_tup = ", flat_a_up_tup, "flat_a_up_tup2 = ", flat_a_up_tup2);
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)
              flat_a_up_tdown ++;
             else
              flat_a_up_tdown2 ++;
            }
          break;
          case 2: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)
              flat_b_up_tup ++;
             else
              flat_b_up_tup2++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0) 
              flat_b_up_tdown ++;
             else
              flat_b_up_tdown2 ++;
            }
          break;
          case 3: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)          
              flat_c_up_tup ++;
             else
              flat_c_up_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)             
              flat_c_up_tdown ++;
             else
              flat_c_up_tdown2 ++;
            }
          break;
          case 4: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)             
              flat_d_up_tup ++;
             else
              flat_d_up_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0) 
              flat_d_up_tdown ++;
             else 
              flat_d_up_tdown2 ++;
            }
          break;
          case 5: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)             
              flat_e_up_tup ++;
             else
              flat_e_up_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)             
              flat_e_up_tdown ++;
             else
              flat_e_up_tdown2 ++;
            }
          break;
          case 6: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)
              flat_f_up_tup ++;
             else
              flat_f_up_tup2++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0) 
              flat_f_up_tdown ++;
             else
              flat_f_up_tdown2 ++;
            }
          break; 
          case 7: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)
              flat_g_up_tup ++;
             else
              flat_g_up_tup2++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0) 
              flat_g_up_tdown ++;
             else
              flat_g_up_tdown2 ++;
            }
          break;                                       
         }    
        calcMode = 0; // ����� ������������ � ������ ����� 
        //topLevel.Delete();           
        //bottomLevel.Delete();               
       }
      // ���� ���� �������� ������� ������
      if ( LessOrEqualDoubles (SymbolInfoDouble(_Symbol,SYMBOL_BID),bottom_point) )
       { 
        switch (flatType)
         {
          case 1: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)                
              flat_a_down_tup ++;
             else
              flat_a_down_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)                
              flat_a_down_tdown ++;
             else
              flat_a_down_tdown2 ++;
            }
          break;
          case 2: 
           if (trendType == 1)
            { 
             if (timeUp0 > timeDown0)                
              flat_b_down_tup ++;
             else
              flat_b_down_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)                
              flat_b_down_tdown ++;
             else
              flat_b_down_tdown2 ++;
            }
          break;
          case 3: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)    
              flat_c_down_tup ++;
             else
              flat_c_down_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)                
              flat_c_down_tdown ++;
             else
              flat_c_down_tdown2 ++;
            }
          break;
          case 4: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)                
              flat_d_down_tup ++;
             else
              flat_d_down_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)                
              flat_d_down_tdown ++;
             else
              flat_d_down_tdown2 ++;
            }
          break;
          case 5: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)                
              flat_e_down_tup ++;
             else
              flat_e_down_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)                
              flat_e_down_tdown ++;
             else
              flat_e_down_tdown2 ++;
            }
           break; 
           case 6: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)                
              flat_f_down_tup ++;
             else
              flat_f_down_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)                
              flat_f_down_tdown ++;
             else
              flat_f_down_tdown2 ++;
            }
           break;
           case 7: 
           if (trendType == 1) 
            {
             if (timeUp0 > timeDown0)                
              flat_g_down_tup ++;
             else
              flat_g_down_tup2 ++;
            }
           if (trendType == -1)
            {
             if (timeUp0 > timeDown0)                
              flat_g_down_tdown ++;
             else
              flat_g_down_tdown2 ++;
            }
           break;                                       
         } 
        calcMode = 0; // ����� ������������ � ������ �����
        //topLevel.Delete();           
        //bottomLevel.Delete();
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
   trend.UploadOnEvent(sparam,dparam,lparam);
   container.UploadOnEvent(sparam,dparam,lparam);
   
   // ���� ������ ����� "���� �� ���� ������"
   if (calcMode == 0)
    { 
     trendNow = trend.IsTrendNow();
     // ���� ������ ���� ����� 
     if (trendNow)
       {
        // ��������� � ����� ��������� �������� ��������
        calcMode = 1;
        trendType = trend.GetTrendByIndex(0).GetDirection();
       }
    }
   // ���� ������ ����� "����� �����, ����� ������ ��������� ����"
   else if (calcMode == 1)
    {
     trendNow = trend.IsTrendNow();
     // ���� ������ �� �����
     if (!trendNow)
      {
       // �� ������ ������ ���� � �� ��������� � ����� ��������� ����������
       calcMode = 2;
      }
    }
   // ���� ������ ����� "������������ ����"
   else if (calcMode == 2)
    {
     // ��������� ��������� ����������
     
     extrUp0 = container.GetFormedExtrByIndex(0,EXTR_HIGH).price;
     extrUp1 = container.GetFormedExtrByIndex(1,EXTR_HIGH).price;
     timeUp0 = container.GetFormedExtrByIndex(0,EXTR_HIGH).time;
     timeUp1 = container.GetFormedExtrByIndex(1,EXTR_HIGH).time;
     extrDown0 = container.GetFormedExtrByIndex(0,EXTR_LOW).price;
     extrDown1 = container.GetFormedExtrByIndex(1,EXTR_LOW).price;
     timeDown0 = container.GetFormedExtrByIndex(0,EXTR_LOW).time;
     timeDown1 = container.GetFormedExtrByIndex(1,EXTR_LOW).time;
     /*
     Comment ("extr0 = ",DoubleToString(extrUp0),
              "\nextrUp1 = ",DoubleToString(extrUp1) 
             );
     */
     
     H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
     top_point = extrUp0 + H*0.75;
     bottom_point = extrDown0 - H*0.75;     
     flatType = 0;
     // ��������� ��� �����
     if (IsFlatA())
      flatType = 1;
     if (IsFlatB())
      flatType = 2;
     if (IsFlatC())
      flatType = 3;
     if (IsFlatD())
      flatType = 4;
     if (IsFlatE())
      flatType = 5;
     if (IsFlatF())
      flatType = 6;
     if (IsFlatG())
      flatType = 7;
     // ���� ������� ��������� ����
     if (flatType != 0)
      {
       // ��������� � ����� �������� ����������
       calcMode = 3;
       CreateFlatLine(); // ������������ ����
      } 
     else
      {
       
      }
     tempTrendType = 0;                      
    }
    
    
    else if (calcMode == 3)
     {
     // tempLastExtrTime = container.GetFormedExtrByIndex(0, EXTR_BOTH).time;
      trendNow = trend.IsTrendNow();
      if (trendNow)
       {
        tempTrendType = trend.GetTrendByIndex(0).GetDirection();
       }
      else // ������ ����
       {
        if (tempTrendType != 0) // ����� ����
         {
          trendType = tempTrendType;   
          //Print("����� ����", countFlat);
         }
        calcMode = 2;   // ��������� � ����� �������� �������
       }
     }
  }   
  
// ������� ��������� ����� ������

bool IsFlatA ()
 {
  //  ���� 
  if ( LessOrEqualDoubles (MathAbs(extrUp1-extrUp0), percent*H) &&
       GreatOrEqualDoubles (extrDown0 - extrDown1, percent*H)
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
  if ( LessOrEqualDoubles (MathAbs(extrUp1-extrUp0), percent*H) &&
       LessOrEqualDoubles (MathAbs(extrDown0 - extrDown1), percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatD ()
 {
  //  ���� 
  if ( GreatOrEqualDoubles (MathAbs(extrUp1-extrUp0), percent*H) &&
       GreatOrEqualDoubles (MathAbs(extrDown0 - extrDown1), percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatE ()
 {
  //  ���� 
  if ( GreatOrEqualDoubles (extrUp0-extrUp1, percent*H) &&
       GreatOrEqualDoubles (extrDown1 - extrDown0, percent*H)
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
 // �������������� �������
 void CreateFlatLine ()  // ������� ����� �����
  {
   
   flatLine.Create(0, "flatUp_" + countDrawedFlat, 0, timeUp0, extrUp0, timeUp1, extrUp1); // ������� �����  
   flatLine.Color(clrYellow);
   flatLine.Width(1);
   flatLine.Create(0,"flatDown_" + countDrawedFlat, 0, timeDown0, extrDown0, timeDown1, extrDown1); // ������ �����
   flatLine.Color(clrYellow);
   flatLine.Width(1);
   countDrawedFlat ++;   
   
   topLevel.Delete();
   topLevel.Create(0, "topLevel", 0, top_point);
   bottomLevel.Delete();
   bottomLevel.Create(0, "bottomLevel", 0, bottom_point);   
  }