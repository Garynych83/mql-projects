//+------------------------------------------------------------------+
//|                                                CExtremumMACD.mqh |
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
class CExtremumMACD : public CObject
{
private:

public:
 CExtremumMACD(){};
 ~CExtremumMACD(){};
 CExtremumMACD(int direction, int index, double value, datetime time);
                     
 int direction;                      // ����������� ����������: 1 - max; -1 -min; 0 - null
 double value;                       // �������� ����������: ��� max - high; ��� min - low
 int index;                          // ������ ���������� ������������ ��������� ���������
 datetime time;                      // ����� ���� �� ������� ��������� ���������
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtremumMACD::CExtremumMACD(int direction, int index, double value, datetime time)
                            : direction(direction), index(index), value(value), time(time)
  {
  }
