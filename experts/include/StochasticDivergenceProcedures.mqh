//+------------------------------------------------------------------+
//|                               StochasticDivergenceProcedures.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+


extern int depthSto = 10;
double aStochastic[3][10][5]; // [][0] - ������
                           // [][1] - ����-� Stochastic
                           // [][2] - ����-� ���� � ���������� Stochastic
                           // [][3] - ����� ����
                           // [][4] - ���� +/-                           

// --- ��������� �� ��������� �� ����� ���������� --- 
int isStochasticExtremum(int timeframe, int startIndex = 0)
{
  double Sto1 = iStochastic(NULL,timeframe, 5, 3, 3 ,MODE_SMA,0,MODE_MAIN, startIndex + 1);
  double Sto2 = iStochastic(NULL,timeframe, 5, 3, 3 ,MODE_SMA,0,MODE_MAIN, startIndex + 2);
  double Sto3 = iStochastic(NULL,timeframe, 5, 3, 3 ,MODE_SMA,0,MODE_MAIN, startIndex + 3);

  if (Sto1 < Sto2 && Sto3 < Sto2) // ����� ��� ���� ��������
  {
   return(1);
  }

  if (Sto1 > Sto2 && Sto3 > Sto2) // ����� ��� ���� �������
  {
   return(-1);     
  }
  return(0);
}
//------------------------------------------------



// --- ��������� ������ ����������� ���������� ---
void InitStoDivergenceArray(int timeframe)
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
      Alert("InitStoDivergenceArray: �� �������� � �����������");
      return(false);
 }
 // �������� ������ ���� ������� �����������
 double tmpArray[10][4];
 ArrayInitialize(tmpArray, 0);
 
 for (int m = 0; m < 10; m++)
    for (int n = 0; n < 4; n++)
       aStochastic[index][m][n] = tmpArray[m][n];
 
 // ��������� ������ ���� ������ ����������
 int cnt = 0; // ������� �����������
 for (int bar_num = 0; bar_num < depthSto; bar_num++) // �������� �� ����� 
 {
  int stochasticExtremum = isStochasticExtremum(timeframe, bar_num);
  
  if (stochasticExtremum > 0) // ���� ���� �������� �� Stochastic
  { 
   cnt++;
   
   aStochastic[index][cnt][1] = iStochastic(NULL, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, bar_num+2); // �������� ���������� ��������� Stochastic
   //aStochastic[index][cnt][2] = iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 3, bar_num+2)); // �������� ���� � ��������� ��������� //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
   aStochastic[index][cnt][3] = bar_num+2; // ����� ���� � ����������
   aStochastic[index][cnt][4] = 1; // ��� ��������� ��������  
  }
   
  if (stochasticExtremum < 0) // ���� ���� ������� �� Stochastic
  {
   cnt++;
   aStochastic[index][cnt][1] = iStochastic(NULL, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, bar_num+2); // �������� ���������� �������� Stochastic
   //aStochastic[index][cnt][2] = iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 3, bar_num+2)); // ������� ���� � ��������� ��������� //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
   aStochastic[index][cnt][3] = bar_num+2; // ����� ���� � ���������
   aStochastic[index][cnt][4] = -1; // ��� ��������� �������  
  }
 }
 aStochastic[index][0][0] = cnt; // ����� ���������� �����������
}
// -----------------------------------------------


//  --- ��������� �� ��������� �� ����������� ----                           
int isStoDivergence(int timeframe)
{
 int i;
 int stochasticExtremum = isStochasticExtremum(timeframe);
 
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
      Alert("isStoDivergence: �� �������� � �����������");
      return(false);
 }
 
 double curMaxPrice = 
      iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, 3, 0)); // ������� ������������ ���� �� 0-2 ��������� �����
 double curMinPrice = 
      iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, 3, 0)); // ������� ����������� ���� �� 0-2 ��������� �����
      
 double maxPrice = 
      iHigh(NULL, timeframe, iHighest(NULL, timeframe, MODE_HIGH, depthSto - 4, 3)); // ������� ������������ ���� �� 2-10 ��������� �����
 double minPrice = 
      iLow(NULL, timeframe, iLowest(NULL, timeframe, MODE_LOW, depthSto - 4, 3)); // ������� ����������� ���� �� 2-10 ��������� �����

 if (curMaxPrice > maxPrice) // ���� �������� ���������� ������, ��� � �������
 {
  if (stochasticExtremum > 0 && aStochastic[index][1][1] < 80) // ��������� ���������� ��������� Sto ������ 80
  {
   for (i = 2; i <= 10; i++)
   { 
    if (aStochastic[index][i][4] > 0 && aStochastic[index][i][1] > 80) // ��������, ������ 80
    {
     openPlace = 
       TimeDay(iTime(NULL, timeframe, aStochastic[index][1][3])) + ":"
     + TimeHour(iTime(NULL, timeframe, aStochastic[index][1][3])) + ":"
     + TimeMinute(iTime(NULL, timeframe, aStochastic[index][1][3]));
     barsCountToBreak[index][1] = 0;
     return(-1); // ����������� ������, ���� �������, ����������� ���� (��������)
    } 
   } // 
  } // close ��������� ���������� ��������� Sto
 } // close ���� �������� ���������� ������, ��� � �������
 
 //Alert("���� �������� ���������� =", curMinPrice, " ����������� ���� �� 2-10 ��������� �����=",minPrice);
 if(curMinPrice < minPrice) // ���� �������� ���������� ������ ��� � �������
 {
  //Alert("���� �������� ���������� ������ ��� � �������");
  if (stochasticExtremum < 0 && aStochastic[index][1][1] > 20) // ��������� ���������� �������� ���������� ������ 20
  {
   //Alert("");
   for (i = 2; i <= 10; i++)
   {
    if (aStochastic[index][i][4] < 0 && aStochastic[index][i][1] < 20) // �������, ������ 20
    { 
     openPlace = 
       TimeDay(iTime(NULL, timeframe, aStochastic[index][1][3])) + ":"
     + TimeHour(iTime(NULL, timeframe, aStochastic[index][1][3])) + ":"
     + TimeMinute(iTime(NULL, timeframe, aStochastic[index][1][3]));
     barsCountToBreak[index][1] = 0;
     return(1); // ����������� ������, ���� �������, ����������� ����� (�����)
    } 
   } // 
  } // close ��������� ���������� �������� MACD
 }// close ���� �������� ���������� ������ ��� � ������� 
 
 return(0);
}                           