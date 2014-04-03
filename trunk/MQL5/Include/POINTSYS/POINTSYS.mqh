//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// ����������� ���������

#include <TradeManager/TradeManager.mqh>    // �������� ����������
#include "STRUCTS.mqh"                      // ���������� �������� ������ ��� ��������� ��������

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
   
   
  public:
  // ������ ��������� �������� �������� �� ������ ������� �������
  
  // ������������ � ����������� ������ �����������
  POINTSYS (); // ����������� ������
 ~POINTSYS (); // ���������� ������ 
 };
 
 // ����������� ������������ � �����������
 
 // ����������� ������ �����������
 POINTSYS::POINTSYS(void)
  {
   //---------�������������� ���������, ������, ���������� � ������
   
   ////// �������������� ����������
   _handlePBI       = iCustom(_Symbol, _base_params.eldTF, "PriceBasedIndicator", _pbi_params.historyDepth, _pbi_params.bars);
   _handleSTOCEld   = iStochastic(NULL, eldTF, kPeriod, dPeriod, slow, MODE_SMA, STO_CLOSECLOSE);
   _handleEMAfastJr = iMA(Symbol(),  jrTF, periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMAslowJr = iMA(Symbol(),  jrTF, periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMA3Eld   = iMA(Symbol(), eldTF,               3, 0, MODE_EMA, PRICE_CLOSE);

 if (handleTrend == INVALID_HANDLE || handleEMAfastJr == INVALID_HANDLE || handleEMAslowJr == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  //return(INIT_FAILED);
 }   
 
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
   IndicatorRelease(_handleTrend);
   IndicatorRelease(_handleEMA3Eld);
   IndicatorRelease(_handleEMAfastJr);
   IndicatorRelease(_handleEMAslowJr);
   IndicatorRelease(_handleSTOCEld);
   // ����������� ������ ��� ������
   ArrayFree(_bufferTrend);
   ArrayFree(_bufferEMA3Eld);
   ArrayFree(_bufferEMAfastJr);
   ArrayFree(_bufferEMAslowJr);
   // ����� � ��� �� ���������������
   log_file.Write(LOG_DEBUG, StringFormat("%s �������������.", MakeFunctionPrefix(__FUNCTION__)));    
  }