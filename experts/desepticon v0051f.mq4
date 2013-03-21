//+------------------------------------------------------------------+
//|                                              desepticon flat.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

#include <BasicVariables.mqh>
#include <DesepticonVariables.mqh>    // �������� ����������
//------- ������� ��������� ��������� -----------------------------------------+
extern string Expert_Self_Parameters = "Expert_Self_Parameters";
extern int hairLength = 250;

extern int Kperiod = 5;
extern int Dperiod = 3;
extern int slowing = 3;
extern int topStochastic = 80;
extern int bottomStochastic = 20;
//------- ���������� ���������� ��������� -------------------------------------+


//------- ����������� ������� ������� -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <AddOnFuctions.mqh> 
#include <CheckBeforeStart.mqh>       // �������� ������� ����������
#include <DesepticonTrendCriteria.mqh>
//#include <DesepticonBreakthrough2.mqh>
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
  aTimeframe[1,4] = MACD_channel;
  
  aTimeframe[2,0] = PERIOD_M5;
  aTimeframe[2,4] = MACD_channel;
  
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("���������� ����������� ������");
  }
  frameIndex = startTF;
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
  jr_Timeframe = PERIOD_M5;
  elder_Timeframe = PERIOD_H1;
    
  jr_MACD_channel = aTimeframe[frameIndex + 1, 4];
  elder_MACD_channel = aTimeframe[frameIndex, 4];
   
   if (!CheckBeforeStart())   // ��������� ������� ���������
   {
    PlaySound("alert2.wav");
    return (0); 
   }
    
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
        if (!isMinProfit && Bid-OrderOpenPrice() > minimumProfitLvl*Point) // �������� ������������ ������ �������
        {
         isMinProfit = true;
         Alert("��� ������ �� ����������. ���������� ������. isMinProfit = ",isMinProfit);
        }

        if (isMinProfit && Bid < OrderOpenPrice())
        {
         Alert("Buy, ��� ������ ��� ��������� �����, ������� 0 ��������� ������� ������");
	      isMinProfit = false; // ������ ������
	      barNumber = 0;
        }
        
        if (useLowTF_EMA_Exit)
        {
         if (Bid-OrderOpenPrice() > minProfit*Point) // �������� ����������� ������
         {
          if (iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 0) 
                 > iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 0) + deltaEMAtoEMA*Point) // �������� �������� EMA  �� ������� ��
          {
           ClosePosBySelect(Bid, "�������� ����������� �������, �������� ��� �� ������� ��, ��������� �������"); // ��������� ������� BUY
           Alert("������� �����, �������� ����������. Bid-OrderOpenPrice()= ",Bid-OrderOpenPrice(), " minProfit ", minProfit*Point);
          }
         } // close �������� ����������� ������ 
        }
       } // Close ������� ������� ������� BUY
        
       if (OrderType()==OP_SELL) // ������� �������� ������� SELL
       {
        if (!isMinProfit && OrderOpenPrice()-Ask > minimumProfitLvl*Point) // �������� ������������ ������ �������
        {
         isMinProfit = true;
         Alert("Sell, ��� ������ �� ����������. ���������� ������. isMinProfit = ",isMinProfit);
        }

        if (isMinProfit && Ask > OrderOpenPrice())
        {
         Alert("��� ������ ��� ��������� �����, ������� 0 ��������� ������� ������");
	      isMinProfit = false; // ������ ������
	      barNumber = 0;
        }
        
        if (useLowTF_EMA_Exit)
        {
         if (OrderOpenPrice()-Ask > minProfit*Point)
         {
          if (iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 0)
                 < iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 0) - deltaEMAtoEMA*Point) // �������� �������� EMA  �� ������� ��
          {
           ClosePosBySelect(Ask, "�������� ����������� �������, �������� ��� �� ������� ��, ��������� �������");// ��������� ������� SELL
           Alert("������� �����, �������� ����������. OrderOpenPrice()-Ask= ",OrderOpenPrice()-Ask, " minProfit ", minProfit*Point);
          }
         } // close �������� ����������� ������
        }
       } // Close ������� �������� ������� SELL
      } // close _MagicNumber �� ����� jr_Timeframe
     } // close OrderSelect 
    } // close for
   } // close total > 0

   if( isNewBar(elder_Timeframe) ) // �� ������ ����� ���� �������� �� ��������� ����� � ��������� �� �������
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
          ClosePosBySelect(-1, "������ �� ���� � ������� ������� ������ �����");// ��������� �������
         }
        }
       } 
      }
     }
    }
   
    trendDirection[frameIndex][0] = TwoTitsTrendCriteria(elder_Timeframe, elder_MACD_channel, eld_EMA1, eld_EMA2, eldFastMACDPeriod, eldSlowMACDPeriod);
    if (trendDirection[frameIndex][0] > 0) // ���� ����� ����� �� ������� ����������
    {
     trendDirection[frameIndex][1] = 1;
    }
    if (trendDirection[frameIndex][0] < 0) // ���� ����� ����
    {
     trendDirection[frameIndex][1] = -1;
    }
   } // close isNewBar(elder_Timeframe) 
   //-------------------------------------------------------------------------------------------
   // ����
   //------------------------------------------------------------------------------------------- 
   double stochastic0;
   double stochastic1;     
   if (trendDirection[frameIndex][0] == 0)    // ���������� ����, ����� ���� �������� ����� �� MACD, �����������.
   {
    if (Ask > iMA(NULL, elder_Timeframe, 3, 0, 1, PRICE_HIGH, 0) + hairLength*Point)
    {
     trendDirection[frameIndex][0] = 1;
     trendDirection[frameIndex][1] = 1;
     return(0);
    }
    if (Bid < iMA(NULL, elder_Timeframe, 3, 0, 1, PRICE_LOW, 0) - hairLength*Point)
    {
     trendDirection[frameIndex][0] = -1;
     trendDirection[frameIndex][1] = -1;
     return(0);
    }
    
    stochastic0 = iStochastic(NULL, elder_Timeframe, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
    stochastic1 = iStochastic(NULL, elder_Timeframe, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,2);
    if (stochastic0 < topStochastic && stochastic1 > topStochastic) // ��������� �������� ������ ����, ���� ����������� - ����� ���������
    {
     if (iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 1) < iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
         iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 2) > iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // ����������� ��� ������ ����
     { 
     if (Ask > iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point)
     {  
      openPlace = "������� �� ����, ��������� �������, �� ������� ����������� ��� ������ ���� ";
      ticket = DesepticonOpening(-1, elder_Timeframe);
      if (ticket > 0)
      {
       Alert("������� ������, ������ ������");
       for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
       {
        wantToOpen[frameIndex][0] = 0;
        wantToOpen[frameIndex][1] = 0;
        barsCountToBreak[frameIndex][0] = 0;
        barsCountToBreak[frameIndex][1] = 0;
       }
	    isMinProfit = false; // ������ ������
	    barNumber = 0;
      }
     }
    } // close ����������� ��� ������ ����   
   }  // close ��������� �������       
	 
   if (stochastic0 > bottomStochastic && stochastic1 < bottomStochastic) // ��������� �����, ����������� - ����� ��������
   {  			   
    if (iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 1) > iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
        iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 2) < iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // ����������� ��� ����� �����
    {
     if (Bid < iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point)
     {   
      openPlace = "������� �� ����, ��������� �����, �� ������� ����������� ��� ����� ����� ";
      ticket = DesepticonOpening(1, elder_Timeframe);
      if (ticket > 0)
      {
       Alert("������� ������, ������ ������");
       for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
       {
        wantToOpen[frameIndex][0] = 0;
        wantToOpen[frameIndex][1] = 0;
        barsCountToBreak[frameIndex][0] = 0;
        barsCountToBreak[frameIndex][1] = 0;
       }
	    isMinProfit = false; // ������ ������
	    barNumber = 0;
      }
     }
    } // close ����������� ��� ����� �����
   } // close ��������� �����
  } // close ����	
 } // close ����
//----
 if (useTrailing) DesepticonTrailing(NULL, jr_Timeframe); 
 return(0);
} // close start
//+------------------------------------------------------------------+