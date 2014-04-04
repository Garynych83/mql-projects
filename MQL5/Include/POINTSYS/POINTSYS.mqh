//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// ����������� ���������

#include <TradeManager/TradeManager.mqh>             // �������� ����������
#include <ColoredTrend/ColoredTrendUtilities.mqh>    // ��� �������� PriceBased indicator   
#include <Lib CisNewBar.mqh>                         // ��� �������� ������������ ������ ����
#include "STRUCTS.mqh"                               // ���������� �������� ������ ��� ��������� ��������

// ����� �����������
class POINTSYS
 { 
  private:
   //---------- ��������� ������ ������ �����������
   
   // ��������� ����������
   EMA_PARAMS  _ema_params;   // ��������� EMA
   MACD_PARAMS _macd_params;  // ��������� MACD
   STOC_PARAMS _stoc_params;  // ��������� ����������
   PBI_PARAMS  _pbi_params;   // ��������� PriceBasedIndicator
   DEAL_PARAMS _deal_params;  // ���������� ������
   BASE_PARAMS _base_params;  // ������� ���������
   
   // P.S. ���� ��� ����� ������ � ������ ��� DesepticonFlat
   
   // ������ �����������
   int    _handlePBI;              // ����� PriceBased indicator
   int    _handleEMA3Eld;          // ����� EMA 3 �������� TF
   int    _handleEMAfastJr;        // ����� EMA fast �������� ����������
   int    _handleEMAslowJr;        // ����� EMA fast �������� ����������
   int    _handleSTOCEld;          // ����� Stochastic �������� ����������

   // ������ ����������� 
   double _bufferPBI[];            // ����� ��� PriceBased indicator  
   double _bufferEMA3Eld[];        // ����� ��� EMA 3 �������� ����������
   double _bufferEMAfastJr[];      // ����� ��� EMA fast �������� ����������
   double _bufferEMAslowJr[];      // ����� ��� EMA slow �������� ����������
   double _bufferSTOCEld[];        // ����� ��� Stochastic �������� ����������  
   
   // ��������� ����������
   ENUM_TM_POSITION_TYPE _opBuy,   // ������ �� ������� 
                         _opSell;  // ������ �� �������
   int _priceDifference;           // Price Difference
   CisNewBar *_eldNewBar;          // ���������� ��� ����������� ������ ���� �� eldTF  
   
  public:
  // ������ ��������� �������� �������� �� ������ ������� �������
  bool  UpLoad();                  // ����� �������� (����������) ������� � �����
  ENUM_MOVE_TYPE GetMovingType();  // ��� ��������� ���� �������� 
  // ������������ � ����������� ������ �����������
  POINTSYS (DEAL_PARAMS &deal_params,BASE_PARAMS &base_params,EMA_PARAMS &ema_params,MACD_PARAMS &macd_params,STOC_PARAMS &stoc_params,PBI_PARAMS &pbi_params);      // ����������� ������
 ~POINTSYS ();      // ���������� ������ 
 };
 
 // ����������� ������� ������ ������� �������
 
 bool POINTSYS::UpLoad(void)   // ����� �������� (����������) ������� � �����
  {
    int copiedPBI=-1;
    int copiedSTOCEld=-1;
    int copiedEMAfastJr=-1;
    int copiedEMAslowJr=-1;
    int copiedEMA3Eld=-1; 
    int attempts;
    if (_eldNewBar.isNewBar() > 0)      //�� ������ ����� ���� �������� TF
      {
        for (attempts = 0; attempts < 25 && (   copiedPBI     < 0
                                             || copiedSTOCEld   < 0
                                             || copiedEMAfastJr < 0
                                             || copiedEMAslowJr < 0
                                             || copiedEMA3Eld   < 0 ); attempts++) //�������� ������ �����������
           {
            copiedPBI       =     CopyBuffer( _handlePBI,       4, 1, 1, _bufferPBI);
            copiedSTOCEld   =     CopyBuffer( _handleSTOCEld,   0, 1, 2, _bufferSTOCEld);
            copiedEMAfastJr =     CopyBuffer( _handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
            copiedEMAslowJr =     CopyBuffer( _handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
            copiedEMA3Eld   =     CopyBuffer( _handleEMA3Eld,   0, 0, 1, _bufferEMA3Eld);
           }  
        if (attempts < 25)
         return true;
        
      }
   return false;
  }
  
 // ��� ��������� ���� ��������
 
 ENUM_MOVE_TYPE POINTSYS::GetMovingType(void)
  {

   if (_bufferPBI[0] == 1)
    return MOVE_TYPE_TREND_UP;            // ����� ����� - �����
   if (_bufferPBI[0] == 1)
    return MOVE_TYPE_TREND_UP_FORBIDEN;   // ����� �����, ����������� ������� �� - ����������
   if (_bufferPBI[0] == 1)
    return MOVE_TYPE_TREND_DOWN;          // ����� ���� - �������
   if (_bufferPBI[0] == 1) 
    return MOVE_TYPE_TREND_DOWN_FORBIDEN; // ����� ����, ����������� ������� �� - ����������
   if (_bufferPBI[0] == 1)  
    return MOVE_TYPE_CORRECTION_UP;       // ��������� �����, �������������� ����� ���� - �������
   if (_bufferPBI[0] == 1)  
    return MOVE_TYPE_CORRECTION_DOWN;     // ��������� ����, �������������� ����� ����� - �������
   if (_bufferPBI[0] == 1)  
    return MOVE_TYPE_FLAT;                // ���� - ������
    
   return MOVE_TYPE_UNKNOWN;              // ����������� ��������
  }
 
 // ����������� ������������ � �����������
 
 // ����������� ������ �����������
 POINTSYS::POINTSYS(DEAL_PARAMS &deal_params,BASE_PARAMS &base_params,EMA_PARAMS &ema_params,MACD_PARAMS &macd_params,STOC_PARAMS &stoc_params,PBI_PARAMS &pbi_params)
  {
   //---------�������������� ���������, ������, ���������� � ������
   
   ////// ��������� ������� ���������
   _deal_params = deal_params;
   _base_params = base_params;
   _ema_params  = ema_params;
   _macd_params = macd_params;
   _stoc_params = stoc_params;
   _pbi_params  = pbi_params;
   
   Alert("��������� top_level = ",_stoc_params.top_level);
   
   ////// �������������� ����������
   _handlePBI       = iCustom(_Symbol, _base_params.eldTF, "PriceBasedIndicator", _pbi_params.historyDepth, _pbi_params.bars);
   _handleSTOCEld   = iStochastic(NULL, _base_params.eldTF, _stoc_params.kPeriod, _stoc_params.dPeriod, _stoc_params.slow, MODE_SMA, STO_CLOSECLOSE);
   _handleEMAfastJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMAslowJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMA3Eld   = iMA(Symbol(), _base_params.eldTF,               3, 0, MODE_EMA, PRICE_CLOSE);

 if (_handlePBI == INVALID_HANDLE || _handleEMAfastJr == INVALID_HANDLE || _handleEMAslowJr == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  //return(INIT_FAILED);
 }   
 
if ( _deal_params.useLimitOrders)                           // ����� ���� ������ Order / Limit / Stop
 {
  _opBuy  = OP_BUYLIMIT;
  _opSell = OP_SELLLIMIT;
  _priceDifference =  _deal_params.limitPriceDifference;
 }
 else if (_deal_params.useStopOrders)
      {
       _opBuy  = OP_BUYSTOP;
       _opSell = OP_SELLSTOP;
       _priceDifference = _deal_params.stopPriceDifference;
      }
      else
      {
       _opBuy = OP_BUY;
       _opSell = OP_SELL;
       _priceDifference = 0;
      } 
  // �������� ������ ��� ������ ������ ����������� ������������ ������ ����
  _eldNewBar = new CisNewBar(_base_params.eldTF);
  // ������� ��������� � ��������, ��� � ���������
  ArraySetAsSeries( _bufferPBI, true);
  ArraySetAsSeries( _bufferEMA3Eld, true);
  ArraySetAsSeries( _bufferEMAfastJr, true);
  ArraySetAsSeries( _bufferEMAslowJr, true);
  ArraySetAsSeries( _bufferSTOCEld, true);
  // �������� ������ �������
  ArrayResize( _bufferPBI, 1);
  ArrayResize( _bufferEMA3Eld, 1);
  ArrayResize( _bufferEMAfastJr, 2);
  ArrayResize( _bufferEMAslowJr, 2);
  ArrayResize( _bufferSTOCEld, 1);
   
  }
  
 // ���������� ������ �����������
 
 POINTSYS::~POINTSYS(void)
  {
   // ����������� ����������
   IndicatorRelease(_handlePBI);
   IndicatorRelease(_handleEMA3Eld);
   IndicatorRelease(_handleEMAfastJr);
   IndicatorRelease(_handleEMAslowJr);
   IndicatorRelease(_handleSTOCEld);
   // ����������� ������ ��� ������
   ArrayFree(_bufferPBI);
   ArrayFree(_bufferEMA3Eld);
   ArrayFree(_bufferEMAfastJr);
   ArrayFree(_bufferEMAslowJr);
   // ����� � ��� �� ���������������
   log_file.Write(LOG_DEBUG, StringFormat("%s �������������.", MakeFunctionPrefix(__FUNCTION__)));    
  }