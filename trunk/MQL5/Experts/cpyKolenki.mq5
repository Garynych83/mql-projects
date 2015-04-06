//+------------------------------------------------------------------+
//|                                               StatisticRobot.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// ���� ���������� �������� �����

#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����
#include <TradeManager/TradeManager.mqh>    // �������� ����������

input double percent = 0.1; // ������� 
input double lot = 1.0; // ���
input bool use = true; // �������
input bool half_stop = true;
input int n = 2; 


// ��������� ����� ��� ���������� �����
struct pointLine
 {
  int direction;
  int bar;
  double price;
  datetime time;
 };
 
CTradeManager *ctm; 

int  handleDE;
bool switchTrend = false; // ���������� �������� ��������� �����
bool switchHor = false; // ���������� �������� �������������� �����
bool printed = false;
bool validTrend = false;
// �������� 
int countTotal = 0; // ����� �����������
int NoTrendNoHor = 0; 
int YesTrendNoHor = 0;
int NoTrendYesHor = 0;
int YesTrendYesHor = 0;
int trend = 0; // ������� �����
double curBid; // ������� ���� bid
double prevBid; // ���������� ���� bid
double priceTrend;
double horPrice;
pointLine extr[4]; // ����� ��� ����������� �����
CChartObjectTrend  trendLine; // ������ ������ ��������� �����
CChartObjectHLine  horLine; // ������ ������ �������������� �����

// ��������� ������� � ���������
SPositionInfo pos_info;      // ��������� ���������� � �������
STrailing     trailing;      // ��������� ���������� � ���������

int OnInit()
 {
  ctm = new CTradeManager(); 
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
  // ���� ������� ���������� ��������� ����������
  if (UploadExtremums())
  {
   trend = IsTrendNow();
   // ��������� ���������� ������
   validTrend = IsValidState (trend);
   if (validTrend)
   {
    // ������ ����� 
    DrawLines ();    
   }
  }
  countTotal = 0;
   // ��������� ����  
  curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  prevBid = curBid;
   // ��������� ���� �������
  pos_info.volume = lot;
  pos_info.expiration = 0;
   // ��������� 
  trailing.trailingType = TRAILING_TYPE_NONE;
  trailing.handleForTrailing = 0;     
  return(INIT_SUCCEEDED);
 }

void OnDeinit(const int reason)
  {
   delete ctm;
   IndicatorRelease(handleDE);
  }
  
  
void OnTick()
  {     
   ctm.OnTick();
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);    
     // ���� �������� �������
     if (validTrend)
      {
       if (trend == 1)
        priceTrend = ObjectGetValueByTime(0,"trendUp",TimeCurrent());
       if (trend == -1)
        priceTrend = ObjectGetValueByTime(0,"trendDown",TimeCurrent());          
       
       // ���� ����� ����
       if (trend == -1)
        {
         // ���� ���� ������� ������������ �����
         if (LessDoubles(curBid,priceTrend))
            {
             switchTrend = true; // �� ����������� ���������� ��������
            }
         // ���� ���� ������� �������������� �����
         if (LessDoubles(curBid,horPrice))
            {
             switchHor = true;
            }
         }
       // ���� ����� �����
       if (trend == 1)
        {
         // ���� ���� ������� ������������ �����
         if (GreatDoubles(curBid,priceTrend))
            {
             switchTrend = true; // �� ����������� ���������� ��������
            }
         // ���� ���� ������� �������������� �����
         if (GreatDoubles(curBid,horPrice))
            {
             switchHor = true;
            }  
        }
      } 
    
    prevBid = curBid;
  }

// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
  {
   double price;
   if (sparam == "EXTR_DOWN_FORMED")
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
     pos_info.type = OP_BUY; 
    }
   if (sparam == "EXTR_UP_FORMED")
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     pos_info.type = OP_SELL;
    }
   // ������ ������� "������������� ����� ���������"
   if (sparam == "EXTR_DOWN_FORMED" || sparam == "EXTR_UP_FORMED")
    {
     // ������� ����� � �������
     DeleteLines();
     // ���� �������� ���� �������
     if (validTrend)
      {
       // ������������ ��������
       if (switchHor == false && switchTrend == false)
        NoTrendNoHor ++;
       if (switchHor == false && switchTrend == true)
        YesTrendNoHor ++;
       if (switchHor == true && switchTrend == false)
        NoTrendYesHor ++;
       if (switchHor == true && switchTrend == true)
        YesTrendYesHor ++;
       countTotal ++;
      }
     // ���������� �������� �������
     switchHor = false;
     switchTrend = false;
     // �������� ����� �������� ����������� � �������
     UploadExtremums ();
    // DragExtremums(direction,dparam,datetime(lparam));
     trend = IsTrendNow();
     // ��������� ���������� ������
     validTrend = IsValidState (trend);
     if (validTrend)
      {
       if (half_stop)
        pos_info.sl = int(MathAbs((price-extr[0].price)/2)/_Point);
       else
       pos_info.sl = int(MathAbs(price-extr[0].price)/_Point);
       pos_info.tp = int(MathAbs(price-extr[1].price)/_Point);
       if (use)
        {
         if (pos_info.tp > pos_info.sl*n)
         ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
        }
       else
        {
          ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);        
        }
        
       // �������������� �����
       DrawLines ();
      }
    }

  } 

// ������� �������� ����������� �� OnInit
bool UploadExtremums ()
 {
  double extrHigh[];
  double extrLow[];
  double extrHighTime[];
  double extrLowTime[];
  int count=0; // ������� �����������
  int bars = Bars(_Symbol,_Period);
  for (int ind=0;ind<bars;)
   {
    if (CopyBuffer(handleDE,0,ind,1,extrHigh) < 1 || CopyBuffer(handleDE,1,ind,1,extrLow) < 1 ||
        CopyBuffer(handleDE,4,ind,1,extrHighTime) < 1 || CopyBuffer(handleDE,5,ind,1,extrLowTime) < 1 )
       {
        Sleep(100);
        continue;
       }
    // ���� ������ ����� ��������� high
    if (extrHigh[0] != 0)
     {
      extr[count].price = extrHigh[0];
      extr[count].time = datetime(extrHighTime[0]);
      extr[count].direction = 1;
      extr[count].bar = ind;
      count++;
     }
    // ���� ������� ��� 3 ����������
    if (count == 4)
     return (true);     
    // ���� ������ ����� ��������� low
    if (extrLow[0] != 0)
     {
      extr[count].price = extrLow[0];
      extr[count].time = datetime(extrLowTime[0]);
      extr[count].direction = -1;
      extr[count].bar = ind;
      count++;
     }     
    // ���� ������� ��� 4 ����������
    if (count == 4)
     return (true);
    ind++;
   }
  return(false);
 }
 
// ������� ������� ���������� � �������
void DragExtremums (int direction,double price,datetime time)
 {
  for (int ind=3;ind>0;ind--)
   {
    extr[ind] = extr[ind-1];
   }
  extr[0].direction = direction;
  extr[0].price = price;
  extr[0].time = time;
 }

// ������� ������� ����� � �������
void DeleteLines ()
 {
  ObjectDelete(0,"trendUp");
  ObjectDelete(0,"trendDown");
  ObjectDelete(0,"horLine");
 }

// ���������� ��� �������� (����� �����, ����� ���� ��� �� �����
int   IsTrendNow ()
 {
  // ���� ����� �����
  if (GreatDoubles(extr[0].price,extr[2].price) && GreatDoubles(extr[1].price,extr[3].price) )
   return (1);
  // ���� ����� ����
  if (LessDoubles(extr[0].price,extr[2].price) && LessDoubles(extr[1].price,extr[3].price) )
   return (-1);
  return (0);   
 }
 
// ������ true, ���� ����� �������
bool  IsValidState (int trendType)
 {
  double H1,H2;
  double h1,h2;
  // ��������� ���������� h1,h2
  h1 = MathAbs(extr[0].price - extr[2].price);
  h2 = MathAbs(extr[1].price - extr[3].price);
  // ���� ����� �����
  if (trendType == 1)
   {
    // ���� ��������� ��������� - ����
    if (extr[0].direction == -1)
     {
      H1 = extr[1].price - extr[2].price;
      H2 = extr[3].price - extr[2].price;
      // ���� ���� ��������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (true);
     }
   }
  // ���� ����� ����
  if (trendType == -1)
   {
    // ����  ��������� ��������� - �����
    if (extr[0].direction == 1)
     {
     
      H1 = extr[1].price - extr[2].price;
      H2 = extr[3].price - extr[2].price;
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )    
       return (true);
     }

   }   
  return (false);   
 }
 
 // ������� ������������ ����� �� �����������  
void DrawLines ()
 {
    // �� ������� ����� �� ������
    if (extr[0].direction == 1)
     {
      trendLine.Create(0,"trendUp",0,extr[2].time,extr[2].price,extr[0].time,extr[0].price); // �������  �����
      ObjectSetInteger(0,"trendUp",OBJPROP_RAY_RIGHT,1);
      trendLine.Create(0,"trendDown",0,extr[3].time,extr[3].price,extr[1].time,extr[1].price); // ������  �����
      ObjectSetInteger(0,"trendDown",OBJPROP_RAY_RIGHT,1);   
      if (trend == 1)
       {
        horLine.Create(0,"horLine",0,extr[0].price); // �������������� �����    
        horPrice = extr[0].price;    
       } 
      if (trend == -1)
       {
        horLine.Create(0,"horLine",0,extr[1].price); // �������������� �����       
        horPrice = extr[1].price;         
       }        
     }
    // �� ������� ����� �� ������
    if (extr[0].direction == -1)
     {
      trendLine.Create(0,"trendDown",0,extr[2].time,extr[2].price,extr[0].time,extr[0].price); // ������  �����
      ObjectSetInteger(0,"trendDown",OBJPROP_RAY_RIGHT,1);
      trendLine.Create(0,"trendUp",0,extr[3].time,extr[3].price,extr[1].time,extr[1].price); // �������  �����
      ObjectSetInteger(0,"trendUp",OBJPROP_RAY_RIGHT,1);   
      if (trend == 1)
       {
        horLine.Create(0,"horLine",0,extr[1].price); // �������������� �����     
        horPrice = extr[1].price;           
       } 
      if (trend == -1)
       {
        horLine.Create(0,"horLine",0,extr[0].price); // �������������� �����      
        horPrice = extr[0].price;          
       }          
     }   
   
 }