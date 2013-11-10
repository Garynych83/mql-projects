//+------------------------------------------------------------------+
//|                                                      CTihiro.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Extrem.mqh" 
#include <CompareDoubles.mqh>  

//+------------------------------------------------------------------+
//| ����� ��� �������� TIHIRO                                        |
//+------------------------------------------------------------------+


class CTihiro 
 {
    //��������� ���� ������
   private:
    //������ 
    double   _price_high[];      // ������ ������� ���  
    double   _price_low[];       // ������ ������ ���  
    datetime _price_time[];      // ������ ������� 
    //������
    string  _symbol;
    //���������
    ENUM_TIMEFRAMES _timeFrame;
    //�����
    double  _point;
    //����� ��������� �����
    TIHIRO_MODE _mode;
    //���������� ����� �������
    uint    _bars;  
    //������� ����� ������
    double  _tg;
    //���������� �� ����� ������ �� ���������� ����������
    double  _range;
    //���� ������
    uint  _takeProfit;
    //����, �� ������� ���� ������� �������
    double  _open_price;
    //��������� ����������
    Extrem  _extr_up_past,_extr_down_past;
    //��������� �����������
    Extrem  _extr_up_present,_extr_down_present;
    //����� ���������� �����������
    short   _flag_up,_flag_down;
    //��� ��������
    short   _trend_type;
    //������������ ����� ������������ ����� ������ �� ���������� ����
    short   _prev_locate;
    //��������� ������ ������
   private:
    //�������� �������� �������� ���� ������� ����� ������   
    void    GetTan();  
    //���������� ���������� �� ���������� �� ����� ������
    void    GetRange();
    //���� TD ����� ��� ����� �����
    void    GetTDPoints();
    //���������� ��������
    void    RecognizeSituation();
    //���������, ���� ��� ���� ����� ������ ��������� ������� �����
    short   TestPointLocate(datetime cur_time,double cur_price);
   public:
   //����������� ������ 
   CTihiro(string symbol,ENUM_TIMEFRAMES timeFrame,double point,uint bars):
     _symbol(symbol),
     _timeFrame(timeFrame),
     _point(point),
     _mode(TM_WAIT_FOR_CROSS),
     _bars(bars)
    { 
     //������� ��� � ���������
     ArraySetAsSeries(_price_high,true);
     ArraySetAsSeries(_price_low, true);   
     ArraySetAsSeries(_price_time,true);        
    }; 
   //���������� ������
   ~CTihiro()
    {
     //������� ������� �� ������������ ������
     ArrayFree(_price_high);
     ArrayFree(_price_low);
     ArrayFree(_price_time);
    };
   // -----------------------------------------------------------------------------
   //���������� �������� ������
   short   GetSignal();   
   //���������� ����������
   uint    GetTakeProfit() { return (_takeProfit); };
   //�������� �� �������� ��������� �� ������� ������������ � ����������� ��� �����
   //� ��������� ��� ����������� �������� �� ���
   //� ������ - ����������, ������� ��������� �����, ���������� �� ����� ������ �� ���������� ���������� 
   void    OnNewBar();

 };

//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+

void CTihiro::GetTan() 
//�������� �������� �������� ���� ������� ����� ������
 {
  if (_trend_type == TREND_DOWN)
   {  
    _tg =  (_extr_down_present.price-_extr_down_past.price)/(_extr_down_present.time - _extr_down_past.time);
   }
  if (_trend_type == TREND_UP)
   {  
    _tg =  (_extr_up_present.price-_extr_up_past.price)/(_extr_up_present.time - _extr_up_past.time);
   }   
 }
 
void CTihiro::GetRange(void)
//��������� ���� ������
 {
  datetime L;
  double H;
  if (_trend_type == TREND_DOWN)
   {
    L=_extr_up_present.time-_extr_down_past.time;  
    H=_extr_up_present.price-_extr_down_past.price;
   }
  if (_trend_type == TREND_UP)
   {
    L=_extr_down_present.time-_extr_up_past.time;  
    H=_extr_down_present.price-_extr_up_past.price;
   }   
  _range=H-_tg*L;
 }
 
void CTihiro::GetTDPoints()
//���� TD ����� ��� ����� �����
 {
   short i; 
   _flag_down = 0;
   _flag_up   = 0;
   //�������� �� ����� � ��������� ����������
   for(i = 1; i < (_bars-1) && (_flag_down<2||_flag_up<2); i++)
    {
     //���� ������� high ���� ������ high ��� ����������� � ����������
     if (_price_high[i] > _price_high[i-1] && _price_high[i] > _price_high[i+1] && _flag_down < 2)
      {
       if (_flag_down == 0)
        {
         //��������� ������ ���������
         _extr_down_present.SetExtrem(_price_time[i+1],_price_high[i]);
         _flag_down = 1; 
        }
       else 
        {
         if(_price_high[i] > _extr_down_present.price)
          {
          //��������� ����� ���������
          _extr_down_past.SetExtrem(_price_time[i+1],_price_high[i]);               
          _flag_down = 2;
          }
        }            
      }  //���������� �����
//���� ������� low ���� ������ low ��� ����������� � ����������
     if (_price_low[i] < _price_low[i-1] && _price_low[i] < _price_low[i+1] && _flag_up < 2 )
      {
       if (_flag_up == 0)
        {
         //��������� ������ ���������
         _extr_up_present.SetExtrem(_price_time[i+1],_price_low[i]);
         _flag_up = 1; 
        }
       else 
        {
         if(_price_low[i] < _extr_up_present.price)
          {
          //��������� ����� ���������
          _extr_up_past.SetExtrem(_price_time[i+1],_price_low[i]);        
          _flag_up = 2;
          }
        }            
      }  //���������� �����               
     }
 } 
 
void  CTihiro::RecognizeSituation(void)
//���������� �������� 
 {
   _trend_type = NOTREND; //��� ������
   if (_flag_down == 2) //���� ���������� ����� ������
    {
     if (_flag_up > 0) //���� ���� ���� ��������� ������
      {
       if (_extr_up_present.time > _extr_down_present.time)  //���� ������ ��������� ������� ����� ������
        {
         //������������ ������� ���� ������������ ����� ������
         _prev_locate = TestPointLocate(TimeCurrent(),SymbolInfoDouble(_symbol,SYMBOL_ASK));
         //��������, ��� ����� ����������
         _trend_type = TREND_DOWN; 
         return;
        } 
      }
    }
   if (_flag_up == 2) //���� ���������� ����� ������
    {
     if (_flag_down > 0) //���� ���� ���� ��������� ������
      {
       if (_extr_down_present.time > _extr_up_present.time)  //���� ������� ��������� ������� ����� ������
        {
         //������������ ������� ���� ������������ ����� ������
         _prev_locate = TestPointLocate(TimeCurrent(),SymbolInfoDouble(_symbol,SYMBOL_BID));        
         //��������, ��� ����� ����������
         _trend_type = TREND_UP; 
         return;
        } 
      }
    }      
 }
 
short CTihiro::TestPointLocate(datetime cur_time,double cur_price)
//���������, ���� ��� ���� ����� ������ ��������� ������� �����
 {
   datetime time;
   double price;
   double line_level;
   if (_trend_type == TREND_DOWN)
    {
     line_level = _extr_down_past.price+(_price_time[0]-_extr_down_past.time)*_tg;  //��������  ����� ������ � ������ ����� 
     //Comment("�������� ������ DOWN = ",DoubleToString(line_level));
    }
   if (_trend_type == TREND_UP)
    {
     line_level = _extr_up_past.price+(_price_time[0]-_extr_up_past.time)*_tg;  //��������  ����� ������ � ������ ����� 
     //Comment("�������� ������ UP = ",DoubleToString(line_level));     
    }    
   if (cur_price>line_level)
    {
    Comment("����");
    return 1;  //����� ��������� ���� ����� ������
    }
   if (cur_price<line_level)
    {
    Comment("����");
    return -1; //����� ��������� ���� ����� ������
    }
    Comment("�� �����");
   return 0;   //����� ��������� �� ����� ������
 }
 
//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+  
 
short CTihiro::GetSignal()
//���������� �������� ������
 {
 datetime time;   //������� �����
 double   price;  //������� ����
 short    locate; //��������� ����� ������������ ������
  //���� ����� ���������� 
 if (_trend_type == TREND_UP) 
   {
    //��������� ������� �����
    time = TimeCurrent();
    //��������� ���� BID, ��� ������
    price = SymbolInfoDouble(_symbol,SYMBOL_BID);
    //��������� � ��������� ���������� ��������� ���� ������������ ����� ������
    locate  = TestPointLocate(time,price);
    //���� ���� ���������� �� ����� ������ ������ ����
    if (_prev_locate > 0 && locate<=0)
     {
     //��������� ���� ������
      _takeProfit = (price-_range)/_point;     
      _trend_type = NOTREND;      
      return SELL;
     }
    _prev_locate = locate;     
   }
  //���� ����� ����������
  if (_trend_type == TREND_DOWN) 
   {
    //��������� ������� �����
    time = TimeCurrent();   
    //��������� ���� ASK, ��� �������
    price = SymbolInfoDouble(_symbol,SYMBOL_ASK);
    //��������� � ��������� ���������� ��������� ���� ������������ ����� ������
    locate  = TestPointLocate(time,price);    
    //���� ���� ���������� �� ����� ������ ����� �����
    if (_prev_locate < 0 && locate >= 0)
     { 
      //��������� ���� ������
      _takeProfit = (price-_range)/_point; 
      _trend_type = NOTREND;
      return BUY;
     }    
    _prev_locate = locate;
   }  
  return UNKNOWN;  
 }
   

void CTihiro::OnNewBar()
//��������� ��� ����������� �������� �� �������� ������������ � ����������� ��� �����
 {
  //��������� ������ 
  if(CopyHigh(_symbol, _timeFrame, 1, _bars, _price_high) <= 0 ||
     CopyLow (_symbol, _timeFrame, 1, _bars, _price_low)  <= 0 ||
     CopyTime(_symbol, _timeFrame, 0, _bars+1, _price_time) <= 0  ) 
      {
       Print("�� ������� ��������� ���� �� �������");
       return;
      }
  // ��������� ���������� (TD-����� ����� ������)
  GetTDPoints();
  /*
     //���� ���� ��� ����� 
   
     if (_flag_down==2)  //�������� �� ���������� ���������� �����������
      {
       PrintFormat("����� ����. ��������� ������ = (%s,%s), ������� ����� = (%s,%s)",TimeToString(_extr_down_present.time),DoubleToString(_extr_down_present.price),
       TimeToString(_extr_down_past.time),DoubleToString(_extr_down_past.price));
      }
     if (_flag_up==2)  //�������� �� ���������� ���������� �����������
      {
       PrintFormat("����� �����. ��������� ������ = (%s,%s), ������� ����� = (%s,%s)",TimeToString(_extr_up_present.time),DoubleToString(_extr_up_present.price),
       TimeToString(_extr_up_past.time),DoubleToString(_extr_up_past.price));
      }       
     
     //���� ���� ��� �����
  */
  
  // ��������� ��� ������ (��������)
  RecognizeSituation();
  
    //���� ���� ��� �����
   /*
     if (_trend_type == TREND_DOWN)
      Comment("��� - ����� ����");
     if (_trend_type == TREND_UP)
      Comment("��� - ����� �����");
     if (_trend_type == NOTREND)
      Comment("��� �������� ��������");              
    */
    //���� ���� ��� �����
  
  
  // ��������� ������� ����� �����
  GetTan();
  // ��������� ���������� �� ���������� �� ����� ������
  GetRange();
  
  if (_trend_type==TREND_DOWN)
   PrintFormat("���������� �� ���������� �� ����� ������ DOWN = %s",DoubleToString(_range));
  if (_trend_type==TREND_UP)
   PrintFormat("���������� �� ���������� �� ����� ������ UP = %s",DoubleToString(_range));   
 }
 
 