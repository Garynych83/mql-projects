//+------------------------------------------------------------------+
//|                                               ReplayPosition.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "TradeManagerEnums.mqh"
#include "PositionOnPendingOrders.mqh"
#include "PositionArray.mqh"
#include "TradeManager.mqh"
//+------------------------------------------------------------------+
//| �����-��������� ��� �������� � ������ � ���������                |
//+------------------------------------------------------------------+

 class ReplayPosition
  { 
   private:
    CTradeManager ctm;  //�������� ����� 
 //   CPositionArray _positionsToReplay; //������ �������
    ReplayPos _posToReplay[];   //������������ ������ ��� ��������� ������� �� �������
   public: 
    void AddToArray (ReplayPos * new_pos); //����� ��������� ����� �������
    void DeletePosition(uint index);      //������� ������� �� �������    
    void CustomPosition (int stopLoss,double lot);   //��������� �� ������� � �������� ������� ������� ���������� ������ �������    
  };
//+------------------------------------------------------------------+
//| ��������� ������� � ������ �� �������                            |
//+------------------------------------------------------------------+  

void ReplayPosition::AddToArray(ReplayPos *new_pos)
 {
   ArrayResize(_posToReplay,ArraySize(_posToReplay)+1); //�������� ������ ������� �� �������
   _posToReplay[ArraySize(_posToReplay)-1].price_close = new_pos.price_close;
   _posToReplay[ArraySize(_posToReplay)-1].price_open  = new_pos.price_open;
   _posToReplay[ArraySize(_posToReplay)-1].status      = new_pos.status;
   _posToReplay[ArraySize(_posToReplay)-1].type        = new_pos.type;   
   _posToReplay[ArraySize(_posToReplay)-1].symbol      = new_pos.symbol; 
   _posToReplay[ArraySize(_posToReplay)-1].profit      = new_pos.profit;

 }
//+------------------------------------------------------------------+
//| ������� ������� �� �������                                       |
//+------------------------------------------------------------------+  
 
 void ReplayPosition::DeletePosition(uint index)
  { 
   uint i;
   uint total = ArraySize(_posToReplay); //��������� ����� �������
   //�������  �� ������� �������� ����� ����������
   for(i=index+1;i<total;i++)
    {
   _posToReplay[i-1].price_close = _posToReplay[i].price_close ;
   _posToReplay[i-1].price_open  = _posToReplay[i].price_open;
   _posToReplay[i-1].status      = _posToReplay[i].status;
   _posToReplay[i-1].type        = _posToReplay[i].type;   
   _posToReplay[i-1].status      = _posToReplay[i].status;   
   _posToReplay[i-1].profit      = _posToReplay[i].profit;         
    }
   //��������� ������ �� �������
   ArrayResize(_posToReplay,total-1);
  }
   
//+------------------------------------------------------------------+
//| ��������� �� ������� ������� � ���������\������ �������          |
//+------------------------------------------------------------------+
  void ReplayPosition::CustomPosition(int stopLoss,double lot)
   {

   uint index;
   uint total = ArraySize(_posToReplay);       //������� ����� �������
   double tp; //����������
   double sl; //���� ����
   double price;
   CPosition *pos;                           //��������� �� ������� 

   for (index=0;index<total;index++)         //��������� �� ������� �������
    {

    if (_posToReplay[index].status == POSITION_STATUS_MUST_BE_REPLAYED)  //���� ������� ������� �������� �� ����� � Loss
     {
      //���� ���� ���������� �� Loss
      if ((SymbolInfoDouble(_posToReplay[index].symbol,SYMBOL_ASK) - _posToReplay[index].price_close ) <= _posToReplay[index].profit)
       {
         _posToReplay[index].status =  POSITION_STATUS_READY_TO_REPLAY;  //��������� ������� � ����� ���������� � ��������
       } 
     }
    else if (_posToReplay[index].status == POSITION_STATUS_READY_TO_REPLAY) //���� ������� ������ � ��������
     {
      if (SymbolInfoDouble(_posToReplay[index].symbol,SYMBOL_BID) >= _posToReplay[index].price_close ) //���� ���� ���������� �� ���� ���� �������� �������
       {
        //  Alert("TYPE = ",GetNameOP(_posToReplay[index].type));
          switch (_posToReplay[index].type) //�������� ��� ���� ��� �������� �������
           {
             case OP_BUY:
             
             price = SymbolInfoDouble(_posToReplay[index].symbol,SYMBOL_ASK);
             Comment("��� = BUY ���� = ",price, 
                     "; ���� �������� = ",_posToReplay[index].price_open, 
                     " ���� �������� = ", _posToReplay[index].price_close,
                     " ������ ������� = ",_posToReplay[index].profit,
                     " ���� � ����� = ", TimeToString(TimeCurrent())
                     
                     );
             break;
             case OP_SELL:
             price = SymbolInfoDouble(_posToReplay[index].symbol,SYMBOL_BID);
             Comment("��� = SELL ���� = ",price, 
                     "; ���� �������� = ",_posToReplay[index].price_open, 
                     " ���� �������� = ", _posToReplay[index].price_close,
                     " ������ ������� = ",_posToReplay[index].profit,
                     " ���� � ����� = ", TimeToString(TimeCurrent())                     
                     );
             break;
           }
           
    
         tp = NormalizeDouble( MathMax( SymbolInfoInteger( _posToReplay[index].symbol, SYMBOL_TRADE_STOPS_LEVEL )*_Point,
               MathAbs( price-_posToReplay[index].price_open ) / _Point ), SymbolInfoInteger( _posToReplay[index].symbol, SYMBOL_DIGITS));
                     
         ctm.OpenMultiPosition(_posToReplay[index].symbol,_posToReplay[index].type,lot,stopLoss,tp,0,0,0); //��������� �������
         
        Alert("HELL");
         
         DeletePosition(index); //� ������� � �� �������  
         total = ArraySize(_posToReplay);
       }      
     }
    }    
   }