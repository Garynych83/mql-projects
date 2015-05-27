//+------------------------------------------------------------------+
//|                                                      URabbit.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//����������� ����������� ���������
#include <TradeManager/TradeManager.mqh> // 
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <CTrendChannel.mqh> // ��������� ���������
#include <Chicken/ContainerBuffers(NoPBI).mqh> //��������� ������� ��� �� ���� �� (No PBI) - ��� ������� � ��
#include <Rabbit/TimeFrame.mqh>

//���������
#define KO 3            //����������� ��� ������� �������� �������, �� ������� ��� ������� ����������� ���� ������ ������ ��������� ����������� ���� ����
#define SPREAD 30       // ������ ������ 

enum ENUM_SIGNAL_FOR_TRADE
{
 SELL = -1,     // �������� ������� �� �������
 BUY  = 1,      // �������� ������� �� �������
 NO_SIGNAL = 0, // ��� ��������, ����� ������� �� �������� ������� �� ����
 DISCORD = 2,   // ������ ������������, "������ �������"
};
//---------------------��������---------------------------------+
// ENUM ��� �������
// ������� ��������� ��� �������� supremacyPercent
// ����� �� � ������ ��������� ������ ���������� ���, � ���� ��������?
//--------------------------------------------------------------+

//-------�������� ������������� ���������-------------
input string base_param = ""; // ������� ���������
input double lot = 1;         // ���
input double percent = 0.1;   // �������
input double M1_Ratio  = 5;   //�������, ��������� ��� M1 ������ �������� ��������
input double M5_Ratio  = 3;   //�������, ��������� ��� M1 ������ �������� ��������
input double M15_Ratio  = 1;  //�������, ��������� ��� M1 ������ �������� ��������
input double profitPercent = 0.5;// ������� �������                                                          
input int priceDifference = 50;  // Price Difference
input string filters_param = ""; // �������
input bool useTwoTrends = true;  // �� ���� ��������� �������
input bool useChannel = true;    // �������� ������ ������
input bool useClose = true;      // �������� ������� � ��������������� ������
input bool use19Lines = true;    // 19 �����

// ---------���������� ������------------------
CTrendChannel *trend;      // ����� �������
CTimeframe *ctf;           // ������ �� ��
CContainerBuffers *conbuf; // ����� ����������� �� ��������� ��, ����������� �� OnTick()
                           // highPrice[], lowPrice[], closePrice[] � �.�; 
CArrayObj *dataTFs;        // ������ ��, ��� �������� �� ���������� �� ������������
CArrayObj *trends;         // ������ ������� ������� (��� ������� �� ���� �����)

CTradeManager ctm;         //�������� ����� 
     
datetime history_start;    // ����� ��� ��������� �������� �������                           
double atr_buf[1], open_buf[1];

ENUM_TM_POSITION_TYPE opBuy, opSell;
int handle19Lines; 
int handleATR;
int handleDE;

double Ks[3]; // ������ ������������� ��� ������� �� �� �1 �� �15

//---------��������� ������� � ���������------------
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   //�����  

// ����������� �������� �������
int posOpenedDirection = 0;
int signalForTrade;
int SL, TP;
long magic;
ENUM_TIMEFRAMES TFs[3] = {PERIOD_M1, PERIOD_M5, PERIOD_M15};
ENUM_TIMEFRAMES posOpenedTF;  // ������ �� ������� ���� ������� �������

int indexPosOpenedTF;         // ������� ����� �������� ������� �� ������� ������ ������ ��� �� ��� �� ��� � ���� �������

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 Ks[0] = M1_Ratio;
 Ks[1] = M5_Ratio;
 Ks[2] = M15_Ratio;
 history_start = TimeCurrent(); //�������� ����� ������� �������� ��� ��������� �������� �������
 dataTFs = new CArrayObj();
 trends = new CArrayObj();
 //�������� ������ ��������� 
 for(int i = 0; i < ArraySize(TFs); i++)
 {
  handleDE = iCustom(_Symbol,TFs[i],"DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   PrintFormat("�� ������� ������� ����� ���������� DrawExtremums �� %s", PeriodToString(TFs[i]));
   return (INIT_FAILED);
  }
  handleATR = iMA(_Symbol, TFs[i], 100, 0, MODE_EMA, iATR(_Symbol, TFs[i], 30));
  if (handleATR == INVALID_HANDLE)
  {
   PrintFormat("�� ������� ������� ����� ���������� ATR �� %s", PeriodToString(TFs[i]));
   return (INIT_FAILED);
  } 
  ctf = new CTimeframe(TFs[i],_Symbol, handleATR, handleDE); // �������� ��
  ctf.SetRatio(Ks[i]);                                       // ��������� �����������
  ctf.IsThisNewBar();                                        // ������� ������� �� ������ ����
  dataTFs.Add(ctf);                                          // ������� � ������ �� dataTFs
  // ������� ��������� ������� ��� ������� �������
  trend = new CTrendChannel(0, _Symbol, TFs[i], handleDE, percent);
  trend.UploadOnHistory();
  trends.Add(trend);
  log_file.Write(LOG_DEBUG, StringFormat(" �������� �� = %s ������ �������", PeriodToString(TFs[i])));
 }
 
 //----------- ��������� ���������� NineTeenLines----------
 handle19Lines = iCustom(_Symbol,_Period,"NineTeenLines");
 if (handle19Lines == INVALID_HANDLE)
 {
  Print("�� ������� ������� ����� ���������� NineTeenLines");
  return (INIT_FAILED);
 }
 
 //---------- ����� ��������� NineTeenLines----------------
 conbuf = new CContainerBuffers(TFs);
 opBuy  = OP_BUY;  // ��� ����. �����?
 opSell = OP_SELL;
 
 pos_info.volume = 1;
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;

 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete trend;
 delete conbuf;
 dataTFs.Clear();
 delete dataTFs;
 trends.Clear();
 delete trends;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 ctm.OnTick();    
 conbuf.Update();             // ��������� ���������� ������ � ����
 pos_info.type = OP_UNKNOWN;  // ����� �������� �������
 signalForTrade = NO_SIGNAL;  // ������� ������ ������

 if (ctm.GetPositionCount() == 0) // ���� ��� �������� �������
  posOpenedDirection = NO_SIGNAL; // ����������� �������� ������� NO_SIGNAL (0)
  
 for(int i = ArraySize(TFs)-1; i >= 0; i--) // ������� �� ������� ���������, ������� �� ��������
 { 
  trend = trends.At(i);                     
  if(!trend.UploadOnHistory()) // �������� ����� ������� �� ������� ��
   return;
  ctf = dataTFs.At(i);         // �������� ������� ��
  if(ctf.IsThisNewBar() > 0)   // ���� �� ��� ������ ����� ���
  {
   signalForTrade = GetTradeSignal(ctf); // ������� ������ �� ���� ��
   pos_info.sl = SL;                     // ���������� ������������ SL
   pos_info.tp = 10 * SL;                
   if( (signalForTrade == BUY || signalForTrade == SELL ) ) //(signalForTrade != NO_POISITION)
   {
    if(signalForTrade == BUY)
     pos_info.type = opBuy;
    else 
     pos_info.type = opSell;
    posOpenedDirection = signalForTrade;  // ��������� ����������� �� �������� ���� ������� ������
    posOpenedTF = TFs[i];                 // ��������� ��, �� ������� ���� ������� ������
    indexPosOpenedTF = i;                 // ��������� ������ �� � ������� dataTFs, �� ������� ���� ������� ������
    ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing, SPREAD);   // ������� �������
   }
  }
 }   
}
void OnTrade()
{
 ctm.OnTrade();
 if(history_start != TimeCurrent())
 {
  history_start = TimeCurrent() + 1;
 }
}

// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
{
 // �������� �� ������ �������. 
 // ���� ��� ��������� ����� � ��������������� �������, ������� �������
 int newDirection;  
 for(int i = 0; i < ArraySize(TFs); i++)
 {
  trend = trends.At(i);
  trend.UploadOnEvent(sparam, dparam, lparam);
  ctf = dataTFs.At(i);
  ctf.SetTrendNow(trend.IsTrendNow());
  // ���� ������ ����� ����� � �� ���������� ������ �������� ������� �� ������� ���������������� ������
  if (ctf.IsThisTrendNow() && useClose)
  {
   newDirection = trend.GetTrendByIndex(0).GetDirection();
   // ���� ������ ��������������� ����������� ������� �����
   if (i >= indexPosOpenedTF && posOpenedDirection != NO_SIGNAL && newDirection == -posOpenedDirection && ctm.GetPositionCount() > 0 ) // && ctf.GetPeriod() == posOpenedTF
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� �� OnChartEvent �� ���������������� ������", MakeFunctionPrefix(__FUNCTION__)));
    // ��������� ������� 
    ctm.ClosePosition(0);
    posOpenedDirection = NO_SIGNAL;
   }
  }
 } 
}
//������� ��������� ��������� ������� (���������� ����������� ��������� �������) 
int GetTradeSignal(CTimeframe *TF)  
{
 int signalThis = 0;
 int signalYoungTF;
 SL = 0;
 if(TF.GetPeriod() == PERIOD_M1)
 {
  signalYoungTF = 0;
 }
 else 
 {
  CTimeframe *tf = GetBottom(TF);
  signalYoungTF = GetTradeSignal(GetBottom(TF));

  if(signalYoungTF == 2)   //���� ������� ������������ �� ������� ��
   return 2;
 }
 if( CopyOpen(_Symbol,TF.GetPeriod(), 1, 1, open_buf) < 1 ||
     CopyBuffer(TF.GetHandleATR(), 0, 1, 1, atr_buf) <1 )
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� ����������� ���� �������� ���������� ���� ��� �������� ATR", MakeFunctionPrefix(__FUNCTION__)));
  return 2;
 }
 //������� ��������
 if(GreatDoubles(MathAbs(open_buf[0] - conbuf.GetClose(TF.GetPeriod()).buffer[1]), atr_buf[0]*(1 + TF.GetRatio())))
 {
  if(open_buf[0] - conbuf.GetClose(TF.GetPeriod()).buffer[1] > 0)
  {
   signalThis = SELL;
   Print("������ SELL");
  }
  else 
  {
   signalThis = BUY;
   Print("������ BUY");
  }
  bool barInChannel = true;
  if(!TrendsDirection(TF, signalThis))
  {
   if(TF.IsThisTrendNow())
   { 
    barInChannel = LastBarInChannel(TF);
    Print("������ ���� �����!");
   }
   if (barInChannel)
   {
    SL = (MathAbs(conbuf.GetClose(TF.GetPeriod()).buffer[1] - open_buf[0]))/2;
    if (FilterBy19Lines(signalThis, TF.GetPeriod(), SL))
     if(signalThis != NO_SIGNAL && signalYoungTF != -signalThis)
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s �������� ������ SELL/BUY = %d", MakeFunctionPrefix(__FUNCTION__), signalThis));
      return signalThis;
     }
   }
  }
 }
 signalThis = NO_SIGNAL;
 return signalThis;
}

// ���������� ��������� ������ ��� �������� ��
CTimeframe *GetBottom(CTimeframe *curTF)
{
 if(curTF.GetPeriod()==PERIOD_M1)
  return curTF;
 CTimeframe *ctf;
 for(int i = dataTFs.Total()-1; i >= 0 ;i--)
 {
  ctf = dataTFs.At(i);
  if(ctf.GetPeriod() == curTF.GetPeriod())
  {
   ctf = dataTFs.At(i-1);
   return ctf;
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("������: %s �� ���������� ����� ������� ������ ��� %s", MakeFunctionPrefix(__FUNCTION__), PeriodToString(curTF.GetPeriod())));
 return(curTF);
}


// ������� ���������� true, ���� ��������� ��� ������ � ���� ������� � ������������ direction
bool TrendsDirection (CTimeframe *curTF, int direction)
{
 int index = GetIndexTF(curTF);
 CTrendChannel *trendForTF;
 trendForTF = trends.At(index);
 if(index!=-1)
 {
  if (trendForTF.GetTrendByIndex(0).GetDirection() == direction && trendForTF.GetTrendByIndex(1).GetDirection() == direction)
  {
   return (true); 
  }
  else
  {
   //Print("��� ���� �������");
   return false;
  }
 }
 //Print("���-�� �� ��, ����� ������ = %d",index);
 return true; // ���������� true, ����� ������� ������ ��� �������� �����������
}

// ������� ���������� ������ �� , ��������� � �������
int GetIndexTF(CTimeframe *curTF)
{
 int i;
 CTimeframe *masTF;
 for( i = 0; i <= dataTFs.Total(); i++)
 { 
  masTF = dataTFs.At(i);
  if(curTF.GetPeriod() == masTF.GetPeriod())
   return i;
 }
 return -1;
}

// ������� ��� ��������, ��� ��� �������� ������ ������
bool LastBarInChannel (CTimeframe *curTF) 
{
 CTrendChannel *trendTF;
 int index = GetIndexTF(curTF);
 Print("index = ", index, "period = ",PeriodToString(curTF.GetPeriod()));
 trendTF = trends.At(index);
 double priceLineUp;
 double priceLineDown;
 double closePrice;
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
 PrintFormat(" close = %f priceLineUp = %f priceLineDown = %f", conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp, priceLineDown);
 if ( LessOrEqualDoubles(conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp) && GreatOrEqualDoubles(conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineDown))
 { 
  PrintFormat("�������� � ������ close = %f priceLineUp = %f priceLineDown = %f", conbuf.GetClose(curTF.GetPeriod()).buffer[1], priceLineUp, priceLineDown);
  return (true);
 }
 return (false);
}

// ���������� true ���� ����������� �� ������� ������ SL � 10 ���
bool FilterBy19Lines (int direction, ENUM_TIMEFRAMES period, int stopLoss)
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
 
 if (CopyBuffer(handle19Lines,bufferLevel3,0,1,level3) < 1 || 
     CopyBuffer(handle19Lines,bufferLevel4,0,1,level4) < 1)
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