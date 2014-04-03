//+------------------------------------------------------------------+
//|                                                      STRUCTS.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ���������� �������� ������ ��� ��������� ��������                |
//+------------------------------------------------------------------+

// ��������� EMA

struct EMA_PARAMS
 {
 
 };
 
// ��������� MACD

struct MACD_PARAMS
 {
  int    fast_EMA_period;            // ������� ������ EMA ��� MACD
  int    slow_EMA_period;            // ��������� ������ EMA ��� MACD
  int    signal_period;              // ������ ���������� ����� ��� MACD 
 };

// ��������� ���������� ����������

struct STOC_PARAMS
 {
  int    kPeriod;                    // �-������ ����������
  int    dPeriod;                    // D-������ ����������
  int    slow;                       // ����������� ����������. ��������� �������� �� 1 �� 3.
  int    top_level;                  // Top-level ���������
  int    bottom_level;               // Bottom-level ����������
  int    DEPTH;                      // ������� ������ �����������
  int    ALLOW_DEPTH_FOR_PRICE_EXTR; // ���������� ������� ��� ���������� ����
 };
 
// ��������� ���������� PriceBasedIndicator
struct PBI_PARAMS
 {
  int    historyDepth;               // ������� ������� ��� �������
  int    bars;                       // ������� ������ ����������
 };
// ��������� ������
struct DEAL_PARAMS
 {
  double orderVolume;                // ����� ������
  int    slOrder;                    // Stop Loss
  int    tpOrder;                    // Take Profit
  int    trStop;                     // Trailing Stop
  int    trStep;                     // Trailing Step
  int    minProfit;                  // Minimal Profit 
  bool   useLimitOrders;             // ������������ Limit ������
  int    limitPriceDifference;       // ������� ��� Limit �������
  bool   useStopOrders;              // ������������ Stop ������
  int    stopPriceDifference;        // ������� ��� Stop ������� 
 };
 
// ��������� ������� ��������
struct BASE_PARAMS
 {
  ENUM_TIMEFRAMES eldTF;             //
  ENUM_TIMEFRAMES jrTF;              //
  bool   useJrEMAExit;               // ����� �� �������� �� ���
  int    posLifeTime;                // ����� �������� ������ � �����
  int    deltaPriceToEMA;            // ���������� ������� ����� ����� � EMA ��� �����������
  int    deltaEMAtoEMA;              // ����������� ������� ��� ��������� EMA
  int    waitAfterDiv;               // �������� ������ ����� ����������� (� �����)
 };