//+------------------------------------------------------------------+
//|                                                CTradeManager.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <CompareDoubles.mqh>

//--- ���������� ��������
#define OP_BUY 0           //������� 
#define OP_SELL 1          //������� 
#define OP_BUYLIMIT 2      //���������� ����� BUY LIMIT 
#define OP_SELLLIMIT 3     //���������� ����� SELL LIMIT 
#define OP_BUYSTOP 4       //���������� ����� BUY STOP 
#define OP_SELLSTOP 5      //���������� ����� SELL STOP 

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CTradeManager
  {
protected:
  CPositionInfo PosInfo;
  CSymbolInfo SymbInfo;
  MqlTradeRequest request;      // ��������� �� ��������� ������� �� OrderSend
  MqlTradeResult trade_result;  // ��������� �� ��������� ������ �� OrderSend
  string _symbol;              // ������
  ulong _magic;
  int _digits;                 // ���������� ������ ����� ������� � ����
  double _point;               // �������� ������
  int _stopLevel;
  int _freezeLevel;
  double _bid;
  double _ask;
  int _spread; 
  int _SL, _TP;
  int _minProfit, _trailingStop, _trailingStep;
  int _numberOfTry; 
  bool _useSound;
  string _nameFileSound;   // ������������ ��������� �����
  
public:
  void CTradeManager(string symbol, ulong magic, int SL, int TP, int minProfit, int trailingStop, int trailingStep)
             : _symbol(symbol), _magic(magic), _point(SymbolInfoDouble(_symbol, SYMBOL_POINT))
             , _SL(SL), _TP(TP), _minProfit(minProfit), _trailingStop(trailingStop), _trailingStep(trailingStep)
             , _numberOfTry(5), _useSound(true), _nameFileSound("expert.wav"){};
  double pricetype(int type);     // ��������� ������� �������� � ����������� �� ���� 
  double SLtype(int type);        // ��������� ������� ����-����� � ����������� �� ����
  double TPtype(int type);        // ��������� ������� ����-������� � ����������� �� ����
               // ���������� ����� �������� �����������
  
  bool UpdateSymbolInfo();
  void SendOrder(ENUM_ORDER_TYPE type,double volume);
  void DoTrailing();
  void ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action);
  string GetNameOP(int op);
  };

//+------------------------------------------------------------------+
//|��������� ���������� ���������� �� ��������� �����������          |
//+------------------------------------------------------------------+

bool CTradeManager::UpdateSymbolInfo()
  {
   SymbInfo.Name(_symbol);
   if(SymbInfo.Select() && SymbInfo.RefreshRates())
     {
      _symbol = SymbInfo.Name();
      _digits = SymbInfo.Digits();
      _point = SymbInfo.Point();
      _stopLevel = SymbInfo.StopsLevel();
      _freezeLevel = SymbInfo.FreezeLevel();
      _bid = SymbInfo.Bid();
      _ask = SymbInfo.Ask();
      _spread = SymbInfo.Spread();
      return(true);
     }
   return(false);
  }  
//+------------------------------------------------------------------+
//| ��������� ������� �������� � ����������� �� ����                 |
//+------------------------------------------------------------------+
double CTradeManager::pricetype(int type)
  {
   UpdateSymbolInfo();
   if(type == 0)return(_ask);
   if(type == 1)return(_bid);
   return(-1);
  }
//+------------------------------------------------------------------+
//| ��������� ������� ��������� � ����������� �� ����                |
//+------------------------------------------------------------------+
double CTradeManager::SLtype(int type)
  {
   if(UpdateSymbolInfo())
     {
      if(type==0)return(_bid-_SL*_point);
      if(type==1)return(_ask+_SL*_point);
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| ��������� ������� ����������� � ����������� �� ����              |
//+------------------------------------------------------------------+
double CTradeManager::TPtype(int type)
  {
   if(UpdateSymbolInfo())
     {
      if(type==0)return(_ask+_TP*_point);
      if(type==1)return(_bid-_TP*_point);
     }
   return(0);
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CTradeManager::SendOrder(ENUM_ORDER_TYPE type,double volume)
  {
   request.action = TRADE_ACTION_DEAL;      // ��� ������������ ��������
   request.magic = _magic;                  // ����� �������� (������������� magic number)
   request.symbol = _symbol;                // ��� ��������� �����������
   request.volume = volume;                 // ������������� ����� ������ � �����
   request.price = pricetype((int)type);   // ����       
   request.sl = SLtype((int)type);      // ������� Stop Loss ������
   request.tp = TPtype((int)type);      // ������� Take Profit ������         
   request.deviation = _spread;                 // ����������� ���������� ���������� �� ������������� ����
   request.type = type;                               // ��� ������
   request.type_filling = ORDER_FILLING_FOK;
   
   ModifyPosition(request.action);
   
  }
//+------------------------------------------------------------------+ 
// ������� ���������� ���������� ���������
//+------------------------------------------------------------------+
void CTradeManager::DoTrailing()
 {
  //--- ��������� �������, ���� �� ������� ��������, ������ ������� ����������
  if(PositionSelect(_symbol))
  {
   if(UpdateSymbolInfo())
   {
    double positionOpenPrice = PosInfo.PriceOpen();
    double positionSL = PosInfo.StopLoss();
    if (PosInfo.PositionType() == POSITION_TYPE_BUY)
    {
     if (LessDoubles(positionOpenPrice, _bid - _minProfit*_point))
     {
      if (LessDoubles(positionSL, _bid - (_trailingStop+_trailingStep-1)*_point) || positionSL == 0)
      {
       request.sl = NormalizeDouble(_bid - _trailingStop*_point, _digits);
       request.tp = PosInfo.TakeProfit();

       this.ModifyPosition(TRADE_ACTION_SLTP);
      }
     }
    }
    
    if (PosInfo.PositionType() == POSITION_TYPE_SELL)
    {
     if (GreatDoubles(positionOpenPrice - _ask, _minProfit*_point))
     {
      if (GreatDoubles(positionSL, _ask+(_trailingStop+_trailingStep-1)*_point) || positionSL == 0) 
      {
       request.sl = NormalizeDouble(_ask + _trailingStop*_point, _digits);
       request.tp = PosInfo.TakeProfit();

       this.ModifyPosition(TRADE_ACTION_SLTP);
      }
     }
    }
   }
  } 
 }; 

//+------------------------------------------------------------------+ 
// ������� ����������� �������
//+------------------------------------------------------------------+
void CTradeManager::ModifyPosition(ENUM_TRADE_REQUEST_ACTIONS trade_action)
{
//--- ������� ��� ��������� ������ � ����
 ResetLastError();
 request.action = trade_action;
 bool success = false;
 int er;
  
 for (int it = 1; it <= _numberOfTry; it++) 
 {
  if (!MQL5InfoInteger(MQL5_TESTING) && (!AccountInfoInteger(ACCOUNT_TRADE_EXPERT) || IsStopped())) break;
  while (!MQL5InfoInteger(MQL5_TRADE_ALLOWED)) Sleep(5000);

//--- �������� ������
  success = OrderSend(request,trade_result);
  if (success)
  {
   if (_useSound) PlaySound(_nameFileSound); break;
  }
  else
  {
  //--- ���� ��������� ��������� - ��������� ������ � ��� ����
   er=GetLastError();
   //Print("Error(",trade_result.retcode,") modifying order: ",ErrorDescription(er),", try ",it);
   Print("Ask=",trade_result.ask,"  Bid=",trade_result.bid,"  sy=",_symbol,
             "  op="+GetNameOP(request.type),"  pp=",request.price,"  sl=",request.sl,"  tp=",request.tp);
             
   Print("TradeLog: Trade request failed. Error = ",GetLastError(),", try ",it);
   switch(trade_result.retcode)
   {
    //--- �������
    case 10004:
    {
     Print("TRADE_RETCODE_REQUOTE");
     Print("request.price = ",request.price,"   trade_result.ask = ", trade_result.ask," trade_result.bid = ",trade_result.bid);
     break;
    }
    //--- ����� �� ������ ��������
    case 10006:
    {
     Print("TRADE_RETCODE_REJECT");
     Print("request.price = ",request.price,"   trade_result.ask = ", trade_result.ask," trade_result.bid = ",trade_result.bid);
     break;
    }
    //--- ������������ ����
    case 10015:
    {
     Print("TRADE_RETCODE_INVALID_PRICE");
     Print("request.price = ",request.price,"   trade_result.ask = ", trade_result.ask," trade_result.bid = ",trade_result.bid);
     break;
    }
    //--- ������������ SL �/��� TP
    case 10016:
    {
     Print("TRADE_RETCODE_INVALID_STOPS");
     Print("request.sl = ",request.sl," request.tp = ",request.tp);
     Print("trade_result.ask = ",trade_result.ask," trade_result.bid = ",trade_result.bid);
     break;
    }
    //--- ������������ �����
    case 10014:
    {
     Print("TRADE_RETCODE_INVALID_VOLUME");
     Print("request.volume = ",request.volume,"   trade_result.volume = ", trade_result.volume);
     break;
    }
    //--- �� ������� ����� �� �������� ��������  
    case 10019:
    {
     Print("TRADE_RETCODE_NO_MONEY");
     Print("request.volume = ",request.volume,"   trade_result.volume = ", trade_result.volume,"   trade_result.comment = ",trade_result.comment);
     break;
    }
    //--- �����-�� ������ �������, ������� ��� ������ �������   
    default:
    {
     Print("Other answer = ",trade_result.retcode);
    }
   }          
  Sleep(1000*10);
  }
 }
};

string CTradeManager::GetNameOP(int op)
{
 switch (op)
 {
  case OP_BUY      : return("Buy");
  case OP_SELL     : return("Sell");
  case OP_BUYLIMIT : return("Buy Limit");
  case OP_SELLLIMIT: return("Sell Limit");
  case OP_BUYSTOP  : return("Buy Stop");
  case OP_SELLSTOP : return("Sell Stop");
  default          : return("Unknown Operation");
 }
};