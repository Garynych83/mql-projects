//+------------------------------------------------------------------+
//|                                                     Position.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#include "ChartObjectsTradeLines.mqh"
#include "TradeManagerConfig.mqh"
#include "CTMTradeFunctions.mqh" //���������� ���������� ��� ���������� �������� ��������
#include <GlobalVariable.mqh>
#include <StringUtilities.mqh>
#include <CompareDoubles.mqh>
#include <CLog.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPosition : public CObject
  {
private:
   CSymbolInfo SymbInfo;
   CTMTradeFunctions *trade;
   CConfig config;
   ulong _magic;
   ulong _tmTicket;
   ulong _orderTicket;
   string _symbol;
   ENUM_TIMEFRAMES _period;
   double _lots;
   ulong _slTicket;
   ENUM_ORDER_TYPE _slType;
   double _slPrice, _tpPrice; // ���� ��������� ����� � �����
   int _sl, _tp;  // ���� � ���� � �������
   
   datetime _posOpenTime;  //����� �������� �������
   datetime _posCloseTime; //����� ���������� ������� 
   
   double _posOpenPrice;
   double _posAveragePrice;
   double _posClosePrice;     //����, �� ������� ������� ���������
   double _posProfit;         //������� � �������
   
   ENUM_TRAILING_TYPE _trailingType;
   int _minProfit, _trailingStop, _trailingStep; // ��������� ������ � �������
   int _handle_PBI;
   ENUM_TM_POSITION_TYPE _type;
   datetime _expiration;
   int      _priceDifference;
   
   CEntryPriceLine   _entryPriceLine;
   CStopLossLine     _stopLossLine;
   CTakeProfitLine   _takeProfitLine;

   ENUM_POSITION_STATUS _pos_status;
   ENUM_STOPLEVEL_STATUS _sl_status;
   
   ENUM_ORDER_TYPE SLOrderType(int type);
   ENUM_ORDER_TYPE TPOrderType(int type);
   ENUM_ORDER_TYPE OrderType(int type);
   ENUM_POSITION_TYPE PositionType(int type);
   
public:
   void CPosition()   // ����������� �� ���������
   {
    //Print("����������� �� ���������");
    trade = new CTMTradeFunctions();
    _pos_status = POSITION_STATUS_NOT_INITIALISED;
    _sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
   };  
   
   // ����������� �����������
   void CPosition(CPosition *pos);
   // ����������� ��� �������� �������
   void CPosition(string symbol, ENUM_TIMEFRAMES period
                 , ENUM_TM_POSITION_TYPE type, double volume
                 , double profit, double priceOpen, double priceClose);
   // ����������� � �����������
   void CPosition(ulong magic, string symbol, ENUM_TIMEFRAMES period
                    ,ENUM_TM_POSITION_TYPE type, double volume, int sl = 0, int tp = 0
                    ,ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_NONE
                    ,int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int handlePBI = 0, int priceDifference = 0);
// GET   
   datetime getClosePosDT()      {return (_posCloseTime);};   //�������� ���� �������� �������
   datetime getExpiration()      {return (_expiration);};      
   int      getHandlePBI()       {return (_handle_PBI);}; 
   ulong    getMagic()           {return (_magic);};
   int      getMinProfit()       {return(_minProfit);};
   datetime getOpenPosDT()       {return (_posOpenTime);};     //�������� ���� �������� �������
   ulong    getOrderTicket()     {return(_orderTicket);};
   ENUM_TIMEFRAMES getPeriod()   {return(_period);};
   double   getPositionPrice()   {return(_posAveragePrice);};
   int      getPositionPointsProfit();
   ENUM_POSITION_STATUS getPositionStatus() {return (_pos_status);};
   double   getPosProfit();                                 //�������� ������� �������  
   int   getPriceDifference()    {return(_priceDifference);};
   double   getPriceOpen()       {return(_posOpenPrice);};     //�������� ���� �������� �������
   double   getPriceClose()      {return(_posClosePrice);};   //�������� ���� �������� �������
   int      getSL()              {return(_sl);};
   double   getStopLossPrice()   {return(_slPrice);};
   ENUM_ORDER_TYPE getStopLossType() {return(_slType);};
   ENUM_STOPLEVEL_STATUS getStopLossStatus() {return (_sl_status);};
   ulong    getStopLossTicket()  {return (_slTicket);};
   string   getSymbol()          {return (_symbol);};
   double   getTakeProfitPrice() {return(_tpPrice);};
   ulong    getTMTicket()        {return(_tmTicket);};
   int      getTP()              {return(_tp);};
   int      getTrailingStop()    {return(_trailingStop);};
   int      getTrailingStep()    {return(_trailingStep);};
   ENUM_TRAILING_TYPE getTrailingType() {return(_trailingType);};
   ENUM_TM_POSITION_TYPE getType() {return (_type);};
   double   getVolume()          {return (_lots);};
   
// SET
   void     setMagic(ulong magic) {_magic = magic;};
   void     setPositionStatus(ENUM_POSITION_STATUS status) {_pos_status = status;};
   void     setStopLossStatus(ENUM_STOPLEVEL_STATUS status) {_sl_status = status;};
   ENUM_STOPLEVEL_STATUS setStopLoss();
   ENUM_STOPLEVEL_STATUS setTakeProfit();
   void     setType(ENUM_TM_POSITION_TYPE type) {_type = type;};
   void     setVolume(double lots) {_lots = lots;}; 
 
   bool     ChangeSize(double lot);
   ENUM_STOPLEVEL_STATUS ChangeStopLossVolume();   
   bool     CheckTakeProfit();
   bool     ClosePosition();
   bool     isMinProfit();
   bool     ModifyPosition(double sl, int tp);
   ulong    NewTicket();
   ENUM_POSITION_STATUS OpenPosition();
   double   OpenPriceByType(ENUM_TM_POSITION_TYPE type);     // ��������� ������� �������� � ����������� �� ���� 
   double   PriceByType(ENUM_TM_POSITION_TYPE type);     // ��������� ������� �������� � ����������� �� ���� 
   bool     ReadFromFile (int handle);
   ENUM_POSITION_STATUS  RemovePendingPosition();
   ENUM_STOPLEVEL_STATUS RemoveStopLoss();         
   double   SLPriceByType(ENUM_TM_POSITION_TYPE type);        // ��������� ������� ����-����� � ����������� �� ����
   double   TPPriceByType(ENUM_TM_POSITION_TYPE type);        // ��������� ������� ����-������� � ����������� �� ����
   bool     UpdateSymbolInfo();        // ��������� ���������� ���������� �� ��������� ����������� 
   void     WriteToFile (int handle);
   
 };

//+------------------------------------------------------------------+
//| Constructor for replay positions                                 |
//+------------------------------------------------------------------+
CPosition::CPosition(string symbol, ENUM_TIMEFRAMES period, ENUM_TM_POSITION_TYPE type, double volume, double profit, double priceOpen, double priceClose)
{
  //Print("����������� � ����������� ��� ������");
 trade = new CTMTradeFunctions();
 _symbol = symbol;
 _period = period;
 _type = type;
 _lots = volume;
 _posProfit = profit;
 _posOpenPrice = priceOpen;
 _posClosePrice = priceClose;
 _pos_status = POSITION_STATUS_NOT_INITIALISED;
 _sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
}
//+------------------------------------------------------------------+
//| Copy Constructor                                                 |
//+------------------------------------------------------------------+
CPosition::CPosition(CPosition *pos)
{
 //Print("����������� �����������");
 trade = new CTMTradeFunctions();
 
 _magic = pos.getMagic();
 _tmTicket = pos.getTMTicket();
 _orderTicket = pos.getOrderTicket();
 _symbol = pos.getSymbol();
 _period = pos.getPeriod();
 _lots = pos.getVolume();
 _slTicket = pos.getStopLossTicket();
 _slType = pos.getStopLossType();
 _slPrice = pos.getStopLossPrice(); // ���� ��������� �����
 _tpPrice = pos.getTakeProfitPrice(); // ���� ��������� �����
 if (_tpPrice > 0) _takeProfitLine.Create(0, _tpPrice);
   
 _posOpenTime = pos.getOpenPosDT();  //����� �������� �������
 _posCloseTime = pos.getClosePosDT(); //����� ���������� ������� 
   
 _posOpenPrice = pos.getPriceOpen();
 _posClosePrice = pos.getPriceClose();     //����, �� ������� ������� ���������
 _posProfit = pos.getPosProfit();      //������� � �������
   
 _sl = pos.getSL();
 _tp = pos.getTP();  // ���� � ���� � �������
 _minProfit = pos.getMinProfit();
 _trailingStop = pos.getTrailingStop();
 _trailingStep = pos.getTrailingStep(); // ��������� ������ � �������
 _trailingType = pos.getTrailingType();
 _handle_PBI = pos.getHandlePBI();
 _type = pos.getType();
 _expiration = pos.getExpiration();
 _priceDifference = pos.getPriceDifference();

 _pos_status = getPositionStatus();
 _sl_status = getStopLossStatus();
}

//+------------------------------------------------------------------+
//| Constructor with parameters                                      |
//+------------------------------------------------------------------+
CPosition::CPosition(ulong magic, string symbol, ENUM_TIMEFRAMES period
                    ,ENUM_TM_POSITION_TYPE type, double volume, int sl = 0, int tp = 0
                    ,ENUM_TRAILING_TYPE trailingType = TRAILING_TYPE_NONE
                    ,int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int handlePBI = 0, int priceDifference = 0)
                    : _magic(magic), _symbol(symbol), _period(period), _type(type), _lots(volume), _sl(0), _tp(0)
                      , _trailingType(trailingType)
                      , _minProfit(minProfit), _trailingStep(trailingStep), _handle_PBI(handlePBI), _priceDifference(priceDifference)
{
//--- initialize trade functions class
 //Print("����������� � �����������");
 UpdateSymbolInfo();
 if(sl > 0) _sl = (sl < SymbInfo.StopsLevel()) ? SymbInfo.StopsLevel() : sl;
 if(tp > 0) _tp = (tp < SymbInfo.StopsLevel()) ? SymbInfo.StopsLevel() : tp;
 if (trailingStop > 0) _trailingStop = (trailingStop < SymbInfo.StopsLevel()) ? SymbInfo.StopsLevel() : trailingStop;
 _expiration = TimeCurrent()+2*PeriodSeconds(Period());
 trade = new CTMTradeFunctions();
 _pos_status = POSITION_STATUS_NOT_INITIALISED;
 _sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
 /*
 if (_trailingType == TRAILING_TYPE_PBI)
 {
  _handle_PBI = iCustom(_symbol, _period, "PriceBasedIndicator", 100, 2, 1.5, 12, 2, 1.5, 12);
  if(_handle_PBI == INVALID_HANDLE)                                //��������� ������� ������ ����������
  {
   Print("�� ������� �������� ����� Price Based Indicator");      //���� ����� �� �������, �� ������� ��������� � ��� �� ������
  }
 }*/
}

//+------------------------------------------------------------------+
//|  ������ ������� � �������                                        |
//+------------------------------------------------------------------+
int CPosition::getPositionPointsProfit()
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 int result = 0;
 if (_type == OP_BUY)
  result = (bid - _posAveragePrice)/_Point;
 if (_type == OP_SELL)
  result = (_posAveragePrice - ask)/_Point;
 
 return(result);
}
//+------------------------------------------------------------------+
//| ��������� � ���������� �������� �������
//+------------------------------------------------------------------+
double CPosition::getPosProfit()
{
 UpdateSymbolInfo();
 double currentPrice = PriceByType(_type);
 _posProfit = _posAveragePrice * _lots;
 return(_posProfit);
}

//+------------------------------------------------------------------+
//| ������������� StopLoss
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::setStopLoss()
{
 if (_sl > 0 && _sl_status != STOPLEVEL_STATUS_PLACED)
 {
  if (_slPrice <= 0) _slPrice = SLPriceByType(_type);
  _slType = SLOrderType((int)_type);
  if (trade.OrderOpen(_symbol, _slType, _lots, _slPrice)) //, sl + stopLevel, sl - stopLevel);
  {
   _slTicket = trade.ResultOrder();
   _sl_status = STOPLEVEL_STATUS_PLACED;
   log_file.Write(LOG_DEBUG, StringFormat("%s ��������� �������� %d c � ����� %0.6f", MakeFunctionPrefix(__FUNCTION__), _slTicket, _slPrice));     
  }
  else
  {
   _sl_status = STOPLEVEL_STATUS_NOT_PLACED;
   log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� ��������� ���������", MakeFunctionPrefix(__FUNCTION__)));
  }
 }
 return(_sl_status);
}

//+------------------------------------------------------------------+
//| ������������� TakeProfit
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::setTakeProfit()
{
 if (_tp > 0)
 {
  _tpPrice = TPPriceByType(_type);
  _takeProfitLine.Create(0, _tpPrice);
  log_file.Write(LOG_DEBUG, StringFormat("%s ��������� ����������� ���������� � ����� %.05f", MakeFunctionPrefix(__FUNCTION__), _tpPrice));     
 }
 else
 {
  _tpPrice = 0;
 }
 return(STOPLEVEL_STATUS_PLACED);
}

//+------------------------------------------------------------------+
// Add additional volume to position
//+------------------------------------------------------------------+
bool CPosition::ChangeSize(double additionalVolume)
{
 ENUM_TM_POSITION_TYPE type = this.getType();
 if (additionalVolume < 0) type = type + MathPow(-1, type);
 double openPrice = OpenPriceByType(type);
 _posAveragePrice = (_lots*_posOpenPrice + additionalVolume*openPrice)/(_lots + additionalVolume);
 
 if (type == OP_BUY || type == OP_SELL)
 {
  //PrintFormat("%s ������� ��� = %s, ���������� ����� ���� = %s, ����� ������ = %.02f", MakeFunctionPrefix(__FUNCTION__), GetNameOP(this.getType()), GetNameOP(type), additionalVolume);
  if(trade.PositionOpen(_symbol, PositionType(type), MathAbs(additionalVolume), openPrice))
  {
   _lots = _lots + additionalVolume;
   //PrintFormat("%s ����� ����� = %.02f", MakeFunctionPrefix(__FUNCTION__), _lots);
   if (_lots < 0)
   {
    _type = (ENUM_TM_POSITION_TYPE)(_type + MathPow(-1, _type));
    _lots = -_lots;
    //PrintFormat("%s ������� ���� �����������, ����� ��� = %s", MakeFunctionPrefix(__FUNCTION__), GetNameOP(this.getType()));
   }
   
   log_file.Write(LOG_DEBUG, StringFormat("%s �������� ������� %d", MakeFunctionPrefix(__FUNCTION__), _tmTicket));
   PrintFormat("%s �������� ������� %d, ������� ��� = %s", MakeFunctionPrefix(__FUNCTION__), _tmTicket, GetNameOP(this.getType()));
   
   if (_sl_status == STOPLEVEL_STATUS_PLACED)
   {
    if (ChangeStopLossVolume() == STOPLEVEL_STATUS_PLACED)
    {
     _pos_status = POSITION_STATUS_OPEN;
     PrintFormat("%s �������� ������� � ��������", MakeFunctionPrefix(__FUNCTION__));
     return(true);
    }
    else
    {
     _pos_status = POSITION_STATUS_NOT_COMPLETE;
     PrintFormat("%s �� ������� �������� ��������", MakeFunctionPrefix(__FUNCTION__));
     return (false);
    }
   }
  }
  else
  {
   PrintFormat("%s �� ������� �������� �������", MakeFunctionPrefix(__FUNCTION__));
   return (false);
  }
 }
 else
 {
  if (trade.OrderDelete(_orderTicket))
  {
   if (trade.OrderOpen(_symbol, OrderType(getType()), additionalVolume, openPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ����� %d; ����� ��������� %s", MakeFunctionPrefix(__FUNCTION__), _tmTicket, TimeToString(_expiration)));
   }
  }
 }
 return(true);
}

//+------------------------------------------------------------------+
//| �������� ����� StopLoss
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::ChangeStopLossVolume()
{
 if (RemoveStopLoss() == STOPLEVEL_STATUS_DELETED)
 {
  setStopLoss();
 }
 return (_sl_status);
}

//+------------------------------------------------------------------+
//| �������� �� �� ��� ���� ������ ������� TakeProfit
//+------------------------------------------------------------------+
bool CPosition::CheckTakeProfit(void)
{
 if (_tpPrice > 0)
 {
  UpdateSymbolInfo();
  if (_type == OP_SELL && _tpPrice >= SymbInfo.Ask())
  {
   PrintFormat("������� ����, ������� ������� ����������");
  }
  if (_type == OP_BUY  && _tpPrice <= SymbInfo.Bid())
  {
   PrintFormat("������� ���, ������� ������� ����������");
  }
  return ((_type == OP_SELL && _tpPrice >= SymbInfo.Ask()) || 
          (_type == OP_BUY  && _tpPrice <= SymbInfo.Bid()) );
 }
 return (false);
}

//+------------------------------------------------------------------+
//| �������� �������
//+------------------------------------------------------------------+
bool CPosition::ClosePosition()
{
 int i = 0;
 ResetLastError();
 if (_pos_status == POSITION_STATUS_PENDING)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s RemovePendingPosition", MakeFunctionPrefix(__FUNCTION__)));
  _pos_status = RemovePendingPosition();
 }
 
 if (_pos_status == POSITION_STATUS_OPEN)
 {
  switch(_type)
  {
   case OP_BUY:
    if(trade.PositionClose(_symbol, POSITION_TYPE_BUY, _lots, config.Deviation))
    {     
     _pos_status = POSITION_STATUS_CLOSED;
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� %d", MakeFunctionPrefix(__FUNCTION__), _tmTicket));
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ������� BUY.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
    }
    break;
   case OP_SELL:
    if(trade.PositionClose(_symbol, POSITION_TYPE_SELL, _lots, config.Deviation))
    {
     _pos_status = POSITION_STATUS_CLOSED;
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� %d", MakeFunctionPrefix(__FUNCTION__), _tmTicket));
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ������� SELL.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));    
    }
    break;
   default:
    break;
  }
  
  if (_sl_status == STOPLEVEL_STATUS_PLACED)
  {
   _sl_status = RemoveStopLoss();
  }
 }
 
 if (_pos_status == POSITION_STATUS_CLOSED)
 {
  _posClosePrice = PriceByType(_type);   //��������� ���� �������� �������
  _posCloseTime = TimeCurrent();       //��������� ����� �������� �������
  getPosProfit();                      //��������� ������ �������
 }
 
 _takeProfitLine.Delete();
 return(_pos_status != POSITION_STATUS_NOT_DELETED
      && _sl_status != STOPLEVEL_STATUS_NOT_DELETED);
}

//+------------------------------------------------------------------+
//|��������� ���������� � ���������� ������������ �������            |
//+------------------------------------------------------------------+
bool CPosition::isMinProfit(void)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 
 if (getType() == OP_BUY && LessDoubles(_posAveragePrice, bid - _minProfit*point))
  return true;
 if (getType() == OP_SELL && GreatDoubles(_posAveragePrice, ask + _minProfit*point))
  return true;
  
 return false;
}

//+------------------------------------------------------------------+
//| EMPTY
//+------------------------------------------------------------------+
bool CPosition::ModifyPosition(double sl, int tp)
{
 if (trade.StopOrderModify(_slTicket, sl))
 {
  _slPrice = sl;
  PrintFormat("%s �������� ��������, ����� �������� %.05f", MakeFunctionPrefix(__FUNCTION__), _slPrice);
  return (true);
 }
 else
 {
  PrintFormat("%s �� ������� �������� ��������",MakeFunctionPrefix(__FUNCTION__));
 }
 return(false);
}

//+------------------------------------------------------------------+
/// Increments Config.VirtualOrderTicketGlobalVariable.
/// \return    Unique long integer
//+------------------------------------------------------------------+
ulong CPosition::NewTicket()
{
 CGlobalVariable g_lTicket;
 g_lTicket.Name(Config.VirtualOrderTicketGlobalVariable);
 _tmTicket=g_lTicket.Increment();
 return(_tmTicket);
}

//+------------------------------------------------------------------+
//| �������� �������
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS CPosition::OpenPosition()
{
 UpdateSymbolInfo();
 _posOpenPrice = OpenPriceByType(_type);
 _posAveragePrice = OpenPriceByType(_type);
 _posOpenTime = TimeCurrent(); //��������� ����� �������� �������    
 _posProfit = 0;
 
 switch(_type)
 {
  case OP_BUY:
   PrintFormat("%s, ��������� ������� ���", MakeFunctionPrefix(__FUNCTION__));
   if(trade.PositionOpen(_symbol, POSITION_TYPE_BUY, _lots, _posOpenPrice))
   {
    _orderTicket = 0;
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� �������", MakeFunctionPrefix(__FUNCTION__)));
    PrintFormat("%s ������� �������", MakeFunctionPrefix(__FUNCTION__));
    if (setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
    {
     _pos_status = POSITION_STATUS_OPEN;
    }
    else
    {
     _pos_status = POSITION_STATUS_NOT_COMPLETE;
    }
   }
   break;
  case OP_SELL:
   if(trade.PositionOpen(_symbol, POSITION_TYPE_SELL, _lots, _posOpenPrice))
   {
    _orderTicket = 0;
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� ", MakeFunctionPrefix(__FUNCTION__)));
    PrintFormat("%s ������� �������", MakeFunctionPrefix(__FUNCTION__));
    if (setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
    {
     _pos_status = POSITION_STATUS_OPEN;   
    }
    else
    {
     _pos_status = POSITION_STATUS_NOT_COMPLETE;
    }
   }
   break;
  case OP_BUYLIMIT:
   if (trade.OrderOpen(_symbol, ORDER_TYPE_BUY_LIMIT, _lots, _posOpenPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _orderTicket = trade.ResultOrder();
    _pos_status = POSITION_STATUS_PENDING;             
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ����� ; ����� ��������� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(_expiration)));
   }
   break;
  case OP_SELLLIMIT:
   if (trade.OrderOpen(_symbol, ORDER_TYPE_SELL_LIMIT, _lots, _posOpenPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _orderTicket = trade.ResultOrder();
    _pos_status = POSITION_STATUS_PENDING;
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ����� ; ����� ��������� %s", MakeFunctionPrefix(__FUNCTION__),  TimeToString(_expiration)));
   }
   break;
  case OP_BUYSTOP:
   if (trade.OrderOpen(_symbol, ORDER_TYPE_BUY_STOP, _lots, _posOpenPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _orderTicket = trade.ResultOrder();
    _pos_status = POSITION_STATUS_PENDING;  
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ����� ; ����� ��������� %s", MakeFunctionPrefix(__FUNCTION__),  TimeToString(_expiration)));
   }
   break;
  case OP_SELLSTOP:
   if (trade.OrderOpen(_symbol, ORDER_TYPE_SELL_STOP, _lots, _posOpenPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _orderTicket = trade.ResultOrder();
    _pos_status = POSITION_STATUS_PENDING;
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ����� ; ����� ��������� %s", MakeFunctionPrefix(__FUNCTION__), TimeToString(_expiration)));
   }
   break;
  default:
   Print("����� �������� ��� �������");
   break;
 }

 NewTicket();
 return(_pos_status);
}

//+------------------------------------------------------------------+
//| ��������� ������� �������� � ����������� �� ����                 |
//+------------------------------------------------------------------+
double CPosition::OpenPriceByType(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 if(type == OP_BUY) return(ask);
 if(type == OP_SELL) return(bid);
 if(type == OP_BUYLIMIT  || type == OP_SELLSTOP) return(bid - _priceDifference*point);
 if(type == OP_SELLLIMIT || type == OP_BUYSTOP)  return(ask + _priceDifference*point);
 return(-1);
}

//+------------------------------------------------------------------+
//| ��������� ������� �������� � ����������� �� ����                 |
//+------------------------------------------------------------------+
double CPosition::PriceByType(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 if(type == OP_BUY || type == OP_SELLLIMIT || type == OP_BUYSTOP) return(ask);
 if(type == OP_SELL || type == OP_BUYLIMIT  || type == OP_SELLSTOP) return(bid);
 return(-1);
}

//+------------------------------------------------------------------+
/// Reads order line from an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle					Handle of the CSV file
/// \param [in] bCreateLineObjects  if true, creates open, sl & tp lines on chart 
/// \return 				True if successful, false otherwise
//+------------------------------------------------------------------+
bool CPosition::ReadFromFile(int  handle)
{
 if(handle != INVALID_HANDLE)
 {
  if(FileIsEnding(handle)) return false;
  _magic = StringToInteger(FileReadString(handle));                               //��������� ������
 // Alert("> MAGIC = ",FileReadString(handle));  
  if(FileIsEnding(handle)) return false; 
   _symbol         = FileReadString(handle);                      //��������� ������
//  Alert("> SYMBOL = ",FileReadString(handle));   
  if(FileIsEnding(handle)) return false;  
  _type           = StringToPositionType(FileReadString(handle));//��������� ���
 // Alert("> TYPE = ",_type);    
  if(FileIsEnding(handle)) return false;   
  _lots           = StringToDouble(FileReadString(handle));                      //��������� ������ ����
 // Alert("> LOT = ",_lots);  
  if(FileIsEnding(handle)) return false;   
  _tmTicket      = StringToInteger(FileReadString(handle));                      //��������� ����� �������
 // Alert("> LOT = ",_lots);  
  if(FileIsEnding(handle)) return false;   
  _orderTicket      = StringToInteger(FileReadString(handle));                      //��������� ����� �������
 // Alert("> POS TICKET = ",_posTicket);  
  if(FileIsEnding(handle)) return false;   
  _slTicket       = StringToInteger(FileReadString(handle));                      //��������� ����� ���� �����  
 // Alert("> STOP LOSS TICKET = ",_slTicket);  
  if(FileIsEnding(handle)) return false;    
  _slPrice        = StringToDouble(FileReadString(handle));                      //��������� ���� ���� �����
 // Alert("> STOP LOSS PRICE = ",_slPrice);   
  if(FileIsEnding(handle)) return false;    
  _sl             = StringToInteger(FileReadString(handle));                      //��������� ���� ����
 // Alert("> STOP LOSS = ",_sl); 
  if(FileIsEnding(handle)) return false;  
  _tpPrice        = StringToDouble(FileReadString(handle));                      //��������� ���� ���� �������
 // Alert("> TAKE PROFIT PRICE = ",_tpPrice); 
  if(FileIsEnding(handle)) return false;    
  _trailingStop   = StringToInteger(FileReadString(handle));                      //�������� ����
 // Alert("> TRAILING STOP = ",_trailingStop); 
  if(FileIsEnding(handle)) return false;    
  _trailingStep   = StringToInteger(FileReadString(handle));                    //�������� ����
 // Alert("> TRAILING STEP = ",_trailingStep); 
  if(FileIsEnding(handle)) return false;    
  _posOpenPrice       = StringToDouble(FileReadString(handle));                //���� �������� �������
 // Alert("> POS OPEN PRICE = ",_posOpenPrice); 
  if(FileIsEnding(handle)) return false;    
  _posClosePrice     = StringToDouble(FileReadString(handle));                 //���� �������� �������
 // Alert("> POS CLOSE PRICE = ",_posClosePrice); 
  if(FileIsEnding(handle)) return false;    
  _posOpenTime  = StringToTime(FileReadString(handle));                    //����� �������� �������
 // Alert("> POS OPEN TIME = ",_posOpenTime); 
  if(FileIsEnding(handle)) return false;    
  _posCloseTime = StringToTime(FileReadString(handle));                    //����� �������� �������
 // Alert("> POS CLOSE TIME = ",_posCloseTime); 
  if(FileIsEnding(handle)) return false;    
  _posProfit      = StringToDouble(FileReadString(handle));                      //������ �������
 // Alert("> POS PROFIT = ",_posProfit); 
                                //������� ������� �������  
  return true;
 }
 return false;
}
 
//+------------------------------------------------------------------+
//| ������� ���������� �����
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS CPosition::RemovePendingPosition()
{
 if (_pos_status == POSITION_STATUS_PENDING || _pos_status == POSITION_STATUS_NOT_DELETED)
 {
  if (trade.OrderDelete(_orderTicket))
  {
   _pos_status = POSITION_STATUS_DELETED;
  }
  else
  {
   _pos_status = POSITION_STATUS_NOT_DELETED;
  }
 }
 return(_pos_status);
}

//+------------------------------------------------------------------+
//| ������� StopLoss
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::RemoveStopLoss()
{
 ResetLastError();
 if (_sl_status == STOPLEVEL_STATUS_NOT_PLACED)
 {
  _sl_status = STOPLEVEL_STATUS_DELETED;
 }
 
 if (_sl_status == STOPLEVEL_STATUS_PLACED || _sl_status == STOPLEVEL_STATUS_NOT_DELETED) // ���� ����� ��� ���������� ��� ��� �� ������� ������� � �������
 {
  if (OrderSelect(_slTicket))
  {
   if (trade.OrderDelete(_slTicket))
   {
    _sl_status = STOPLEVEL_STATUS_DELETED;
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ �������� %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
   }
   else
   {
    _sl_status = STOPLEVEL_STATUS_NOT_DELETED;
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ���������.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
   }
  }
  else
  {
   switch(_type)
   {
    case OP_BUY:
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
     if (trade.PositionClose(_symbol, POSITION_TYPE_SELL, _lots)) // ��� ������� ���, �� ��������� ���� ����� - ����
     {
      _sl_status = STOPLEVEL_STATUS_DELETED;

      log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����������� �������� %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
      break;
     }
     else
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ���������.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
     }
     
    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
     if (trade.PositionClose(_symbol, POSITION_TYPE_BUY, _lots)) // ��� ������� ����, �� ��������� ���� ����� - ���
     {
      _sl_status = STOPLEVEL_STATUS_DELETED;

      log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����������� �������� %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
      break;
     }
     else
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ���������.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), ::GetLastError(), ErrorDescription(::GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
     }
   }
  }
 }
 return (_sl_status);
}

//+------------------------------------------------------------------+
//| ��������� ������� ��������� � ����������� �� ����                |
//+------------------------------------------------------------------+
double CPosition::SLPriceByType(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 if(type == 0 || type == 2 || type == 4) return(SymbInfo.Bid()-_sl*SymbInfo.Point()); // Buy
 if(type == 1 || type == 3 || type == 5) return(SymbInfo.Ask()+_sl*SymbInfo.Point()); // Sell
 return(0);
}

//+------------------------------------------------------------------+
//| ��������� ������� ����������� � ����������� �� ����              |
//+------------------------------------------------------------------+
double CPosition::TPPriceByType(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 if(type == 0 || type == 2 || type == 4) return(SymbInfo.Ask()+_tp*SymbInfo.Point()); // Buy 
 if(type == 1 || type == 3 || type == 5) return(SymbInfo.Bid()-_tp*SymbInfo.Point()); // Sell
 return(0);
}

//+------------------------------------------------------------------+
//|��������� ���������� ���������� �� ��������� �����������          |
//+------------------------------------------------------------------+
bool CPosition::UpdateSymbolInfo()
{
 SymbInfo.Name(_symbol);
 if(SymbInfo.Select() && SymbInfo.RefreshRates())
 {
  return(true);
 }
 return(false);
}

//+------------------------------------------------------------------+
/// Writes order as a line to an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle	handle of the CSV file
/// \param [in] bHeader 
//+------------------------------------------------------------------+
void CPosition::WriteToFile(int handle)
{
 if(handle != INVALID_HANDLE)
 {
  FileWrite(handle,      
            _magic,           
            Symbol(),         
            GetNameOP(_type), 
            _lots,            
            _tmTicket, 
            _orderTicket,      
            _slTicket,        
            _slPrice,         
            _sl,              
            _tpPrice,         
            _trailingStop,   
            _trailingStep,    
            _posOpenPrice,
            _posClosePrice,
            _posOpenTime,
            _posCloseTime,
            _posProfit
            );
 }
}  


//---------------PRIVATE-----------------------------

//+------------------------------------------------------------------+
//| ���������� ��� ������ StopLoss
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE CPosition::SLOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type == 0 || type == 2 || type == 4) res = ORDER_TYPE_SELL_STOP; // Buy
 if(type == 1 || type == 3 || type == 5) res = ORDER_TYPE_BUY_STOP; // Sell
 return(res);
}

//+------------------------------------------------------------------+
//| ���������� ��� ������ TakeProfit
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE CPosition::TPOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type == 0 || type == 2 || type == 4) res = ORDER_TYPE_SELL_LIMIT; // Buy
 if(type == 1 || type == 3 || type == 5) res = ORDER_TYPE_BUY_LIMIT; // Sell
 return(res);
}

//+------------------------------------------------------------------+
//| ���������� ��� �������
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE CPosition::PositionType(int type)
{
 ENUM_POSITION_TYPE res;
 if(type == 0) res = POSITION_TYPE_BUY;
 if(type == 1) res = POSITION_TYPE_SELL;
 return(res);
}

//+------------------------------------------------------------------+
//| ���������� ��� ����������� ������
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE CPosition::OrderType(int type)
{
 ENUM_ORDER_TYPE res;
 switch (type)
 {
  case OP_BUYLIMIT:
   res = ORDER_TYPE_BUY_LIMIT;
   break;
  case OP_SELLLIMIT:
   res = ORDER_TYPE_SELL_LIMIT;
   break;
  case OP_BUYSTOP:
   res = ORDER_TYPE_BUY_STOP;
   break;
  case OP_SELLSTOP:
   res = ORDER_TYPE_SELL_STOP;
   break;
 }
 return(res);
}











