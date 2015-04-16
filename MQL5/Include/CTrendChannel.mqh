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

// ����� ��������� �������
class CTrend : public CObject
 {
  private:
   CExtremum *_extrUp0,*_extrUp1; // ���������� ������� �����
   CExtremum *_extrDown0,*_extrDown1; // ���������� ������ �����
   CChartObjectTrend _trendLine; // ������ ������ ��������� �����
   int _direction; // ����������� ������ 
   long _chartID;  // ID �������  
   string _symbol; // ������
   ENUM_TIMEFRAMES _period; // ������
   string _trendUpName; // ���������� ��� ��������� ������� �����
   string _trendDownName; // ���������� ��� ��������� ������ �����
   double _percent; // ������� �������� ������
   // ��������� ������ ������
   void GenUniqName (); // ���������� ���������� ��� ���������� ������
   int  IsItTrend (); // ����� ���������, �������� �� ����������� ������ �������. 
  public:
   CTrend(int chartID, string symbol, ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent); // ����������� ������ �� �����
  ~CTrend(); // ���������� ������
   // ������ ������
   int  GetDirection () { return (_direction); }; // ���������� ����������� ������ 
   void ShowTrend (); // ���������� ����� �� �������
   void HideTrend (); // �������� ����������� ������
 };
 
// ����������� ������� ������ ��������� �������

/////////��������� ������ ������

void CTrend::GenUniqName(void) // ���������� ���������� ��� ���������� ������
 {
  // ������� ���������� ����� ��������� ����� ������ �� �������, ������� � ������� ������� ����������
  _trendUpName = "trendUp."+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrUp0.time);
  _trendDownName = "trendDown."+_symbol+"."+PeriodToString(_period)+"."+TimeToString(_extrDown0.time);  
 }
 
int CTrend::IsItTrend(void) // ���������, �������� �� ������ ����� ���������
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

CTrend::CTrend(int chartID,string symbol,ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1,double percent)
 {
  // ��������� ���� ������
  _chartID = chartID;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  // ������� ������� ����������� ��� ��������� �����
  _extrUp0   = new CExtremum(extrUp0.direction,extrUp0.price,extrUp0.time,extrUp0.state);
  _extrUp1   = new CExtremum(extrUp1.direction,extrUp1.price,extrUp1.time,extrUp1.state);
  _extrDown0 = new CExtremum(extrDown0.direction,extrDown0.price,extrDown0.time,extrDown0.state);
  _extrDown1 = new CExtremum(extrDown1.direction,extrDown1.price,extrDown1.time,extrDown1.state);   
  // ���������� ���������� ����� ��������� �����
  GenUniqName();   
  // �������� ��� ��������
  _direction = IsItTrend ();
  if (_direction != 0)
   {
    // ���������� ��������� �����
    ShowTrend();
   }
 }
 
// ���������� ������
CTrend::~CTrend()
 {
 
 }

void CTrend::ShowTrend(void) // ���������� ����� �� �������
 {
  _trendLine.Create(_chartID,_trendUpName,0,_extrUp0.time,_extrUp0.price,_extrUp1.time,_extrUp1.price); // ������� �����
  _trendLine.Create(_chartID,_trendDownName,0,_extrDown0.time,_extrDown0.price,_extrDown1.time,_extrDown1.price); // ������� �����  
 }

void CTrend::HideTrend(void) // �������� ����� � �������
 {
  ObjectDelete(_chartID,_trendUpName);
  ObjectDelete(_chartID,_trendDownName);
 }

class CTrendChannel 
 {
  private:
   int _handleDE; // ����� ���������� DrawExtremums
   int _chartID; //ID �������
   string _symbol; // ������
   double _percent; // ������� �������� ������
   ENUM_TIMEFRAMES _period; // ������
   CExtrContainer *_container; // ��������� �����������
   CArrayObj _bufferTrend;// ����� ��� �������� ��������� �����  
  public:
   CTrendChannel(int chartID,string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent); // ����������� ������
  ~CTrendChannel(); // ���������� ������
  // ������ ������
  CTrend * GetTrendByIndex (int index); // ���������� ��������� �� ����� �� �������
 };
 
// ����������� ������� ������ CTrendChannel
CTrendChannel::CTrendChannel(int chartID, string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent)
 {
  int i;
  int extrTotal;
  int dirLastExtr;
  CTrend *temparyTrend;
  _chartID = chartID;
  _handleDE = handleDE;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _container = new CExtrContainer(handleDE,symbol,period);
  // ���� ������� ������� ������ ����������
  if (_container != NULL)
   {
    _container.Upload(0);
    // ���� ������� ���������� ��� ���������� �� ������� 
    if (_container.isUploaded())
     {    
      extrTotal = _container.GetCountFormedExtr(); // �������� ���������� �����������
      dirLastExtr = _container.GetLastFormedExtr(EXTR_BOTH).direction; // �������� ��������� �������� ����������
      // �������� �� ����������� � ��������� ����� �������
      for (i=0;i<extrTotal-4;i++)
       {
        // ���� ��������� ����������� ���������� - �����
        if (dirLastExtr == 1)
         {
           temparyTrend = new CTrend(_chartID, _symbol, _period,_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2),_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3),_percent );
           if (temparyTrend != NULL)
            {
             if (temparyTrend.GetDirection() != 0)
                _bufferTrend.Add(temparyTrend);
            }
         }
        // ���� ��������� ����������� ���������� - ����
        if (dirLastExtr == -1)
         {
           temparyTrend = new CTrend(_chartID, _symbol, _period,_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3),_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2),_percent );         
           if (temparyTrend != NULL)
            {
             if (temparyTrend.GetDirection() != 0)
                _bufferTrend.Add(temparyTrend);
            }
         }
        dirLastExtr = -dirLastExtr; 
       }
     }
   }
 }
 
// ���������� ������
CTrendChannel::~CTrendChannel()
 {
  _bufferTrend.Clear();
 }