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

// ����� �������� ����
class CPriceMovement : public CObject
 {
  private:
   CExtremum *_extrUp0,*_extrUp1; // ���������� ������� �����
   CExtremum *_extrDown0,*_extrDown1; // ���������� ������ �����
   CChartObjectTrend _moveLine; // ������ ������ �����
   int _moveType; // ��� �������� 
   long _chartID;  // ID �������
   string _symbol; // ������
   ENUM_TIMEFRAMES _period; // ������
   string _lineUpName; // ���������� ��� ��������� ������� �����
   string _lineDownName; // ���������� ��� ��������� ������ �����
   double _percent; // ������� �������� ������
   
   // ��������� ������ ������
   void GenUniqName (); // ���������� ���������� ��� ���������� ������
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
   CPriceMovement(int chartID, string symbol, ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent); // ����������� ������ �� �����
  ~CPriceMovement(); // ���������� ������
   // ������ ������
   int    GetMoveType () { return (_moveType); }; // ���������� ��� �������� 
   double GetPriceLineUp(datetime time); // ���������� ���� �� ������� ����� �� �������
   double GetPriceLineDown(datetime time); // ���������� ���� �� ������ ����� �� �������
 };

// ����������� ������� ������ ������� ��������

/////////��������� ������ ������

void CPriceMovement::GenUniqName(void) // ���������� ���������� ��� ���������� ������
 {
  // ������� ���������� ����� ��������� ����� ������ �� �������, ������� � ������� ������� ����������
  _lineUpName = "moveLineUp."+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrUp0.time);
  _lineDownName = "moveLineDown."+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrDown0.time);
 }
 
int CPriceMovement::IsItTrend(void) // ���������, �������� �� ������ ����� ���������
 {
  double h1,h2;
  double H1,H2;
  // ���� ����� ����� 
  if (GreatDoubles(_extrUp0.price,_extrUp1.price) && GreatDoubles(_extrDown0.price,_extrDown1.price))
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
   
   }
  // ���� ����� ����
  if (LessDoubles(_extrUp0.price,_extrUp1.price) && LessDoubles(_extrDown0.price,_extrDown1.price))
   {
    
    // ����  ��������� ��������� - �����
    if (_extrUp0.time > _extrDown0.time)
     {
      H1 = _extrDown0.price - _extrUp1.price;    
      H2 = _extrDown1.price - _extrUp1.price;
      h1 = MathAbs(_extrUp0.price - _extrUp1.price);
      h2 = MathAbs(_extrDown0.price - _extrDown1.price);
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h1,H1*_percent) && GreatDoubles(h2,H2*_percent) )    
       return (-1);
     }

   }   
   
  return (0);
 }

// ����������� ������� ���������� ����� �������� ��������

// ������� ��������� ����� ������

int CPriceMovement::IsFlatA ()  // ���� �  
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price),_percent*H) &&
       GreatOrEqualDoubles (_extrDown0.price - _extrDown1.price,_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }

int CPriceMovement::IsFlatB () // ���� B
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( GreatOrEqualDoubles (_extrUp1.price-_extrUp0.price,_percent*H) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price),_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }

int CPriceMovement::IsFlatC () // ���� C
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price),_percent*H) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price),_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CPriceMovement::IsFlatD () // ���� D
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( GreatOrEqualDoubles (_extrUp1.price-_extrUp0.price,_percent*H) &&
       GreatOrEqualDoubles (_extrDown0.price - _extrDown1.price,_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CPriceMovement::IsFlatE () // ���� E
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( GreatOrEqualDoubles (_extrUp0.price-_extrUp1.price,_percent*H) &&
       GreatOrEqualDoubles (_extrDown1.price - _extrDown0.price,_percent*H)
     )
    {
     return (true);
    }
  return (false);
 }
 
int CPriceMovement::IsFlatF () // ���� F
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( LessOrEqualDoubles (MathAbs(_extrUp1.price-_extrUp0.price), _percent*H) &&
       GreatOrEqualDoubles (_extrDown1.price - _extrDown0.price , _percent*H)
     )
    {
     return (true);
    }
  return (false);
 } 

int CPriceMovement::IsFlatG () // ���� G
 {
  double H = MathMax(_extrUp0.price,_extrUp1.price) - MathMin(_extrDown0.price,_extrDown1.price);
  if ( GreatOrEqualDoubles (_extrUp0.price - _extrUp1.price, _percent*H) &&
       LessOrEqualDoubles (MathAbs(_extrDown0.price - _extrDown1.price), _percent*H)
     )
    {
     return (true);
    }
  return (false);
 }  

///////////// ��������� ������ ������

CPriceMovement::CPriceMovement(int chartID,string symbol,ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent)
 {
  int tempDir; // ��������� ���������� ��� ���������� �������� ��������
  // ��������� ���� ������
  _chartID = chartID;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _moveType = 0;
  // ������� ������� ����������� ��� ��������� �����
  _extrUp0   = extrUp0;
  _extrUp1   = extrUp1;
  _extrDown0 = extrDown0;
  _extrDown1 = extrDown1;
  // ���������� ���������� ����� ��������� �����
  GenUniqName();
  // ������������ ���� ��������
  tempDir = IsItTrend ();
  if (tempDir == 1)  // ���� ������ ����� �����
    _moveType = 1;
  if (tempDir == -1) // ���� ������ ����� ����
    _moveType = -1; 
  if (IsFlatA())     // ���� ������ ���� �
    _moveType = 2;
  if (IsFlatB())     // ���� ������ ���� B
    _moveType = 3;
  if (IsFlatC())     // ���� ������ ���� C
    _moveType = 4;  
  if (IsFlatD())     // ���� ������ ���� D
    _moveType = 5;
  if (IsFlatE())     // ���� ������ ���� E
    _moveType = 6;
  if (IsFlatF())     // ���� ������ ���� F
    _moveType = 7;
  if (IsFlatG())     // ���� ������ ���� G
    _moveType = 8;  
  // ���� �� ����� �������� 
  if (_moveType == 1 || _moveType == -1)  // ���� ������� ��������� ��������
   {
    _moveLine.Create(_chartID,_lineUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // ������� �����
    ObjectSetInteger(_chartID,_lineUpName,OBJPROP_COLOR,clrRed);
    _moveLine.Create(_chartID,_lineDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // ������� ����� 
    ObjectSetInteger(_chartID,_lineDownName,OBJPROP_COLOR,clrRed);     
    Print("����� = ",TimeToString(TimeCurrent()));         
   }
  else if (_moveType > 1) // ���� ������� �������� ��������
   {
    _moveLine.Create(_chartID,_lineUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // ������� �����
    ObjectSetInteger(_chartID,_lineUpName,OBJPROP_COLOR,clrYellow);      
    _moveLine.Create(_chartID,_lineDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // ������� �����     
    ObjectSetInteger(_chartID,_lineDownName,OBJPROP_COLOR,clrYellow);      
   } 
 }
 
// ���������� ������
CPriceMovement::~CPriceMovement()
 {
  ObjectDelete(_chartID,_lineDownName);
  ObjectDelete(_chartID,_lineUpName);
 }
 
double CPriceMovement::GetPriceLineUp(datetime time) // ���������� ���� �� ������� ����� 
 {
  return (ObjectGetValueByTime(_chartID,_lineUpName,time));
 } 
 
double CPriceMovement::GetPriceLineDown(datetime time) // ���������� ���� �� ������ �����
 {
  return (ObjectGetValueByTime(_chartID,_lineDownName,time));
 }

class CMoveContainer 
 {
  private:
   int _handleDE; // ����� ���������� DrawExtremums
   int _chartID; //ID �������
   
   string _symbol; // ������
   string _eventExtrUp; // ��� ������� ������� �������� ����������
   string _eventExtrDown; // ��� ������� ������� ������� ���������� 
   double _percent; // ������� �������� ������
   ENUM_TIMEFRAMES _period; // ������
   int    _trendNow; // ���� ����, ��� � ������ ������ ���� ��� ��� ������
   CExtrContainer *_container; // ��������� �����������
   CArrayObj _bufferMove;// ����� ��� �������� ��������
   // ��������� ������ ������
   string GenEventName (string eventName) { return(eventName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
  public:
   // ��������� ������ ������
   CMoveContainer(int chartID,string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent); // ����������� ������
   ~CMoveContainer(); // ���������� ������
   // ������ ������
   CPriceMovement *GetMoveByIndex (int index); // ���������� ��������� �� ����� �� �������
   bool IsTrendNow () { return (_trendNow); }; // ���������� true, ���� � ������� ������ - �����, false - ���� � ������� ������ - ��� �����
   int  GetTotal () { return (_bufferMove.Total() ); }; // ���������� ���������� �������� �� ������� ������ � ������
   void RemoveAll (); // ������� ����� ��������
   void UploadOnEvent (string sparam,double dparam,long lparam); // ����� ��������� ���������� �� �������� 
   bool UploadOnHistory (); // ����� ��������� ������ � ����� �� ������� 
 };

// ����������� ������� ������ CTrendChannel
CMoveContainer::CMoveContainer(int chartID, string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent)
 {
  _chartID = chartID;
  _handleDE = handleDE;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _container = new CExtrContainer(handleDE,symbol,period);
  // ��������� ���������� ����� �������
  _eventExtrDown = GenEventName("EXTR_DOWN_FORMED");
  _eventExtrUp = GenEventName("EXTR_UP_FORMED");
 }
 
// ���������� ������
CMoveContainer::~CMoveContainer()
 {
  _bufferMove.Clear();
  delete _container;
 }
 
// ���������� ��������� �� ����� �� �������
CPriceMovement * CMoveContainer::GetMoveByIndex(int index)
 {
  CPriceMovement *curTrend = _bufferMove.At(_bufferMove.Total()-1-index);
  if (curTrend == NULL)
   PrintFormat("%s �� ������� ������ i=%d, total=%d", MakeFunctionPrefix(__FUNCTION__), index, _bufferMove.Total());
  return (curTrend);
 }
 
// ����� ������� ����� ��������
void CMoveContainer::RemoveAll(void)
 {  
  _bufferMove.Clear();
 }
 
// ����� ��������� ��������� � �����
void CMoveContainer::UploadOnEvent(string sparam,double dparam,long lparam)
 {
  CPriceMovement *temparyMove;
  CPriceMovement *previewMove;
  
  // ��������� ����������
  _container.UploadOnEvent(sparam,dparam,lparam);
  previewMove = GetMoveByIndex(0);
  // ���� ��������� ��������� - ������
  if (sparam == _eventExtrDown)
   {
     // �������� �������� �������� ��������
     temparyMove = new CPriceMovement(_chartID, _symbol, _period,_container.GetExtrByIndex(2),_container.GetExtrByIndex(4),_container.GetExtrByIndex(1),_container.GetExtrByIndex(3),_percent );     
     // ���� ������� �������� ������� ��������
     if (temparyMove != NULL)
        {
         // ���� ������� �����
         if (temparyMove.GetMoveType() == 1 || temparyMove.GetMoveType() == -1)
          {
           // ��������� ������� �����
           _trendNow = temparyMove.GetMoveType();
           // �� ������� �����
           RemoveAll();
           // � ��������� ����� � �����
           _bufferMove.Add(temparyMove);
          }
         // ����� ����  ��� ����
         else if (temparyMove.GetMoveType() > 1)
          {
           // �� ��������� ��� � �����
           _bufferMove.Add(temparyMove);
          }
        }     
   }
  // ���� ��������� ��������� - �������
  if (sparam == _eventExtrUp)
   {
     temparyMove = new CPriceMovement(_chartID, _symbol, _period,_container.GetExtrByIndex(1),_container.GetExtrByIndex(3),_container.GetExtrByIndex(2),_container.GetExtrByIndex(4),_percent );
     if (temparyMove != NULL)
        {
         // ���� ������� �����
         if (temparyMove.GetMoveType() == 1 || temparyMove.GetMoveType() == -1)
          {
           // �� ������� �����
           RemoveAll();
           // � ��������� ����� � �����
           _bufferMove.Add(temparyMove);
          }
         // ����� ����  ��� ����
         else if (temparyMove.GetMoveType() > 1)
          {
           // �� ��������� ��� � �����
           _bufferMove.Add(temparyMove);
          }
        }   
   }
 }
 
// ����� ��������� ������ �� �������
bool CMoveContainer::UploadOnHistory(void)
 { 
   int i;
   int extrTotal;
   int dirLastExtr;
   CPriceMovement *temparyMove; 
    // ��������� ������ 
    _container.Upload(0);
    // ���� ������� ���������� ��� ���������� �� �������
    if (_container.isUploaded())
     {    
      extrTotal = _container.GetCountFormedExtr(); // �������� ���������� �����������
      dirLastExtr = _container.GetLastFormedExtr(EXTR_BOTH).direction; // �������� ��������� �������� ����������
      // �������� �� ����������� � ��������� ����� ��������
      for (i=0; i < extrTotal-4; i++)
       {
        // ���� ��������� ����������� ���������� - �����
        if (dirLastExtr == 1)
         {
           temparyMove = new CPriceMovement(_chartID, _symbol, _period,_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2),_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3),_percent );
           if (temparyMove != NULL)
            {
             // ���� ���������� �����
             if (temparyMove.GetMoveType() == 1 || temparyMove.GetMoveType() == -1)
              {
               // ��������� ����� � �����
               _bufferMove.Add(temparyMove);
               // � ���������� true
               Print("���� ����� ����� 1");
               return (true);
              }
             // ���� ��� ����
             else if (temparyMove.GetMoveType() > 1)
              {
               // �� ������ ��������� ��� � ����� ��������
               _bufferMove.Add(temparyMove);
               Print("���� ����� ���� 1");
              }
            }
         }
        // ���� ��������� ����������� ���������� - ����
        if (dirLastExtr == -1)
         {
           temparyMove = new CPriceMovement(_chartID, _symbol, _period,_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3),_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2),_percent );         
           if (temparyMove != NULL)
            {
             // ���� ������� �����
             if (temparyMove.GetMoveType() == 1 || temparyMove.GetMoveType() == -1)
              {
                // �� ��������� ����� � �����
                _bufferMove.Add(temparyMove);
                Print("���� ����� ����� 2");
                // � ���������� true
                return (true);
              }
             else if (temparyMove.GetMoveType() > 1)
              { 
               // �� ������ ��������� �������� � ����� ��������
               _bufferMove.Add(temparyMove);
               Print("���� ����� ���� 2");
              }
              
            }
         }
        dirLastExtr = -dirLastExtr; 
       }
      return (true);
     }
   return (false);
 }