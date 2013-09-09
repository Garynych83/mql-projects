//+------------------------------------------------------------------+
//|                                                  PositionSys.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "PositionEnum.mqh"
#include <StringUtilities.mqh>
//���������� ������� �� ������ � ��������
//ErrorDescription

class  PositionSys  //����� ������ � �������� 
 {
  public:
   position_properties  pos; //���������� ������� �������  
   void ZeroPositionProperties();    //������� �������� �������
   uint CurrentPositionTotalDeals(); //���������� ���������� ������ ������� �������
   double CurrentPositionFirstDealPrice(); //���������� ���� ������ ������ ������� �������    
   double CurrentPositionLastDealPrice();  //���������� ���� ��������� ������ ������� �������    
   double CurrentPositionInitialVolume();  //���������� ��������� ����� ������� �������    
   ulong CurrentPositionDuration(ENUM_POSITION_DURATION mode); //
   string PositionTypeToString(ENUM_POSITION_TYPE type);  //
   string CurrentPositionDurationToString(ulong time); //����������� ������������ ������� � ������   
   string GetPropertyValue(int number);   //���������� �������� ������� � ���� ������          
   void GetPositionProperties(string mask); //��������� �������� �������
   PositionSys(); //����������� ������
  ~PositionSys(); //���������� ������
 };


//+------------------------------------------------------------------+
//| ���������� ���������� ������ ������� �������                     |
//+------------------------------------------------------------------+
uint PositionSys::CurrentPositionTotalDeals()
  {
   int    total       =0;  // ����� ������ � ������ ��������� �������
   int    count       =0;  // ������� ������ �� ������� �������
   string deal_symbol =""; // ������ ������
//--- ���� ������� ������� ��������
   if(HistorySelect(pos.time,TimeCurrent()))
     {
      //--- ������� ���������� ������ � ���������� ������
      total=HistoryDealsTotal();
      //--- ������� �� ���� ������� � ���������� ������
      for(int i=0; i<total; i++)
        {
         //--- ������� ������ ������
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- ���� ������ ������ � ������� ������ ���������, �������� �������
         if(deal_symbol==_Symbol)
            count++;
        }
     }
//---
   return(count);
  }
//+------------------------------------------------------------------+
//| ���������� ���� ������ ������ ������� �������                    |
//+------------------------------------------------------------------+
double PositionSys::CurrentPositionFirstDealPrice()
  {
   int      total       =0;    // ����� ������ � ������ ��������� �������
   string   deal_symbol ="";   // ������ ������
   double   deal_price  =0.0;  // ���� ������
   datetime deal_time   =NULL; // ����� ������
//--- ���� ������� ������� ��������
   if(HistorySelect(pos.time,TimeCurrent()))
     {
      //--- ������� ���������� ������ � ���������� ������
      total=HistoryDealsTotal();
      //--- ������� �� ���� ������� � ���������� ������
      for(int i=0; i<total; i++)
        {
         //--- ������� ���� ������
         deal_price=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_PRICE);
         //--- ������� ������ ������
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- ������� ����� ������
         deal_time=(datetime)HistoryDealGetInteger(HistoryDealGetTicket(i),DEAL_TIME);
         //--- ���� ����� ������ � ����� �������� ������� �����, 
         //    � ����� ����� ������ ������ � ������� ������, ������ �� �����
         if(deal_time==pos.time && deal_symbol==_Symbol)
            break;
        }
     }
//---
   return(deal_price);
  }
//+------------------------------------------------------------------+
//| ���������� ���� ��������� ������ ������� �������                 |
//+------------------------------------------------------------------+
double PositionSys::CurrentPositionLastDealPrice()
  {
   int    total       =0;   // ����� ������ � ������ ��������� �������
   string deal_symbol ="";  // ������ ������ 
   double deal_price  =0.0; // ����
//--- ���� ������� ������� ��������
   if(HistorySelect(pos.time,TimeCurrent()))
     {
      //--- ������� ���������� ������ � ���������� ������
      total=HistoryDealsTotal();
      //--- ������� �� ���� ������� � ���������� ������ �� ��������� ������ � ������ � ������
      for(int i=total-1; i>=0; i--)
        {
         //--- ������� ���� ������
         deal_price=HistoryDealGetDouble(HistoryDealGetTicket(i),DEAL_PRICE);
         //--- ������� ������ ������
         deal_symbol=HistoryDealGetString(HistoryDealGetTicket(i),DEAL_SYMBOL);
         //--- ���� ������ ������ � ������� ������ �����, ��������� ����
         if(deal_symbol==_Symbol)
            break;
        }
     }
//---
   return(deal_price);
  }
//+------------------------------------------------------------------+
//| ���������� ��������� ����� ������� �������                       |
//+------------------------------------------------------------------+
double PositionSys::CurrentPositionInitialVolume()
  {
   int             total       =0;           // ����� ������ � ������ ��������� �������
   ulong           ticket      =0;           // ����� ������
   ENUM_DEAL_ENTRY deal_entry  =WRONG_VALUE; // ������ ��������� �������
   bool            inout       =false;       // ������� ������� ��������� �������
   double          sum_volume  =0.0;         // ������� ����������� ������ ���� ������ ����� ������
   double          deal_volume =0.0;         // ����� ������
   string          deal_symbol ="";          // ������ ������ 
   datetime        deal_time   =NULL;        // ����� ���������� ������
//--- ���� ������� ������� ��������
   if(HistorySelect(pos.time,TimeCurrent()))
     {
      //--- ������� ���������� ������ � ���������� ������
      total=HistoryDealsTotal();
      //--- ������� �� ���� ������� � ���������� ������ �� ��������� ������ � ������ � ������
      for(int i=total-1; i>=0; i--)
        {
         //--- ���� ����� ������ �� ��� ������� � ������ �������, ��...
         if((ticket=HistoryDealGetTicket(i))>0)
           {
            //--- ������� ����� ������
            deal_volume=HistoryDealGetDouble(ticket,DEAL_VOLUME);
            //--- ������� ������ ��������� �������
            deal_entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
            //--- ������� ����� ���������� ������
            deal_time=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
            //--- ������� ������ ������
            deal_symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
            //--- ����� ����� ���������� ������ ����� ������ ��� ����� ������� �������� �������, ������ �� �����
            if(deal_time<=pos.time)
               break;
            //--- ����� ������� ���������� ����� ������ �� ������� �������, ����� ������
            if(deal_symbol==_Symbol)
               sum_volume+=deal_volume;
           }
        }
     }
//--- ���� ������ ��������� ������� - ��������
   if(deal_entry==DEAL_ENTRY_INOUT)
     {
      //--- ���� ����� ������� ������������/����������
      //    �� ����, ������ ������ �����
      if(fabs(sum_volume)>0)
        {
         //--- ������� ����� ����� ����� ���� ������ ����� ������
         double result=pos.volume-sum_volume;
         //--- ���� ���� ������ ����, ������ ����, ����� ������ ������� ����� �������         
         deal_volume=result>0 ? result : pos.volume;
        }
      //--- ���� ������ ����� ����� ������ �� ����,
      if(sum_volume==0)
         deal_volume=pos.volume; // ������ ������� ����� �������
     }
//--- ������ ��������� ����� �������
   return(NormalizeDouble(deal_volume,2));
  }
//+------------------------------------------------------------------+
//| ���������� ������������ ������� �������                          |
//+------------------------------------------------------------------+
ulong PositionSys::CurrentPositionDuration(ENUM_POSITION_DURATION mode)
  {
   ulong     result=0;   // �������� ���������
   ulong     seconds=0;  // ���������� ������
//--- �������� ������������ ������� � ��������
   seconds=TimeCurrent()-pos.time;
//---
   switch(mode)
     {
      case DAYS      : result=seconds/(60*60*24);   break; // ��������� ���-�� ����
      case HOURS     : result=seconds/(60*60);      break; // ��������� ���-�� �����
      case MINUTES   : result=seconds/60;           break; // ��������� ���-�� �����
      case SECONDS   : result=seconds;              break; // ��� �������� (���-�� ������)
      //---
      default        :
         Print(__FUNCTION__,"(): ������� ����������� ����� ������������!");
         return(0);
     }
//--- ������ ���������
   return(result);
  }
//+------------------------------------------------------------------+
//| ����������� ������������ ������� � ������                        |
//+------------------------------------------------------------------+
string PositionSys::CurrentPositionDurationToString(ulong time)
  {
//--- ������� � ������ ���������� �������
   string result="-";
//--- ���� ���� �������
   if(pos.exists)
     {
      //--- ���������� ��� ���������� ��������
      ulong days=0;
      ulong hours=0;
      ulong minutes=0;
      ulong seconds=0;
      //--- 
      seconds=time%60;
      time/=60;
      //---
      minutes=time%60;
      time/=60;
      //---
      hours=time%24;
      time/=24;
      //---
      days=time;
      //--- ���������� ������ � ��������� ������� DD:HH:MM:SS
      result=StringFormat("%02u d: %02u h : %02u m : %02u s",days,hours,minutes,seconds);
     }
//--- ������ ���������
   return(result);
  }
  
  void PositionSys::ZeroPositionProperties()
  {
   pos.symbol ="";
   pos.comment="";
   pos.magic=0;
   pos.price=0.0;
   pos.current_price=0.0;
   pos.sl=0.0;
   pos.tp         =0.0;
   pos.type       =WRONG_VALUE;
   pos.volume     =0.0;
   pos.commission =0.0;
   pos.swap       =0.0;
   pos.profit     =0.0;
   pos.time       =NULL;
   pos.id         =0;
  }
//+------------------------------------------------------------------+
//| ����������� ��� ������� � ������                                 |
//+------------------------------------------------------------------+
string PositionSys::PositionTypeToString(ENUM_POSITION_TYPE type)
  {
   string str="";
//---
   if(type==POSITION_TYPE_BUY)
      str="buy";
   else if(type==POSITION_TYPE_SELL)
      str="sell";
   else
      str="wrong value";
//---
   return(str);
  }
  
  string PositionSys::GetPropertyValue(int number)
  {
//--- ���� ���������� ������� ��� ���������� ���� ��� ����� ��������
//    ��������, ���������� �����������, Stop Loss ��� Take Profit
   string empty="-";
//--- ���� ������� ����, ���������� �������� ������������ ��������
   if(pos.exists)
     {
      switch(number)
        {
         case 0   : return(IntegerToString(pos.total_deals));                     break;
         case 1   : return(pos.symbol);                                           break;
         case 2   : return(IntegerToString((int)pos.magic));                      break;
         //--- ���������� �������� �����������, ���� ����, ����� - ���� ����������
         case 3   : return(pos.comment!="" ? pos.comment : empty);                break;
         case 4   : return(DoubleToString(pos.swap,2));                           break;
         case 5   : return(DoubleToString(pos.commission,2));                     break;
         case 6   : return(DoubleToString(pos.first_deal_price,_Digits));         break;
         case 7   : return(DoubleToString(pos.price,_Digits));                    break;
         case 8   : return(DoubleToString(pos.current_price,_Digits));            break;
         case 9   : return(DoubleToString(pos.last_deal_price,_Digits));          break;
         case 10  : return(DoubleToString(pos.profit,2));                         break;
         case 11  : return(DoubleToString(pos.volume,2));                         break;
         case 12  : return(DoubleToString(pos.initial_volume,2));                 break;
         case 13  : return(pos.sl!=0.0 ? DoubleToString(pos.sl,_Digits) : empty); break;
         case 14  : return(pos.tp!=0.0 ? DoubleToString(pos.tp,_Digits) : empty); break;
         case 15  : return(TimeToString(pos.time,TIME_DATE|TIME_MINUTES));        break;
         case 16  : return(CurrentPositionDurationToString(pos.duration));        break;
         case 17  : return(IntegerToString((int)pos.id));                         break;
         case 18  : return(PositionTypeToString(pos.type));                       break;

         default : return(empty);
        }
     }
//---
// ���� �� ������� ���, ���������� ���� ���������� ������� "-"
   return(empty);
  }
  

  
  void PositionSys::GetPositionProperties(string mask) //����� ����������� �������� �������
  {
//--- ������, ���� �� �������
   pos.exists=PositionSelect(_Symbol);
//--- ���� ������� ����, ������� � ��������
   if(pos.exists)
     {    
         if (StringGetCharacter(mask,0)=='1')
            {
                             pos.time=(datetime)PositionGetInteger(POSITION_TIME);
                             pos.total_deals=CurrentPositionTotalDeals();             
            }                            
         if (StringGetCharacter(mask,1)=='1')        pos.symbol=PositionGetString(POSITION_SYMBOL);                 
         if (StringGetCharacter(mask,2)=='1')        pos.magic=PositionGetInteger(POSITION_MAGIC);                  
         if (StringGetCharacter(mask,3)=='1')        pos.comment=PositionGetString(POSITION_COMMENT);               
         if (StringGetCharacter(mask,4)=='1')        pos.swap=PositionGetDouble(POSITION_SWAP);                      
         if (StringGetCharacter(mask,5)=='1')        pos.commission=PositionGetDouble(POSITION_COMMISSION);          
         if (StringGetCharacter(mask,6)=='1')
            {
                             pos.time=(datetime)PositionGetInteger(POSITION_TIME);
                             pos.first_deal_price=CurrentPositionFirstDealPrice();
            }                                 
         if (StringGetCharacter(mask,7)=='1')        pos.price=PositionGetDouble(POSITION_PRICE_OPEN);               
         if (StringGetCharacter(mask,8)=='1')        pos.current_price=PositionGetDouble(POSITION_PRICE_CURRENT);    
         if (StringGetCharacter(mask,9)=='1')
            {
                             pos.time=(datetime)PositionGetInteger(POSITION_TIME);
                             pos.last_deal_price=CurrentPositionLastDealPrice();           
            }                        
         if (StringGetCharacter(mask,10)=='1')       pos.profit=PositionGetDouble(POSITION_PROFIT);                  
         if (StringGetCharacter(mask,11)=='1')       pos.volume=PositionGetDouble(POSITION_VOLUME);                  
         if (StringGetCharacter(mask,12)=='1')
            {
                             pos.time=(datetime)PositionGetInteger(POSITION_TIME);
                             pos.initial_volume=CurrentPositionInitialVolume();          
            }                           
         if (StringGetCharacter(mask,13)=='1')       pos.sl=PositionGetDouble(POSITION_SL);                          
         if (StringGetCharacter(mask,14)=='1')       pos.tp=PositionGetDouble(POSITION_TP);                          
         if (StringGetCharacter(mask,15)=='1')       pos.time=(datetime)PositionGetInteger(POSITION_TIME);           
         if (StringGetCharacter(mask,16)=='1')       pos.duration=CurrentPositionDuration(SECONDS);                  
         if (StringGetCharacter(mask,17)=='1')       pos.id=PositionGetInteger(POSITION_IDENTIFIER);                 
         if (StringGetCharacter(mask,18)=='1')       pos.type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); 
        
     }
//--- ���� ������� ���, ������� ���������� ������� �������
   else
      ZeroPositionProperties();
  }
  
  PositionSys::PositionSys(void) //����������� ������
   {
   
   }
  PositionSys::~PositionSys(void) //���������� ������
   {
   
   }