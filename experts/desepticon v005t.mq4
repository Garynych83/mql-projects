//+------------------------------------------------------------------+
//|                                             desepticon trend.mq4 |
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
#include <BasicVariables.mqh>
#include <DesepticonVariables.mqh>    // �������� ����������
#include <AddOnFuctions.mqh> 
#include <CheckBeforeStart.mqh>       // �������� ������� ����������
#include <DesepticonTrendCriteria.mqh>
#include <Correction.mqh>
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
  
  ArrayInitialize(aCorrection, 0);
  
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   trendDirection[frameIndex][0] = InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("trendDirection[0]=",trendDirection[frameIndex][0], " frameIndex=",frameIndex);
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
int start()
{
 if (_isTradeAllow)
 {
  frameIndex = startTF;
  jr_Timeframe = PERIOD_M5;
  elder_Timeframe = PERIOD_H1;
    
  jr_MACD_channel = aTimeframe[frameIndex + 1, 4];
  elder_MACD_channel = aTimeframe[frameIndex, 4];
     
  if (!CheckBeforeStart())   // ��������� ������� ���������
  {
   PlaySound("alert2.wav");
   _isTradeAllow = false;
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
        if (!isMinProfit && Bid-OrderOpenPrice() > minimumProfitLvl*Point) // �������� ������������ ������ �������
        {
         isMinProfit = true;
         Alert("��� ������ �� ����������. ���������� ������. isMinProfit = ",isMinProfit);
        }
        
        if (useLowTF_EMA_Exit)
        {
         if (Bid-OrderOpenPrice() > minProfit*Point) // �������� ����������� ������
         {
          if (iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 0) 
                 > iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 0) + deltaEMAtoEMA*Point) // �������� �������� EMA  �� ������� ��
          {
           ClosePosBySelect(Bid, "�������� ����������� �������, �������� ��� �� ������� ��, ��������� �������"); // ��������� ������� BUY
           Alert("������� �����, �������� ����������. Bid-OrderOpenPrice()= ",Bid-OrderOpenPrice(), " MinProfit ", minProfit*Point);
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
        
        if (useLowTF_EMA_Exit)
        {
         if (OrderOpenPrice()-Ask > minProfit*Point)
         {
          if (iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 0)
                 < iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 0) - deltaEMAtoEMA*Point) // �������� �������� EMA  �� ������� ��
          {
           ClosePosBySelect(Ask, "�������� ����������� �������, �������� ��� �� ������� ��, ��������� �������");// ��������� ������� SELL
           Alert("������� �����, �������� ����������. OrderOpenPrice()-Ask= ",OrderOpenPrice()-Ask, " MinProfit ", minProfit*Point);
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
   if( isNewBar(jr_Timeframe) ) // �� ������ ����� ���� �������� �� ��������� ����� �� �������
   {
    trendDirection[frameIndex + 1][0] = TwoTitsTrendCriteria(jr_Timeframe, jr_MACD_channel, jr_EMA1, jr_EMA2, jrFastMACDPeriod, jrSlowMACDPeriod);
    if (trendDirection[frameIndex + 1][0] > 0) // ���� ����� ����� �� ������� ����������
    { 
     trendDirection[frameIndex + 1][1] = 1;
    } 
    if (trendDirection[frameIndex + 1][0] < 0) // ���� ����� ����� �� ������� ����������
    {
     trendDirection[frameIndex + 1][1] = -1;
    }
   } // close  isNewBar(jr_Timeframe)
   if (trendDirection[frameIndex + 1][0] == 0) // ���� �� ������� ���� �� �������
   {
    //Alert("���� �� �������");
    return(0); // ��������� ��� ����� �� �����
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
      if (iLow(NULL, elder_Timeframe, 1) < iMA(NULL, elder_Timeframe, eld_EMA1, 0, 1, 0, 1) + deltaPriceToEMA*Point ||
          iLow(NULL, elder_Timeframe, 0) < iMA(NULL, elder_Timeframe, eld_EMA1, 0, 1, 0, 0) + deltaPriceToEMA*Point) // �� ��������� 2-� ����� ���� ���� ���� �������� ���       
      {
       if (iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 1) > iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
           iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 2) < iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // ����������� ��� ����� �����
       {
        openPlace = "������� ����� �����, �� ������� ����������� ��� ����� ����� ";
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
      if (iHigh(NULL, elder_Timeframe, 1) > iMA(NULL, elder_Timeframe, eld_EMA1, 0, 1, 0, 1) - deltaPriceToEMA*Point ||
          iHigh(NULL, elder_Timeframe, 0) > iMA(NULL, elder_Timeframe, eld_EMA1, 0, 1, 0, 0) - deltaPriceToEMA*Point) // �� ��������� 2-� ����� ���� ���� ���� �������� ���
      {
       if (iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 1) < iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
           iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 2) > iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // ����������� ��� ������ ����
       {
        openPlace = "������� ����� ����, �� ������� ����������� ��� ������ ���� Ask=" + Ask + "  EMA="+ (iMA(NULL, PERIOD_D1, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point);
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
       } // close ����������� ��� ������ ����
      } // close �� ��������� 2-� ����� ���� ���� ���� �������� ��� 
     } // close �� �������� ���� ���� ��� �� ������ ���� ���3
    } // close else ��������� ����� 
   }
//----
	if (useTrailing) DesepticonTrailing(NULL, jr_Timeframe); 
	return(0);
  } // close isTradeAllow
} // close start
//+------------------------------------------------------------------+