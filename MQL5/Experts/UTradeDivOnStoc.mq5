//+------------------------------------------------------------------+
//|                                            UselessPersonSTOC.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBar.mqh>                    // ��� �������� ������������ ������ ����
#include <TradeManager\TradeManager.mqh>        // ����������� �������� ����������

#define  SELL -1
#define  BUY   1

int const sl_border = 130;                      //��������� ��� ���������� SL � ������� ������
//------------������� ������------------

//---------------�������----------------

//---------------�������----------------

CisNewBar      *isNewBar;
SPositionInfo  pos_inf;                          // ��������� � �������
STrailing      trail;                            // ���������� �� trail
CTradeManager  *ctm;                             // �������� �������

//---------------����������-------------
int    handlesmydSTOC;                             
int    handlePriceBasedIndicator;
double signal_buf[];                            // ������ �������� ����������� (SELL/BUY)
double buf_type_candle[];                       // ������ - ��� �������� ���� i-��� ����
double cur_price[];                             // ������ - ���� ���������� ����������� 
            

int    signal_buf_copied;
int    type_candle_copied;
int    price_copied;

double open_price;                              // ���� �������� �������
double divPrice;                                // ���� ���������� ����������� 
double stL;                                     // stopLoss - <<-�� ����������� ���� ���->>
int    minProf;                                 // minProfit
int    type_of_trade;                           // ��� �����������, �� ������� ��� ������ ��������� ������
                                                // ���� type_of_trade = 0 - �� �������� � ������ ���� �� ����� ������ �����������
bool   trendContinue;                           // ��������������� ����� �������� ������������ �����������


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 //---
 ctm = new CTradeManager(); 
 handlesmydSTOC = iCustom(_Symbol, _Period, "smydSTOC");
 if (handlesmydSTOC == INVALID_HANDLE)
 {
  Print("������ ��� ������������� �������� UselessPercon. �� ������� ������� ����� ShowMeYourDivSTOC");
  return(INIT_FAILED);
 }
 handlePriceBasedIndicator = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 if (handlePriceBasedIndicator == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� UselessPercon. �� ������� ������� ����� PriceBasedIndicator");
  return(INIT_FAILED);
 }
 isNewBar = new CisNewBar();
 //---------------�������� ���������!!!!!------------------------------------------------
 pos_inf.expiration = 0;   //����� ����� ����������� ����, 0- �����, ���� ���� �� ������
 pos_inf.volume = 1;       //����� ��������
 type_of_trade = 0;
 trendContinue = false;
 trail.trailingType = TRAILING_TYPE_USUAL;
 trail.trailingStep = 10;
 //---
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 ArrayFree(signal_buf);
 ArrayFree(buf_type_candle);
 IndicatorRelease(handlesmydSTOC);
 IndicatorRelease(handlePriceBasedIndicator);
 delete ctm;  
 delete isNewBar; 
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{ 
 ctm.OnTick();                            //<<��� ����� OnTick � DoTrailing>>
 signal_buf_copied  = CopyBuffer(handlesmydSTOC, 2, 0, 1, signal_buf);
 type_candle_copied = CopyBuffer(handlePriceBasedIndicator, 4, 0, 1, buf_type_candle);
 if(signal_buf_copied <= 0)
 {
  Print("�� ������� ����������� ������ � ���������� smydMACD");
  return;
 }
  if(type_candle_copied <= 0)
 {
  Print("�� ������� ����������� ������ � ���������� PriceBasedIndicator");
  return;
 }
 ctm.DoTrailing();
 
 //--------------�������� �������� � �������� �������------------
 //--------------------���� ��� ������� SELL---------------------
 if (type_of_trade == SELL)         
 {
  if(!CopyCurrentHighPrice(0))return;
  if(trendContinue)                 
  { Print("SELL: ����� ������������!!");
    //���� ����������� ������ � ������������ ���� ���� ��� �������������� ������
    if(buf_type_candle[0] == 1|| divPrice <= cur_price[0]) 
      divPrice = cur_price[0];               //������� ������� ���� 
    else 
     trendContinue = false;
     return;
  }
  else
  {
   if(buf_type_candle[0] == 1 || cur_price[0] > divPrice)               //���� ����� �����
   { Print("SELL: ��������� ����� ����� �������� ������!!");
    type_of_trade = 0;
   }
   else
   {
    if(buf_type_candle[0] == 2 || buf_type_candle[0] == 4)//���� ������� ��� �����������
     return;
    open_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    minProf    = (int) MathAbs((divPrice - open_price) / _Point);
    if(minProf <= sl_border)
     minProf = (int)(minProf + (sl_border - minProf) * 0.8);
    else
     minProf = (int)(minProf/((minProf - sl_border)/10+10));
    Print("SELL: ��������� ����� �����, ��������� �������!");
    //��������� � ������� ������� �� SELL 
    pos_inf.sl          = minProf;
    pos_inf.tp          = minProf * 1.4;  
    trail.minProfit     = minProf * 0.8;
    trail.trailingStop  = minProf;
    Print("SL = ", pos_inf.sl, " minProf = ", minProf, "divPrice = ", divPrice, "open_price = ", open_price);
    ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trail, 0);
    type_of_trade = 0;
   }
  }
 }

 //------------------���� ��� ������� BUY-------------------
 if (type_of_trade == BUY)         
 {
  if(!CopyCurrentLowPrice(0))return;    
  if(trendContinue)                 
  { Print("BUY: ����� ������������!!");
   //���� ����������� ������ � ������������ ���� ���� ��� �������������� ������
   if(buf_type_candle[0] == 3|| divPrice >= cur_price[0]) 
    divPrice = cur_price[0];              //������� ������� ���� 
   else 
    trendContinue = false;                //����������� ������ �����������
  }
  else
  { 
   if(buf_type_candle[0] == 3|| cur_price[0] <= divPrice)            //���� ����� ����
   {
    Print("BUY: ��������� ����� ���� �������� ������!!");
    type_of_trade = 0;
   }
   else
   {
    if(buf_type_candle[0] == 2 || buf_type_candle[0] == 4)//���� ������� ��� �����������
     return;    
    //��������� � ������� ������� �� BUY
    open_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    Print("BUY: ��������� ����� �����, ��������� �������!");
    minProf    = (int) MathAbs((divPrice - open_price) / _Point);
    if(minProf <= sl_border)
     minProf = (int)(minProf + (sl_border - minProf) * 0.8);
    else
     minProf = (int)(minProf /((minProf - sl_border)/10+10));//(int)minProf * 0.9; 
    pos_inf.sl          = minProf;
    trail.minProfit     = minProf * 0.8;
    trail.trailingStop  = minProf;
    pos_inf.tp          = minProf * 1.4;  
    Print("open_price = ", open_price);
    Print("SL = ", pos_inf.sl, " minProf = ", minProf);
    ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trail, 0);
    type_of_trade = 0;
   }
  }
 } 
}

void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
{
 //------------���� ��� ������ ������ ����������� �� SELL----------------
 if (sparam == "SELL")
 {
  type_of_trade = SELL;                       //��������� ���������� ������
  pos_inf.type = OP_SELL;
  Print("������� ������ BUY � ���������� ���� trendContinue");
  trendContinue = true;
  divPrice = dparam;                 //������� ������� ���� � slR
  Print("divPrice = ", divPrice);
 }
 //------------���� ��� ������ ������ ����������� �� BUY----------------
 if (sparam == "BUY")
 {
  type_of_trade = BUY;                       //��������� ���������� ������
  pos_inf.type = OP_BUY;
  Print("������� ������ BUY � ���������� ���� trendContinue");
  trendContinue = true;
  divPrice = dparam;                 
  Print("divPrice = ", divPrice);
 }
}

//---------------------CopyCurrentHighPrice--------------------------+
//-------------------------------------------------------------------+
bool CopyCurrentHighPrice(int index)
{
 price_copied  = CopyHigh(_Symbol, _Period, index, 1, cur_price);
 if(price_copied != 1)
 {
  Print("������! �� ������� ����������� ������� ���� High");  
  return false;
 }
 return true;
}


//---------------------CopyCurrentLowPrice---------------------------+
//-------------------------------------------------------------------+
bool CopyCurrentLowPrice(int index)
{
 price_copied  = CopyLow(_Symbol, _Period, index, 1, cur_price);
 if(price_copied != 1)
 {
  Print("������! �� ������� ����������� ������� ���� High");  
  return false;
 }
 return true;
}