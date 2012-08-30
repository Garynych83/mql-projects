//+------------------------------------------------------------------+
//|                                          InitDivergenceArray.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

void InitDivergenceArray(int timeframe)
{
 int index;
 int fastPeriod = divergenceFastMACDPeriod;
 int slowPeriod = divergenceSlowMACDPeriod;
 switch(timeframe)
 {
  case PERIOD_D1:
      index = 0;
      break;
  case PERIOD_H1:
      index = 1;
      break;
  case PERIOD_M5:
      index = 2;
      break;
  default:
      Alert("InitDivergenceArray: �� �������� � �����������");
      return(false);
 }  
 
   // �������� ������ ���� ������� �����������
   double tmpArray[60][5];
   ArrayInitialize(tmpArray, 0);
   
   for (int m = 0; m < 60; m++)
      for (int n = 0; n < 5; n++)
         aDivergence[index][m][n] = tmpArray[m][n];
   
   // ��������� ������ ���� ������ ����������
   int cnt = 0; // ������� �����������
   for (int bar_num = 0; bar_num < depthDiv; bar_num++) // �������� �� ����� 
   {
    int ExtremumMACD = isMACDExtremum(timeframe, fastPeriod, slowPeriod, bar_num);
    
    if (ExtremumMACD > 0) // ���� ���� �������� �� MACD
    { 
     cnt++;
     aDivergence[index][cnt][1] = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, bar_num+2); //M2; // �������� ���������� ��������� MACD
     //aDivergence[cnt][2] = iHigh(NULL, Jr_Timeframe, bar_num+2); // �������� ���� � ��������� ��������� //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
     aDivergence[index][cnt][3] = bar_num+2; // ����� ���� � ����������
     aDivergence[index][cnt][4] = 1; // ��� ��������� ��������  
    }
    
    if (ExtremumMACD < 0) 
    {
     cnt++;
     aDivergence[index][cnt][1] = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, bar_num+2);//M2; // �������� ���������� �������� MACD
     //aDivergence[cnt][2] = iLow(NULL, Jr_Timeframe, bar_num+2); // ������� ���� � ��������� ��������� //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
     aDivergence[index][cnt][3] = bar_num+2; // ����� ���� � ���������
     aDivergence[index][cnt][4] = -1; // ��� ��������� �������  
    }
   }
   aDivergence[index][0][0] = cnt; // ����� ���������� �����������
}