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
#include <SystemLib/IndicatorManager.mqh>     // ���������� �� ������ � ������������
#include <CompareDoubles.mqh>                 // ��� ��������� ������������ �����
#include <TradeManager/TradeManager.mqh>      // �������� ����������
#include <Lib CisNewBarDD.mqh>                // ��� �������� ������������ ������ ����

input double lot = 1; // ���
input double percent = 0.1; // �������

// ��������� ����� ��� ���������� �����
struct pointLine
 {
  int direction;
  int bar;
  double price;
  datetime time;
 };
// ������� ������� 
CTradeManager *ctm; 
CisNewBar *isNewBar;
// ������ �����������
int  handleDE;
int  handlePBI;
// �������� 
int countTotal = 0; // ����� �����������
int trend = 0; // ������� ����� 1-� ����
int prevTrend = 0; // ���������� �����
double curBid; // ������� ���� bid
double curAsk; // ������� ���� Ask
double prevBid; // ���������� ���� bid
double priceTrendUp; // ���� ������� ����� ������
double priceTrendDown; // ���� ������ ����� ������
double H1,H2; // ���������� ����� ������������
double channelH; // ������ ������
double horPrice;
double pbiMove; // �������� �������� �� PBI � ������� ������
// ����� ������� 
string eventExtrUpName;    // ������� ������� �������� ����������
string eventExtrDownName;  // ����
string eventMoveChanged;
// ������� � ������
pointLine extr[4]; // ����� ��� ����������� �����
MqlRates rates[]; // ����� ���������
CChartObjectTrend  trendLine; // ������ ������ ��������� �����
CChartObjectHLine  horLine; // ������ ������ �������������� �����
// ��������� ������� � ���������
SPositionInfo pos_info;      // ��������� ���������� � �������
STrailing     trailing;      // ��������� ���������� � ���������

int OnInit()
 {
  isNewBar = new CisNewBar(_Symbol, _Period); 
  // ��������� ����� �������
  eventExtrDownName = "EXTR_DOWN_FORMED_" + _Symbol + "_"   + PeriodToString(_Period);
  eventExtrUpName   = "EXTR_UP_FORMED_"   + _Symbol + "_"   + PeriodToString(_Period); 
  eventMoveChanged  = "MOVE_CHANGED_"     + _Symbol + "_"   + PeriodToString(_Period); 
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
    
   // �������� ���������� PriceBasedIndicator
  handlePBI = DoesIndicatorExist(_Symbol,_Period,"PriceBasedIndicator");
  if (handlePBI == INVALID_HANDLE)
  {
   handlePBI = iCustom(_Symbol,_Period,"PriceBasedIndicator");
   if (handlePBI == INVALID_HANDLE)
   {
    Print("�� ������� ������� ����� ���������� PriceBasedIndicator");
    return (INIT_FAILED);
   }
   SetIndicatorByHandle(_Symbol,_Period,handlePBI);
  }     
  
  // ���� ������� ���������� ��������� ����������
  if (UploadExtremums())
  {
   trend = IsTrendNow();
   if (trend)
   {
    // ������ ����� 
    DrawLines ();    
   }
  }
  
   // ��������� ����  
  curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  curAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  prevBid = curBid;
   // ��������� ���� �������
  pos_info.expiration = 0;
   // ��������� 
  trailing.trailingType = TRAILING_TYPE_NONE;
  trailing.handleForTrailing = 0;     
  return(INIT_SUCCEEDED);
 }

void OnDeinit(const int reason)
  {
   DeleteLines ();
   delete isNewBar;
   delete ctm;
  }
  
void OnTick()
  {     
   ctm.OnTick();
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID); 
   curAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK); 
   // ���� � ������� ������ ������� ������� � ����� ���������������
   if (prevTrend == -trend && ctm.GetPositionCount() > 0)
     { 
      // �� ��������� �������
      ctm.ClosePosition(0);
     }
   // ���� ������� �������� - ����� 1-� ���� �����
   if (trend == 1)
    {
     // ���� ������������� ����� ���
     if (isNewBar.isNewBar() > 0)
      {
       // �������� ��������� ��������� ���� �����
       if (CopyRates(_Symbol,_Period,1,2,rates) == 2)
        {
         priceTrendUp = ObjectGetValueByTime(0,"trendUp",TimeCurrent());
         priceTrendDown = ObjectGetValueByTime(0,"trendDown",TimeCurrent());   
         channelH = priceTrendUp - priceTrendDown;   // �������� ������ ������   
         // ���� ���� �������� �� ��������� ���� ���� ���� �������� (� ���� �������), � �� ���������� ���� - �������� ���������
         if ( GreatDoubles(rates[1].close,rates[1].open) && LessDoubles(rates[0].close,rates[0].open) &&  // ���� ��������� ��� �������� � ���� �������, � ������� - � ���������������
              LessOrEqualDoubles(MathAbs(curBid-priceTrendDown),channelH*0.2)                             // ���� ������� ���� ��������� ����� ������ ������� ������ ������ 
            )
             {
              pos_info.sl = CountStopLossForTrendLines ();
              pos_info.tp = pos_info.sl*10;
              pos_info.volume = lot;
              pos_info.type = OP_BUY;
              ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
             }
        }
      }
    }
   // ���� ������� �������� - ����� 1-� ���� ����
   if (trend == -1)
    {
     // ���� ������������� ����� ���
     if (isNewBar.isNewBar() > 0)
      {
       // �������� ��������� ��������� ���� �����
       if (CopyRates(_Symbol, _Period, 1, 2, rates) == 2)
        {
         priceTrendUp = ObjectGetValueByTime(0,"trendUp", TimeCurrent());
         priceTrendDown = ObjectGetValueByTime(0,"trendDown", TimeCurrent());   
         channelH = priceTrendUp - priceTrendDown;   // �������� ������ ������   
         // ���� ���� �������� �� ��������� ���� ���� ���� �������� (� ���� �������), � �� ���������� ���� - �������� ���������
         if ( LessDoubles(rates[1].close,rates[1].open) && GreatDoubles(rates[0].close,rates[0].open) &&  // ���� ��������� ��� �������� � ���� �������, � ������� - � ���������������
              LessOrEqualDoubles(MathAbs(curBid-priceTrendUp),channelH * 0.2)                             // ���� ������� ���� ��������� ����� ������ ������� ������ ������ 
            )
             {
              pos_info.sl = CountStopLossForTrendLines ();
              pos_info.tp = pos_info.sl*10;
              pos_info.volume = lot;
              pos_info.type = OP_SELL;
              ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
             }
        }
      }
    }    
   prevBid = curBid;
   if (trend != 0)
    prevTrend = trend;
  }

// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
  {
   double price;
   
   if (sparam == eventExtrDownName)
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
     pos_info.type = OP_BUY; 
    }
   if (sparam == eventExtrUpName)
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     pos_info.type = OP_SELL;
    }
   // ������ ������� "������������� ����� ���������"
   if (sparam == eventExtrDownName || sparam == eventExtrUpName)
    {
     // ������� ����� � �������
     DeleteLines();
     // �������� ����� �������� ����������� � �������
     UploadExtremums ();

     trend = IsTrendNow();
     if (trend)
      {  
       // �������������� �����
       DrawLines ();     
      }
       
    }
   // ������ ������� "���������� �������� �� PBI"
   if (sparam == eventMoveChanged)
   {
    // ���� ����� �����
    if (dparam == 1.0 || dparam == 2.0)
    {
     
    }
    // ���� ����� ����
    if (dparam == 3.0 || dparam == 4.0)
    {
     
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
  int count = 0;           // ������� �����������
  int bars = Bars(_Symbol,_Period);
  for (int ind = 0; ind < bars;)
   {
    if (CopyBuffer(handleDE, 0, ind, 1, extrHigh) < 1 || CopyBuffer(handleDE, 1, ind, 1, extrLow) < 1 ||
        CopyBuffer(handleDE, 4, ind, 1, extrHighTime) < 1 || CopyBuffer(handleDE, 5, ind, 1, extrLowTime) < 1 )
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
 
// ������ true, ���� ����� �������
int  IsTrendNow ()
 {
  double h1,h2;
  
  // ��������� ���������� h1,h2
  h1 = MathAbs(extr[0].price - extr[2].price);
  h2 = MathAbs(extr[1].price - extr[3].price);
  // ���� ����� ����� 
  if (GreatDoubles(extr[0].price,extr[2].price) && GreatDoubles(extr[1].price,extr[3].price))
   {
    // ���� ��������� ��������� - ����
    if (extr[0].direction == -1)
     {
      H1 = extr[1].price - extr[2].price;
      H2 = extr[3].price - extr[2].price;
      // ���� ���� ��������� ����� ��� �������������
      if (GreatDoubles(h1, H1*percent) && GreatDoubles(h2, H2*percent) )
       return (1);
     }
   }
  // ���� ����� ����
  if (LessDoubles(extr[0].price,extr[2].price) && LessDoubles(extr[1].price,extr[3].price))
   {
    // ����  ��������� ��������� - �����
    if (extr[0].direction == 1)
     {
      H1 = extr[1].price - extr[2].price;
      H2 = extr[3].price - extr[2].price;
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )    
       return (-1);
     }
   }   
  return (0);   
 }
 
// ������� ��������� ���� ���� ��� ��������� �����
int CountStopLossForTrendLines ()
 {
  // ���� ����� �����
  if (trend == 1)
   {
    return (int((MathAbs(curBid-extr[0].price) + H1*percent)/_Point));
   }
  // ���� ����� ����
  if (trend == -1)
   {
    return (int((MathAbs(curAsk-extr[0].price) - H1*percent)/_Point));
   }   
  return (0);
 }

// ������� ��������� ���� ���� ��� PBI
int CountStopLossForPBI ()
 {
  // ���� ����� �����
  if (trend == 1)
   {
    return ( int(MathAbs( ((curBid-extr[0].price)/2)/_Point )) );
   }
  // ���� ����� ����
  if (trend == -1)
   {
    return (int(MathAbs( ((curAsk-extr[0].price)/2)/_Point )) );   
   }
  return (0);
 }
 
 // ������� ������������ ����� �� �����������  
void DrawLines ()
 {
    Print ("������ �����");
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
      trendLine.Create(0,"trendDown", 0, extr[2].time, extr[2].price, extr[0].time, extr[0].price); // ������  �����
      ObjectSetInteger(0,"trendDown", OBJPROP_RAY_RIGHT, 1);
      trendLine.Create(0,"trendUp", 0, extr[3].time, extr[3].price, extr[1].time, extr[1].price); // �������  �����
      ObjectSetInteger(0,"trendUp", OBJPROP_RAY_RIGHT, 1);   
      if (trend == 1)
       {
        horLine.Create(0,"horLine", 0, extr[1].price); // �������������� �����     
        horPrice = extr[1].price;           
       } 
      if (trend == -1)
       {
        horLine.Create(0,"horLine", 0, extr[0].price); // �������������� �����      
        horPrice = extr[0].price;          
       }          
     }   
 }