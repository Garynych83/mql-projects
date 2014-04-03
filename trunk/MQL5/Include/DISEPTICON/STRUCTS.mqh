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

// ��������� ������
struct DEAL_PARAMS
 {
  double orderVolume = 0.1;         // ����� ������
  int    slOrder = 100;             // Stop Loss
  int    tpOrder = 100;             // Take Profit
  int    trStop = 100;              // Trailing Stop
  int    trStep = 100;              // Trailing Step
  int    minProfit = 250;           // Minimal Profit 
  bool   useLimitOrders = false;    // ������������ Limit ������
  int    limitPriceDifference = 50; // ������� ��� Limit �������
  bool   useStopOrders = false;     // ������������ Stop ������
  int    stopPriceDifference = 50;  // ������� ��� Stop ������� 
 };