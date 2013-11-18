//+------------------------------------------------------------------+
//|                                                       TIHIRO.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TIHIRO\CTihiro.mqh>            //����� CTihiro
#include <Lib CisNewBar.mqh>             //��� �������� ������������ ������ ����
#include <TradeManager/TradeManager.mqh> //���������� ���������� TradeManager

//+------------------------------------------------------------------+
//| TIHIRO �������                                                   |
//+------------------------------------------------------------------+
//�������, ���������� ������������� ��������� ��������
input uint              bars=500;                   //���������� ����� �������
input double            orderVolume = 1;            //������ ����
input TAKE_PROFIT_MODE  takeprofitMode = TPM_HIGH; //����� ���������� ���� �������
input double            takeprofitFactor = 1.0;     //����������� ���� �������  
//������
string symbol=_Symbol;
//���������
ENUM_TIMEFRAMES timeFrame = _Period; 
//�����
double point = _Point;
//������� �������
CTihiro       tihiro(symbol,timeFrame,point,bars,takeprofitMode,takeprofitFactor); // ������ ������ CTihiro   
CisNewBar     isNewBar;                            // ��� �������� �� ����� ���
CTradeManager ctm;                                 // ������ ������ TradeManager
int handle;                                        // ����� ����������
bool allow_continue = true;                        // ���� ����������� 
ENUM_TM_POSITION_TYPE signal;                      // ���������� ��� �������� ��������� �������

int OnInit()
{
 //��������� ����� ���������� Tihiro
 handle = iCustom(symbol, timeFrame, "TihiroIndicator",timeFrame); 
 //��������� �������� �������� � ����� ������ ������ ��������
 
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| TIHIRO ��������������� ��������                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //���� ���� ���������� ���������� ���������
   if (allow_continue) 
    {
     ctm.OnTick();
     //���� ����������� ����� ���
     if ( isNewBar.isNewBar() > 0 )
      {  
       allow_continue = tihiro.OnNewBar();
      }
     //�������� ������ 
     if (allow_continue)
      {
       signal = tihiro.GetSignal();   
       if (signal != OP_UNKNOWN)
        {      
         ctm.OpenUniquePosition(symbol,signal,orderVolume,tihiro.GetStopLoss(),tihiro.GetTakeProfit(),0,0,0); 
        }
      }
    }
  }