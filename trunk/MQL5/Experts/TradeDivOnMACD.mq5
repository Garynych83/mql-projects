//+------------------------------------------------------------------+
//|                                            UselessPersonMACD.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                                                                  |
//|             ����� UselessPerson ������������ ��� �������� ������ | 
//|                                 �� ������� � ���������� smydMACD |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBar.mqh>                    // ��� �������� ������������ ������ ����
#include <TradeManager\TradeManager.mqh>        // ����������� �������� ����������

#define  SELL -1
#define  BUY 1

//----������� ������---

//-------�������-------
SPositionInfo pos_inf;                          //��������� � �������
STrailing trailingR;                            //���������� �� trailingR
CTradeManager *ctm;                             //�������� �������


//------����������-----
int handlesmydMACD;                             
int handlePriceBasedIndicator;
double signal_buf_smydMACD[];                   //������ �������� ����������� (SELL/BUY)
double buf_type_candle[];                       //������ - ��� �������� ���� i-��� ����
double current_price[];                         //<< ����� ������� ����������� � �������� 1>> ��� �������� ���� �������� �������
            
int smydMACD_copied;
int type_candle_copied;
int price_copied;
double cur_price;
double slR;
int minProfitR;
bool trendContinue;                             //��������������� ����� �������� ������������ �����������
int type_of_trade;                              //��� �����������, �� ������� ��� ������ ��������� ������
                                                //���� type_of_trade=0 - �� �������� � ������ ���� �� ����� ������ �����������
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 ctm = new CTradeManager(); 
 handlesmydMACD = iCustom(_Symbol, _Period, "smydMACD");
 if (handlesmydMACD == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� TradeDivOnMACD. �� ������� ������� ����� ShowMeYourDivMACD");
  return(INIT_FAILED);
 }
 handlePriceBasedIndicator = iCustom(_Symbol, _Period, "PriceBasedIndicator");
 if (handlePriceBasedIndicator == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� TradeDivOnMACD. �� ������� ������� ����� PriceBasedIndicator");
  return(INIT_FAILED);
 } 
 pos_inf.expiration = 0;                        //����� ����� ����������� ����, 0- �����, ���� ���� �� ������
 pos_inf.volume = 1;                            //����� ��������
 type_of_trade = 0;
 trendContinue = false;
 trailingR.trailingType = TRAILING_TYPE_USUAL;
 trailingR.trailingStep = 10;
 
 return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 ArrayFree(signal_buf_smydMACD);
 ArrayFree(buf_type_candle);
 IndicatorRelease(handlesmydMACD);
 delete ctm;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();
 type_candle_copied = CopyBuffer(handlePriceBasedIndicator, 4, 0, 1, buf_type_candle);
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
  if(trendContinue)                 
  {
   if(buf_type_candle[0] == 1)      //���� ����� �����
     if(CopyCurrentHighPrice(0))    //���� ����������� ������
      slR = current_price[0];       //������� ������� ���� � slR
     else 
      return;
   else
   trendContinue = false;
  }
  else
  {
   if(buf_type_candle[0] == 1)      //���� ����� �����
   {
    type_of_trade = 0;
   }
   else
   {
    if(buf_type_candle[0] == 3 || buf_type_candle[0] == 6)//���� ����������� ��������� ��� ����� ����
    {
    Print("SELL: ��������� ����� �����, ��������� �������!");
     //��������� � ������� ������� �� SELL
     cur_price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
     minProfitR = (int) MathAbs((slR - cur_price) / _Point);
     //���������� SL  � minProfitR...  
     pos_inf.sl = minProfitR * 0.8;
     trailingR.minProfit = minProfitR;
     trailingR.trailingStop  = minProfitR;
     Print("cur_pice = ",cur_price);
     Print("SL = ", pos_inf.sl, " minProfitR = ", minProfitR);
     ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trailingR, 0);
     type_of_trade = 0;
    }
   }
  }
 }
 
 //------------------���� ��� ������� BUY-------------------
 if (type_of_trade == BUY)         
 {
  if(trendContinue)                 
  { 
   if(buf_type_candle[0] == 3)         //���� ����� ����
    if(CopyCurrentLowPrice(0))         //���� ����������� ������    
     slR = current_price[0];           //������� ������� ���� � slR
    else 
     return;
   else
   {
   trendContinue = false;              //����������� ������ �����������
   }
  }
  else
  { 
   if(buf_type_candle[0] == 3)         //���� ����� ����
   {
    Print("BUY: ��������� ����� ���� �������� ������!!");
    type_of_trade = 0;
   }
   else
   {
    if(buf_type_candle[0] == 1 || buf_type_candle[0] == 5)//���� ����������� ��������� ��� ����� �����
    {
     Print("BUY: ��������� ����� �����, ��������� �������!");
     //��������� � ������� ������� �� BUY
     cur_price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     minProfitR = (int) MathAbs((slR - cur_price) / _Point);  
     //���������� SL  � minProfitR...  
     pos_inf.sl = minProfitR * 0.8;
     trailingR.trailingStop  = minProfitR; 
     trailingR.minProfit     = minProfitR;
     trailingR.trailingStop  = minProfitR;
     Print("cur_pice = ",cur_price);
     Print("SL = ", pos_inf.sl, " minProfitR = ", minProfitR);
     ctm.OpenUniquePosition(_Symbol,_Period, pos_inf, trailingR, 0);
     type_of_trade = 0;
    }
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
 //��� ������� �������!  
 //int id1 = CatchEventfrom();
 //int id2 =
 
 //�������� ��� ������� ����� �� ������ ���� ������� OnChartEvent() ����� ������ OnTick()
 type_candle_copied = CopyBuffer(handlePriceBasedIndicator, 4, 0, 1, buf_type_candle);
 if(type_candle_copied <= 0)
 {
  Print("�� ������� ����������� ������ � ���������� PriceBasedIndicator");
  return;
 }
 //------------���� ��� ������ ������ ����������� �� SELL----------------
 if (sparam == "SELL")
 {
  type_of_trade = SELL;
  pos_inf.type = OP_SELL;
  if(buf_type_candle[0] == 1)       //���� ������� ��� ���������� ���� � ����������� ������
  {
   Print("������� ������ SELL � ���������� ���� trendContinue");
   trendContinue = true;
  }
  else
  {
   slR = dparam;                    //������� ������� ���� � slR
   Print("BUY slR = ",slR);
  }
 }
 //------------���� ��� ������ ������ ����������� �� BUY----------------
 if (sparam == "BUY")
 {
  type_of_trade = BUY;
  pos_inf.type = OP_BUY;
  if(buf_type_candle[0] == 3)       //���� ������� ��� ���������� ���� � ����������� ������
  {
   Print("������� ������ BUY � ���������� ���� trendContinue");
   trendContinue = true;
  }
  else
  {
    slR = dparam;                   //������� ������� ���� � slR
    Print("BUY slR = ",slR);
  }
 } 
}



bool CopyCurrentHighPrice(int index)
{
 price_copied  = CopyHigh(_Symbol, _Period, index, 1, current_price);
 if(price_copied != 1)
 {
  Print("������! �� ������� ����������� ������� ���� High");  
  return false;
 }
 return true;
}
bool CopyCurrentLowPrice(int index)
{
 price_copied  = CopyLow(_Symbol, _Period, index, 1, current_price);
 if(price_copied != 1)
 {
  Print("������! �� ������� ����������� ������� ���� High");  
  return false;
 }
 return true;
}
