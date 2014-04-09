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
   int _handleEMAfastJr;   // ����� EMA fast �������� ����������
   int _handleEMAslowJr;   // ����� EMA fast �������� ����������
   int _handleSTOCEld;     // ����� Stochastic �������� ����������
   int _handleMACD;        // ����� MACD
   // ������ ����������� 
   double _bufferPBI[];            // ����� ��� PriceBased indicator  
   double _bufferEMA3Eld[];        // ����� ��� EMA 3 �������� ����������
   double _bufferEMAfastJr[];      // ����� ��� EMA fast �������� ����������
   double _bufferEMAslowJr[];      // ����� ��� EMA slow �������� ����������
   double _bufferSTOCEld[];        // ����� ��� Stochastic �������� ����������  
   
   CisNewBar *_eldNewBar;          // ���������� ��� ����������� ������ ���� �� eldTF  
   
   // ������ ���������� ��������
   int StochasticAndEma();

   // �����
   int    _divMACD;                // ����������� MACD
   int    _divStoc;                // ����������� ����������
   
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
   
 // �������� �����
 _divMACD     = 0;
 _divStoc     = 0;
   
 ////// �������������� ����������
 //---------�������������� ���������, ������, ���������� � ������
   
 ////// ��������� ������� ���������   ////// �������������� ����������
 _handlePBI       = iCustom(Symbol(), Period(), "PriceBasedIndicator", 1000);
 _handleMACD      = iMACD(Symbol(), Period(), _macd_params.fast_EMA_period,  _macd_params.slow_EMA_period, _macd_params.signal_period, _macd_params.applied_price);
 _handleSTOCEld   = iStochastic(NULL, _base_params.eldTF, _stoc_params.kPeriod, _stoc_params.dPeriod, _stoc_params.slow, MODE_SMA, STO_CLOSECLOSE);
 _handleEMAfastJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
 _handleEMAslowJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);

 if (_handlePBI == INVALID_HANDLE || 
     _handleEMAfastJr == INVALID_HANDLE || 
     _handleEMAslowJr == INVALID_HANDLE || 
     _handleMACD == INVALID_HANDLE || 
     _handleSTOCEld == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
 }   
            
 // �������� ������ ��� ������ ������ ����������� ������������ ������ ����
 _eldNewBar = new CisNewBar(_base_params.eldTF);
  // ������� ��������� � ��������, ��� � ���������
 ArraySetAsSeries( _bufferPBI, true);
 ArraySetAsSeries( _bufferEMAfastJr, true);
 ArraySetAsSeries( _bufferEMAslowJr, true);
 ArraySetAsSeries( _bufferSTOCEld, true);
  // �������� ������ �������
 ArrayResize( _bufferPBI, 1);
 ArrayResize( _bufferEMAfastJr, 2);
 ArrayResize( _bufferEMAslowJr, 2);
 ArrayResize( _bufferSTOCEld, 1);
}

//---------------------------------------------  
// ���������� �������� �������
//---------------------------------------------
 CPointSys::~CPointSys(void)
  {
   delete _eldNewBar;
   // ����������� ����������
   IndicatorRelease(_handlePBI);
   IndicatorRelease(_handleEMAfastJr);
   IndicatorRelease(_handleEMAslowJr);
   IndicatorRelease(_handleSTOCEld);
   IndicatorRelease(_handleMACD);
   // ����������� ������ ��� ������
   ArrayFree(_bufferPBI);
   ArrayFree(_bufferEMAfastJr);
   ArrayFree(_bufferEMAslowJr);
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
 int copiedPBI=-1;
 int copiedSTOCEld=-1;
 int copiedEMAfastJr=-1;
 int copiedEMAslowJr=-1;
 int attempts;

 for (attempts = 0; attempts < 25 && copiedPBI < 0; attempts++)
 {
  copiedPBI = CopyBuffer(_handlePBI, 4, 1, 1, _bufferPBI);
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
   copiedEMAfastJr = CopyBuffer( _handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
   copiedEMAslowJr = CopyBuffer( _handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
  }  
  if (copiedSTOCEld != 2 || copiedEMAfastJr != 2 || copiedEMAslowJr != 2 )   
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
 return(0);
}

//------------------------------------------
// ������ ����������� MACD
//------------------------------------------
