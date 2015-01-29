//+------------------------------------------------------------------+
//|                                                    SExtremum.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| �������� ��������� ��� �������� �����������                      |
//+------------------------------------------------------------------+

struct SExtremum
{
 int direction;                      // ����������� ����������: 1 - max; -1 -min; 0 - null
 double price;                       // ���� ����������: ��� max - high; ��� min - low
 datetime time;                      // ����� ���� �� ������� ��������� ���������
}; 