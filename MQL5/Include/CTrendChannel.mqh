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
   CTrend(CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1); // ����������� ������ �� �����
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
  
 }
 
bool CTrend::IsItTrend(void) // ���������, �������� �� ������ ����� ���������
 {
  return (true);
 }

CTrend::CTrend(CExtremum *extrUp0,CExtremum *extrUp1,CExtremum *extrDown0,CExtremum *extrDown1)
 {
  // ������� ������� ����������� ��� ��������� �����
  _extrUp0 = new CExtremum(extrUp0.direction,extrUp0.price,extrUp0.time,extrUp0.state);
  _extrUp1 = new CExtremum(extrUp1.direction,extrUp1.price,extrUp1.time,extrUp1.state);
  _extrDown0 = new CExtremum(extrDown0.direction,extrDown0.price,extrDown0.time,extrDown0.state);
  _extrDown1 = new CExtremum(extrDown1.direction,extrDown1.price,extrDown1.time,extrDown1.state);      
 }

void CTrend::ShowTrend(void) // ���������� ����� �� �������
 {
  //_trendLine.Create(0,"trendUp_"+_uniqName,0,extrs[2].time,extrs[2].price,extr[0].time,extrs[0].price); // �������  �����
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
   CTrendChannel(string symbol,ENUM_TIMEFRAMES period,int handleDE); // ����������� ������
  ~CTrendChannel(); // ���������� ������
  // ������ ������
  CTrend * GetTrendByIndex (int index); // ���������� ��������� �� ����� �� �������
 };
 
// ����������� ������� ������ CTrendChannel
CTrendChannel::CTrendChannel(string symbol,ENUM_TIMEFRAMES period,int handleDE)
 {
  int i;
  int extrTotal; 
  int dirLastExtr;
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
      dirLastExtr = _container.GetLastFormedExtr(EXTR_BOTH).direction;
      // �������� �� ����������� � ��������� ����� �������
      for (i=0;i<extrTotal-4;i++)
       {
      //  _bufferTrend.Add(new CTrend(_container.GetExtrByIndex(i)
       }
     }
   }
 }