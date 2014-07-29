//+------------------------------------------------------------------+
//|                                                 TrailingStop.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <TradeManager\TradeManagerEnums.mqh>
#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <ColoredTrend\ColoredTrendUtilities.mqh>
#include <BlowInfoFromExtremums.mqh>

#define DEPTH_PBI 100

//+------------------------------------------------------------------+
//| ����� ��� ���������� ����-������                                 |
//+------------------------------------------------------------------+
class CTrailingStop
  {
private:
   CSymbolInfo SymbInfo;
   bool UpdateSymbolInfo(string symbol);
   double _previewPriceAsk;
   double _previewPriceBid;
   double PBI_colors[], PBI_Extrems[];
   
public:
   CTrailingStop();
   ~CTrailingStop();
   
   double UsualTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                       , int _minProfit, int _trailingStop, int _trailingStep);
                       
   double LosslessTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                       , int _minProfit, int _trailingStop, int _trailingStep);
   double PBITrailing(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_TM_POSITION_TYPE type, double sl, int handle_PBI);
   double ExtremumsTrailing (string symbol,ENUM_TM_POSITION_TYPE type,double sl, CBlowInfoFromExtremums *blowInfo=NULL);                    
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrailingStop::CTrailingStop()
  {
   ArraySetAsSeries(PBI_colors, true);
   ArraySetAsSeries(PBI_Extrems, true);
   _previewPriceAsk = 0;
   _previewPriceBid = 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrailingStop::~CTrailingStop()
  {
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// ������� ��������
//+------------------------------------------------------------------+
double CTrailingStop::UsualTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                                   , int minProfit, int trailingStop, int trailingStep)
{
 double newSL = 0;
 if (minProfit > 0 && trailingStop > 0 && trailingStep > 0)
 {
  UpdateSymbolInfo(symbol);
  double ask = SymbInfo.Ask();
  double bid = SymbInfo.Bid();
  double point = SymbInfo.Point();
  int digits = SymbInfo.Digits();
 
  if (type == OP_BUY &&
      LessDoubles(openPrice, bid - minProfit*point) &&
      (LessDoubles(sl, bid - (trailingStop+trailingStep-1)*point) || sl == 0))
  {
   Print("UsualTrailing");
   newSL = NormalizeDouble(bid - trailingStop*point, digits);
  }
 
  if (type == OP_SELL &&
      GreatDoubles(openPrice, ask + minProfit*point) &&
      (GreatDoubles(sl, ask + (trailingStop+trailingStep-1)*point) || sl == 0))
  {
   Print("UsualTrailing");
   newSL = NormalizeDouble(ask + trailingStop*point, digits);
  }
 }
 return (newSL);
}

//+------------------------------------------------------------------+
// �������� � ������� �� ���������
//+------------------------------------------------------------------+
double CTrailingStop::LosslessTrailing(string symbol, ENUM_TM_POSITION_TYPE type, double openPrice, double sl
                       , int minProfit, int trailingStop, int trailingStep)
{
 double newSL = 0;
 if (minProfit > 0 && trailingStop > 0 && trailingStep > 0)
 {
  UpdateSymbolInfo(symbol);
  double price;
  int direction;
  if (type == OP_BUY)
  {
   price = SymbInfo.Bid();
   direction = -1;
  }
  else if (type == OP_SELL)
       {
        price = SymbInfo.Ask();
        direction = 1; 
       }
       else return true;
  
  double point = SymbInfo.Point();
  int digits = SymbInfo.Digits();
 
  if (GreatDoubles(direction*openPrice, direction*price + minProfit*point)) // ���� ��������� ��������� 
  {
   newSL = openPrice*point;                                                  // ��������� �� � ��������� 
  }
  if (GreatDoubles(direction*openPrice, direction*price + minProfit*point)
     && GreatDoubles(direction*sl, direction*price + (trailingStop+trailingStep-1)*point) || sl == 0)
  {
   newSL = NormalizeDouble(price + direction*trailingStop*point, digits);
  }
 }
 return (newSL);
}

//+------------------------------------------------------------------+
// �������� �� ���������� PBI
//+------------------------------------------------------------------+
double CTrailingStop::PBITrailing(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_TM_POSITION_TYPE type, double sl, int handle_PBI)
{
 datetime buffer_date[];
 int errcolors = CopyBuffer(handle_PBI, 4, 0, DEPTH_PBI, PBI_colors);
 int errdate = CopyTime(symbol, timeframe, 0, DEPTH_PBI, buffer_date);
 ArraySetAsSeries(buffer_date, true);
 int errextrems, direction;
 int mainTrend, forbidenTrend;
 
 if (type == OP_SELL)
 {
  //Print("PBI_Trailing, ������� ����, ��� �������� ", PBI_colors[0]);
  errextrems = CopyBuffer(handle_PBI, 5, 0, DEPTH_PBI, PBI_Extrems); // �������� ���������
  direction = 1;
  mainTrend = 3;
  forbidenTrend = 4;
 }
 if (type == OP_BUY)
 {
  //Print("PBI_Trailing, ������� ���, ��� �������� ", PBI_colors[0]);
  errextrems = CopyBuffer(handle_PBI, 6, 0, DEPTH_PBI, PBI_Extrems); // �������� ��������
  direction = -1;
  mainTrend = 1;
  forbidenTrend = 2;
 }
 if(errcolors < 0 || errextrems < 0)
 {
  PrintFormat("%s �� ������� ����������� ������ �� ������������� ������", MakeFunctionPrefix(__FUNCTION__)); 
  return(0.0); 
 }
 
 double newExtr = 0;
 int index;
 if (PBI_colors[0] == mainTrend || PBI_colors[0] == forbidenTrend)
 {
//  PrintFormat("������� �������� %s. time = %s", MoveTypeToString((ENUM_MOVE_TYPE)PBI_colors[0]), TimeToString(buffer_date[0]));
  for (index = 0; index < DEPTH_PBI; index++)
  { 
   if (PBI_Extrems[index] > 0)
   {
    if (PBI_colors[index] == 5 || PBI_colors[index] == 6 || PBI_colors[index] == 7)
    {
     newExtr = PBI_Extrems[index];
     //Print("��������� ��������� ", newExtr);
     break;
    } 
   }
  }
 }
 
 if (newExtr > 0 && GreatDoubles(direction * sl, direction * (newExtr + direction * 50.0*Point()), 5))
 {
  PrintFormat("%s %s currentMoving = %s, extremum_from_last_coor_or_trend = %s, oldSL = %.05f, newSL = %.05f", MakeFunctionPrefix(__FUNCTION__), TimeToString(buffer_date[0]), MoveTypeToString((ENUM_MOVE_TYPE)PBI_colors[0]), MoveTypeToString((ENUM_MOVE_TYPE)PBI_colors[index]), sl, (newExtr + direction*50.0*Point()));
  return (newExtr + direction*50.0*Point());
 }
 ArrayFree(buffer_date);
 return(0.0);
};


// �������� �� �����������
double CTrailingStop::ExtremumsTrailing (string symbol,ENUM_TM_POSITION_TYPE type,double sl, CBlowInfoFromExtremums *blowInfo=NULL)
{
 double stopLoss = 0;                                            // ���������� ��� �������� ������ ���� ����� 
 double currentPriceBid = SymbolInfoDouble(symbol, SYMBOL_BID);  // ������� ���� BID
 double currentPriceAsk = SymbolInfoDouble(symbol, SYMBOL_ASK);  // ������� ���� ASK
 double tmpPrevBid;                                              // ���������� ���� BID
 double tmpPrevAsk;                                              // ���������� ���� ASK
 double lastExtrHigh;                                            // ���� ���������� ���������� �� HIGH
 double lastExtrLow;                                             // ���� ���������� ���������� �� LOW
 double stopLevel;                                               // ������ ���� ������
 ENUM_EXTR_USE last_extr;                                        // ���������� ��� �������� ���������� ����������
 tmpPrevAsk = _previewPriceAsk;
 tmpPrevBid = _previewPriceBid;
 // ��������� ������� ���� � �������� ����������
 _previewPriceAsk = currentPriceAsk;
 _previewPriceBid = currentPriceBid;
 if (tmpPrevAsk == 0 || tmpPrevBid == 0)
  return (0.0);
 // �������� �������� ������ �� �����������
 if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )     
  {
   // �������� ��� ���������� ����������
   last_extr = blowInfo.GetLastExtrType();
   if (last_extr == EXTR_NO)
    return (0.0);
   // ��������� ���� �����
   stopLevel = SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;
   if (type == OP_BUY)
    {
     // ���� ��������� ����������� �������� LOW
     if (last_extr == EXTR_LOW)
      {
       lastExtrHigh   = blowInfo.GetExtrByIndex(EXTR_HIGH,0).price;     // �������� ��������� ������� ��������� HIGH ��� ��������
       lastExtrLow    = blowInfo.GetExtrByIndex(EXTR_LOW,0).price;      // �������� ��������� ������ ��������� LOW ��� stopLoss
       // ���� ������� ���� ������� ��������� �������� HIGH ���������  
       if ( GreatDoubles(currentPriceBid,lastExtrHigh) &&
            LessDoubles (tmpPrevBid,lastExtrHigh) )
          {
           // ���� ���������� �� ���� �� ������ ���� ����� ������ ���� ������
           if ( GreatDoubles(currentPriceBid-lastExtrLow,stopLevel) )
             {
               // ���� ����� ���� ���� ������ �����������
               if ( GreatDoubles(lastExtrLow,sl) )
                  stopLoss = lastExtrLow;        
             }
          else
             {
               // ���� ����� ���� ���� ������ �����������
               if ( GreatDoubles(currentPriceBid-stopLevel-0.0001,sl) )
                  stopLoss = currentPriceBid - stopLevel-0.0001;
             }
          } 
       }
    }
   if (type == OP_SELL)
    {
     // ���� ��������� ����������� �������� HIGH
     if (last_extr == EXTR_HIGH)
      {
       lastExtrHigh   = blowInfo.GetExtrByIndex(EXTR_HIGH,0).price;     // �������� ��������� ������� ��������� HIGH ��� stopLoss
       lastExtrLow    = blowInfo.GetExtrByIndex(EXTR_LOW,0).price;      // �������� ��������� ������ ��������� LOW ��� ��������
       // ���� ������� ���� ������� ��������� �������� LOW ���������  
       if ( LessDoubles(currentPriceAsk,lastExtrLow) &&
            GreatDoubles (tmpPrevAsk,lastExtrLow) )
          {
           // ���� ���������� �� ���� �� ������ ���� ����� ������ ���� ������
           if ( GreatDoubles(lastExtrHigh - currentPriceAsk,stopLevel) )
             {
               // ���� ����� ���� ���� ������ �����������
               if ( LessDoubles(lastExtrHigh,sl) )
                  stopLoss = lastExtrHigh;        
             }
          else
             {
               // ���� ����� ���� ���� ������ �����������
               if ( LessDoubles(currentPriceAsk+stopLevel+0.0001,sl) )
                  stopLoss = currentPriceAsk + stopLevel+0.0001;
             }
          } 
      }    
   }
  }
  /*
  datetime d1 = D'2012.07.12 10:00:57';
  datetime d2 = D'2012.07.12 10:25:09';


  if (TimeCurrent() >= d1 && TimeCurrent() <= d2) 
   {
     Print("STOP LOSS = ",DoubleToString(stopLoss),
     " STOP LEVEL = ",DoubleToString(stopLevel),
     " PRICE = ",DoubleToString(currentPrice),
     " PRICE REAL = ",DoubleToString(SymbolInfoDouble(symbol,SYMBOL_BID)));
   }
   */
 return (NormalizeDouble(stopLoss,_Digits));
}
 
//+------------------------------------------------------------------+
//|��������� ���������� ���������� �� ��������� �����������          |
//+------------------------------------------------------------------+
bool CTrailingStop::UpdateSymbolInfo(string symbol)
{
 SymbInfo.Name(symbol);
 if(SymbInfo.Select() && SymbInfo.RefreshRates())
 {
  return(true);
 }
 return(false);
}