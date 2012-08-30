//+------------------------------------------------------------------+
//|                                         BreakthroughEntrance.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int BreakthroughEntrance()
{
    if (maxPrice > 0) // ���� �������� ���������
    {
     // ������� �� Bid
     //Alert("�������� ������, ���� ����-������ ����" );
     if (Bid < iLow(NULL, Jr_Timeframe, 1) && Bid < iLow(NULL, Jr_Timeframe, 2))     
     {
      if (total < 1) // ���� �������� ������� -> ���� ����������� ��������
        { 
         Opening(OP_SELL);
         return (1);
        }
        else
        {
         OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
         if (OrderType()==OP_BUY) // ������� �������� ������� SELL
         {
          OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // ��������� ������� SELL
          Alert("������� �����, �������� ����������" );
          Opening(OP_SELL);
          return(1);
         }
        }
     }
    }
     
    if (minPrice > 0)
    {
      // �������� �� Ask
      //Alert("������� ������, ���� ����-������ �����" );
     if (Ask > iHigh(NULL, Jr_Timeframe, 1) && Ask > iHigh(NULL, Jr_Timeframe, 2))
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
          Alert("������� �����, �������� ����������" );
          Opening(OP_BUY);
          return(1);
         }
        }
     }
    }
  return (0);
}