//+------------------------------------------------------------------+
//|                                        EntranceExtremumPrice.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int EntranceExtremumPrice()
{
     if (maxPrice > 0) // ���� �������� ��������� ������� �� Bid
      {
       if (maxPrice <= (Bid + deltaPrice*Point)) // ������� ���� ��������� ��������
       {
        if (total < 1) // ���� �������� ������� -> ���� ����������� ��������
        { 
         Opening(OP_SELL);
         return (1);
        }
        else
        {
         OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
         if (OrderType()==OP_BUY) // ������� ������� ������� BUY
         {
          OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // ��������� ������� BUY
          Opening(OP_SELL);
          return (1);
         }
        }
       }
      }
     
    if (minPrice > 0) // �������� �� Ask
      {
       if (minPrice >= (Ask - deltaPrice*Point)) // ������� ���� ������� �������
       {
        if (total < 1) // ���� �������� ������� -> ���� ����������� ��������
        { 
         Opening(OP_BUY);
         return (1);
        }
        else
        {
         OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
         if (OrderType()==OP_SELL) // ������� �������� ������� SELL
         {
          OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // ��������� ������� SELL
          Opening(OP_BUY);
          return (1);
         }
        }
       }
      }
  return (0);
}