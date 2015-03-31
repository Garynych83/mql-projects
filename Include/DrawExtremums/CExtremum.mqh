//+------------------------------------------------------------------+
//|                                                  CExtremumNew.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Object.mqh>

enum STATE_OF_EXTR
{
 EXTR_FORMING = 0,
 EXTR_FORMED,
 EXTR_NO_TYPE        //�� ���� ����� �� ���������
};

class CExtremum : public CObject
{
 private:

 public:
 int direction;                      // ����������� ����������: 1 - max; -1 -min; 0 - null
 double price;                       // ���� ����������: ��� max - high; ��� min - low
 datetime time;                      // ����� ���� �� ������� ��������� ���������
 STATE_OF_EXTR state;                // ������ ���������� ���� ������������ STATE_OF_EXTR (��������������/��������������)
                     CExtremum();
                     CExtremum(int direction, double price, datetime time = 0, STATE_OF_EXTR state = EXTR_NO_TYPE);
                    ~CExtremum();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtremum::CExtremum()
{
}
CExtremum::CExtremum(int _direction, double _price, datetime _time = 0, STATE_OF_EXTR _state = EXTR_NO_TYPE)
{
 direction = _direction;
 price     = _price;
 time      = _time;
 state     = _state;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CExtremum::~CExtremum()
{
}
//+------------------------------------------------------------------+
