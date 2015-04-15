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
   // ��������� ������ ������
   void GenUniqName (); // ���������� ���������� ��� ���������� ������
   bool IsItTrend (); // ����� ���������, �������� �� ����������� ������ �������. 
  public:
   CTrend(int chartID, string symbol, ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1); // ����������� ������ �� �����
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
 
bool CTrend::IsItTrend(void) // ���������, �������� �� ������ ����� ���������
 {
  /*
  double h1,h2;
  // ��������� ���������� h1,h2
  h1 = MathAbs(extrs[0].price - extrs[2].price);
  h2 = MathAbs(extrs[1].price - extrs[3].price);
    
  // ���� ����� ����� 
  if (GreatDoubles(_extrUp0.price,_extrUp1.price) && GreatDoubles(_extrDown0.price,_extrDown1.price))
   {
    // ���� ��������� ��������� - ����
    if (_extrDown0.time > _extrUp0.time)
     {
      H1 = extrs[1].price - extrs[2].price;
      H2 = extrs[3].price - extrs[2].price;
      // ���� ���� ��������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (1);
     }
   }
  // ���� ����� ����
  if (LessDoubles(_extrUp0.price,_extrUp1.price) && LessDoubles(_extrDown0.price,_extrDown1.price))
   {
    // ����  ��������� ��������� - �����
    if (_extrUp0.time > _extrDown0.time)
     {
      H1 = extrs[1].price - extrs[2].price;
      H2 = extrs[3].price - extrs[2].price;
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )    
       return (-1);
     }
   }   
   */
  return (true);
 }

CTrend::CTrend(int chartID,string symbol,ENUM_TIMEFRAMES period,CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1)
 {
  // ��������� ���� ������
  _chartID = chartID;
  _symbol = symbol;
  _period = period;
  // ������� ������� ����������� ��� ��������� �����
  _extrUp0   = new CExtremum(extrUp0.direction,extrUp0.price,extrUp0.time,extrUp0.state);
  _extrUp1   = new CExtremum(extrUp1.direction,extrUp1.price,extrUp1.time,extrUp1.state);
  _extrDown0 = new CExtremum(extrDown0.direction,extrDown0.price,extrDown0.time,extrDown0.state);
  _extrDown1 = new CExtremum(extrDown1.direction,extrDown1.price,extrDown1.time,extrDown1.state);   
  // ���������� ���������� ����� ��������� �����
  GenUniqName();   
  // ���������� ��������� �����
  ShowTrend();
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
   ENUM_TIMEFRAMES _period; // ������
   CExtrContainer *_container; // ��������� �����������
   CArrayObj _bufferTrend;// ����� ��� �������� ��������� �����  
  public:
   CTrendChannel(int chartID,string symbol,ENUM_TIMEFRAMES period,int handleDE); // ����������� ������
  ~CTrendChannel(); // ���������� ������
  // ������ ������
  CTrend * GetTrendByIndex (int index); // ���������� ��������� �� ����� �� �������
 };
 
// ����������� ������� ������ CTrendChannel
CTrendChannel::CTrendChannel(int chartID, string symbol,ENUM_TIMEFRAMES period,int handleDE)
 {
  int i;
  int extrTotal;
  int dirLastExtr;
  
  _chartID = chartID;
  _handleDE = handleDE;
  _symbol = symbol;
  _period = period;
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
        // ���� ��������� ����������� ������ - �����
        if (dirLastExtr == 1)
         {
          _bufferTrend.Add(new CTrend(_chartID, _symbol, _period,_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2),_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3) ) );
         }
        // ���� ��������� ����������� ������ - ����
        if (dirLastExtr == -1)
         {
          _bufferTrend.Add(new CTrend(_chartID, _symbol, _period,_container.GetExtrByIndex(i+1),_container.GetExtrByIndex(i+3),_container.GetExtrByIndex(i),_container.GetExtrByIndex(i+2) ) );
         }
        dirLastExtr = -dirLastExtr; 
       }
     }
   }
 }
 
// ���������� ������
CTrendChannel::~CTrendChannel()
 {
  
 }