//+------------------------------------------------------------------+
//|                                        TesterOfMoveContainer.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// ������� �������� ���������� �� ������ ���� �

#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <DrawExtremums/CExtremum.mqh> // ������ �����������
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������

input double percent = 0.1;


CExtrContainer *extr_container;
bool firstUploadedExtr = false;
int handleDE;
string cameHighEvent;  // ��� ������� ������� �������� ����������
string cameLowEvent;   // ��� ������� ������� ������� ����������
// ���������� ������
double h; // ������ ������ �����
double bottom_price; // ���� ������ ������� ������
double top_price; // ���� ������� ������� ������
double second_bottom_price; // ���� �������������� ������ ������� ������
double second_top_price; // ���� �������������� ������� ������� ������
// ���������� ��������
CExtremum trend_high0,trend_high1; 
CExtremum trend_low0,trend_low1;

CExtremum flat_high0,flat_high1;
CExtremum flat_low0,flat_low1;

// ������� ����������� ������ ������
CChartObjectTrend flatLine;    // ������ ������ �������� �����
CChartObjectTrend trendLine;   // ������ ������ ��������� �����
CChartObjectHLine topLevel;    // ������� �������
CChartObjectHLine bottomLevel; // ������ �������

// ��������� ��� �������� ����������

// ����� �����, ��������� �����
int countTotal0 = 0;
int countUp0 = 0;
int countDown0 = 0;
int countSecondUp0 = 0;
int countSecondDown0 = 0;
// ����� �����, ��������� ����
int countTotal1 = 0;
int countUp1 = 0;
int countDown1 = 0;
int countSecondUp1 = 0;
int countSecondDown1 = 0;
// ����� ����, ��������� �����
int countTotal2 = 0;
int countUp2 = 0;
int countDown2 = 0;
int countSecondUp2 = 0;
int countSecondDown2 = 0;
// ����� ����, ��������� ����
int countTotal3 = 0;
int countUp3 = 0;
int countDown3 = 0;
int countSecondUp3 = 0;
int countSecondDown3 = 0;

int mode = 0;  // 0 - ����� ������ ��������, 1 - ����� �������� ��������
int type; // ��� �������� 
int trend;
int extr;

// ���������� ��� �����
int fileHandle; // ����� �����

// ��������� ��� �������� ������� ��������
struct SubLineStruct
 {
  int type; // ��� �����, � �������� ����� �������� ������
  double top_price; // ������� ���� ������
  double bottom_price; // ������ ���� ������
  int crossed; // ���� �������� (0 - ��� �� �������, 1 - ������� ������, -1 - ������� �����)
 };

// ������ ������� �������, ������� ����� �������
SubLineStruct subLines[]; // ������������ ������ �������� ������� ��� ��������
int subLineSize=0; // ���������� ������� 
// ������� �� ������ � �������� 

// ��������� ����� ������ ��� ����� ��������
void SetNewSubLine (int Type,double topPrice,double bottomPrice)
 { 
  subLineSize ++;
  ArrayResize(subLines,subLineSize);
  subLines[subLineSize-1].bottom_price = bottomPrice;
  subLines[subLineSize-1].top_price = topPrice;
  subLines[subLineSize-1].type = Type;
  subLines[subLineSize-1].crossed = 0;      
 }

// ������� ���������, �� ������ �� �������, � ���� ��� - ������ ���� crossed
void CheckCrossedLevels ()
 {
  double curAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK); // ������� ���
  double curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID); // ������� ���
  for (int index=0;index<subLineSize;index++)
   {
    // ���� ���� ������� ��������� � �������� �� ��������
    if (subLines[index].crossed == 0)
     {
      // ���� ������� ������ ������
      if (GreatOrEqualDoubles(curBid,subLines[index].top_price))
       subLines[index].crossed = 1;
      // ���� ������� ������ �����
      if (LessOrEqualDoubles(curAsk,subLines[index].bottom_price))
       subLines[index].crossed = -1;       
     }
   }
 }

// ������������ ���������� �� �������������� ��������
void CountStatToSecondLevels ()
 {
  // �������� �� ���� �������
  for (int index=0;index<subLineSize;index++)
   {
    switch (subLines[index].type)
     {
      case 0: // ����� �����, ��������� �����
       // ���� �������  ��������� ������
       if (subLines[index].crossed == 1)
        countSecondUp0++;
       // ���� �������  ��������� �����
       if (subLines[index].crossed == -1)
        countSecondDown0++;        
      break; 
      case 1: // ����� �����, ��������� ����
       // ���� �������  ��������� ������
       if (subLines[index].crossed == 1)
        countSecondUp1++;
       // ���� �������  ��������� �����
       if (subLines[index].crossed == -1)
        countSecondDown1++;        
      break; 
      case 2: // ����� ����, ��������� �����
       // ���� �������  ��������� ������
       if (subLines[index].crossed == 1)
        countSecondUp2++;
       // ���� �������  ��������� �����
       if (subLines[index].crossed == -1)
        countSecondDown2++;        
      break; 
      case 3: // ����� ����, ��������� ����
       // ���� �������  ��������� ������
       if (subLines[index].crossed == 1)
        countSecondUp3++;
       // ���� �������  ��������� �����
       if (subLines[index].crossed == -1)
        countSecondDown3++;        
      break;                   
     }
   }
 }

int OnInit()
  {
   
   // ������� ����� ����� ������������ ���������� ����������� �������
   fileHandle = FileOpen("FLAT_STAT_SECOND/FLAT_G_" + _Symbol+"_" + PeriodToString(_Period) + ".txt", FILE_WRITE|FILE_COMMON|FILE_ANSI|FILE_TXT, "");
   if (fileHandle == INVALID_HANDLE) //�� ������� ������� ����
    {
     Print("�� ������� ������� ���� ������������ ���������� ����������� �������");
     return (INIT_FAILED);
    }   
   // ��������� ����� �������
   cameHighEvent = GenUniqEventName("EXTR_UP_FORMED");
   cameLowEvent  = GenUniqEventName("EXTR_DOWN_FORMED");
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
   extr_container = new CExtrContainer(handleDE,_Symbol,_Period);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   delete extr_container;
   CountStatToSecondLevels ();
   SaveStatToFile ();
   FileClose(fileHandle);
  }

void OnTick()
  {
    int crossed;
    if (!firstUploadedExtr)
    {
     firstUploadedExtr = extr_container.isUploaded();
    }    
   if (!firstUploadedExtr)
    return;    
   // ��������� �������� ��� �������� ������
   CheckCrossedLevels (); 
   // ���� ������ ����� �������� ������ ������ 
   if (mode == 1)
    {
     crossed = CrossChannel();
     // ���� ������� ������� �������
     if (crossed == 1)
      {
       // ������������ 
       CountStatForSituation (1);
       // ��������� � ����� ������ ����� ��������
       mode = 0;
       // � ������� �����
       DeleteAllLines ();
       
       Comment("���������� ������� �����",
               "\n trend = ",trend,
               "\n��������� = ",extr,
               "\n countTotal0 = ",countTotal0,
               "\n countUp0 = ",countUp0,
               "\n countDown0 = ",countDown0,
               "\n countTotal1 = ",countTotal1,
               "\n countUp1 = ",countUp1,
               "\n countDown1 = ",countDown1,
               "\n countTotal2 = ",countTotal2,
               "\n countUp2 = ",countUp2,
               "\n countDown2 = ",countDown2,
               "\n countTotal3 = ",countTotal3,
               "\n countUp3 = ",countUp3,
               "\n countDown3 = ",countDown3                                             
               );
       
      }
     // ���� ������� ������ �������
     if (crossed == -1)
      {
       // ������������
       CountStatForSituation (-1);
       // ��������� � ����� ������ ����� ��������
       mode = 0;
       // � ������� �����
       DeleteAllLines ();
       
       Comment("���������� ������ �����",
               "\n trend = ",trend,
               "\n��������� = ",extr,
               "\n countTotal0 = ",countTotal0,
               "\n countUp0 = ",countUp0,
               "\n countDown0 = ",countDown0,
               "\n countTotal1 = ",countTotal1,
               "\n countUp1 = ",countUp1,
               "\n countDown1 = ",countDown1,
               "\n countTotal2 = ",countTotal2,
               "\n countUp2 = ",countUp2,
               "\n countDown2 = ",countDown2,
               "\n countTotal3 = ",countTotal3,
               "\n countUp3 = ",countUp3,
               "\n countDown3 = ",countDown3                                             
               );       
       
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

    // ��������� ��������� �����������
    extr_container.UploadOnEvent(sparam,dparam,lparam);
    // ���� ������ �������, ��� ������������� ������� ���������
    if (sparam == cameHighEvent)
     {
      // ���� ������ ����� 0, �� ���� ����
      if (mode == 0)
       {
        extr = 1;
        // ���� ������ ���� 
        if ( IsFlatG(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                     extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                    {
                     // ���������, ��� ���������� �������� �� �������� �������
                     if (!IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                         extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                         {
                          // ���������, ��� ���� ����������� �������� - �����
                          if (trend = IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                                         {
                                           // ��������� ��������� ������
                                           CountFlatChannel();
                                           // ������������ ��������
                                           DrawChannel ();      
                                           // ��������� � ����� 1 (�������� ������ ������ ��� ������ ������ ������) 
                                           mode = 1;   

                                           // ���������� ��� ��������
                                           if (trend == 1)
                                            {
                                             countTotal0++;
                                             type = 0;
                                             // ��������� ����� �������������� ������
                                             SetNewSubLine (0,second_top_price,second_bottom_price); 
                                            }
                                           if (trend == -1)
                                            {
                                             countTotal2++;
                                             type = 2;
                                             // ��������� ����� �������������� ������
                                             SetNewSubLine (2,second_top_price,second_bottom_price);                                              
                                            }   
                                         }
                         }
                    }
                    
       } // END OF MODE
     } // END OF SPARAM
    // ���� ������ �������, ��� ������������� ������ ���������
    if (sparam == cameLowEvent)
     {
      // ���� ������ ����� 0, �� ���� ����
      if (mode == 0)
       {
        extr = -1;
        // ���� ������ ���� 
        if ( IsFlatG(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                     extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                    {
                     // ���������, ��� ���������� �������� �� �������� �������
                     if (!IsItTrend(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                         {
                          // ���������, ��� ���� ����������� �������� - �����
                          if (trend = IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                                         {
                                           // ��������� ��������� ������
                                           CountFlatChannel();
                                           // ������������ ��������
                                           DrawChannel ();      
                                           // ��������� � ����� 1 (�������� ������ ������ ��� ������ ������ ������) 
                                           mode = 1;   
                                           
                                           // ���������� ��� ��������
                                           if (trend == 1)
                                            {
                                             countTotal1++;
                                             type = 1;
                                             // ��������� ����� �������������� ������
                                             SetNewSubLine (1,second_top_price,second_bottom_price);                                              
                                            }
                                           if (trend == -1)
                                            {
                                             countTotal3++;
                                             type = 3;
                                             // ��������� ����� �������������� ������
                                             SetNewSubLine (3,second_top_price,second_bottom_price);                                              
                                            }   
                                         }
                         }
                    }
                    
       } // END OF MODE
     } // END OF SPARAM     
  }
  
 // ������� ��������� ��������� ������ �����
 void CountFlatChannel ()
  {
   h = MathMax(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price,extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price) -
       MathMin(extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price,extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price);
   top_price = extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price + 0.75*h;
   bottom_price = extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price - 0.75*h;
   second_top_price = extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price + 3*h;
   second_bottom_price = extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price - 3*h;   
  } 
  
  
 // �������������� �������
 void  DrawChannel ()  // ������� ����� �����
  {
   DeleteAllLines ();
   flatLine.Create(0, "flatUp", 0, extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price, 
                                   extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price); // ������� �����  
   
   flatLine.Color(clrYellow);
   flatLine.Width(2);
   flatLine.Create(0, "flatDown", 0, extr_container.GetFormedExtrByIndex(0,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price, 
                                     extr_container.GetFormedExtrByIndex(1,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price); // ������ �����  
   flatLine.Color(clrYellow);
   flatLine.Width(2);
   
   
   trendLine.Create(0, "trendUp", 0, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price, 
                                   extr_container.GetFormedExtrByIndex(2,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(2,EXTR_HIGH).price); // ������� �����  
   
   trendLine.Color(clrLightBlue);
   trendLine.Width(2);
   trendLine.Create(0, "trendDown", 0, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price, 
                                     extr_container.GetFormedExtrByIndex(2,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(2,EXTR_LOW).price); // ������ �����  
   trendLine.Color(clrLightBlue);
   trendLine.Width(2);   
   
   topLevel.Create(0, "topLevel", 0, top_price);
   bottomLevel.Create(0, "bottomLevel", 0, bottom_price);   
  }
  
 // ������� ������� ����� � �������
 void DeleteAllLines ()
  {
   ObjectDelete(0,"flatUp");
   ObjectDelete(0,"flatDown");
   ObjectDelete(0,"trendUp");
   ObjectDelete(0,"trendDown");
   topLevel.Delete();
   bottomLevel.Delete();   
  }
  
 
int IsFlatG (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // ���� G
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
  if ( GreatOrEqualDoubles (high0.price - high1.price, percent*height) &&
       LessOrEqualDoubles (MathAbs(low0.price - low1.price), percent*height)
     )
    {
     return (true);
    }
  return (false);
 }  
 

int IsItTrend(CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // ���������, �������� �� ������ ����� ���������
 {
  double h1,h2;
  double H1,H2;
  // ���� ����� ����� 
  if ( GreatDoubles(high0.price,high1.price) && GreatDoubles(low0.price,low1.price))
   {
    // ���� ��������� ��������� - ����
    if (low0.time > high0.time)
     {
      H1 = high0.price - low1.price;
      H2 = high1.price - low1.price;
      h1 = MathAbs(low0.price - low1.price);
      h2 = MathAbs(high0.price - high1.price);
      // ���� ���� ��������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (1);
     }
    // ���� ��������� ��������� - �����
    if (low0.time < high0.time)
     {
      H1 = high1.price - low0.price;
      H2 = high1.price - low1.price;
      h1 = MathAbs(low0.price - low1.price);
      h2 = MathAbs(high0.price - high1.price);
      // ���� ���� ��������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (1);
     }
      
   }
  // ���� ����� ����
  if ( LessDoubles(high0.price,high1.price) && LessDoubles(low0.price,low1.price))
   {
    
    // ����  ��������� ��������� - �����
    if (high0.time > low0.time)
     {
      H1 = high1.price - low0.price;    
      H2 = high1.price - low1.price;
      h1 = MathAbs(high0.price - high1.price);
      h2 = MathAbs(low0.price - low1.price);
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )    
       return (-1);
     }
    // ���� ��������� ��������� - ����
    else if (high0.time < low0.time)
     {
      H1 = high0.price - low1.price;    
      H2 = high1.price - low1.price;
      h1 = MathAbs(high0.price - high1.price);
      h2 = MathAbs(low0.price - low1.price);
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h2,H1*percent) && GreatDoubles(h1,H2*percent) )    
       return (-1);
     }
     
   }   
   
  return (0);
 } 
 

// ���������� ��� ������� 
string  GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 }
 
// ������� �������� ������ ������
int CrossChannel ()
 {
  // ���� ���� ��������� ������� ������� ������
  if (GreatOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_BID),top_price))
   {
    return (1);
   }
  // ���� ���� ��������� ������ ������� ������
  if (LessOrEqualDoubles(SymbolInfoDouble(_Symbol,SYMBOL_ASK),bottom_price))
   {
    return (-1);
   }
  return (0);
 } 

// ������������ ��������� ��������
void CountStatForSituation (int crossType)
 {
  switch (type)
   {
    case 0: // ����� �����, ��������� �������
     // ���� ��������� ������� �����
     if (crossType == 1)
      {
       countUp0++;
      }
     // ���� ��������� ������ �����\
     if (crossType == -1)
      {
       countDown0++;
      }
    break;
    case 1: // ����� �����, ��������� ������
     // ���� ��������� ������� �����
     if (crossType == 1)
      {
       countUp1++;
      }
     // ���� ��������� ������ �����\
     if (crossType == -1)
      {
       countDown1++;
      }
    break;
    case 2: // ����� �����, ��������� �������
     // ���� ��������� ������� �����
     if (crossType == 1)
      {
       countUp2++;
      }
     // ���� ��������� ������ �����\
     if (crossType == -1)
      {
       countDown2++;
      }
    break;
    case 3: // ����� �����, ��������� �������
     // ���� ��������� ������� �����
     if (crossType == 1)
      {
       countUp3++;
      }
     // ���� ��������� ������ �����\
     if (crossType == -1)
      {
       countDown3++;
      }
    break;            
   }
 }
 
// ��������� ���������� � ����
void SaveStatToFile ()
 { 
  FileWriteString(fileHandle,"���������� �� ����� ���� G: " + _Symbol + "\n");
  FileWriteString(fileHandle," {\n");
  FileWriteString(fileHandle,"  ��� ������ �����, ��������� ��������� - �������: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     ���������� �����: "+IntegerToString(countTotal0)+"\n");
  FileWriteString(fileHandle,"     ���������� �������� �����: "+IntegerToString(countUp0)+"\n");   
  FileWriteString(fileHandle,"     ���������� �������� ����: "+IntegerToString(countDown0)+"\n");
  FileWriteString(fileHandle,"     ���������� �������� ����� 3H: "+IntegerToString(countSecondUp0)+"\n");   
  FileWriteString(fileHandle,"     ���������� �������� ���� 3H: "+IntegerToString(countSecondDown0)+"\n");  
  FileWriteString(fileHandle,"   }\n");
  FileWriteString(fileHandle,"  ��� ������ �����, ��������� ��������� - ������: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     ���������� �����: "+IntegerToString(countTotal1)+"\n");
  FileWriteString(fileHandle,"     ���������� �������� �����: "+IntegerToString(countUp1)+"\n");   
  FileWriteString(fileHandle,"     ���������� �������� ����: "+IntegerToString(countDown1)+"\n");
  FileWriteString(fileHandle,"     ���������� �������� ����� 3H: "+IntegerToString(countSecondUp1)+"\n");   
  FileWriteString(fileHandle,"     ���������� �������� ���� 3H: "+IntegerToString(countSecondDown1)+"\n");  
  FileWriteString(fileHandle,"   }\n");        
  FileWriteString(fileHandle,"  ��� ������ ����, ��������� ��������� - �������: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     ���������� �����: "+IntegerToString(countTotal2)+"\n");
  FileWriteString(fileHandle,"     ���������� �������� �����: "+IntegerToString(countUp2)+"\n");   
  FileWriteString(fileHandle,"     ���������� �������� ����: "+IntegerToString(countDown2)+"\n");
  FileWriteString(fileHandle,"     ���������� �������� ����� 3H: "+IntegerToString(countSecondUp2)+"\n");   
  FileWriteString(fileHandle,"     ���������� �������� ���� 3H: "+IntegerToString(countSecondDown2)+"\n");  
  FileWriteString(fileHandle,"   }\n");  
  FileWriteString(fileHandle,"  ��� ������ ����, ��������� ��������� - ������: \n");
  FileWriteString(fileHandle,"   {\n");
  FileWriteString(fileHandle,"     ���������� �����: "+IntegerToString(countTotal3)+"\n");
  FileWriteString(fileHandle,"     ���������� �������� �����: "+IntegerToString(countUp3)+"\n");   
  FileWriteString(fileHandle,"     ���������� �������� ����: "+IntegerToString(countDown3)+"\n");
  FileWriteString(fileHandle,"     ���������� �������� ����� 3H: "+IntegerToString(countSecondUp3)+"\n");   
  FileWriteString(fileHandle,"     ���������� �������� ���� 3H: "+IntegerToString(countSecondDown3)+"\n");  
  FileWriteString(fileHandle,"   }\n");        
  FileWriteString(fileHandle," }\n");   
 } 