//+------------------------------------------------------------------+
//|                                                CTrendChannel.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ����� ��������� ����� � �������                                  |
//+------------------------------------------------------------------+
// ����������� ����������� ���������
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������
#include <DrawExtremums/CExtremum.mqh> // ����� �����������
#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����
#include <Arrays\ArrayObj.mqh> // ����� ������������ ��������
#include <StringUtilities.mqh> // ��������� �������


// ������������ ����� ��������
enum ENUM_PRICE_MOVE_TYPE
 {
  MOVE_UNKNOWN = 0,
  MOVE_TREND_UP,
  MOVE_TREND_DOWN,
  MOVE_FLAT_A,
  MOVE_FLAT_B,
  MOVE_FLAT_C,
  MOVE_FLAT_D,
  MOVE_FLAT_E,
  MOVE_FLAT_F,
  MOVE_FLAT_G
 };
 
// ������������ ����� �����������
enum ENUM_EXTR_TYPE
 {
  EXTR_HIGH_0 = 0,
  EXTR_HIGH_1,
  EXTR_LOW_0,
  EXTR_LOW_1
 };
 
// ����� �������� ����
class CMove : public CObject
 {
  private:
   CChartObjectTrend _moveLine; // ������ ������ �����
   long _chartID;  // ID �������
   string _symbol; // ������
   ENUM_TIMEFRAMES _period; // ������
   string _lineUpName; // ���������� ��� ��������� ������� �����
   string _lineDownName; // ���������� ��� ��������� ������ �����
   string _moveName; // ��� �������� (��� ��������� ����������� ����� �����)
   double _percent; // ������� �������� ������
   // ���������� ��� �������� ������ ��������
   ENUM_PRICE_MOVE_TYPE _moveType; // ��� ��������
   double _height; // ������ ������ ��������
   // ��������� ������ ������
   void GenUniqName (); // ���������� ���������� ��� ���������� ������
   void CountHeight (); // ��������� ������ ������
   void CountMoveType (); // ��������� ��� ��������
   // ������ ���������� ���� ��������
   int IsItTrend(); // ���� ������� �������� �����
   int IsFlatA();   // ��� ����� �
   int IsFlatB();   // ��� ����� B
   int IsFlatC();   // ��� ����� C
   int IsFlatD();   // ��� ����� D
   int IsFlatE();   // ��� ����� E
   int IsFlatF();   // ��� ����� F
   int IsFlatG();   // ��� ����� G
  public:
   CExtremum *_extrUp0,*_extrUp1; // ���������� ������� �����
   CExtremum *_extrDown0,*_extrDown1; // ���������� ������ �����  
   CMove(string move_name,int chartID, string symbol, ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent); // ����������� ������ �� �����
  ~CMove(); // ���������� ������
   // ������ ������ ��� ��������� ������� ��������
   double GetHeight () { return(_height); }; // ���������� ������ ������
   ENUM_PRICE_MOVE_TYPE  GetMoveType () { return(_moveType); }; // ���������� ��� ��������
   int GetDirection (); // ���������� ��� ������, ���� �������� - �����
   CExtremum  *GetMoveExtremum (ENUM_EXTR_TYPE extr_type); // ���������� ��������� ��������
 };

// ����������� ������� ������ ������� ��������

/////////��������� ������ ������

void CMove::GenUniqName(void) // ���������� ���������� ��� ���������� ������
 {
  // ������� ���������� ����� ��������� ����� ������ �� �������, ������� � ������� ������� ����������
  _lineUpName = _moveName+"up"+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrUp0.time)+"."+TimeToString(_extrUp1.time);
  _lineDownName = _moveName+"down"+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrDown0.time)+"."+TimeToString(_extrDown1.time);
 }
 
void CMove::CountHeight(void)
 {
  _height = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
 }
 
int CMove::IsItTrend(void) // ���������, �������� �� ������ ����� ���������
 {
  double h1,h2;
  double H1,H2;
  // ���� ����� ����� 
  if ( GreatDoubles(_extrUp0.price,_extrUp1.price) && GreatDoubles(_extrDown0.price,_extrDown1.price))
   {
    // ���� ��������� ��������� - ����
    if (_extrDown0.time > _extrUp0.time)
     {
      H1 = _extrUp0.price - _extrDown1.price;
      H2 = _extrUp1.price - _extrDown1.price;
      h1 = MathAbs(_extrDown0.price - _extrDown1.price);
      h2 = MathAbs(_extrUp0.price - _extrUp1.price);
      // ���� ���� ��������� ����� ��� �������������
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )
       return (1);
     }
    
    // ���� ��������� ��������� - �����
    if (_extrDown0.time < _extrUp0.time)
     {
      H1 = _extrUp1.price - _extrDown0.price;
      H2 = _extrUp1.price - _extrDown1.price;
      h1 = MathAbs(_extrDown0.price - _extrDown1.price);
      h2 = MathAbs(_extrUp0.price - _extrUp1.price);
      // ���� ���� ��������� ����� ��� �������������
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )
       return (1);
     }
      
   }
  // ���� ����� ����
  if ( LessDoubles(_extrUp0.price,_extrUp1.price) && LessDoubles(_extrDown0.price,_extrDown1.price))
   {
    
    // ����  ��������� ��������� - �����
    if (_extrUp0.time > _extrDown0.time)
     {
      H1 = _extrUp1.price - _extrDown0.price;    
      H2 = _extrUp1.price - _extrDown1.price;
      h1 = MathAbs(_extrUp0.price - _extrUp1.price);
      h2 = MathAbs(_extrDown0.price - _extrDown1.price);
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )    
       return (-1);
     }
    
    // ���� ��������� ��������� - ����
    else if (_extrUp0.time < _extrDown0.time)
     {
      H1 = _extrUp0.price - _extrDown1.price;    
      H2 = _extrUp1.price - _extrDown1.price;
      h1 = MathAbs(_extrUp0.price - _extrUp1.price);
      h2 = MathAbs(_extrDown0.price - _extrDown1.price);
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h2,H1*_percent) && GreatDoubles(h1,H2*_percent) )    
       return (-1);
     }
    
   }   
   
  return (0);
 }

// ����������� ������� ���������� ����� �������� ��������

// ������� ��������� ����� ������


int CMove::IsFlatA ()  // ���� �  
 {
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price),_percent*_height) &&
       GreatOrEqualDoubles (_extrDown0.price - _extrDown1.price,_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 } 

 int CMove::IsFlatB () // ���� B
 {
  if ( GreatOrEqualDoubles (_extrUp1.price-_extrUp0.price,_percent*_height) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price),_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CMove::IsFlatC () // ���� C
 {
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price),_percent*_height) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price),_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 } 
 
int CMove::IsFlatD () // ���� D
 {
  if ( GreatOrEqualDoubles (_extrUp1.price - _extrUp0.price,_percent*_height) &&
       GreatOrEqualDoubles (_extrDown0.price - _extrDown1.price,_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CMove::IsFlatE () // ���� E
 {
  if ( GreatOrEqualDoubles (_extrUp0.price-_extrUp1.price,_percent*_height) &&
       GreatOrEqualDoubles (_extrDown1.price - _extrDown0.price,_percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CMove::IsFlatF () // ���� F
 {
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price), _percent*_height) &&
       GreatOrEqualDoubles (_extrDown1.price -_extrDown0.price , _percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }  
 
int CMove::IsFlatG () // ���� G
 {
  if ( GreatOrEqualDoubles (_extrUp0.price - _extrUp1.price, _percent*_height) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price), _percent*_height)
     )
    {
     return (true);
    }
  return (false);
 }       
 

///////////// ��������� ������ ������

CMove::CMove(string move_name,int chartID,string symbol,ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent)
 {
  int tempDir; // ��������� ���������� ��� ���������� �������� ��������
  // ��������� ���� ������
  _chartID = chartID;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _moveType = 0;
  _moveName = move_name;
  // ������� ������� ����������� ��� ��������� �����
  _extrUp0   = extrUp0;
  _extrUp1   = extrUp1;
  _extrDown0 = extrDown0;
  _extrDown1 = extrDown1;
  
  // ���������� ���������� ����� ��������� �����
  GenUniqName();
  // ��������� ������ ������ ��������
  CountHeight();
  // ������������ ���� ��������
  tempDir = IsItTrend ();
  if (tempDir == MOVE_TREND_UP)  // ���� ������ ����� �����
    _moveType = 1;
  if (tempDir == -1) // ���� ������ ����� ����
    _moveType = MOVE_TREND_DOWN;   
  if (IsFlatA())     // ���� ������ ���� �
     _moveType = MOVE_FLAT_A;
  if (IsFlatB())     // ���� ������ ���� B
     _moveType = MOVE_FLAT_B;
  if (IsFlatC())     // ���� ������ ���� C
     _moveType = MOVE_FLAT_C;
  if (IsFlatD())     // ���� ������ ���� D
     _moveType = MOVE_FLAT_D;               
  if (IsFlatE())     // ���� ������ ���� E
     _moveType = MOVE_FLAT_E;
  if (IsFlatF())     // ���� ������ ���� F
     _moveType = MOVE_FLAT_F;
  if (IsFlatG())     // ���� ������ ���� G
     _moveType = MOVE_FLAT_G;            
 
  // ���� �� ����� �������� 
  if (_moveType == MOVE_TREND_UP || _moveType == MOVE_TREND_DOWN)  // ���� ������� ��������� ��������
   {
    
    _moveLine.Create(_chartID,_lineUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // ������� �����
    ObjectSetInteger(_chartID,_lineUpName,OBJPROP_COLOR,clrLightBlue);  
    _moveLine.Create(_chartID,_lineDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // ������� ����� 
    ObjectSetInteger(_chartID,_lineDownName,OBJPROP_COLOR,clrLightBlue);        
   }
  else if (_moveType == MOVE_FLAT_A ||
           _moveType == MOVE_FLAT_B ||
           _moveType == MOVE_FLAT_C ||
           _moveType == MOVE_FLAT_D ||
           _moveType == MOVE_FLAT_E ||
           _moveType == MOVE_FLAT_F ||
           _moveType == MOVE_FLAT_G                                                       
           ) // ���� ������� �������� ��������
   {
    _moveLine.Create(_chartID,_lineUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // ������� �����
    ObjectSetInteger(_chartID,_lineUpName,OBJPROP_COLOR,clrYellow);      
    _moveLine.Create(_chartID,_lineDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // ������� �����     
    ObjectSetInteger(_chartID,_lineDownName,OBJPROP_COLOR,clrYellow);      
   } 
 }
 
// ���������� ������
CMove::~CMove()
 {
  ObjectDelete(_chartID,_lineDownName);
  ObjectDelete(_chartID,_lineUpName);
 }

 
 // ���������� ��� ������, ���� ������ - �����
 int CMove::GetDirection(void)
  {
   if (_moveType == MOVE_TREND_DOWN)
    return (-1);
   if (_moveType == MOVE_TREND_UP)
    return (1);
   return (0);
  }
 
 CExtremum  *CMove::GetMoveExtremum(ENUM_EXTR_TYPE extr_type=EXTR_HIGH_0)
  {
   switch (extr_type)
    {
     case EXTR_HIGH_0:
      return (_extrUp0);
     break;
     case EXTR_HIGH_1:
      return (_extrUp1);
     break;
     case EXTR_LOW_0:
      return (_extrDown0);
     break;
     case EXTR_LOW_1:
      return (_extrDown1);
     break;               
    }
   return (_extrUp0);
  }