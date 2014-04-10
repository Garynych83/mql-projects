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

// ������������ ����� ��������

enum SIGNAL_TYPE
 {
  CROSS_EMA=0  // ��� ��� ������� �� ����� ���� ��� ��������
 };
 
// ��������� �������� �������� � ���������� ������

struct sPoint
 {
  SIGNAL_TYPE signal;  // ��� �������
  int point_value;     // ���������� ������
 };

// ��������� EMA

struct sEmaParams
 {
  int    periodEMAfastEld;           // ������ ������� EMA �� �������� ����������
  int    periodEMAfastJr;            // ������ ������� EMA �� ������� ����������
  int    periodEMAslowJr;            // ������ ��������� EMA �� ������� ����������
 };
 
// ��������� MACD

struct sMacdParams
 {
  int fast_EMA_period;            // ������� ������ EMA ��� MACD
  int slow_EMA_period;            // ��������� ������ EMA ��� MACD
  int signal_period;              // ������ ���������� ����� ��� MACD 
  int applied_price;                      // ������� ������ �����������    
 };

// ��������� ���������� ����������

struct sStocParams
 {
  int kPeriod;                    // �-������ ����������
  int dPeriod;                    // D-������ ����������
  int slow;                       // ����������� ����������. ��������� �������� �� 1 �� 3.
  int top_level;                  // Top-level ���������
  int bottom_level;               // Bottom-level ����������
  int allow_depth_for_price_extr; // ���������� ������� ��� ���������� ����
  int depth;                      // ������� ������ �����������    
 };
 
// ��������� ���������� PriceBasedIndicator
struct sPbiParams
 {
  int historyDepth;                            // ������� ������� ��� �������
  int bars;                                    // ������� ������ ����������
 };
// ��������� ������
struct sDealParams
 {
  double orderVolume;                          // ����� ������
  int slOrder;                                 // Stop Loss
  int tpOrder;                                 // Take Profit
  int trStop;                                  // Trailing Stop
  int trStep;                                  // Trailing Step
  int minProfit;                               // Minimal Profit 
 };
 
// ��������� ������� ��������
struct sBaseParams
 {
  ENUM_TIMEFRAMES eldTF;             //
  ENUM_TIMEFRAMES jrTF;              //
  bool useJrEMAExit;               // ����� �� �������� �� ���
  int posLifeTime;                // ����� �������� ������ � �����
  int deltaPriceToEMA;            // ���������� ������� ����� ����� � EMA ��� �����������
  int deltaEMAtoEMA;              // ����������� ������� ��� ��������� EMA
  int waitAfterDiv;               // �������� ������ ����� ����������� (� �����)
 };