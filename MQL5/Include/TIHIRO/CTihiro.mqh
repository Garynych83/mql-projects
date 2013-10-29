//+------------------------------------------------------------------+
//|                                                      CTihiro.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Extrem.mqh" 

//+------------------------------------------------------------------+
//| ����� ��� �������� TIHIRO                                        |
//+------------------------------------------------------------------+

class CTihiro 
 {
    //��������� ���� ������
   private:
    //����� 
    TIHIRO_MODE _mode;
    //���������� ����� �������
    uint   _bars;  
    //������� ����� ������
    double _tg;
    //���������� �� ����� ������ �� ���������� ����������
    double _range;
    //����, �� ������� ���� ������� �������
    double _open_price;
    //��������� ����������
    Extrem _extr_past;
    //��������� �����������
    Extrem _extr_present;
    //��������� ���������
    Extrem _extr_last;
    //��������� ������ ������
   private:
    //�������� �������� �������� ���� ������� ����� ������   
    void    GetTan();  
    //���������� ���������� �� ���������� �� ����� ������
    void    GetRange();
    //���������, ���� ��� ���� ����� ������ ��������� ������� �����
    short   TestPointLocate(datetime cur_time,double cur_price);
    //���������, ��� ���� ����� �� ����� ������
    short   TestCrossTrendLine(string symbol);
    //���������, ��� ���� ����� �� ���� range
    short   TestReachRange(string symbol);
   public:
   //����������� ������ 
   CTihiro(uint bars):
     _mode(TM_WAIT_FOR_CROSS),
     _bars(bars)
    {
    
    }; 
   //�������� �� �������� ��������� �� ������� ������������ � ����������� ��� �����
   //� ��������� ��� ����������� �������� �� ���
   //� ������ - ����������, ������� ��������� �����, ���������� �� ����� ������ �� ���������� ���������� 
   void   OnNewBar(double  &price_max[],double  &price_min[]);
   //�� ������ ���� ���������, ������� �� ���� �� ����� �����  
   //���������� �������� ������ 
   //0 - UNKNOWN, 1 - BUY, 2 - SELL
   short  OnTick(string symbol);
 };

//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+

void CTihiro::GetTan() 
//�������� �������� �������� ���� ������� ����� ������
 {
  _tg =  (_extr_present.price-_extr_past.price)/(_extr_present.time - _extr_past.time);
 }
 
void CTihiro::GetRange()
//��������� ���������� �� ���������� �� ����� ������
 {
  datetime L=_extr_present.time-_extr_past.time;  
  double H=_extr_present.price-_extr_past.price;
  _range=H-_tg*L;
 }
 
short CTihiro::TestPointLocate(datetime cur_time,double cur_price)
//���������, ���� ��� ���� ����� ������ ��������� ������� �����
 {
   double line_level=_extr_past.price+(cur_time-_extr_past.time)*_tg;  //��������  ����� ������ � ������ ����� 
   if (cur_price>line_level)
    return 1;  //����� ��������� ���� ����� ������
   if (cur_price<line_level)
    return -1; //����� ��������� ���� ����� ������
   return 0;   //����� ��������� �� ����� ������
 }
 
short CTihiro::TestCrossTrendLine(string symbol)
//���������, ��� ���� ����� �� ����� ������ 
 {
 datetime time;   //������� �����
 double   price;  //������� ����
  //���� ����� ���������� 
 if (_tg > 0) 
   {
    //��������� ������� �����
    time = TimeCurrent();
    //��������� ���� BID, ��� ������
    price = SymbolInfoDouble(symbol,SYMBOL_BID);
    //���� ���� ���������� �� ����� ������
    if (TestPointLocate(time,price)<=0)
     {
      //��������� � ����� �������� ���������� ������ range
      _mode = TM_REACH_THE_RANGE;
      return SELL;
     }
   }
  //���� ����� ����������
  if (_tg < 0) 
   {
    //��������� ������� �����
    time = TimeCurrent();   
    //��������� ���� ASK, ��� �������
    price = SymbolInfoDouble(symbol,SYMBOL_ASK);
    //���� ���� ���������� �� ����� ������
    if (TestPointLocate(time,price)>=0)
     {
      //��������� � ����� �������� ���������� ������ range
      _mode = TM_REACH_THE_RANGE;     
      return BUY;
     }    
   }  
  return UNKNOWN;  
 }
  
short CTihiro::TestReachRange(string symbol)
//���������, ��� ���� ����� �� ���� range
 {
  double cur_price;
  double abs;
  //���� ����� ����������
  if (_tg > 0)
   {
     cur_price = SymbolInfoDouble(symbol,SYMBOL_BID);
     abs=_open_price-cur_price;
     if (abs>_range) 
      {
       //��������� � ����� �������� ����������� � ������ ������
       _mode = TM_WAIT_FOR_CROSS;      
       return BUY;
      }
   }
  //���� ����� ����������
  if (_tg < 0)
   {
     cur_price = SymbolInfoDouble(symbol,SYMBOL_ASK);   
     abs=cur_price-_open_price;
     if (abs>_range) 
      {
       //��������� � ����� �������� ����������� � ������ ������
       _mode = TM_WAIT_FOR_CROSS;            
       return SELL;
      }
   }  
  return UNKNOWN;
 }
 
//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+ 

void CTihiro::OnNewBar(double &price_high[],double &price_low[])
//��������� ��� ����������� �������� �� �������� ������������ � ����������� ��� �����
 {
  //���� ����� �������� ����������� ���� � ������ ������
  if (_mode==TM_WAIT_FOR_CROSS)
  {
  //��������� ����������
  // ---- ����� ����� ���������� �����������
  
  //���� ���������� ��������� - ���������� ��� �������� (���� �� ����)
  //���� �������� ����������, ��
  
  //��������� ������� ����� ������
  GetTan();
  //��������� range
  GetRange();
  }
 }
 
short CTihiro::OnTick(string symbol)
//�� ������ ���� ���������, ������� �� ���� �� ����� �����  
{
  //����� ��������� �����
 switch (_mode)
 {
 //�������� ����������� ����� ������
 case TM_WAIT_FOR_CROSS:   
  return TestCrossTrendLine(symbol); 
 break;
 //����� �������� ���������� ������ range
 case TM_REACH_THE_RANGE:
  return TestReachRange(symbol);
 break; 
 } //switch
 return UNKNOWN;
}