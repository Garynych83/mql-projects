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
    //������ 
    double   price_high[];      // ������ ������� ���  
    double   price_low[];       // ������ ������ ���  
    datetime price_date[];      // ������ ������� 
    //������
    string _symbol;
    //���������
    ENUM_TIMEFRAMES _timeFrame;
    //����� ��������� �����
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
    Extrem _extr_up_past,_extr_down_past;
    //��������� �����������
    Extrem _extr_up_present,extr_down_present;
    //��������� ���������
    Extrem _extr_up_last,_extr_down_last;
    //��������� ������ ������
   private:
    //�������� �������� �������� ���� ������� ����� ������   
    void    GetTan();  
    //���������� ���������� �� ���������� �� ����� ������
    void    GetRange();
    //���� TD ����� ��� ����� �����
    void    GetTDPoints();
    //���������, ���� ��� ���� ����� ������ ��������� ������� �����
    short   TestPointLocate(datetime cur_time,double cur_price);
    //���������, ��� ���� ����� �� ����� ������
    short   TestCrossTrendLine(string symbol);
    //���������, ��� ���� ����� �� ���� range
    short   TestReachRange(string symbol);
   public:
   //����������� ������ 
   CTihiro(string symbol,ENUM_TIMEFRAMES timeFrame,uint bars):
     _symbol(symbol),
     _timeFrame(timeFrame),
     _mode(TM_WAIT_FOR_CROSS),
     _bars(bars)
    { 
     //������� ��� � ���������
     ArraySetAsSeries(price_high,true);
     ArraySetAsSeries(price_low, true);   
     ArraySetAsSeries(price_date,true);        
    }; 
   //���������� ������
   ~CTihiro()
    {
     //������� ������� �� ������������ ������
     ArrayFree(price_high);
     ArrayFree(price_low);
     ArrayFree(price_date);
    };
   // -----------------------------------------------------------------------------
   //�������� �� �������� ��������� �� ������� ������������ � ����������� ��� �����
   //� ��������� ��� ����������� �������� �� ���
   //� ������ - ����������, ������� ��������� �����, ���������� �� ����� ������ �� ���������� ���������� 
   void   OnNewBar(datetime &price_time[],double &price_high[],double &price_low[]);
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
 
bool CTihiro::GetTDPoints()
//���� TD ����� ��� ����� �����
 {
   short i; 
   bool flag_down = false;
   bool
   //�������� �� ����� � ��������� ����������
   for(i = 1; i < _bars; i++)
    {
     //���� ������� high ���� ������ high ��� ����������� � ����������
     if (price_high[i] > price_high[i-1] && price_high[i] > price_high[i+1])
      {
       if (flag_down == false)
        {
         //��������� ������ ���������
         point_down_right.SetExtrem(time[i],high[i]);
         flag_down = true; 
        }
       else 
        {
         if(price_high[i] > point_down_right.price)
          {
          //��������� ����� ���������
          point_down_left.SetExtrem(time[i],high[i]);               
          return true;
          }
        }            
      }  //���������� �����
//���� ������� low ���� ������ low ��� ����������� � ����������
     if (low[i] < low[i-1] && low[i] < low[i+1] && flag_up < 2 )
      {
       if (flag_up == 0)
        {
         //��������� ������ ���������
         point_up_right.SetExtrem(time[i],low[i]);
         flag_up++; 
        }
       else 
        {
         if(low[i] < point_up_right.price)
          {
          //��������� ����� ���������
          point_up_left.SetExtrem(time[i],low[i]);        
          flag_up++;
          }
        }            
      }  //���������� �����               
     }
   return false; //�� ������� ��� ����������
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

void CTihiro::OnNewBar(string symbol)
//��������� ��� ����������� �������� �� �������� ������������ � ����������� ��� �����
 {
   if(CopyHigh(symbol, 0, 1, _bars, price_high) <= 0 ||
      CopyLow (symbol, 0, 1, _bars, price_low) <= 0 ||
      CopyTime(symbol,0,1,_bars,price_date)<=0) 
       {
        Print("�� ������� ��������� ���� �� �������");
        return;
       }
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