//+------------------------------------------------------------------+
//|                                             IndicatorManager.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ��������� ���� ��� ������ � ������������                         |
//+------------------------------------------------------------------+

 // ������� ��������� ��������� �� ������
 void SetIndicatorByHandle (string symbol,ENUM_TIMEFRAMES period,int handle_indicator)
  {
   //������� ���� � �������� � �������� ������ ���� ��� ���
   bool chart = true;
   long z = ChartFirst();
   // �������� �� �������� � ���� ������ � �������� �������� � �����������
   while (chart && z>=0)
    {
     if ( ChartSymbol(z)== symbol && ChartPeriod(z)==period ) 
       {
        chart=false;
        break;
       }
     z = ChartNext(z);
    }
   // ���� �� ��� ������ �� ���� ������ � ��������� �������� � ��������, ��������� ���
   if (chart) z = ChartOpen(symbol, period);
   // � ��������� ���������� �� ��������� ������
   ChartIndicatorAdd(z,0, handle_indicator);   
  }   
  
 // ������� ���������, ���� �� ��������� � �������� ������ �� ����� ������ ������� � ���������� ��� �����
 int DoesIndicatorExist (string symbol,ENUM_TIMEFRAMES period,string indicator_name)
  {
   bool chart = true;
   int handleIndicator = INVALID_HANDLE;
   long z = ChartFirst();
   // �������� �� �������� � ���� ������ � �������� �������� � �����������
   while (chart && z>=0)
    {
     // ���� ������ ������ � �������� �������� � �����������
     if ( ChartSymbol(z)== symbol && ChartPeriod(z)==period ) 
       {
        handleIndicator = ChartIndicatorGet(z,0,indicator_name);  
        // ���� ������ ��������� �� ������� ������
        if (handleIndicator!=INVALID_HANDLE)
         {
          return (handleIndicator);
         }
       }
     z = ChartNext(z);
    }
   return (handleIndicator);
  }     