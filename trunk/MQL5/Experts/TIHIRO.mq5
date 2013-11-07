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
input int      takeProfit=0;   //take profit
input int      stopLoss=0;     //stop loss
input double   orderVolume = 1;  //������ ����
input ulong    magic = 111222;   //���������� �����
input bool trailing = false;     //��������
//������ ��� �������� ��� 
double price_high[];      // ������ ������� ���  
double price_low[];       // ������ ������ ���  
datetime price_date[];    // ������ ������� 
//������
string symbol=_Symbol;
//���������
ENUM_TIMEFRAMES timeFrame = _Period; 
//�����
double point = _Point;
//������� �������
CTihiro       tihiro(symbol,timeFrame,point,bars); // ������ ������ CTihiro   
CisNewBar     newCisBar;    // ��� �������� �� ����� ���
CTradeManager ctm;          // ������ ������ TradeManager

double trendLineDown[];
double trendLineUp[];
int handle;

int OnInit()
  {
  handle = iCustom(symbol, timeFrame, "TihiroIndicator",50); //��������� ����� ���������� Tihiro
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
   int errPBI;
   ctm.OnTick();
   //���� ����������� ����� ���
   if ( newCisBar.isNewBar() > 0 )
    {
     errPBI = CopyBuffer(handle, 0, 0, bars, trendLineDown); //�������� ����� TihiroIndicator
     errPBI = CopyBuffer(handle, 1, 0, bars, trendLineUp); //�������� ����� TihiroIndicator     
     if(errPBI < 0)
     {
      Alert("�� ������� ����������� ������ �� ������������� ������"); 
      return; 
     }    
     tihiro.OnNewBar();
    }
   //�������� ������ 
   signal = tihiro.GetSignal(); 
   if (signal == BUY)
    {
    Comment("���� ������ = ",tihiro.GetTakeProfit());
    ctm.OpenUniquePosition(symbol,OP_BUY,orderVolume,stopLoss,tihiro.GetTakeProfit()/_Point,0,0,0);
    }
   if (signal == SELL)
    {
    Comment("���� ������ = ",tihiro.GetTakeProfit());
    ctm.OpenUniquePosition(symbol,OP_SELL,orderVolume,stopLoss,tihiro.GetTakeProfit()/_Point,0,0,0); 
    }
    
       if (trailing)
   {
    ctm.DoTrailing();
   }
  }