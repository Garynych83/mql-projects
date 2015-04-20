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
#define KO 3 //����������� ��� ������� �������� �������, �� ������� ��� ������� ����������� ���� ������ ������ ��������� ����������� ���� ����
#define SPREAD 30 // ������ ������ 
//�������� ������������� ���������
input double lot = 1; // ���
input double percent = 0.1; // �������
input double M1_supremacyPercent  = 5;//�������, ��������� ��� M1 ������ �������� ��������
input double profitPercent = 0.5;// ������� �������                                                          
input int priceDifference = 50;//Price Difference

// ���������� ������ 
datetime history_start;
//�������� �����
CTradeManager ctm;          
//�������
double ave_atr_buf[1],close_buf[1],open_buf[1],pbi_buf[1];

ENUM_TM_POSITION_TYPE opBuy,opSell;
// ������� ������� ������� ����� �����
CisNewBar *isNewBarM1;
// ������� ����������� �������
CTrendChannel *trendM1;
//������ �����������
int handle_aATR_M1;
int handleDE_M1;
//��������� ������� � ���������
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   //����� 

int signalM1;

bool trendM1Now = false;

bool firstUploadedM1 = false; // ���� ������ �������� �������

//+------------------------------------------------------------------+
//| ������������� ��������                                           |
//+------------------------------------------------------------------+
int OnInit()
{
 history_start=TimeCurrent(); //�������� ����� ������� �������� ��� ��������� �������� �������
 // �������� ���������� DrawExtremums M15
 handleDE_M1 = DoesIndicatorExist(_Symbol,PERIOD_M1,"DrawExtremums");
 if (handleDE_M1 == INVALID_HANDLE)
  {
   handleDE_M1 = iCustom(_Symbol,PERIOD_M1,"DrawExtremums");
   if (handleDE_M1 == INVALID_HANDLE)
    {
     Print("�� ������� ������� ����� ���������� DrawExtremums �� M1");
     return (INIT_FAILED);
    }
   SetIndicatorByHandle(_Symbol,_Period,handleDE_M1);
  }        
  
  opBuy = OP_BUY;
  opSell= OP_SELL;
  
 //������� ������� ������ ��� ����������� ��������� ������ ����
 isNewBarM1= new CisNewBar(_Symbol,PERIOD_M1);
 // ������� ������� ������� ����������� �������
 trendM1 = new CTrendChannel(0,_Symbol,PERIOD_M1,handleDE_M1,percent);
 // ������ ������� ���������� ������� �������
 firstUploadedM1 = trendM1.UploadOnHistory();
 
 handle_aATR_M1=iMA(_Symbol,PERIOD_M1,100,0,MODE_EMA,iATR(_Symbol,PERIOD_M1,30));        
 
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
 {
  delete isNewBarM1;
  delete trendM1;
 }

void OnTick()
{
 ctm.OnTick();
 pos_info.type = OP_UNKNOWN;
 signalM1  = 0;

 // ���� ��� �� ��������� ����������
 if (!firstUploadedM1)
  firstUploadedM1 = trendM1.UploadOnHistory();
  
 // ���� �� ��� ������ �� ���� ����������� ����������, �� �������
 if (!firstUploadedM1)
  return;  

 if(isNewBarM1.isNewBar())
 {
  // �������� ������ �� M1 
  GetTradeSignal(PERIOD_M1, handle_aATR_M1, M1_supremacyPercent, pos_info);
  // ���� ��� ��������� ������ ����������
  if (trendM1.GetTrendByIndex(0)!=NULL && trendM1.GetTrendByIndex(1)!=NULL)
   { 
    // ���� ���������� ����� � ������� ������ � ��� ��������� ������ � ��������������� �������
    if (pos_info.type == opBuy && trendM1Now &&  trendM1.GetTrendByIndex(0).GetDirection() == 1/* && trendM1.GetTrendByIndex(1).GetDirection() == -1*/ )
     signalM1 = 1;
    else if (pos_info.type == opSell  && trendM1Now &&  trendM1.GetTrendByIndex(0).GetDirection() == -1 /*&& trendM1.GetTrendByIndex(1).GetDirection() == 1*/ )
     signalM1 = -1; 
    else
     signalM1 = 0;    
   }
 }
 if( (signalM1 == 1 || signalM1 == -1 ) )
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
   trendM1.UploadOnEvent(sparam,dparam,lparam);
   trendM1Now = trendM1.IsTrendNow();
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

 if(GreatDoubles(MathAbs(open_buf[0] - close_buf[0]), ave_atr_buf[0]*(1 + supremacyPercent)))
 {
  if(LessDoubles(close_buf[0], open_buf[0])) // �� ��������� ���� close < open (��� ����)
  {   
   
   pos.tp=(int)MathCeil((MathAbs(open_buf[0] - close_buf[0])/_Point)*(1+profitPercent));
   pos.sl=CountStoploss(tf,-1);
   
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
   pos.sl = CountStoploss(tf,1);
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
int CountStoploss(ENUM_TIMEFRAMES period,int point)
{
 MqlRates rates[];
 double price;
 if (CopyRates(_Symbol,period,0,1,rates) < 1)
  {
   return (0);
  }
 // ���� ����� ����������� �����
 if (point == 1)
  {
   price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  }
 // ���� ����� ��������� ����
 if (point == -1)
  {
   price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  }
 return( int( MathAbs(price - (rates[0].open+rates[0].close)/2) / _Point) );
}