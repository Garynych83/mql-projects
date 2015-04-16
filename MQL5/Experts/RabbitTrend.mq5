//+------------------------------------------------------------------+
//|                                            FollowWhiteRabbit.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| ������� FollowWhiteRabbit                                        |
//+------------------------------------------------------------------+
//����������� ����������� ���������
#include <Lib CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh> // 
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <CTrendChannel.mqh> // ��������� ���������
//���������
#define ADD_TO_STOPLOSS 50 // ���������� ������ � ���� �����
#define DEPTH  1000        // ������� �������
#define SPREAD 30          // ������ ������
#define KO 3 //����������� ��� ������� �������� �������, �� ������� ��� ������� ����������� ���� ������ ������ ��������� ����������� ���� ���� 
//�������� ������������� ���������
input double lot = 1; // ���
input double percent = 0.1; // �������
input double M1_supremacyPercent  = 5;//�������, ��������� ��� M1 ������ �������� ��������
input double M5_supremacyPercent  = 3;//�������, ��������� ��� M5 ������ �������� ��������
input double M15_supremacyPercent = 1;//�������, ��������� ��� M15 ������ �������� ��������
input double profitPercent = 0.5;// ������� �������                                            

input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;// ��� ����������� ������                    
input int priceDifference = 50;//Price Difference
input bool checkFilter = true; // ������ ������� ��������

// ���������� ������ 
datetime history_start;
//�������� �����
CTradeManager ctm;          
//�������
double ave_atr_buf[1],close_buf[1],open_buf[1],pbi_buf[1];

ENUM_TM_POSITION_TYPE opBuy,opSell;
// ������� ������� ������� ����� �����
CisNewBar *isNewBarM1;
CisNewBar *isNewBarM5;
CisNewBar *isNewBarM15;
// ������� ����������� �������
CTrendChannel *trendM1;
CTrendChannel *trendM5;
CTrendChannel *trendM15;
//������ �����������
int handle_PBI;
int handle_aATR_M1;
int handle_aATR_M5;
int handle_aATR_M15;
int handleDE;
//��������� ������� � ���������
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   //����� 

int signalM1;
int signalM5;
int signalM15;

//+------------------------------------------------------------------+
//| ������������� ��������                                           |
//+------------------------------------------------------------------+
int OnInit()
{
 history_start=TimeCurrent(); //�������� ����� ������� �������� ��� ��������� �������� �������
 // �������� ���������� DrawExtremums 
 handleDE = DoesIndicatorExist(_Symbol,_Period,"DrawExtremums");
 if (handleDE == INVALID_HANDLE)
  {
   handleDE = iCustom(_Symbol,_Period,"DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     Print("�� ������� ������� ����� ���������� DrawExtremums");
     return (INIT_FAILED);
    }
   SetIndicatorByHandle(_Symbol,_Period,handleDE);
  }     
 switch (pending_orders_type) //���������� priceDifference
 {
  case USE_LIMIT_ORDERS: //useLimitsOrders = true;
  opBuy = OP_BUYLIMIT;
  opSell= OP_SELLLIMIT;
  break;
  case USE_STOP_ORDERS:
  opBuy = OP_BUYSTOP;
  opSell= OP_SELLSTOP;
  break;
  case USE_NO_ORDERS:
  opBuy = OP_BUY;
  opSell= OP_SELL;      
  break;
 }   
 //������� ������� ������ ��� ����������� ��������� ������ ����
 isNewBarM1= new CisNewBar(_Symbol,PERIOD_M1);
 isNewBarM5= new CisNewBar(_Symbol,PERIOD_M5);
 isNewBarM15=new CisNewBar(_Symbol,PERIOD_M15);
 // ������� ������� ������� ����������� �������
 trendM1 = new CTrendChannel(0,_Symbol,PERIOD_M1,handleDE,percent);
 trendM5 = new CTrendChannel(0,_Symbol,PERIOD_M5,handleDE,percent);
 trendM15 = new CTrendChannel(0,_Symbol,PERIOD_M15,handleDE,percent);  
 // ������� ����� PriceBasedIndicator
 handle_PBI= iCustom(_Symbol,PERIOD_M15,"PriceBasedIndicator");
 handle_aATR_M1=iMA(_Symbol,PERIOD_M1,100,0,MODE_EMA,iATR(_Symbol,PERIOD_M1,30));
 handle_aATR_M5=iMA(_Symbol,PERIOD_M5,100,0,MODE_EMA,iATR(_Symbol,PERIOD_M5,30)); 
 handle_aATR_M15=iMA(_Symbol,PERIOD_M15,100,0,MODE_EMA,iATR(_Symbol,PERIOD_M15,30));      
 if(handle_PBI==INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� �������� ����� ������ �� ��������������� �����������", MakeFunctionPrefix(__FUNCTION__)));  
  return (INIT_FAILED);
 }       
    
 trailing.trailingType = TRAILING_TYPE_EASY_LOSSLESS;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
 {
  delete isNewBarM1;
  delete isNewBarM15;
  delete isNewBarM5;
  delete trendM1;
  delete trendM15;
  delete trendM5;
 }

void OnTick()
{
 ctm.OnTick();
   
 pos_info.type = OP_UNKNOWN;
 signalM1  = 0;
 signalM5  = 0;
 signalM15 = 0;
 /*
 if(isNewBarM1.isNewBar())
 {
  GetTradeSignal(PERIOD_M1, handle_aATR_M1, M1_supremacyPercent, pos_info); //���� �����������
  if (pos_info.type == opBuy)
   signalM1 = 1;
  else if (pos_info.type == opSell)
   signalM1 = -1; 
  else
   signalM1 = 0;   
 }
 */
 /*
 if(isNewBarM5.isNewBar())
 {
  GetTradeSignal(PERIOD_M5, handle_aATR_M5, M5_supremacyPercent, pos_info);
  if (pos_info.type == opBuy)
   signalM5 = 1;
  else if (pos_info.type == opSell)
   signalM5 = -1; 
  else
   signalM5 = 0;  
 }  
 */
 if(isNewBarM15.isNewBar())
 {
  GetTradeSignal(PERIOD_M15, handle_aATR_M15, M15_supremacyPercent, pos_info);
  if (pos_info.type == opBuy)
   signalM15 = 1;
  else if (pos_info.type == opSell)
   signalM15 = -1; 
  else
   signalM15 = 0;    
 }
 if( (pos_info.type == opBuy || pos_info.type == opSell ) && (InputFilter() || !checkFilter) )
 {
  ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing,SPREAD);   
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
   /*
   double price;
   // ������ ������� "������������� ����� ���������"
   if (sparam == eventExtrDownName || sparam == eventExtrUpName)
    {
     // ������� ����� � �������
     DeleteLines();
     // �������� ����� �������� ����������� � �������
     UploadExtremums ();

     trend = IsTrendNow();
     if (trend)
      {  
       // �������������� �����
       DrawLines ();     
      }
       
    }
   */
  } 

//������� ��������� ��������� ������� (���������� ����������� ��������� �������) 
void GetTradeSignal(ENUM_TIMEFRAMES tf, int handle_atr, double supremacyPercent, SPositionInfo &pos)
{   
 //���� �� ������� ���������� ��� ������ 
 if (CopyClose(_Symbol,tf,1,1,close_buf)<1 ||
     CopyOpen(_Symbol,tf,1,1,open_buf)<1 ||
     CopyBuffer(handle_atr,0,0,1,ave_atr_buf)<1)
 {
  //�� ������� ��������� � ��� �� ������
  log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� ����������� ������ �� ������ �������� �������", MakeFunctionPrefix(__FUNCTION__)));    
  return;//� ������� �� �������
 }
 //���� �� ������� ���������� ����� PBI  
 if(CopyBuffer(handle_PBI,4,1,1,pbi_buf) < 1)   
 {
  //�� ������� ��������� � ��� �� ������
  log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� ����������� ������ �� ���������������� ����������", MakeFunctionPrefix(__FUNCTION__)));   
  return; //� ������� �� �������
 } 
 if(GreatDoubles(MathAbs(open_buf[0] - close_buf[0]), ave_atr_buf[0]*(1 + supremacyPercent)))
 {
  if(LessDoubles(close_buf[0], open_buf[0])) // �� ��������� ���� close < open (��� ����)
  {   

   pos.tp=(int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+profitPercent));
   pos.sl=CountStoploss(-1);
   //���� ����������� ���� ������ � kp ���� ��� ����� ��� ������, ��� ����������� ���� ����
   if(pos.tp >= KO*pos.sl)
    pos.type = opSell;
   else
   {
    pos.type = OP_UNKNOWN;
    return;
   }   
  }
  if(GreatDoubles(close_buf[0], open_buf[0]))
  { 
      
   pos.tp = (int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+profitPercent));
   pos.sl = CountStoploss(1);
   // ���� ����������� ���� ������ � kp ���� ��� ����� ��� ������, ��� ����������� ���� ����
   if(pos.tp >= KO*pos.sl)
    pos.type = opBuy;
   else
   {
    pos.type = OP_UNKNOWN;
    return;
   }
  }
  pos.expiration = 0; 
  pos.expiration_time = 0;
  pos.volume = volume;
  pos.priceDifference = priceDifference; 
  // ���������� minProfit ��� ��� ���� �����
  trailing.minProfit = pos.sl*2;
 }
 ArrayInitialize(ave_atr_buf,EMPTY_VALUE);
 ArrayInitialize(close_buf,EMPTY_VALUE);
 ArrayInitialize(open_buf,EMPTY_VALUE);
 ArrayInitialize(pbi_buf,EMPTY_VALUE);
 return;
} 
// ������� ��������� ���� ����
int CountStoploss(int point)
{
 int stopLoss = 0;
 int direction;
 double priceAB;
 double bufferStopLoss[];
 ArraySetAsSeries(bufferStopLoss, true);
 ArrayResize(bufferStopLoss, DEPTH);
 int extrBufferNumber;
 if (point > 0)
 {
  extrBufferNumber = 6; //minimum
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  direction = 1;
 }
 else
 {
  extrBufferNumber = 5; //maximum
  priceAB = SymbolInfoDouble(_Symbol, SYMBOL_BID);
  direction = -1;
 }
 int copiedPBI = -1;
 for(int attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(handle_PBI, extrBufferNumber, 0,DEPTH, bufferStopLoss);
 }
 if (copiedPBI < DEPTH)
 {
  log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� ����������� ����� bufferStopLoss", MakeFunctionPrefix(__FUNCTION__)));  
  return(0);
 }
 for(int i=0;i<DEPTH;i++)
 {
  if(bufferStopLoss[i]>0)
  {
   if(LessDoubles(direction*bufferStopLoss[i],direction*priceAB))
   {
   // log_file.Write(LOG_DEBUG,StringFormat("%s price = %f; extr = %f",MakeFunctionPrefix(__FUNCTION__), priceAB, bufferStopLoss[i]));      
    stopLoss=(int)(MathAbs(bufferStopLoss[i] - priceAB)/Point());
    break;
   }
  }
 }
 if (stopLoss <= 0)  
 {
  log_file.Write(LOG_DEBUG,StringFormat("%s �� ��������� ���� ���� �� ����������", MakeFunctionPrefix(__FUNCTION__)));   
  stopLoss = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)+ADD_TO_STOPLOSS;
 }
 return(stopLoss);
}

// ������ �� ���������� �������������� �������
bool  InputFilter ()
 {
  // ���� ��� ������� �� BUY (�.�. ��� ������������)
  if (signalM1!=1 && signalM5!=1 && signalM15!=1)
   return(true);
  // ���� ��� ������� �� SELL (�.�. ��� ������������)
  if (signalM1!=-1 && signalM5!=-1 && signalM15!=-1)
   return(true);
  return(false);
 }