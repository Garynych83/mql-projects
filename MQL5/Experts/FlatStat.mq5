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
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <CTrendChannel.mqh> // ��������� ���������
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����
// ���������
input double percent = 0.1; // �������
// ������� ����������
bool trendNow = false;
bool firstUploaded = false; // ���� �������� ������� �������
int  calcMode = 0;  // ����� ����������
int  flatType = 0;
int  trendType = 0;
// ������
int handleDE;
// �������� ��������
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


// ���������� ��� �������� ���� � ������
double extrUp0,extrUp1;
double extrDown0,extrDown1;
double H; // ������ �����
double top_point; // ������� �����, ������� ����� �������
double bottom_point; // ������ �����, ������� ����� �������
// ������� �������
CExtrContainer *container;
CTrendChannel *trend;

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
   // ������� ������� �������
   container = new CExtrContainer(handleDE,_Symbol,_Period);
   trend = new CTrendChannel(0,_Symbol,_Period,handleDE,percent);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // ������� �������
   delete trend;
   delete container;
  }

void OnTick()
  {
   if (!firstUploaded)
    {
     firstUploaded = container.Upload();
    }
   if (!firstUploaded)
    return;
   
  }
  
// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
  {
   int newDirection;
   trend.UploadOnEvent(sparam,dparam,lparam);
   container.UploadOnEvent(sparam,dparam,lparam);
   // ���� ������ ����� "���� �� ���� ������"
   if (calcMode == 0)
    { 
     trendNow = trend.IsTrendNow();
     // ���� ������ ���� ����� 
     if (trendNow )
       {
        // ��������� � ����� ��������� �������� ��������
        calcMode = 1;
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
     extrUp0 = container.GetExtrByIndex(0,EXTR_HIGH).price;
     extrUp1 = container.GetExtrByIndex(1,EXTR_HIGH).price;
     extrDown0 = container.GetExtrByIndex(0,EXTR_LOW).price;
     extrDown1 = container.GetExtrByIndex(1,EXTR_LOW).price;
     H = MathMax(extrUp0,extrUp1) - MathMin(extrDown0,extrDown1);
     top_point = SymbolInfoDouble(_Symbol,SYMBOL_BID) + H*0.75;
     bottom_point = SymbolInfoDouble(_Symbol,SYMBOL_BID) - H*0.75;     
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
     // ���� ������� ��������� ����
     if (flatType != 0)
      {
       // ��������� � ����� �������� ����������
       calcMode = 3;
      }                       
    }
   else if (calcMode == 3)
    {
      // ���� ���� �������� �������� ������
      if ( GreatOrEqualDoubles (SymbolInfoDouble(_Symbol,SYMBOL_BID),top_point) )
       {
        switch (flatType)
         {
          case 1: 
           if (trendType == 1) 
            flat_a_up_tup ++;
           if (trendType == -1)
            flat_a_up_tdown ++;
          break;
          case 2: 
           if (trendType == 1) 
            flat_b_up_tup ++;
           if (trendType == -1)
            flat_b_up_tdown ++;
          break;
          case 3: 
           if (trendType == 1) 
            flat_c_up_tup ++;
           if (trendType == -1)
            flat_c_up_tdown ++;
          break;
          case 4: 
           if (trendType == 1) 
            flat_d_up_tup ++;
           if (trendType == -1)
            flat_d_up_tdown ++;
          break;
          case 5: 
           if (trendType == 1) 
            flat_e_up_tup ++;
           if (trendType == -1)
            flat_e_up_tdown ++;
          break;                                        
         }    
        calcMode = 0; // ����� ������������ � ������ �����  
       }
      // ���� ���� �������� ������� ������
      if ( LessOrEqualDoubles (SymbolInfoDouble(_Symbol,SYMBOL_BID),bottom_point) )
       {
        switch (flatType)
         {
          case 1: 
           if (trendType == 1) 
            flat_a_down_tup ++;
           if (trendType == -1)
            flat_a_down_tdown ++;
          break;
          case 2: 
           if (trendType == 1) 
            flat_b_down_tup ++;
           if (trendType == -1)
            flat_b_down_tdown ++;
          break;
          case 3: 
           if (trendType == 1) 
            flat_c_down_tup ++;
           if (trendType == -1)
            flat_c_down_tdown ++;
          break;
          case 4: 
           if (trendType == 1) 
            flat_d_down_tup ++;
           if (trendType == -1)
            flat_d_down_tdown ++;
          break;
          case 5: 
           if (trendType == 1) 
            flat_e_down_tup ++;
           if (trendType == -1)
            flat_e_down_tdown ++;
          break;                                        
         }      
        calcMode = 0; // ����� ������������ � ������ �����           
       }       
    }
  }   
  
// ������� ��������� ����� ������


bool IsFlatA ()
 {
  //  ���� 
  if ( LessDoubles (MathAbs(extrUp1-extrUp0),percent*H) &&
       GreatDoubles (extrDown0 - extrDown1,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatB ()
 {
  //  ���� 
  if ( GreatDoubles (extrUp1-extrUp0,percent*H) &&
       LessDoubles (MathAbs(extrDown0 - extrDown1),percent*H)
     )
    {
     return (true);
    }
  return (false);
 }

bool IsFlatC ()
 {
  //  ���� 
  if ( LessDoubles (MathAbs(extrUp1-extrUp0),percent*H) &&
       LessDoubles (MathAbs(extrDown0 - extrDown1),percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatD ()
 {
  //  ���� 
  if ( GreatDoubles (extrUp1-extrUp0,percent*H) &&
       GreatDoubles (extrDown0 - extrDown1,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
bool IsFlatE ()
 {
  //  ���� 
  if ( GreatDoubles (extrUp0-extrUp1,percent*H) &&
       GreatDoubles (extrDown1 - extrDown0,percent*H)
     )
    {
     return (true);
    }
  return (false);
 }    