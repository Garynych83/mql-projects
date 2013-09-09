//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//���������� ������ �� ������ �� ��������
#include <Trade/Trade.mqh>
#include <TradeManager/TradeManager.mqh>
#include "PositionSys.mqh"
#include "SymbolSys.mqh"
#include "Graph.mqh"

 class  HisTrade //����� ���������� ������
  {
   private:
    datetime new_bar;  //--- ���������� ��� ������� �������� �������� ����
    datetime time_last_bar[1]; //--- ������ ��� ��������� ������� �������� �������� ����
   int  AllowedNumberOfBars;   
   CTrade trade;   
   double      close_price[]; // Close (���� �������� ����)
   double      open_price[];  // Open (���� �������� ����)
   double      high_price[];  // High (���� ��������� ����)
   double      low_price[];   // Open (���� �������� ����)
   
   long        MagicNumber;     // ���������� �����
   int         Deviation;        // ���������������
   int         NumberOfBars;      // ���-�� ������/��������� ����� ��� �������/�������
   double      Lot;             // ���
   double      VolumeIncrease;  // ���������� ������ �������
   double      StopLoss;         // ���� ����
   double      TakeProfit;      // ���� ������
   double      TrailingStop;     // �������� ����
   bool        Reverse;        // �������� �������
   bool        ShowInfoPanel;  // ����� �������������� ������
   
   public:
   CTradeManager new_trade;
   PositionSys my_pos; 
   SymbolSys   my_sym;
   GraphModule my_graph;   
   bool CheckNewBar();  //��������� ������������ ������ ����
   string TimeframeToString(ENUM_TIMEFRAMES timeframe);  //����������� ��������� � ������
   void GetBarsData();  //
   ENUM_ORDER_TYPE GetTradingSignal(); //�������� ������ ��������
   void OpenPosition(double lot,
                  ENUM_ORDER_TYPE order_type,
                  double price,
                  double sl,
                  double tp,
                  string comment);  //��������� ������� 
   int UploadInputs (long        _MagicNumber,   //����� �������� ���������� �� ������� ������� � ����� �������� 
                     int         _Deviation,
                     int         _NumberOfBars,
                     double      _Lot,
                     double      _VolumeIncrease,
                     double      _StopLoss,
                     double      _TakeProfit,
                     double      _TrailingStop,
                     bool        _Reverse,
                     bool        _ShowInfoPanel                
                     );  //�������� �� ������� �������� ���������� � �������� �����               
   void TradingBlock();  //�������� ����  
   double CalculateLot(double lot);  //������������ ���
   double CalculateTakeProfit(ENUM_ORDER_TYPE order_type); //��������� ���� ������
   double CalculateStopLoss(ENUM_ORDER_TYPE order_type); //��������� ���� ����
   double CalculateTrailingStop(ENUM_POSITION_TYPE position_type); //��������� �������� ����
   void ModifyTrailingStop();  //������������ �������� ����                  
   HisTrade(); //����������� ������
  ~HisTrade(); //���������� ������  
  };
  
  bool HisTrade::CheckNewBar()
  {
//--- ������� ����� �������� �������� ����
//    ���� �������� ������ ��� ���������, ������� �� ����
   if(CopyTime(_Symbol,Period(),0,1,time_last_bar)==-1)
     { Print(__FUNCTION__,": ������ ����������� ������� �������� ����: "+IntegerToString(GetLastError())+""); }
//--- ���� ��� ������ ����� �������
   if(new_bar==NULL)
     {
      // ��������� �����
      new_bar=time_last_bar[0];
      Print(__FUNCTION__,": ������������� ["+_Symbol+"][TF: "+TimeframeToString(Period())+"]["
            +TimeToString(time_last_bar[0],TIME_DATE|TIME_MINUTES|TIME_SECONDS)+"]");
      return(false); // ����� false � ������ 
     }
//--- ���� ����� ����������
   if(new_bar!=time_last_bar[0])
     {
      new_bar=time_last_bar[0]; // ��������� ����� � ������ 
      return(true); // �������� ����� � ������ true
     }
//--- ����� �� ����� ����� - ������ ��� �� �����, ������ false
   return(false);
  }
//+------------------------------------------------------------------+
//| ����������� ��������� � ������                                   |
//+------------------------------------------------------------------+
string HisTrade::TimeframeToString(ENUM_TIMEFRAMES timeframe)
  {
   string str="";
//--- ���� ���������� �������� �����������, ����� ��������� �������� �������
   if(timeframe==WRONG_VALUE|| timeframe== NULL)
      timeframe= Period();
   switch(timeframe)
     {
      case PERIOD_M1  : str="M1";  break;
      case PERIOD_M2  : str="M2";  break;
      case PERIOD_M3  : str="M3";  break;
      case PERIOD_M4  : str="M4";  break;
      case PERIOD_M5  : str="M5";  break;
      case PERIOD_M6  : str="M6";  break;
      case PERIOD_M10 : str="M10"; break;
      case PERIOD_M12 : str="M12"; break;
      case PERIOD_M15 : str="M15"; break;
      case PERIOD_M20 : str="M20"; break;
      case PERIOD_M30 : str="M30"; break;
      case PERIOD_H1  : str="H1";  break;
      case PERIOD_H2  : str="H2";  break;
      case PERIOD_H3  : str="H3";  break;
      case PERIOD_H4  : str="H4";  break;
      case PERIOD_H6  : str="H6";  break;
      case PERIOD_H8  : str="H8";  break;
      case PERIOD_H12 : str="H12"; break;
      case PERIOD_D1  : str="D1";  break;
      case PERIOD_W1  : str="W1";  break;
      case PERIOD_MN1 : str="MN1"; break;
     }
//---
   return(str);
  }
//+------------------------------------------------------------------+
//| �������� �������� �����                                          |
//+------------------------------------------------------------------+
void HisTrade::GetBarsData()
  {
//--- ������������� �������� ���������� ����� ��� ������� �������� �������
   if(NumberOfBars<=1)
      AllowedNumberOfBars=2;              // ����� �� ����� ���� �����
   if(NumberOfBars>=5)
      AllowedNumberOfBars=5;              // � �� ����� 5
   else
      AllowedNumberOfBars=NumberOfBars+1; // � ������ �� ���� ������
//--- ��������� �������� ������� ���������� (... 3 2 1 0)
   ArraySetAsSeries(close_price,true);
   ArraySetAsSeries(open_price,true);
   ArraySetAsSeries(high_price,true);
   ArraySetAsSeries(low_price,true);
//--- ������� ���� �������� ����
//    ���� ���������� �������� ������, ��� ���������, ������� ��������� �� ����
   if(CopyClose(_Symbol,Period(),0,AllowedNumberOfBars,close_price)<AllowedNumberOfBars)
     {
      Print("�� ������� ����������� �������� ("
            +_Symbol+", "+TimeframeToString(Period())+") � ������ ��� Close! "
            "������ "+IntegerToString(GetLastError())+": "+ErrorDescription(GetLastError()));
     }
//--- ������� ���� �������� ����
//    ���� ���������� �������� ������, ��� ���������, ������� ��������� �� ����
   if(CopyOpen(_Symbol,Period(),0,AllowedNumberOfBars,open_price)<AllowedNumberOfBars)
     {
      Print("�� ������� ����������� �������� ("
            +_Symbol+", "+TimeframeToString(Period())+") � ������ ��� Open! "
            "������ "+IntegerToString(GetLastError())+": "+ErrorDescription(GetLastError()));
     }
//--- ������� ���� ��������� ����
//    ���� ���������� �������� ������, ��� ���������, ������� ��������� �� ����
   if(CopyHigh(_Symbol,Period(),0,AllowedNumberOfBars,high_price)<AllowedNumberOfBars)
     {
      Print("�� ������� ����������� �������� ("
            +_Symbol+", "+TimeframeToString(Period())+") � ������ ��� High! "
            "������ "+IntegerToString(GetLastError())+": "+ErrorDescription(GetLastError()));
     }
//--- ������� ���� ��������� ����
//    ���� ���������� �������� ������, ��� ���������, ������� ��������� �� ����
   if(CopyLow(_Symbol,Period(),0,AllowedNumberOfBars,low_price)<AllowedNumberOfBars)
     {
      Print("�� ������� ����������� �������� ("
            +_Symbol+", "+TimeframeToString(Period())+") � ������ ��� Low! "
            "������ "+IntegerToString(GetLastError())+": "+ErrorDescription(GetLastError()));
     }
  }
//+------------------------------------------------------------------+
//| ���������� �������� �������                                      |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE HisTrade::GetTradingSignal()
  {
//--- ������ �� ������� (ORDER_TYPE_BUY) :
   if(AllowedNumberOfBars==2 && 
      close_price[1]>open_price[1])
      return(ORDER_TYPE_BUY);
   if(AllowedNumberOfBars==3 && 
      close_price[1]>open_price[1] && 
      close_price[2]>open_price[2])
      return(ORDER_TYPE_BUY);
   if(AllowedNumberOfBars==4 && 
      close_price[1]>open_price[1] && 
      close_price[2]>open_price[2] && 
      close_price[3]>open_price[3])
      return(ORDER_TYPE_BUY);
   if(AllowedNumberOfBars==5 && 
      close_price[1]>open_price[1] && 
      close_price[2]>open_price[2] && 
      close_price[3]>open_price[3] && 
      close_price[4]>open_price[4])
      return(ORDER_TYPE_BUY);
   if(AllowedNumberOfBars>=6 && 
      close_price[1]>open_price[1] && 
      close_price[2]>open_price[2] && 
      close_price[3]>open_price[3] && 
      close_price[4]>open_price[4] && 
      close_price[5]>open_price[5])
      return(ORDER_TYPE_BUY);
//--- ������ �� ������� (ORDER_TYPE_SELL) :
   if(AllowedNumberOfBars==2 && 
      close_price[1]<open_price[1])
      return(ORDER_TYPE_SELL);
   if(AllowedNumberOfBars==3 && 
      close_price[1]<open_price[1] && 
      close_price[2]<open_price[2])
      return(ORDER_TYPE_SELL);
   if(AllowedNumberOfBars==4 && 
      close_price[1]<open_price[1] && 
      close_price[2]<open_price[2] && 
      close_price[3]<open_price[3])
      return(ORDER_TYPE_SELL);
   if(AllowedNumberOfBars==5 && 
      close_price[1]<open_price[1] && 
      close_price[2]<open_price[2] && 
      close_price[3]<open_price[3] && 
      close_price[4]<open_price[4])
      return(ORDER_TYPE_SELL);
   if(AllowedNumberOfBars>=6 && 
      close_price[1]<open_price[1] && 
      close_price[2]<open_price[2] && 
      close_price[3]<open_price[3] && 
      close_price[4]<open_price[4] && 
      close_price[5]<open_price[5])
      return(ORDER_TYPE_SELL);
//--- ���������� ������� (WRONG_VALUE):
   return(WRONG_VALUE);
  }
  
   int HisTrade::UploadInputs (long        _MagicNumber,   //����� �������� ���������� �� ������� ������� � ����� �������� 
                     int         _Deviation,
                     int         _NumberOfBars,
                     double      _Lot,
                     double      _VolumeIncrease,
                     double      _StopLoss,
                     double      _TakeProfit,
                     double      _TrailingStop,
                     bool        _Reverse,
                     bool        _ShowInfoPanel                
                     )
       {
         MagicNumber = _MagicNumber;
         Deviation = _Deviation;
         NumberOfBars = _NumberOfBars;
         Lot = _Lot;
         VolumeIncrease = _VolumeIncrease;
         StopLoss = _StopLoss;
         TakeProfit = _TakeProfit;
         TrailingStop = _TrailingStop;
         Reverse = _Reverse;
         ShowInfoPanel = _ShowInfoPanel;
         return 1;
       }                 
//+------------------------------------------------------------------+
//| ��������� �������                                                |
//+------------------------------------------------------------------+
void HisTrade::OpenPosition(double lot,
                  ENUM_ORDER_TYPE order_type,
                  double price,
                  double sl,
                  double tp,
                  string comment)
  {
   ENUM_TM_POSITION_TYPE getOrder;
   //trade.SetExpertMagicNumber(MagicNumber); // ��������� ����� ������� � �������� ���������
  // trade.SetDeviationInPoints(my_sym.CorrectValueBySymbolDigits(Deviation)); // ��������� ������ ��������������� � �������
   
   new_trade.MakeMagic(MagicNumber); //������������� ���������� �����
   
//--- ���� ������� �� ���������, ������� ��������� �� ����
   
   if (order_type == ORDER_TYPE_BUY)
      getOrder = OP_BUY;
   if (order_type == ORDER_TYPE_SELL)
      getOrder = OP_SELL;
      
      // if(!trade.PositionOpen(_Symbol,order_type,lot,price,sl,tp,comment))
      
   if (!new_trade.OpenPosition(_Symbol,getOrder,lot,sl,tp,0,0,0) )
     { Print("������ ��� �������� �������: ",GetLastError()," - ",ErrorDescription(GetLastError())); }
  }
//+------------------------------------------------------------------+
//| �������� ����                                                    |
//+------------------------------------------------------------------+
void HisTrade::TradingBlock()
  {
   ENUM_ORDER_TYPE      signal=WRONG_VALUE;                 // ���������� ��� ������ �������
   string               comment="hello :)";                 // ����������� ��� �������
   double               tp=0.0;                             // Take Profit
   double               sl=0.0;                             // Stop Loss
   double               lot=0.0;                            // ����� ��� ������� ������� � ������ ���������� �������
   double               position_open_price=0.0;            // ���� �������� �������
   ENUM_ORDER_TYPE      order_type=WRONG_VALUE;             // ��� ������ ��� �������� �������
   ENUM_POSITION_TYPE   opposite_position_type=WRONG_VALUE; // ��������������� ��� �������
//--- ������� ������
   signal=GetTradingSignal();
//--- ���� ������� ���, �������
   if(signal==WRONG_VALUE)
      return;
//--- ������, ���� �� �������
   my_pos.pos.exists=PositionSelect(_Symbol);
//--- ������� ��� �������� �������
   my_sym.GetSymbolProperties("1111111111111111111");
//--- ��������� �������� �������� ����������
   switch(signal)
     {
      //--- �������� ���������� �������� ��� BUY
      case ORDER_TYPE_BUY  :
         position_open_price=my_sym.symb.ask;
         order_type=ORDER_TYPE_BUY;
         opposite_position_type=POSITION_TYPE_SELL;
         break;
         //--- �������� ���������� �������� ��� SELL
      case ORDER_TYPE_SELL :
         position_open_price=my_sym.symb.bid;
         order_type=ORDER_TYPE_SELL;
         opposite_position_type=POSITION_TYPE_BUY;
         break;
     }
//--- ���������� ������ Take Profit � Stop Loss
   sl=CalculateStopLoss(order_type);
  
   tp=CalculateTakeProfit(order_type);
//--- ���� ������� ���
   if(!my_pos.pos.exists)
     {
      //--- ������������� �����
      lot=CalculateLot(Lot);
      //--- ������� �������
      OpenPosition(lot,order_type,position_open_price,sl,tp,comment);
     }
//--- ���� ������� ����
   else
     {
      //--- ������� ��� �������
      my_pos.GetPositionProperties("1111111111111111111");
      //--- ���� ������� �������������� ������� � ������� ��������� �������
      if(my_pos.pos.type==opposite_position_type && Reverse)
        {
         //--- ������� ����� �������
         my_pos.GetPositionProperties("1111111111111111111");
         //--- ������������� �����
         lot=my_pos.pos.volume+CalculateLot(Lot);
         //--- ���������� �������
         OpenPosition(lot,order_type,position_open_price,sl,tp,comment);
         return;
        }
      //--- ���� ������ �� ����������� ������� � �������� ����������� ������, �������� ����� �������
      if(!(my_pos.pos.type==opposite_position_type) && VolumeIncrease>0)
        {
         //--- ������� Stop Loss ������� �������
         my_pos.GetPositionProperties("1111111111111111111");
         //--- ������� Take Profit ������� �������
         my_pos.GetPositionProperties("1111111111111111111");
         //--- ������������� �����
         lot=CalculateLot(VolumeIncrease);
         //--- �������� ����� �������
         OpenPosition(lot,order_type,position_open_price,my_pos.pos.sl,my_pos.pos.tp,comment);
         return;
        }
     }
//---
   return;
  }
  
  //+------------------------------------------------------------------+
//| ������������ ����� ��� �������                                   |
//+------------------------------------------------------------------+
double HisTrade::CalculateLot(double lot)
  {
//--- ��� ������������� � ������ ����
   double corrected_lot=0.0;
   
//---
   my_sym.GetSymbolProperties("1111111111111111111");  // ������� ���������� ��������� ���
   my_sym.GetSymbolProperties("1111111111111111111");  // ������� ����������� ��������� ���
   my_sym.GetSymbolProperties("1111111111111111111"); // ������� ��� ����������/���������� ����
//--- ������������� � ������ ���� ����
   corrected_lot=MathRound(lot/my_sym.symb.volume_step)*my_sym.symb.volume_step;
//--- ���� ������ ������������, ������ �����������
   if(corrected_lot<my_sym.symb.volume_min)
      return(NormalizeDouble(my_sym.symb.volume_min,2));
//--- ���� ������ �������������, ������ ������������
   if(corrected_lot>my_sym.symb.volume_max)
      return(NormalizeDouble(my_sym.symb.volume_max,2));
//---
   return(NormalizeDouble(corrected_lot,2));
  }
//+------------------------------------------------------------------+
//| ������������ ������� Take Profit                                 |
//+------------------------------------------------------------------+
double HisTrade::CalculateTakeProfit(ENUM_ORDER_TYPE order_type)
  {
//--- ���� Take Profit �����
   if(TakeProfit>0)
     {
      //--- ��� ������������� �������� Take Profit
      double tp=0.0;
      //--- ���� ����� ���������� �������� ��� ������� SELL
      if(order_type==ORDER_TYPE_SELL)
        {
         //--- ���������� �������
         tp=NormalizeDouble(my_sym.symb.bid-my_sym.CorrectValueBySymbolDigits(TakeProfit*my_sym.symb.point),my_sym.symb.digits);
         //--- ������ ������������ ��������, ���� ��� ���� ������ ������� stops level
         //    ���� �������� ���� ��� �����, ������ ����������������� ��������
         return(tp<my_sym.symb.down_level ? tp : my_sym.symb.down_level-my_sym.symb.offset);
        }
      //--- ���� ����� ���������� �������� ��� ������� BUY
      if(order_type==ORDER_TYPE_BUY)
        {
         //--- ���������� �������
         tp=NormalizeDouble(my_sym.symb.ask+my_sym.CorrectValueBySymbolDigits(TakeProfit*my_sym.symb.point),my_sym.symb.digits);
         //--- ������ ������������ ��������, ���� ��� ���� ������� ������� stops level
         //    ���� �������� ���� ��� �����, ������ ����������������� ��������
         return(tp>my_sym.symb.up_level ? tp : my_sym.symb.up_level+my_sym.symb.offset);
        }
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| ������������ ������� Stop Loss                                   |
//+------------------------------------------------------------------+
double HisTrade::CalculateStopLoss(ENUM_ORDER_TYPE order_type)
  {
//--- ���� Stop Loss �����
   if(StopLoss>0)
     {
      //--- ��� ������������� �������� Stop Loss
      double sl=0.0;
      //--- ���� ����� ���������� �������� ��� ������� BUY
      if(order_type==ORDER_TYPE_BUY)
        {
         // ���������� �������
         sl=NormalizeDouble(my_sym.symb.ask-my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
         //--- ������ ������������ ��������, ���� ��� ���� ������ ������� stops level
         //    ���� �������� ���� ��� �����, ������ ����������������� ��������
         return(sl<my_sym.symb.down_level ? sl : my_sym.symb.down_level-my_sym.symb.offset);
        }
      //--- ���� ����� ���������� �������� ��� ������� SELL
      if(order_type==ORDER_TYPE_SELL)
        {
         //--- ���������� �������
         sl=NormalizeDouble(my_sym.symb.bid+my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
         //--- ������ ������������ ��������, ���� ��� ���� ������� ������� stops level
         //    ���� �������� ���� ��� �����, ������ ����������������� ��������
         return(sl>my_sym.symb.up_level ? sl : my_sym.symb.up_level+my_sym.symb.offset);
        }
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| ������������ ������� Trailing Stop                               |
//+------------------------------------------------------------------+
/*
double HisTrade::CalculateTrailingStop(ENUM_POSITION_TYPE position_type)
  {
//--- ���������� ��� ��������
   double            level       =0.0;
   double            buy_point   =low_price[1];    // �������� Low ��� Buy
   double            sell_point  =high_price[1];   // �������� High ��� Sell
//--- ���������� ������� ��� ������� BUY
   if(position_type==POSITION_TYPE_BUY)
     {
      //--- ������� ���� ����� ��������� ���������� �������
      level=NormalizeDouble(buy_point-my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
      //--- ���� ������������ ������� ����, ��� ������ ������� ����������� (stops level), 
      //    �� ������ ��������, ������ ������� �������� ������
      if(level<my_sym.symb.down_level)
         return(level);
      //--- ���� �� �� ����, �� ��������� ���������� �� ���� bid
      else
        {
         level=NormalizeDouble(my_sym.symb.bid-my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
         //--- ���� ������������ ������� ���� ������������, ������ ������� �������� ������
         //    ����� ��������� ����������� ��������� �������
         return(level<my_sym.symb.down_level ? level : my_sym.symb.down_level-my_sym.symb.offset);
        }
     }
//--- ���������� ������� ��� ������� SELL
   if(position_type==POSITION_TYPE_SELL)
     {
      // �������� ���� ���� ��������� ���-�� �������
      level=NormalizeDouble(sell_point+my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
      //--- ���� ������������ ������� ����, ��� ������� ������� ����������� (stops level), 
      //    �� ������ ��������, ������ ������� �������� ������
      if(level>my_sym.symb.up_level)
         return(level);
      //--- ���� �� �� ����, �� ��������� ���������� �� ���� ask
      else
        {
         level=NormalizeDouble(my_sym.symb.ask+my_sym.CorrectValueBySymbolDigits(StopLoss*my_sym.symb.point),my_sym.symb.digits);
         //--- ���� ������������ ������� ���� ������������, ������ ������� �������� ������
         //    ����� ��������� ����������� ��������� �������
         return(level>my_sym.symb.up_level ? level : my_sym.symb.up_level+my_sym.symb.offset);
        }
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| �������� ������� Trailing Stop                                   |
//+------------------------------------------------------------------+
void HisTrade::ModifyTrailingStop()
  {
//--- ���� ������� �������� � StopLoss
   if(TrailingStop>0 && StopLoss>0)
     {
      double         new_sl=0.0;       // ��� ������� ������ ������ Stop loss
      bool           condition=false;  // ��� �������� ������� �� �����������
      //--- ������� ���� �������/���������� �������
      my_pos.pos.exists=PositionSelect(_Symbol);
      //--- ���� ���� �������
      if(my_pos.pos.exists)
        {
         //--- ������� �������� �������
         my_sym.GetSymbolProperties("1111111111111111111");
         //--- ������� �������� �������
         my_pos.GetPositionProperties("1111111111111111111");
         //--- ������� ������� ��� Stop Loss
         new_sl=CalculateTrailingStop(my_pos.pos.type);
         //--- � ����������� �� ���� ������� �������� ��������������� ������� �� ����������� Trailing Stop
         switch(my_pos.pos.type)
           {
            case POSITION_TYPE_BUY  :
               //--- ���� ����� �������� ��� Stop Loss ����,
               //    ��� ������� �������� ���� ������������� ���
               condition=new_sl>my_pos.pos.sl+my_sym.CorrectValueBySymbolDigits(TrailingStop*my_sym.symb.point);
               break;
            case POSITION_TYPE_SELL :
               //--- ���� ����� �������� ��� Stop Loss ����,
               //    ��� ������� �������� ����� ������������� ���
               condition=new_sl<my_pos.pos.sl-my_sym.CorrectValueBySymbolDigits(TrailingStop*my_sym.symb.point);
               break;
           }
         //--- ���� Stop Loss ����, �� ������� �������� ����� ������������
         if(my_pos.pos.sl>0)
           {
            //--- ���� ����������� ������� �� ����������� ������, �.�. ����� �������� ����/����, 
            //    ��� �������, ������������ �������� ������� �������
            if(condition)
              {
               if(!trade.PositionModify(_Symbol,new_sl,my_pos.pos.tp))
                  Print("������ ��� ����������� �������: ",GetLastError()," - ",ErrorDescription(GetLastError()));
              }
           }
         //--- ���� Stop Loss ���, �� ������ ��������� ���
         if(my_pos.pos.sl==0)
           {
            if(!trade.PositionModify(_Symbol,new_sl,my_pos.pos.tp))
               Print("������ ��� ����������� �������: ",GetLastError()," - ",ErrorDescription(GetLastError()));
           }
        }
     }
  }
  */
  HisTrade::HisTrade(void) //����������� ������
   {
 new_trade.Initialization();
   }
  
  HisTrade::~HisTrade(void) //���������� ������
   {
   
   }