//+------------------------------------------------------------------+
//|                                                searchForTits.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

bool searchForTits(int timeframe, double MACD_channel, bool bothTits)
{
 int i = 0;
 int fastPeriod;
 int slowPeriod;
 bool isMax = false;
 bool isMin = false;
 
 if (timeframe == jr_Timeframe)
 { 
  fastPeriod = jrFastMACDPeriod;
  slowPeriod = jrSlowMACDPeriod;
 } 
 else if ( timeframe == elder_Timeframe )
      {
       fastPeriod = eldFastMACDPeriod;
       slowPeriod = eldSlowMACDPeriod;
      }
      else
      {
       Alert ("jr_Timeframe ", jr_Timeframe, " elder_Timeframe ",elder_Timeframe, " timeframe ", timeframe);
       Alert ("searchForTits: �� �������� � �����������");
       return (0);
      }
 
 //Alert ("fastPeriod ", fastPeriod, " slowPeriod ",slowPeriod, " timeframe ", timeframe);
 while (-MACD_channel < iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i)
      && iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i) < MACD_channel)
 {
  if (isMACDExtremum(timeframe, fastPeriod, slowPeriod, i) < 0)
  {
   //Alert (" ������ ������� ", i, " ����� �����" );
   isMax = true;
   break;
  } 
  i++;
 }
 
 i = 0;
 while( MACD_channel > iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i)
       && iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i) > -MACD_channel)
 {
  if (isMACDExtremum(timeframe, fastPeriod, slowPeriod, i) > 0)
  {
   //Alert (" ������ �������� ", i, " ����� �����" );
   isMin = true;
   break;
  } 
  i++;
 }
 
 if (bothTits) // ���� ����� ��� ������ ��� �����
 {
  return (isMin && isMax); // ���������� ��� ������ ���� ��� ������ �������
 }
 else 
 {
  return (isMin || isMax);
 }

}

