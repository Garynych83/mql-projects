//+------------------------------------------------------------------+
//|                                                 RabbitsBrain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <CompareDoubles.mqh>                // ��������� ������������ �����
#include <StringUtilities.mqh>               // ��������� ��������������
#include <CLog.mqh>                          // ��� ����
#include <ContainerBuffers.mqh>       // ��������� ������� ��� �� ���� �� (No PBI) - ��� ������� � ��
#include <CTrendChannel.mqh>                 // ��������� ���������
//#include <MoveContainer/CMoveContainer.mqh>  // ��������� �������� ����
#include <TradeManager/TradeManager.mqh>     // �������� ���������� 
#include <Lib CisNewBarDD.mqh>               // ��� �������� ������������ ������ ����
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������


enum ENUM_SIGNAL_FOR_TRADE
{
 SELL = -1,     // �������� ������� �� �������
 BUY  = 1,      // �������� ������� �� �������
 NO_SIGNAL = 0, // ��� ��������, ����� ������� �� �������� ������� �� ����
 DISCORD = 2,   // ������ ������������, "������ �������"
};

#define M1 5;   //�������, ��������� ��� M1 ������ �������� ��������
#define M5 3;   //�������, ��������� ��� M1 ������ �������� ��������
#define M15 1;  //�������, ��������� ��� M1 ������ �������� ��������
//+------------------------------------------------------------------------------------------------------------+
//|                           ����� TimeFrame �������� ����������, ������� ����� ������� � ����������� ��      |
//| ����� ��������� ������ � ��������, ����������� ��� �� (ATR, DE � ��.), ������ ��������� ���������� isNewBar|
//+------------------------------------------------------------------------------------------------------------+
class CTimeframeInfo: public CObject
{
 private:
   string _symbol;
   ENUM_TIMEFRAMES _period;
   CisNewBar *_isNewBar;   //ContainerBuffer
   int   _handleATR;
   bool  _isTrendNow; //�� ���� ��� �����������. �������� �� _trend.IsTrendNow();
   double _supremacyPercent;
 public: 
   //�����������
   CTimeframeInfo(ENUM_TIMEFRAMES period, string symbol, 
                           int handleATR);
   ~CTimeframeInfo();
   //������� ��� ������ � ������� CTimeframeInfo
   ENUM_TIMEFRAMES GetPeriod()   {return _period;}
   bool            IsThisNewBar(){return _isNewBar.isNewBar();}
   bool            IsThisTrendNow(){return _isTrendNow;}
   int             GetHandleATR(){return _handleATR;}
   double          GetRatio()    {return _supremacyPercent;}
   void            SetRatio(double prc){_supremacyPercent = prc;} 
   void            SetTrendNow(bool isTrendNow) {_isTrendNow = isTrendNow;}

};

CTimeframeInfo::CTimeframeInfo(ENUM_TIMEFRAMES period, string symbol, 
                           int handleATR)
{
 _symbol = symbol;
 _period = period;
 _isNewBar = new CisNewBar(symbol,period);
 _handleATR = handleATR;
}
//+------------------------------------------------------------------+

CTimeframeInfo::~CTimeframeInfo()
  {
  }

//+-----------------------------------------------------------------------------+
//|         ����� RabbitBrain ��������� ������ �� �������� SELL/BUY             |
//|    ��������� � ���� ���� �������� ������ Rabbit. ����������                 |
//| �������������� ����� CTimeframeInfo ��� �������� ���������� ��� ���������   |
//+-----------------------------------------------------------------------------+

class CRabbitsBrain
{
 private:
  static double const trendPercent;
  // ����, ������ � ������� ���������� ����� ������� Get...()
  int _handle19Lines;
  int _posOpenedDirection;
  int _indexPosOpenedTF;
  CTimeframeInfo *_posOpenedTF; // ��, �� ������� ���� ��������� ������
  string _symbol;
  CContainerBuffers *_conbuf;
  CArrayObj     *_trends;     // ������ ������� ������� (��� ������� �� ���� �����)
  CArrayObj     *_dataTFs;    // ������ ��, ��� �������� �� ���������� �� ������������
  CTrendChannel *trend;
  //CMoveContainer *trend;
  CTimeframeInfo *ctf;
  double atr_buf[1], open_buf[1];   // ��� ������� GetSignal
  int handleATR;
  int handleDE;
  int _sl;
  double Ks[3];
  ENUM_TIMEFRAMES TFs[3];
                    CTimeframeInfo *GetBottom(CTimeframeInfo *curTF);
                    bool LastBarInChannel (CTimeframeInfo *curTF);
                    bool TrendsDirection (CTimeframeInfo *curTF, int direction);
                    bool FilterBy19Lines (int direction, ENUM_TIMEFRAMES period, int stopLoss);
                    

 public:
                     CRabbitsBrain(string symbol, CContainerBuffers *conbuf);
                    ~CRabbitsBrain();
                    
                    int GetSignal();
                    int GetTradeSignal(CTimeframeInfo *TF);
                    bool UpdateBuffers();
                    bool UpdateTrendsOnHistory(int i);
                    bool UpdateOnEvent(long lparam, double dparam, string sparam, int countPos);
                    int  GetIndexTF(CTimeframeInfo *curTF);
                    void OpenedPosition(int ctmTotal);

                    int GetSL() {return _sl;}

                    

};
const double  CRabbitsBrain::trendPercent = 0.1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CRabbitsBrain::CRabbitsBrain(string symbol, CContainerBuffers *conbuf)
{
 _symbol = symbol;
 _conbuf = conbuf;
 TFs[0] = PERIOD_M1; TFs[1] = PERIOD_M5; TFs[2] = PERIOD_M15;
 Ks[0] = M1; Ks[1] = M5; Ks[2] = M15;
 //----------- ��������� ���������� NineTeenLines----------
 _handle19Lines = iCustom(_Symbol,_Period,"NineTeenLines");
 if (_handle19Lines == INVALID_HANDLE)
  Print("�� ������� ������� ����� ���������� NineTeenLines");
 _dataTFs = new CArrayObj();
 _trends = new CArrayObj();
 
 //�������� ������ ��������� 
 for(int i = 0; i < ArraySize(TFs); i++)
 {
  handleDE = DoesIndicatorExist(_Symbol, TFs[i], "DrawExtremums");
  if(handleDE == INVALID_HANDLE)
  {
   handleDE = iCustom(_Symbol, TFs[i], "DrawExtremums");
   if (handleDE == INVALID_HANDLE)
   {
    PrintFormat("�� ������� ������� ����� ���������� DrawExtremums �� %s", PeriodToString(TFs[i]));
    log_file.Write(LOG_DEBUG, StringFormat("�� ������� ������� ����� ���������� DrawExtremums �� %s", PeriodToString(TFs[i])));
   }
   else
   log_file.Write(LOG_DEBUG, StringFormat("handleDE = %d", handleDE));
  }
  
  handleATR = iMA(_Symbol, TFs[i], 100, 0, MODE_EMA, iATR(_Symbol, TFs[i], 30)); // �� ���� ����� �� ��������� ������� ����� ���������� �� ������ ��������
  if (handleATR == INVALID_HANDLE)
  {
   PrintFormat("�� ������� ������� ����� ���������� ATR �� %s", PeriodToString(TFs[i]));
   log_file.Write(LOG_DEBUG, StringFormat("�� ������� ������� ����� ���������� ATR �� %s", PeriodToString(TFs[i])));
  }
 
  ctf = new CTimeframeInfo(TFs[i],_Symbol, handleATR);      // �������� ��
  ctf.SetRatio(Ks[i]);                                      // ��������� �����������
  ctf.IsThisNewBar();                                       // ������� ������� �� ������ ����
  _dataTFs.Add(ctf);                                        // ������� � ������ �� dataTFs
  // ������� ��������� ������� ��� ������� �������
  trend = new CTrendChannel(0, _Symbol, TFs[i], handleDE, trendPercent);
  trend.UploadOnHistory(1000);                                  // ������� ��������� �� �������
  _trends.Add(trend);                                       // ������� ��������� ������� � ������ �� �����������
  log_file.Write(LOG_DEBUG, StringFormat(" �������� �� = %s ������ �������", PeriodToString(TFs[i])));
 }
 

 _posOpenedDirection = 0;
 _sl = 0;
 _indexPosOpenedTF = -1;
 
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CRabbitsBrain::~CRabbitsBrain()
{
 _trends.Clear();
 delete _trends;
_dataTFs.Clear();
 delete _dataTFs;  
}
//+------------------------------------------------------------------+

int CRabbitsBrain::GetSignal()
{  
 int signalForTrade;
 for(int i = _dataTFs.Total()-1; i >= 0; i--) // ������� �� ������� ���������, ������� �� ��������
 {
  ctf = _dataTFs.At(i);         // �������� ������� �� 
  trend = _trends.At(i);                   
  if(!trend.UploadOnHistory())  // �������� ����� ������� �� ������� ��
  {
   PrintFormat("DISCORD: �� ������� �������� ������ ������� �� ������� �� = %s", PeriodToString(ctf.GetPeriod()));
   log_file.Write(LOG_DEBUG, StringFormat("DISCORD: �� ������� �������� ������ ������� �� ������� �� = %s", PeriodToString(ctf.GetPeriod())));
   return DISCORD;
  }
  
  if(ctf.IsThisNewBar()>0)      // ���� �� ��� ������ ����� ���
  {
   signalForTrade = GetTradeSignal(ctf); // ������� ������ �� ���� ��
   if( (signalForTrade == BUY || signalForTrade == SELL ) ) //(signalForTrade != NO_POISITION)
   { 
    _posOpenedTF = ctf;
    _posOpenedDirection = signalForTrade;         // ��������� ����������� �� �������� ���� ������� ������
    _indexPosOpenedTF = GetIndexTF(_posOpenedTF); // ��������� ������ �� � ������� dataTFs, �� ������� ���� ������� ������
    log_file.Write(LOG_DEBUG, StringFormat("��������� ��� ������� ������� %i", GetIndexTF(_posOpenedTF)));
   }
   return signalForTrade;
  }
 } 
 return   DISCORD;
}
//+------------------------------------------------------------------+

//������� ��������� ��������� ������� (���������� ��� ������� �� �� ��� ������������ DISCORT "������ �������") 
int CRabbitsBrain::GetTradeSignal(CTimeframeInfo *TF)  
{
 int signalThis = 0;
 int signalYoungTF;
 _sl = 0;
 if(TF.GetPeriod() == PERIOD_M1) // �������� �� ������������ �� ������� ��
 {
  signalYoungTF = 0;
  log_file.Write(LOG_DEBUG, StringFormat("%s ������ �������� ������� �1", MakeFunctionPrefix(__FUNCTION__)));
 }
 else 
 { 
  CTimeframeInfo *tf = GetBottom(TF);
  signalYoungTF = GetTradeSignal(GetBottom(TF));
  if(signalYoungTF == 2)   //���� ������� ������������ �� ������� ��
  {
   log_file.Write(LOG_DEBUG, StringFormat("���� ������� ������������ ��� �� = %s �� �� = %s", PeriodToString(TF.GetPeriod()), PeriodToString(tf.GetPeriod()))); 
   return DISCORD;
  }
 }
 if( CopyOpen(_Symbol,TF.GetPeriod(), 1, 1, open_buf) < 1 ||
     CopyBuffer(TF.GetHandleATR(), 0, 1, 1, atr_buf) <1 )
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� ����������� ���� �������� ���������� ���� ��� �������� ATR", MakeFunctionPrefix(__FUNCTION__)));
  return DISCORD;
 }
 // ���� ���� ������ ��������*� ?
 if(GreatDoubles(MathAbs(open_buf[0] - _conbuf.GetClose(TF.GetPeriod()).buffer[1]), atr_buf[0]*(1 + TF.GetRatio())))
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ���� ���� (%f)  ������ ��� (%f) �� �� = %s", MakeFunctionPrefix(__FUNCTION__),MathAbs(open_buf[0] - _conbuf.GetClose(TF.GetPeriod()).buffer[1]),atr_buf[0]*(1 + TF.GetRatio()), PeriodToString(TF.GetPeriod())));
  if(open_buf[0] - _conbuf.GetClose(TF.GetPeriod()).buffer[1] > 0) // ���������� ����������� ����
   signalThis = SELL;
  else 
   signalThis = BUY;
   
  bool barInChannel = true;
  if(!TrendsDirection(TF, signalThis))  // ����������� ���� ��������� ������������ �������� ?
  {
   if(TF.IsThisTrendNow())              // ���� ������ ���� �����
    barInChannel = LastBarInChannel(TF);// �������� : ���������� ��� ������� � �������� ������?
   if (barInChannel)                    // ���������� ��, � ����� �������� �� 19 �����
   {
    _sl = (MathAbs(_conbuf.GetClose(TF.GetPeriod()).buffer[1] - open_buf[0]))/2;
    if (FilterBy19Lines(signalThis, TF.GetPeriod(), _sl))
     if(signalThis != NO_SIGNAL && signalYoungTF != -signalThis)
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s �������� ������ SELL/BUY = %d", MakeFunctionPrefix(__FUNCTION__), signalThis));
      return signalThis;
     }
   }
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("%s Return NO_SIGNAL", MakeFunctionPrefix(__FUNCTION__)));
 signalThis = NO_SIGNAL;
 return signalThis; //���������� �������� ������
}

// ���������� ��������� ������ ��� �������� ��
CTimeframeInfo *CRabbitsBrain::GetBottom(CTimeframeInfo *curTF)
{
 if(curTF.GetPeriod() == PERIOD_M1)
  return curTF;
 CTimeframeInfo *tf;
 for(int i = _dataTFs.Total()-1; i >= 0 ;i--)
 {
  tf = _dataTFs.At(i);
  if(tf.GetPeriod() == curTF.GetPeriod())
  {
   tf = _dataTFs.At(i-1);
   return tf;
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("������: %s �� ���������� ����� ������� ������ ��� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(curTF.GetPeriod())));
 return(curTF);
}

// ������� ���������� true, ���� ��������� ��� ������ � ���� ������� � ������������ direction
bool CRabbitsBrain::TrendsDirection (CTimeframeInfo *curTF, int direction)
{
 int index = GetIndexTF(curTF);
 CTrendChannel *trendForTF;
 trendForTF = _trends.At(index);
 if(index!=-1)
 {
  if (trendForTF.GetTrendByIndex(0).GetDirection() == direction && trendForTF.GetTrendByIndex(1).GetDirection() == direction)
  {
   return (true); 
  }
  else
  {
   Print("��� ���� �������");
   return false;
  }
 }
 Print("���-�� �� ��, ����� ������ = %d",index);
 return true; // ���������� true, ����� ������� ������ ��� �������� �����������
}


// ������� ��� ��������, ��� ��� �������� ������ ������
bool CRabbitsBrain::LastBarInChannel (CTimeframeInfo *curTF) 
{
 //CMoveContainer *trendTF;
 CTrendChannel *trendTF;
 int index = GetIndexTF(curTF);
 //Print("index = ", index, "period = ",PeriodToString(curTF.GetPeriod()));
 trendTF = _trends.At(index);
 double priceLineUp;
 double priceLineDown;
 datetime timeBuffer[];
 if (CopyTime(_Symbol, curTF.GetPeriod(), 1 , 1, timeBuffer) < 1) 
 {
  Print("�� ������� ���������� ����� timeBuffer");
  log_file.Write(LOG_DEBUG, "�� ������� ���������� ����� timeBuffer");
  return (false);
 }
 priceLineUp = trendTF.GetTrendByIndex(0).GetPriceLineUp(timeBuffer[0]);
 priceLineDown = trendTF.GetTrendByIndex(0).GetPriceLineDown(timeBuffer[0]);
 Print(" time = ", TimeToString(timeBuffer[0]));
 PrintFormat(" close = %f priceLineUp = %f priceLineDown = %f", _conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp, priceLineDown);
 if ( LessOrEqualDoubles(_conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp) && GreatOrEqualDoubles(_conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineDown))
 { 
  PrintFormat("�������� � ������ close = %f priceLineUp = %f priceLineDown = %f", _conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp, priceLineDown);
  return (true);
 }
 return (false);
}

// ���������� true ���� ����������� �� ������� ������ SL � 10 ���
bool CRabbitsBrain::FilterBy19Lines (int direction, ENUM_TIMEFRAMES period, int stopLoss)
{
 double currentPrice;
 double lenPrice3;
 double lenPrice4;
 double level3[];
 double level4[];
 int bufferLevel3;
 int bufferLevel4;  
 // ���� ��� ����� ����� ��� M1
 if (period == PERIOD_M1)
 {
  bufferLevel3 = 34;
  bufferLevel4 = 35;
 }
 // ���� ��� ����� ����� ��� M5
 if (period == PERIOD_M5)
 {
  bufferLevel3 = 34;
  bufferLevel4 = 35;
 }   
 // ���� ��� ����� ����� ��� M15
 if (period == PERIOD_M15)
 {
  bufferLevel3 = 26;
  bufferLevel4 = 27;
 }   
  
 if (direction == 1)
 {
  currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
 }
 if (direction == -1)
 {
  currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);    
 }
 
 if (CopyBuffer(_handle19Lines,bufferLevel3,0,1,level3) < 1 || 
     CopyBuffer(_handle19Lines,bufferLevel4,0,1,level4) < 1)
 {
  Print("�� ������� ����������� ������ ������� 19Lines");
  log_file.Write(LOG_DEBUG, "�� ������� ����������� ������ ������� 19Lines");
  return (false);
 }
 // ��������� ���������� �� ������� ���� �� �������
 lenPrice3 = MathAbs(level3[0] - currentPrice);
 lenPrice4 = MathAbs(level4[0] - currentPrice);
 if (direction == 1)
 {
  if (GreatDoubles(level3[0],level4[0]) && GreatDoubles(lenPrice3,10*lenPrice4))
   return (true);
  if (GreatDoubles(level4[0],level3[0]) && GreatDoubles(lenPrice4,10*lenPrice3))
   return (true);     
 }
 if (direction == -1)
 {
  if (GreatDoubles(level3[0],level4[0]) && GreatDoubles(lenPrice4,10*lenPrice3))
   return (true);
  if (GreatDoubles(level4[0],level3[0]) && GreatDoubles(lenPrice3,10*lenPrice4))
   return (true);      
 }
 return (false);
}

// ������� ���������� ������ �� , ��������� � �������
int CRabbitsBrain::GetIndexTF(CTimeframeInfo *curTF)
{
 int i;
 CTimeframeInfo *masTF;
 for( i = 0; i <= _dataTFs.Total(); i++)
 { 
  masTF = _dataTFs.At(i);
  if(curTF.GetPeriod() == masTF.GetPeriod())
   return i;
 }
 return -1;
}

bool CRabbitsBrain::UpdateBuffers()
{ 
 if(_conbuf.Update())
  return true;
 else
  return false;
}
/*
bool CRabbitsBrain::UpdateTrendsOnHistory(int i)
{
 trend = _trends.At(i);
 if(!trend.UploadOnHistory())
  return false;
 else
  return true;
}*/

bool CRabbitsBrain::UpdateOnEvent(long lparam, double dparam, string sparam, int countPos)
{
 // �������� �� ������ �������. 
 // ���� ��� ��������� ����� � ��������������� �������, ������� �������.
 int newDirection;  
 bool closePosition = false;
 for(int i = 0; i < _dataTFs.Total(); i++)
 {  
  trend = _trends.At(i);
  trend.UploadOnEvent(sparam, dparam, lparam);
  ctf = _dataTFs.At(i);
  ctf.SetTrendNow(trend.IsTrendNow());
  // ���� ������ ����� ����� � �� ���������� ������ �������� ������� �� ������� ���������������� ������
  if (ctf.IsThisTrendNow())
  {
   newDirection = trend.GetTrendByIndex(0).GetDirection();
   // ���� ������ ��������������� ����������� ������� �����
   if (i >= _indexPosOpenedTF && _posOpenedDirection != NO_SIGNAL && newDirection == -_posOpenedDirection && countPos > 0 ) // && ctf.GetPeriod() == posOpenedTF
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� �� OnChartEvent �� ���������������� ������", MakeFunctionPrefix(__FUNCTION__)));
    // ��������� ������� 
    _posOpenedDirection = NO_SIGNAL;
    _posOpenedTF = ctf; 
    closePosition =  true;
   }
  }
 } 
 return closePosition;
}

void CRabbitsBrain::OpenedPosition(int ctmTotal)
{
 if(ctmTotal==0)
 {
  _posOpenedDirection = NO_SIGNAL;
 }
}