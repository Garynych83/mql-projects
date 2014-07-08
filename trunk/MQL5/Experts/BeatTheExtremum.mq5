//+------------------------------------------------------------------+
//|                                              BeatTheExtremum.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <TradeManager\TradeManager.mqh>   // �������� ����������
#include <BlowInfoFromExtremums.mqh>       // ���������� ��� ��������� ���������� �� ����������

// �����, ��������� �� �������� ����������

// ��������� ����������
double currentPrice;                // ���������� �������� ������� ����
ENUM_EXTR_USE   lastExtrType;       // ��� ���������� ����������
ENUM_EXTR_USE   curExtrType;        // ��� �������� ����������
double          lastExtrValue;      // �������� ���������� ����������
bool            extrBeaten = false; // ���� �������� ����������

CTradeManager *ctm;                 // �������� ����������
CBlowInfoFromExtremums *blowInfo;   // ������ ������ ��� ��������� ���������� �� �����������
CChartObjectHLine  horLine;         // ������ ������ �������������� �����
int OnInit()
  {
   ctm   = new CTradeManager();
   if (ctm == NULL)
    return (INIT_FAILED);
   blowInfo = new CBlowInfoFromExtremums(_Symbol,_Period);
   if (blowInfo == NULL)
    return (INIT_FAILED); 
   if (blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )
    {
     lastExtrType = blowInfo.GetLastExtrType(); // ��������� ��� ���������� ����������  
     if (lastExtrType == EXTR_HIGH)
       {
        lastExtrValue = blowInfo.GetExtrByIndex(EXTR_LOW,1).price;  // �������� �������� ���������� ����������
       }
     else if (lastExtrType == EXTR_LOW)
       {
        lastExtrValue = blowInfo.GetExtrByIndex(EXTR_HIGH,1).price; // �������� �������� ���������� ����������
       }
     else 
      return (INIT_FAILED);
     }
    else
     return (INIT_FAILED);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // ������� �������
   delete ctm;
   delete blowInfo;
  } 

void OnTick()
  {
   ctm.OnTick();
   if ( blowInfo.Upload(EXTR_BOTH,TimeCurrent(),1000) )    // ���� ������� �������� ������ �� �����������
    {
     
     currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);  // �������� ������� ����
     curExtrType  = blowInfo.GetLastExtrType();            // �������� �������� ���������� ����������
     
     // ��������� ��������� ��� ��� ��������
     if (curExtrType == EXTR_HIGH)
       curExtrType = EXTR_LOW;
     else if (curExtrType == EXTR_LOW)
       curExtrType = EXTR_HIGH;
     
     
     
     if (curExtrType != lastExtrType)                      // ���� ������ ��������������� ���������
      {

        // �� �������� ������� ���������
        lastExtrType = curExtrType;
        // � ��� ��������
        if (lastExtrType == EXTR_HIGH)
         lastExtrValue = blowInfo.GetExtrByIndex(EXTR_LOW,1).price;
        if (lastExtrType == EXTR_LOW)
         lastExtrValue = blowInfo.GetExtrByIndex(EXTR_HIGH,1).price;         
        // � ���� �������� ���������� �������� � false
        extrBeaten = false;
      }       
     
     Comment("��������� ��������� = ",DoubleToString(lastExtrValue) ); 
     horLine.Create(0,"kolk",0,lastExtrValue);
   
     
      
     if (lastExtrType == EXTR_HIGH && !extrBeaten)         // ���� ��������� ��������� HIGH � � ���������� ��������� �� ������
      {
        //�� ���������, ������ �� ���������
        if (currentPrice < lastExtrValue)
          {
           // ��������� �������
           ctm.OpenUniquePosition(_Symbol,_Period,OP_SELL,1.0);
           // � ���������� ���� �������� ���������� � true
           extrBeaten = true;
          }
      }
     if (lastExtrType == EXTR_LOW && !extrBeaten)         // ���� ��������� ��������� HIGH � � ���������� ��������� �� ������
      {
        //�� ���������, ������ �� ���������
        if (currentPrice > lastExtrValue)
          {
           // ��������� �������
           ctm.OpenUniquePosition(_Symbol,_Period,OP_BUY,1.0);
           // � ���������� ���� �������� ���������� � true
           extrBeaten = true;
          }
      }      
      
      
    } // ����� Upload
  }