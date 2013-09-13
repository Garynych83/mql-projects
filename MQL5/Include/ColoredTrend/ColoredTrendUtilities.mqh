//+------------------------------------------------------------------+
//|                                            ColoredTrendEnums.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

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
      case MOVE_TYPE_UNKNOWN: return("�������� �� ����������");
      case MOVE_TYPE_TREND_UP: return("����� �����");
      case MOVE_TYPE_TREND_UP_FORBIDEN: return("����� ����� �������� �� �������� ��");
      case MOVE_TYPE_TREND_DOWN: return("����� ����");
      case MOVE_TYPE_TREND_DOWN_FORBIDEN: return("����� ���� �������� �� �������� ��");
      case MOVE_TYPE_CORRECTION_UP: return("��������� �����");
      case MOVE_TYPE_CORRECTION_DOWN: return("��������� ����");
      case MOVE_TYPE_FLAT: return("����");
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
      default: return("Error: unknown period "+(string)timeframe);
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
      default: return("Error: unknown period "+(string)timeframe);
 }
}