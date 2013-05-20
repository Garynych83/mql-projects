//+------------------------------------------------------------------+
//|                                           fast-start-example.mq5 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert includes                                                  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>                                         //���������� ���������� ��� ���������� �������� ��������
#include <Trade\PositionInfo.mqh>                                  //���������� ���������� ��� ��������� ���������� � ��������
#include <CisNewBar.mqh>                                    //���������� ���������� ��� ��������� ���������� � ��������� ������ ����

//+------------------------------------------------------------------+
//| Expert variables                                                 |
//+------------------------------------------------------------------+
input int jrEMA = 12;
input int eldEMA = 26;

int               iMA_jr_handle;                                      //���������� ��� �������� ������ ����������
double            iMA_jr_buf[];                                       //������������ ������ ��� �������� �������� ����������
double            Close_jr_buf[];                                     //������������ ������ ��� �������� ���� �������� ������� ���� �������� ��

int               iMA_eld_handle;                                      //���������� ��� �������� ������ ����������
double            iMA_eld_buf[];                                       //������������ ������ ��� �������� �������� ����������
double            Close_eld_buf[];                                     //������������ ������ ��� �������� ���� �������� ������� ���� �������� ��

string            my_symbol;                                       //���������� ��� �������� �������
ENUM_TIMEFRAMES   my_jr_timeframe;                                    //���������� ��� �������� �������� ����������
ENUM_TIMEFRAMES   my_eld_timeframe;                                    //���������� ��� �������� �������� ����������

CTrade            m_Trade;                                         //��������� ��� ���������� �������� ��������
CPositionInfo     m_Position;                                      //��������� ��� ��������� ���������� � ��������
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   my_symbol=Symbol();                                             //�������� ������� ������ ������� ��� ���������� ������ ��������� ������ �� ���� �������
   my_jr_timeframe=PERIOD_M5;                                    
   my_eld_timeframe=PERIOD_H1;                                    
   iMA_jr_handle=iMA(my_symbol,my_jr_timeframe,12,0,MODE_SMA,PRICE_CLOSE);  //���������� ��������� � �������� ��� �����
   if(iMA_jr_handle==INVALID_HANDLE)                                  //��������� ������� ������ ����������
   {
      Print("�� ������� �������� ����� ����������");               //���� ����� �� �������, �� ������� ��������� � ��� �� ������
      return(-1);                                                  //��������� ������ � �������
   }
   
   iMA_eld_handle=iMA(my_symbol,my_jr_timeframe,26,0,MODE_SMA,PRICE_CLOSE);  //���������� ��������� � �������� ��� �����
   if(iMA_eld_handle==INVALID_HANDLE)                                  //��������� ������� ������ ����������
   {
      Print("�� ������� �������� ����� ����������");               //���� ����� �� �������, �� ������� ��������� � ��� �� ������
      return(-1);                                                  //��������� ������ � �������
   }
   //ChartIndicatorAdd(ChartID(),0,iMA_handle);                      //��������� ��������� �� ������� ������
   ArraySetAsSeries(iMA_jr_buf,true);                                 //������������� ���������� ��� ������� iMA_buf ��� � ���������
   ArraySetAsSeries(iMA_eld_buf,true);                                 //������������� ���������� ��� ������� iMA_buf ��� � ���������
   ArraySetAsSeries(Close_jr_buf,true);                               //������������� ���������� ��� ������� Close_buf ��� � ���������
   ArraySetAsSeries(Close_eld_buf,true);                               //������������� ���������� ��� ������� Close_buf ��� � ���������
   return(0);                                                      //���������� 0, ������������� ���������
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(iMA_jr_handle);                                   //������� ����� ���������� � ����������� ������ ���������� ��
   ArrayFree(iMA_jr_buf);                                             //����������� ������������ ������ iMA_buf �� ������
   IndicatorRelease(iMA_eld_handle);                                   //������� ����� ���������� � ����������� ������ ���������� ��
   ArrayFree(iMA_eld_buf);                                             //����������� ������������ ������ iMA_buf �� ������
   ArrayFree(Close_jr_buf);                                           //����������� ������������ ������ Close_buf �� ������
   ArrayFree(Close_eld_buf);                                           //����������� ������������ ������ Close_buf �� ������
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int err1=0;                                                     //���������� ��� �������� ����������� ������ � ������� ����������
   int err2=0;                                                     //���������� ��� �������� ����������� ������ � ������� ��������

   static CIsNewBar isNewBarEld;
   static CIsNewBar isNewBarJr;
   if(isNewBarEld.isNewBar(my_symbol, my_eld_timeframe))
   {
    err1=CopyBuffer(iMA_eld_handle,0,1,2,iMA_eld_buf);                      //�������� ������ �� ������������� ������� � ������������ ������ iMA_buf ��� ���������� ������ � ����
    err2=CopyClose(my_symbol,my_eld_timeframe,1,2,Close_eld_buf);           //�������� ������ �������� ������� � ������������ ������ Close_buf  ��� ���������� ������ � ����
    if(err1<0 || err2<0)                                            //���� ���� ������
    {
     Print("�� ������� ����������� ������ �� ������������� ������ ��� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
     return;                                                                                      //� ������� �� �������
    }
   }
   
   if(isNewBarJr.isNewBar(my_symbol, my_jr_timeframe))
   {
    err1=CopyBuffer(iMA_jr_handle,0,1,2,iMA_jr_buf);                      //�������� ������ �� ������������� ������� � ������������ ������ iMA_buf ��� ���������� ������ � ����
    err2=CopyClose(my_symbol,my_jr_timeframe,1,2,Close_jr_buf);           //�������� ������ �������� ������� � ������������ ������ Close_buf  ��� ���������� ������ � ����
    if(err1<0 || err2<0)                                            //���� ���� ������
    {
     Print("�� ������� ����������� ������ �� ������������� ������ ��� ������ �������� �������");  //�� ������� ��������� � ��� �� ������
     return;                                                                                      //� ������� �� �������
    }
   
    if(iMA_jr_buf[1]>Close_jr_buf[1] && iMA_jr_buf[0]<Close_jr_buf[0])          //���� �������� ���������� ���� ������ ���� �������� � ����� ������
    {
     if(m_Position.Select(my_symbol))                             //���� ��� ���������� ������� �� ����� �������
      {
       if(m_Position.PositionType()==POSITION_TYPE_SELL) m_Trade.PositionClose(my_symbol);  //� ��� ���� ������� Sell, �� ��������� ��
       if(m_Position.PositionType()==POSITION_TYPE_BUY) return;                             //� ���� ��� ���� ������� Buy, �� �������
      }
     m_Trade.Buy(1,my_symbol);                                  //���� ����� ����, ������ ������� ���, ��������� ��
    }
   if(iMA_jr_buf[1]<Close_jr_buf[1] && iMA_jr_buf[0]>Close_jr_buf[0])          //���� �������� ���������� ���� ������ ���� �������� � ����� ������
    {
     if(m_Position.Select(my_symbol))                             //���� ��� ���������� ������� �� ����� �������
      {
       if(m_Position.PositionType()==POSITION_TYPE_BUY) m_Trade.PositionClose(my_symbol);   //� ��� ���� ������� Buy, �� ��������� ��
       if(m_Position.PositionType()==POSITION_TYPE_SELL) return;                            //� ���� ��� ���� ������� Sell, �� �������
      }
     m_Trade.Sell(1,my_symbol);                                 //���� ����� ����, ������ ������� ���, ��������� ��
    }
   }
  }
