//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// ����������� ���������
#include <Divergence/divergenceMACD.mqh>
#include <Divergence/divergenceStochastic.mqh>
#include <Lib CisNewBar.mqh>                // ��� �������� ������������ ������ ����
#include <StringUtilities.mqh>
#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <CLog.mqh>
#include "PointSystemUtilities.mqh"                      // ���������� �������� ������ ��� ��������� ��������

// ����� �������� �������
class CPointSys
 { 
  private:
   //---------- ��������� ������ ������ �������� �������
   
   // ��������� ����������
   sEmaParams  _ema_params;   // ��������� EMA
   sMacdParams _macd_params;  // ��������� MACD
   sStocParams _stoc_params;  // ��������� ����������
   sPbiParams  _pbi_params;   // ��������� PriceBasedIndicator
   sDealParams _deal_params;  // ���������� ������
   sBaseParams _base_params;  // ������� ���������
   
   //---------- ��������� ���������� ������ �������� �������
   MqlTick _tick;   // ��������� ���� 
   string _symbol; // ������� ����������
   
   // P.S. ���� ��� ����� ������ � ������ ��� DesepticonFlat
   
   // ������ �����������
   int _handlePBI;         // ����� PriceBased indicator
   int _handleEMA3Eld;             // ����� ��� EMA 3 �������� ����������
   int _handleEMAfastEld;          // ����� EMA fast �������� ����������   
   int _handleEMAfastJr;   // ����� EMA fast �������� ����������
   int _handleEMAslowJr;   // ����� EMA fast �������� ����������
   int _handleSTOCEld;     // ����� Stochastic �������� ����������
   int _handleMACD;        // ����� MACD
   // ������ ����������� 
   double _bufferPBI[];            // ����� ��� PriceBased indicator  
   double _bufferPBIforTrendDirection[];
   double _bufferEMA3Eld[];        // ����� ��� EMA 3 �������� ����������
   double _bufferEMAfastEld[];     // ����� ��� EMA fast �������� ����������    
   double _bufferEMAfastJr[];      // ����� ��� EMA fast �������� ����������
   double _bufferEMAslowJr[];      // ����� ��� EMA slow �������� ����������
   double _bufferSTOCEld[];        // ����� ��� Stochastic �������� ����������  
   // ������ ���
   double _bufferHighEld[];        // ����� ��� ���� high �� ������� ����������
   double _bufferLowEld[];         // ����� ��� ���� low �� ������� ����������   
   
   CisNewBar *_eldNewBar;          // ���������� ��� ����������� ������ ���� �� eldTF  
   
   // ������ ���������� ��������
   int StochasticAndEma();         // ������ ��������� ��� � ���� ���������������/���������������
   
   int lastTrend;                  // ����������� ���������� ������
  public:

  // ������ ��������� �������� �������� �� ������ �������� �������
   int  GetFlatSignals  ();        // ��������� ��������� ������� �� �����
   int  GetTrendSignals ();        // ��������� ��������� ������� �� ������
   int  GetCorrSignals  ();        // ��������� ��������� ������� �� ���������  
  // ��������� ������
   bool  isUpLoaded();              // ����� �������� (����������) ������� � �����. ���������� true, ���� �� �������
   int GetMovingType() {return((int)_bufferPBI[0]);};  // ��� ��������� ���� �������� 
  // ������������ � ����������� ������ �����������
   CPointSys (sDealParams &deal_params,sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params);      // ����������� ������
   ~CPointSys ();      // ���������� ������ 
 };

//--------------------------------------
// ����������� �������� �������
//--------------------------------------
CPointSys::CPointSys(sDealParams &deal_params,sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params)
{
 //---------�������������� ���������, ������, ���������� � ������
 _symbol = Symbol();

 ////// ��������� ������� ���������
 _deal_params = deal_params;
 _base_params = base_params;
 _ema_params  = ema_params;
 _macd_params = macd_params;
 _stoc_params = stoc_params;
 _pbi_params  = pbi_params;
   
 ////// �������������� ����������
 //---------�������������� ���������, ������, ���������� � ������
   
 ////// ��������� ������� ���������   ////// �������������� ����������
 _handlePBI       = iCustom(Symbol(), Period(), "PriceBasedIndicator", 1000);
 _handleMACD      = iMACD(Symbol(), Period(), _macd_params.fast_EMA_period,  _macd_params.slow_EMA_period, _macd_params.signal_period, _macd_params.applied_price);
 _handleSTOCEld   = iStochastic(NULL, _base_params.eldTF, _stoc_params.kPeriod, _stoc_params.dPeriod, _stoc_params.slow, MODE_SMA, STO_CLOSECLOSE);
 _handleEMA3Eld    = iMA(Symbol(),  _base_params.eldTF, 3,                            0, MODE_EMA, PRICE_CLOSE);
 _handleEMAfastEld = iMA(Symbol(),  _base_params.eldTF, _ema_params.periodEMAfastEld, 0, MODE_EMA, PRICE_CLOSE); 
 _handleEMAfastJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 _handleEMAslowJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);

 if (_handlePBI == INVALID_HANDLE || 
     _handleEMA3Eld    == INVALID_HANDLE ||
     _handleEMAfastEld == INVALID_HANDLE ||
     _handleEMAfastJr == INVALID_HANDLE || 
     _handleEMAslowJr == INVALID_HANDLE || 
     _handleMACD == INVALID_HANDLE || 
     _handleSTOCEld    == INVALID_HANDLE   )
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
 }   
            
 // �������� ������ ��� ������ ������ ����������� ������������ ������ ����
 _eldNewBar = new CisNewBar(_base_params.eldTF);
  // ������� ��������� � ��������, ��� � ���������
 ArraySetAsSeries( _bufferPBI, true);
 ArraySetAsSeries( _bufferPBIforTrendDirection, true);
 ArraySetAsSeries( _bufferEMAfastJr, true);
 ArraySetAsSeries( _bufferEMAslowJr, true);
 ArraySetAsSeries( _bufferSTOCEld, true);
 ArraySetAsSeries( _bufferHighEld,   true);
 ArraySetAsSeries( _bufferLowEld,    true);
  // �������� ������ �������
 int bars = Bars(Symbol(), Period());
 ArrayResize( _bufferPBI, 1);
 ArrayResize( _bufferPBIforTrendDirection, bars);
 ArrayResize( _bufferEMAfastJr, 2);
 ArrayResize( _bufferEMAslowJr, 2);
 ArrayResize( _bufferSTOCEld, 1);
 
 int copiedPBI = 0;
 for (int attempts = 0; attempts < 25 && copiedPBI <= 0; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(_handlePBI, 4, 0, bars, _bufferPBIforTrendDirection);
 }
 
 lastTrend = MOVE_TYPE_UNKNOWN;
 for(int i = 0; i < bars; i++)
 {
  if (_bufferPBIforTrendDirection[i] == MOVE_TYPE_TREND_UP ||
      _bufferPBIforTrendDirection[i] == MOVE_TYPE_TREND_DOWN ||
      _bufferPBIforTrendDirection[i] == MOVE_TYPE_TREND_UP_FORBIDEN ||
      _bufferPBIforTrendDirection[i] == MOVE_TYPE_TREND_DOWN_FORBIDEN)
  {
   lastTrend = _bufferPBIforTrendDirection[i];
   break;
  }
 }
}

//---------------------------------------------  
// ���������� �������� �������
//---------------------------------------------
 CPointSys::~CPointSys(void)
  {
   delete _eldNewBar;
   // ����������� ����������
   IndicatorRelease(_handlePBI);
   IndicatorRelease(_handleEMAfastEld);
   IndicatorRelease(_handleEMAfastJr);
   IndicatorRelease(_handleEMAslowJr);
   IndicatorRelease(_handleSTOCEld);
   IndicatorRelease(_handleMACD);
   // ����������� ������ ��� ������
   ArrayFree(_bufferPBI);
   ArrayFree(_bufferEMA3Eld);
   ArrayFree(_bufferEMAfastEld);
   ArrayFree(_bufferEMAfastJr);
   ArrayFree(_bufferEMAslowJr);
   ArrayFree(_bufferHighEld);
   ArrayFree(_bufferLowEld);
   // ����� � ��� �� ���������������
   log_file.Write(LOG_DEBUG, StringFormat("%s �������������.", MakeFunctionPrefix(__FUNCTION__)));    
  }
 
//---------------------------------------------------
// ��������� ������ �� �����
//--------------------------------------------------- 
int CPointSys::GetFlatSignals()
 {
  int points = 0; 
  SymbolInfoTick(_symbol, _tick); 

  if (isUpLoaded ())     // ���� ������ ���������� ������� ������������
  {
   //StochasticAndEma();  // ���� ������ �� �������� � ���� ��� �� ������������
      
   points += divergenceMACD(_handleMACD, Symbol(), Period());   
   points += divergenceSTOC(_handleSTOCEld, Symbol(), Period(),80,20); 
   points += (lastTrend == MOVE_TYPE_TREND_UP || lastTrend == MOVE_TYPE_TREND_UP_FORBIDEN) ? 1 : -1;  
  }
  return (points); // ��� �������
 }

//---------------------------------------------------
// ��������� ������ �� ������
//--------------------------------------------------- 
int  CPointSys::GetTrendSignals(void)
{
 SymbolInfoTick(Symbol(), _tick);
 
 if ( isUpLoaded () )   // �������� ���������� ����������
 {
   return ( TrendSignals() );  // ������ ������ �� ������
 }
 return (0); // ��� �������
} 

//---------------------------------------------------
// ��������� ������ �� ���������
//---------------------------------------------------  
int CPointSys::GetCorrSignals(void)
{
 SymbolInfoTick(Symbol(), _tick);
 if ( isUpLoaded () ) // ���� ������� ���������� ����������
 {
   
 }
 return (0); // ��� �������
}

//-----------------------------------------------
// ����� ���������� ������������ �������
//-----------------------------------------------
bool CPointSys::isUpLoaded(void)  
{
 // ���������� ��� �������� ���������� ������������� ����� � ������
 int copiedPBI=-1;
 int copiedSTOCEld=-1;
 int copiedEMA3Eld=-1;
 int copiedEMAfastEld=-1;
 int copiedEMAfastJr=-1;
 int copiedEMAslowJr=-1;
 int copiedHigh=-1;
 int copiedLow=-1;
 int attempts;

 for (attempts = 0; attempts < 25 && copiedPBI < 0; attempts++)
 {
  copiedPBI = CopyBuffer(_handlePBI, 4, 0, 1, _bufferPBI);
 }
 if (copiedPBI < 0) return(false);  // �� ������ ��������� ����� PBI
 
 if (_eldNewBar.isNewBar() > 0)      //�� ������ ����� ���� �������� TF
 {
  for (attempts = 0; attempts < 25 && (copiedSTOCEld   < 0
                                       || copiedEMAfastJr < 0
                                       || copiedEMAslowJr < 0); attempts++) 
  {
   //�������� ������ �����������
   copiedSTOCEld   = CopyBuffer( _handleSTOCEld,   0, 1, 2, _bufferSTOCEld);
   copiedEMA3Eld    = CopyBuffer( _handleEMA3Eld,   0, 0, 1, _bufferEMA3Eld);
   copiedEMAfastEld = CopyBuffer( _handleEMAfastEld,0, 1, 2, _bufferEMAfastEld);
   copiedEMAfastJr = CopyBuffer( _handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
   copiedEMAslowJr = CopyBuffer( _handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
   copiedHigh       = CopyHigh  ( Symbol(),  _base_params.eldTF,  1, 2, _bufferHighEld);
   copiedLow        = CopyLow   ( Symbol(),  _base_params.eldTF,  1, 2, _bufferLowEld); 
  }  
  if (copiedSTOCEld    != 2 ||
      copiedEMA3Eld    != 1 ||
      copiedEMAfastEld != 2 || 
      copiedEMAfastJr  != 2 ||  
      copiedEMAslowJr  != 2 ||
      copiedHigh       != 2 ||
      copiedLow        != 2 )   
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ������.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return (false);
  }
 }
 return (true); // ����� �� ������, ������ ��� �����������
}
 
//------------------------------------------
// ������ ��������� � ���
//------------------------------------------
int CPointSys::StochasticAndEma(void) 
{
 if(_bufferSTOCEld[1] > _stoc_params.top_level && _bufferSTOCEld[0] < _stoc_params.top_level)
 {
  if(GreatDoubles(_bufferEMAfastJr[1], _bufferEMAslowJr[1]) && GreatDoubles(_bufferEMAslowJr[0], _bufferEMAfastJr[0]))
  {
   if(GreatDoubles(_tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
   {
     //�������
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� SELL.", MakeFunctionPrefix(__FUNCTION__)));     
    return(-1);  // ���� ������ �� �������
   }
  }
 }
 if(_bufferSTOCEld[1] < _stoc_params.bottom_level && _bufferSTOCEld[0] > _stoc_params.bottom_level)
 {
  if(GreatDoubles(_bufferEMAslowJr[1], _bufferEMAfastJr[1]) && GreatDoubles(_bufferEMAfastJr[0], _bufferEMAslowJr[0]))
  {
   if(LessDoubles(_tick.bid, _bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point))
   {
     //�������
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� BUY.", MakeFunctionPrefix(__FUNCTION__)));     
    return(1);  // ���� ������ �� �������
   }
  }
 }
 return(0);   // ��� �������
}

//------------------------------------------
// ������ ����������� MACD
//------------------------------------------

//------------------------------------------
// ������ ����������� �� ����������
//------------------------------------------

//------------------------------------------
// ������ ��� ������
//------------------------------------------

 

 int CPointSys::TrendSignals(void)
  {
   if (_bufferPBI[0] == 1)                   //���� ����������� ������ TREND_UP  
 {
  if (GreatOrEqualDoubles(_bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point, _tick.bid))
  {
  
   if (GreatDoubles(_bufferEMAfastEld[0] + _base_params.deltaPriceToEMA*_Point, _bufferLowEld[0]) || 
       GreatDoubles(_bufferEMAfastEld[1] + _base_params.deltaPriceToEMA*_Point, _bufferLowEld[1]))
   {

    if (GreatDoubles(_bufferEMAslowJr[1], _bufferEMAfastJr[1]) && LessDoubles(_bufferEMAslowJr[0], _bufferEMAfastJr[0]))
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� BUY.", MakeFunctionPrefix(__FUNCTION__)));
     return (1);  // ���� ������ �� �������
    }
   }
  }
 } //end TREND_UP
 else if (_bufferPBI[0] == 3)               //���� ����������� ������ TREND_DOWN  
 {
  if (GreatOrEqualDoubles(_tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
  {

   if (GreatDoubles(_bufferHighEld[0], _bufferEMAfastEld[0] - _base_params.deltaPriceToEMA*_Point) || 
       GreatDoubles(_bufferHighEld[1], _bufferEMAfastEld[1] - _base_params.deltaPriceToEMA*_Point))
   {
    if (GreatDoubles(_bufferEMAfastJr[1], _bufferEMAslowJr[1]) && LessDoubles(_bufferEMAfastJr[0], _bufferEMAslowJr[0]))
    {
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� SELL.", MakeFunctionPrefix(__FUNCTION__)));
     return (-1);  // ���� ������ �� �������
    }
   }
  }
 } //end TREND_DOWN
   return (0); // ��� �������
  }
  
//------------------------------------------
// ������ ��� ���������                
//------------------------------------------

int CPointSys::CorrSignals(void)
 {
 if(GreatDoubles(_bufferEMAslowJr[1], _bufferEMAfastJr[1]) && GreatDoubles (_bufferEMAfastJr[0], _bufferEMAslowJr[0]) 
    && _bufferSTOCEld[0] < _stoc_params.bottom_level) //��������� �����; ����������� ������� EMA ����� �����
    return(100);     
  return (0); // ��� �������
 }