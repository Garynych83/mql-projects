//+------------------------------------------------------------------+
//|                                                 ExtremumSTOC.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"


#include <Object.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CExtremumSTOC: public CObject
{
private:

public:
 CExtremumSTOC();
 ~CExtremumSTOC();
 CExtremumSTOC(int direction, int index, double value, datetime time);
                     
 int direction;                      // ����������� ����������: 1 - max; -1 -min; 0 - null
 double value;                       // �������� ����������: ��� max - high; ��� min - low
 int index;                          // ������ ���������� ������������ ��������� ���������
 datetime time;                      // ����� ���� �� ������� ��������� ���������
};
                    
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtremumSTOC::CExtremumSTOC(int _direction, int _index, double _value, datetime _time)
                            : direction(_direction), index(_index), value(_value), time(_time)
{
}
CExtremumSTOC::CExtremumSTOC()
{
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtremumSTOC::~CExtremumSTOC()
{
}
//+------------------------------------------------------------------+
