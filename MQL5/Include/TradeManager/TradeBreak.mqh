//+------------------------------------------------------------------+
//|                                  BIG_BROTHER_IS_WATCHING_YOU.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <TradeManager\PositionArray.mqh>  // ���������� ����� �� ������ � ���������

 // ����� ��������� ��������
 class TradeBreak 
  {
   private:
    double _current_profit;     // ������� ������� 
    double _current_drawdown;   // ������� �������� �������
    double _min_profit;         // ���������� ���������� �������
    double _max_drawdown;       // ����������� ���������� ��������
    double _max_balance;        // ������������ ������
    CPositionArray *_positionsHistory; //������ �������, ����������� � �������    
   public:
    //---- �������� ��������� ������� ������ 
    
    // ���������� ������ � ������� ������� � ��������
    // ���������� true, ���� �� ���� �� ���������� �� �������� ���������� �����
    bool   UpdateData (CPositionArray * positionsHistory);
    // ���������� ������� �������
    double GetCurrentProfit() { return(_current_profit);};
    // ����������  ������� �������� �� �������
    double GetCurrentDrawdown() { return(_current_drawdown); };  
   TradeBreak (double min_profit,double max_drawdown):
   _min_profit(min_profit),
   _max_drawdown(max_drawdown),
   _current_profit(0),
   _current_drawdown(0),
   _max_balance(0)
   {
   }; // ����������� ������ 
  };
  
  //---- �������� ������� ������
  
  // ��������� ������ � ������� ������� � ��������
  bool TradeBreak::UpdateData(CPositionArray * positionsHistory)
   {
    int index;  // ������ ������� �� �����
    int length = positionsHistory.Total(); // ����� ����������� ������� �������
    CPosition *pos; // ��������� �� ������� �������
    // �������� �� ���� ������� � ��������� ������� �������
    for (index = 0; index<length;index++)
     {
      // ��������� ��������� �� ������� ������� �� �������
      pos = _positionsHistory.At(index);
      // �������� ������� ������� 
      _current_profit = _current_profit + pos.getPosProfit();
      //���� ������ �������� ������� ������������ ������
      if (_current_profit > _max_balance)  
        {
          // �� �������������� ���
          _max_balance = _current_profit;
        }
      else 
        {
        //���� ���������� ������ ��������, ��� ����
         if ((_max_balance-_current_profit) > _current_drawdown) 
          {
           //�� ���������� ����� �������� �������
            _current_drawdown = _max_balance-_current_profit;  
          }
        }  
     }
     // ���� ������� ������� ������ ���������� ����������
     // ��� ���� ������� �������� ������ ����������� ����������
     if (_current_profit < _min_profit || _current_drawdown > _max_drawdown)
      return false; 
    return true;
   }