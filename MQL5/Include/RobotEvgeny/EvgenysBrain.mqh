//+------------------------------------------------------------------+
//|                                                 EvgenysBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Lib CisNewBarDD.mqh>                // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>                 // ��� ��������� ������������ �����
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������
#include <DrawExtremums/CExtrContainer.mqh>   // ��������� ����������� (����������� ������� ����� ��������� ���������� �������)
#include <ContainerBuffers.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double percent = 0.1; // ��� ���������� �������� (������ ����� ������ ����������)


// ������������ ��� �������� ��������
enum ENUM_SIGNAL_FOR_TRADE
{
 SELL = -1,     // �������� ������� �� �������
 BUY  = 1,      // �������� ������� �� �������
 NO_SIGNAL = 0, // ��� ��������, ����� ������� �� �������� ������� �� ����
 DISCORD = 2,   // ������ ������������, "������ �������"
};

 
class CEvgenysBrain
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
 ENUM_SIGNAL_FOR_TRADE signalForTrade;
 string _symbol;
 int _countTotal;  // ����� �����������
 int _trend;       // ������� ����� 1-� ����
 int _prevTrend;   // ���������� �����
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
                     CEvgenysBrain(string symbol,ENUM_TIMEFRAMES period, CExtrContainer *extremums, CContainerBuffers *conbuf);
                    ~CEvgenysBrain();
                    int GetSignal();
                    int CountStopLossForTrendLines();
                    int IsTrendNow();
                    void UploadOnEvent();
                    bool CheckClose();
                    bool UploadExtremums();
                    void DrawLines();
                    void DeleteLines();
                    
                    
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CEvgenysBrain::CEvgenysBrain(string symbol,ENUM_TIMEFRAMES period, CExtrContainer *extremums, CContainerBuffers *conbuf) // ������ �����  � �������� CExtrContainer
{
 _countTotal = 0;  // ����� �����������
 _trend = 0;       // ������� ����� 1-� ����
 _prevTrend = 0;   // ���������� �����
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
 curBid = SymbolInfoDouble(_symbol,SYMBOL_BID);   // ����� �� ������������ ������, ���� ����� ������� ������ ����� ������
 curAsk = SymbolInfoDouble(_symbol,SYMBOL_ASK);
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

int CEvgenysBrain::GetSignal()
{
 curBid = SymbolInfoDouble(_symbol,SYMBOL_BID); 
 curAsk = SymbolInfoDouble(_symbol,SYMBOL_ASK);
 signalForTrade =  NO_SIGNAL;
  // ���� ������� �������� - ����� 1-� ���� �����
 if (_trend == 1)
 {
  // ���� ������������� ����� ���
  if (_isNewBar.isNewBar() > 0)
  {
   priceTrendUp = ObjectGetValueByTime(0,"trendUp",TimeCurrent());
   priceTrendDown = ObjectGetValueByTime(0,"trendDown",TimeCurrent());   
   channelH = priceTrendUp - priceTrendDown;   // �������� ������ ������   
   // ���� ���� �������� �� ��������� ���� ���� ���� �������� (� ���� �������), � �� ���������� ���� - �������� ���������
   if ( GreatDoubles(_conbuf.GetClose(_period).buffer[2], _conbuf.GetOpen(_period).buffer[2]) && LessDoubles(_conbuf.GetClose(_period).buffer[1],_conbuf.GetOpen(_period).buffer[1]) &&  // ���� ��������� ��� �������� � ���� �������, � ������� - � ���������������
        LessOrEqualDoubles(MathAbs(curBid-priceTrendDown),channelH*0.2)                             // ���� ������� ���� ��������� ����� ������ ������� ������ ������ 
      )
   {
    signalForTrade = BUY;
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
   if ( LessDoubles(_conbuf.GetClose(_period).buffer[2], _conbuf.GetOpen(_period).buffer[2]) && GreatDoubles(_conbuf.GetClose(_period).buffer[1],_conbuf.GetOpen(_period).buffer[1]) &&  // ���� ��������� ��� �������� � ���� �������, � ������� - � ���������������
        LessOrEqualDoubles(MathAbs(curBid-priceTrendUp),channelH * 0.2)                             // ���� ������� ���� ��������� ����� ������ ������� ������ ������ 
      )
   {
    signalForTrade =  SELL;
   }
  }
 }    
 prevBid = curBid;
 if (_trend != 0)
  _prevTrend = _trend; 
 return signalForTrade;
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
 if (GreatDoubles(extr1.price,extr3.price) && GreatDoubles(extr2.price,extr4.price)) // ����� ���������� �������� (����� ��� - ����� -�������)
 {
  // ���� ��������� ��������� - ����
  if (extr1.direction == -1) 
  {
   H1 = extr2.price - extr3.price;
   H2 = extr4.price - extr1.price;
   // ���� ���� ��������� ����� ��� �������������
   if (GreatDoubles(h1, H1*percent) && GreatDoubles(h2, H2*percent) )
    return (1);
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
  trendLine.Create(0,"trendDown", 0, extr3.time, extr3.price, extr1.time, extr1.price); // ������  �����
  ObjectSetInteger(0,"trendDown", OBJPROP_RAY_RIGHT, 1);
  trendLine.Create(0,"trendUp", 0, extr4.time, extr4.price, extr2.time, extr2.price); // �������  �����
  ObjectSetInteger(0,"trendUp", OBJPROP_RAY_RIGHT, 1);   
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
void CEvgenysBrain::DeleteLines ()
{
 ObjectDelete(0,"trendUp");
 ObjectDelete(0,"trendDown");
 ObjectDelete(0,"horLine");
}

// ������� ��������� ���� ���� ��� ��������� �����
int CEvgenysBrain::CountStopLossForTrendLines ()
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
  _trend = IsTrendNow();
  if (_trend)
  {  
   // �������������� �����
   DrawLines();     
  }   
}