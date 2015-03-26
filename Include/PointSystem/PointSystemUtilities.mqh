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
  int handleEMA3;   
  int handleEMAfast;           // ������ ������� EMA �� �������� ����������
  int handleEMAfastJr;            // ������ ������� EMA �� ������� ����������
  int handleEMAslowJr;            // ������ ��������� EMA �� ������� ����������
 };
 
// ��������� MACD

struct sMacdParams
 {
  int handleMACD;
 };

// ��������� ���������� ����������

struct sStocParams
 {
  int handleStochastic;
  int top_level;                  // Top-level ���������
  int bottom_level;               // Bottom-level ����������
 };
 
// ��������� ���������� PriceBasedIndicator
struct sPbiParams
 {
  int handlePBI;
  int historyDepth;                            // ������� ������� ��� �������
 };
// ��������� ������
struct sDealParams
 {
  double orderVolume;                          // ����� ������
  int sl;                                 // Stop Loss
  int tp;                                 // Take Profit
  int trStop;                                  // Trailing Stop
  int trStep;                                  // Trailing Step
  int minProfit;                               // Minimal Profit 
 };
 
// ��������� ������� ��������
struct sBaseParams
 {
  ENUM_TIMEFRAMES eldTF;             //
  ENUM_TIMEFRAMES curTF;          // 
  ENUM_TIMEFRAMES jrTF;              //
  bool useJrEMAExit;               // ����� �� �������� �� ���
  int posLifeTime;                // ����� �������� ������ � �����
  int deltaPriceToEMA;            // ���������� ������� ����� ����� � EMA ��� �����������
  int deltaEMAtoEMA;              // ����������� ������� ��� ��������� EMA
  int waitAfterDiv;               // �������� ������ ����� ����������� (� �����)
 };