//+------------------------------------------------------------------+
//|                                              desepticon v004.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

//------- ������� ��������� ��������� -----------------------------------------+
extern int hairLength = 250;

extern int divergenceFastMACDPeriod = 12;
extern int divergenceSlowMACDPeriod = 26;

extern double differencePrice = 10;
//------- ���������� ���������� ��������� -------------------------------------+


//------- ����������� ������� ������� -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <DesepticonVariables.mqh>    // �������� ���������� 
#include <AddOnFuctions.mqh> 
#include <CheckBeforeStart.mqh>       // �������� ������� ����������
#include <DesepticonTrendCriteria.mqh>
//#include <direction_MACD.mqh>
#include <DesepticonBreakthrough2.mqh>
#include <searchForTits.mqh>
//#include <DesepticonDivergence.mqh>
#include <GetLastOrderHist.mqh>
#include <GetLots.mqh>     // �� ����� ���������� ����� �����������
#include <isNewBar.mqh>
#include <UpdateDivergenceArray.mqh>
#include <isMACDExtremum.mqh>
#include <_isDivergence.mqh>
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
  
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   // �������������� ����������� MACD
   InitDivergenceArray(aTimeframe[frameIndex, 0]);
   //Alert("���������� ������ ����������� MACD");
   InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("���������� ����������� ������");
   InitExtremums(frameIndex);
   //Alert("���������� ���������� MACD");
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
	for (frameIndex = startTF; frameIndex < finishTF; frameIndex++){
     //Alert ("���� �� ����� ��");
     //Alert ("frameIndex", frameIndex);
     Jr_Timeframe = aTimeframe[frameIndex, 9];
     Elder_Timeframe = aTimeframe[frameIndex, 0];
     
     TakeProfit = aTimeframe[frameIndex, 1];
     StopLoss_min = aTimeframe[frameIndex, 2];
     StopLoss_max = aTimeframe[frameIndex, 3]; 
     Jr_MACD_channel = aTimeframe[frameIndex + 1, 4];
     Elder_MACD_channel = aTimeframe[frameIndex, 4];
     
     minProfit = aTimeframe[frameIndex, 5]; 
     trailingStop_min = aTimeframe[frameIndex, 6];
     trailingStop_max = aTimeframe[frameIndex, 7]; 
     trailingStep = aTimeframe[frameIndex, 8];
     
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
         if (Bid-OrderOpenPrice() > minProfit*Point) // �������� ����������� ������
         {
          if (iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 0) 
                 > iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 0) + deltaEMAtoEMA*Point) // �������� �������� EMA  �� ������� ��
          {
           ClosePosBySelect(Bid, "�������� ����������� �������, �������� ��� �� ������� ��, ��������� �������"); // ��������� ������� BUY
           Alert("������� �����, �������� ����������. Bid-OrderOpenPrice()= ",Bid-OrderOpenPrice(), " minProfit ", minProfit*Point);
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
         if (OrderOpenPrice()-Ask > minProfit*Point)
         {
          if (iMA(NULL, Jr_Timeframe, jr_EMA2, 0, 1, 0, 0)
                 < iMA(NULL, Jr_Timeframe, jr_EMA1, 0, 1, 0, 0) - deltaEMAtoEMA*Point) // �������� �������� EMA  �� ������� ��
          {
           ClosePosBySelect(Ask, "�������� ����������� �������, �������� ��� �� ������� ��, ��������� �������");// ��������� ������� SELL
           Alert("������� �����, �������� ����������. OrderOpenPrice()-Ask= ",OrderOpenPrice()-Ask, " minProfit ", minProfit*Point);
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
          ClosePosBySelect(-1, "������ �� ���� � ������� ������� ������ �����");// ��������� �������
         }
        }
       } 
      }
     }
    }
    
    trendDirection[frameIndex][0] = TwoTitsTrendCriteria(Elder_Timeframe, Elder_MACD_channel, eld_EMA1, eld_EMA2, eldFastMACDPeriod, eldSlowMACDPeriod);
    if (trendDirection[frameIndex][0] > 0) // ���� ����� ����� �� ������� ����������
    {
     trendDirection[frameIndex][1] = 1;
    }
    if (trendDirection[frameIndex][0] < 0) // ���� ����� ����
    {
     trendDirection[frameIndex][1] = -1;
    }
    
//--------------------------
// ���������� ��� ��� ��� ����� �����������
//--------------------------     
    if (wantToOpen[frameIndex][0] != 0) // ���� ������ ����������� �� ����������� MACD
    {
     barsCountToBreak[frameIndex][0]++;
     if (barsCountToBreak[frameIndex][0] > breakForMACD)
     { 
      barsCountToBreak[frameIndex][0] = 0; // ������ 4� ����� ��������, ��� ������ �����������
      wantToOpen[frameIndex][0] = 0;
     }
    }
//--------------------------
// ���������, ��� ��� ��� ����� �����������
//--------------------------     
     
//--------------------------
// ��������� ����������� MACD
//--------------------------     
      
    UpdateDivergenceArray(Elder_Timeframe); // ��������� ������ ����������� MACD
    InitExtremums(frameIndex); // ��������� ��������� ���� � MACD
    if (wantToOpen[frameIndex][0] == 0) // ���� ��� �� ����� �����������
    {   
     wantToOpen[frameIndex][0] = _isDivergence(Elder_Timeframe);  // ��������� �� ����������� �� ���� ����       
    } 
//--------------------------
// ��������� ����������� MACD
//-------------------------- 

   } // close isNewBar(Elder_Timeframe)

   //-------------------------------------------------------------------------------------------
   // ����
   //-------------------------------------------------------------------------------------------      
   if (trendDirection[frameIndex][0] == 0)    // ���������� ����, ����� ���� �������� ����� �� MACD, �����������.
   {
    if (Ask > iMA(NULL, Elder_Timeframe, 3, 0, 1, PRICE_HIGH, 0) + hairLength*Point)
    {
     trendDirection[frameIndex][0] = 1;
     trendDirection[frameIndex][1] = 1;
     return(0);
    }
    if (Bid < iMA(NULL, Elder_Timeframe, 3, 0, 1, PRICE_LOW, 0) - hairLength*Point)
    {
     trendDirection[frameIndex][0] = -1;
     trendDirection[frameIndex][1] = -1;
     return(0);
    }
//--------------------------
// ����������� 
//--------------------------
   if (wantToOpen[frameIndex][0] > 0) // ����� ����������� ����� (���� ����), ���� ������ ���������, ����� ��������
   {
    if (Bid < iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point)
    {
     openPlace = "������� �� ����, " + openPlace;
     if (DesepticonBreakthrough2(1, Jr_Timeframe) > 0) // ��� ������������ ������������� ����, ���� ������, �����������
     {
      Alert("������� ������, ������ ������");
	   isMinProfit = false; // ������ ������
	   barNumber = 0;
     }
    }
   } // close ����� ����������� �����
    
   if (wantToOpen[frameIndex][0] < 0) // ����� ����������� ���� (���� �������), ���� ������ ��������, ����� ���������
   {
    if (Ask > iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point)
    {
     openPlace = "������� �� ����, " + openPlace;
     if (DesepticonBreakthrough2(-1, Jr_Timeframe) > 0) // ��� ������������ ������������� ����, ���� ������, �����������
     {
      Alert("������� ������, ������ ������");
	   isMinProfit = false; // ������ ������
	   barNumber = 0;
     }
    }
   } // close ����� ����������� ����
//--------------------------
// ����������� 
//--------------------------
   
  } // close ����	
 } // close ����
//----
 if (useTrailing) DesepticonTrailing(NULL, Jr_Timeframe); 
 return(0);
} // close start
//+------------------------------------------------------------------+