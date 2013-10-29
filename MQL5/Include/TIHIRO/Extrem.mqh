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
#define UNKNOWN 0
#define BUY 1
#define SELL 2

//������������ �������
enum  TIHIRO_MODE
 {
  TM_WAIT_FOR_CROSS=0, //����� �������� �������� ���� �� ������ ������
  TM_REACH_THE_RANGE   //����� �������� �� Range
 };
//����� �����������
 class Extrem
  {
   public:
   datetime time;   //��������� ��������� ����������
   double price;  //������� ��������� ����������
   void SetExtrem(datetime t,double p){ time=t; price=p; }; //��������� ���������
  };