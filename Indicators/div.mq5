//+------------------------------------------------------------------+
//|                                                          div.mq5 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot div
#property indicator_label1  "div"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

ENUM_MA_METHOD Method = MODE_SMA; // ����� �����������

double orderVolume = 0.1; // ����� ������
int kPeriod = 5; // �-������
int dPeriod = 3; // D-������
int slov  = 3; // ����������� �������. ��������� �������� �� 1 �� 3.

int stoHandle; // ��������� �� ���������.
int period = 12; // �������������� ������, ���������� �����.

int d; // ���� �����������
int c; // ���� ������������
double rightPoint;
double leftPoint;
int rightIndex;
int leftIndex;
double rpSto; // right point stochastic
double lpSto; // left point stochastic
int riSto; // right index stochastic
int liSto; // left index stochastic
int firstBar; // ������ ����, � ������� ���������� ����������.
int bar; // ������ ����� ��������������� �������.

double main[]; // ������ �����������/��������� ����������.

//--- indicator buffers
double         divBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   stoHandle = iStochastic(NULL, 0, kPeriod, dPeriod, slov, Method, STO_LOWHIGH); // ������������� ���������.
   if (stoHandle < 0)
   {
    Print("Error: ����� (���������) �� ���������������!", GetLastError());
    return(-1);
   }
   else Print("������������� ������ (���������) ������ �������!");
   
   
//--- indicator buffers mapping
   SetIndexBuffer(0,divBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, period - 1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(isNewBar() == true)
   {
    if (rates_total < period - 1)
    {
     return(0);
    }
    
    if (CopyBuffer(stoHandle, MAIN_LINE, 0, rates_total, main) < 0) // ���������� � �������� ������� �������� �����.
    {
    Print("������ ���������� ������� main");
    return(false);
    }
    
    /*if (prev_calculated == 0)
    {
     firstBar = period - 1 + begin;
    }
    else
    {
     firstBar = prev_calculated - 1;
    }*/
    
    firstBar = period - 1 + begin;
    
    for (bar = firstBar; bar < rates_total; bar++)
    {
     d = 1;
     c = 1;
     rightPoint = 0;
     leftPoint = 0;
     rightIndex = 0;
     leftIndex = 0;
     rpSto = 0;
     lpSto = 0;
     riSto = 0;
     liSto = 0;
     
     for (int i = 2; i < (period - 1); i++)
     { 
      //---------------------------------------------------------- ����������� ���� -------------------------------------------------------------
      if ((price[bar - i] > price[bar - (i-1)]) && (price[bar - i] > price[bar - (i+1)]) && (d > 0)) // ������� �� ���� ��� ���������� �����������
      {
       if (i == 2) // ��������� ������ ���� �� ������ ���������������� ����
       {
        rightPoint = price[bar - i]; // ��������� �������� �� ������ ����
        rightIndex = bar - i; // ��������� ������ ����
        c = -1; // ������������ �� ������ ������� ��� ���������
       }
       else
       {
        if (rightPoint > price[bar - i])
        {
         leftPoint = price[bar - i];
         leftIndex = bar - i;
        }
        else
        {
         rightPoint = 0;
         d = -1;
        }
       }
      }
      else
      {
       if (i == 2) // ���� �� ������ ���� ��� ���������
       {
        d = -1; // ������ ���� ������ ������ ���� ��� �����������
        lpSto = 101; // ����� �������� ���� ���������, ��� ��������� � ���������� ��������� ����������
       }
      }
      
      //---------------------------------------------------------- ������������ ���� ----------------------------------------------------------
      if ((price[bar - i] < price[bar - (i-1)]) && (price[bar - i] < price[bar - (i+1)]) && (c > 0)) // ������� �� ���� ��� ���������� ���������
      {
       if (i == 2) // ��������� ������ ���� �� ������ ���������������� ����
       {
        rightPoint = price[bar - i]; // ��������� ������� �� ������ ����
        rightIndex = bar - i; // ��������� ������ ����
       }
       else
       {
        if (rightPoint < price[bar - i])
        {
         leftPoint = price[bar - i];
         leftIndex = bar - i;
        }
        else
        {
         rightPoint = 0;
         c = -1;
        }
       }
      }
      else
      {
       if (i == 2) // ���� �� ������ ���� ��� ��������
       {
        c = -1; // ������ ���� ������ ������ ���� ��� ���������
       }
      }
      
      //---------------------------------------------------------- ����������� ���������� -----------------------------------------------------
      if ((main[bar - i] > main[bar - (i-1)]) && (main[bar - i] > main[bar - (i+1)]) && (d > 0)) // ������� �� ��������� ��� ���������� �����������
      {
       if ((i < 5) && (rpSto == 0) && (main[bar - i] < 80))
       {
        rpSto = main[bar - i];
        riSto = bar - i;
       }
       else
       {
        if ((main[bar - i] > 80) && (main[bar - i] > lpSto) && (rpSto != 0))
        {
         lpSto = main[bar - i];
         liSto = bar - i;
        }
       }
      }
      
      //---------------------------------------------------------- ������������ ���������� ----------------------------------------------------
      if ((main[bar - i] < main[bar - (i-1)]) && (main[bar - i] < main[bar - (i+1)]) && (c > 0)) // ������� �� ��������� ��� ���������� ���������
      {
       if ((i < 5) && (rpSto == 0) && (main[bar - i] > 20))
       {
        rpSto = main[bar - i];
        riSto = bar - i;
       }
       else
       {
        if ((main[bar - i] < 20) && (main[bar - i] < lpSto) && (rpSto != 0))
        {
         lpSto = main[bar - i];
         liSto = bar - i;
        }
       }
      }
     }
     
     if((rightPoint > 0) && (leftPoint > 0) && (rpSto > 0) && (lpSto > 0) && (lpSto < 101))
     {
      divBuffer[leftIndex] = leftPoint;
      divBuffer[rightIndex] = rightPoint;
     }
     
     
    }
    
   }
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   
  }
//+------------------------------------------------------------------+
  bool isNewBar()
  {
   static datetime lastTime = 0; // ����� �������� ���������� ����.
   datetime lastBarTime = (datetime)SeriesInfoInteger(_Symbol, 0, SERIES_LASTBAR_DATE); // ����� �������� ������ ����
   
   if (lastTime == 0)
   {
    lastTime = lastBarTime;
    return (false);
   }
   
   if (lastTime != lastBarTime)
   {
    lastTime = lastBarTime;
    return (true);
   }
   return(false);  
  }