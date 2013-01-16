//+------------------------------------------------------------------+
//|                                              desepticon v005.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

//------- ������� ��������� ��������� -----------------------------------------+



//------- ���������� ���������� ��������� -------------------------------------+
double aCorrection[3][2]; // [][0] - ������� ���������, [][1] - �������� ����

//------- ����������� ������� ������� -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <DesepticonVariables.mqh>    // �������� ���������� 
#include <AddOnFuctions.mqh> 
#include <CheckBeforeStart.mqh>       // �������� ������� ����������
#include <DesepticonTrendCriteria.mqh>
#include <Correction.mqh>
#include <DesepticonBreakthrough2.mqh>
#include <searchForTits.mqh>
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // �� ����� ���������� ����� �����������
#include <isNewBar.mqh>
#include <isMACDExtremum.mqh>
#include <DesepticonOpening.mqh>
#include <DesepticonTrailing.mqh>

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init(){
  Alert("��������� �-�� init() ��� �������");

  aTimeframe[1,0] = PERIOD_H1;
  aTimeframe[1,1] = TakeProfit_1H;
  aTimeframe[1,2] = StopLoss_1H_min;
  aTimeframe[1,3] = StopLoss_1H_max;
  aTimeframe[1,4] = MACD_channel_1H;
  aTimeframe[1,5] = MinProfit_1H;
  aTimeframe[1,6] = TrailingStop_1H_min;
  aTimeframe[1,7] = TrailingStop_1H_max;
  aTimeframe[1,8] = TrailingStep_1H;
  aTimeframe[1,9] = PERIOD_M5;
  
  aTimeframe[2,0] = PERIOD_M5;
  
  ArrayInitialize(aCorrection, 0);
  
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   trendDirection[frameIndex][0] =  InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("trendDirection[0]=",trendDirection[frameIndex][0], " frameIndex=",frameIndex);
  }

  return(0);
 }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit(){
	Alert("��������� ������� deinit");
	return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start(){
  for (frameIndex = startTF; frameIndex < finishTF; frameIndex++)
  {
   Jr_Timeframe = aTimeframe[frameIndex, 9];
   Elder_Timeframe = aTimeframe[frameIndex, 0];
     
   TakeProfit = aTimeframe[frameIndex, 1];
   StopLoss_min = aTimeframe[frameIndex, 2];
   StopLoss_max = aTimeframe[frameIndex, 3]; 
   Jr_MACD_channel = aTimeframe[frameIndex + 1, 4];
   Elder_MACD_channel = aTimeframe[frameIndex, 4];
   
   MinProfit = aTimeframe[frameIndex, 5]; 
   TrailingStop_min = aTimeframe[frameIndex, 6];
   TrailingStop_max = aTimeframe[frameIndex, 7]; 
   TrailingStep = aTimeframe[frameIndex, 8];
     
   if (!CheckBeforeStart())   // ��������� ������� ���������
   {
    PlaySound("alert2.wav");
    return (0); 
   }
     
   total=OrdersTotal();
     
   if (total > 0)
   {
    for (int i=0; i<total; i++)
    {
     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
     {
      if (OrderMagicNumber() == _MagicNumber)  
      {
       if (OrderType()==OP_BUY)   // ������� ������� ������� BUY
       {
        if (!isMinProfit && Bid-OrderOpenPrice() > MinimumLvl*Point) // �������� ������������ ������ �������
        {
         isMinProfit = true;
         Alert("��� ������ �� ����������. ���������� ������. isMinProfit = ",isMinProfit);
        }
        
        if (useLowTF_EMA_Exit)
        {
         if (Bid-OrderOpenPrice() > MinProfit*Point) // �������� ����������� ������
         {
          if (iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 0) 
                 > iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 0) + deltaEMAtoEMA*Point) // �������� �������� EMA  �� ������� ��
          {
           ClosePosBySelect(Bid, "�������� ����������� �������, �������� ��� �� ������� ��, ��������� �������"); // ��������� ������� BUY
           Alert("������� �����, �������� ����������. Bid-OrderOpenPrice()= ",Bid-OrderOpenPrice(), " MinProfit ", MinProfit*Point);
          }
         } // close �������� ����������� ������ 
        }
       } // Close ������� ������� ������� BUY
        
       if (OrderType()==OP_SELL) // ������� �������� ������� SELL
       {
        if (!isMinProfit && OrderOpenPrice()-Ask > MinimumLvl*Point) // �������� ������������ ������ �������
        {
         isMinProfit = true;
         Alert("Sell, ��� ������ �� ����������. ���������� ������. isMinProfit = ",isMinProfit);
        }
        
        if (useLowTF_EMA_Exit)
        {
         if (OrderOpenPrice()-Ask > MinProfit*Point)
         {
          if (iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 0)
                 < iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 0) - deltaEMAtoEMA*Point) // �������� �������� EMA  �� ������� ��
          {
           ClosePosBySelect(Ask, "�������� ����������� �������, �������� ��� �� ������� ��, ��������� �������");// ��������� ������� SELL
           Alert("������� �����, �������� ����������. OrderOpenPrice()-Ask= ",OrderOpenPrice()-Ask, " MinProfit ", MinProfit*Point);
          }
         } // close �������� ����������� ������
        } 
       } // Close ������� �������� ������� SELL
      } // close _MagicNumber �� ����� Jr_Timeframe
     } // close OrderSelect 
    } // close for
   } // close total > 0

   if( isNewBar(Elder_Timeframe) ) // �� ������ ����� ���� �������� �� ��������� ����� � ��������� �� �������
   {
    total=OrdersTotal();
    if (useTimeExit)
    {
     if (total > 0 && !isMinProfit)
     {
      barNumber++; // ����������� ������� ����� ���� ���� �������� ������ ����������� ����������
      Alert("��� ������ ��� �� ��� ���������, ������ ����, ����������� ������� barNumber=",barNumber);
      if (barNumber > waitForMove) // ���� ������� ����� ���� �������� � ���� �������
      {
       for (i=0; i<total; i++) // ���� �� ���� �������
       {
        if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if (OrderMagicNumber() == _MagicNumber) // �������� ���� ������
         {
          //ClosePosBySelect(-1, "������ �� ���� � ������� ������� ������ �����");// ��������� �������
         }
        }
       } 
      }
     }
    }
    
    trendDirection[frameIndex][0] = TwoTitsTrendCriteria(Elder_Timeframe, Elder_MACD_channel, eld_EMA1, eld_EMA2, eldFastMACDPeriod, eldSlowMACDPeriod);
    if (aCorrection[frameIndex][0] > 0) // ��������� �����
    {
     if (trendDirection[frameIndex][0] > 0 || Bid < aCorrection[frameIndex][1]) // ����� �����
     {
      ArrayInitialize(aCorrection, 0); // ����� ��������� �����
     }
    } // close ��������� �����
    else if (aCorrection[frameIndex][0] < 0) // ��������� ����
         {
          if (trendDirection[frameIndex][0] < 0 || Ask > aCorrection[frameIndex][1]) // ����� ����
          {
           ArrayInitialize(aCorrection, 0); // ����� ��������� ����
          }
         } // close ��������� ����
         else  // ��� ���������
         {
          Correction(); // �������� �� �������� �� ���������
         }
   } // close isNewBar
     
//--------------------------------------
// ��������� �������� ��� ������ �� �������� ��� ����� �� ������� ��
//--------------------------------------
   if( isNewBar(Jr_Timeframe) ) // �� ������ ����� ���� �������� �� ��������� ����� �� �������
   {
    trendDirection[frameIndex + 1][0] = TwoTitsTrendCriteria(Jr_Timeframe, Jr_MACD_channel, jr_EMA1, jr_EMA2, jrFastMACDPeriod, jrSlowMACDPeriod);
    if (trendDirection[frameIndex + 1][0] > 0) // ���� ����� ����� �� ������� ����������
    { 
     trendDirection[frameIndex + 1][1] = 1;
    } 
    if (trendDirection[frameIndex + 1][0] < 0) // ���� ����� ����� �� ������� ����������
    {
     trendDirection[frameIndex + 1][1] = -1;
    }
   } // close  isNewBar(Jr_Timeframe)
   if (trendDirection[frameIndex + 1][0] == 0) // ���� �� ������� ���� �� �������
   {
    //Alert("���� �� �������");
    continue; // ��������� ��� ����� �� �����
   }
//--------------------------------------
// ��������� �������� ��� ������ �� �������� ��� ����� �� ������� ��
//--------------------------------------
           
//-------------------------------------------------------------------------------------------
// ������� ����� �����
//-------------------------------------------------------------------------------------------
   if (trendDirection[frameIndex][0] > 0) // ���� ����� ����� �� ������� ����������
   {
    trendDirection[frameIndex][1] = 1;
        if (aCorrection[frameIndex][0] >= 0) // ��� ��������� ����
    {
     if (Bid < iMA(NULL, PERIOD_D1, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point) // �� �������� ���� ���� ��� �� ������ ���� ���3 
     {
      if (iLow(NULL, Elder_Timeframe, 1) < iMA(NULL, Elder_Timeframe, eld_EMA1, 0, 1, 0, 1) + deltaPriceToEMA*Point ||
          Bid < iMA(NULL, Elder_Timeframe, eld_EMA1, 0, 1, 0, 0) + deltaPriceToEMA*Point) // �� ��������� 2-� ����� ���� ���� ���� �������� ���       
      {
       if (iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 1) > iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
           iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 2) < iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // ����������� ��� ����� �����
       {
        openPlace = "������� ����� �����, �� ������� ����������� ��� ����� ����� ";
        if (DesepticonBreakthrough2(1, Jr_Timeframe) > 0) // ���� ������� ��������� 
        {
         Alert("������� ������, ������ ������");
	      isMinProfit = false; // ������ ������
	      barNumber = 0;
	     }
       } // close ����������� ��� ����� �����
      } // close �� ��������� 2-� ����� ���� ���� ���� �������� ��� 
     } // close �� �������� ���� ���� ��� �� ������ ���� ���3
    } // close ��� ��������� ����
   }

//-------------------------------------------------------------------------------------------
// ������� ����� ����
//-------------------------------------------------------------------------------------------     
   if (trendDirection[frameIndex][0] < 0) // ���� ����� ����
   {
    trendDirection[frameIndex][1] = -1;
     if (aCorrection[frameIndex][0] <= 0) // ��� ��������� �����
    {
     if (Ask > iMA(NULL, PERIOD_D1, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point) // �� �������� ���� ���� ��� �� ������ ���� ���3
     {
      if (iHigh(NULL, Elder_Timeframe, 1) > iMA(NULL, Elder_Timeframe, eld_EMA1, 0, 1, 0, 1) - deltaPriceToEMA*Point ||
          Ask > iMA(NULL, Elder_Timeframe, eld_EMA1, 0, 1, 0, 0) - deltaPriceToEMA*Point) // �� ��������� 2-� ����� ���� ���� ���� �������� ���
      {
       if (iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 1) < iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
           iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 2) > iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // ����������� ��� ������ ����
       {
        openPlace = "������� ����� ����, �� ������� ����������� ��� ������ ���� Ask=" + Ask + "  EMA="+ (iMA(NULL, PERIOD_D1, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point);
        if (DesepticonBreakthrough2(-1, Jr_Timeframe) > 0) // ���� ������� ���������
        {
         Alert("������� ������, ������ ������");
	      isMinProfit = false; // ������ ������
	      barNumber = 0;
	     }
       } // close ����������� ��� ������ ����
      } // close �� ��������� 2-� ����� ���� ���� ���� �������� ��� 
     } // close �� �������� ���� ���� ��� �� ������ ���� ���3
    } // close else ��������� ����� 
   }
  } // close ����
//----
	if (UseTrailing) DesepticonTrailing(NULL, Jr_Timeframe); 
	return(0);
} // close start
//+------------------------------------------------------------------+