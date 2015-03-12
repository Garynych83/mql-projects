//+------------------------------------------------------------------+
//|                                                      CTihiro.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <TradeManager\TradeManagerEnums.mqh>
#include <CompareDoubles.mqh>  
//+------------------------------------------------------------------+
//| ����� ��� �������� TIHIRO                                        |
//+------------------------------------------------------------------+
//��������� 
#define UNKNOWN    0
#define BUY        1
#define SELL       2
#define TREND_UP   3
#define TREND_DOWN 4
#define NOTREND    5

//��������� �����������
struct Extrem
  {
   uint n_bar;      //����� ���� 
   double price;    //������� ��������� ����������
  };
  
//������������ ������� ���������� ���� �������
enum TAKE_PROFIT_MODE
 {
  TPM_HIGH=0, //������� ����
  TPM_CLOSE,  //���� ��������
 };

class CTihiro 
 {
    //��������� ���� ������
   private:
    //������ 
    double   _price_high[];      // ������ ������� ���  
    double   _price_low[];       // ������ ������ ���  
    double   _price_close[];     // ������ ��� ��������
    double   _parabolic[];       // �������� ���������� Parabolic SAR
    //������
    string  _symbol;
    //���������
    ENUM_TIMEFRAMES _timeFrame;
    //�����
    double  _point;
    //���������� ����� �������
    uint    _bars;  
    //������� ����� ������
    double  _tg;
    //���������� �� ����� ������ �� ���������� ����������
    double  _range;
    //���� ������
    int  _takeProfit;
    //���� ����
    int  _stopLoss;
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
    //���� �� ���������� ����
    double   _prev_bid;
    double   _prev_ask;
    //����� ���������� ���� �������
    TAKE_PROFIT_MODE _takeProfitMode;
    //����������� ���������� ���� �������
    double _takeProfitFactor;
    //������� ��� ��� ������ ����������
    double   _priceDifferent;
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
    short   TestPointLocate(double cur_price);
    //��������� ���������
    void    SetExtrem(Extrem & extr,uint n,double p);
   public:
   //����������� ������ 
   CTihiro(string symbol,ENUM_TIMEFRAMES timeFrame,double point,uint bars,TAKE_PROFIT_MODE takeProfitMode,double takeProfitFactor,uint priceDifferent):
     _symbol(symbol),
     _timeFrame(timeFrame),
     _point(point),
     _bars(bars),
     _takeProfitMode(takeProfitMode),
     _takeProfitFactor(takeProfitFactor),
     _priceDifferent(priceDifferent*point)
    { 
     //������� ��� � ���������
     ArraySetAsSeries(_price_high,true);  
     ArraySetAsSeries(_price_low, true);  
     ArraySetAsSeries(_price_close,true);      
     _prev_ask = -1;
     _prev_bid = -1;     
    }; 
   //���������� ������
   ~CTihiro()
    {
     //������� ������� �� ������������ ������
     ArrayFree(_price_high);  
     ArrayFree(_price_low);   
     ArrayFree(_price_close); 
    };
   // -----------------------------------------------------------------------------
   //���������� �������� ������
   ENUM_TM_POSITION_TYPE   GetSignal();   
   //���������� ����������
   int     GetTakeProfit() { return (_takeProfit); };
   //���������� ���� ����
   int     GetStopLoss()   { return (_stopLoss); };
   //�������� �� �������� ��������� �� ������� ������������ � ����������� ��� �����
   //� ��������� ��� ����������� �������� �� ���
   //� ������ - ����������, ������� ��������� �����, ���������� �� ����� ������ �� ���������� ���������� 
   bool    OnNewBar();
 };

//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+

void CTihiro::GetTan() 
//�������� �������� �������� ���� ������� ����� ������
 {
  if (_trend_type == TREND_DOWN)
   {  
    _tg =  (_extr_down_present.price-_extr_down_past.price)/( _extr_down_past.n_bar - _extr_down_present.n_bar);
   }
  if (_trend_type == TREND_UP)
   {  
    _tg =  (_extr_up_present.price-_extr_up_past.price)/(_extr_up_past.n_bar - _extr_up_present.n_bar);
   }   
 }
 
void CTihiro::GetRange(void)
//��������� ���� ������
 {
  datetime L;
  double H;
  if (_trend_type == TREND_DOWN)
   {
    L=_extr_down_past.n_bar-_extr_up_present.n_bar;  
    
    switch (_takeProfitMode)
     {
      case TPM_CLOSE:
      H=_price_close[_extr_up_present.n_bar]-_extr_down_past.price;
      break;
      case TPM_HIGH:
      H=_extr_up_present.price-_extr_down_past.price;
      break;      
     }
   }
  if (_trend_type == TREND_UP)
   {
    L=_extr_up_past.n_bar-_extr_down_present.n_bar;  
    
    switch (_takeProfitMode)
     {
      case TPM_CLOSE:
      H=_price_close[_extr_down_present.n_bar]-_extr_up_past.price;
      break;
      case TPM_HIGH:
      H=_extr_down_present.price-_extr_up_past.price;
      break;
     }
   }   
  _range=MathAbs(H-_tg*L);
 }
 
void CTihiro::GetTDPoints()
//���� TD ����� ��� ����� �����
 {
   short i; 
   double price_diff_left;
   double price_diff_right;
   _flag_down = 0;
   _flag_up   = 0;
   //�������� �� ����� � ��������� ����������
   for(i = 1; i < (_bars-1) && (_flag_down<2||_flag_up<2); i++)
    {
     price_diff_left  = _price_high[i] - _price_high[i-1];
     price_diff_right = _price_high[i] - _price_high[i+1];
     //���� ������� high ���� ������ high ��� ����������� � ����������
   //  if ( GreatDoubles(_price_high[i],_price_high[i-1]) && GreatDoubles(_price_high[i],_price_high[i+1]) && _flag_down < 2 )  
     if (price_diff_left >= _priceDifferent && price_diff_right >= _priceDifferent && _flag_down < 2)   
      {
       if (_flag_down == 0)
        {
         //��������� ������ ���������
         SetExtrem(_extr_down_present,i+1,_price_high[i]);
         _flag_down = 1; 
        }
       else 
        {
         if( GreatDoubles(_price_high[i],_extr_down_present.price) )
          {
          //��������� ����� ���������
          SetExtrem(_extr_down_past,i+1,_price_high[i]);             
          _flag_down = 2;
          }
        }            
      }  //���������� �����
     price_diff_left  = _price_low[i-1] - _price_low[i];
     price_diff_right = _price_low[i+1] - _price_low[i];
//���� ������� low ���� ������ low ��� ����������� � ����������
    // if ( LessDoubles(_price_low[i],_price_low[i-1]) && LessDoubles(_price_low[i],_price_low[i+1])&&_flag_up < 2)     
     if (price_diff_left >= _priceDifferent && price_diff_right >= _priceDifferent && _flag_up < 2)
      {
       if (_flag_up == 0)
        {
         //��������� ������ ���������
          SetExtrem(_extr_up_present,i+1,_price_low[i]);           
         _flag_up = 1; 
        }
       else 
        {
         if(LessDoubles(_price_low[i],_extr_up_present.price))         
          {
          //��������� ����� ���������
          SetExtrem(_extr_up_past,i+1,_price_low[i]);                    
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
   if (_flag_down == 2 && _flag_up > 0 &&_extr_up_present.n_bar < _extr_down_present.n_bar)  //���� ������ ��������� ������� ����� ������
     {
      //��������, ��� ����� ����������
      _trend_type = TREND_DOWN; 
      return;
     } 
   if (_flag_up == 2 && _flag_down > 0 && _extr_down_present.n_bar < _extr_up_present.n_bar)  //���� ������� ��������� ������� ����� ������
     {      
      //��������, ��� ����� ����������
      _trend_type = TREND_UP; 
      return;
     }     
 }
 
short CTihiro::TestPointLocate(double cur_price)
//���������, ���� ��� ���� ����� ������ ��������� ������� �����
 {
   datetime time;
   double price;
   double line_level;
   if (_trend_type == TREND_DOWN)
    {
     line_level = _extr_down_past.price+_extr_down_past.n_bar*_tg;  //��������  ����� ������ � ������ ����� 
    }
   if (_trend_type == TREND_UP)
    {
     line_level = _extr_up_past.price+_extr_up_past.n_bar*_tg;  //��������  ����� ������ � ������ �����     
    }    
   if (cur_price>line_level)
    {
     return 1;  //����� ��������� ���� ����� ������
    }
   if (cur_price<line_level)
    {
     return -1; //����� ��������� ���� ����� ������
    }
   return 0;   //����� ��������� �� ����� ������
 }
  
void CTihiro::SetExtrem(Extrem & extr,uint n,double p)
//��������� ��������� 
 {
  extr.n_bar = n;
  extr.price = p;
 }
 
//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+  
 
ENUM_TM_POSITION_TYPE CTihiro::GetSignal()
//���������� �������� ������
 {
 //������� ���� �� BID � ASK 
 double   price_bid = SymbolInfoDouble(_symbol,SYMBOL_BID);
 double   price_ask = SymbolInfoDouble(_symbol,SYMBOL_ASK);
 if (_prev_ask==-1)
  {
   _prev_ask = price_ask;
   _prev_bid = price_bid;
  }
 //������� ��������� ���� ������������ ����� ������
 short    locate_now;
 //���������� ��������� ���� ������������ ����� ������
 short    locate_prev;
  //���� ����� ���������� 
 if (_trend_type == TREND_UP) 
   {
    //��������� ������� ��������� ���� ������������ ����� ������
    locate_now = TestPointLocate(price_bid);
    //��������� ��������� ����������� ���� ������������ ����� ������
    locate_prev = TestPointLocate(_prev_bid);    
    //���� ���� ���������� �� ����� ������ ������ ����
    if (locate_prev > 0 && locate_now<=0)
     {
     //��������� ���� ������
      _takeProfit = _takeProfitFactor*_range/_point;  
      //���������� ���� ����
      _stopLoss   =  (_extr_down_present.price-price_bid)/_point;      
      _prev_bid   = price_bid;
      _prev_ask   = price_ask; 
      return OP_SELL;
     }  
   }
  //���� ����� ����������
  if (_trend_type == TREND_DOWN) 
   {
    //��������� ������� ��������� ���� ������������ ����� ������
    locate_now = TestPointLocate(price_ask);
    //��������� ��������� ����������� ���� ������������ ����� ������
    locate_prev = TestPointLocate(_prev_ask);      
    //���� ���� ���������� �� ����� ������ ����� �����
    if (locate_prev < 0 && locate_now >= 0)
     { 
      //��������� ���� ������
      _takeProfit = _takeProfitFactor*_range/_point; 
      //���������� ���� ����
      _stopLoss   = (price_ask-_extr_up_present.price)/_point;
      _prev_bid = price_bid;
      _prev_ask = price_ask;       
      return OP_BUY;
     }    
   }  
      _prev_bid = price_bid;
      _prev_ask = price_ask; 
  return OP_UNKNOWN;  
 }

bool CTihiro::OnNewBar()
//��������� ��� ����������� �������� �� �������� ������������ � ����������� ��� �����
 {
  //��������� ������ 
  if(CopyHigh (_symbol, _timeFrame, 1, _bars, _price_high)  <= 0 ||
     CopyLow  (_symbol, _timeFrame, 1, _bars, _price_low)   <= 0 ||
     CopyClose(_symbol, _timeFrame, 1, _bars, _price_close) <= 0 )
      {
       Print("�� ������� ��������� ���� �� �������");
       return false;
      }
  // ��������� ���������� (TD-����� ����� ������)
  GetTDPoints();  
  // ��������� ��� ������ (��������)
  RecognizeSituation();
  // ��������� ������� ����� �����
  GetTan();
  // ��������� ���������� �� ���������� �� ����� ������
  GetRange();
  return true; 
 }