//+------------------------------------------------------------------+
//|                                                _isDivergence.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

int _isDivergence(int timeframe)
{
 int index;
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
      Alert("_isDivergence: �� �������� � �����������");
      return(false);
 }
 
 int qnt = aDivergence[index][0][0];
 int i;
 int ExtremumMACD = isMACDExtremum(timeframe, divergenceFastMACDPeriod, divergenceSlowMACDPeriod);
 
 /*
 // ����� ���� � ������������ ����� �� ���� �������
 int maxPriceBarNumber = iHighest(NULL, aTimeframe[index,0], MODE_HIGH, depthDiv, 0);
 // ����� ���� � ����������� ����� �� ���� ������� 
 int minPriceBarNumber = iLowest(NULL, aTimeframe[index,0], MODE_LOW, depthDiv, 0);
 
 // ����� ���� � ������������ ����� �� ���������� �������
 maxPriceBarNumber 
         = iHighest(NULL, aTimeframe[index,0], MODE_HIGH, depthDiv - maxPriceBarNumber, maxPriceBarNumber + 1);
 // ����� ���� � ����������� ����� �� ���������� �������
 minPriceBarNumber
          = iLowest(NULL, aTimeframe[index,0], MODE_LOW, depthDiv - minPriceBarNumber, minPriceBarNumber + 1);
 */

 // ����� ���� � ������������ ����� �� 15-100 �����
 int maxPriceBarNumber 
         = iHighest(NULL, timeframe, MODE_HIGH, depthDiv - 8, 9);
 // ����� ���� � ����������� ����� �� 15-100 ��������� �����
 int minPriceBarNumber
          = iLowest(NULL, timeframe, MODE_LOW, depthDiv - 8, 9);

 double maxPrice = 
      iHigh(NULL, timeframe, maxPriceBarNumber); // ������� ������������ ���� �� 15-100 ��������� �����
 double minPrice = 
      iLow(NULL, timeframe, minPriceBarNumber); // ������� ����������� ���� �� 15-100 ��������� �����

 if (maxPriceForDiv[index][0] > maxPrice) // �� ��������� 15-�� ����� ���� ���� ��������� �� 15-100
 {
  //Alert("�� ��������� 15-�� ����� ���� ���� ��������� �� 15-100, ����� ���� ", maxPriceForDiv[index][1]);
  if (ExtremumMACD > 0) // ��������� ���������� ��������� MACD
  {
   //Alert("��������� ���������� ��������� MACD ", aDivergence[index][1][3]);
   if (maxMACD[index][0] > aDivergence[index][1][1]) // ��������� �������� MACD ������(����� � ����) ����������� ���������
   {
    i = 2;
    while (aDivergence[index][i][3] < maxMACD[index][1]) // ���� �� ���� �����������, ���������� ������ ����� � ������� ����������� ���������
    {
     if (aDivergence[index][i][4] < 0) // ���� ������������� MACD ����� ��������������
     {
      /*
      Alert (" ����������� ������: ������������� ���������  ", aDivergence[index][i][1]
      , " ����� ���� " , aDivergence[index][i][3],  " ����� "
      , TimeDay(iTime(NULL, timeframe, aDivergence[index][i][3])),":"
      , TimeHour(iTime(NULL, timeframe, aDivergence[index][i][3])),":"
      , TimeMinute(iTime(NULL, timeframe, aDivergence[index][i][3])));
      
      Alert(" ����� ����������� ��������� MACD " , maxMACD[index][0], " "
      , TimeDay(iTime(NULL, timeframe, maxMACD[index][1])),":"
      , TimeHour(iTime(NULL, timeframe, maxMACD[index][1])),":"
      , TimeMinute(iTime(NULL, timeframe, maxMACD[index][1])));
      
      Alert(" ����������(����������) �������� ���� " , maxPrice, " "
      , " ����� ���� � ������������ ����� �� ���������� ������� ", maxPriceBarNumber);
      
      Alert(" ��������� ��������� MACD ", aDivergence[index][1][1]
      , " ����� ���� " , aDivergence[index][1][3],  " ����� "
      , TimeDay(iTime(NULL, timeframe, aDivergence[index][1][3])),":"
      , TimeHour(iTime(NULL, timeframe, aDivergence[index][1][3])),":"
      , TimeMinute(iTime(NULL, timeframe, aDivergence[index][1][3])));
      
      Alert(" ��������� �������� ���� " , maxPriceForDiv[index][0], " ");
      */
      openPlace = "����������� �� " + timeframe + "-�������� �� �� MACD ���� ";
      barsCountToBreak[index][0] = 0;
      //Alert("trendDirection[",index,"][0]",trendDirection[index][0]);
      return(-1); // ����������� ������, ���� �������, ����������� ���� (��������)
     } 
     i++;
    } // close while
   } // 
   //waitForMACDMaximum[index] = false;
  } // close ��������� ���������� ��������� MACD
 }
 
 if (minPriceForDiv[index][0] < minPrice) // �� ��������� 10-�� ����� ���� ���� �������� �� 10-100
 {
  if (ExtremumMACD < 0) // ��������� ���������� �������� MACD
  {
   if (minMACD[index][0] < aDivergence[index][1][1]) // ��������� ������� MACD ������(����� � ����) ����������� ��������
   {
    i = 2;
    while (aDivergence[index][i][3] < minMACD[index][1])// ���� �� ���� �����������, ���������� ������ ����� � ������� ����������� ��������
    {
     if (aDivergence[index][i][4] > 0) // ���� ������������� MACD ����� ��������������
     {
      /*
      Alert (" ����������� �����: ������������� ���������,  ", aDivergence[index][i][1]
      , " ����� ���� " , aDivergence[index][i][3], " ����� "
      , TimeDay(iTime(NULL, timeframe, aDivergence[index][i][3])),":"
      , TimeHour(iTime(NULL, timeframe, aDivergence[index][i][3])),":"
      , TimeMinute(iTime(NULL, timeframe, aDivergence[index][i][3])));
      
      Alert ( " ����� ����������� �������� ", minMACD[index][0], " "
      , TimeDay(iTime(NULL, timeframe, minMACD[index][1])),":"
      , TimeHour(iTime(NULL, timeframe, minMACD[index][1])),":"
      , TimeMinute(iTime(NULL, timeframe, minMACD[index][1])));
      
      Alert(" ����������(����������) ������� ���� " , minPrice, " "
      , " ����� ���� � ����������� ����� �� ���������� ������� ", minPriceBarNumber);
      
      Alert ( " ��������� ��������� MACD ", aDivergence[index][1][1]
      , " ����� ���� ", aDivergence[index][1][3],  " ����� "
      , TimeDay(iTime(NULL, timeframe, aDivergence[index][1][3])),":"
      , TimeHour(iTime(NULL, timeframe, aDivergence[index][1][3])),":"
      , TimeMinute(iTime(NULL, timeframe, aDivergence[index][1][3])));
      
      Alert(" ��������� ������� ���� " , minPriceForDiv[index][0], " ");
      */
      openPlace = "����������� �� " + timeframe + "-�������� �� �� MACD ����� ";
      barsCountToBreak[index][0] = 0;
      return(1); // ����������� �����, ���� ����, ����������� ����� (�����)
     } 
     i++;
    } // close while 
   } 
   //waitForMACDMinimum[index] = false;
  } // close ��������� ���������� �������� MACD
 }
 
 return(0);
}