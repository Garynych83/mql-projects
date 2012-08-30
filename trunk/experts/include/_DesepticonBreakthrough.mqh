//+------------------------------------------------------------------+
//|                                       DesepticonBreakthrough.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int DesepticonBreakthrough(int iDirection, string openPlace, int timeframe)
{
    total=OrdersTotal();
    if (iDirection < 0 && trendDirection[frameIndex] < 0)
    {
     // ������� �� Bid
     //Alert("�������� ������, ���� ����-������ ����" );
     if (Bid < iLow(NULL, timeframe, 1) && Bid < iLow(NULL, timeframe, 2))     
     {
      if (total < 1) // ���� �������� ������� -> ���� ����������� ��������
      { 
       if (DesepticonOpening(OP_SELL, openPlace, timeframe) > 0)
            return (1);
       else // ������ ��������
            return(-1);
      }
      else
      {
       OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
       if (OrderMagicNumber() - _MagicNumber == Jr_Timeframe)  
       {
        if (OrderType()==OP_BUY)   // ������� ������� ������� BUY
        {
         OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // ��������� ������� BUY
         Alert("������� �����, �������� ����������" );
         if (DesepticonOpening(OP_SELL, openPlace,  timeframe) > 0)
            return(1);
         else     // ������ ��������
            return(-1);
        }
       }
      }
     }
    }
     
    if (iDirection > 0 && trendDirection[frameIndex] > 0)
    {
      // �������� �� Ask
      //Alert("������� ������, ���� ����-������ �����" );
     if (Ask > iHigh(NULL, timeframe, 1) && Ask > iHigh(NULL, timeframe, 2))
     {
      if (total < 1) // ���� �������� ������� -> ���� ����������� ��������
      { 
       if(DesepticonOpening(OP_BUY, openPlace, timeframe) > 0)
            return (1);
       else // ������ ��������
            return(-1);
      }
      else
      {
       OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
       if (OrderMagicNumber() - _MagicNumber == Jr_Timeframe)  
       {
        if (OrderType()==OP_SELL) // ������� �������� ������� SELL
        {
         OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // ��������� ������� SELL
         Alert("������� �����, �������� ����������" );
         if (DesepticonOpening(OP_BUY, openPlace, timeframe) > 0)
            return(1);
         else // ������ ��������
            return(-1);
        }
       }
      }
     }
    }
  return (0);
}