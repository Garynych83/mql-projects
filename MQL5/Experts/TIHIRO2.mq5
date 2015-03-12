//+------------------------------------------------------------------+
//|                                                      TIHIRO2.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ����� ��� �������� ��������� ����� ����� ������������            |
//+------------------------------------------------------------------+

// ����������� ����������� ���������
#include <TradeManager/TradeManager.mqh>  // �������� ����������
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������
#include <SystemLib/IndicatorManager.mqh>  // ���������� �� ������ � ������������
#include <DrawExtremums/SExtremum.mqh> // ��������� ����������
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����
#include <CLog.mqh>  // ��� ������� ����

// ��������� ������
input double lot = 1.0; // ���

// ����������� ����������
int handleDE; // ����� ���������� DrawExtremums
int handleATR; // ����� ATR
double curBid; // ������� ���� Bid
double prevBid; // ���������� ���� Bid
// ������� �������
CChartObjectTrend trend; // ��������� ����� �� ������� �����������
CTradeManager *ctm; // ������ ��������� ������
// ������� ����������� ��� ��������� ��������� �����
SExtremum extrHigh[2];  // ��� ��������� ������� ����������
SExtremum extrLow[2]; // ��� ��������� ������ ����������
// ��������� ������� � ���������
SPositionInfo pos_info; // ��������� ���������� � �������
STrailing     trailing; // ��������� ���������� � ���������
//+------------------------------------------------------------------+
//| ��������� ������� ������ TIHIRO 2                                |
//+------------------------------------------------------------------+
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
   // �������� ������� ����� ATR
   handleATR       = iATR(_Symbol,_Period, 25);
   if (handleATR == INVALID_HANDLE)
    {
     Print("�� ������� ������� ��������� ATR");
     return (INIT_FAILED);
    }         
   ctm = new CTradeManager();
   if (ctm == NULL)
    {
     Print("�� ������� ������� �������� ����������");
     return (INIT_FAILED);
    }
   
   // ���� �� ������� �������� ��������� ����������
   if (!GetFirstTrend () )
    {
     Print("�� ������� ���������� ��������� ���������� ��� ���������� ��������� �����");
     return (INIT_FAILED); // �� ���������� ����, ����� ����������� � ����. ���    
    }
   // ������� ��������� ����� �� ��������� �����������
   
   trend.Create(0,"TihiroTrend",0,datetime(extrHigh[1].time),extrHigh[1].price,datetime(extrHigh[0].time),extrHigh[0].price); 
   
   // ������������� �������� �����
   ObjectSetInteger(0,"TihiroTrend",OBJPROP_RAY_RIGHT,1);
   // �������� ����
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   prevBid = curBid;
   // ��������� ���� �������
   pos_info.volume = lot;
   pos_info.expiration = 0;
   pos_info.tp = 0;     
   // ��������� 
   trailing.trailingType = TRAILING_TYPE_ATR;
   trailing.handleForTrailing = handleATR;   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {  
   // ������� �������
   delete ctm;
  }

void OnTick()
  {
   ctm.OnTick();
   ctm.DoTrailing();
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if (SignalToOpenPosition ())
    {
     pos_info.type = OP_BUY;  
     pos_info.sl = CountStopLoss ();
     trailing.minProfit = pos_info.sl;
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);     
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
   // ���� ������ ����� ������� ���������
   if (sparam == "EXTR_UP_FORMED")
    {
     // �� ��������� ����� ������
     UpdateTrend(dparam,datetime(lparam));
     DragRay(lparam);
    } 
  }  
  
//+------------------------------------------------------------------+
//| ��������������� ������� ������ TIHIRO 2                          |
//+------------------------------------------------------------------+

// ������� �������� ������ ����� ��� ������� ������
bool GetFirstTrend () 
 {
  double buffHigh[];
  double buffTime[];
  bool countExtr=false;
  int bars = Bars(_Symbol,_Period);
  for (int ind=1;ind<bars;)
   {
    // ���� �� ������� ���������� ��������� �������� �������
    if (CopyBuffer(handleDE,0,ind,1,buffHigh) < 1 || CopyBuffer(handleDE,4,ind,1,buffTime) < 1)
     {
      Sleep(100);
      continue;
     }    
    // ���� ������ ���������
    if (buffHigh[0] != 0)
     {
      // ���� ��� ������ ���������� �� ���� ���������
      if (countExtr==false)
       {
        extrHigh[0].direction = 1;
        extrHigh[0].price = buffHigh[0];
        extrHigh[0].time = datetime(buffTime[0]);
        countExtr=true;
       }
      else
       {
        // ���� ��������� ��������� ���� �������
        if (GreatDoubles(buffHigh[0],extrHigh[0].price))
         {
          // �� ��������� ������ ��������� � ���������� true
          extrHigh[1].direction = 1;
          extrHigh[1].price = buffHigh[0];
          extrHigh[1].time = datetime(buffTime[0]);
          return (true);
         }
       }
       
     }
    ind++;
   }
  return(false);
 }
 
// ������� ���������� ������ (� �������� ������ ����������
void UpdateTrend (double price,datetime time)
 {
  // ���� ����� ��������� ���� ����������
  if (LessDoubles(price,extrHigh[0].price))
   {
    // �� ���������� ������ ������ �� ��������� ���������
    extrHigh[1] = extrHigh[0];
   }
  // ���� ����� ��������� ���� ������ ����� ������
  if (GreatDoubles(price,extrHigh[1].price))
   {
    // ����� ��������� ����������� �����
    GetFirstTrend();
   }
  else
   {
    // �������� ��������� ��������� �� ����� 
    extrHigh[0].direction = 1;
    extrHigh[0].price = price;
    extrHigh[0].time = time;
   }
 }

// ������� ��������� ������� �������� �������
bool SignalToOpenPosition ()
 {
  double priceTrendLine = ObjectGetValueByTime(0,"TihiroTrend",TimeCurrent());
  // ���� ����� ������ ����� �����
  if ( LessDoubles(prevBid,priceTrendLine) && GreatOrEqualDoubles(curBid,priceTrendLine) )
    return (true);     
  return (false);
 }

// ������� ���������� ���� �����
int CountStopLoss ()
 {
  // ���� ��� �������� ���, �� ������ ���������
  double buffLow[];
  double buffTime[];
  int bars = Bars(_Symbol,_Period);
  for (int ind=0;ind<bars;)
   {
    if (CopyBuffer(handleDE,1,ind,1,buffLow) < 1 || CopyBuffer(handleDE,5,ind,1,buffTime) < 1) 
     {
      Sleep(100);
      continue;
     }
    if (buffLow[0] != 0.0)
     {
       return (int(MathAbs(curBid-buffLow[0])/_Point));
     }
    ind++;
   } 
  return (0);
 }

//+------------------------------------------------------------------+
//| ���������� ������� ������ TIHIRO 2                               |
//+------------------------------------------------------------------+
 
// ������� ��������� ����
void DragRay (int type)
 {
  ObjectDelete(0,"TihiroTrend");
  trend.Create(0,"TihiroTrend",0,datetime(extrHigh[1].time),extrHigh[1].price,datetime(extrHigh[0].time),extrHigh[0].price);
  ObjectSetInteger(0,"TihiroTrend",OBJPROP_RAY_RIGHT,1);    
 }