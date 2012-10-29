//+------------------------------------------------------------------+
//|                                                _isDivergence.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

//------- ���������� ���������� ������ -------------------------------------+
int depthMACD = 9;
double minPriceForDiv[3][2]; //[��][0] - ��������, [��][1] - ����� ����
double maxPriceForDiv[3][2]; //[��][0] - ��������, [��][1] - ����� ����

//------- ������������� ������� �����������---------------------------------+
void InitExtremums(int index)
{
 maxPriceForDiv[index][1] = iHighest(NULL, aTimeframe[index,0], MODE_HIGH, depthMACD, 0); 
 minPriceForDiv[index][1] = iLowest(NULL, aTimeframe[index,0], MODE_LOW, depthMACD, 0);
 maxPriceForDiv[index][0] = iHigh(NULL, aTimeframe[index,0], maxPriceForDiv[index][1]); // ������� ������������ ���� �� ��������� 15 ����� (������ �� ���� �������)
 minPriceForDiv[index][0] = iLow(NULL, aTimeframe[index,0], minPriceForDiv[index][1]); // ������� ����������� ���� �� ��������� 15 ����� (������ �� ���� �������)
 
 int qnt = aDivergence[index][0][0];
 minMACD[index][0] = aDivergence[index][1][1]; minMACD[index][1] = aDivergence[index][1][3];
 maxMACD[index][0] = aDivergence[index][1][1]; maxMACD[index][1] = aDivergence[index][1][3];
 
 for (int i = 2; i < qnt; i++) // �������� �� ������� MACD
 {
  if (minMACD[index][0] > aDivergence[index][i][1])
   {
    minMACD[index][0] = aDivergence[index][i][1];
    minMACD[index][1] = aDivergence[index][i][3];
   }
  if (maxMACD[index][0] < aDivergence[index][i][1])
   {
    maxMACD[index][0] = aDivergence[index][i][1];
    maxMACD[index][1] = aDivergence[index][i][3];
   }
 }
 return;
}


//----------��������� ������ ����������� MACD -----------------
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

//------ ���������� ����������� -----------------------------------+
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
 
 // ����� ���� � ������������ ����� �� 15-100 �����
 int maxPriceBarNumber 
         = iHighest(NULL, timeframe, MODE_HIGH, depthDiv - depthMACD + 1, depthMACD);
 // ����� ���� � ����������� ����� �� 15-100 ��������� �����
 int minPriceBarNumber
          = iLowest(NULL, timeframe, MODE_LOW, depthDiv - depthMACD + 1, depthMACD);

 double maxPrice = 
      iHigh(NULL, timeframe, maxPriceBarNumber); // ������� ������������ ���� �� 15-100 ��������� �����
 double minPrice = 
      iLow(NULL, timeframe, minPriceBarNumber); // ������� ����������� ���� �� 15-100 ��������� �����

 if (maxPriceForDiv[index][0] > maxPrice + differencePrice) // �� ��������� 15-�� ����� ���� ���� ��������� �� 15-100
 {
  //Alert("�� ��������� 15-�� ����� ���� ���� ��������� �� 15-100, ����� ���� ", maxPriceForDiv[index][1]);
  if (ExtremumMACD > 0) // ��������� ���������� ��������� MACD
  {
   if (maxMACD[index][0] - differenceMACD > aDivergence[index][1][1]) // ��������� �������� MACD ������(����� � ����) ����������� ���������
   {
    i = 2;
    while (aDivergence[index][i][3] < maxMACD[index][1]) // ���� �� ���� �����������, ���������� ������ ����� � ������� ����������� ���������
    {
     if (aDivergence[index][i][4] < 0) // ���� ������������� MACD ����� ��������������
     {
      openPlace = "����������� �� " + timeframe + "-�������� �� �� MACD ���� ";
      barsCountToBreak[index][0] = 0;
      //Alert("trendDirection[",index,"][0]",trendDirection[index][0]);
      return(-1); // ����������� ������, ���� �������, ����������� ���� (��������)
     } 
     i++;
    } // close while
   } // 
  } // close ��������� ���������� ��������� MACD
 }
 
 if (minPriceForDiv[index][0] < minPrice - differencePrice) // �� ��������� 10-�� ����� ���� ���� �������� �� 10-100
 {
  if (ExtremumMACD < 0) // ��������� ���������� �������� MACD
  {
   if (minMACD[index][0] + differenceMACD < aDivergence[index][1][1]) // ��������� ������� MACD ������(����� � ����) ����������� ��������
   {
    i = 2;
    while (aDivergence[index][i][3] < minMACD[index][1])// ���� �� ���� �����������, ���������� ������ ����� � ������� ����������� ��������
    {
     if (aDivergence[index][i][4] > 0) // ���� ������������� MACD ����� ��������������
     {
      openPlace = "����������� �� " + timeframe + "-�������� �� �� MACD ����� ";
      barsCountToBreak[index][0] = 0;
      return(1); // ����������� �����, ���� ����, ����������� ����� (�����)
     } 
     i++;
    } // close while 
   } 
  } // close ��������� ���������� �������� MACD
 }
 
 return(0);
}