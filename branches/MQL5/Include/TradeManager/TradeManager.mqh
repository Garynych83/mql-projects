//+------------------------------------------------------------------+
//|                                                CTradeManager.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include "TradeManagerEnums.mqh"
#include "PositionOnPendingOrders.mqh"
#include "PositionArray.mqh"
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>
#include <CLog.mqh>
//���������� �������� � �����
#define N_COLUMNS 17
  
//#include <Graph\Graph.mqh>


int error = 0;
//+------------------------------------------------------------------+
//| ��������� ����� ���  �������� ����������� ���������� ��������    |
//+------------------------------------------------------------------+
 struct SysParam
  {

   uint nTrades;               //���������� �������
   uint nDeals;                //���������� ������
   uint nWinTrades;            //���������� ���������� �������
   uint nLoseTrades;           //���������� ��������� �������
   
   double shortTradeWinPer;    //������� ���������� �������� ������ (�� ����������)
   double longTradeWinPer;     //������� ���������� ������� ������ (�� ����������)
   double profitTradesPer;     //������� ���������� ������� (�� ����)
   double loseTradesPer;       //������� ����������� ������� (�� ����)
   
   double maxWinTrade;         //����� ������� ���������� �����
   double maxLoseTrade;        //����� ������� ��������� �����
   
   double medWinTrade;         //������� ���������� �����
   double medLoseTrade;        //������� ������� �����
   
   uint maxWinTradesN;         //������������ ����� ����������� ���������
   uint maxLoseTradesN;        //������������ ����� ����������� ����������
   
   double maxWinTradeSum;      //������������ ����������� �������
   double maxLoseTradeSum;     //������������ ����������� ������
      
  };
  

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CTradeManager
{
protected:
  ulong _magic;
  bool _useSound;
  string _nameFileSound;   // ������������ ��������� �����
  datetime _historyStart;
 // GraphModule  graphModule;   //����������� ������
  CPositionArray _positionsToReProcessing; ///������ �������, ����������� � ��������
  CPositionArray _openPositions;           ///������ ������� �������� �������
  CPositionArray _positionsHistory;        ///������ ������� ����������� �������
  

  
  //�������������� ���������  
  bool _pos_panel_draw;                     //���� ����������� �������
  
public:

  SysParam tmpParam;   //��������� �������� ������

  void CTradeManager(bool pos_panel_draw=false):  _useSound(true), _nameFileSound("expert.wav") 
  {
   _magic = MakeMagic();
   _historyStart = TimeCurrent(); 
   log_file.Write(LOG_DEBUG, StringFormat("%s �������� ������� CTradeManager", MakeFunctionPrefix(__FUNCTION__)));
   log_file.Write(LOG_DEBUG, StringFormat("%s History start: %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(_historyStart))); 
  
  /*
  
   graphModule.RenameGraph("�������� �������"); //��������� ����� ���������
   graphModule.SetElem("������");            //���������� ���������� �����        
   graphModule.SetElem("����");              //���������� ���� �������
   graphModule.SetElem("������");            //������ �������
   graphModule.SetElem("���");               //��� �������
   graphModule.SetElem("���� ����");         //���� ����
   graphModule.SetElem("���� ������");       //���������� ���� �������
   graphModule.SetElem("�����");             //����� 
   graphModule.SetElem("�������� ������");   //���� ���� ������  
   graphModule.SetElem("����� ��������");    //����� �������� ������� 
   graphModule.SetElem("���� ��������");     //���� ��������
   //graphModule.SetElem("����� ��������");  //����� �������� �������
   
   */
       
   _pos_panel_draw = pos_panel_draw;
  };
  
  //��������� ������ ��� ���������� ��������
  
  bool BackTest();   //������� �����, ����������� �������� ��������
  
  void GetNTrades();          //���������� ���������� ������� � �������                                       (�������)
  void GetNDeals();           //���������� ���������� ������  
  void GetNWinLoseTrades();   //���������� ���������� ���������� � ��������� �������                          (�������)
  void GetShortTradeWinPer(); //���������� ������� ���������� �������� ������ �� ��������� �� ���� ����������
  void GetLongTradeWinPer();  //���������� ������� ���������� ������� ������ �� ��������� �� ���� ����������
  void GetProfitTradesPer();  //���������� ������� ���������� ������� �� ��������� �� ����                    (�������)
  void GetLoseTradesPer();    //���������� �������  ��������� ������� �� ��������� �� ����                    (�������)
  void GetMaxWinTrade();      //���������� ����� ������� ���������� �����                                     (�������)
  void GetMaxLoseTrade();     //���������� ����� ������� ��������� �����                                      (�������)
  void GetMedWinTrade();      //���������� ������� ���������� �����                                           (�������)
  void GetMedLoseTrade();     //���������� ������� ��������� �����                                            (�������)
  void GetMaxWinTradesN();    //���������� ������������ ����� ����������� ���������� �������                  (�������)
  void GetMaxLoseTradesN();    //���������� ������������ ����� ����������� ��������� �������                  (�������)
  void GetMaxWinTradeSum();   //���������� ������������ ��
  void GetMaxLoseTradeSum();  //������������ ����������� ������  
  
  void   ZeroParam();          //������� ��������� ��������
  
  void   ShowBackTestResults();  //���������� ����������� �������� ��������
  
  //������� ������ TradeManager
  
  bool OpenPosition(string symbol, ENUM_TM_POSITION_TYPE type,double volume ,int sl, int tp, 
                    int minProfit, int trailingStop, int trailingStep, int priceDifference = 0);
  void ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action);
  bool ClosePosition(long ticket, color Color=CLR_NONE);     // �������� ������� �� ������
  bool ClosePosition(int i,color Color=CLR_NONE);            // �������� ������� �� ������� � ������� �������
  bool ClosePosition(string symbol, color Color=CLR_NONE);   // �������� ������� �� ������� 
  bool CloseReProcessingPosition(int i,color Color=CLR_NONE);
  long MakeMagic(string strSymbol = "");
  void DoTrailing();
  void Initialization();
  void Deinitialization();
  bool isMinProfit(string symbol);
  void OnTick();
  void OnTrade(datetime history_start);
  void SaveSituationToFile();
  bool LoadHistoryFromFile(); //��������� ������� �� �����
  private:
  ENUM_TM_POSITION_TYPE GetPositionType(string symbol);
  void SaveHistoryToFile();
  void DrawCurrentPosition(int index);  //����������� ������� �������
};
//+------------------------------------------------------------------+
//| ��������� ������ ���������� ��������                             |
//+------------------------------------------------------------------+

void CTradeManager::GetNTrades(void)      //�������� ���������� �������
 {
   tmpParam.nTrades = _positionsHistory.Total();
 }
 
void CTradeManager::GetLoseTradesPer(void)  //��������� ������� ��������� ������� �� ��������� �� ����
 {
  tmpParam.loseTradesPer = (double)(int)(tmpParam.nLoseTrades/tmpParam.nTrades);
 } 
 
void CTradeManager::GetProfitTradesPer(void)  //��������� ������� ���������� ������� �� ��������� �� ����
 {
  tmpParam.profitTradesPer = (double)(int)(tmpParam.nWinTrades/tmpParam.nTrades);
 }  
 
void CTradeManager::GetNWinLoseTrades(void)   //�������� ���������� ���������� � ��������� �������
 {
   uint index;
   tmpParam.nWinTrades = 0;    //�������� ���������� ���������� �������
   tmpParam.nLoseTrades = 0;   //�������� ���������� ��������� �������   
   GetNTrades();               //��������� ���������� �������
   uint total = tmpParam.nTrades;
   CPosition * pos;          //��������� �� �������
   for (index=0;index<total;index++)
    {
    pos  = _positionsHistory.Position(index); //��������� �� ������� �� �������
    //���� ���������� �����
    if (pos.getPosProfit()>0) 
     tmpParam.nWinTrades++;  //����������� ������� ���������� ������� �� �������
    //���� ��������� �����
    if (pos.getPosProfit()<0) 
     tmpParam.nLoseTrades++;  //����������� ������� ��������� ������� �� �������     
    }   
 } 


void CTradeManager::GetMaxWinTrade(void) //��������� ����� ������� ���������� �����
 {
   uint index;
   GetNTrades(); //��������� ���������� �������
   uint total = tmpParam.nTrades;
   CPosition * pos;  //��������� �� �������
   tmpParam.maxWinTrade = 0;
   Alert("N TRADES = ",total);
   for (index=0;index<total;index++)
    {
     Alert("<<<< ",index);
    pos  = _positionsHistory.Position(index); //��������� �� ������� �� �������
    //���������� ������ �������� ����������� ������
    if (pos.getPosProfit()>tmpParam.maxWinTrade)
     tmpParam.maxWinTrade = pos.getPosProfit();
    }
 }
 
void CTradeManager::GetMaxLoseTrade(void) //��������� ����� ������� ��������� �����
 {
   uint index;
   GetNTrades(); //��������� ���������� �������
   uint total = tmpParam.nTrades;
   CPosition * pos;  //��������� �� �������
   tmpParam.maxLoseTrade = 0;   
   for (index=0;index<total;index++)
    {
    pos  = _positionsHistory.Position(index); //��������� �� ������� �� �������
    //���������� ������ �������� ����������� ������
    if ( pos.getPosProfit()<tmpParam.maxLoseTrade)
     tmpParam.maxLoseTrade = pos.getPosProfit();
    }
 } 

void CTradeManager::GetMedWinTrade(void)  //��������� ������� ���������� �����
 {
   uint index;
   uint count=0;   //������� ���������� �������
   GetNTrades(); //��������� ���������� �������
   uint total = tmpParam.nTrades;
   double profitSum=0; //����� �������� 
   CPosition * pos;  //��������� �� �������
   for (index=0;index<total;index++)
    {
    pos  = _positionsHistory.Position(index); //��������� �� ������� �� �������
    //���������� ������ �������� ����������� ������
    if (pos.getPosProfit()>0)  //���� ����� - ����������
     {
      profitSum = profitSum + pos.getPosProfit();
      count++;
     }
    } 
    if (count) //���� ���������� ���������� ������� ������ ����
    tmpParam.medWinTrade = profitSum/count; //��������� ������� ���������� �����
 } 
 
void CTradeManager::GetMedLoseTrade(void)  //��������� ������� ��������� �����
 {
   uint index;
   uint count=0;   //������� ��������� �������
   GetNTrades(); //��������� ���������� �������
   uint total = tmpParam.nTrades;
   double profitSum=0; //����� �������� 
   CPosition * pos;  //��������� �� �������
   for (index=0;index<total;index++)
    {
    pos  = _positionsHistory.Position(index); //��������� �� ������� �� �������
    //���������� ������ �������� ����������� ������
    if (pos.getPosProfit()<0)  //���� ����� - ���������
     {
      profitSum = profitSum + pos.getPosProfit();
      count++;
     }
    } 
    if (count) //���� ���������� ��������� ������� ������ ����
    tmpParam.medLoseTrade = profitSum/count; //��������� ������� ��������� �����
 }  


void CTradeManager::GetMaxWinTradesN(void)  //���������  ������������ ���������� ������ ������ ���������� �������
 {
  uint count=0;                   //������� ����� ������ ������ �������
  uint index;                     //������ �� ������� �������
  CPosition * pos;                //��������� �� �������
  GetNTrades();                   //��������� ���������� ������� (�������) � �������
  uint total = tmpParam.nTrades;  //���������� ������� � �������
  tmpParam.maxWinTradesN = 0;     //�������� ������������ ����� ������ ������ ���������� �������
  for (index=0;index<total;index++)
   {
    pos  = _positionsHistory.Position(index); //��������� �� ������� �� �������    
    if (pos.getPosProfit()>0) count++;  //���� ���������� �����, �� �������
    else //�����
     {
      if (count>0) //������� �������������, ������ ������� ����� ��� ����������
       {
        if (count > tmpParam.maxWinTradesN) //���� ������� ������� ���������� ������ ������ �������
         tmpParam.maxWinTradesN = count;
        count = 0; //�������� �������
       }
     }
   }
  if (count > tmpParam.maxWinTradesN)  
   tmpParam.maxWinTradesN = count;
 }
 
void CTradeManager::GetMaxLoseTradesN(void)  //���������  ������������ ���������� ������ ������ ��������� �������
 {
  uint count=0;                   //������� ����� ������ ������ �������
  uint index;                     //������ �� ������� �������
  CPosition * pos;                //��������� �� �������
  GetNTrades();                   //��������� ���������� ������� (�������) � �������
  uint total = tmpParam.nTrades;  //���������� ������� � �������
  tmpParam.maxLoseTradesN = 0;     //�������� ������������ ����� ������ ������ ��������� �������
  for (index=0;index<total;index++)
   {
    pos  = _positionsHistory.Position(index); //��������� �� ������� �� �������    
    if (pos.getPosProfit()<0) count++;  //����  ��������� �����, �� �������
    else //�����
     {
      if (count>0) //������� �������������, ������ ������� ����� ��� ���������
       {
        if (count > tmpParam.maxLoseTradesN) //���� ������� ������� ���������� ������ ������ �������
         tmpParam.maxLoseTradesN = count;
        count = 0; //�������� �������
       }
     }
   }
  if (count > tmpParam.maxLoseTradesN)  
   tmpParam.maxLoseTradesN = count;
 } 
 
   void CTradeManager::ZeroParam(void)  //�������� ��� ��������� ��������
   {
     tmpParam.nTrades=0;             //���������� �������
     tmpParam.nDeals=0;              //���������� ������
   
     tmpParam.shortTradeWinPer=0;    //������� ���������� �������� ������ (�� ����������)
     tmpParam.longTradeWinPer=0;     //������� ���������� ������� ������ (�� ����������)
     tmpParam.profitTradesPer=0;     //������� ���������� ������� (�� ����)
     tmpParam.loseTradesPer=0;       //������� ����������� ������� (�� ����)
   
     tmpParam.maxWinTrade=0;         //����� ������� ���������� �����
     tmpParam.maxLoseTrade=0;        //����� ������� ��������� �����
   
     tmpParam.medWinTrade=0;         //������� ���������� �����
     tmpParam.medLoseTrade=0;        //������� ������� �����
   
     tmpParam.maxWinTradesN=0;       //������������ ����� ����������� ���������
     tmpParam.maxLoseTradesN=0;      //������������ ����� ����������� ����������
   
     tmpParam.maxWinTradeSum=0;      //������������ ����������� �������
     tmpParam.maxLoseTradeSum=0;     //������������ ����������� ������   
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::OpenPosition(string symbol, ENUM_TM_POSITION_TYPE type, double volume,int sl, int tp, 
                                 int minProfit, int trailingStop, int trailingStep, int priceDifferense = 0)
{
 if (_positionsToReProcessing.Total() > 0) 
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ������� ������� ��� ��� ��� ���� ������� � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));
  return false;
 }

 int i = 0;
 int total = _openPositions.Total();
 CPosition *pos;
 log_file.Write(LOG_DEBUG
               ,StringFormat("%s, ��������� ������� %s. �������� ������� �� ������ ������: %d"
                            , MakeFunctionPrefix(__FUNCTION__), GetNameOP(type), total));
 log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString())); // ���������� ���� ������� �� ������� _openPositions
 switch(type)
 {
  case OP_BUY:
  case OP_BUYLIMIT:
  case OP_BUYSTOP:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // ��������� ��� ������ ��� ������� �� �������
    {
     pos = _openPositions.At(i);
     if (pos.getSymbol() == symbol)
     {
      if (pos.getType() == OP_SELL)
      {
       ClosePosition(i);
      }
      else
      {
       if (pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP)
       {
        ResetLastError();
        if(OrderSelect(pos.getPositionTicket()))
        {
         ClosePosition(i);
        }
        else
        {
         log_file.Write(LOG_DEBUG ,StringFormat("%s, �������� ������� �� �������: �� ������ ����� � ������� %d. ������ %d - %s"
                       , MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket()
                       , GetLastError(), ErrorDescription(GetLastError())));
        }
       }
      }
     }
    }
   }
   break;
  case OP_SELL:
  case OP_SELLLIMIT:
  case OP_SELLSTOP:
   if (total > 0)
   {
    for (i = total - 1; i >= 0; i--) // ��������� ��� ������ ��� ������� �� �������
    {
     pos = _openPositions.At(i);
     if (pos.getSymbol() == symbol)
     {
      if (pos.getType() == OP_BUY)
      {
       ClosePosition(i);
      }
      else
      {
       if (pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP)
       {
        ResetLastError();
        if(OrderSelect(pos.getPositionTicket()))
        {
         ClosePosition(i);
        }
        else
        {
         log_file.Write(LOG_DEBUG ,StringFormat("%s, �������� ������� �� �������: �� ������ ����� � ������� %d. ������ %d - %s"
                        , MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket()
                        , GetLastError(), ErrorDescription(GetLastError())));
        }
       }
      }
     }
    }
   }
   break;
  default:
   //log_file.Write(LOG_DEBUG, StringFormat("%s Error: Invalid ENUM_VIRTUAL_ORDER_TYPE", MakeFunctionPrefix(__FUNCTION__)));
   break;
 }
 
 total = _openPositions.OrderCount(symbol, _magic) + _positionsToReProcessing.OrderCount(symbol, _magic);
 if (total <= 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s openPositions � positionsToReProcessing ����� - ��������� ����� �������", MakeFunctionPrefix(__FUNCTION__)));
  pos = new CPosition(_magic, symbol, type, volume, sl, tp, minProfit, trailingStop, trailingStep, priceDifferense);
  ENUM_POSITION_STATUS openingResult = pos.OpenPosition();
  if (openingResult == POSITION_STATUS_OPEN || openingResult == POSITION_STATUS_PENDING) // ������� ���������� �������� �������
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s, magic=%d, symb=%s, type=%s, price=%.05f vol=%.02f, sl=%.05f, tp=%.05f"
                                          , MakeFunctionPrefix(__FUNCTION__), pos.getMagic(), pos.getSymbol(), GetNameOP(pos.getType()), pos.getPositionPrice(), pos.getVolume(), pos.getStopLossPrice(), pos.getTakeProfitPrice()));


   _openPositions.Add(pos);  // ��������� �������� ������� � ������ �������� �������
   SaveSituationToFile();
   log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
   return(true); // ���� ������ ������� �������
  }
  else
  {
   error = GetLastError();
   if(pos.getType() == OP_SELL || pos.getType() == OP_BUY) _positionsToReProcessing.Add(pos);
   log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� �������. Error{%d} = %s. Status = %s", MakeFunctionPrefix(__FUNCTION__), error, ErrorDescription(error), PositionStatusToStr(pos.getPositionStatus())));
   return(false); // ���� ������� ������� �� �������
  }
 }
 log_file.Write(LOG_DEBUG, StringFormat("%s �������� �������� ������� %d", MakeFunctionPrefix(__FUNCTION__), total));
 return(true); // ���� �������� �������� �������, ������ �� ���� ����������� 
}
//+------------------------------------------------------------------+ 
// ������� ���������� ���������� ���������
//+------------------------------------------------------------------+
void CTradeManager::DoTrailing()
{
 int total = _openPositions.Total();
//--- ������� � ����� �� ���� �������
 for(int i = 0; i < total; i++)
 {
  CPosition *pos = _openPositions.At(i);
  if(pos.DoTrailing())
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ��������� SL ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
   log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
  }
 } 
};
//+------------------------------------------------------------------+ 
// ������� ����������� �������
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action)
{
 
};

//+------------------------------------------------------------------+
/// Called from EA OnTrade().
/// Include the folowing in each EA that uses TradeManager
//+------------------------------------------------------------------+
void CTradeManager::OnTrade(datetime history_start=0)
{
/*
 if (_pos_panel_draw) 
  DrawCurrentPosition(_openPositions.Total()-1);  //���������� ������ ������� �������
*/
}

//+------------------------------------------------------------------+
/// Called from EA OnTick().
/// Actions virtual positions 
/// Include the folowing in each EA that uses TradeManage
//+------------------------------------------------------------------+
void CTradeManager::OnTick()
{
//--- ������� ���������� ������������� �������
 int total = _positionsToReProcessing.Total();
 for(int i = total - 1; i>=0; i--) // �� ������� ������� �� ���������
 {
  CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� ������
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_DELETED)
  {
   if (pos.RemovePendingPosition() == POSITION_STATUS_DELETED)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ������� ������� [%d].������� � �� positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__), i));
              //       pos.setClosePosDT(TimeCurrent());  //��������� ����� ��������
              //       pos.pos_closed = true;
                    
                    // pos.setPriceClose(SymbolInfoDouble(pos.getSymbol(),SYMB
/*ADD TO HISTORY*/
   //_positionsHistory.Add(_positionsToReProcessing.Detach(i)); //��������� ��������� ������� � ������
   _positionsToReProcessing.Delete(i);   
    SaveHistoryToFile();                  
    break;
   }
  }
  
  if (pos.getStopLossStatus() == STOPLEVEL_STATUS_NOT_DELETED)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ������� StopLoss � TakeProfit", MakeFunctionPrefix(__FUNCTION__)));    
   CloseReProcessingPosition(i);
   break;
  }
  
  if (pos.getPositionStatus() == POSITION_STATUS_NOT_COMPLETE)
  {
   if (pos.setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && pos.setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ���������� StopLoss � TakeProfit � ������� [%d].���������� � �� positionsToReProcessing � openPositions.", MakeFunctionPrefix(__FUNCTION__), i));    
    pos.setPositionStatus(POSITION_STATUS_OPEN);
  
    _openPositions.Add(_positionsToReProcessing.Detach(i));    
    SaveSituationToFile();
   }
  }
 } 

//--- ���������� �������
 if(!HistorySelect(_historyStart, TimeCurrent()))
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ������� ������� � %s �� %s", MakeFunctionPrefix(__FUNCTION__), _historyStart, TimeCurrent())); 
  return;
 }

//--- ���� ������� ������������, �������� � �������� ���������  
 total = _openPositions.Total();
 CPosition *pos;
//--- �� ������� ����� �������
 for(int i = total - 1; i >= 0; i--) 
 {
  pos = _openPositions.At(i);   // ������� ������� �� �� �������
  ENUM_TM_POSITION_TYPE type = pos.getType();
  
  if (!OrderSelect(pos.getStopLossTicket()) && pos.getPositionStatus() != POSITION_STATUS_PENDING && pos.getStopLossStatus() != STOPLEVEL_STATUS_NOT_DEFINED) // ���� �� �� ����� ������� ���� �� ��� ������, ������ �� ��������
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ��� ������-StopLoss, ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
                   //  pos.setClosePosDT(TimeCurrent());  //��������� ����� ��������
                   //  pos.pos_closed = true;
/*ADD TO HISTORY*/    _positionsHistory.Add(_openPositions.Detach(i));   
    SaveHistoryToFile();  
   SaveSituationToFile();               // ���������� ���� ���������
   break;                          
  }
  
  if (pos.CheckTakeProfit())    //��������� ������� ���������� TP
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ���� ����� �� ������ TP, ��������� ������� type = %s, TPprice = %f", MakeFunctionPrefix(__FUNCTION__), GetNameOP(type),  pos.getTakeProfitPrice()));
   ClosePosition(i);
   break;             
  }
     
  if (pos.getPositionStatus() == POSITION_STATUS_PENDING) // ���� ��� ������� ���������� �������...
  {
   if (!OrderSelect(pos.getPositionTicket())) // ���� �� �� ����� ������� �� �� ������
   {
    long ticket = pos.getPositionTicket();
    if(!FindHistoryTicket(ticket))            // ��������� ����� ���� ����� � �������
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s � ������� ������� �� ������ ����� � ������� %d", MakeFunctionPrefix(__FUNCTION__), ticket));
     return;
    }
    
    long state;
    if (HistoryOrderGetInteger(ticket, ORDER_STATE, state)) // ������� ������ ������ �� �������
    {
     switch (state)
     {
      case ORDER_STATE_FILLED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ��������� ������� ���������� ���������� �������.�������� ���������� StopLoss � TakeProfit.", MakeFunctionPrefix(__FUNCTION__)));
       
       if (pos.setStopLoss() == STOPLEVEL_STATUS_NOT_PLACED
        || pos.setTakeProfit() == STOPLEVEL_STATUS_NOT_PLACED )  // ��������� ���������� �������� � ����������
       {
        log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ���������� StopLoss �/��� TakeProfit. ���������� ������� [%d] � positionsToReProcessing.", MakeFunctionPrefix(__FUNCTION__)));                  
        pos.setPositionStatus(POSITION_STATUS_NOT_COMPLETE);  // ���� �� ����������, ��������, ����� ��������� �������
        _positionsToReProcessing.Add(_openPositions.Detach(i)); 
        break;
       }
       
       log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ���������� StopLoss �/��� TakeProfit. �������� ������� [%d] � openPositions.", MakeFunctionPrefix(__FUNCTION__)));
       pos.setPositionStatus(POSITION_STATUS_OPEN); // ������� ���������, ���� � ���� �����������
       if (pos.getType() == OP_BUYLIMIT || pos.getType() == OP_BUYSTOP) pos.setType(OP_BUY);
       if (pos.getType() == OP_SELLLIMIT || pos.getType() == OP_SELLSTOP) pos.setType(OP_SELL);
       log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
       SaveSituationToFile();
       break;
      }
      case ORDER_STATE_CANCELED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ����� ������� %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getPositionTicket(), ORDER_STATE))));
                 //    pos.setClosePosDT(TimeCurrent());  //��������� ����� ��������
                 //    pos.pos_closed = true; 
/*ADD TO HISTORY*/   _positionsHistory.Add(_openPositions.Detach(i));
                     SaveHistoryToFile();  
       break;
      }
      case ORDER_STATE_EXPIRED:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����� �������� %d STATE = %s", MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket(), EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getPositionTicket(), ORDER_STATE))));
                 //    pos.setClosePosDT(TimeCurrent());  //��������� ����� ��������
                 //    pos.pos_closed = true; 
/*ADD TO HISTORY*/   _positionsHistory.Add(_openPositions.Detach(i));
                     SaveHistoryToFile();  
       break;
      }
      
      default:
      {
       log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������ ������� ��� ����������� � �������: %s; ����� ������: %d", MakeFunctionPrefix(__FUNCTION__), EnumToString((ENUM_ORDER_STATE)state), ticket));
       break;
      }
     }
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ������� ����� �� ������ %d �� �������", MakeFunctionPrefix(__FUNCTION__), pos.getPositionTicket()));
     log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(GetLastError())));
     string str;
     int total = HistoryOrdersTotal();
     for(int i = total-1; i >= 0; i--)
     {
      str += HistoryOrderGetTicket(i) + " ";
     }
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ������� �� �������: %s", MakeFunctionPrefix(__FUNCTION__), str));
    } 
   }
  }
 }


 
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CTradeManager::Initialization()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� �������������.", MakeFunctionPrefix(__FUNCTION__)));
 int file_handle = FileOpen(CreateRDFilename(), FILE_READ|FILE_CSV|FILE_COMMON, ";");
 if (file_handle != INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ���������� ���� ���������. ��������� ������ �� ����.", MakeFunctionPrefix(__FUNCTION__)));
  _openPositions.ReadFromFile(file_handle);
  FileClose(CreateRDFilename());
  log_file.Write(LOG_DEBUG, StringFormat("%s ����������� ������ �� ����� ���������.", MakeFunctionPrefix(__FUNCTION__)));
  //SaveSituationToFile(true);
  log_file.Write(LOG_DEBUG, StringFormat("%s %s", MakeFunctionPrefix(__FUNCTION__), _openPositions.PrintToString()));
 }
 else
  log_file.Write(LOG_DEBUG, StringFormat("%s ���� ��������� �����������.���������� ���������� ��������� ���� ����������.", MakeFunctionPrefix(__FUNCTION__)));
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void CTradeManager::Deinitialization()
{
 log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� ���������������.", MakeFunctionPrefix(__FUNCTION__)));
 int size = _openPositions.Total();
 int attempts = 0;
 while (attempts < 25)
 {
  for(int i = size - 1; i>=0; i--) // �� ������� ����� �������
  {
   ClosePosition(i);
  }
  size = _openPositions.Total();
  if(size == 0) break;
  attempts++;
 }
 log_file.Write(LOG_DEBUG, StringFormat("%s ������� ��������������� ��������.", MakeFunctionPrefix(__FUNCTION__)));
 FileDelete(CreateRDFilename(), FILE_COMMON);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CTradeManager::isMinProfit(string symbol)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(pos.isMinProfit());
  }
 }
 return false;
}
//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] ticket			Open virtual order ticket
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(long ticket, color Color=CLR_NONE)
{
 int index = _openPositions.TicketToIndex(ticket);
 return ClosePosition(index);
}

//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] symbol			current symbol
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(string symbol, color Color=CLR_NONE)
{
 int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(ClosePosition(i));
  }
 }
 return false;
}

//+------------------------------------------------------------------+
/// Close a virtual order.
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _openPositions.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 if (pos.ClosePosition())
 {
                  //   pos.setClosePosDT(TimeCurrent());  //��������� ����� ��������
                   //  pos.setClosePosDT(0);
                   //  pos.pos_closed = true; 
                  //   pos.setPosProfit(PositionGetDouble(POSITION_PROFIT)); //��������� ������� �� �������
/*ADD TO HISTORY*/   _positionsHistory.Add(_openPositions.Detach(i));  //���������� ��������� ������� � ������ ������� �������
                     SaveHistoryToFile();  
  SaveSituationToFile();
  log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� [%d]", MakeFunctionPrefix(__FUNCTION__), i));
  return(true);
 }
 else
 {
  error = GetLastError();
  _positionsToReProcessing.Add(_openPositions.Detach(i));
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ������� ������� ������� [%d]. ������� ���������� � ������ positionsToReProcessing.Error{%d} = %s"
                                        , MakeFunctionPrefix(__FUNCTION__), i, error, ErrorDescription(error)));
 }
 return(false);
}

//+------------------------------------------------------------------+
/// Delete a virtual pos from "not_deleted".
/// \param [in] i			      pos index in array of positions
/// \param [in] arrow_color 	Default=CLR_NONE. This parameter is provided for MT4 compatibility and is not used.
/// \return							true if successful, false if not
//+------------------------------------------------------------------+
bool CTradeManager::CloseReProcessingPosition(int i,color Color=CLR_NONE)
{
 CPosition *pos = _positionsToReProcessing.Position(i);  // �������� �� ������� ��������� �� ������� �� �� �������
 if (pos.RemoveStopLoss() == STOPLEVEL_STATUS_DELETED)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������� ����������� ����-�����", MakeFunctionPrefix(__FUNCTION__)));
                 //    pos.setClosePosDT(TimeCurrent());  //��������� ����� ��������
                 //    pos.pos_closed = true; 
/*ADD TO HISTORY*/  _positionsHistory.Add(_positionsToReProcessing.Detach(i));
                    SaveHistoryToFile();  
  return(true);
 }
 return(false);
}
//+------------------------------------------------------------------+
/// Create magic number
/// \param [string] str       symbol
/// \return							generated magic number
//+------------------------------------------------------------------+
long CTradeManager::MakeMagic(string strSymbol = "")
{
 if(strSymbol == "") strSymbol = Symbol();
 string s = strSymbol + PeriodToString(Period()) + MQL5InfoString(MQL5_PROGRAM_NAME);
 ulong ulHash = 5381;
 for(int i = StringLen(s) - 1; i >= 0; i--)
 {
  ulHash = ((ulHash<<5) + ulHash) + StringGetCharacter(s,i);
 }
 return MathAbs((long)ulHash);
}

//+------------------------------------------------------------------+
/// Create file name
/// \return							generated string
//+------------------------------------------------------------------+
string CreateRDFilename ()
{
 string result;
 result = StringFormat("%s\\RescueData\\%s_%s_%s_rd.csv", MQL5InfoString(MQL5_PROGRAM_NAME), MQL5InfoString(MQL5_PROGRAM_NAME), StringSubstr(Symbol(),0,6), PeriodToString(Period()));
 return(result);
}

string CreateHistoryFilename ()
{
 string result;
 result = StringFormat("%s\\History\\%s_%s_%s_history.csv", MQL5InfoString(MQL5_PROGRAM_NAME), MQL5InfoString(MQL5_PROGRAM_NAME), StringSubstr(Symbol(),0,6), PeriodToString(Period()));
 return(result);
}

//+------------------------------------------------------------------+
/// Save position array to file
/// \param [bool] debug       if want to debug
//+------------------------------------------------------------------+
void CTradeManager::SaveSituationToFile()
{
 string file_name = CreateRDFilename();
 int file_handle = FileOpen(file_name, FILE_WRITE|FILE_CSV|FILE_COMMON, ";");
 if(file_handle == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ������� ����: %s", MakeFunctionPrefix(__FUNCTION__), file_name));
  return;
 }
 _openPositions.WriteToFile(file_handle);
 FileClose(file_handle);
}

//+------------------------------------------------------------------+
/// Search for ticket in History
/// \param [long] ticket       number of ticket to search
/// \return                    true if successful, false if not
//+------------------------------------------------------------------+
bool FindHistoryTicket(long ticket)
{
 int total = HistoryOrdersTotal();
 for(int i = 0; i < total; i++)
 {
  if(ticket == HistoryOrderGetTicket(i)) return true;  
 }
 return false;
}
//+------------------------------------------------------------------+
/// Return current position type
/// \param [long] ticket       number of ticket to search
/// \return                    true if successful, false if not
//+------------------------------------------------------------------+
ENUM_TM_POSITION_TYPE CTradeManager::GetPositionType(string symbol)
{
  int total = _openPositions.Total();
 CPosition *pos;
 for (int i = 0; i < total; i++)
 {
  pos = _openPositions.At(i);
  if (pos.getSymbol() == symbol)
  {
   return(pos.getType());
  }
 }
 return OP_UNKNOWN;
}

bool CTradeManager::LoadHistoryFromFile()   //��������� ������� ������� �� �����
 {
  string historyUrl = CreateHistoryFilename(); 
  int file_handle;   //�������� �����
  int ind;
  string tmp_str[17];
  bool read_flag;  //���� ���������� ������ �� �����
  CPosition *pos;  
     if (!FileIsExist(historyUrl,FILE_COMMON) ) //�������� ������������� ����� ������� 
      return false;   
   file_handle = FileOpen(historyUrl, FILE_READ|FILE_COMMON|FILE_CSV|FILE_ANSI, ";");
   if (file_handle == INVALID_HANDLE) //�� ������� ������� ����
    return false;
   _positionsHistory.Clear(); //������� ������ ������� �������
   for(ind=0;ind<N_COLUMNS;ind++) //N_COLUMNS - ���������� �������� 
    {
    tmp_str[ind] = FileReadString(file_handle);  //������� ������ ������ �������
    } 
    /*
   Alert("11 = ", tmp_str[11],
         " 12 = ", tmp_str[12],
         " 13 = ", tmp_str[13],
         " 14 = ", tmp_str[14],
         " 15 = ", tmp_str[15],
         " 16 = ", tmp_str[16],
         " 6 = ", tmp_str[17],
         " 7 = ", tmp_str[1],
         " 8 = ", tmp_str[2],
         " 9 = ", tmp_str[3],
         " 10 = ", tmp_str[4],
         " 11 = ", tmp_str[5],
         " 12 = ", tmp_str[12],
         " 13 = ", tmp_str[13],
         " 14 = ", tmp_str[14],
         " 15 = ", tmp_str[15],
         " 16 = ", tmp_str[16]       
                );*/ 
   read_flag = true;      //��� ������� ���� ������ �� ������ ���������� �������
   
   while (read_flag)
    {
     pos = new CPosition(0,"",OP_UNKNOWN,0);    //�������� ������ ��� ����� ������� 
     read_flag = pos.ReadFromFile(file_handle); //��������� ������ ��� ����� �������
     if (read_flag)                             //���� ������� ������� ������ 
      _positionsHistory.Add(pos);               //�� ��������� ������� � ������ ������� 
    }   
   FileClose(file_handle);  //��������� ���� ������� ������� 
  return true;
 }

void CTradeManager::SaveHistoryToFile(void) //��������� ������� ��������\�������� ������� � ����
 { /*
 int file_handle = FileOpen(CreateHistoryFilename(), FILE_WRITE|FILE_COMMON|FILE_CSV|FILE_ANSI, "");
 int index;
 int total = _positionsHistory.Total(); //�������� ���������� ��������� �������
 string result;
 CPosition *pos; //��������� �� �������

 if(file_handle == INVALID_HANDLE)
 {
  Alert("�� ������� ������� ���� ��� ���������� ������� �������");
  return;
 }

     //��������� ������������ ������� �������
     result = "";
     StringConcatenate(result, "������;",
                               "������;",
                               "��� �������;",
                               "���;",
                               "����� �������;",
                               "����� ���� ����;",
                               "���� ���� ����;",
                               "���� ����;",
                               "���� ���� �������;",
                               "�������� ����;",
                               "�������� ����;",
                               "���� �������� �������;",
                               "���� �������� �������;",
                               "����� �������� �������;",
                               "����� �������� �������;",
                               "������� �� �������;"
                               );                 
  
     FileWrite(file_handle,result); //��������� �������� �������                            
 
   for (index=0;index<_positionsHistory.Total();index++)
    {    
    result = "";
     pos  = _positionsHistory.Position(index); //��������� �� �������
     StringConcatenate(result, 
                       pos.getMagic(), ";",                   //������
                       pos.getSymbol(), ";",                  //������
                       GetNameOP(pos.getType()), ";",         //��� �������
                       pos.getVolume(), ";",                  //���
                       pos.getPositionTicket(), ";",          //����� �������
                       pos.getStopLossTicket(), ";",          //����� ���� ����                     
                       pos.getStopLossPrice(), ";",           //���� ���� ����
                       pos.getStopLossStatus(), ";",          //������ ���� ���� 
                       pos.getTakeProfitPrice(),";",          //���� ���� ������
                       pos.getTrailingStop(), ";",            //�������� ����
                       pos.getTrailingStep(), ";",            //�������� ����
                       DoubleToString(pos.getPriceOpen(),SymbolInfoInteger(pos.getSymbol(),SYMBOL_DIGITS)), ";",  //���� ��������
                       DoubleToString(pos.getPriceClose(),SymbolInfoInteger(pos.getSymbol(),SYMBOL_DIGITS)), ";", //���� ��������
                       TimeToString(pos.getOpenPosDT()),";",  //����� �������� �������
                       TimeToString(pos.getClosePosDT()),";", //����� �������� ������� 
                       DoubleToString(pos.getPosProfit(),SymbolInfoInteger(pos.getSymbol(),SYMBOL_DIGITS)),";"    //������� �� �������                  
                       );     
                                     
                       
   if(pos.getType() != OP_BUY && pos.getType() != OP_SELL) 
     {
      if(OrderSelect(pos.getPositionTicket()))
        StringConcatenate(result, result, ";",EnumToString((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)));
      else
        StringConcatenate(result, result,";",EnumToString((ENUM_ORDER_STATE)HistoryOrderGetInteger(pos.getPositionTicket(), ORDER_STATE)));
    } 
   else
        StringConcatenate(result, result, ";","�����������_����������");  
     FileWrite(file_handle,result); //��������� �������� �������
   } 
    FileClose(file_handle); //��������� ����     
    */
 }
 
 /*
 
void CTradeManager::DrawCurrentPosition(int index)  //����������� ������� ������� � � ����������
 {
 CPosition *pos; //��������� �� �������
 if( index >= 0)
  {
 pos  = _openPositions.Position(index); //��������� �� �������
 //pos  = _openPositions.Position(index);
 graphModule.EditElem("������",pos.getMagic()); //���������� ���������� �����        
 graphModule.EditElem("����",pos.getPositionPrice()); //���������� ���� �������
 graphModule.EditElem("������",PositionStatusToStr(pos.getPositionStatus())); //������ �������
 graphModule.EditElem("���",GetNameOP(pos.getType())); //��� �������
 graphModule.EditElem("���� ����", pos.getStopLossPrice()); //���� ����
 graphModule.EditElem("���� ������",pos.getTakeProfitPrice()); //���������� ���� �������
 graphModule.EditElem("�����",pos.getStopLossTicket());  //����� 
 graphModule.EditElem("�������� ������",pos.getStopLossStatus());  //���� ���� ������ 
 graphModule.EditElem("����� ��������",TimeToString(pos.getOpenPosDT()) );  //����� �������� �������  
 graphModule.EditElem("���� ��������",pos.getPriceOpen());    //���� ��������  
 //graphModule.EditElem("����� ��������",TimeToString(pos.getClosePosDT()) );  //����� ��������  �������    
 
 graphModule.ShowPanel(); //���������� ������           
  }              
 } 
 */