//+------------------------------------------------------------------+
//|                                        UpdateDivergenceArray.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

void UpdateDivergenceArray(int timeframe)
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
      Alert("UpdateDivergenceArray: �� �������� � �����������");
      return(false);
 }
 
 int qnt = aDivergence[index][0][0];
 int i; int j;
  
 for (i = 1; i <= qnt; i++) // �� ���� �����������
 {
  aDivergence[index][i][3]++; // ����� ������� ����� ���� �����������
 }
 
// --- ���������� ������ ���������� ---
 if (aDivergence[index][qnt][3] > depthDiv) // ���� ������� ��������� ���� �� ������� �������, ������� ���
 {
  for (i = 0; i < 5; i++)
   {
    aDivergence[index][qnt][i] = 0;
   }
  qnt--; // ���������� ����������� �����������
  aDivergence[index][0][0] = qnt; // �������� ����� ����������
 }  
  
 //Alert ("���� ��������� MACD");
 int ExtremumMACD = isMACDExtremum(timeframe, fastPeriod, slowPeriod); //�������� ��� �� ���������� �� MACD
 
 if (ExtremumMACD > 0) // ���� ���� �������� �� MACD
 {
  for (i = qnt; i > 0; i--)
  {
   for (j = 0; j < 5; j++)
   {
    aDivergence[index][i+1][j] = aDivergence[index][i][j];
   }
  }
  aDivergence[index][1][1] = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, 2); // �������� ���������� ��������� MACD
  //aDivergence[1][2] = iHigh(NULL, Jr_Timeframe, 2); // �������� ���� � ��������� ��������� //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
  aDivergence[index][1][3] = 2; // ����� ���� � ����������
  aDivergence[index][1][4] = 1; // ��� ��������� ��������
  qnt++; // ��������� ���������� �����������
  aDivergence[index][0][0] = qnt; // �������� ����� ����������
 }
 
 if (ExtremumMACD < 0)  // ���� ���� ������� �� MACD
 {
  for (i = qnt; i > 0; i--)
  {
   for (j = 0; j < 5; j++)
   {
    aDivergence[index][i+1][j] = aDivergence[index][i][j];
   }
  }
  aDivergence[index][1][1] = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, 2); // �������� ���������� �������� MACD
  //aDivergence[1][2] = iLow(NULL, Jr_Timeframe, 2); // ������� ���� � ��������� ��������� //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
  aDivergence[index][1][3] = 2; // ����� ���� � ���������
  aDivergence[index][1][4] = -1; // ��� ��������� �������
  qnt++; // ��������� ���������� �����������
  aDivergence[index][0][0] = qnt; // �������� ����� ���������� 
 }
 
 return;
}