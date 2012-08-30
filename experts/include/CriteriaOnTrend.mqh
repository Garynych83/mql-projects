//+------------------------------------------------------------------+
//|                                              CriteriaOnTrend.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int CriteriaOnTrend()
{
  Current_fastEMA = iMA(NULL, Elder_Timeframe, jr_EMA1, 0, 1, 0, 0);
  Current_slowEMA = iMA(NULL, Elder_Timeframe, jr_EMA2, 0, 1, 0, 0);
  CurrentMACD = iMACD(NULL, Elder_Timeframe, eldFastMACDPeriod, eldSlowMACDPeriod, 9, PRICE_CLOSE, MODE_MAIN, 0);
  
  bool MACD_down;
  bool MACD_up;
  int i;
  
  if  (-MACD_channel_1H < CurrentMACD && CurrentMACD < MACD_channel_1H)
   {
    return (0);
   }
  
  if (Current_fastEMA < (Current_slowEMA - deltaEMAtoEMA*Point))
      {
      //Alert("Open order ", "����� ���� ");  ��������� 15-�������
       MACD_down = true; // �������� ������ �� MACD
       for (i = 0; i < depthMACD - 1; i++)
       {
         if (MACD_15M[i] > MACD_15M[i+1]) {
         MACD_down = false;  // ��� �� ������
         }
       }
       if (MACD_down && MACD_15M[i-1] > 0) // MACD ����� ������ � ������������� ��������- ���� ������������ ����
       {
        //Alert("����� ����  �������� MACD ������!! ������� ��������  Current_EMA_13 ", Current_EMA_13, " Current_EMA_20 ", Current_EMA_20, " Prev_EMA_13 ", Prev_EMA_13);
        maxPrice = iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, depthPrice, 0)); // ������� ������������ ���� �� ��������� 5-� �����
        //Alert(" ������� �������� ", maxPrice);
        //for (int imax = 0; imax < depthPrice; imax++) {Alert("�������� �� ", imax, "-� ���� ", High[imax], "  Time=", TimeHour(Time[imax]),":", TimeMinute(Time[imax]));}
        //Alert("��������� �������� ", maxPrice, " ", wantToOpen, " ", wantToClose);
       }
       return (-1);
      }
    
   if (Current_fastEMA > (Current_slowEMA + deltaEMAtoEMA*Point))
      {
       //Alert("Open order ", "����� ����� ", "MACD_1H ", MACD_1H, " MACD_channel ", MACD_channel);
       MACD_up = true;
       for (i = 0; i < depthMACD - 1; i++)
       {
         if (MACD_15M[i] < MACD_15M[i+1])
         {
         MACD_up = false;
         }
       }  
      if (MACD_up && MACD_15M[i-1] < 0) // MACD ����� ����� � ������������� ��������- ���� ����������� ����
       {
        //Alert(" ����� ����� �������� MACD ������!! ������� �������. Current_EMA_13 ", Current_EMA_13, " Current_EMA_20 ", Current_EMA_20, " Prev_EMA_13 ", Prev_EMA_13);
        minPrice = iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, depthPrice, 0)); // ������� ����������� ���� �� ��������� 5-� �����
        //Alert(" ������� ������� ", minPrice);
        //for (int imin = 0; imin < depthPrice; imin++) { Alert("������� �� ", imin, "-� ���� ", Low[imin], "  Time=", TimeHour(Time[imin]), ":", TimeMinute(Time[imin]));}
        //Alert("��������� ������� ", minPrice, " ", wantToOpen, " ", wantToClose);
       }
       return (1);
      }
      
   return (0);
}


