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
input int price_diff = 50; // ���� �������

// ����������� ����������
int handleTrendLines; // ����� ���������� ��������� �����
int handleATR; // ����� ATR
int handleDE; // ����� DrawExtremums
int currentMoveType=0; // ������� ��������
int tradeSignal; // ���������� ��� �������� ������� �������� �������
double curBid; // ������� ���� Bid
double curAsk; // ������� ���� Ask
double prevBid; // ���������� ���� Bid
double prevAsk; // ���������� ���� Ask
double price_difference;
string supportLineName; // ��� ����� ���������
string resistanceLineName; // ��� ����� �������������
// ������� �������
CChartObjectTrend trend; // ��������� ����� �� ������� �����������
CTradeManager *ctm; // ������ ��������� ������
// ��������� ������� � ���������
SPositionInfo pos_info; // ��������� ���������� � �������
STrailing     trailing; // ��������� ���������� � ���������
//+------------------------------------------------------------------+
//| ��������� ������� ������ TIHIRO 2                                |
//+------------------------------------------------------------------+
int OnInit()
  {    
   // ��������� ����� ����� ������
   supportLineName = _Symbol + "_" + PeriodToString(_Period) + "_supLine"; 
   resistanceLineName = _Symbol + "_" + PeriodToString(_Period) + "_resLine";      
   price_difference = price_diff * _Point;
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
   
   handleTrendLines = iCustom(_Symbol,_Period,"TrendLines");
   if (handleTrendLines == INVALID_HANDLE)
    {
     Print("�� ������� ������� ��������� TrendLines");
     return (INIT_FAILED);
    }
   // �������� ������� ����� ATR
   handleATR = iATR(_Symbol,_Period, 25);
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
   // �������� ����
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   curAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   prevBid = curBid;
   prevAsk = curAsk;
   // ��������� ���� �������
   pos_info.volume = lot;
   pos_info.expiration = 0;
   pos_info.tp = 0;     
   // ��������� 
  // trailing.trailingType = TRAILING_TYPE_ATR;
   trailing.trailingType = TRAILING_TYPE_USUAL;
   trailing.handleForTrailing = 0;
   //trailing.handleForTrailing = handleATR;   
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
   // �������� ������� ������� ��������
   currentMoveType = GetMoveType();
   curBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   curAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   
   if (currentMoveType == 1)
    Comment("����� �����");
   if (currentMoveType == -1)
    Comment("����� ����");
   if (currentMoveType == 0)
    Comment("����");
  
   tradeSignal = SignalToOpenPosition();
   
   if (tradeSignal==1)
    {
     pos_info.type = OP_BUY;  
     pos_info.sl = CountStopLoss ();
     trailing.minProfit = pos_info.sl;
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);
    }
   if (tradeSignal==-1)
    {
     pos_info.type = OP_SELL;  
     pos_info.sl = CountStopLoss ();
     trailing.minProfit = pos_info.sl;
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);     
    }    
   prevBid = curBid;
   prevAsk = curAsk;
  }
  
//+------------------------------------------------------------------+
//| ��������������� ������� ������ TIHIRO 2                          |
//+------------------------------------------------------------------+

// ������� ��������� ������� �������� �������
int SignalToOpenPosition ()
 {
  double priceTrendLine;
  // ���� � ������ ������ - ����� �����
  if (currentMoveType == 1)
   {
    priceTrendLine = ObjectGetValueByTime(0,supportLineName,TimeCurrent());
    // ���� ����� ������ ����� �����
    if ( GreatDoubles(prevBid,priceTrendLine) && LessOrEqualDoubles(curBid,priceTrendLine) )
      return (1);     
   }
  // ���� � ������ ������ - ����� ����
  if (currentMoveType == -1)
   {
    priceTrendLine = ObjectGetValueByTime(0,resistanceLineName,TimeCurrent());
    // ���� ����� ������ ����� �����
    if ( LessDoubles(prevBid,priceTrendLine) && GreatOrEqualDoubles(curBid,priceTrendLine) )
      return (-1);     
   }     
  return (0);
 }

// ������� ����������, ����� ������ ����������� �������� ��������
int GetMoveType ()
 {
  color clrSup;
  color clrRes;
  clrSup = color(ObjectGetInteger(0,supportLineName,OBJPROP_COLOR));
  clrRes = color(ObjectGetInteger(0,resistanceLineName,OBJPROP_COLOR));
  if (clrSup == clrBlue && clrRes == clrBlue)
   return (1);
  if (clrSup == clrRed && clrRes == clrRed)
   return (-1);
  // ����� ��� ����
  return (0);
 }

// ������� ���������� ���� �����
int CountStopLoss ()
 {
  // ���� ��� �������� ���, �� ������ ���������
  double buffExtr[];
  double buffTime[];
  double curPrice;
  int buffInd;
  int timeInd;
  int bars = Bars(_Symbol,_Period);
  if (currentMoveType == 1)
   {
    buffInd = 1;
    timeInd = 5;
    curPrice = curBid;
   }
  if (currentMoveType == -1)
   {
    buffInd = 0;
    timeInd = 4;
    curPrice = curAsk;
   }
  for (int ind=0;ind<bars;)
   {
    if (CopyBuffer(handleDE,buffInd,ind,1,buffExtr) < 1 || CopyBuffer(handleDE,timeInd,ind,1,buffTime) < 1) 
     {
      Sleep(100);
      continue;
     }
    if (buffExtr[0] != 0.0)
     {
       return (int(MathAbs(curPrice-buffExtr[0])/_Point));
     }
    ind++;
   } 
  return (0);
 }  