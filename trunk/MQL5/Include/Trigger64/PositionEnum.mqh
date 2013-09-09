//+------------------------------------------------------------------+
//|                                                 PositionEnum.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//���������� ������������ ����������� �������
struct position_properties
  {
   uint              total_deals;      // ���������� ������
   bool              exists;           // ������� �������/���������� �������� �������
   string            symbol;           // ������
   long              magic;            // ���������� �����
   string            comment;          // �����������
   double            swap;             // ����
   double            commission;       // ��������   
   double            first_deal_price; // ���� ������ ������ �������
   double            price;            // ������� ���� �������
   double            current_price;    // ������� ���� ������� �������      
   double            last_deal_price;  // ���� ��������� ������ �������
   double            profit;           // �������/������ �������
   double            volume;           // ������� ����� �������
   double            initial_volume;   // ��������� ����� �������
   double            sl;               // Stop Loss �������
   double            tp;               // Take Profit �������
   datetime          time;             // ����� �������� �������
   ulong             duration;         // ������������ ������� � ��������
   long              id;               // ������������� �������
   ENUM_POSITION_TYPE type;            // T�� �������
  };
  //--- ������������ ������� �������
enum ENUM_POSITION_PROPERTIES
  {
   P_TOTAL_DEALS     = 0,
   P_SYMBOL          = 1,
   P_MAGIC           = 2,
   P_COMMENT         = 3,
   P_SWAP            = 4,
   P_COMMISSION      = 5,
   P_PRICE_FIRST_DEAL= 6,
   P_PRICE_OPEN      = 7,
   P_PRICE_CURRENT   = 8,
   P_PRICE_LAST_DEAL = 9,
   P_PROFIT          = 10,
   P_VOLUME          = 11,
   P_INITIAL_VOLUME  = 12,
   P_SL              = 13,
   P_TP              = 14,
   P_TIME            = 15,
   P_DURATION        = 16,
   P_ID              = 17,
   P_TYPE            = 18,
   P_ALL             = 19
  };
  //--- ������������ �������
enum ENUM_POSITION_DURATION
  {
   DAYS     = 0, // ���
   HOURS    = 1, // ����
   MINUTES  = 2, // ������
   SECONDS  = 3  // �������
  };
  
