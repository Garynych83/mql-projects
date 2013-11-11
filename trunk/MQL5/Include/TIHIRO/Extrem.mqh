//+------------------------------------------------------------------+
//|                                                       Extrem.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| �������������� ���������� ��� ������ CTihiro                     |
//+------------------------------------------------------------------+

//��������� 
#define UNKNOWN    0
#define BUY        1
#define SELL       2
#define TREND_UP   3
#define TREND_DOWN 4
#define NOTREND    5

//����� �����������
 class Extrem
  {
   public:
   datetime time;   //��������� ��������� ����������
   double price;    //������� ��������� ����������
   void SetExtrem(datetime t,double p){ time=t; price=p; }; //��������� ���������
   Extrem(datetime t=0,double p=0):time(t),price(p){};      //�����������
  };