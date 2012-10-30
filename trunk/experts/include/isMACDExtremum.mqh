//+------------------------------------------------------------------+
//|                                               isMACDExtremum.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"


// --- ��������� �� ��������� �� ����� ���������� --- 
int isMACDExtremum(int timeframe, int fastPeriod, int slowPeriod, int startIndex = 0)
{
  //Alert ("���� ��������� MACD_2");
  //int qnt = aDivergence[frameIndex][0][0];
  //int i; int j;
  
  //double M0 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex);
  double M1 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 1);
  double M2 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 2);
  double M3 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 3);
  double M4 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 4);

  //if (M0 < M2 && M1 < M2 && M2 > M3 && M2 > M4 && M2 > 0) // ����� ��� ���� ��������
  if (M1 < M2 && M2 > M3 && M2 > M4 && M2 > differenceMACD)
  {
   //Alert("����� ����� �������� �� MACD ");
   return(1);
  }

  //if (M0 > M2 && M1 > M2 && M2 < M3 && M2 < M4 && M2 < 0) // ����� ��� ���� �������
  if (M1 > M2 && M2 < M3 && M2 < M4 && M2 < -differenceMACD) 
  {
   //Alert("����� ����� ������� �� MACD ");
   return(-1);     
  }
  return(0);
}

// --- ��������� �� ��������� �� ����� ��� --- 
int isMACDPit(int timeframe, int fastPeriod, int slowPeriod, int startIndex = 0)
{
  //Alert ("���� ��������� MACD_2");
  //int qnt = aDivergence[frameIndex][0][0];
  //int i; int j;
  
  //double M0 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex);
  double M1 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 1);
  double M2 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 2);
  double M3 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 3);
  double M4 = iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, startIndex + 4);

  if (M1 < M2 && M2 > M3 && M2 > M4)
  {
   return(1); // MACD �����, ������ ������
  }

  if (M1 > M2 && M2 < M3 && M2 < M4) 
  {
   return(-1);     
  }
  return(0); // MACD ������, ������ �����
}