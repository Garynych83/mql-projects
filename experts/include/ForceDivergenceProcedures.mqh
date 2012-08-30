//+------------------------------------------------------------------+
//|                                    ForceDivergenceProcedures.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+


extern int depthSto = 30;
double aForce[3][10][5]; // [][0] - ������
                           // [][1] - ����-� MACD
                           // [][2] - ����-� ���� � ���������� MACD
                           // [][3] - ����� ����
                           // [][4] - ���� +/-                           

// --- ��������� �� ��������� �� ����� ���������� --- 
int isForceExtremum(int timeframe, int startIndex = 0)
{
  double force1 = iForce(NULL,Jr_Timeframe, 2 ,MODE_SMA,PRICE_CLOSE, startIndex + 1);
  double force2 = iForce(NULL,Jr_Timeframe, 2 ,MODE_SMA,PRICE_CLOSE, startIndex + 2);
  double force3 = iForce(NULL,Jr_Timeframe, 2 ,MODE_SMA,PRICE_CLOSE, startIndex + 3);

  if (force1 < force2 && force3 < force2) // ����� ��� ���� ��������
  {
   return(1);
  }

  if (force1 > force2 && force3 > force2) // ����� ��� ���� �������
  {
   return(-1);     
  }
  return(0);
}
//------------------------------------------------



// --- ��������� ������ ����������� ���������� ---
void InitForceDivergenceArray(int timeframe)
{  
   // �������� ������ ���� ������� �����������
   double tmpArray[10][4];
   ArrayInitialize(tmpArray, 0);
   
   for (int m = 0; m < 10; m++)
      for (int n = 0; n < 4; n++)
         aForce[frameIndex][m][n] = tmpArray[m][n];
   
   // ��������� ������ ���� ������ ����������
   int cnt = 0; // ������� �����������
   for (int bar_num = 0; bar_num < depthSto; bar_num++) // �������� �� ����� 
   {
    int forceExtremum = isForceExtremum(timeframe, bar_num);
    
    if (forceExtremum > 0) // ���� ���� �������� �� Force
    { 
     cnt++;
     
     aForce[frameIndex][cnt][1] = iForce(NULL, timeframe, 2, MODE_SMA, PRICE_CLOSE, bar_num+2); // �������� ���������� ��������� MACD
     aForce[frameIndex][cnt][2] = iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, 3, bar_num+1)); // �������� ���� � ��������� ��������� //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
     aForce[frameIndex][cnt][3] = bar_num+2; // ����� ���� � ����������
     aForce[frameIndex][cnt][4] = 1; // ��� ��������� ��������  
    }
    
    if (forceExtremum < 0) // ���� ���� ������� �� Force
    {
     cnt++;
     aForce[frameIndex][cnt][1] = iForce(NULL, timeframe, 2, MODE_SMA, PRICE_CLOSE, bar_num+2); // �������� ���������� �������� MACD
     aForce[frameIndex][cnt][2] = iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, 3, bar_num+1)); // ������� ���� � ��������� ��������� //iHighest(NULL, PERIOD_M15, MODE_HIGH, depthPrice, 0)]; 
     aForce[frameIndex][cnt][3] = bar_num+2; // ����� ���� � ���������
     aForce[frameIndex][cnt][4] = -1; // ��� ��������� �������  
    }
   }
   aForce[frameIndex][0][0] = cnt; // ����� ���������� �����������
}

// -----------------------------------------------


//  --- ��������� �� ��������� �� ����������� ----                           
int isForceDivergence()
{
 int i;
 int forceExtremum = isForceExtremum(Jr_Timeframe);
 
 double maxPrice = 
      iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, 3, 0)); // ������� ������������ ���� �� 3 ��������� �����
 double minPrice = 
      iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, 3, 0)); // ������� ����������� ���� �� 3 ��������� �����

  if (forceExtremum > 0 && aForce[frameIndex][1][1] > 0.15) // ��������� ���������� ��������� Force
  {
   for (i = 2; i <= 10; i++)
   { 
    if (aForce[frameIndex][i][4] > 0 && aForce[frameIndex][i][1] > 0.2 // �������� ������ 80
        && aForce[frameIndex][1][1] < aForce[frameIndex][i][1])        // ������� ��������� ������ ��� � �������
     if (aForce[frameIndex][1][2] > aForce[frameIndex][i][2])       // ���� �������� ���������� ������ ��� � �������
     {
      if (iHigh(NULL, Jr_Timeframe, iHighest(NULL, Jr_Timeframe, MODE_HIGH, aForce[frameIndex][i][3] - aForce[frameIndex][1][3] - 1, aForce[frameIndex][1][3] + 1)) < aForce[frameIndex][1][2])
      {
       return(-1); // ����������� ������, ���� �������, ����������� ���� (��������)
      }
      else
      {
       return(0);
      }
     }
     else
     {
      return(0);
     } 
   } // 
  } // close ��������� ���������� ��������� Force
 
  if (forceExtremum < 0 && aForce[frameIndex][1][1] < -0.15) // ��������� ���������� �������� Force
  {
   for (i = 2; i <= 10; i++)
   {
    if (aForce[frameIndex][i][4] < 0 && aForce[frameIndex][i][1] < -0.2 // ������� ������ 20
        && aForce[frameIndex][1][1] > aForce[frameIndex][i][1])        // ������� ��������� ������ ��� � �������
     if (aForce[frameIndex][1][2] < aForce[frameIndex][i][2])       // ���� �������� ���������� ������ ��� � �������
     {
      if (iLow(NULL, Jr_Timeframe, iLowest(NULL, Jr_Timeframe, MODE_LOW, aForce[frameIndex][i][3] - aForce[frameIndex][1][3] - 1, aForce[frameIndex][1][3] + 1)) > aForce[frameIndex][1][2])
      {
       return(1); // ����������� ������, ���� �������, ����������� ���� (��������)
      }
      else
      {
       return(0);
      }
     }
     else 
     {
      return(0);
     }
   } // 
  } // close ��������� ���������� �������� Force
 
 return(0);
}                           