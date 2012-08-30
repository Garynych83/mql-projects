//+------------------------------------------------------------------+
//|                                            CriteriaOnFlatRSI.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
void CriteriaOnFlatRSI()
{
   bool MACD_down;
   bool MACD_up;
   int i;
   
   RSI = iRSI(NULL,Elder_Timeframe,periodRSI,PRICE_CLOSE,0);

   if  (-MACD_channel < MACD_1H && MACD_1H < MACD_channel)
   {
    // ������ MACD
    if (RSI < 25) // RSI �����, ����������� - ����� ��������
    {
     MACD_up = true;
     for (i = 0; i < depthMACD - 1; i++)
     {
      if (MACD_15M[i] < MACD_15M[i+1])
      {
       MACD_up = false;
      }
     }  
     if (MACD_up && MACD_15M[i-1] < 0) // MACD ����� ����� � ������������� ��������
     {
      minPrice = iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, depthPrice, 0));
      return;
     }     
    }
    
    if (RSI > 75) // RSI �������, ����������� - ����� ���������
    {
     MACD_down = true; // �������� ������ �� MACD
     for (i = 0; i < depthMACD - 1; i++)
     {
      if (MACD_15M[i] > MACD_15M[i+1])
      {
       MACD_down = false;  // ��� �� ������
      }
     }
     if (MACD_down && MACD_15M[i-1] > 0) // MACD ����� ������ � ������������� ��������- ���� ������������ ����
     {
      maxPrice = iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, depthPrice, 0));
      return;
     }     
    }
   } // Close  ������ MACD
   return;
}


