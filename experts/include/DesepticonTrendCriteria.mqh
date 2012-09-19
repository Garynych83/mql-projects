//+------------------------------------------------------------------+
//|                                      DesepticonTrendCriteria.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
int InitTrendDirection(int timeframe, double MACD_channel)
{
 int i = 0;
 int depth = 200;
 int index;
 int fastEMA;
 int slowEMA;
 int fastPeriod;
 int slowPeriod;
 bool isTrendDefined = false;
  
 switch(timeframe)
 {
  case PERIOD_D1:
      Alert("PERIOD_D1");
      index = 0;
      fastEMA = eld_EMA1;
      slowEMA = eld_EMA2;
      fastPeriod = eldFastMACDPeriod;
      slowPeriod = eldSlowMACDPeriod;
      break;
  case PERIOD_H1:
      Alert("PERIOD_H1");
      index = 1;
      fastEMA = eld_EMA1;
      slowEMA = eld_EMA2;
      fastPeriod = eldFastMACDPeriod;
      slowPeriod = eldSlowMACDPeriod;
      break;
  case PERIOD_M5:
      Alert("PERIOD_M5");
      index = 2;
      fastEMA = jr_EMA1;
      slowEMA = jr_EMA2;
      fastPeriod = jrFastMACDPeriod;
      slowPeriod = jrSlowMACDPeriod;
      break;
  default:
      Alert("InitTrendDirection: �� �������� � �����������");
      break;
 }
 
 //Alert("��� ��� ������ ���� ���������, timeframe=",timeframe," fastPeriod=",fastPeriod," slowPeriod=",slowPeriod, " MACD_channel=", MACD_channel);
 while (!isTrendDefined && i < depth)
 {
  Alert("MACD_channel=",-MACD_channel,"  iMACD=",iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, 1));
  while((MACD_channel > iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i)
        && iMACD(NULL, timeframe, fastPeriod, slowPeriod, 9, PRICE_CLOSE, MODE_MAIN, i) > -MACD_channel) && i < 200)
  {
   i++;
  }
  Alert("i=",i);
  Current_fastEMA = iMA(NULL, timeframe, fastEMA, 0, 1, 0, i);
  Current_slowEMA = iMA(NULL, timeframe, slowEMA, 0, 1, 0, i);
  if ((Current_fastEMA < (Current_slowEMA - deltaEMAtoEMA*Point)))
  {
   trendDirection[index][1] = -1;
   isTrendDefined = true;
   return(-1);   
  }
  if ((Current_fastEMA > (Current_slowEMA + deltaEMAtoEMA*Point)) )
  {
   Alert("i=",i,"  Current_fastEMA=",Current_fastEMA,"  Current_slowEMA=",Current_slowEMA + deltaEMAtoEMA*Point);
   trendDirection[index][1] = 1;
   isTrendDefined = true;
   return(1);
  }
  i++;
 }
 
 if (i >= depth)
 {
  Alert("��������!!! ����� ������� ������� ������� MACD, ��������� ����������� ������ �� ����������! �������� ������������ ������ ��������!");
 }
 return(0);
}

//-----------------------------------------------------
//
//-----------------------------------------------------

int OneTitTrendCriteria(int timeframe, double MACD_channel, int period_EMA1, int period_EMA2, int fastEMAPeriod, int slowEMAPeriod)
{

  Current_fastEMA = iMA(NULL, timeframe, period_EMA1, 0, 1, 0, 1);
  Current_slowEMA = iMA(NULL, timeframe, period_EMA2, 0, 1, 0, 1);
  CurrentMACD = iMACD(NULL, timeframe, fastEMAPeriod, slowEMAPeriod, 9, PRICE_CLOSE, MODE_MAIN, 1);
  
  bool MACD_down;
  bool MACD_up;
  int i;
  
  if (-MACD_channel < CurrentMACD && CurrentMACD < MACD_channel)
  {  // ������ MACD
   if (searchForTits(timeframe, MACD_channel, false))
   {
    return (0);
   } // Close  searchForTits
   if (timeframe == Elder_Timeframe)
    return (trendDirection[frameIndex][1]);
   if (timeframe == Jr_Timeframe)
    return (trendDirection[frameIndex + 1][1]); 
  }
  
  if ((Current_fastEMA < (Current_slowEMA - deltaEMAtoEMA*Point)))
  {
	return (-1);   
  }
    
  if ((Current_fastEMA > (Current_slowEMA + deltaEMAtoEMA*Point)) )
  {
   return (1);
  }

  return (0); // ��� ������
}

//-----------------------------------------------------
//
//-----------------------------------------------------

int TwoTitsTrendCriteria(int timeframe, double MACD_channel, int period_EMA1, int period_EMA2, int fastEMAPeriod, int slowEMAPeriod)
{
   int index;
   
   if (timeframe == Elder_Timeframe)
   {
    index = frameIndex;
   }
   else if (timeframe == Jr_Timeframe)
        {
         index = frameIndex + 1; 
        }
        else
        {
         Alert("TwoTitsTrendCriteria: �� �������� � �����������");
        }

  Current_fastEMA = iMA(NULL, timeframe, period_EMA1, 0, 1, 0, 1);
  Current_slowEMA = iMA(NULL, timeframe, period_EMA2, 0, 1, 0, 1);
  CurrentMACD = iMACD(NULL, timeframe, fastEMAPeriod, slowEMAPeriod, 9, PRICE_CLOSE, MODE_MAIN, 1);
  
  bool MACD_down;
  bool MACD_up;
  int i;
  
  if (-MACD_channel <= CurrentMACD && CurrentMACD <= MACD_channel)
  {  // ������ MACD
   if (isMACDExtremum(timeframe, fastEMAPeriod, slowEMAPeriod) != 0)
   {
    //Alert("isMACDExtremum = ",isMACDExtremum(timeframe, fastEMAPeriod, slowEMAPeriod));
    if (searchForTits(timeframe, MACD_channel, true))
    {
     //Alert("����� ������");
     return (0);
    } // Close  searchForTits
   }
   return (trendDirection[index][0]);
  }
  
  if ((Current_fastEMA < (Current_slowEMA - deltaEMAtoEMA*Point)))
  {
   //Alert("Current_fastEMA=",Current_fastEMA,"  (Current_slowEMA - deltaEMAtoEMA*Point)=",(Current_slowEMA - deltaEMAtoEMA*Point));
   // ��������� ��� ���� �������� - ����� ����
	return (-1);   
  }
  else if ((Current_fastEMA > (Current_slowEMA + deltaEMAtoEMA*Point)) )
       {
       //Alert("Current_fastEMA=",Current_fastEMA,"  (Current_slowEMA - deltaEMAtoEMA*Point)=",(Current_slowEMA - deltaEMAtoEMA*Point));\
       // ��������� ��� ���� �������� - ����� �����
       return (1);
       }
       else
       {
        // MACD �������, �� ��� ������, ����� �� ���������� ������
        return (trendDirection[index][1]);
       }
  
  Alert("�������� !!! ��� ������!!!");
  return (0); // ��� ������
}