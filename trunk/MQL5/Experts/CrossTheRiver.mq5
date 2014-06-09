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

int     handlePBI;   // ����� PriceBasedIndicator

double  bufferPBI[]; // ����� PBI

// ��������� �������
struct bufferLevel
 {
  double price[];
  double atr[];
 };


// ������ ������� 
bufferLevel buffers[20];

int OnInit()
  {
   handlePBI = iCustom(_Symbol,_Period,"PriceBasedIndicator");
   if (handlePBI == INVALID_HANDLE)
    {
     Print("�� ������� ������� ����� ���������� PricaBasedIndicator");
     return (INIT_FAILED);
    }
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ArrayFree(bufferPBI);
   IndicatorRelease(handlePBI);
  }

void OnTick()
  {
   
  }
  
  
// ���������� ��������� ������� � ������� ����
 double GetClosestLevel (int direction) 
  {
   double cuPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
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
        if ( GreatDoubles((buffers[index].price[0]-buffers[index].atr[0]),cuPrice)  )
         {
          if (foundLevel)
           {
             tmpLen = buffers[index].price[0] - buffers[index].atr[0] - cuPrice;
             if (tmpLen < len)
              len = tmpLen;  
           }
          else
           {
            len = buffers[index].price[0] - buffers[index].atr[0] - cuPrice;
            foundLevel = true;
           }
         }
       }
     break;
     case -1: // ������� �����
      for (index=0;index<20;index++)
       {
        // ���� ������� ����
        if ( LessDoubles((buffers[index].price[0]+buffers[index].atr[0]),cuPrice)  )
          {
          if (foundLevel)
           {
             tmpLen = cuPrice - buffers[index].price[0] + buffers[index].atr[0] ;
             if (tmpLen < len)
              len = tmpLen;
           }
          else
           {
            len =  cuPrice - buffers[index].price[0] + buffers[index].atr[0];
            foundLevel = true;
           }
         }

       }     
       
      break;
   }
   return (len);
  }