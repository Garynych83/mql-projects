//+------------------------------------------------------------------+
//|                                                       TIHIRO.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TIHIRO\CTihiro.mqh>           //����� CTihiro
#include <Lib CisNewBar.mqh>            //��� �������� ������������ ������ ����
#include <TradeManager/TradeManager.mqh> //���������� ���������� TradeManager

//+------------------------------------------------------------------+
//| TIHIRO �������                                                   |
//+------------------------------------------------------------------+
//�������, ���������� ������������� ��������� ��������
input uint     bars=50;          //���������� ����� �������
input int      takeProfit=100;   //take profit
input int      stopLoss=100;     //stop loss
input double   orderVolume = 1;  //������ ����
input ulong    magic = 111222;   //���������� �����
//������ ��� �������� ��� 
double price_high[];      // ������ ������� ���  
double price_low[];       // ������ ������ ���  
datetime price_date[];    // ������ ������� 
//������
string symbol=_Symbol;
//���������
ENUM_TIMEFRAMES timeFrame = _Period; 
//������� �������
CTihiro       tihiro(bars); // ������ ������ CTihiro   
CisNewBar     newCisBar;    // ��� �������� �� ����� ���
CTradeManager ctm;          // ������ ������ TradeManager


int OnInit()
  {
  
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| TIHITO ��������������� ��������                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   short signal;
   ctm.OnTick();
   //���� ����������� ����� ���
   if ( newCisBar.isNewBar() > 0 )
    {

     tihiro.OnNewBar(price_high,price_low);
    }
   //�������� ������ 
   signal = tihiro.OnTick(symbol); 
   if (signal == BUY)
    ctm.OpenUniquePosition(symbol,OP_BUY,orderVolume,stopLoss,takeProfit,0,0,0);
   if (signal == SELL)
    ctm.OpenUniquePosition(symbol,OP_SELL,orderVolume,stopLoss,takeProfit,0,0,0); 
  }

