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
input uint     bars=500;          //���������� ����� �������
input double   orderVolume = 1;  //������ ����
//������ ��� �������� ��� 
double price_high[];      // ������ ������� ���  
double price_low[];       // ������ ������ ���  
datetime price_date[];    // ������ ������� 
//����� ��� ���������� Parabolic SAR
double sar_buffer[1];
//������
string symbol=_Symbol;
//���������
ENUM_TIMEFRAMES timeFrame = _Period; 
//�����
double point = _Point;
//������� �������
CTihiro       tihiro(symbol,timeFrame,point,bars); // ������ ������ CTihiro   
CisNewBar     isNewBar;                            // ��� �������� �� ����� ���
CTradeManager ctm;                                 // ������ ������ TradeManager
int handle;                                        // ����� ����������
int handle_parabolic;                              // ����� ����������
bool allow_continue = true;                        // ���� ����������� 
ENUM_TM_POSITION_TYPE signal;                      // ���������� ��� �������� ��������� �������
int errTrendDown, errTrendUp;                      // ���������� ��� ������ �� �������

int OnInit()
{
 //��������� ����� ���������� Tihiro
 handle           = iCustom(symbol, timeFrame, "TihiroIndicator",timeFrame); 
 //����� ���������� 
 handle_parabolic = iSAR(symbol,timeFrame,0.02,0.2); 
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
       CopyBuffer(handle_parabolic, 0, 0, 1, sar_buffer); //�������� ����� Price Based Indicator       
      }
     //�������� ������ 
     if (allow_continue)
      {
       signal = tihiro.GetSignal();   
       if (signal != OP_UNKNOWN)
        {      
         Print(" ���� ������ = ", tihiro.GetTakeProfit());
         ctm.OpenUniquePosition(symbol,signal,orderVolume,tihiro.GetStopLoss(),tihiro.GetTakeProfit(),0,0,0); 
        }
      }
    }
  }