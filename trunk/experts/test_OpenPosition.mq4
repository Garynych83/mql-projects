//+----------------------------------------------------------------------------+
//|                                                     test_OpenPosition.mq4  |
//|                                                                            |
//|                                                                            |
//|  17.03.2008  ������ ��� ������������ ������� OpenPosition().               |
//+----------------------------------------------------------------------------+
#property copyright "��� ����� �. aka KimIV"
#property link  "http://www.kimiv.ru"
#property show_confirm

//------- ���������� ���������� -----------------------------------------------+
//bool   gbDisabled    = False;          // ���� ���������� ���������
//color  clOpenBuy     = LightBlue;      // ���� ������ �������� �������
//color  clOpenSell    = LightCoral;     // ���� ������ �������� �������
//int    Slippage      = 3;              // ��������������� ����
//int    NumberOfTry   = 5;              // ���������� �������� �������
//bool   UseSound      = True;           // ������������ �������� ������
//string NameFileSound = "expert.wav";   // ������������ ��������� �����

//------- ����������� ������� ������� -----------------------------------------+
#include <stdlib.mqh>                  // ����������� ����������
#include <BasicVariables.mqh>
#include <DesepticonVariables.mqh>    // �������� ���������� 
#include <AddOnFuctions.mqh> 
#include <DesepticonOpening.mqh>
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // �� ����� ���������� ����� �����������

void start() {
  double pa, pb, po;
  string sy;
  openPlace = "test opening";
  int timeframe = PERIOD_H1;
//1. ������ 0.1 ���� �������� �����������
//  OpenPosition(NULL, OP_BUY, 0.1);

//2. ������� 2 ���� EURUSD
//  sy="EURUSD";
//  pa=MarketInfo("EURUSD", MODE_ASK);
//  pb=MarketInfo("EURUSD", MODE_BID);
//  po=MarketInfo("EURUSD", MODE_POINT);
//  OpenPositionTest(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber);

//3. ������� 0.12 ���� USDCAD �� ������ 20 �������
//  sy="USDCAD";
//  pa=MarketInfo("USDCAD", MODE_ASK);
//  pb=MarketInfo("USDCAD", MODE_BID);
//  po=MarketInfo("USDCAD", MODE_POINT);
//  OpenPosition("USDCAD", OP_SELL, 0.12, pb+20*po);

//4. ������ 0.15 ���� USDJPY � ������ 40 �������
//  sy="USDJPY";
//  pa=MarketInfo("USDJPY", MODE_ASK);
//  pb=MarketInfo("USDJPY", MODE_BID);
//  po=MarketInfo("USDJPY", MODE_POINT);
//  OpenPosition("USDJPY", OP_BUY, 0.15, 0, pa+40*po);

//5. ������� 0.1 ���� GBPJPY �� ������ 23 � ������ 44 ������
//  sy="GBPJPY";
//  pa=MarketInfo("GBPJPY", MODE_ASK);
//  pb=MarketInfo("GBPJPY", MODE_BID);
//  po=MarketInfo("GBPJPY", MODE_POINT);
//  OpenPosition("GBPJPY", OP_SELL, 0.1, pb+23*po, pb-44*po);
}


