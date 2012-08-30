//+------------------------------------------------------------------+
//|                                         DesepticonDivergence.mq4 |
//|                      Copyright � 2011, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
int DesepticonDivergence()
  {
   if( isNewBar() ) 
   { 
    InitDivergenceArray(Jr_Timeframe, frameIndex);
    InitExtremums(frameIndex);
    
    if (waitForMACDMaximum[frameIndex] || waitForMACDMinimum[frameIndex]) // ��� ���� ��������� �� MACD
     {
      //Alert ("���� �����������");
      wantToOpen[frameIndex] = isDivergence();
      return (wantToOpen[frameIndex]);
     }
   } // ��������� ������ ����������� MACD
   
   //total=OrdersTotal();
   //if (total < 1)
   //{ // ���� �������� ������� -> ���� ����������� ��������
    if (wantToOpen[frameIndex] == 0) // ��� �� ����� ��� �����������
    {
     if (!waitForMACDMaximum[frameIndex])
     {
      if (Ask > maxPriceForDiv[frameIndex]) // �������� ����� ��������� ����
      {
       waitForMACDMaximum[frameIndex] = true;
      }
     } 
     if (!waitForMACDMinimum[frameIndex])
     {
      if (Bid < minPriceForDiv[frameIndex]) // �������� ����� ��������� ����
      {
       waitForMACDMinimum[frameIndex] = true;
      }
     }  
    } //close ��� �� ����� ��� �����������
    return (wantToOpen[frameIndex]);
   //} 
  }