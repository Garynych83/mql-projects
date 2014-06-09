//+------------------------------------------------------------------+
//|                                                CrossTheRiver.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| �������, ���������� �� �������� ������                           |
//+------------------------------------------------------------------+

// ���������� ����������
#include <TradeManager\TradeManager.mqh>
#include <CompareDoubles.mqh>

sinput string base_Str                             = "";                 // ������� ���������
input double lot                                   = 0.1;                // ������ ����
input ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_PBI;               // ��� ���������
input int priceDifference                          = 0;                  // ������� ���
input int ADD_TO_STOP_LOSS                         = 50;                 // �������� � ���� �����

sinput string pbi_Str                              = "";                 // ��������� PBI
input double  percentage_ATR_cur                   = 2;   
input double  difToTrend_cur                       = 1.5;
input int     ATR_ma_period_cur                    = 12;
input int     historyDepth                         = 1000;               // ������� �������

// ��������� � ��������� 

// ��������� ������������ ���� ������������ ������
#define no_location     0
#define up_location     1
#define down_location   2

// ��������� �������
struct bufferLevel
 {
  double price[];
  double atr[];
 };

int     handle19Lines;   // ����� ���������� 19Lines
int     handlePBI;       // ����� PriceBasedIndicator
int     indexBuffer;     // ������ ������
int     stopLoss;        // ���� ����
int     takeProfit;      // ���� ������   
double  buffer19Lines[]; // ����� 19Lines
double  curPrice;        // ������� ����

// ������ ������� 
bufferLevel buffers[20];            // �������� ����� �������
int         bufferState[20];        // ����� ��������� ������� ���� ������������ ������
double      bufferPrevLevel[20];    // ����� ��� �������� ���� ������ � ���������� ������

// �������� ����������
CTradeManager *ctm;

int OnInit()
  {
   handle19Lines = iCustom(_Symbol,_Period,"NineteenLines");
   if (handle19Lines == INVALID_HANDLE)
    {
     Print("�� ������� ������� ����� ���������� NineteenLines");
     return (INIT_FAILED);
    }
   handlePBI     = iCustom(_Symbol, _Period, "PriceBasedIndicator",historyDepth, percentage_ATR_cur, difToTrend_cur);
   if ( handlePBI == INVALID_HANDLE)
    {
     Print("�� ������� ������� ����� PriceBasedIndicator");
     return(INIT_FAILED);
    }    
   ctm = new CTradeManager();
   ArrayFill(bufferState,0,20,no_location);
   ArrayFill(bufferPrevLevel,0,20,0.0);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ArrayFree(buffer19Lines);
   IndicatorRelease(handle19Lines);
   IndicatorRelease(handlePBI);
   delete ctm;
  }

void OnTick()
  {
   ctm.OnTick();
   ctm.DoTrailing();    
   curPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  // �������� ������� ����
   if (UpdateBuffers())      // ���� ������ ���������� ������
    {
     ChangeLevelState ();    // ������ ������� ���� ������������ �������
     if (indexBuffer != -1)  // ���� ����� ���� ������� ��� ������
      {
        if ( bufferState[indexBuffer] == up_location)   // ���� � ��������� ������ ���� ��������� ���� ������, �� ���� ������� ������� ����� �����
          {
            stopLoss   = int( (curPrice - buffers[indexBuffer].price[0]+buffers[indexBuffer].atr[0]) / _Point );  // ���� ����
            takeProfit = int(  GetClosestLevel (1) / _Point);                                                     // ���� ������
            ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1,stopLoss,takeProfit,trailingType, 0, 0, 0, handlePBI, priceDifference);
          }
        if ( bufferState[indexBuffer] == down_location) // ���� � ��������� ������ ���� ��������� ���� ������, �� ���� ������� ������� ������ ����
          {
            stopLoss   = int ( (buffers[indexBuffer].price[0]+buffers[indexBuffer].atr[0] - curPrice) / _Point );  // ���� ����
            takeProfit = int (  GetClosestLevel (-1) / _Point );                                                   // ���� ������
            ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,1,stopLoss,takeProfit,trailingType, 0, 0, 0, handlePBI, priceDifference);          
          }
          
      }
     SavePreviewPrices ();  // ��������� ���������� �������� ��� �������  
    }
  }
  

void  SavePreviewPrices ()  // ������� ��������� ���������� �������� ��� �������
 {
  for (int index=0;index<20;index++)
   bufferPrevLevel[index] = buffers[index].price[0];
 }  
  
void  ChangeLevelState ()   // �������� �� ������� � ���������� ����� ���� ������, ������� ������� �������
 {
   indexBuffer = -1;   // ������������ ������ ������
   for (int index=0;index<20;index++)
    {
     // ���� ���� ������
     if (GreatDoubles(curPrice,buffers[index].price[0]+buffers[index].atr[0]) )
      {

        if (bufferState [index] == down_location && EqualDoubles (bufferPrevLevel [index],buffers [index].price[0]) )
          {
           indexBuffer = index;
          }
        bufferState [index] = up_location;
      }
     // ���� ���� ������
     else if (LessDoubles(curPrice,buffers[index].price[0]-buffers[index].atr[0]) )
      {
        if (bufferState [index] == up_location && EqualDoubles (bufferPrevLevel [index],buffers [index].price[0]))
          {
           indexBuffer = index;
          }
        bufferState [index] = down_location;
      }
          
    }
 }
  
bool UpdateBuffers ()   // �������� ��������� �������� �������
 {
  int copiedPrice;
  int copiedATR;
  for (int index=0;index<20;index++)
   {
    copiedPrice = CopyBuffer(handle19Lines,index*2,  0,1,  buffers[index].price);
    copiedATR   = CopyBuffer(handle19Lines,index*2+1,0,1,  buffers[index].atr);
    if (copiedPrice < 1 || copiedATR < 1)
     {
      Print("�� ������� ���������� ������ ���������� NineTeenLines");
      return (false);
     }
   }
  return(true);     
 }
  
  
// ���������� ��������� ������� � ������� ����
 double GetClosestLevel (int direction) 
  {
   double len = 0;  //���������� �� ���� �� ������
   double tmpLen; 
   bool   foundLevel = false;  // ���� ���������� ������� ������
   int    index;
   
   switch (direction)
    {
     case 1:  // ������� ������
      for (index=0;index<20;index++)
       {
        // ���� ������� ����
        if ( GreatDoubles((buffers[index].price[0]-buffers[index].atr[0]),curPrice)  )
         {
          if (foundLevel)
           {
             tmpLen = buffers[index].price[0] - buffers[index].atr[0] - curPrice;
             if (tmpLen < len)
              len = tmpLen;  
           }
          else
           {
            len = buffers[index].price[0] - buffers[index].atr[0] - curPrice;
            foundLevel = true;
           }
         }
       }
     break;
     case -1: // ������� �����
      for (index=0;index<20;index++)
       {
        // ���� ������� ����
        if ( LessDoubles((buffers[index].price[0]+buffers[index].atr[0]),curPrice)  )
          {
            
          if (foundLevel)
           {
             tmpLen = curPrice - buffers[index].price[0] - buffers[index].atr[0] ;
             if (tmpLen < len)
              len = tmpLen;
           }
          else
           {
            len =  curPrice - buffers[index].price[0] - buffers[index].atr[0];
            foundLevel = true;
           }
         }

       }     
       
      break;
   }
   return (len);
  }
  
