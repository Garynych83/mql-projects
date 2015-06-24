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
   CisNewBar *_curNewBar;          // ���������� ��� ����������� ������ ���� �� ������� ��  
   // ������ ���������� ��������
   int StochasticAndEma();         // ������ ��������� ��� � ���� ���������������/���������������
   int CompareEMAWithPriceEld_AND_CrossEMAJr(); // 
   int CorrSignals();
   ENUM_MOVE_TYPE lastTrend;                  // ����������� ���������� ������
  public:

  // ������ ��������� �������� �������� �� ������ �������� �������
   int  GetFlatSignals  ();        // ��������� ��������� ������� �� �����
   int  GetTrendSignals ();        // ��������� ��������� ������� �� ������
   int  GetCorrSignals  ();        // ��������� ��������� ������� �� ���������  
  // ��������� ������
   bool  isUpLoaded();              // ����� �������� (����������) ������� � �����. ���������� true, ���� �� �������
   int GetMovingType() {return((int)_bufferPBI[0]);};  // ��� ��������� ���� �������� 
  // ������������ � ����������� ������ �����������
   CPointSys (sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params);      // ����������� ������
   ~CPointSys ();      // ���������� ������ 
 };

//--------------------------------------
// ����������� �������� �������
//--------------------------------------
CPointSys::CPointSys(sBaseParams &base_params,sEmaParams &ema_params,sMacdParams &macd_params,sStocParams &stoc_params,sPbiParams &pbi_params)
{
 Print("���������� PointSystem");
 //---------�������������� ���������, ������, ���������� � ������
 _symbol = Symbol();
 lastTrend = 0;     // ���������� ������ ���� ��� �� ����
 ////// ��������� ������� ���������
 _base_params = base_params;
 _ema_params  = ema_params;
 _macd_params = macd_params;
 _stoc_params = stoc_params;
 _pbi_params  = pbi_params;
               
 // �������� ������ ��� ������ ������ ����������� ������������ ������ ����
 _eldNewBar = new CisNewBar(_base_params.eldTF);
 _curNewBar = new CisNewBar(_base_params.curTF);
  // ������� ��������� � ��������, ��� � ���������
 ArraySetAsSeries( _bufferPBI, true);
 ArraySetAsSeries( _bufferPBIforTrendDirection, true);
 ArraySetAsSeries( _bufferEMAfastJr, true);
 ArraySetAsSeries( _bufferEMAslowJr, true);
 ArraySetAsSeries( _bufferSTOCEld, true);
 ArraySetAsSeries( _bufferHighEld,   true);
 ArraySetAsSeries( _bufferLowEld,    true);
  // �������� ������ �������
 //int bars = Bars(Symbol(), Period());
 ArrayResize( _bufferPBI, 1);
 ArrayResize( _bufferPBIforTrendDirection, _pbi_params.historyDepth);
 ArrayResize( _bufferEMAfastJr, 2);
 ArrayResize( _bufferEMAslowJr, 2);
 ArrayResize( _bufferSTOCEld, 1);
 
 //int tmp_handle = iCustom(Symbol(), Period(), "PriceBasedIndicator", 1000, 1, 1.5);
}

//---------------------------------------------  
// ���������� �������� �������
//---------------------------------------------
 CPointSys::~CPointSys(void)
  {
   delete _eldNewBar;
   // ����������� ������ ��� ������
   ArrayFree(_bufferPBI);
   ArrayFree( _bufferPBIforTrendDirection);   
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
  static int dm = 0, ds = 0;
  int points = 0; 
  SymbolInfoTick(_symbol, _tick); 

  if (isUpLoaded ())     // ���� ������ ���������� ������� ������������
  {
   if (_curNewBar.isNewBar())
   {
    dm = divergenceMACD(_macd_params.handleMACD, Symbol(), Period());
    ds = divergenceSTOC(_stoc_params.handleStochastic, Symbol(), Period(), _stoc_params.top_level, _stoc_params.bottom_level);
   }
   points += dm;
   points += ds;
   //points += lastTrend;
   if (MathAbs(points) >= 1)
   {
    Print("Points=",points);  
    dm = 0;
    ds = 0;
   }
  }
  return (points); 
 }

//---------------------------------------------------
// ��������� ������ �� ������
//--------------------------------------------------- 
int  CPointSys::GetTrendSignals(void)
{
 int points = 0;
 SymbolInfoTick(Symbol(), _tick);
 
 if ( isUpLoaded () )   // �������� ���������� ����������
 {
   points+= CompareEMAWithPriceEld_AND_CrossEMAJr();  // ���������� ������ 
 }
 return (points); // ���������� ���������� ������
} 

//---------------------------------------------------
// ��������� ������ �� ���������
//---------------------------------------------------  
int CPointSys::GetCorrSignals(void)
{
 int points = 0;
 SymbolInfoTick(Symbol(), _tick);
 if ( isUpLoaded () ) // ���� ������� ���������� ����������
 {
   points+= CorrSignals();  // ���������� ������
 }
 return (points); // ���������� ���������� ������
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
 int copiedEMAfast =-1;
 int copiedEMAfastJr=-1;
 int copiedEMAslowJr=-1;
 int copiedHigh=-1;
 int copiedLow=-1;
 int attempts;
 
 if (lastTrend == 0)
 {
  for(attempts = 0; attempts < 25; attempts++)
  {
   Sleep(100);
   copiedPBI = CopyBuffer(_pbi_params.handlePBI, 4, 0, _pbi_params.historyDepth, _bufferPBIforTrendDirection);
  }
  if (copiedPBI < 0)
  {
   PrintFormat("%s �� ������� ����������� ����� _bufferPBIforTrendDirection", MakeFunctionPrefix(__FUNCTION__));
   return(false);
  }
  
  for (int i = 0; i < _pbi_params.historyDepth; i++)
  {
   if (_bufferPBIforTrendDirection[i] == 1 ||   // ���� ��������� ����� �����
       _bufferPBIforTrendDirection[i] == 2 )
   {
    lastTrend = 1;
    break;
   }
   if (_bufferPBIforTrendDirection[i] == 3 ||   // ���� ��������� ����� ����
       _bufferPBIforTrendDirection[i] == 4 ) 
   {
    lastTrend = -1;
    break;
   }
  }
 }
 
 for(attempts = 0; attempts < 25; attempts++)
 {
  Sleep(100);
  copiedPBI = CopyBuffer(_pbi_params.handlePBI, 4, 0, 1, _bufferPBI);
 }
 if (copiedPBI < 0)
 {
  PrintFormat("%s �� ������� ����������� ����� PBI", MakeFunctionPrefix(__FUNCTION__));
  return(false);
 }
 
 if (_bufferPBI[0] == 1 ||   // ���� ��������� ����� �����
     _bufferPBI[0] == 2 )
   {
     lastTrend = 1;
   }
 if (_bufferPBI[0] == 3 ||   // ���� ��������� ����� ����
     _bufferPBI[0] == 4 ) 
    {
     lastTrend = -1;
    }
 
 if (_eldNewBar.isNewBar() > 0)      //�� ������ ����� ���� �������� TF
 {
  for (attempts = 0; attempts < 25 && (copiedSTOCEld   < 0
                                       || copiedEMAfastJr < 0
                                       || copiedEMAslowJr < 0); attempts++) 
  {
   //�������� ������ �����������
   copiedSTOCEld   = CopyBuffer( _stoc_params.handleStochastic,   0, 1, 2, _bufferSTOCEld);
   copiedEMA3Eld   = CopyBuffer( _ema_params.handleEMA3,   0, 0, 1, _bufferEMA3Eld);
   copiedEMAfast   = CopyBuffer( _ema_params.handleEMAfast,0, 1, 2, _bufferEMAfastEld);
   copiedEMAfastJr = CopyBuffer( _ema_params.handleEMAfastJr, 0, 1, 2, _bufferEMAfastJr);
   copiedEMAslowJr = CopyBuffer( _ema_params.handleEMAslowJr, 0, 1, 2, _bufferEMAslowJr);
   copiedHigh      = CopyHigh  ( Symbol(),  _base_params.eldTF,  1, 2, _bufferHighEld);
   copiedLow       = CopyLow   ( Symbol(),  _base_params.eldTF,  1, 2, _bufferLowEld); 
  }  
  if (copiedSTOCEld    != 2 ||
      copiedEMA3Eld    != 1 ||
      copiedEMAfast    != 2 || 
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
    return(1);  // ���� ������ �� �������
   }
  }
 }
 return(0);   // ��� �������
}

//------------------------------------------
// ������ ��� ������
//------------------------------------------
int CPointSys::CompareEMAWithPriceEld_AND_CrossEMAJr(void)
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
     return (1);  // ���� ������ �� �������
    }
   }
  }
 } //end TREND_UP
 else if (_bufferPBI[0] == 3)               //���� ����������� ������ TREND_DOWN  
 {
  if(GreatOrEqualDoubles(_tick.ask, _bufferEMA3Eld[0] - _base_params.deltaPriceToEMA*_Point))
  {

   if (GreatDoubles(_bufferHighEld[0], _bufferEMAfastEld[0] - _base_params.deltaPriceToEMA*_Point) || 
       GreatDoubles(_bufferHighEld[1], _bufferEMAfastEld[1] - _base_params.deltaPriceToEMA*_Point))
   {
    if (GreatDoubles(_bufferEMAfastJr[1], _bufferEMAslowJr[1]) && LessDoubles(_bufferEMAfastJr[0], _bufferEMAslowJr[0]))
    {
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
    return(1);  
 
  return (0); // ��� �������
 }
