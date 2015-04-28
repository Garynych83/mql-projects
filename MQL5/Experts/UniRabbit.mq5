//+------------------------------------------------------------------+
//|                                            FollowWhiteRabbit.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+---------------------------------////////////////////////////---------------------------------+
//| ������� FollowWhiteRabbit                                        |
//+------------------------------------------------------------------+
//����������� ����������� ���������
#include <Lib CIsNewBar.mqh>
#include <TradeManager/TradeManager.mqh> // 
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <ColoredTrend/ColoredTrendUtilities.mqh> 
#include <CTrendChannel.mqh> // ��������� ���������
//���������
#define KO 3 //����������� ��� ������� �������� �������, �� ������� ��� ������� ����������� ���� ������ ������ ��������� ����������� ���� ����
#define SPREAD 30 // ������ ������ 
//�������� ������������� ���������
input string base_param = ""; // ������� ���������
input double lot = 1; // ���
input double percent = 0.1; // �������
input bool useM1 = true; // ������������ M1
input bool useM5 = true; // ������������ M5
input bool useM15 = true; // ������������ M15 
input double M1_supremacyPercent  = 5;//�������, ��������� ��� M1 ������ �������� ��������
input double M5_supremacyPercent  = 3;//�������, ��������� ��� M5 ������ �������� ��������
input double M15_supremacyPercent  = 1;//�������, ��������� ��� M15 ������ �������� ��������
input double profitPercent = 0.5;// ������� �������                                                          
input int priceDifference = 50;//Price Difference
input string filters_param = ""; // �������
input bool useTwoTrends = true; // �� ���� ��������� �������
input bool useChannel = true; // �������� ������ ������
input bool useClose = true; // �������� ������� � ��������������� ������
input bool use19Lines = true; // 19 �����
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
int handle_aATR_M1;
int handle_aATR_M5;
int handle_aATR_M15;
int handleDE_M1;
int handleDE_M5;
int handleDE_M15;
int handle19Lines; 
//��������� ������� � ���������
SPositionInfo pos_info;
STrailing     trailing;
double volume = 1.0;   //����� 
// ���������� ��� ��������� ��������
int signalM1;
int signalM5;
int signalM15;
// ����� �������� ������ 
bool trendM1Now = false;
bool trendM5Now = false;
bool trendM15Now = false;
// ����������� �������� �������
int posOpenedDirection = 0;
// ����� ������ �������� �������
bool firstUploadedM1 = false; 
bool firstUploadedM5 = false;
bool firstUploadedM15 = false;
// ������� ������� �� 
ENUM_TIMEFRAMES eldPeriodForM1 = GetTopTimeframe(PERIOD_M1); 
ENUM_TIMEFRAMES eldPeriodForM5 = GetTopTimeframe(PERIOD_M5); 
ENUM_TIMEFRAMES eldPeriodForM15 = GetTopTimeframe(PERIOD_M15); 

//+------------------------------------------------------------------+
//| ������������� ��������                                           |
//+------------------------------------------------------------------+
int OnInit()
{
 history_start=TimeCurrent(); //�������� ����� ������� �������� ��� ��������� �������� �������
 
 //----------- ��������� ����������� DrawExtremums
 
 // �������� ���������� DrawExtremums M1
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
    
 // �������� ���������� DrawExtremums M5
 handleDE_M5 = DoesIndicatorExist(_Symbol,PERIOD_M5,"DrawExtremums");
 if (handleDE_M5 == INVALID_HANDLE)
  {
   handleDE_M5 = iCustom(_Symbol,PERIOD_M5,"DrawExtremums");
   if (handleDE_M5 == INVALID_HANDLE)
    {
     Print("�� ������� ������� ����� ���������� DrawExtremums �� M5");
     return (INIT_FAILED);
    }
   SetIndicatorByHandle(_Symbol,_Period,handleDE_M5);
  }    
  
 // �������� ���������� DrawExtremums M15
 handleDE_M15 = DoesIndicatorExist(_Symbol,PERIOD_M15,"DrawExtremums");
 if (handleDE_M15 == INVALID_HANDLE)
  {
   handleDE_M15 = iCustom(_Symbol,PERIOD_M15,"DrawExtremums");
   if (handleDE_M15 == INVALID_HANDLE)
    {
     Print("�� ������� ������� ����� ���������� DrawExtremums �� M15");
     return (INIT_FAILED);
    }
   SetIndicatorByHandle(_Symbol,_Period,handleDE_M15);
  }    
  //----------- ����� ��������� ���������� DrawExtremums
        
  //----------- ��������� ���������� NineTeenLines
  handle19Lines = DoesIndicatorExist(_Symbol,_Period,"NineTeenLines");
  if (handle19Lines == INVALID_HANDLE)
   {
    handle19Lines = iCustom(_Symbol,_Period,"NineTeenLines");
    if (handle19Lines == INVALID_HANDLE)
     {
      Print("�� ������� ������� ����� ���������� NineTeenLines");
      return (INIT_FAILED);
     }
    SetIndicatorByHandle(_Symbol,_Period,handle19Lines);
   } 
  //---------- ����� ��������� NineTeenLines
   
  opBuy = OP_BUY;
  opSell= OP_SELL;
  
 //----------- ������� ������� ������ ��� ����������� ��������� ������ ����
 isNewBarM1= new CisNewBar(_Symbol,PERIOD_M1);
 isNewBarM5= new CisNewBar(_Symbol,PERIOD_M5);
 isNewBarM15= new CisNewBar(_Symbol,PERIOD_M15);  
 
 //----------- ������� ������� ������� ����������� �������
 trendM1 = new CTrendChannel(0,_Symbol,PERIOD_M1,handleDE_M1,percent);
 trendM5 = new CTrendChannel(0,_Symbol,PERIOD_M5,handleDE_M5,percent);
 trendM15 = new CTrendChannel(0,_Symbol,PERIOD_M15,handleDE_M15,percent);  
 // ������ ������� ���������� ������� �������
 firstUploadedM1 = trendM1.UploadOnHistory();
 firstUploadedM5 = trendM5.UploadOnHistory();
 firstUploadedM15 = trendM15.UploadOnHistory();  
 
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
  delete isNewBarM5;
  delete isNewBarM15;
  delete trendM1;
  delete trendM5;
  delete trendM15;
 }

void OnTick()
{
 int tempPosDirection=0;
 ctm.OnTick();
 pos_info.type = OP_UNKNOWN;
 signalM1  = 0;
 signalM5  = 0;
 signalM15 = 0;
 // ���� �� ������� �� ���� �������
 if (ctm.GetPositionCount() == 0)
  posOpenedDirection = 0;

 // ���� ��� �� ��������� ���������� �� M1
 if (!firstUploadedM1)
  firstUploadedM1 = trendM1.UploadOnHistory();
  
 // ���� ��� �� ��������� ���������� �� M5
 if (!firstUploadedM5)
  firstUploadedM5 = trendM5.UploadOnHistory();  
  
 // ���� �� ��� ������ �� ���� ����������� ����������, �� �������
 if (!firstUploadedM1 || !firstUploadedM5)
  return;  
  
 // ��������� �������� �� M1
 if(isNewBarM1.isNewBar()>0)
 {
  // �������� ������ �� M1 
  GetTradeSignal(PERIOD_M1, handle_aATR_M1, M1_supremacyPercent, pos_info);
  
  // ���� ��� ��������� ������ ����������
  if (trendM1.GetTrendByIndex(0)!=NULL && trendM1.GetTrendByIndex(1)!=NULL)
   { 
    // ���� ���������� ����� � ������� ������ � ��� ��������� ������ � ��������������� �������
    if (pos_info.type == opBuy  )
     {
      tempPosDirection = 1;
      signalM1 = 1;
      // ������������ �������
      if (trendM1.IsTrendNow() && TestTrendsDirection(0,1) && useTwoTrends) // ������ ���� ��������� ������� ��� ������� ������� �������� ������
       signalM1 = 0;
      if (trendM1.IsTrendNow() && TestLargeBarOnChannel(PERIOD_M1) && useChannel) // ������ �������� �������� ���� ������ ������
       signalM1 = 0;
      if (!FilterBy19Lines(1,PERIOD_M1,0) && use19Lines)
       signalM1 = 0;
     }
    else if (pos_info.type == opSell )
     {
      tempPosDirection = -1;
      signalM1 = -1;
      // ������������ �������
      if (trendM1.IsTrendNow() && TestTrendsDirection(0,-1) && useTwoTrends) // ������ ���� ��������� ������� ��� ������� ������� �������� ������
       signalM1 = 0; 
      if (trendM1.IsTrendNow() && TestLargeBarOnChannel(PERIOD_M1) && useChannel) // ������ �������� �������� ���� ������ ������
       signalM1 = 0;       
      if (!FilterBy19Lines(-1,PERIOD_M1,0) && use19Lines)
       signalM1 = 0;
     }
    else
     {
      tempPosDirection = 0;
      signalM1 = 0;  
     }
       
   }
 }
 
 // ��������� �������� �� M5
 if(isNewBarM5.isNewBar()>0)
 {
  // �������� ������ �� M5 
  GetTradeSignal(PERIOD_M5, handle_aATR_M5, M5_supremacyPercent, pos_info);
  
  // ���� ��� ��������� ������ ����������
  if (trendM5.GetTrendByIndex(0)!=NULL && trendM5.GetTrendByIndex(1)!=NULL)
   { 
    // ���� ���������� ����� � ������� ������ � ��� ��������� ������ � ��������������� �������
    if (pos_info.type == opBuy  )
     {
      tempPosDirection = 1;
      signalM5 = 1;
      // ������������ �������
      if (trendM5.IsTrendNow() && TestTrendsDirection(1,1) && useTwoTrends) // ������ ���� ��������� ������� ��� ������� ������� �������� ������
       signalM5 = 0;
      if (trendM5.IsTrendNow() && TestLargeBarOnChannel(PERIOD_M5) && useChannel) // ������ �������� �������� ���� ������ ������
       signalM5 = 0;
      if (!FilterBy19Lines(1,PERIOD_M5,0) && use19Lines)
       signalM5 = 0;
     }
    else if (pos_info.type == opSell )
     {
      tempPosDirection = -1;
      signalM5 = -1;
      // ������������ �������
      if (trendM5.IsTrendNow() && TestTrendsDirection(1,-1) && useTwoTrends) // ������ ���� ��������� ������� ��� ������� ������� �������� ������
       signalM5 = 0; 
      if (trendM5.IsTrendNow() && TestLargeBarOnChannel(PERIOD_M5) && useChannel) // ������ �������� �������� ���� ������ ������
       signalM5 = 0;       
      if (!FilterBy19Lines(-1,PERIOD_M5,0) && use19Lines)
       signalM5 = 0;
     }
    else
     {
      tempPosDirection = 0;
      signalM5 = 0;  
     }
       
   }
 } 
 
 if( ( useM1 && (signalM1 == 1 || signalM1 == -1) || useM5 && (signalM5 == 1 || signalM5 == -1) ) && (InputFilter() || !checkFilter) )
 {
  posOpenedDirection = tempPosDirection;
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
   int newDirection;
   trendM1.UploadOnEvent(sparam,dparam,lparam);
   trendM1Now = trendM1.IsTrendNow();
   
   // ���� ������ ����� ����� � �� ���������� ������ �������� ������� �� ������� ���������������� ������
   if (trendM1Now && useClose )
    {
     newDirection = trendM1.GetTrendByIndex(0).GetDirection();
     // ���� ������ ��������������� ����������� ������� �����
     if (posOpenedDirection !=0 && newDirection == -posOpenedDirection && ctm.GetPositionCount() > 0 )
      {
       // ��������� �������
       ctm.ClosePosition(0);
       posOpenedDirection = 0;
      }
    }
    
   trendM5.UploadOnEvent(sparam,dparam,lparam);
   trendM5Now = trendM5.IsTrendNow();
   
   // ���� ������ ����� ����� � �� ���������� ������ �������� ������� �� ������� ���������������� ������
   if (trendM5Now && useClose )
    {
     newDirection = trendM5.GetTrendByIndex(0).GetDirection();
     // ���� ������ ��������������� ����������� ������� �����
     if (posOpenedDirection !=0 && newDirection == -posOpenedDirection && ctm.GetPositionCount() > 0 )
      {
       // ��������� �������
       ctm.ClosePosition(0);
       posOpenedDirection = 0;
      }
    }    
    
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
 if (CopyRates(_Symbol,period,1,1,rates) < 1)
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
 //PrintFormat("price = %.05f open = %.05f close = %.05f",price,rates[0].open,rates[0].close);
      
 return( int( MathAbs(price - (rates[0].open+rates[0].close)/2) / _Point) );
}

// �������

// ������� ���������� true, ���� ��������� ��� ������ � ���� �������
bool TestTrendsDirection (int type,int direction)
 {
  switch (type)
   {
    // M1
    case 0:
     if (trendM1.GetTrendByIndex(0).GetDirection() == direction && trendM1.GetTrendByIndex(1).GetDirection() == direction)
       return (true);
    break; 
    // M5
    case 1:
     if (trendM5.GetTrendByIndex(0).GetDirection() == direction && trendM5.GetTrendByIndex(1).GetDirection() == direction)
       return (true);
    break; 
    // M15
    case 2:
     if (trendM15.GetTrendByIndex(0).GetDirection() == direction && trendM15.GetTrendByIndex(1).GetDirection() == direction)
       return (true);
    break;         
   }
  return (false);
 }

// ������� ��� ��������, ��� ��� �������� ������ ������
bool TestLargeBarOnChannel (ENUM_TIMEFRAMES period) // ������� ��������� 
 {
  double priceLineUp;
  double priceLineDown;
  double closeLargeBar[];
  datetime timeBuffer[];
  if (CopyClose(_Symbol,period,1,1,closeLargeBar) < 1 || CopyTime(_Symbol,period,1,1,timeBuffer) < 1) 
   {
    Print("�� ������� ���������� ����� ���� �������� ����������� ����");
    return (false);
   }
  priceLineUp = trendM1.GetTrendByIndex(0).GetPriceLineUp(timeBuffer[0]);
  priceLineDown = trendM1.GetTrendByIndex(0).GetPriceLineDown(timeBuffer[0]);
  if ( LessOrEqualDoubles( closeLargeBar[0],priceLineUp) && GreatOrEqualDoubles(closeLargeBar[0],priceLineDown) )
   return (true);
  return (false);
 }
 
bool FilterBy19Lines (int direction,ENUM_TIMEFRAMES period,int stopLoss)
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
 
// ������ �� ���������� �������������� �������
bool  InputFilter ()
 {
  // ���� ��� ������� �� BUY (�.�. ��� ������������)
  if (signalM1!=1 && signalM5!=1)
   return(true);
  // ���� ��� ������� �� SELL (�.�. ��� ������������)
  if (signalM1!=-1 && signalM5!=-1)
   return(true);
  return(false);
 } 