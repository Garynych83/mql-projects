//+------------------------------------------------------------------+
//|                                                       TIHIRO.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <JAPAN\jExperts\CTihiro.mqh>      //����� CTihiro
#include <Lib CisNewBar.mqh>               //��� �������� ������������ ������ ����
#include <TradeManager\TradeManager.mqh>   //���������� ���������� TradeManager
#include <TradeManager\BackTest.mqh>       //�������
#include <Graph\Widgets\WBackTest.mqh>
#include <TradeManager\GetBackTest.mqh>

#include <TradeManager\TradeBreak.mqh>     //�������� ��������

#import "kernel32.dll"
int      WinExec(uchar &NameEx[], int dwFlags);
#import

//+------------------------------------------------------------------+
//| �������� ����� ��� �������������������                           |
//| �� ���������������� - ������-������� TIHIRO                      |
//+------------------------------------------------------------------+

//�������, ���������� ������������� ��������� ��������
input uint              bars=500;                   //���������� ����� �������
input double            orderVolume = 1;            //������ ����
input TAKE_PROFIT_MODE  takeprofitMode = TPM_HIGH;  //����� ���������� ���� �������
input double            takeprofitFactor = 1.0;     //����������� ���� �������  
input int               priceDifferent=10;          //������� ��� ��� ������ �����������
input double            min_profit=-3;               //����������� ������� �������
input double            max_drawdown=3;             //������������ ������� ��������
//������
string symbol=_Symbol;
//���������
ENUM_TIMEFRAMES timeFrame = _Period; 
//�����
double point = _Point;
//������� �������
CTihiro       tihiro(symbol,timeFrame,point,bars,takeprofitMode,takeprofitFactor,priceDifferent); // ������ ������ CTihiro   
CisNewBar     isNewBar;                            // ��� �������� �� ����� ���
CTradeManager ctm;                                 // ������ ������ TradeManager
TradeBreak  * tb  = new TradeBreak (min_profit,max_drawdown);  // ����� ������ TradeBreak
int handle;                                        // ����� ����������
bool allow_continue = true;                        // ���� ����������� 
ENUM_TM_POSITION_TYPE signal;                      // ���������� ��� �������� ��������� �������

datetime  currentTime;                             // ������� ����� 
int count=0;                                       // ������� 

int OnInit()
{
 //��������� ����� ���������� Tihiro
 handle = iCustom(symbol, timeFrame, "test_PBI"); 
 int han = iCustom(symbol,timeFrame,"WBackTest");
 //��������� �������� �������� � ����� ������ ������ ��������
 //WBackTest * wBackTest = new WBackTest("backtest","���������� ��������",5,12,200,50,0,0,CORNER_LEFT_UPPER,0);
 currentTime = TimeCurrent();
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
  {

  }



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
  
 void OnTrade()
  {
    if (count<3)
      count++;
    else
     {
      if ( tb.UpdateData(ctm.GetPositionHistory(currentTime,TimeCurrent()) ) )
       Alert("����� ��������� �� ���������");
      count=0;
     }
  }
  
// ����� ��������� �������  
void OnChartEvent(const int id,
                const long &lparam,
                const double &dparam,
                const string &sparam)
  { 
   // ���� ������ ������
   if(id==CHARTEVENT_OBJECT_CLICK)
    {
     // ��������� ���� ������� ������

       if (sparam == "backtest_all_expt")     // ������ "��� ��������"
        {
         CalculateBackTest (0,TimeCurrent());
         Alert("��� ��������");
        }
       if (sparam == "backtest_cur_expt")     // ������ "���� �������"
        {
         Print("������� �������");       
        }
       if (sparam == "backtest_close_button") // ������ �������� ������
        {
          Print("�������� ������");  
          uchar val[];
          StringToCharArray ("mspaint.exe",val);
          Alert("",WinExec(val, 1));     
        }
    }
  } 