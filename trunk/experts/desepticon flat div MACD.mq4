//+------------------------------------------------------------------+
//|                                              desepticon v004.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <DesepticonVariables.mqh>    // �������� ���������� 
#include <AddOnFuctions.mqh> 
#include <InitDivergenceArray.mqh>
#include <InitExtremums.mqh>
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
  
  aTimeframe[0,0] = PERIOD_D1; 
  aTimeframe[0,1] = TakeProfit_1D;
  aTimeframe[0,2] = StopLoss_1D_min;
  aTimeframe[0,3] = StopLoss_1D_max;
  aTimeframe[0,4] = MACD_channel_1D;
  aTimeframe[0,5] = MinProfit_1D;
  aTimeframe[0,6] = TrailingStop_1D_min;
  aTimeframe[0,7] = TrailingStop_1D_max;
  aTimeframe[0,8] = TrailingStep_1D;
  aTimeframe[0,9] = PERIOD_H1;
  
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
  aTimeframe[2,1] = TakeProfit_5M;
  aTimeframe[2,2] = StopLoss_5M_min;
  aTimeframe[2,3] = StopLoss_5M_max;
  aTimeframe[2,4] = MACD_channel_5M;
  aTimeframe[2,5] = MinProfit_5M;
  aTimeframe[2,6] = TrailingStop_5M_min;
  aTimeframe[2,7] = TrailingStop_5M_max;
  aTimeframe[2,8] = TrailingStep_5M;
  aTimeframe[2,9] = PERIOD_M5;
  
  ArrayInitialize(aCorrection, 0);

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
     
     MinProfit = aTimeframe[frameIndex, 5]; 
     TrailingStop_min = aTimeframe[frameIndex, 6];
     TrailingStop_max = aTimeframe[frameIndex, 7]; 
     TrailingStep = aTimeframe[frameIndex, 8];
     
     if (!CheckBeforeStart())  return (0); // ��������� ������� ���������
     
     total=OrdersTotal();


     if( isNewBar(Elder_Timeframe) ) // �� ������ ����� ���� �������� �� ��������� ����� � ��������� �� �������
     {
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
	     if (DesepticonBreakthrough2(1, Jr_Timeframe) != 0) // ��� ������������ ������������� ����, ���� ������, �����������
	     {
	      // �������� ���������� ������ �������� ������ 
	     }
	    }
      } // close ����� ����������� �����
    
      if (wantToOpen[frameIndex][0] < 0) // ����� ����������� ���� (���� �������), ���� ������ ��������, ����� ���������
      {
       if (Ask > iMA(NULL, Elder_Timeframe, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point)
       {
        openPlace = "������� �� ����, " + openPlace;
	     if (DesepticonBreakthrough2(-1, Jr_Timeframe) <= 0) // ��� ������������ ������������� ����, ���� ������, �����������
	     {
	      // �������� ���������� ������ �������� ������ 
	     }
	    }
      } // close ����� ����������� ����
	//--------------------------
	// ����������� 
	//--------------------------
   
     } // close ����	
    } // close ����
//----
	if (UseTrailing) DesepticonTrailing(); 
	return(0);
} // close start
//+------------------------------------------------------------------+