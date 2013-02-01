//+------------------------------------------------------------------+
//|                                               Example4NewBar.mq5 |
//|                                            Copyright 2010, Lizar |
//|                                               Lizar-2010@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright 2010, Lizar"
#property link      "Lizar-2010@mail.ru"
#property version   "1.00"

#include <Lib CisNewBar.mqh>

CisNewBar current_chart;   // ��������� ������ CisNewBar: ������� ������
CisNewBar gbpusd_M1_chart; // ��������� ������ CisNewBar: ������ gbpusd, ������ M1
CisNewBar usdjpy_M2_chart; // ��������� ������ CisNewBar: ������ usdjpy, ������ M2

datetime start_time;

void OnInit()
  {
   //--- ������������� ������ ������ ��� �������� �������:
   current_chart.SetSymbol(Symbol());
   current_chart.SetPeriod(Period()); 
   //--- ������������� ������ ������ ��� gbpusd, ������ M1:
   start_time=TimeCurrent();
   gbpusd_M1_chart.SetSymbol("GBPUSD");
   gbpusd_M1_chart.SetPeriod(PERIOD_M1); 
   //--- ������������� ������ ������ ��� usdjpy, ������ M2:
   usdjpy_M2_chart.SetSymbol("USDJPY");
   usdjpy_M2_chart.SetPeriod(PERIOD_M2); 
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   string          symbol;
   ENUM_TIMEFRAMES period;
   int             new_bars;
   string          comment;
//--- ��������� ��������� ������ current_chart:
   symbol = current_chart.GetSymbol();       // �������� ��� ������� �������, ������������ � ������� ���������� ������.
   period = current_chart.GetPeriod();       // �������� ������ �������, ������������ � ������� ���������� ������.
   if(current_chart.isNewBar())              // ������ ������ �� ����������� ������ ���� ������� isNewBar(), ������������ � ������� ���������� ������
     {     
      comment=current_chart.GetComment();    // �������� ����������� ���������� ������, ������� �������� � ������� ���������� ������.
      new_bars = current_chart.GetNewBars(); // �������� ���������� ������������ ����� �����, ������� ��������� � ������� ���������� ������.
      Print(symbol,GetPeriodName(period),comment," ���������� ����� �����=",new_bars," �����=",TimeToString(TimeCurrent(),TIME_SECONDS));
      
      //--- ��������� ��������� ������ gbpusd_M1_chart:
         symbol = gbpusd_M1_chart.GetSymbol();       // �������� ��� ������� �������, ������������ � ������� ���������� ������.
         period = gbpusd_M1_chart.GetPeriod();       // �������� ������ �������, ������������ � ������� ���������� ������.
         gbpusd_M1_chart.SetLastBarTime(start_time); // �������������� m_lastbar_time ���������� ������ ���������
         if(gbpusd_M1_chart.isNewBar())              // ������ ������ �� ����������� ������ ���� ������� isNewBar(), ������������ � ������� ���������� ������
           {     
            new_bars = gbpusd_M1_chart.GetNewBars(); // �������� ���������� ������������ ����� �����, ������� ��������� � ������� ���������� ������.
            Print(symbol,GetPeriodName(period)," ���������� ����� � ������� ������ ���������=",new_bars," �����=",TimeToString(TimeCurrent(),TIME_SECONDS));
           }
      //---
      
      //--- ��������� ��������� ������ gbpusd_M1_chart:
         symbol = usdjpy_M2_chart.GetSymbol();       // �������� ��� ������� �������, ������������ � ������� ���������� ������.
         period = usdjpy_M2_chart.GetPeriod();       // �������� ������ �������, ������������ � ������� ���������� ������.
         usdjpy_M2_chart.SetLastBarTime(0);          // �������������� m_lastbar_time ������� ���������, ������������ ������� �������� ������� �������
         if(usdjpy_M2_chart.isNewBar())              // ������ ������ �� ����������� ������ ���� ������� isNewBar(), ������������ � ������� ���������� ������
           {     
            new_bars = usdjpy_M2_chart.GetNewBars(); // �������� ���������� ������������ ����� �����, ������� ��������� � ������� ���������� ������.
            Print(symbol,GetPeriodName(period)," ���������� ����� �����=",new_bars," �����=",TimeToString(TimeCurrent(),TIME_SECONDS));
           }     
         else
           {
            comment=usdjpy_M2_chart.GetComment();    // �������� ����������� ���������� ������, ������� �������� � ������� ���������� ������.
            uint error=usdjpy_M2_chart.GetRetCode(); // �������� ����� ������, ����������� � ������� ���������� ������.
            Print(symbol,GetPeriodName(period),comment," ������ ",error," �����=",TimeToString(TimeCurrent(),TIME_SECONDS));
           }
     }
   else
     {
      uint error=current_chart.GetRetCode(); // �������� ����� ������, ����������� � ������� ���������� ������.
      if(error!=0)
        {
         comment=current_chart.GetComment();    // �������� ����������� ���������� ������, ������� �������� � ������� ���������� ������.
         Print(symbol,GetPeriodName(period),comment," ������ ",error," �����=",TimeToString(TimeCurrent(),TIME_SECONDS));
        }
     }
  }

//+------------------------------------------------------------------+
//| ���������� ��������� �������� �������                            |
//+------------------------------------------------------------------+
string GetPeriodName(ENUM_TIMEFRAMES period)
  {
   if(period==PERIOD_CURRENT) period=Period();
//---
   switch(period)
     {
      case PERIOD_M1:  return(" M1 ");
      case PERIOD_M2:  return(" M2 ");
      case PERIOD_M3:  return(" M3 ");
      case PERIOD_M4:  return(" M4 ");
      case PERIOD_M5:  return(" M5 ");
      case PERIOD_M6:  return(" M6 ");
      case PERIOD_M10: return(" M10 ");
      case PERIOD_M12: return(" M12 ");
      case PERIOD_M15: return(" M15 ");
      case PERIOD_M20: return(" M20 ");
      case PERIOD_M30: return(" M30 ");
      case PERIOD_H1:  return(" H1 ");
      case PERIOD_H2:  return(" H2 ");
      case PERIOD_H3:  return(" H3 ");
      case PERIOD_H4:  return(" H4 ");
      case PERIOD_H6:  return(" H6 ");
      case PERIOD_H8:  return(" H8 ");
      case PERIOD_H12: return(" H12 ");
      case PERIOD_D1:  return(" Daily ");
      case PERIOD_W1:  return(" Weekly ");
      case PERIOD_MN1: return(" Monthly ");
     }
//---
   return("unknown period");
  }
  
/*     else
     {
      uint error=current_chart.GetRetCode();
      if(error!=0)
        {
         Print(symbol,GetPeriodName(period),comment," ������ ",error," �����=",TimeToString(TimeCurrent(),TIME_SECONDS));
        }
     }*/