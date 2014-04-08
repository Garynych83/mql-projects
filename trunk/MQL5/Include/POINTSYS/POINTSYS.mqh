//+------------------------------------------------------------------+
//|                                                   DISEPTICON.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

// ����������� ���������

#include <TradeManager/TradeManager.mqh>    // �������� ����������
#include <ColoredTrend/ColoredTrendUtilities.mqh>
#include <Lib CisNewBar.mqh>                // ��� �������� ������������ ������ ����
#include "STRUCTS.mqh"                      // ���������� �������� ������ ��� ��������� ��������



// ����� �������� �������
class CPointSys
 { 
  private:
   //---------- ��������� ������ ������ �����������
   
   // ��������� ����������
   sEmaParams  _ema_params;   // ��������� EMA
   sMacdParams _macd_params;  // ��������� MACD
   sStocParams _stoc_params;  // ��������� ����������
   sPbiParams  _pbi_params;   // ��������� PriceBasedIndicator
   sDealParams _deal_params;  // ���������� ������
   sBaseParams _base_params;  // ������� ���������
   
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
   

   CisNewBar *_eldNewBar;          // ���������� ��� ����������� ������ ���� �� eldTF  
   
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
  ENUM_MOVE_TYPE GetMovingType();  // ��� ��������� ���� �������� 
  // ������������ � ����������� ������ �����������
  CPointSys (sDealParams &deal_params,sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params);      // ����������� ������
 ~CPointSys ();      // ���������� ������ 
 };
 
 
 int  CPointSys::GetFlatSignals(void)
  {
  static int  wait = 0;
  int order_direction = 0;  

  MqlTick tick;   // ��������� ���� 
 
  if ( isUpLoaded () )     // ���� ������ ���������� ������� ������������
   {
 
  if(_bufferSTOCEld[1] > _stoc_params.top_level && _bufferSTOCEld[0] < _stoc_params.top_level)
  {
   if(GreatDoubles(_bufferEMAfastJr[1], _bufferEMAslowJr[1]) && GreatDoubles(_bufferEMAslowJr[0], _bufferEMAfastJr[0]))
   {
    if(GreatDoubles(tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
    {
     //�������
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� SELL.", MakeFunctionPrefix(__FUNCTION__)));     
     return (-1);  // ���� ������ �� �������
    }
   }
  }
  if(_bufferSTOCEld[1] < _stoc_params.bottom_level && _bufferSTOCEld[0] > _stoc_params.bottom_level)
  {
   if(GreatDoubles(_bufferEMAslowJr[1], _bufferEMAfastJr[1]) && GreatDoubles(_bufferEMAfastJr[0], _bufferEMAslowJr[0]))
   {
    if(LessDoubles(tick.bid, _bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point))
    {
     //�������
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� BUY.", MakeFunctionPrefix(__FUNCTION__)));     
     return (1);  // ���� ������ �� �������
    }
   }
  }
  
  // divengenceFlatMACD
  
  wait++; 
  if (order_direction != 0)   // ���� ���� ������ � ����������� ������ 
  {
   if (wait > _base_params.waitAfterDiv)   // ��������� �� ���������� ����� �������� ����� �����������
   {
    wait = 0;                 // ���� �� ��������� �������� ������� �������� � ����������� ������
    order_direction = 0;
   }
  }  
    //order_direction = divergenceMACD(handleMACD, Symbol(), eldTF, 0, nullMACD);   
  if (order_direction == 1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ����������� MACD 1", MakeFunctionPrefix(__FUNCTION__)));
   if(LessDoubles(tick.bid, _bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� BUY.", MakeFunctionPrefix(__FUNCTION__)));
    wait = 0;
    return (1);  // ���� ������ �� �������

   }
  }
  if (order_direction == -1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ����������� MACD -1", MakeFunctionPrefix(__FUNCTION__)));
   if(GreatDoubles(tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� SELL.", MakeFunctionPrefix(__FUNCTION__)));
    wait = 0;
    return (-1);  // ���� ������ �� �������
  
   }
  }  
  
  // divergence Flat Stochastic
  
  if (order_direction == 1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ����������� MACD 1", MakeFunctionPrefix(__FUNCTION__)));
   if(LessDoubles(tick.bid, _bufferEMA3Eld[0] + _base_params.deltaPriceToEMA*_Point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� BUY.", MakeFunctionPrefix(__FUNCTION__)));
    wait = 0;
    return (1);  // ������ �� �������    
   }
  }
  if (order_direction == -1)
  {
   log_file.Write(LOG_DEBUG, StringFormat("%s ����������� MACD -1", MakeFunctionPrefix(__FUNCTION__)));
   if(GreatDoubles(tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
   {
    log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������� SELL.", MakeFunctionPrefix(__FUNCTION__)));
    wait = 0;    
    return (-1);  // ������ �� �������
   }
  }
  
  }
  
    return 0; // ��� �������
  }
  
 int  CPointSys::GetTrendSignals(void)
  {
   MqlTick tick;   // ��������� ����
   
   if ( isUpLoaded () )   // �������� ���������� ����������
    {
     
   }
   return (0); // ��� �������
  } 
 
 
 
 int CPointSys::GetCorrSignals(void)
  {
   MqlTick tick;   // ��������� ����
   if ( isUpLoaded () ) // ���� ������� ���������� ����������
    {
     
    }
   return (0); // ��� �������
  }
 
 // ����������� ������� ������ ������� �������
 
 bool CPointSys::isUpLoaded(void)   // ����� �������� (����������) ������� � �����. ���������� true � ������ ������
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
            copiedPBI     =       CopyBuffer( _handlePBI,       4, 1, 1, _bufferPBI);
            copiedSTOCEld   =     CopyBuffer( _handleSTOCEld,   0, 1, 2, _bufferSTOCEld);
            copiedEMAfastJr =     CopyBuffer( _handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
            copiedEMAslowJr =     CopyBuffer( _handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
            copiedEMA3Eld   =     CopyBuffer( _handleEMA3Eld,   0, 0, 1, _bufferEMA3Eld);
           }  
 if (    copiedPBI != 1 ||   copiedSTOCEld != 2 ||  copiedEMA3Eld != 1 ||
      copiedEMAfastJr != 2 || copiedEMAslowJr != 2 )   //�������� ������ �����������
  {
  // Comment("STOC = ",copiedSTOCEld," copiedEMA3Eld = ",copiedEMA3Eld,"copiedEMAfastJr=",copiedEMAfastJr,"copiedEMAslowJr=",copiedEMAslowJr,"copiedPBI=",copiedPBI);
   log_file.Write(LOG_DEBUG, StringFormat("%s ������ ���������� ������.Error(%d) = %s" 
                                          , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
   return (false);
  }
 else
  {
  //Comment("�������� � ��������� = ",_bufferPBI[0]);
  return (true);
   }     
      }
   return (false);
  }
 
 
 ENUM_MOVE_TYPE CPointSys::GetMovingType(void)
  {
   if (_bufferPBI[0] == 1)
    return (MOVE_TYPE_TREND_UP);            // ����� ����� - �����
   if (_bufferPBI[0] == 2)
    return (MOVE_TYPE_TREND_UP_FORBIDEN);   // ����� �����, ����������� ������� �� - ����������
   if (_bufferPBI[0] == 3)
    return (MOVE_TYPE_TREND_DOWN);          // ����� ���� - �������
   if (_bufferPBI[0] == 4) 
    return (MOVE_TYPE_TREND_DOWN_FORBIDEN); // ����� ����, ����������� ������� �� - ����������
   if (_bufferPBI[0] == 5)  
    return (MOVE_TYPE_CORRECTION_UP);       // ��������� �����, �������������� ����� ���� - �������
   if (_bufferPBI[0] == 6)  
    return (MOVE_TYPE_CORRECTION_DOWN);     // ��������� ����, �������������� ����� ����� - �������
   if (_bufferPBI[0] == 7)  
    return (MOVE_TYPE_FLAT);                // ���� - ������
    
   return (MOVE_TYPE_UNKNOWN);              // ����������� ��������
  }
 
 // ����������� ������������ � �����������
 
 // ����������� ������ �����������
 CPointSys::CPointSys(sDealParams &deal_params,sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params)
  {
   //---------�������������� ���������, ������, ���������� � ������
   
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
   _handlePBI       = iCustom(_Symbol, /*_base_params.eldTF*/ _Period, "PriceBasedIndicator", /*_pbi_params.bars*/1000);
   _handleSTOCEld   = iStochastic(NULL, _base_params.eldTF, _stoc_params.kPeriod, _stoc_params.dPeriod, _stoc_params.slow, MODE_SMA, STO_CLOSECLOSE);
   _handleEMAfastJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAfastJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMAslowJr = iMA(Symbol(),  _base_params.jrTF, _ema_params.periodEMAslowJr, 0, MODE_EMA, PRICE_CLOSE);
   _handleEMA3Eld   = iMA(Symbol(),  _base_params.eldTF,               3, 0, MODE_EMA, PRICE_CLOSE);

 if (_handlePBI == INVALID_HANDLE || _handleEMAfastJr == INVALID_HANDLE || _handleEMAslowJr == INVALID_HANDLE)
 {

  log_file.Write(LOG_DEBUG, StringFormat("%s INVALID_HANDLE (handleTrend). Error(%d) = %s" 
                                        , MakeFunctionPrefix(__FUNCTION__), GetLastError(), ErrorDescription(GetLastError())));
  //return(INIT_FAILED);
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
 
 CPointSys::~CPointSys(void)
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