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

// ��������� � ��������� 

// ��������� ������������ ���� ������������ ������
#define no_location     0
#define up_location     1
#define down_location   2
#define inside_location 3

// ��������� �������
struct bufferLevel
 {
  double price[];
  double atr[];
 };

int     handle19Lines;   // ����� ���������� 19Lines
int     indexBuffer;     // ������ ������
int     stopLoss;        // ���� ����
int     takeProfit;      // ���� ������   
double  buffer19Lines[]; // ����� 19Lines
double  curPrice;        // ������� ����

// ������ ������� 
bufferLevel buffers[20];
int         bufferState[20];        // ����� ��������� ������� ���� ������������ ������

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
   ctm = new CTradeManager();
   ArrayFill(bufferState,0,20,0);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ArrayFree(buffer19Lines);
   IndicatorRelease(handle19Lines);
   delete ctm;
  }

void OnTick()
  {
   ctm.OnTick();
   curPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  // �������� ������� ����
   if (UploadBuffers())
    {
     ChangeLevelState ();    // ������ ������� ���� ������������ �������
     if (indexBuffer != -1)  // ���� ����� ���� ������� ��� ������
      {
        if ( bufferState[indexBuffer] == up_location)   // ���� � ��������� ������ ���� ��������� ���� ������, �� ���� ������� ������� ����� �����
          {
            stopLoss   = int( (buffers[indexBuffer].price[0]-buffers[indexBuffer].atr[0]) / _Point );  // ���� ����
            takeProfit = int( GetClosestLevel (1) );                                                   // ���� ������
            ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1,stopLoss,takeProfit);
          }
        if ( bufferState[indexBuffer] == down_location) // ���� � ��������� ������ ���� ��������� ���� ������, �� ���� ������� ������� ������ ����
          {
            stopLoss   = int( (buffers[indexBuffer].price[0]+buffers[indexBuffer].atr[0]) / _Point );  // ���� ����
            takeProfit = int( GetClosestLevel (-1) );                                                  // ���� ������
            ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,1,stopLoss,takeProfit);          
          }
          
      }
    }
  }
  
  
void  ChangeLevelState ()   // �������� �� ������� � ���������� ����� ���� ������, ������� ������� �������
 {
   indexBuffer = -1;   // ������������ ������ ������
   for (int index=0;index<20;index++)
    {
     // ���� ���� ������
     if (GreatDoubles(curPrice,buffers[index].price[0]+buffers[index].atr[0]) )
      {
        if (bufferState [index] == down_location)
          {
           indexBuffer = index;
           return;
          }
        bufferState [index] = up_location;
      }
     // ���� ���� ������
     else if (LessDoubles(curPrice,buffers[index].price[0]-buffers[index].atr[0]) )
      {
        if (bufferState [index] == up_location)
          {
           indexBuffer = index;
           return;
          }
        bufferState [index] = down_location;
      }
          
    }
 }
  
bool UploadBuffers ()   // �������� ��������� �������� �������
 {
  int copiedPrice;
  int copiedATR;
  for (int index=0;index<20;index++)
   {
    copiedPrice = CopyBuffer(handle19Lines,index*2,  0,1,  buffers[index].price);
    copiedATR   = CopyBuffer(handle19Lines,index*2+1,0,1,buffers[index].atr);
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
             tmpLen = curPrice - buffers[index].price[0] + buffers[index].atr[0] ;
             if (tmpLen < len)
              len = tmpLen;
           }
          else
           {
            len =  curPrice - buffers[index].price[0] + buffers[index].atr[0];
            foundLevel = true;
           }
         }

       }     
       
      break;
   }
   return (len);
  }