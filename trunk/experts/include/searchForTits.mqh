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
 int ext = 0;
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
 for (i = 0; MathAbs(iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i)) < MACD_channel; i++)
 {
  ext = isMACDExtremum(timeframe, fastPeriod, slowPeriod, i);
  if (ext != 0)
  {
   if (ext < 0)
   {
    //Alert (" ������ ������� ", i, " ����� �����" );
    isMin = true;
   } 
   if (ext > 0)
   {
    //Alert (" ������ �������� ", i, " ����� �����" );
    isMax = true;
   } 
   if (isMin && isMax)
   {
    break;
   }
  }
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

