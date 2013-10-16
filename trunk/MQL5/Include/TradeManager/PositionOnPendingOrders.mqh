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
   ulong _posTicket;
   double _posPrice;
   string _symbol;
   double _lots;
   ulong _slTicket;
   double _slPrice;
   double _tpPrice;
   int _sl, _tp;
   int _minProfit, _trailingStop, _trailingStep;
   ENUM_TM_POSITION_TYPE _type;
   datetime _expiration;
   datetime _open_pos_time;  //����� �������� �������
   datetime _close_pos_time; //����� ���������� ������� 
   double   _priceClose;     //����, �� ������� ������� ���������
   double   _posProfit;      //������� � �������
   int      _priceDifference;
   
   CEntryPriceLine   _entryPriceLine;
   CStopLossLine     _stopLossLine;
   CTakeProfitLine   _takeProfitLine;

   ENUM_STOPLEVEL_STATUS sl_status;
   ENUM_POSITION_STATUS pos_status;
   
   ENUM_ORDER_TYPE SLOrderType(int type);
   ENUM_ORDER_TYPE TPOrderType(int type);
   ENUM_ORDER_TYPE PositionOrderType(int type);
   
public:
   bool     pos_closed;     //���� �������� �������
   void CPosition() {}; // ����������� �� ���������
   void CPosition(ulong magic, string symbol, ENUM_TM_POSITION_TYPE type, double volume
                ,int sl = 0, int tp = 0, int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int priceDifference = 0);
                
   datetime getOpenPosDT() { return (_open_pos_time); };     //�������� ���� �������� �������
   datetime getClosePosDT() { return (_close_pos_time); };   //�������� ���� �������� �������             
   double   getPriceOpen() { return(_posPrice); };           //�������� ���� �������� �������
   double   getPriceClose() { return(_priceClose); };        //�������� ���� �������� �������
   double   getPosProfit() { return(_posProfit); };          //�������� ������� �������             
   ulong    getMagic() {return (_magic);};
   void     setMagic(ulong magic) {_magic = magic;};
   ulong    getPositionTicket() {return(_posTicket);};
   string   getSymbol() {return (_symbol);};
   double   getVolume() {return (_lots);};
   void     setVolume(double lots) {_lots = lots;};
   ulong    getStopLossTicket() {return (_slTicket);};
   double   getPositionPrice() {return(_posPrice);};
   double   getStopLossPrice() {return(_slPrice);};
   double   getTakeProfitPrice() {return(_tpPrice);};
   double   getMinProfit() {return(_minProfit);};
   bool     isMinProfit();
   double   getTrailingStop() {return(_trailingStop);};
   double   getTrailingStep() {return(_trailingStep);};
   
   ENUM_TM_POSITION_TYPE getType() {return (_type);};
   void setType(ENUM_TM_POSITION_TYPE type) {_type = type;};
   
   ENUM_POSITION_STATUS getPositionStatus() {return (pos_status);};
   void setPositionStatus(ENUM_POSITION_STATUS status) {pos_status = status;};
   
   ENUM_STOPLEVEL_STATUS getStopLossStatus() {return (sl_status);};
   void setStopLossStatus(ENUM_STOPLEVEL_STATUS status) {sl_status = status;};
   
   datetime getExpiration() {return (_expiration);};
   void setExpiration(datetime expiration) {_expiration = expiration;};
   
   bool UpdateSymbolInfo();        // ��������� ���������� ���������� �� ��������� ����������� 
   double pricetype(ENUM_TM_POSITION_TYPE type);     // ��������� ������� �������� � ����������� �� ���� 
   double SLtype(ENUM_TM_POSITION_TYPE type);        // ��������� ������� ����-����� � ����������� �� ����
   double TPtype(ENUM_TM_POSITION_TYPE type);        // ��������� ������� ����-������� � ����������� �� ����

   ENUM_POSITION_STATUS OpenPosition();
   ENUM_STOPLEVEL_STATUS setStopLoss();
   ENUM_STOPLEVEL_STATUS setTakeProfit();
   bool ModifyPosition();
   bool CheckTakeProfit();
   ENUM_STOPLEVEL_STATUS RemoveStopLoss();
   ENUM_POSITION_STATUS RemovePendingPosition();
   bool ClosePosition();
   bool DoTrailing();
   bool ReadFromFile (int handle);
   void WriteToFile (int handle);
 };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPosition::CPosition(ulong magic, string symbol, ENUM_TM_POSITION_TYPE type, double volume
                    ,int sl = 0, int tp = 0, int minProfit = 0, int trailingStop = 0, int trailingStep = 0, int priceDifference = 0)
                    : _magic(magic), _symbol(symbol), _type(type), _lots(volume), _minProfit(minProfit), 
                      _trailingStop(trailingStop), _trailingStep(trailingStep), _priceDifference(priceDifference), _sl(0), _tp(0)
  {
//--- initialize trade functions class
   UpdateSymbolInfo();
   if(sl > 0) _sl = (sl < SymbInfo.StopsLevel()) ? SymbInfo.StopsLevel() : sl;
   if(tp > 0) _tp = (tp < SymbInfo.StopsLevel()) ? SymbInfo.StopsLevel() : tp;
   _expiration = TimeCurrent()+2*PeriodSeconds(Period());
   trade = new CTMTradeFunctions();
   pos_status = POSITION_STATUS_NOT_INITIALISED;
   sl_status = STOPLEVEL_STATUS_NOT_DEFINED;
   pos_closed = false; 
  }

//+------------------------------------------------------------------+
//|��������� ���������� � ���������� ������������ �������            |
//+------------------------------------------------------------------+
bool CPosition::isMinProfit(void)
{
 UpdateSymbolInfo();
 if(pos_status == POSITION_STATUS_OPEN)
 {
  switch(_type)
  {
   case OP_BUY:
   case OP_BUYLIMIT:
   case OP_BUYSTOP:
    if (SymbInfo.Bid() - _minProfit*SymbInfo.Point() >= _posPrice ) return true;
    break;
   case OP_SELL:
   case OP_SELLLIMIT:
   case OP_SELLSTOP:
    if (SymbInfo.Ask() + _minProfit*SymbInfo.Point() <= _posPrice ) return true;
    break;
  }
 }
 return false;
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
//| ��������� ������� �������� � ����������� �� ����                 |
//+------------------------------------------------------------------+
double CPosition::pricetype(ENUM_TM_POSITION_TYPE type)
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
//| ��������� ������� ��������� � ����������� �� ����                |
//+------------------------------------------------------------------+
double CPosition::SLtype(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 if(type == 0 || type == 2 || type == 4) return(SymbInfo.Bid()-_sl*SymbInfo.Point()); // Buy
 if(type == 1 || type == 3 || type == 5) return(SymbInfo.Ask()+_sl*SymbInfo.Point()); // Sell
 return(0);
}
//+------------------------------------------------------------------+
//| ��������� ������� ����������� � ����������� �� ����              |
//+------------------------------------------------------------------+
double CPosition::TPtype(ENUM_TM_POSITION_TYPE type)
{
 UpdateSymbolInfo();
 if(type == 0 || type == 2 || type == 4) return(SymbInfo.Ask()+_tp*SymbInfo.Point()); // Buy 
 if(type == 1 || type == 3 || type == 5) return(SymbInfo.Bid()-_tp*SymbInfo.Point()); // Sell
 return(0);
}

ENUM_ORDER_TYPE CPosition::SLOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type == 0 || type == 2 || type == 4) res = ORDER_TYPE_SELL_STOP; // Buy
 if(type == 1 || type == 3 || type == 5) res = ORDER_TYPE_BUY_STOP; // Sell
 return(res);
}

ENUM_ORDER_TYPE CPosition::TPOrderType(int type)
{
 ENUM_ORDER_TYPE res;
 if(type == 0 || type == 2 || type == 4) res = ORDER_TYPE_SELL_LIMIT; // Buy
 if(type == 1 || type == 3 || type == 5) res = ORDER_TYPE_BUY_LIMIT; // Sell
 return(res);
}


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS CPosition::OpenPosition()
{

 UpdateSymbolInfo();
 //double stopLevel = _Point*SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL);
 //double ask = SymbInfo.Ask();
 //double bid = SymbInfo.Bid();
 _posPrice = pricetype(_type);

 switch(_type)
 {
  case OP_BUY:
   if(trade.PositionOpen(_symbol, POSITION_TYPE_BUY, _lots, _posPrice))
   {
    _open_pos_time= TimeCurrent(); //��������� ����� �������� �������    
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� %d", MakeFunctionPrefix(__FUNCTION__), _posTicket));
    if (setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
    {
     _posTicket = 0;
     pos_status = POSITION_STATUS_OPEN;
    }
    else
    {
     _posTicket = 0;
     pos_status = POSITION_STATUS_NOT_COMPLETE;
    }
   }
   break;
  case OP_SELL:
   if(trade.PositionOpen(_symbol, POSITION_TYPE_SELL, _lots, _posPrice))
   {
    _open_pos_time= TimeCurrent(); //��������� ����� �������� �������    
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� %d", MakeFunctionPrefix(__FUNCTION__), _posTicket));
    if (setStopLoss() != STOPLEVEL_STATUS_NOT_PLACED && setTakeProfit() != STOPLEVEL_STATUS_NOT_PLACED)
    {
     _posTicket = 0;
     pos_status = POSITION_STATUS_OPEN;   
    }
    else
    {
     _posTicket = 0;
     pos_status = POSITION_STATUS_NOT_COMPLETE;
    }
   }
   break;
  case OP_BUYLIMIT:
   Alert("OP_BUYLIMIT");
   if (trade.OrderOpen(_symbol, ORDER_TYPE_BUY_LIMIT, _lots, _posPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _posTicket = trade.ResultOrder();
    pos_status = POSITION_STATUS_PENDING;             
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����� %d; ����� ��������� %s", MakeFunctionPrefix(__FUNCTION__), _posTicket, TimeToString(_expiration)));
   }
   break;
  case OP_SELLLIMIT:
   Alert("OP_SELLLIMIT");  
   if (trade.OrderOpen(_symbol, ORDER_TYPE_SELL_LIMIT, _lots, _posPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _posTicket = trade.ResultOrder();
    pos_status = POSITION_STATUS_PENDING;
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����� %d; ����� ��������� %s", MakeFunctionPrefix(__FUNCTION__), _posTicket, TimeToString(_expiration)));
   }
   break;
  case OP_BUYSTOP:
   Alert("OP_BUYSTOP");  
   if (trade.OrderOpen(_symbol, ORDER_TYPE_BUY_STOP, _lots, _posPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _posTicket = trade.ResultOrder();
    pos_status = POSITION_STATUS_PENDING;  
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����� %d; ����� ��������� %s", MakeFunctionPrefix(__FUNCTION__), _posTicket, TimeToString(_expiration)));
   }
   break;
  case OP_SELLSTOP:
   Alert("OP_SELLSTOP");  
   if (trade.OrderOpen(_symbol, ORDER_TYPE_SELL_STOP, _lots, _posPrice, ORDER_TIME_SPECIFIED, _expiration))
   {
    _posTicket = trade.ResultOrder();
    pos_status = POSITION_STATUS_PENDING;
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����� %d; ����� ��������� %s", MakeFunctionPrefix(__FUNCTION__), _posTicket, TimeToString(_expiration)));
   }
   break;
  default:
   Print("����� �������� ��� �������");
   break;
 }

 return(pos_status);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::ModifyPosition()
{
 return(false);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::setStopLoss()
{
 ENUM_ORDER_TYPE order_type;
 if (_sl > 0 && sl_status != STOPLEVEL_STATUS_PLACED)
 {
  _slPrice = SLtype(_type);
  order_type = SLOrderType((int)_type);
  if (trade.OrderOpen(_symbol, order_type, _lots, _slPrice)) //, sl + stopLevel, sl - stopLevel);
  {
   _slTicket = trade.ResultOrder();
   sl_status = STOPLEVEL_STATUS_PLACED;
   log_file.Write(LOG_DEBUG, StringFormat("%s ��������� �������� %d c � ����� %0.6f", MakeFunctionPrefix(__FUNCTION__), _slTicket, _slPrice));     
  }
  else
  {
   sl_status = STOPLEVEL_STATUS_NOT_PLACED;
   log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� ��������� ���������", MakeFunctionPrefix(__FUNCTION__)));
  }
 }
 return(sl_status);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::setTakeProfit()
{
 if (_tp > 0)
 {
  _tpPrice = TPtype(_type);
  log_file.Write(LOG_DEBUG, StringFormat("%s ��������� ����������� ���������� � ����� %0.6f", MakeFunctionPrefix(__FUNCTION__), _tpPrice));     
 }
 else
 {
  _tpPrice = 0;
 }
 return(STOPLEVEL_STATUS_PLACED);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::CheckTakeProfit(void)
{
 if (_tpPrice > 0)
 {
  UpdateSymbolInfo();
  return ((_type == OP_SELL && _tpPrice >= SymbInfo.Ask()) || 
          (_type == OP_BUY  && _tpPrice <= SymbInfo.Bid()) );
 }
 return (false);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_STOPLEVEL_STATUS CPosition::RemoveStopLoss()
{
 ResetLastError();
 if (sl_status == STOPLEVEL_STATUS_NOT_PLACED)
 {
  sl_status = STOPLEVEL_STATUS_DELETED;
 }
 
 if (sl_status == STOPLEVEL_STATUS_PLACED || sl_status == STOPLEVEL_STATUS_NOT_DELETED) // ���� ����� ��� ���������� ��� ��� �� ������� ������� � �������
 {
  if (OrderSelect(_slTicket))
  {
   if (trade.OrderDelete(_slTicket))
   {
    sl_status = STOPLEVEL_STATUS_DELETED;
    log_file.Write(LOG_DEBUG, StringFormat("%s ������ �������� %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
   }
   else
   {
    sl_status = STOPLEVEL_STATUS_NOT_DELETED;
      log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ���������.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
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
      sl_status = STOPLEVEL_STATUS_DELETED;

      log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����������� �������� %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
      break;
     }
     else
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ���������.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
     }
     
    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
     if (trade.PositionClose(_symbol, POSITION_TYPE_BUY, _lots)) // ��� ������� ����, �� ��������� ���� ����� - ���
     {
      sl_status = STOPLEVEL_STATUS_DELETED;

      log_file.Write(LOG_DEBUG, StringFormat("%s ������ ����������� �������� %d", MakeFunctionPrefix(__FUNCTION__), _slTicket));
      break;
     }
     else
     {
      log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ���������.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
     }
   }
  }
 }
 return (sl_status);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
ENUM_POSITION_STATUS CPosition::RemovePendingPosition()
{
 if (pos_status == POSITION_STATUS_PENDING || pos_status == POSITION_STATUS_NOT_DELETED)
 {
  if (trade.OrderDelete(_posTicket))
  {
   pos_status = POSITION_STATUS_DELETED;
  }
  else
  {
   pos_status = POSITION_STATUS_NOT_DELETED;
  }
 }
 return(pos_status);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::ClosePosition()
{
 int i = 0;
 double tmp_profit;   //���������� ��� �������� ������� �������
 ResetLastError();
 if (pos_status == POSITION_STATUS_PENDING)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s RemovePendingPosition", MakeFunctionPrefix(__FUNCTION__)));
  pos_status = RemovePendingPosition();
 }
 
 if (pos_status == POSITION_STATUS_OPEN)
 {
  switch(_type)
  {
   case OP_BUY:
     PositionSelect(_symbol);

    if(trade.PositionClose(_symbol, POSITION_TYPE_BUY, _lots, config.Deviation))
    {     
    // tmp_profit = PositionGetDouble(POSITION_PROFIT); //��������� ������ �������    
     _priceClose = SymbolInfoDouble(_symbol,SYMBOL_ASK);   //��������� ���� �������� �������
     _close_pos_time = TimeCurrent();                      //��������� ����� �������� �������
     _posProfit =  _priceClose-_posPrice; 
     pos_closed = true;  
     
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� %d", MakeFunctionPrefix(__FUNCTION__), _posTicket));
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ������� BUY.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));
    }
    break;
   case OP_SELL:
     PositionSelect(_symbol);

    if(trade.PositionClose(_symbol, POSITION_TYPE_SELL, _lots, config.Deviation))
    {
     // tmp_profit = PositionGetDouble(POSITION_PROFIT); //��������� ������ �������     
     _priceClose = SymbolInfoDouble(_symbol,SYMBOL_BID);   //��������� ���� �������� �������
     _close_pos_time = TimeCurrent();                      //��������� ����� �������� �������
     _posProfit = _posPrice-_priceClose;
     pos_closed = true;  
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� %d", MakeFunctionPrefix(__FUNCTION__), _posTicket));
    }
    else
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s ������ ��� �������� ������� SELL.Error(%d) = %s.Result retcode %d = %s", MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError()), trade.ResultRetcode(), trade.ResultRetcodeDescription()));    
    }
    break;
   default:
    break;
  }
  
  if (sl_status == STOPLEVEL_STATUS_PLACED)
  {
   sl_status = RemoveStopLoss();
  }
 }
  
 return(pos_status != POSITION_STATUS_NOT_DELETED
      && sl_status != STOPLEVEL_STATUS_NOT_DELETED);

}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool CPosition::DoTrailing(void)
{
 UpdateSymbolInfo();
 double ask = SymbInfo.Ask();
 double bid = SymbInfo.Bid();
 double point = SymbInfo.Point();
 int digits = SymbInfo.Digits();
 double newSL = 0;
 
 if (getType() == OP_BUY)
 {
  if (LessDoubles(_posPrice, bid - _minProfit*point))
  {
   if (LessDoubles(_slPrice, bid - (_trailingStop+_trailingStep-1)*point) || _slPrice == 0)
   {
    newSL = NormalizeDouble(bid - _trailingStop*point, digits);
    if (trade.OrderModify(_slTicket, newSL, 0, 0, ORDER_TIME_GTC, 0))
    {
     _slPrice = newSL;
     return true;
    } 
   }
  }
 }
 
 if (getType() == OP_SELL)
 {
  if (GreatDoubles(_posPrice - ask, _minProfit*point))
  {
   if (GreatDoubles(_slPrice, ask+(_trailingStop+_trailingStep-1)*point) || _slPrice == 0) 
   {
    newSL = NormalizeDouble(ask + _trailingStop*point, digits);
    if (trade.OrderModify(_slTicket, newSL, 0, 0, ORDER_TIME_GTC, 0))
    {
     _slPrice = newSL;
     return true;
    }
   }
  }
 }
 return false;
}

//+------------------------------------------------------------------+
/// Reads order line from an open file handle.
/// File should be FILE_CSV format
/// \param [in] handle					Handle of the CSV file
/// \param [in] bCreateLineObjects  if true, creates open, sl & tp lines on chart 
/// \return 				True if successful, false otherwise
//+------------------------------------------------------------------+

ulong _magic;
   ulong _posTicket;
   double _posPrice;
   string _symbol;
   double _lots;
   ulong _slTicket;
   double _slPrice;
   double _tpPrice;
   int _sl, _tp;
   int _minProfit, _trailingStop, _trailingStep;
   ENUM_TM_POSITION_TYPE _type;
   datetime _expiration;
   datetime _open_pos_time;  //����� �������� �������
   datetime _close_pos_time; //����� ���������� ������� 
   double   _priceClose;     //����, �� ������� ������� ���������
   double   _posProfit;      //������� � �������
   int      _priceDifference;

bool CPosition::ReadFromFile(int handle)
{
 string ggg;
 if(handle != INVALID_HANDLE)
 {
  if(FileIsEnding(handle)) return false;
  _magic = StringToInteger(FileReadString(handle));                               //��������� ������
  if(FileIsEnding(handle)) return false;
  _symbol         = FileReadString(handle);                      //��������� ������
  if(FileIsEnding(handle)) return false;  
  _type           = StringToPositionType(FileReadString(handle));//��������� ���
  if(FileIsEnding(handle)) return false;  
  _lots           = FileReadNumber(handle);                      //��������� ������ ����
  if(FileIsEnding(handle)) return false;  
  _posTicket      = StringToInteger(FileReadString(handle));                      //��������� ����� �������
  if(FileIsEnding(handle)) return false;  
  _slTicket       = StringToInteger(FileReadString(handle));                      //��������� ����� ���� �����
  if(FileIsEnding(handle)) return false;  
  _slPrice        = FileReadNumber(handle);                      //��������� ���� ���� �����
  if(FileIsEnding(handle)) return false;  
  _sl             = FileReadNumber(handle);                      //��������� ���� ����
  if(FileIsEnding(handle)) return false;  
  _tpPrice        = FileReadNumber(handle);                      //��������� ���� ���� �������
  if(FileIsEnding(handle)) return false;  
  _trailingStop   = FileReadNumber(handle);                      //�������� ����
  if(FileIsEnding(handle)) return false;  
  _trailingStep   = FileReadNumber(handle);                      //�������� ����
  if(FileIsEnding(handle)) return false;  
  _posPrice       = FileReadNumber(handle);                      //���� �������� �������
  if(FileIsEnding(handle)) return false;  
  _priceClose     = FileReadNumber(handle);                      //���� �������� �������
  if(FileIsEnding(handle)) return false;  
  _open_pos_time  = FileReadDatetime(handle);                    //����� �������� �������
  if(FileIsEnding(handle)) return false;  
  _close_pos_time = FileReadDatetime(handle);                    //����� �������� �������
  if(FileIsEnding(handle)) return false;  
  _posProfit      = FileReadNumber(handle);                      //������ �������
  if(FileIsEnding(handle)) return false;  
     FileReadString(handle);                                     //������� ������� �������  
/*
  ggg = 
        " ������ = "+IntegerToString(_magic)+
        " ������ = "+_symbol+        
        " ��� = "+GetNameOP(_type)+
        " ��� = "+DoubleToString(_lots,5)+
        " �����_��� = "+IntegerToString(_posTicket)+
        " �����_���� = "+IntegerToString(_slTicket)+
        " ����_���� = "+DoubleToString(_slPrice,5)+
        " ����_���� = "+IntegerToString(_sl)+
        " ����_���� = "+DoubleToString(_tpPrice)+
        " ��������_���� = "+IntegerToString(_trailingStop)+
        " ��������_���� = "+IntegerToString(_trailingStep)+
        " ����_������� = "+DoubleToString(_posPrice)+
        " ����_�������� = "+DoubleToString(_priceClose)+
        " �����_�������� = "+TimeToString(_open_pos_time)+
        " �����_�������� = "+TimeToString(_close_pos_time)+
        " ������_������� = "+DoubleToString(_posProfit); 
                                                                        
  Alert("",ggg);*/
  //log_file.Write(LOG_DEBUG, StringFormat("%s ���� ������� ��������", MakeFunctionPrefix(__FUNCTION__)));
  return true;
 }
 return false;
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
            _posTicket,       
            _posPrice,        
            _slTicket,        
            _slPrice,         
            _sl,              
            _tpPrice,         
            _tp,              
            _minProfit,       
            _trailingStop,   
            _trailingStep,    
            TimeToString(_expiration)
            );
 }
}