//+------------------------------------------------------------------+
//|                                                      CRabbit.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ����� ������ "������"                                            |
//+------------------------------------------------------------------+
#include <CTrendChannel.mqh> // ��������� ������� 
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <CTrendChannel.mqh> // ��������� ���������
//���������
#define KO 3 //����������� ��� ������� �������� �������, �� ������� ��� ������� ����������� ���� ������ ������ ��������� ����������� ���� ����
#define SPREAD 30 // ������ ������ 

class CRabbit 
 {
  private:
   string _symbol; // ������
   ENUM_TIMEFRAMES _period; // ������
   int _handleDE; // ����� DrawExtremums
   int _handleATR; // ����� ATR  
   int _stopLoss; // ���� ����
   int _takeProfit; // ���� ������ 
   double _percent; // ������� ���������� ������� 
   double _supremacyPercent; // �������, �� ������� ��� ������ �������� ��������
   double _profitPercent; // ������� �������
   CTrendChannel *_trendChannel; // ��������� �������
   // ��������� ������ ������
   int CountStopLoss (int point); // ��������� ���� ����
  public:
   CRabbit (string symbol, ENUM_TIMEFRAMES period,double supremacyPercent,double profitPercent); // ����������� 
  ~CRabbit (); // ����������
  // ������ ������
  int GetSignal (); // ����� ���������� ������ �������� 
  int GetStopLoss () { return(_stopLoss); }; // ���������� ���� ����
  int GetTakeProfit () { return (_takeProfit); }; // ���������� ���� ������
  // ������� ������� 
 };
 
 // ����������� ������� ������ 
 int CRabbit::CountStopLoss(int point)  // ��������� ���� ����
  {
   MqlRates rates[];
   double price;
   if (CopyRates(_symbol,_period,1,1,rates) < 1)
    {
     return (0);
    }
   // ���� ����� ����������� �����
   if (point == 1)
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
    }
   // ���� ����� ��������� ����
   if (point == -1)
    {
     price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    }    
   return( int( MathAbs(price - (rates[0].open+rates[0].close)/2) / _Point) );   
  }

 
 CRabbit::CRabbit(string symbol,ENUM_TIMEFRAMES period,double supremacyPercent,double profitPercent) // ����������� �������
  {
   // ��������� ���� ������
   _symbol = symbol;
   _period = period;
   _supremacyPercent = supremacyPercent;
   _percent = 0.1;
   // ������� ��������� DrawExtremums
   _handleDE = DoesIndicatorExist(_symbol,_period,"DrawExtremums");
   if (_handleDE == INVALID_HANDLE)
    {
     _handleDE = iCustom(_Symbol,_period,"DrawExtremums");
     if (_handleDE == INVALID_HANDLE)
      {
       Print("�� ������� ������� ����� ���������� DrawExtremums");
       return;
      }
     SetIndicatorByHandle(_symbol,_period,_handleDE);
    }
   // ��������� ATR
   _handleATR = iMA(_symbol,_period,100,0,MODE_EMA,iATR(_symbol,_period,30));         
   _trendChannel = new CTrendChannel(0,_symbol,_period,_handleDE,_percent);
  }
 
 CRabbit::~CRabbit(void) // ���������� �������
  {
   // �������� ��������
   delete _trendChannel; 
  }
  
 
 // ����� ���������� ������ �������� 
 int CRabbit::GetSignal(void)
  {
   double close_buf[];
   double open_buf[];
   double ave_atr_buf[]; 
   int type = 0;
   //���� �� ������� ���������� ��� ������ 
   if (CopyClose  (_symbol,_period,1,1,close_buf)<1 ||
       CopyOpen   (_symbol,_period,1,1,open_buf)<1 ||
       CopyBuffer (_handleATR,0,0,1,ave_atr_buf)<1)
      {
       //�� ������� ��������� � ��� �� ������
       log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� ����������� ������ �� ������ �������� �������", MakeFunctionPrefix(__FUNCTION__)));    
       return (0);//� ������� �� ������� 
      }
      
   if (GreatDoubles(MathAbs(open_buf[0] - close_buf[0]), ave_atr_buf[0]*(1 + _supremacyPercent)))
    {
     if(LessDoubles(close_buf[0], open_buf[0])) // �� ��������� ���� close < open (��� ����)
      {     
       _takeProfit=(int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+_profitPercent));
       _stopLoss=CountStopLoss(-1);        
       //���� ����������� ���� ������ � kp ���� ��� ����� ��� ������, ��� ����������� ���� ����
       if(_takeProfit >= KO*_stopLoss)
        type = -1; // ����� ��������� �� SELL
       else
        {
         return (0); // �� �������� ������ �� ��������
        }   
       }
       
  if (GreatDoubles(close_buf[0], open_buf[0]))
   {     
    _takeProfit = (int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+_profitPercent));
    _stopLoss = CountStopLoss(1);
    // ���� ����������� ���� ������ � kp ���� ��� ����� ��� ������, ��� ����������� ���� ����
    if(_takeProfit >= KO*_stopLoss)
     type = 1; // ����� ��������� �� BUY
    else
     {
      return (0); // �� �������� ������ �� ��������
     }
   }

  }
   return ( type ); // ���������� ������ �� ��������
 }