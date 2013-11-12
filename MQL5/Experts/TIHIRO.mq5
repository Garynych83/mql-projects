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
input double   orderVolume = 1;  //������ ����
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
CisNewBar     isNewBar;                           // ��� �������� �� ����� ���
CTradeManager ctm;                                 // ������ ������ TradeManager
int handle;
bool first_load = false;

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
   ENUM_TM_POSITION_TYPE signal;
   int errTrendDown, errTrendUp;
   bool allow_continue = true;   //���� ����������� 
   ctm.OnTick();
   //���� ����������� ����� ���
   
   if ( isNewBar.isNewBar() > 0 && first_load)
   {  
    allow_continue = tihiro.OnNewBar();
   }
   
   if (first_load == false)
   {
     allow_continue = tihiro.OnNewBar();
     first_load = true;
   }
   
   //�������� ������ 
   if (allow_continue)
   {
    signal = tihiro.GetSignal();   
    if (signal != OP_UNKNOWN)
    {      
     Print("���� ���� = ",tihiro.GetStopLoss(), " ���� ������ = ", tihiro.GetTakeProfit()," ����� = ",DoubleToString(_Point));
     ctm.OpenUniquePosition(symbol,signal,orderVolume,tihiro.GetStopLoss(),tihiro.GetTakeProfit(),0,0,0); 
    }
   }
  }