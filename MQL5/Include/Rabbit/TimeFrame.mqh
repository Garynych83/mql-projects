//+------------------------------------------------------------------+
//|                                                    TimeFrame.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBarDD.mqh>
//+------------------------------------------------------------------------------------------------------------+
//|                           ����� TimeFrame �������� ����������, ������� ����� ������� � ����������� ��      |
//| ����� ��������� ������ � ��������, ����������� ��� �� (ATR, DE � ��.), ������ ��������� ���������� isNewBar|
//| ����� �������� �� �1, �5, �15. ��� ���������� ����� �������� ���������� ������ ��������� � ��� ��������:   |
//|                       //-GetBottom()                                                                       |
//+------------------------------------------------------------------------------------------------------------+
class CTimeFrame: public CObject
{
 private:
   string _symbol;
   ENUM_TIMEFRAMES _period;
   CisNewBar *_isNewBar;   //ContainerBuffer
   int   _handleATR;
   int   _handleDE;
   bool  _isTrendNow; //�� ���� ��� �����������. �������� �� _trend.IsTrendNow();
   int   _signalTrade;
   double   _supremacyPercent;
 public: 
   //�����������
   CTimeFrame(ENUM_TIMEFRAMES period, string symbol, 
                           int handleATR, int   handleDE);
   ~CTimeFrame();
   //������� ��� ������ � ������� CTimeFrame
   ENUM_TIMEFRAMES GetPeriod()   {return _period;}
   bool            IsThisNewBar(){return _isNewBar.isNewBar();}
   bool            IsThisTrendNow(){return _isTrendNow;}
   int             GetHandleATR(){return _handleATR;}
   int             GetHandleDE() {return _handleDE;}
   int             GetSignal()   {return _signalTrade;}
   double          GetRatio()    {return _supremacyPercent;}
   void            SetRatio(double prc){_supremacyPercent = prc;} 
   void            SetSignal(int signalTrade)     {_signalTrade = signalTrade;}
   void            SetTrendNow(bool isTrendNow) {_isTrendNow = isTrendNow;}
  // bool            isTrendNow()  {return _trend.IsTrendNow();}
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTimeFrame::CTimeFrame(ENUM_TIMEFRAMES period, string symbol, 
                           int handleATR, int   handleDE)
{
 _symbol = symbol;
 _period = period;
 _isNewBar = new CisNewBar(symbol,period);
 _handleATR = handleATR;
 _handleDE = handleDE;
 //  ��� � ���? _isTrendNow = fal;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTimeFrame::~CTimeFrame()
  {
  }
//+------------------------------------------------------------------+
