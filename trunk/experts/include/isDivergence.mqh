//+------------------------------------------------------------------+
//|                                                 isDivergence.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

int isDivergence()
{
 int qnt = aDivergence[frameIndex][0][0];
 int i;
 int ExtremumMACD = isMACDExtremum(Jr_Timeframe, jrFastMACDPeriod, jrSlowMACDPeriod, 0);
 
 if (waitForMACDMaximum[frameIndex]) 
 {
  //Alert (" ���� ��������� MACD ");
  if (ExtremumMACD > 0) // ��������� ���������� ��������� MACD
  {
   //Alert (" ��������� ���������� ��������� MACD ", ExtremumMACD);
   if (maxMACD[frameIndex][0] > aDivergence[frameIndex][1][1]) // �������� ���������� ��������� MACD ������ ����������� ���������
   {
    //for (i=2; i<aDivergence[0][0]; i++)
    i = 2;
    while (aDivergence[frameIndex][i][3] < maxMACD[frameIndex][1]) // ���� �� ���� �����������, ���������� ������ ����� � ������� ����������� ���������
    {
     //Alert (" ���� ������������� ��������� ", aDivergence[frameIndex][i][3], " ", minMACD[frameIndex][1], " ");
     //Alert (" ���� ������������� ��������� ", aDivergence[i][3], " ", maxMACD[1]);
     if (aDivergence[frameIndex][i][4] < 0) // ���� ������������� MACD ����� ��������������
     {
      waitForMACDMaximum[frameIndex] = false;
      waitForMACDMinimum[frameIndex] = false;
      
      Alert (" ����������� ������: ������������� ���������  ", aDivergence[frameIndex][i][1]
      , " ����� ���� " , aDivergence[frameIndex][i][3],  " ����� "
      , TimeDay(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])));
      
      Alert(" ����� ����������� ��������� MACD " , maxMACD[frameIndex][0], " "
      , TimeDay(iTime(NULL, Jr_Timeframe, maxMACD[frameIndex][1])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, maxMACD[frameIndex][1])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, maxMACD[frameIndex][1])));
      
      Alert(" ���������� �������� ���� " , aDivergence[frameIndex][i][2], " ");
      
      Alert(" ��������� ��������� MACD ", aDivergence[frameIndex][1][1]
      , " ����� ���� " , aDivergence[frameIndex][1][3],  " ����� "
      , TimeDay(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])));
      
      Alert(" ��������� �������� ���� " , aDivergence[frameIndex][1][2], " ");
      
      return(-1); // ����������� ������, ���� �������, ����������� ���� (��������)
     } 
     i++;
    } // close while
   } // 
   waitForMACDMaximum[frameIndex] = false;
  } // close ��������� ���������� ��������� MACD
 }
 
 if (waitForMACDMinimum[frameIndex])
 {
  //Alert (" ���� �������� MACD ", ExtremumMACD);
  if (ExtremumMACD < 0) // ��������� ���������� �������� MACD
  {
   //Alert (" ��������� ���������� �������� MACD ");
   if (minMACD[frameIndex][0] < aDivergence[frameIndex][1][1]) // �������� ���������� �������� MACD ������ ����������� ��������
   {
    // for (i=2; i<aDivergence[0][0]; i++)
    i = 2;
    while (aDivergence[frameIndex][i][3] < minMACD[frameIndex][1])// ���� �� ���� �����������, ���������� ������ ����� � ������� ����������� ��������
    {
     //Alert (" ���� ������������� ��������� ", aDivergence[frameIndex][i][3], " ", minMACD[frameIndex][1], " ");
     //Alert (" ���� ������������� ��������� ", aDivergence[i][3], " ", maxMACD[1]);
     if (aDivergence[frameIndex][i][4] > 0) // ���� ������������� MACD ����� ��������������
     {
      waitForMACDMaximum[frameIndex] = false;
      waitForMACDMinimum[frameIndex] = false;
      
      Alert (" ����������� �����: ������������� ���������,  ", aDivergence[frameIndex][i][1]
      , " ����� ���� " , aDivergence[frameIndex][i][3], " ����� "
      , TimeDay(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][i][3])));
      
      Alert ( " ����� ����������� �������� ", minMACD[frameIndex][0], " "
      , TimeDay(iTime(NULL, Jr_Timeframe, minMACD[frameIndex][1])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, minMACD[frameIndex][1])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, minMACD[frameIndex][1])));
      
      Alert(" ���������� ������� ���� " , aDivergence[frameIndex][i][2], " ");
      
      Alert ( " ��������� ���������  ", aDivergence[frameIndex][1][1], " ����� ���� "
      , aDivergence[frameIndex][1][3],  " ����� "
      , TimeDay(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])),":"
      , TimeHour(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])),":"
      , TimeMinute(iTime(NULL, Jr_Timeframe, aDivergence[frameIndex][1][3])));
      
      Alert(" ��������� ������� ���� " , aDivergence[frameIndex][1][2], " ");
      return(1); // ����������� �����, ���� ����, ����������� ����� (�����)
     } 
     i++;
    } // close while 
   } 
   waitForMACDMinimum[frameIndex] = false;
  } // close ��������� ���������� �������� MACD
 }
 
 return(0);
}