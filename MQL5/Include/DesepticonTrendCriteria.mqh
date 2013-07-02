//+------------------------------------------------------------------+
//|                                      DesepticonTrendCriteria.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#include <CompareDoubles.mqh>
#include <SearchExtremum.mqh>
#define DEPTH 200                                   //������� ������ ��� InitTrendDirection � SearchForTits

int InitTrendDirection (int handleMACD, int handleFastEMA, int handleSlowEMA, int deltaEMA, double channel_MACD)
{
 //Print("������ InitTrendDirection");
 int i = 0;                                                 
 double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
 
 double iMACD_buf[DEPTH] = {0};                       //������������� �������� ��������
 double iMA_fast_buf[DEPTH] = {0};                    //
 double iMA_slow_buf[DEPTH] = {0};                    //
 
 ArraySetAsSeries(iMACD_buf, false);        //���������� � �������� ��� � ����������
 ArraySetAsSeries(iMA_fast_buf, false);     //��������� ������ ������� = 0 �������
 ArraySetAsSeries(iMA_slow_buf, false);     //
 
 if (handleMACD == INVALID_HANDLE || handleFastEMA == INVALID_HANDLE || handleSlowEMA == INVALID_HANDLE )
 {
  Alert(__FUNCTION__, "INVALID_HANDLE");
 }
 else
 {
  //Print(__FUNCTION__, "hMACD = ", handleMACD, "; hF_EMA = ", handleFastEMA, "; hS_EMA = ", handleSlowEMA);
 }
 
 //Print("�������� ������ InitTrendDirection");
 //Print("Begin sleep");
 Sleep(10000);                                          //����� ��� ���� ��� �� ���������� ������ �����������
 //Print("End sleep");
 int sizeMACD, sizeF_EMA, sizeS_EMA, ERROR;
 sizeMACD = CopyBuffer(handleMACD, 0, 0, DEPTH, iMACD_buf);           //���������� �������� ��������
 sizeF_EMA = CopyBuffer(handleFastEMA, 0, 0, DEPTH, iMA_fast_buf);    //
 sizeS_EMA = CopyBuffer(handleSlowEMA, 0, 0, DEPTH, iMA_slow_buf);    //
 //Alert (__FUNCTION__, "sizeMACD = ", sizeMACD, "; sizeF_EMA = ", sizeF_EMA, "; sizeS_EMA = ", sizeS_EMA, "; depth = ", DEPTH);
 if (sizeMACD < 0 || sizeF_EMA < 0 || sizeS_EMA < 0)
 {
  ERROR = GetLastError ();
  ResetLastError();
  Print (__FUNCTION__, "�� ������� ����������� ������ � ������������ ������(MACD || EMA). ERROR = .", ERROR);
  return (0);
 }
 
 while (i < DEPTH)
 {
  //Alert("BEGIN OF WHILE");
  while ((i < sizeMACD) && GreatDoubles(channel_MACD, MathAbs (iMACD_buf[i]))) 
  {                                                             //���������� ��� ������� ����� ��������� �������� ������ channel_MACD
   i++;                                                      
  }
//  Alert("��������� ��� ������������ ��� ��������. i = ", i , "  �� ", depth);
  if ((i < sizeF_EMA) && (i < sizeS_EMA))
  {
   if (LessDoubles(iMA_fast_buf[i], (iMA_slow_buf[i] - deltaEMA*point))) 
   {                                                           //������� EMA ���� ��������� EMA => ���������� �����
    //Alert ("DOWN, i = ", i, " (", depth, ") ; EMAfast = ", iMA_fast_buf[i], "; EMAslow = ", iMA_slow_buf[i]);
    return(-1);
   }
   else if (GreatDoubles(iMA_fast_buf[i], iMA_slow_buf[i] + deltaEMA*point)) 
        {                                                           //��������� EMA ���� ������� EMA => ���������� �����
         //Alert ("UP, i = ", i, " (", depth, ") ; EMAfast = ", iMA_fast_buf[i], "; EMAslow = ", iMA_slow_buf[i]);
         return(1);
        }
   i++;
  }
 }
 if (i >= DEPTH)
  Alert(__FUNCTION__, "��������!!! ����� ������� ������� ������� MACD, ��������� ����������� ������ �� ����������! �������� ������������ ������ ��������!");
 
 return(0);
}

bool searchForTits(int handleMACD, double channel_MACD, bool bothTits)
{
 int i = 0;
 int extremum = 0;
 bool isMax = false;
 bool isMin = false;
 int sizeMACD = 0;
 double iMACD_buf[DEPTH];
 ArraySetAsSeries(iMACD_buf, true);
 sizeMACD = CopyBuffer(handleMACD, 0, 0, DEPTH, iMACD_buf);
 if (sizeMACD < 0)
 {
  Alert (__FUNCTION__, "�� ������� ��������� ����� ���������� MACD");
  return(false);
 }
 
 while ((i < sizeMACD) && LessDoubles(MathAbs(iMACD_buf[i]), channel_MACD))    
 {
  extremum = isMACDExtremum(handleMACD, i);
  if (extremum != 0)
  {
   if (extremum < 0)
   {
    //Alert (" ������ ������� ", i, " ����� �����" );
    isMin = true;
   }
   else if (extremum > 0)
        {
         //Alert (" ������ �������� ", i, " ����� �����" );
         isMax = true;
        } 
        
   if (isMin && isMax) break;
  }
  i++;
 }
 
 if (bothTits) // ���� ����� ��� ������ ��� �����
  return (isMin && isMax); // ���������� ��� ������ ���� ��� ������ �������
 else 
  return (isMin || isMax); // ���������� ��� ���� ������� ���� �� ����
}

int TwoTitsCriteria (int handleMACD, int handleFastEMA, int handleSlowEMA, int deltaEMA, double channel_MACD, int currentTrend, int historyTrend)
{                                               
 double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
 
 double iMACD_buf[1];                       //������������� �������� ��������
 double iMA_fast_buf[1];                    //
 double iMA_slow_buf[1];                    //
 
 ArraySetAsSeries(iMACD_buf, true);        //���������� � �������� ��� � ����������
 ArraySetAsSeries(iMA_fast_buf, true);     //��������� ������ ������� = 0 �������
 ArraySetAsSeries(iMA_slow_buf, true);     //
 
 int sizeMACD, sizeF_EMA, sizeS_EMA;
 sizeMACD = CopyBuffer(handleMACD, 0, 1, 1, iMACD_buf);           //���������� �������� ��������
 sizeF_EMA = CopyBuffer(handleFastEMA, 0, 1, 1, iMA_fast_buf);    //
 sizeS_EMA = CopyBuffer(handleSlowEMA, 0, 1, 1, iMA_slow_buf);    //
// Alert ("sizeMACD = ", sizeMACD, "; sizeF_EMA = ", sizeF_EMA, "; sizeS_EMA = ", sizeS_EMA);
 if (sizeMACD < 0 || sizeF_EMA < 0 || sizeS_EMA < 0)
 {
  Print (__FUNCTION__, "�� ������� ����������� ������ � ������������ ������(MACD || EMA). �������� �������� � ���������� depth.");
  return (0);
 }
 
 if (LessDoubles(MathAbs(iMACD_buf[0]), channel_MACD))
 {
  if (searchForTits(handleMACD, channel_MACD, true))
  {
   return(0);
  }
  return (currentTrend);
 }
  
 if (LessDoubles(iMA_fast_buf[0], iMA_slow_buf[0] - deltaEMA*point)) 
 {                                                           //������� EMA ���� ��������� EMA => ���������� �����
  //Alert ("DOWN, i = ", i, " (", depth, ") ; EMAfast = ", iMA_fast_buf[i], "; EMAslow = ", iMA_slow_buf[i]);
  return(-1);
 }
 else if (GreatDoubles(iMA_fast_buf[0], iMA_slow_buf[0] + deltaEMA*point)) 
      {                                                           //��������� EMA ���� ������� EMA => ���������� �����
       //Alert ("UP, i = ", i, " (", depth, ") ; EMAfast = ", iMA_fast_buf[i], "; EMAslow = ", iMA_slow_buf[i]);
       return(1);
      }
      else
      {
       return(historyTrend);
      }

 return(0);
}