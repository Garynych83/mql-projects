//+------------------------------------------------------------------+
//|                                                      ONODERA.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
// ������������ ��������� 
#include <TradeManager\TradeManager.mqh>        // ����������� �������� ����������
#include <Lib CisNewBar.mqh>                    // ��� �������� ������������ ������ ����
#include <CompareDoubles.mqh>                   // ��� �������� �����������  ���
#include <Constants.mqh>                        // ���������� ��������
#define ADD_TO_STOPPLOSS 50
// ��������� ��������
#define BUY   1    
#define SELL -1

//+------------------------------------------------------------------+
//| �������, ���������� �� ����������� Blau                          |
//+------------------------------------------------------------------+                                                                 
   
// ������� ���������
sinput string base_param                           = "";                 // ������� ��������� ��������
input  int    risk                                 = 1;                  // ������ ����� � ���������   
input  int    top_level                            = 75;                 // Top Level
input  int    bottom_level                         = 25;                 // Bottom Level
input  ENUM_MA_METHOD      ma_method               = MODE_EMA;           // ��� �����������
input  ENUM_STO_PRICE      price_field             = STO_LOWHIGH;        // ������ ������� ����������   
input  int    q                                    = 2;                  // q - ������, �� �������� ����������� ��������
input  int    r                                    = 20;                 // r - ������ 1-� EMA, ������������� � ���������
input  int    s                                    = 1;                  // s - ������ 2-� EMA, ������������� � ���������� ������� �����������
input  int    u                                    = 1;                  // u - ������ 3-� EMA, ������������� � ���������� ������� �����������
// �������
CTradeManager    *ctm;                                                   // ��������� �� ������ �������� ����������
static CisNewBar *isNewBar;                                              // ��� �������� ������������ ������ ����
// ������ ����������� 
int handleSmydBlau;                                                      // ����� ���������� smydBlau
int handleStoc;                                                          // ����� ����������
int handle19Lines;                                                       // ����� NineTeenLines
// ��������� �������
SPositionInfo pos_info;                                                  // ���������� � �������
STrailing     trailing;                                                  // ���������� � ���������
// ���������� �������� 
double lastRightExtr=0;                                                  // �������� ��������� ���� ������� ���������� �����������
double riskSize;                                                         // ������ �����
// ������ 
double signalBuffer[];                                                   // ����� ��� ��������� ������� �� ���������� smydBlau
double dateRightExtr[];                                                  // ����� ��� ��������� ������� ������� ������� ���������� �����������
double stoc[];                                                           // ����� ����������
double levelPrices[10];                                                  // ����� ��� �������
int OnInit()
{
 // �������� ������ ��� ������ ��������� ����������
 isNewBar = new CisNewBar(_Symbol, _Period);
 ctm = new CTradeManager(); 
  
 // ������� ����� ���������� smyBlau
 handleSmydBlau = iCustom (_Symbol,_Period,"smydBLAU","",q,r,s,u);   
 if ( handleSmydBlau == INVALID_HANDLE )
 {
  Print("������ ��� ������������� �������� TradeDivOnBlau. �� ������� ������� ����� smydBlau");
  return(INIT_FAILED);
 }     
 // ������� ����� ���������� ����������
 handleStoc = iStochastic(_Symbol,_Period,5,3,3,ma_method,price_field);
 if ( handleStoc == INVALID_HANDLE)
 {
  Print("������ ��� ������������� �������� TradeDivOnBlau. �� ������� ������� ����� ����������"); 
  return(INIT_FAILED);
 }
 // ������� ����� ���������� NineTeenLines
 handle19Lines = iCustom(_Symbol,_Period,"NineteenLines");       
 if (handle19Lines == INVALID_HANDLE)
  {
   Print("�� ������� �������� ����� NineteenLines");
   return(INIT_FAILED);    
  }
 pos_info.tp = 0;
 //pos_info.volume = lot;
 pos_info.expiration = 0;
 pos_info.priceDifference = 0; 
 pos_info.sl = 0;
 pos_info.tp = 0; 
 
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
 
 // ��������� �������� �����
 riskSize = risk/100.0;
 
 return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
 // ������� ������ ������ TradeManager
 delete isNewBar;
 delete ctm;
 // ������� ��������� 
 IndicatorRelease(handleSmydBlau);
}

void OnTick()
{
 ctm.OnTick();
 // ���� ����������� ����� ���
   if (CopyBuffer(handleSmydBlau,1,0,1,signalBuffer) < 1 || CopyBuffer(handleSmydBlau,3,0,1,dateRightExtr) < 1 || CopyBuffer(handleStoc,0,0,1,stoc) < 1 )
    {
     PrintFormat("�� ������� ���������� ��� ������ Error=%d",GetLastError());
     return;
    }   
  
   if ( signalBuffer[0] == BUY)  // �������� ����������� �� �������
     { 
      // ���� ��������� ���������� ������ �� ����� �����������
      if ( !EqualDoubles( lastRightExtr,dateRightExtr[0]) && stoc[0] < bottom_level ) 
       {     
          // �� ��������� ������� �� BUY
          pos_info.type = OP_BUY;
          // ������ ���� ����
          pos_info.sl  =  CountStopLoss(1,SymbolInfoDouble(_Symbol,SYMBOL_BID));
          // ��������� ������ ����
          pos_info.volume = CountLotByStopLoss(SymbolInfoDouble(_Symbol,SYMBOL_BID),pos_info.sl);
          if (pos_info.volume!=0)
           ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing);                  
        }
       // ��������� ��������� ������
       lastRightExtr = dateRightExtr[0];
     }
   if ( signalBuffer[0] == SELL) // �������� ����������� �� �������
     { 
      // ���� ��������� ���������� ������ �� ����� �����������
      if ( !EqualDoubles( lastRightExtr,dateRightExtr[0]) && stoc[0] > top_level )
       {
          // �� ��������� ������� �� SELL
          pos_info.type = OP_SELL;
          // ������ ���� ����
          pos_info.sl = CountStopLoss(-1,SymbolInfoDouble(_Symbol,SYMBOL_ASK));
          // ��������� ������ ����
          pos_info.volume = CountLotByStopLoss(SymbolInfoDouble(_Symbol,SYMBOL_ASK),pos_info.sl);
          if (pos_info.volume!=0)
           ctm.OpenUniquePosition(_Symbol,_Period, pos_info, trailing);                   
       }
      //��������� ��������� ������ ��������� �����������
      lastRightExtr = dateRightExtr[0]; 
     }
}

// �������� ��������� �������� �������
bool UploadBuffers ()   
 {
  int copiedPrice;
  int indexPer;
  int indexBuff;
  int indexLines = 0;
  double tmpLevelBuff[];
  for (indexPer=0;indexPer<5;indexPer++)
   {
    for (indexBuff=0;indexBuff<2;indexBuff++)
     {
      copiedPrice = CopyBuffer(handle19Lines,indexPer*8+indexBuff*2+4,  0,1, tmpLevelBuff);
      if (copiedPrice < 1)
       {
        Print("�� ������� ���������� ������ ���������� NineTeenLines");
        return (false);
       }
      levelPrices[indexLines] = tmpLevelBuff[0];
      indexLines++;
     }
   }
  return(true);     
 }

// ���������� ���� ���� �� ������� NineTeenLines
int   CountStopLoss (int dealType, double currentPrice)
 {
  double closestLevel=0;  // ���� ���������� ������
  int ind;                // ��� ������� �� ������
  int stopLoss;           // ���� ���� � �������
  // ��������� ������ �������
  if (!UploadBuffers())
   return (0);
    // �������� �� ����� � ��������� ��������� ���� ������ �����
    for (ind=0;ind < 10; ind++)
     {
      // ���� ������� ������� �� Buy, ���� ������ ���� ���� �������� ������� , �� ��� ����� � ���� �������
      if (dealType == 1 && LessDoubles(levelPrices[ind],currentPrice) && GreatDoubles(levelPrices[ind],closestLevel)  )
       {
        // �� ��������� ���� ���������� ������
        closestLevel = levelPrices[ind]; 
       }
      // ���� ������� ������� �� Sell, ���� ������ ���� ���� �������� ������� , �� ��� ����� � ���� �������
      if (dealType == -1 && GreatDoubles(levelPrices[ind],currentPrice) && (LessDoubles(levelPrices[ind],closestLevel)||closestLevel==0) )
       {   
        // �� ��������� ���� ���������� ������
        closestLevel = levelPrices[ind];
       }       
     } 
  // ��������� ������ �����
  stopLoss = int( MathAbs(currentPrice-closestLevel)/_Point );
  // ���� stopLoss �������� ������ 100 �������, �� ���������� ��� � ������� 100 �������
  if (stopLoss < 100)
   stopLoss = 100; 
  // ���������� ���� ���� � �������
  return (stopLoss);
 }
 
// ������� ��������� ������ ���� � ���������� �� ���� ����� 
double  CountLotByStopLoss (double posOpenPrice,int stopLoss)
 {
  double balancePart;
  double Sp;
  double percentLot;
  // ��������� ������� ����� �� �������� �������, ������� �� ����� ��������
  balancePart = AccountInfoDouble(ACCOUNT_BALANCE)*riskSize;
  Sp = stopLoss*SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_PROFIT);
  //SymbolInfoInteger(_Symbol,
  percentLot = NormalizeDouble(balancePart / Sp, 2);
 // PrintFormat("������ ���� = %.02f, ������� ������� = %.05f, ��������� ����� = %.05f, ��������� ���� = %.05f ",percentLot, balancePart , Sp, SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_PROFIT)  );
  //Comment("������� ���� = ",DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE) ) );  
  return (percentLot);
 }