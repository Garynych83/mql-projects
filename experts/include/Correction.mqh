//+------------------------------------------------------------------+
//|                                                   Correction.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int Correction()
{
 int fastEMA = eld_EMA1;
 int slowEMA = eld_EMA2;
 int fastMACD = eldFastMACDPeriod;
 int slowMACD = eldSlowMACDPeriod;
 //double MACD_channel = Elder_MACD_channel;
 int index = frameIndex;
 
 /*
 if (timeframe == Jr_Timeframe)
 {
  fastEMA = jr_EMA1;
  slowEMA = jr_EMA2;
  fastMACD = jrFastEMAPeriod;
  slowMACD = jrSlowEMAPeriod;
  MACD_channel = Jr_MACD_channel;
  index = frameindex + 1;
 }
 else if (timeframe == elder_Timeframe)
      {
       fastEMA = eld_EMA1;
       slowEMA = eld_EMA2;
       fastMACD = eldFastEMAPeriod;
       slowMACD = eldSlowEMAPeriod;
       MACD_channel = Elder_MACD_channel;
       index = frameindex;
      }
      else 
      {
       Alert ("Jr_Timeframe ", Jr_Timeframe, " elder_Timeframe ", elder_Timeframe, " timeframe ", timeframe);
       Alert ("�� �������� � �����������");
       return (false);
      }
*/
        
  if (trendDirection[index][0] > 0) // ����� ����� �� �������� ����������
  {  
   if (iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 1) < iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 2)) // �������� ��������� ����
   {
    aCorrection[index][0] = -1;
    aCorrection[index][1] = iHigh(NULL, elder_Timeframe, iHighest(NULL, elder_Timeframe, MODE_HIGH, 5, 0));
   } // Close  �������� ��������� ����
  } // close ����� �����
   
  if (trendDirection[index][0] < 0) // ����� ���� �� �������� ����������
  { 
   if (iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 1) > iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 2)) // �������� ��������� �����
   {
    aCorrection[index][0] = 1;
    aCorrection[index][1] = iLow(NULL, elder_Timeframe, iLowest(NULL, elder_Timeframe, MODE_HIGH, 5, 0));
   } // Close  �������� ��������� ����
  } // close ����� �����
  return (aCorrection[index][0]);
}


