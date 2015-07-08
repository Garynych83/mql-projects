//+------------------------------------------------------------------+
//|                                                 EvgenysBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Brain.mqh>
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������
#include <DrawExtremums/CExtrContainer.mqh>   // ��������� ����������� (����������� ������� ����� ��������� ���������� �������)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double percent = 0.1; // ��� ���������� �������� (������ ����� ������ ����������)

 
class CEvgenysBrain: CBrain
{
private:
 CisNewBar *_isNewBar;
 CContainerBuffers *_conbuf;
 CExtrContainer *_extremums; // ��������� �����������
 CExtremum *extr1; //��� ���������� ��������� (���������� �������� � ��.)
 CExtremum *extr2;
 CExtremum *extr3; 
 CExtremum *extr4;
 ENUM_TIMEFRAMES _period;
 ENUM_TM_POSITION_TYPE signalPositionType;
 string _symbol;
 int _trend;       // ������� ����� 1-� ����
 int _prevTrend;   // ���������� �����
 int _magic;       // ���������� ����� ��� ����� ������
 ENUM_SIGNAL_FOR_TRADE _current_direction; // ������������ ���������� ������� (SEll, BUY, DISCORD(0) - �������� ���������)
 double curBid;   // ������� ���� bid
 double curAsk;   // ������� ���� Ask
 double prevBid;  // ���������� ���� bid
 double priceTrendUp; // ���� ������� ����� ������
 double priceTrendDown; // ���� ������ ����� ������
 double H1,H2; // ���������� ����� ������������
 double channelH; // ������ ������
 double horPrice;
 double pbiMove; // �������� �������� �� PBI � ������� ������
 // ������� � ������
 MqlRates rates[]; // ����� ���������
 CChartObjectTrend  trendLine; // ������ ������ ��������� �����
 CChartObjectHLine  horLine; // ������ ������ �������������� �����

public:
                     CEvgenysBrain(string symbol, ENUM_TIMEFRAMES period, CExtrContainer *extremums, CContainerBuffers *conbuf);
                    ~CEvgenysBrain();
            virtual ENUM_TM_POSITION_TYPE GetSignal();
            virtual long GetMagic(){return _magic;}
            virtual ENUM_SIGNAL_FOR_TRADE GetDirection(){return _current_direction;}
            virtual ENUM_TIMEFRAMES GetPeriod(){return _period;}
            virtual string  GetName(){return StringFormat("CEvgenysBrain_%s",PeriodToString(_period));};
            virtual int  CountTakeProfit();
            virtual int  CountStopLoss();
            virtual int  GetPriceDifference();
            virtual int  GetExpiration();
                    int  CountStopLossForTrendLines();
                    int  IsTrendNow();
                    void UploadOnEvent();
                    bool CheckClose();
                    void DrawLines();
                    void DeleteLines();
                    
                    
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CEvgenysBrain::CEvgenysBrain(string symbol,ENUM_TIMEFRAMES period, CExtrContainer *extremums, CContainerBuffers *conbuf) // ������ �����  � �������� CExtrContainer
{
 _trend = 0;       // ������� ����� 1-� ����
 _prevTrend = 0;   // ���������� �����
 _current_direction = SELL;
 _symbol = symbol;
 _period = period;
 _isNewBar = new CisNewBar(_symbol, _period);
 _isNewBar.isNewBar();
 _extremums = extremums;
 _conbuf = conbuf;
 _trend = IsTrendNow();
  if (_trend)
  {
   // ������ ����� 
   DrawLines ();    
  }
  
 // ��������� ����  
 curBid = SymbolInfoDouble(_symbol, SYMBOL_BID);   // ����� �� ������������ ������, ���� ����� ������� ������ ����� ������
 curAsk = SymbolInfoDouble(_symbol, SYMBOL_ASK);
 prevBid = curBid;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CEvgenysBrain::~CEvgenysBrain()
{
 DeleteLines ();
 delete _isNewBar;
}
//+------------------------------------------------------------------+

ENUM_TM_POSITION_TYPE CEvgenysBrain::GetSignal()
{
 curBid = SymbolInfoDouble(_symbol,SYMBOL_BID); 
 curAsk = SymbolInfoDouble(_symbol,SYMBOL_ASK);
 signalPositionType = OP_UNKNOWN;
  
 if (CheckClose()) // ������ ������� return DISCORD
 { 
  _current_direction = NO_SIGNAL;
  signalPositionType = OP_UNKNOWN;
  return signalPositionType;
 }

  // ���� ������� �������� - ����� 1-� ���� �����
 if (_trend == 1)
 {
  // ���� ������������� ����� ���
  if (_isNewBar.isNewBar() > 0)
  {
   priceTrendUp = ObjectGetValueByTime(0,"trendUp", TimeCurrent());
   priceTrendDown = ObjectGetValueByTime(0,"trendDown", TimeCurrent());   
   channelH = priceTrendUp - priceTrendDown;   // �������� ������ ������
   log_file.Write(LOG_DEBUG, StringFormat("channelH(%f) = priceTrendUp(%f) - priceTrendDown(%f)", channelH, priceTrendUp, priceTrendDown));  
   //PrintFormat("Close[1] (%f) > Open[1] (%f) && Close[2] (%f) < Open[2] (%f) && |curBid - priceTrendDown| (%f) < channelH*0.2 (%f)", 
   //_conbuf.GetClose(_period).buffer[1],_conbuf.GetOpen(_period).buffer[1],_conbuf.GetClose(_period).buffer[2], _conbuf.GetOpen(_period).buffer[2],curBid-priceTrendDown,channelH*0.2);   
   // ���� ���� �������� �� ��������� ���� ���� ���� �������� (� ���� �������), � �� ���������� ���� - �������� ���������
   if ( GreatDoubles(_conbuf.GetClose(_period, 1), _conbuf.GetOpen(_period, 1)) && LessDoubles(_conbuf.GetClose(_period, 2),_conbuf.GetOpen(_period, 2)) &&  // ���� ��������� ��� �������� � ���� �������, � ������� - � ���������������
        LessOrEqualDoubles(MathAbs(curBid-priceTrendDown), channelH * 0.2)                             // ���� ������� ���� ��������� ����� ������ ������� ������ ������ 
      )
   {
    log_file.Write(LOG_DEBUG, StringFormat("Close[1] (%f) > Open[1] (%f) && Close[2] (%f) < Open[2] (%f) && |curBid(%f) - priceTrendDown| (%f) < channelH*0.2 (%f)", 
    _conbuf.GetClose(_period).buffer[1],_conbuf.GetOpen(_period).buffer[1],_conbuf.GetClose(_period).buffer[2], _conbuf.GetOpen(_period).buffer[2],curBid, MathAbs(curBid-priceTrendDown),channelH*0.2));
    _current_direction = BUY;
    signalPositionType = OP_BUY;

   }
  }
 }
 // ���� ������� �������� - ����� 1-� ���� ����
 if (_trend == -1)
 {
  // ���� ������������� ����� ���
  if (_isNewBar.isNewBar() > 0)
  {
   priceTrendUp = ObjectGetValueByTime(0,"trendUp", TimeCurrent());
   priceTrendDown = ObjectGetValueByTime(0,"trendDown", TimeCurrent());   
   channelH = priceTrendUp - priceTrendDown;   // �������� ������ ������   
   // ���� ���� �������� �� ��������� ���� ���� ���� �������� (� ���� �������), � �� ���������� ���� - �������� ���������
   if ( LessDoubles(_conbuf.GetClose(_period,1), _conbuf.GetOpen(_period,1)) && GreatDoubles(_conbuf.GetClose(_period,2),_conbuf.GetOpen(_period,2)) &&  // ���� ��������� ��� �������� � ���� �������, � ������� - � ���������������
        LessOrEqualDoubles(MathAbs(curBid-priceTrendUp),channelH * 0.2)                             // ���� ������� ���� ��������� ����� ������ ������� ������ ������ 
      )
   {
   log_file.Write(LOG_DEBUG, StringFormat("Close[1] (%f) < Open[1] (%f) && Close[2] (%f) > Open[2] (%f) && |curBid(%f) - priceTrendDown| (%f) < channelH*0.2 (%f)", 
    _conbuf.GetClose(_period,1),_conbuf.GetOpen(_period,1),_conbuf.GetClose(_period,2), _conbuf.GetOpen(_period,2),curBid, MathAbs(curBid-priceTrendDown),channelH*0.2));
    _current_direction =  SELL;
    signalPositionType = OP_SELL;
   }
  }
 } 

 prevBid = curBid;
 if (_trend != 0)
  _prevTrend = _trend; 
  
 return signalPositionType;
}

bool CEvgenysBrain::CheckClose()
{
 if (_prevTrend == -_trend)
  return true;
 else
  return false;
}


// ������ true, ���� ����� �������
int  CEvgenysBrain::IsTrendNow ()
{
 double h1,h2;
 extr1 = _extremums.GetFormedExtrByIndex(0, EXTR_BOTH);
 extr2 = _extremums.GetFormedExtrByIndex(1, EXTR_BOTH);
 extr3 = _extremums.GetFormedExtrByIndex(2, EXTR_BOTH);
 extr4 = _extremums.GetFormedExtrByIndex(3, EXTR_BOTH);
 
 // ��������� ���������� h1, h2
 h1 = MathAbs(extr1.price - extr3.price);
 h2 = MathAbs(extr2.price - extr4.price);
 // ���� ����� ����� 
 log_file.Write(LOG_DEBUG, StringFormat("extr1 = %f extr2 = %f extr3 = %f extr4 = %f ", extr1.price,extr2.price,extr3.price,extr4.price));
 if (GreatDoubles(extr1.price,extr3.price) && GreatDoubles(extr2.price,extr4.price)) // ����� ���������� �������� (����� ��� - ����� -�������)
 {
  // ���� ��������� ��������� - ����
  if (extr1.direction == -1) 
  {
   H1 = extr2.price - extr3.price;
   H2 = extr4.price - extr1.price;
   // ���� ���� ��������� ����� ��� �������������
   if (GreatDoubles(h1, H1*percent) && GreatDoubles(h2, H2*percent) )
   {
    log_file.Write(LOG_DEBUG, " � ��� � ����� ����� �������������");
    return (1);
   }
  }
 }
 // ���� ����� ����
 if (LessDoubles(extr1.price,extr3.price) && LessDoubles(extr2.price,extr4.price))
 {
  // ����  ��������� ��������� - �����
  if (extr1.direction == 1)
  {
   H1 = extr2.price - extr3.price;
   H2 = extr4.price - extr1.price;
   // ���� ���� ����������� ����� ��� �������������
   if (GreatDoubles(h1, H1 * percent) && GreatDoubles(h2, H2 * percent))    
   log_file.Write(LOG_DEBUG, " � ��� � ����� ���� �������������");
    return (-1);
  }
 }   
 return (0);   
}

// ������� ������������ ����� �� �����������  
void CEvgenysBrain::DrawLines()
{
 // �� ������� ����� �� ������
 if (extr1.direction == 1)
 {
  trendLine.Create(0,"trendUp",0,extr3.time,extr3.price,extr1.time, extr1.price);   // �������  �����
  ObjectSetInteger(0,"trendUp",OBJPROP_RAY_RIGHT,1);
  trendLine.Create(0,"trendDown",0,extr4.time,extr4.price,extr2.time,extr2.price); // ������  �����
  ObjectSetInteger(0,"trendDown",OBJPROP_RAY_RIGHT,1);   
  if (_trend == 1)
  {
   horLine.Create(0,"horLine",0,extr1.price); // �������������� �����    
   horPrice = extr1.price;    
  } 
  if (_trend == -1)
  {
   horLine.Create(0,"horLine",0,extr2.price); // �������������� �����       
   horPrice = extr1.price;         
  }        
 }
 // �� ������� ����� �� ������
 if (extr1.direction == -1)
 {
  trendLine.Create(0, "trendDown", 0, extr3.time, extr3.price, extr1.time, extr1.price); // ������  �����
  ObjectSetInteger(0, "trendDown", OBJPROP_RAY_RIGHT, 1);
  trendLine.Create(0, "trendUp", 0, extr4.time, extr4.price, extr2.time, extr2.price);   // �������  �����
  ObjectSetInteger(0, "trendUp", OBJPROP_RAY_RIGHT, 1);   
  if (_trend == 1)
  {
   horLine.Create(0,"horLine", 0, extr2.price); // �������������� �����     
   horPrice = extr2.price;           
  } 
  if (_trend == -1)
  {
   horLine.Create(0,"horLine", 0, extr1.price); // �������������� �����      
   horPrice = extr1.price;          
  }          
 }   
} 

// ������� ������� ����� � �������
void CEvgenysBrain::DeleteLines()
{
 ObjectDelete(0,"trendUp");
 ObjectDelete(0,"trendDown");
 ObjectDelete(0,"horLine");
}

// ������� ��������� ���� ���� ��� ��������� �����
int CEvgenysBrain::CountStopLossForTrendLines()
 {
  // ���� ����� �����
  if (_trend == 1)
   {
    return (int((MathAbs(curBid-extr1.price) + H1*percent)/_Point));
   }
  // ���� ����� ����
  if (_trend == -1)
   {
    return (int((MathAbs(curAsk-extr1.price) - H1*percent)/_Point));
   }   
  return (0);
 }
//---------------------------------------------------------------------------+
//         ������� UploadOnEvent()                                           |
//       �������� � ������� OnChartEvent() ��� ��������� �������             | 
//       � �������������� ���������� (������� ��� ������)                    |
//---------------------------------------------------------------------------+
void CEvgenysBrain::UploadOnEvent(void)
{
   // ������� ����� � �������
  DeleteLines();
  log_file.Write(LOG_DEBUG, " ���������� �� ������� ������ �� �������");
  _trend = IsTrendNow();
  if (_trend)
  {  
   // �������������� �����
   DrawLines();     
  }   
}

int CEvgenysBrain::CountStopLoss(void)
{
 int stop_level;
 int sl;
 stop_level = (int)SymbolInfoInteger(_symbol, SYMBOL_TRADE_STOPS_LEVEL);
 sl = CountStopLossForTrendLines();
 if(sl > stop_level)
  return sl;
 else
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������������ �������� �� ������������� ��������� sl = %d", MakeFunctionPrefix(__FUNCTION__), stop_level));
  return stop_level;
 }
}

int CEvgenysBrain::CountTakeProfit()
{
 return 10 * CountStopLoss();
}
