//+------------------------------------------------------------------+
//|                                      DesepticonBreakthrough2.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int DesepticonBreakthrough2(int iDirection, int timeframe)
{
 int i;
 total=OrdersTotal();
 
 if (iDirection < 0)
 {
  // ������� �� Bid
  if (!ExistPositions("", -1, _MagicNumber)) // ���� �������� ������� -> ���� ����������� ��������
  {
   //if (Ask > iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
   if (OpenPosition(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
   {
    return (1);
   }  
   else // ������ ��������
    return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_BUY)   // ������� ������� ������� BUY
      {
       ClosePosBySelect(Bid); // ��������� ������� BUY
       Alert("DesepticonBreakthrough2: ������� ����� BUY" );
       if (OpenPosition(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
       {
        return (1);
       }  
       else // ������ ��������
        return(-1);
      }
     }
    } 
   } 
  }
 }
      
 if (iDirection > 0)
 {
  // �������� �� Ask
  if (!ExistPositions("", -1, _MagicNumber)) // ���� �������� ������� -> ���� ����������� ��������
  { 
   //if (Bid < iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
    if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
    {
     return (1);
    }
    else // ������ ��������
     return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_SELL) // ������� �������� ������� SELL
      {
       ClosePosBySelect(Ask); // ��������� ������� SELL
       Alert("DesepticonBreakthrough2: ������� ����� SELL" );
        if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
        {
         return (1);
        }
        else // ������ ��������
         return(-1);
      }
     }
    }
   }  
  }
 }
 return (0);
}

////

/////


int DesepticonBreakthroughTest(int iDirection, int timeframe)
{
 int i;
 total=OrdersTotal();
 
 if (iDirection < 0)
 {
  // ������� �� Bid
  if (!ExistPositions("", -1, _MagicNumber)) // ���� �������� ������� -> ���� ����������� ��������
  {
   //if (Ask > iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
   if (OpenPositionTest(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
   {
    return (1);
   }  
   else // ������ ��������
    return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_BUY)   // ������� ������� ������� BUY
      {
       OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet); // ��������� ������� BUY
       Alert("DesepticonBreakthrough2: ������� ����� BUY" );
       //if (Ask > iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
       if (OpenPositionTest(NULL, OP_SELL, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
       {
        return (1);
       }  
       else // ������ ��������
        return(-1);
      }
     }
    } 
   } 
  }
 }
      
 if (iDirection > 0)
 {
  // �������� �� Ask
  if (!ExistPositions("", -1, _MagicNumber)) // ���� �������� ������� -> ���� ����������� ��������
  { 
   //if (Bid < iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
    if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
    {
     return (1);
    }
    else // ������ ��������
     return(-1);
  }
  else
  {
   for (i=0; i<total; i++)
   {
    if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES))
    {
     if (OrderMagicNumber() == _MagicNumber)  
     {
      if (OrderType()==OP_SELL) // ������� �������� ������� SELL
      {
       OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet); // ��������� ������� SELL
       Alert("DesepticonBreakthrough2: ������� ����� SELL" );
       //if (Bid < iMA(NULL, Elder_Timeframe, eld_EMA2, 0, 1, 0, 0))
        if (OpenPosition(NULL, OP_BUY, openPlace, timeframe, 0, 0, _MagicNumber) > 0)
        {
         return (1);
        }
        else // ������ ��������
         return(-1);
      }
     }
    }
   }  
  }
 }
 return (0);
}