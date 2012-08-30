//+------------------------------------------------------------------+
//|                                               direction_MACD.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

int direction_MACD()
{
  MACD_up = true;
  MACD_down = true;
  int i;
  
  for (i = 0; i < depthMACD - 1; i++)
  {
   if (MACD_15M[i] < MACD_15M[i+1]) {
      MACD_up = false;
   }
   if (MACD_15M[i] > MACD_15M[i+1]) {
      MACD_down = false;
   }
  }

  if (MACD_down && MACD_15M[i-1] > 0) // MACD ����� ������ - ����� �� 3-� �����
  {
   if (MACD_down && MACD_15M[i-1] > 0) // MACD ����� ������ � ������������� ��������- ���� ������������ ����
   {
    return (1);
   }     
  }
  
  if (MACD_up && MACD_15M[i-1] < 0) // MACD ����� �����, ����������� 
  {
   if (MACD_up && MACD_15M[i-1] < 0) // MACD ����� ����� � ������������� ��������- ���� ����������� ����
   {
    return (-1);
   }     
  }
}    