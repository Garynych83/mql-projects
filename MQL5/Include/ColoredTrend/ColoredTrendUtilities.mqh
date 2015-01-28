      //+------------------------------------------------------------------+
//|                                        ColoredTrendUtilities.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

//+-----------------------------------+
//|  ���������                        |
//+-----------------------------------+
#define AMOUNT_OF_PRICE 2           // ���������� ����� � ������� ��� ����� ����� ����. ��� ���������� ���� �������� ��� ��������� ���� � �������� � ���������� ����.
#define AMOUNT_BARS_FOR_HUGE 100    // ���������� ����� �� ������� ��������� ������� ��� �� ������� ����������
#define DEFAULT_DIFF_TO_TREND 1.5   // �������� ���������� ����� �������� �� ���������
#define FACTOR_OF_SUPERIORITY 2     // �� ������� ��� ��� ������ ���� ������ �������� ����� ���� �������

//+-----------------------------------+
//|  ���������� ������������          |
//+-----------------------------------+
enum ENUM_TF
  {
   BOTTOM_TF,
   CURRENT_TF,
   TOP_TF
  };
  
enum ENUM_MOVE_TYPE      // ��� ��������
  {
   MOVE_TYPE_UNKNOWN = 0,
   MOVE_TYPE_TREND_UP,            // ����� ����� - �����
   MOVE_TYPE_TREND_UP_FORBIDEN,   // ����� �����, ����������� ������� �� - ����������
   MOVE_TYPE_TREND_DOWN,          // ����� ���� - �������
   MOVE_TYPE_TREND_DOWN_FORBIDEN, // ����� ����, ����������� ������� �� - ����������
   MOVE_TYPE_CORRECTION_UP,       // ��������� �����, �������������� ����� ���� - �������
   MOVE_TYPE_CORRECTION_DOWN,     // ��������� ����, �������������� ����� ����� - �������
   MOVE_TYPE_FLAT,                // ���� - ������
  };
  
string MoveTypeToString(ENUM_MOVE_TYPE enumMoveType)
  {
   switch(enumMoveType)
     {
      case MOVE_TYPE_UNKNOWN: return("NULL");
      case MOVE_TYPE_TREND_UP: return("TREND UP");
      case MOVE_TYPE_TREND_UP_FORBIDEN: return("TREND UP FORB");
      case MOVE_TYPE_TREND_DOWN: return("TREND DOWN");
      case MOVE_TYPE_TREND_DOWN_FORBIDEN: return("TREND DOWN FORB");
      case MOVE_TYPE_CORRECTION_UP: return("CORRECTION UP");
      case MOVE_TYPE_CORRECTION_DOWN: return("CORRECTION DOWN");
      case MOVE_TYPE_FLAT: return("FLAT");
      default: return("Error: unknown move type"+(string)enumMoveType);
     }
  }
  
string MoveTypeToColor(ENUM_MOVE_TYPE enumMoveType)
  {
   switch(enumMoveType)
     {
      case MOVE_TYPE_UNKNOWN: return("���� �� ���������");
      case MOVE_TYPE_TREND_UP: return("�����");
      case MOVE_TYPE_TREND_UP_FORBIDEN: return("����������");
      case MOVE_TYPE_TREND_DOWN: return("�������");
      case MOVE_TYPE_TREND_DOWN_FORBIDEN: return("����������");
      case MOVE_TYPE_CORRECTION_UP: return("�������");
      case MOVE_TYPE_CORRECTION_DOWN: return("�������");
      case MOVE_TYPE_FLAT: return("������");
      default: return("Error: unknown move type"+(string)enumMoveType);
     }
  }

ENUM_TIMEFRAMES GetTopTimeframe(ENUM_TIMEFRAMES timeframe)
{
 switch(timeframe)
 {
      case PERIOD_M1: return(PERIOD_M5);
      case PERIOD_M2: return(PERIOD_M5);
      case PERIOD_M3: return(PERIOD_M15);
      case PERIOD_M4: return(PERIOD_M15);
      case PERIOD_M5: return(PERIOD_M15);
      case PERIOD_M6: return(PERIOD_M15);
      case PERIOD_M10: return(PERIOD_H1);
      case PERIOD_M12: return(PERIOD_H1);
      case PERIOD_M15: return(PERIOD_H1);
      case PERIOD_M20: return(PERIOD_H1);
      case PERIOD_M30: return(PERIOD_H4);
      case PERIOD_H1: return(PERIOD_H4);
      case PERIOD_H2: return(PERIOD_D1);
      case PERIOD_H3: return(PERIOD_D1);
      case PERIOD_H4: return(PERIOD_D1);
      case PERIOD_H6: return(PERIOD_D1);
      case PERIOD_H8: return(PERIOD_D1);
      case PERIOD_D1: return(PERIOD_W1);
      case PERIOD_W1: return(PERIOD_MN1);
      case PERIOD_MN1: return(PERIOD_MN1);
      default: 
      {
       Alert(StringFormat("Error: unknown period %s", (string)timeframe));
       return(PERIOD_MN1);
      }
 }
}

ENUM_TIMEFRAMES GetBottomTimeframe(ENUM_TIMEFRAMES timeframe)
{
 switch(timeframe)
 {
      case PERIOD_M1: return(PERIOD_M1);
      case PERIOD_M2: return(PERIOD_M1);
      case PERIOD_M3: return(PERIOD_M1);
      case PERIOD_M4: return(PERIOD_M1);
      case PERIOD_M5: return(PERIOD_M1);
      case PERIOD_M6: return(PERIOD_M1);
      case PERIOD_M10: return(PERIOD_M1);
      case PERIOD_M12: return(PERIOD_M1);
      case PERIOD_M15: return(PERIOD_M5);
      case PERIOD_M20: return(PERIOD_M5);
      case PERIOD_M30: return(PERIOD_M5);
      case PERIOD_H1: return(PERIOD_M15);
      case PERIOD_H2: return(PERIOD_M15);
      case PERIOD_H3: return(PERIOD_M15);
      case PERIOD_H4: return(PERIOD_H1);
      case PERIOD_H6: return(PERIOD_H1);
      case PERIOD_H8: return(PERIOD_H1);
      case PERIOD_D1: return(PERIOD_H4);
      case PERIOD_W1: return(PERIOD_D1);
      case PERIOD_MN1: return(PERIOD_W1);
      default: 
      {
       Alert(StringFormat("Error: unknown period %s", (string)timeframe));
       return(PERIOD_M1);
      }
 }
}

int GetMaPeriodForATR(ENUM_TIMEFRAMES timeframe)
{
 switch(timeframe)
 {
      case PERIOD_M1: return(100);
      case PERIOD_M2: return(100);
      case PERIOD_M3: return(100);
      case PERIOD_M4: return(100);
      case PERIOD_M5: return(100);
      case PERIOD_M6: return(100);
      case PERIOD_M10: return(15);
      case PERIOD_M12: return(15);
      case PERIOD_M15: return(15);
      case PERIOD_M20: return(15);
      case PERIOD_M30: return(12);
      case PERIOD_H1: return(12);
      case PERIOD_H2: return(12);
      case PERIOD_H3: return(12);
      case PERIOD_H4: return(12);
      case PERIOD_H6: return(10);
      case PERIOD_H8: return(10);
      case PERIOD_D1: return(10);
      case PERIOD_W1: return(8);
      case PERIOD_MN1: return(8);
      default: 
      {
       Alert(StringFormat("Error: unknown period %s", (string)timeframe));
       return(100);
      }
 }
}


double SetDiffToTrend(ENUM_TIMEFRAMES period)
{
 switch(period)
 {
   case(PERIOD_M5):
      return (1.5);     
   case(PERIOD_M15):
      return (1.3);
   case(PERIOD_H1):
      return (1.3);
   case(PERIOD_H4):
      return (1.3);
   case(PERIOD_D1):
      return (0.8);
   case(PERIOD_W1):
      return (0.8);
   case(PERIOD_MN1):
      return (0.8);
 }
 return (DEFAULT_DIFF_TO_TREND);
}