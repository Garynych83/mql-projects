//+------------------------------------------------------------------+
//|                                              desepticon v004.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

#include <BasicVariables.mqh>
#include <DesepticonVariables.mqh>    // �������� ����������
//------- ������� ��������� ��������� -----------------------------------------+
extern string Expert_Self_Parameters = "Expert_Self_Parameters";

extern int divergenceFastMACDPeriod = 12;
extern int divergenceSlowMACDPeriod = 26;
extern double differencePrice = 10;
extern int depthDiv = 100;
extern int Kperiod = 5;
extern int Dperiod = 3;
extern int slowing = 3;
extern int topStochastic = 80;
extern int bottomStochastic = 20;


//------- ���������� ���������� ��������� -------------------------------------+
double aCorrection[3][2]; // [][0] - ������� ���������, [][1] - �������� ����
double Stochastic;
//------- ����������� ������� ������� -----------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>
//--------------------------------------------------------------- 3 --
#include <AddOnFuctions.mqh> 
#include <CheckBeforeStart.mqh>       // �������� ������� ����������
#include <DesepticonTrendCriteria.mqh>
#include <Correction.mqh>
#include <StochasticDivergenceProcedures.mqh>
//#include <DesepticonBreakthrough2.mqh>
#include <searchForTits.mqh>
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
  ArrayInitialize(aCorrection, 0);
  
  aTimeframe[1,0] = PERIOD_H1;
  aTimeframe[1,4] = MACD_channel;
  
  aTimeframe[2,0] = PERIOD_M5;
  //aTimeframe[2,4] = 0.0001;
  
  for (frameIndex = startTF; frameIndex <= finishTF; frameIndex++)
  {
   InitTrendDirection(aTimeframe[frameIndex, 0], aTimeframe[frameIndex,4]);
   //Alert("���������� ����������� ������");  
   InitDivergenceArray(aTimeframe[frameIndex, 0]);
   //Alert("���������� ������ ����������� MACD");
   InitExtremums(frameIndex);
   //Alert("���������� ���������� MACD");
   InitStoDivergenceArray(aTimeframe[frameIndex, 0]);
   //Alert("���������� ����������� Stochastic");
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
//| Check for buy conditions function                                |
//+------------------------------------------------------------------+
int CheckBuyCondition()
{
 if (wantToOpen[frameIndex][0] > 0) // ����� ����������� �� ������� MACD ����� (���� ����)
 { 
  openPlace = openPlace + " ����������� �� ������� MACD �����";
  return(100);
 }
 if (wantToOpen[frameIndex][1] > 0) // ����� ����������� �� ������� ���������� ����� (���� ����)
 {    
  openPlace = openPlace + " ����������� �� ������� ���������� �����";
  return(100);
 }
 if (wantToOpen[frameIndex + 1][0] > 0) // ����� ����������� �� ������� MACD ����� (���� ����)
 {    
  openPlace = openPlace + " ����������� �� ������� MACD �����";
  return(50);
 }
 if (wantToOpen[frameIndex + 1][1] > 0) // ����� ����������� �� ������� ���������� ����� (���� ����)
 {   
  openPlace = openPlace + " ����������� �� ������� ���������� �����"; 
  return(50);
 }
 
 if (Stochastic < bottomStochastic) // ��������� �����, ����������� - ����� ��������
 {  			   
  if (iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 1) > iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
      iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 2) < iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // ����������� ��� ����� �����
  {
	if (Bid < iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 0) + deltaPriceToEMA*Point)
	{
	 openPlace = " ��������� �����, �� ������� ����������� ��� ����� ����� ";
	 return(100);
	}
  }
 }
 return(0); 
}

//+------------------------------------------------------------------+
//| Check for sell conditions function                               |
//+------------------------------------------------------------------+
int CheckSellCondition()
{
 if (wantToOpen[frameIndex][0] < 0) // ����� ����������� �� ������� MACD ���� (���� �������)
 {    
  openPlace = openPlace + " ����������� �� ������� MACD ����";
  return(100);
 }
 if (wantToOpen[frameIndex][1] < 0) // ����� ����������� �� ������� ���������� ���� (���� �������)
 {  
  openPlace = openPlace + " ����������� �� ������� ���������� ����";
  return(100);
 }
 if (wantToOpen[frameIndex + 1][0] < 0) // ����� ����������� �� ������� MACD ���� (���� �������)
 { 
  openPlace = openPlace + " ����������� �� ������� MACD ����"; 
  return(50);
 }
 if (wantToOpen[frameIndex + 1][1] < 0) // ����� ����������� �� ������� ���������� ���� (���� �������)
 {   
  openPlace = openPlace + " ����������� �� ������� ���������� ����"; 
  return(50);
 }
 
 if (Stochastic > topStochastic) // ��������� �����, ����������� - ����� ��������
 {  			   
  if (iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 1) < iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 1) && 
      iMA(NULL, jr_Timeframe, jr_EMA1, 0, 1, 0, 2) > iMA(NULL, jr_Timeframe, jr_EMA2, 0, 1, 0, 2)) // ����������� ��� ������ ����
  {
	if (Ask > iMA(NULL, elder_Timeframe, 3, 0, 1, 0, 0) - deltaPriceToEMA*Point)
	{
	 openPlace = " ��������� ������, �� ������� ����������� ��� ������ ���� ";
	 return(100);
	}
  }
 }
 return(0);
}

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start(){
 if (_isTradeAllow)
 {
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
         if (OrderType()==OP_SELL || OrderType()==OP_BUY) // ������� �������� ������� SELL
         {
          ClosePosBySelect(-1, "������ �� ���� � ������� ������� ������ �����");// ��������� �������
         }
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
   
   if (wantToOpen[frameIndex][1] != 0) // ���� ������ ����������� �� ����������� Stochastic
   {
    barsCountToBreak[frameIndex][1]++;
    if (barsCountToBreak[frameIndex][1] > breakForStochastic)
    { 
     barsCountToBreak[frameIndex][1] = 0; // ������ 2� ����� ��������, ��� ������ �����������
     wantToOpen[frameIndex][1] = 0;
    }
   }
   
 //--------------------------
 // ��������� ����������� MACD �� �������
 //--------------------------     
   UpdateDivergenceArray(elder_Timeframe); // ��������� ������ ����������� MACD
   InitExtremums(frameIndex); // ��������� ��������� ���� � MACD
   if (wantToOpen[frameIndex][0] == 0) // ���� ��� �� ����� �����������
   {   
    wantToOpen[frameIndex][0] = _isDivergence(elder_Timeframe);  // ��������� �� ����������� �� ���� ����       
   } 
 //--------------------------
 // ��������� ����������� MACD �� �������
 //--------------------------     
   UpdateDivergenceArray(jr_Timeframe); // ��������� ������ ����������� MACD
   InitExtremums(frameIndex + 1); // ��������� ��������� ���� � MACD
   if (wantToOpen[frameIndex + 1][0] == 0) // ���� ��� �� ����� �����������
   {   
    wantToOpen[frameIndex + 1][0] = _isDivergence(jr_Timeframe);  // ��������� �� ����������� �� ���� ����       
   } 
 //--------------------------
 // ��������� ����������� Stochastic �� �������
 //--------------------------    
   InitStoDivergenceArray(elder_Timeframe); 
   if (wantToOpen[frameIndex][1] == 0) // ���� ��� �� ����� �����������
   {   
    wantToOpen[frameIndex][1] = isStoDivergence(elder_Timeframe);  // ��������� �� ����������� �� ���� ����    
   }
 //--------------------------
 // ��������� ����������� Stochastic �� �������
 //--------------------------    
   InitStoDivergenceArray(jr_Timeframe); 
   if (wantToOpen[frameIndex + 1][1] == 0) // ���� ��� �� ����� �����������
   {   
    wantToOpen[frameIndex + 1][1] = isStoDivergence(jr_Timeframe);  // ��������� �� ����������� �� ���� ����    
   }
  } // close isNewBar
    
 //--------------------------------------
 // ��������� �������� ��� ������ �� �������� ��� ����� �� ������� ��
 //--------------------------------------
  if( isNewBar(jr_Timeframe) ) // �� ������ ����� ���� �������� �� ��������� ����� �� �������
  {
   trendDirection[frameIndex + 1][0] = TwoTitsTrendCriteria(jr_Timeframe, jr_MACD_channel, jr_EMA1, jr_EMA2, jrFastMACDPeriod, jrSlowMACDPeriod);
   Alert("trendDirection=",trendDirection[frameIndex + 1][0]);
 //--------------------------
 // ���������� ��� ��� ��� ����� �����������
 //--------------------------     
   if (wantToOpen[frameIndex + 1][0] != 0) // ���� ������ ����������� �� ����������� MACD
   {
    barsCountToBreak[frameIndex + 1][0]++;
    if (barsCountToBreak[frameIndex + 1][0] > breakForMACD)
    { 
     barsCountToBreak[frameIndex + 1][0] = 0; // ������ 4� ����� ��������, ��� ������ �����������
     wantToOpen[frameIndex + 1][0] = 0;
    }
   }
  
   if (wantToOpen[frameIndex + 1][1] != 0) // ���� ������ ����������� �� ����������� Stochastic
   {
    barsCountToBreak[frameIndex + 1][1]++;
    if (barsCountToBreak[frameIndex + 1][1] > breakForStochastic)
    { 
     barsCountToBreak[frameIndex + 1][1] = 0; // ������ 2� ����� ��������, ��� ������ �����������
     wantToOpen[frameIndex + 1][1] = 0;
    }
   }
    
 //--------------------------
 // ���������� ������� �����
 //-------------------------- 
   if (trendDirection[frameIndex + 1][0] > 0) // ���� ����� ����� �� ������� ����������
   { 
    Alert("���� ����� ����� �� ������� ����������");
    trendDirection[frameIndex + 1][1] = 1;
   } 
   if (trendDirection[frameIndex + 1][0] < 0) // ���� ����� ���� �� ������� ����������
   {
    Alert("���� ����� ���� �� ������� ����������");
    trendDirection[frameIndex + 1][1] = -1;
   }
  } // close  isNewBar(jr_Timeframe)
  if (trendDirection[frameIndex + 1][0] == 0) // ���� �� ������� ���� �� �������
  {
   //Alert("��������� ��� ����� �� �����");
   return(0); // ��������� ��� ����� �� �����
  }
 //--------------------------------------
 // ��������� �������� ��� ������ �� �������� ��� ����� �� ������� ��
 //--------------------------------------     
     
  Stochastic = iStochastic(NULL, elder_Timeframe, Kperiod, Dperiod , slowing ,MODE_SMA,0,MODE_MAIN,1);
  buyCondition = CheckBuyCondition();
  sellCondition = CheckSellCondition();
   
  //-------------------------------------------------------------------------------------------
  // ������� ����� �����
  //-------------------------------------------------------------------------------------------
  if (trendDirection[frameIndex][0] > 0) // ���� ����� ����� �� ������� ����������
  {
   trendDirection[frameIndex][1] = 1;
   if (aCorrection[frameIndex][0] < 0) // ��������� ����
   {
    if (buyCondition > sellCondition)
    {
     ticket = DesepticonOpening(1, elder_Timeframe);
     if (ticket > 0)
     {
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
      ticket = OrderTicket();
      Alert("������� ������, �������� ����������, ������ ������.");
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
     openPlace = "";
    }
    if (sellCondition > buyCondition)
    {
     ticket = DesepticonOpening(-1, elder_Timeframe);
     if (ticket > 0)
     {
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
      ticket = OrderTicket();
      Alert("������� ������, �������� ����������, ������ ������.");
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
     openPlace = "";
    }
   } // close ��������� ����
  }
  
  //-------------------------------------------------------------------------------------------
  // ������� ����� ����
  //-------------------------------------------------------------------------------------------     
  if (trendDirection[frameIndex][0] < 0) // ���� ����� ����
  {
   trendDirection[frameIndex][1] = -1;
   if (aCorrection[frameIndex][0] > 0) // ��������� �����
   {
    if (buyCondition > sellCondition)
    {
     ticket = DesepticonOpening(1, elder_Timeframe);
     if (ticket > 0)
     {
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
      ticket = OrderTicket();
      Alert("������� ������, ������ ������. ticket=",ticket," OrderExpiration = ", TimeToStr(OrderExpiration(), TIME_DATE),":",TimeToStr(OrderExpiration(), TIME_MINUTES));
      isMinProfit = false; // ������ ������
      barNumber = 0;
     }
     openPlace = "";
    }
    if (sellCondition > buyCondition)
    {
     ticket = DesepticonOpening(-1, elder_Timeframe);
     if (ticket > 0)
     {
      OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES); 
      ticket = OrderTicket();
      Alert("������� ������, ������ ������. ticket=",ticket," OrderExpiration = ", TimeToStr(OrderExpiration(), TIME_DATE),":",TimeToStr(OrderExpiration(), TIME_MINUTES));
      isMinProfit = false; // ������ ������
      barNumber = 0;
     }
     openPlace = "";
    }
   } // close ��������� ����� 
  }
//}
//----
  if (useTrailing) DesepticonTrailing(NULL, jr_Timeframe);
  return(0);
 } // close isTradeAllow
}
//+------------------------------------------------------------------+


