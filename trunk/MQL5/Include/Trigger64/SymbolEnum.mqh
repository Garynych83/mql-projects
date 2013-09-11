//+------------------------------------------------------------------+
//|                                                   SymbolEnum.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ��������� ������������ ���������� �������                        |
//+------------------------------------------------------------------+
struct symbol_properties
  {
   int               digits;        // ���������� ������ � ���� ����� �������
   int               spread;        // ������ ������ � �������
   int               stops_level;   // ������������ ��������� Stop �������
   double            point;         // �������� ������ ������
   double            ask;           // ���� ask
   double            bid;           // ���� bid
   double            volume_min;    // ����������� ����� ��� ���������� ������
   double            volume_max;    // ������������ ����� ��� ���������� ������
   double            volume_limit;  // ����������� ���������� ����� ��� ������� � ������� � ����� �����������
   double            volume_step;   // ����������� ��� ��������� ������ ��� ���������� ������
   double            offset;        // ������ �� ����������� ��������� ���� ��� ��������
   double            up_level;      // ���� �������� ������ stop level
   double            down_level;    // ���� ������� ������ stop level
  };
//+------------------------------------------------------------------+
//| ������������ ������� �������                                     |
//+------------------------------------------------------------------+
enum ENUM_SYMBOL_PROPERTIES
  {
   S_DIGITS       = 0,
   S_SPREAD       = 1,
   S_STOPSLEVEL   = 2,
   S_POINT        = 3,
   S_ASK          = 4,
   S_BID          = 5,
   S_VOLUME_MIN   = 6,
   S_VOLUME_MAX   = 7,
   S_VOLUME_LIMIT = 8,
   S_VOLUME_STEP  = 9,
   S_FILTER       = 10,
   S_UP_LEVEL     = 11,
   S_DOWN_LEVEL   = 12,
   S_ALL          = 13
  };