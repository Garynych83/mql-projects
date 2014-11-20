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

// ����������� ����������� ���������
#include <Lib CIsNewBar.mqh>
#include <TradeManager\TradeManager.mqh> 
// ���������
#define ADD_TO_STOPLOSS 50                                                      // ���������� ������ � ���� �����
#define DEPTH 30                                                                // ������� �������
#define SPREAD 30                                                               // ������ ������
#define KO 3                                                                    // ����������� ��� ������� �������� �������, �� ������� ��� ������� ����������� ���� ������ ������ ��������� ����������� ���� ���� 
// �������� ������������� ���������
input string baseParams = "";                                                   // ������� ���������
input double M1_supremacyPercent  = 5;                                          // �������, ��������� ��� M1 ������ �������� ��������
input double M5_supremacyPercent  = 3;                                          // �������, ��������� ��� M5 ������ �������� ��������
input double M15_supremacyPercent = 1;                                          // �������, ��������� ��� M15 ������ �������� ��������
input double profitPercent = 0.5;                                               // ������� �������                                            
input string orderParams = "";                                                  // ��������� �������
input ENUM_USE_PENDING_ORDERS pending_orders_type = USE_LIMIT_ORDERS;           // ��� ����������� ������                    
input int priceDifference = 50;                                                 // Price Difference
input string lockParams="";                                                     // ��������� �������� �� ����
input bool useLinesLock=false;                                                  // ���� ��������� ������� �� ���� �� ���������� NineTeenLines
input int    koLock  = 2;                                                       // ����������� ������� �� ����
// ��������� �������
struct bufferLevel
 {
  double price[];  // ���� ������
  double atr[];    // ������ ������
 };

// ���������� ���������� 
datetime history_start;
//�������� �����
CTradeManager ctm;          
// �������
double ave_atr_buf[1], close_buf[1], open_buf[1], pbi_buf[1];
bufferLevel buffers[8];                                                         // ����� �������

ENUM_TM_POSITION_TYPE opBuy, opSell;

CisNewBar *isNewBarM1;
CisNewBar *isNewBarM5;
CisNewBar *isNewBarM15;
// ������ �����������
int handle_PBI;
int handle_aATR_M1;
int handle_aATR_M5;
int handle_aATR_M15;
// ����� ���������� NineTeenLines
int handle_19Lines; 
// ��������� ������� � ���������
SPositionInfo pos_info;
STrailing     trailing;

double volume = 1.0;                                                           // ����� 
double lenClosestUp;                                                           // ���������� �� ���������� ������ ������
double lenClosestDown;                                                         // ���������� �� ���������� ������ ����� 
//+------------------------------------------------------------------+
//| ������������� ��������                                           |
//+------------------------------------------------------------------+

int OnInit()
  {
   history_start=TimeCurrent();        //--- �������� ����� ������� �������� ��� ��������� �������� �������

   switch (pending_orders_type)  //���������� priceDifference
   {
    case USE_LIMIT_ORDERS: //useLimitsOrders = true;
     opBuy  = OP_BUYLIMIT;
     opSell = OP_SELLLIMIT;
    break;
    case USE_STOP_ORDERS:
     opBuy  = OP_BUYSTOP;
     opSell = OP_SELLSTOP;
    break;
    case USE_NO_ORDERS:
     opBuy  = OP_BUY;
     opSell = OP_SELL;      
    break;
   }
   
   // ������� ������� ������ ��� ����������� ��������� ������ ����
   isNewBarM1      = new CisNewBar(_Symbol, PERIOD_M1);
   isNewBarM5      = new CisNewBar(_Symbol, PERIOD_M5);
   isNewBarM15     = new CisNewBar(_Symbol, PERIOD_M15);
   // ������� ����� PriceBasedIndicator
   handle_PBI      = iCustom(_Symbol, PERIOD_M15, "PriceBasedIndicator");
   handle_aATR_M1  = iMA(_Symbol,  PERIOD_M1,  100, 0, MODE_EMA, iATR(_Symbol,  PERIOD_M1,  30));
   handle_aATR_M5  = iMA(_Symbol,  PERIOD_M5,  100, 0, MODE_EMA, iATR(_Symbol,  PERIOD_M5,  30)); 
   handle_aATR_M15 = iMA(_Symbol,  PERIOD_M15, 100, 0, MODE_EMA, iATR(_Symbol,  PERIOD_M15, 30));  
     
   if ( handle_PBI == INVALID_HANDLE )
    {
     log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� �������� ����� ������ �� ��������������� �����������", MakeFunctionPrefix(__FUNCTION__) ) );  
     return (INIT_FAILED);
    }       
   // ���� ������������ ������� �� ���� �� NineTeenLines
   if (useLinesLock)
    {
     handle_19Lines = iCustom(_Symbol,_Period,"NineteenLines");     
     if (handle_19Lines == INVALID_HANDLE)
      {
       log_file.Write(LOG_DEBUG,StringFormat("%s ������ ��� ������������� �������� SimpleTrend. �� ������� �������� ����� NineteenLines",MakeFunctionPrefix(__FUNCTION__) ) );
       return (INIT_FAILED);
      }    
  }      
   trailing.trailingType      = TRAILING_TYPE_EASY_LOSSLESS;
   trailing.trailingStop      = 0;
   trailing.trailingStep      = 0;
   trailing.handleForTrailing = 0;
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  {
   ctm.OnTick();
   // ���� �� ���������� ������ �� ���� �� NineTeenLines
   if (useLinesLock)
    {
     // ���� �� ������� ���������� ������ NineTeenLines
     if (!Upload19LinesBuffers()) 
      {
       log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� ���������� ������ NineTeenLines",MakeFunctionPrefix(__FUNCTION__) ) );
       return;
      }
    }    
   pos_info.type = OP_UNKNOWN;
   if(isNewBarM1.isNewBar())
   {
    GetTradeSignal(PERIOD_M1, handle_aATR_M1, M1_supremacyPercent, pos_info); //���� �����������
   }
   if(isNewBarM5.isNewBar())
   {
    GetTradeSignal(PERIOD_M5, handle_aATR_M5, M5_supremacyPercent, pos_info);
   }  
   if(isNewBarM15.isNewBar())
   {
    GetTradeSignal(PERIOD_M15, handle_aATR_M15, M15_supremacyPercent, pos_info);
   }
   if (pos_info.type == opBuy || pos_info.type == opSell)
    {
     ctm.OpenUniquePosition(_Symbol, _Period, pos_info, trailing,SPREAD);
    }
  }

void OnTrade()
  {
   ctm.OnTrade();
   if (history_start != TimeCurrent())
   {
    history_start = TimeCurrent() + 1;
   }
  }

// ������� ��������� ��������� ������� (���������� ����������� ��������� �������) 
void GetTradeSignal(ENUM_TIMEFRAMES tf, int handle_atr, double supremacyPercent,SPositionInfo &pos)
{   
 // ���� �� ������� ���������� ��� ������ 
 if ( CopyClose  (_Symbol,tf,1,1, close_buf)    < 1 ||
      CopyOpen   (_Symbol,tf,1,1,open_buf)      < 1 ||
      CopyBuffer (handle_atr,0,0,1,ave_atr_buf) < 1 )
 {
  //�� ������� ��������� � ��� �� ������
  log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� ����������� ������ �� ������ �������� �������", MakeFunctionPrefix(__FUNCTION__) ) );    
  return;                                                 //� ������� �� �������
 }
 // ���� �� ������� ���������� ����� PBI  
 if( CopyBuffer(handle_PBI,4,1,1,pbi_buf) < 1)   
 {
  //�� ������� ��������� � ��� �� ������
  log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� ����������� ������ �� ���������������� ����������", MakeFunctionPrefix(__FUNCTION__) ) );   
  return;                                                                 //� ������� �� �������
 }
   
 if(GreatDoubles(MathAbs(open_buf[0] - close_buf[0]), ave_atr_buf[0]*(1 + supremacyPercent)))
 {
  if(LessDoubles(close_buf[0], open_buf[0])) // �� ��������� ���� close < open (��� ����)
  {  
    // ���� ������������ ������� �� NineTeenLines
    if (useLinesLock)
     { 
     // �������� ���������� �� ��������� ������� ����� � ������
     lenClosestUp   = GetClosestLevel(1);
     lenClosestDown = GetClosestLevel(-1);    
     // ���� �������� ������ ������� �� ����
     if (lenClosestDown != 0 &&
         LessOrEqualDoubles(lenClosestDown, lenClosestUp*koLock) )
         {        
          pos.type = OP_UNKNOWN;
          log_file.Write(LOG_DEBUG,StringFormat("%s �������� ������ ������� �� ���� �� SELL",MakeFunctionPrefix(__FUNCTION__) ) );
          return;
         }
     }   
   pos.tp = (int)MathCeil((MathAbs(open_buf[0] - close_buf[0]) / _Point) * (1 + profitPercent));
   pos.sl = CountStoploss(-1);
   // ���� ����������� ���� ������ � kp ���� ��� ����� ��� ������, ��� ����������� ���� ����
   if (pos.tp >= KO*pos.sl)
    pos.type = opSell;
   else
    {
     pos.type = OP_UNKNOWN;
     return;
    }
   
  }
  if(GreatDoubles(close_buf[0], open_buf[0]))
  { 
    // ���� ������������ ������� �� NineTeenLines
    if (useLinesLock)
     {
      Print("���������� ������ �� 19 ������");
      // �������� ���������� �� ��������� ������� ����� � ������
      lenClosestUp   = GetClosestLevel(1);
      lenClosestDown = GetClosestLevel(-1);
      // ���� �������� ������ �� ������ �� ����
      if (lenClosestUp != 0 && 
        LessOrEqualDoubles(lenClosestUp, lenClosestDown*koLock) )
         {
          pos.type = OP_UNKNOWN;
          log_file.Write(LOG_DEBUG,StringFormat("%s �������� ������ ������� �� ���� �� BUY",MakeFunctionPrefix(__FUNCTION__) ) );
          return;
         }   
     }     
   pos.tp = (int)MathCeil((MathAbs(open_buf[0] - close_buf[0]) / _Point) * (1 + profitPercent));
   pos.sl = CountStoploss(1);
   // ���� ����������� ���� ������ � kp ���� ��� ����� ��� ������, ��� ����������� ���� ����
   if (pos.tp >= KO*pos.sl)
    pos.type = opBuy;
   else
    {
     pos.type = OP_UNKNOWN;
     return;
    }
  }
   pos.expiration = 0; 
   pos.expiration_time = 0;
   pos.volume     = volume;
   pos.priceDifference = priceDifference; 
   // ���������� minProfit ��� ��� ���� �����
   trailing.minProfit = pos.sl*2;
  }
  ArrayInitialize(ave_atr_buf, EMPTY_VALUE);
  ArrayInitialize(close_buf,   EMPTY_VALUE);
  ArrayInitialize(open_buf,    EMPTY_VALUE);
  ArrayInitialize(pbi_buf,     EMPTY_VALUE);
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
  extrBufferNumber = 5; // maximum
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
  log_file.Write(LOG_DEBUG,StringFormat("%s �� ������� ����������� ����� bufferStopLoss", MakeFunctionPrefix(__FUNCTION__) ) );  
  return(0);
 }
 for(int i = 0; i < DEPTH; i++)
 {
  if (bufferStopLoss[i] > 0)
  {
   if (LessDoubles(direction*bufferStopLoss[i], direction*priceAB))
   {
    log_file.Write(LOG_DEBUG,StringFormat("%s price = %f; extr = %f",MakeFunctionPrefix(__FUNCTION__), priceAB, bufferStopLoss[i])  );      
    stopLoss = (int)(MathAbs(bufferStopLoss[i] - priceAB)/Point());// + ADD_TO_STOPPLOSS;
    Print("bufferStopLoss[i] = ",DoubleToString(bufferStopLoss[i]),
          "\npriceAB = ",DoubleToString(priceAB)
         );
    break;
   }
  }
 }
 if (stopLoss <= 0)  
 {
  log_file.Write(LOG_DEBUG,StringFormat("%s �� ��������� ���� ���� �� ����������", MakeFunctionPrefix(__FUNCTION__) ) );   
  stopLoss = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) + ADD_TO_STOPLOSS;
 }
 return(stopLoss);
}

bool Upload19LinesBuffers ()   // �������� ��������� �������� �������
 {
  int copiedPrice;
  int copiedATR;
  int indexPer;
  int indexBuff;
  int indexLines = 0;
  for (indexPer=1;indexPer<5;indexPer++)
   {
     for (indexBuff=0;indexBuff<2;indexBuff++)
      {
       copiedPrice = CopyBuffer(handle_19Lines,indexPer*8+indexBuff*2+4,  0,1,  buffers[indexLines].price);
       copiedATR   = CopyBuffer(handle_19Lines,indexPer*8+indexBuff*2+5,  0,1,buffers[indexLines].atr);
       if (copiedPrice < 1 || copiedATR < 1)
        {
         Print("�� ������� ���������� ������ ���������� NineTeenLines");
         return (false);
        }
       indexLines++;
     }
   }
  return(true);     
 }
 // ���������� ��������� ������� � ������� ����
 double GetClosestLevel (int direction) 
  {
   double cuPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double len = 0;  //���������� �� ���� �� ������
   double tmpLen; 
   int    index;
   int    savedInd;
   switch (direction)
    {
     case 1:  // ������� ������
      for (index=0;index<8;index++)
       {         
          // ���� ������� ����
          if ( GreatDoubles((buffers[index].price[0]-buffers[index].atr[0]),cuPrice)  )
            {
             tmpLen = buffers[index].price[0] - buffers[index].atr[0] - cuPrice;
             if (tmpLen < len || len == 0)
               {
                savedInd = index;
                len = tmpLen;
               }  
            }           
            
       }
     break;
     case -1: // ������� �����
      for (index=0;index<8;index++)
       {
        // ���� ������� ����
        if ( LessDoubles((buffers[index].price[0]+buffers[index].atr[0]),cuPrice)  )
          {
           tmpLen = cuPrice - buffers[index].price[0] - buffers[index].atr[0] ;
           if (tmpLen < len || len == 0)
            {
             savedInd = index;
             len = tmpLen;
            }
          }
       }     
      break;
   }
   return (len);
  }   