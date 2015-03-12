//+------------------------------------------------------------------+
//|                                              UselessPersonMA.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
#include <Lib CisNewBar.mqh>                    // ��� �������� ������������ ������ ����
#include <TradeManager\TradeManager.mqh>        // ����������� �������� ����������
#include <CompareDoubles.mqh>                   // ��� �������� �����������  ���

#define SELL -1
#define BUY 1
//----------------���������--------------
int const upBorderRSI   = 50;
int const downBorderRSI = 50;

//---------------�������----------------
CisNewBar      *isNewBar;
CTradeManager  *ctm;
SPositionInfo  pos_inf;
STrailing      trail;                            

//---------------����������-------------
int      ihandleMA_fast;
int      ihandleMA_slow;
int      ihandleDE;
int      ihandleRSI;
int      ihandleATR;
int      bars;
int      price_copied;
int      copied_DE_low;
int      copied_DE_high;
int      copied_RSI;
int      openedPosition;
double   buf_MA_fast[];
double   buf_MA_slow[];
double   curRSI[];
double   lastMaxExtrPrice[];
double   lastMinExtrPrice[];
double   lastExtrPrice[];
double   last_extrem_low = 0;
double   last_extrem_high = 0;


int OnInit()
{
 ihandleMA_slow   = iMA(_Symbol,_Period, 70, 0, MODE_SMA, PRICE_CLOSE);
 ihandleMA_fast   = iMA(_Symbol,_Period, 50, 0, MODE_SMA, PRICE_CLOSE);
 ihandleDE        = iCustom(_Symbol, _Period, "DrawExtremums");
 ihandleRSI       = iRSI(_Symbol, _Period, 7, PRICE_CLOSE);
 ihandleATR       = iATR(_Symbol,_Period, 25);
 if(ihandleMA_slow == INVALID_HANDLE || ihandleMA_fast == INVALID_HANDLE)
 {
  Print("�� ������� ������� ����� ���������� iMA ");
  return(INIT_FAILED);
 }
 if(ihandleDE == INVALID_HANDLE)
 {
  Print("�� ������� ������� ����� ���������� DrawExtremums ");
  return(INIT_FAILED);
 }
 if(ihandleRSI == INVALID_HANDLE)
 {
  Print("�� ������� ������� ����� RSI ");
  return(INIT_FAILED);
 }
 //----------------�������� ����� �����������-------------------
 bars = Bars(_Symbol, _Period);
 if(bars > 1000)
  bars = 1000;
 for (int attempts=0; attempts < 25; attempts++)
  {
   copied_DE_high = CopyBuffer(ihandleDE,2,0,bars,lastMaxExtrPrice);
   copied_DE_low  = CopyBuffer(ihandleDE,3,0,bars,lastMinExtrPrice); 
   Sleep(100);
  }
 if(copied_DE_high != bars || copied_DE_low != bars)
 {
  Print("�� ������� ����������� ����� ����������� ");
  return(INIT_FAILED);
 }
 for(int i = bars - 1; i >= 0; i--)
 {
  if(lastMaxExtrPrice[i] != 0)
   last_extrem_high = lastMaxExtrPrice[i]; 
  if(lastMinExtrPrice[i] != 0)
   last_extrem_low = lastMinExtrPrice[i]; 
  if(last_extrem_low != 0 && last_extrem_high != 0)
   break; 
 }
 //--------------������������� ����������-----------------------
 isNewBar = new CisNewBar();
 ctm      = new CTradeManager();
 trail.trailingType = TRAILING_TYPE_ATR;
 trail.handleForTrailing = ihandleATR;
 pos_inf.volume = 1;
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete ctm;
 delete isNewBar;  
 IndicatorRelease(ihandleDE);
 IndicatorRelease(ihandleMA_fast);
 IndicatorRelease(ihandleMA_slow);
 IndicatorRelease(ihandleRSI);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{ 
 ctm.OnTick();
 UpdateExtremums();
 ctm.DoTrailing();
 if(bars >= 300 && isNewBar.isNewBar())  //���� ������ ����� ��� � ������� ��������� ����������, ����� ��������� �� ��� ����������
 {
  if(!(CopyBuffer(ihandleMA_slow,0,1,2,buf_MA_slow) && CopyBuffer(ihandleMA_fast,0,1,2,buf_MA_fast)))
  {
   Print("�� ������� ���������� ������ ��");
   return;
  }
  if(GreatDoubles(buf_MA_fast[0],buf_MA_slow[0]) && LessDoubles(buf_MA_fast[1], buf_MA_slow[1])) //������������� ����������� �������
  {
   if(CopyCurrentHighPrice(1)) //�������� High ���������� ��������������� ����
   { 
    if(lastExtrPrice[0] > buf_MA_slow[1]) //���� High ��������� ���� �����������
    {
     copied_RSI = CopyBuffer(ihandleRSI, 0, 1, 1, curRSI); // �������� �������� RSI �� ���������� ����
    if(copied_RSI != 1)
     {
      Print("�� ������� ����������� ����� ����������� ");
      return;
     }
     // ���� RSI ������ upborderRSI 
     if(curRSI[0] > upBorderRSI)
     {
      // ��������� ������� �� �������
      openedPosition = SELL;
      pos_inf.type = OP_SELL;
      pos_inf.sl = GetStopLoss(openedPosition);
      trail.minProfit = pos_inf.sl; 
      ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trail, 0);
     }
    }
   }
  }
  if(LessDoubles(buf_MA_fast[0], buf_MA_slow[0]) && GreatDoubles(buf_MA_fast[1],buf_MA_slow[1])) //������������� ����������� �������
  {
   
   if(CopyCurrentLowPrice(1)) //�������� Low ���������� ��������������� ����
   {
    if(lastExtrPrice[0] < buf_MA_slow[1]) //���� Low ��������� ���� �����������
    {
     copied_RSI = CopyBuffer(ihandleRSI, 0, 1, 1, curRSI); // �������� �������� RSI �� ���������� ����
     if(copied_RSI != 1)
     {
      Print("�� ������� ����������� ����� ����������� ");
      return;
     }
     // ���� RSI ������ downborderRSI 
     if(curRSI[0] < downBorderRSI)
     {
      // ��������� ������� �� �������
      openedPosition = BUY;
      pos_inf.type = OP_BUY;
      pos_inf.sl = GetStopLoss(openedPosition);             //�������� sl
      trail.minProfit = pos_inf.sl;                        //minProfit  = sl
      ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trail, 0);
     }
    }
   }
  }
 } 
}



//---------------------CopyCurrentHighPrice---------------------------+
//-----------------������� high ���� �� �������------------------------
bool CopyCurrentHighPrice(int index)
{
 price_copied  = CopyHigh(_Symbol, _Period, index, 1, lastExtrPrice);
 if(price_copied != 1)
 {
  Print("������! �� ������� ����������� ������� ���� High");  
  return false;
 }
 return true;
}


//---------------------CopyCurrentLowPrice---------------------------+
//--------------- ������� low ���� �� ������� -----------------------+
bool CopyCurrentLowPrice(int index)
{
 price_copied  = CopyLow(_Symbol, _Period, index, 1, lastExtrPrice);
 if(price_copied != 1)
 {
  Print("������! �� ������� ����������� ������� ���� High");  
  return false;
 }
 return true;
}


//-----------------------UpdateExtremums-----------------------------+
//--------------- ��������� ��������� ���������� --------------------+
void UpdateExtremums()
{
 copied_DE_high = CopyBuffer(ihandleDE,2,0,1,lastMaxExtrPrice);
 copied_DE_low  = CopyBuffer(ihandleDE,3,0,1,lastMinExtrPrice);
 if(copied_DE_high != 1 || copied_DE_low != 1)
 {
  Print("�� ������� ����������� ����� ����������� ");
  return;
 }
 if(lastMaxExtrPrice[0] != 0)
  last_extrem_high = lastMaxExtrPrice[0];
 if(lastMinExtrPrice[0] != 0)
  last_extrem_low = lastMinExtrPrice[0];
 return;
}


//-----------------------GetStopLoss-----------------------------+
//--------------- ������������ � ���������� StopLoss ------------+
int GetStopLoss(int openedPos)
{
 int slValue = 0;      // �������� ���� �����
 int stopLevel;        // ���� �����
 double openPrice;
 stopLevel = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);  // �������� ���� �����
 switch(openedPos)
 {
  case BUY:
   openPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   slValue = (int)MathAbs((last_extrem_low - openPrice) / _Point);
   break;
  case SELL:
   openPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   slValue = (int)MathAbs((last_extrem_high - openPrice) / _Point);
  break;
 }Print("last_extrem_low = ", last_extrem_low, " openPrice = ", openPrice , " slValue = ", slValue, " stopLevel = ", stopLevel);
 if (slValue > stopLevel)
  return (slValue);
 else
  return (stopLevel + 1);   
}


//-----------------------IsSuitRSI------------------------------------+
//------ ���������� ���������� �������� ������ �� ������� RSI --------+
//---------------------�� ������������ � ����!------------------------+
bool IsSuitRSI(int borderRSI, int tradeType)
{
 int copied_RSI;
 copied_RSI = CopyBuffer(ihandleRSI, 0, 1, 1, curRSI); // �������� �������� RSI �� ���������� ����
 if(copied_RSI != 1)
 {
  Print("�� ������� ����������� ����� ����������� ");
  return false;
 }
 // ���� RSI , ������ borderRSI ��� tradeType = SELL
 if(curRSI[0] > borderRSI && tradeType == SELL)
 return true;
 // ���� RSI , ������ borderRSI ��� tradeType = SELL
 if(curRSI[0] > borderRSI && tradeType == BUY)
 return true;
 return false;
}