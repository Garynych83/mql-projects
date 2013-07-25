//+------------------------------------------------------------------+
//|                                                      CDynamo.mq5 |
//|                                              Copyright 2013, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, GIA"
#property link      "http://www.saita.net"
#property version   "1.00"

#include <CompareDoubles.mqh>
#include <StringUtilities.mqh>
#include <CLog.mqh>

//+------------------------------------------------------------------+
//| ����� ������������ ��������������� �������� ����������           |
//+------------------------------------------------------------------+
class CDynamo
{
protected:
 MqlDateTime m_day_time;          // �����
 MqlDateTime m_last_day_number;   // ����� ���������� ������������� ���
 MqlDateTime m_last_month_number; // ����� ���������� ������������� ������
 
 string m_symbol;                 // ��� �����������
 ENUM_TIMEFRAMES m_period;        // ������ �������
      
 uint m_retcode;          // ��� ���������� ����������� ������ ��� 
 int m_new_day_number;    // ����� ������ ��� (0-6)
 int m_new_month_number;  // ����� ������ ��� (0-6)
 string m_comment;        // ����������� ����������
 
 int deltaFast;   // ������ ��� ������� ������ "�������" ��������
 int deltaSlow;   // ������ ��� ������� ������ "��������" ��������
 double fastVol;  // ����� ��� ������� ��������
 double slowVol;  // ����� ��� �������� ��������
 
 int currentLevelDay;   // ������� ������� ���� ���
 int currentLevelMonth; // ������� ������� ���� ������
 
 // ������ ����������� ������� ��������� ��� �� ���� ������ ������ ���
 double currentDaily[21];
 // ������ ����������� �������� ��������� ��� �� ���� ������ ������ ������
 double currentMonth[21];

 bool newMonth; // ���� ������ ������
 bool isMonthInit; // ���� ������������� ������� ��� ������
 bool isDayInit;  // ���� ������������� ������� ��� ���
public:
//--- ������������
 void CDynamo();      // ����������� CDynamo
 void CDynamo(string symbol);      // ����������� CDynamo � �����������
 void CDynamo(ENUM_TIMEFRAMES period);      // ����������� CDynamo � �����������
 void CDynamo(string symbol, ENUM_TIMEFRAMES period);      // ����������� CDynamo � �����������
 
//--- ������ ������� � ���������� ������:
 uint GetRetCode() const {return(m_retcode);}    // ��� ���������� ����������� ������ ���� 
 MqlDateTime GetLastTime() const {return(m_day_time);}
 MqlDateTime GetLastDay() const {return(m_last_day_number);}  // ����� ���������� ������������� ���
 int GetNewDay() const {return(m_new_day_number);}    // ����� ������ ���
 MqlDateTime GetLastMonth() const {return(m_last_month_number);}  // ����� ���������� ������������� ���
 int GetNewMonth() const {return(m_new_month_number);}    // ����� ������ ���
 string GetComment() const {return(m_comment);}    // ����������� ����������
 string GetSymbol() const {return(m_symbol);}     // ��� �����������
 ENUM_TIMEFRAMES GetPeriod() const {return(m_period);}     // ������ �������
 bool isInit() const {return(isMonthInit && isDayInit);}  // ������������� ��������
//--- ������ ������������� ���������� ������:  
 void SetSymbol(string symbol) {m_symbol = (symbol==NULL || symbol=="") ? Symbol() : symbol; }
 void SetPeriod(ENUM_TIMEFRAMES period) {m_period = (period==PERIOD_CURRENT) ? Period() : period; }

//--- ������� ������ ������
 bool isNewDay();
 bool isNewMonth();
 int MonWenFriEighteen();
 void InitDayTrade();
 void InitMonthTrade();
 void FillArrayWithPrices(double &dstArray[], int start);
 double RecountVolume();
 void RecountDelta();
 bool CorrectOrder(double volume);
};

//+------------------------------------------------------------------+
//| ����������� CDynamo.                                             |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo()
  {
   m_retcode = 0;         // ��� ���������� ����������� ������ ���� 
   ZeroMemory(m_last_day_number);    // ����� �������� ���������� ����
   m_new_day_number = 0;        // ���������� ����� �����
   ZeroMemory(m_last_month_number);    // ����� �������� ���������� ����
   m_new_month_number = 0;        // ���������� ����� �����
   m_comment = "";        // ����������� ����������
   isDayInit = false;
   isMonthInit = false;
   m_symbol = Symbol();   // ��� �����������, �� ��������� ������ �������� �������
   m_period = Period();   // ������ �������, �� ��������� ������ �������� �������
  }
  
//+------------------------------------------------------------------+
//| ����������� CDynamo � �����������                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo(string symbol)
  {
   m_retcode = 0;         // ��� ���������� ����������� ������ ���� 
   ZeroMemory(m_last_day_number);    // ����� �������� ���������� ����
   m_new_day_number = 0;        // ���������� ����� �����
   ZeroMemory(m_last_month_number);    // ����� �������� ���������� ����
   m_new_month_number = 0;        // ���������� ����� �����
   m_comment = "";        // ����������� ����������
   isDayInit = false;
   isMonthInit = false;
   m_symbol=symbol;   // ��� �����������, �� ��������� ������ �������� �������
   m_period=Period();   // ������ �������, �� ��������� ������ �������� �������    
  }
//+------------------------------------------------------------------+
//| ����������� CDynamo � �����������                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo(ENUM_TIMEFRAMES period)
  {
   m_retcode = 0;         // ��� ���������� ����������� ������ ���� 
   ZeroMemory(m_last_day_number);    // ����� �������� ���������� ����
   m_new_day_number = 0;        // ���������� ����� �����
   ZeroMemory(m_last_month_number);    // ����� �������� ���������� ����
   m_new_month_number = 0;        // ���������� ����� �����
   m_comment = "";        // ����������� ����������
   isDayInit = false;
   isMonthInit = false;
   m_symbol=Symbol();   // ��� �����������, �� ��������� ������ �������� �������
   m_period=period;   // ������ �������, �� ��������� ������ �������� �������    
  }

//+------------------------------------------------------------------+
//| ����������� CDynamo � �����������                                |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::CDynamo(string symbol, ENUM_TIMEFRAMES period)
  {
   m_retcode = 0;         // ��� ���������� ����������� ������ ���� 
   ZeroMemory(m_last_day_number);    // ����� �������� ���������� ����
   m_new_day_number = 0;        // ���������� ����� �����
   ZeroMemory(m_last_month_number);    // ����� �������� ���������� ����
   m_new_month_number = 0;        // ���������� ����� �����
   m_comment = "";        // ����������� ����������
   isDayInit = false;
   isMonthInit = false;
   m_symbol=symbol;   // ��� �����������, �� ��������� ������ �������� �������
   m_period=period;   // ������ �������, �� ��������� ������ �������� �������    
  }

//+------------------------------------------------------------------+
//| ������ �� ��������� ������ ���.                                  |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - ���� ����� ����                                 |
//|         false  - ���� �� ����� ���� ��� �������� ������          |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::isNewDay()
  {
   MqlDateTime current_time;
   TimeToStruct(TimeCurrent(), current_time);
      
   //--- ���� ��� ������ ����� 
   if(m_last_day_number.year == 0)
     {  
      log_file.Write(LOG_DEBUG, MakeFunctionPrefix(__FUNCTION__) + "������ �����");
      m_last_day_number = current_time; //--- �������� ������� ���� � ������
      log_file.Write(LOG_DEBUG, StringFormat("%s ������������� m_last_day_number=%s"
                                            , MakeFunctionPrefix(__FUNCTION__)
                                            , TimeToString(StructToTime(m_last_day_number))));
      return(false);
     }  
     
   //--- ��������� ��������� ������ ���: 
   if(m_last_day_number.year < current_time.year || (m_last_day_number.year == current_time.year && m_last_day_number.day_of_year < current_time.day_of_year))
     { 
      m_last_day_number = current_time; // ���������� ������� ����
      //log_file.Write(LOG_DEBUG, StringFormat("%s �������� ��������� ������ ��� ����������� �������", MakeFunctionPrefix(__FUNCTION__)));
      return(true);
     }
  
   //--- ����� �� ����� ����� - ������ ���� �� �����
   return(false);
  }

//+------------------------------------------------------------------+
//| ������ �� 18:00 ������� ���.                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - ���� ������ �����                               |
//|         false  - ���� ����� �� ������ ��� �������� ������        |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CDynamo::MonWenFriEighteen()
{
 MqlDateTime current_time;
 TimeToStruct(TimeCurrent(), current_time);
 
   //--- ���� ��� ������ ����� 
 if(m_day_time.year == 0)
 {  
  log_file.Write(LOG_DEBUG, MakeFunctionPrefix(__FUNCTION__) + "������ �����");
  m_day_time = current_time; //--- �������� ��������� ����� � ������
  log_file.Write(LOG_DEBUG, StringFormat("%s ������������� m_day_time=%s"
                                        , MakeFunctionPrefix(__FUNCTION__)
                                        , TimeToString(StructToTime(m_day_time))));
  return(-1);
 }  
 
 if (current_time.hour < 18)
 {
  m_day_time = current_time;
  return(-1);
 }
 if (m_day_time.hour < 18 && current_time.hour >= 18) 
 {
  m_day_time = current_time;
  return(m_day_time.day_of_week);
 }

 //--- ����� �� ����� ����� - ������ ���� �� �����
 return(-1);
}

//+------------------------------------------------------------------+
//| ������ �� ��������� ������ ������.                               |
//| INPUT:  no.                                                      |
//| OUTPUT: true   - ���� ����� �����                                |
//|         false  - ���� �� ����� ����� ��� �������� ������         |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::isNewMonth()
  {
   MqlDateTime current_time;
   TimeToStruct(TimeCurrent(), current_time);

   //--- ���� ��� ������ ����� 
   if(m_last_month_number.year == 0)
     {  
      log_file.Write(LOG_DEBUG, MakeFunctionPrefix(__FUNCTION__) + "������ �����");
      m_last_month_number = current_time; //--- �������� ������� �����
      m_last_month_number.mon--;          //--- ��� ����� ����� ������ �������� � ��������� 18.00
      newMonth = false;
      log_file.Write(LOG_DEBUG, StringFormat("%s ������������� m_last_month_number=%s"
                                            , MakeFunctionPrefix(__FUNCTION__)
                                            , TimeToString(StructToTime(m_last_month_number))));
      return(false);
     }  
     
   //--- ��������� ��������� ������ ������: 
   if (( m_last_month_number.year < current_time.year   // � ��������� �������� ��������� ���,
      && m_last_month_number.day == current_time.day)   // ���� ������ ���������
       
    ||(  m_last_month_number.year == current_time.year  // ��� ��� ������� �������
      && m_last_month_number.mon < current_time.mon     // ��������� �����
      && m_last_month_number.day == current_time.day))  // ���� ���������
   {
    newMonth = true; // ������� ������ ���� ������ ������
    m_last_month_number = current_time; // ���������� ������� ����
   }
   
   if (newMonth && (m_last_month_number.hour < 18 && current_time.hour >= 18)) // ����� ����� ���������� � 18 �����
   { 
    newMonth = false; // ������� ������ ���� ������ ������
    m_last_month_number = current_time; // ���������� ������� ����
    //log_file.Write(LOG_DEBUG, StringFormat("%s �������� ��������� ������ ������ ����������� �������", MakeFunctionPrefix(__FUNCTION__)));
    return(true);
   }
  
   //--- ����� �� ����� ����� - ������ ����� �� �����
   return(false);
  }

//+------------------------------------------------------------------+
//| ������������� ���������� ��� �������� � ������� ���              |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::InitDayTrade()
{
 if (MonWenFriEighteen() > 0)
 {
  if (m_day_time.day_of_week == 1 || m_day_time.day_of_week == 3 || m_day_time.day_of_week == 5)
  {/*
   deltaFast = FAST_DELTA;
   currentLevelDay = FAST_DELTA / 5;
   slowVol = NormalizeDouble(VOLUME * FACTOR * deltaSlow, 2);
   fastVol = NormalizeDouble(slowVol * deltaFast * FACTOR, 2);
   FillArrayWithPrices(currentDaily, currentLevelDay);
   isDayInit = true;*/
  }
  
  if (m_day_time.day_of_week == 0 || m_day_time.day_of_week == 2 || m_day_time.day_of_week == 4 || m_day_time.day_of_week == 6)
  {
   FillArrayWithPrices(currentDaily, currentLevelDay);
  }
  
  log_file.Write(LOG_DEBUG, StringFormat("%s %s : %02d:%02d ; fast_vol= %f, slow_vol= %f, fastDelta= %d, slowDelta= %d"
                                        , MakeFunctionPrefix(__FUNCTION__)
                                        , DayOfWeekToString(m_day_time.day_of_week)
                                        , GetLastTime().hour
                                        , GetLastTime().min
                                        , fastVol
                                        , slowVol
                                        , deltaFast
                                        , deltaSlow));
 }
}

//+------------------------------------------------------------------+
//| ������������� ���������� ��� �������� � ������� ������           |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::InitMonthTrade()
{
 if(isNewMonth())
 {/*
  deltaSlow = SLOW_DELTA;
  currentLevelMonth = SLOW_DELTA / 5;
  slowVol = NormalizeDouble(VOLUME * deltaSlow * FACTOR, 2);
  FillArrayWithPrices(currentMonth, currentLevelMonth);
  isMonthInit = true;
  log_file.Write(LOG_DEBUG, StringFormat("%s %02d.%02d : %02d:%02d ; fast_vol= %f, slow_vol= %f, monthLvl=%d"
                                        , MakeFunctionPrefix(__FUNCTION__)
                                        , GetLastTime().mon
                                        , GetLastTime().day
                                        , GetLastTime().hour
                                        , GetLastTime().min
                                        , fastVol
                                        , slowVol
                                        , currentLevelMonth));*/
 }
}

//+------------------------------------------------------------------+
//| ���������� ������� ��������� ��� �� ������� ����                 |
//| INPUT:  dstArray - ������ ��� �������� ���                       |
//|         srcArray - ������ �� ���������� ������ � �������         |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::FillArrayWithPrices(double &dstArray[], int start)
{
 int i;
 int step;
 dstArray[start] = SymbolInfoDouble(m_symbol, SYMBOL_LAST);
 for (i = start - 1; i >= 0 ; --i)
 {
  //dstArray[i] = dstArray[i + 1] - srcArray[i + 1]*Point();
 }
 
 for (i = start + 1; i < 21; ++i)
 {
  //dstArray[i] = dstArray[i - 1] + srcArray[i - 1]*Point();
 }
 /*
 PrintFormat("%s DayLevel = %d, MonthLevel = %d, CurrentPrice=%.06f", MakeFunctionPrefix(__FUNCTION__), currentLevelDay, currentLevelMonth, SymbolInfoDouble(m_symbol, SYMBOL_LAST));
 for (i = 0; i < 21; ++i)
 {
  PrintFormat("%s Price[%d]=%f", MakeFunctionPrefix(__FUNCTION__), i, dstArray[i]);
 }*/
}

//+------------------------------------------------------------------+
//| �������� �������� ������                                         |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CDynamo::RecountDelta()
{
 double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_LAST);
 if (currentLevelDay < 20)
  if (currentPrice > currentDaily[currentLevelDay + 1])
  {
   deltaFast = deltaFast + 5;
   currentLevelDay++;
  }
 if (currentLevelDay > 0)
  if (currentPrice < currentDaily[currentLevelDay - 1])
  {
   deltaFast = deltaFast - 5;
   currentLevelDay--;
  }
 if (currentLevelMonth < 20) 
  if (currentPrice > currentMonth[currentLevelMonth + 1])
  {
   deltaSlow = deltaSlow + 5;
   currentLevelMonth++;
  }
 if (currentLevelMonth > 0)
  if (currentPrice < currentMonth[currentLevelMonth - 1])
  {
   deltaSlow = deltaSlow - 5;
   currentLevelMonth--;
  }
  /*
  log_file.Write(LOG_DEBUG, StringFormat("%s fast_vol= %f, slow_vol= %f, fastDelta= %d, slowDelta= %d"
                                        , MakeFunctionPrefix(__FUNCTION__)
                                        , fastVol
                                        , slowVol
                                        , deltaFast
                                        , deltaSlow));*/
}

//+------------------------------------------------------------------+
//| �������� ������� ����� �� ��������� ����� ������                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
double CDynamo::RecountVolume()
{/*
 slowVol = NormalizeDouble(VOLUME * FACTOR * deltaSlow, 2);
 fastVol = NormalizeDouble(slowVol * deltaFast * FACTOR, 2);/*
 log_file.Write(LOG_DEBUG, StringFormat("%s fast_vol= %f, slow_vol= %f, slow-fast = %f"
                                       , MakeFunctionPrefix(__FUNCTION__)
                                       , fastVol
                                       , slowVol
                                       , slowVol - fastVol));*/
 return (slowVol - fastVol); 
}

//+------------------------------------------------------------------+
//| �������� ������� ����� �� ��������� ����� ������                 |
//| INPUT:  no.                                                      |
//| OUTPUT: no.
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CDynamo::CorrectOrder(double volume)
{
 if (volume == 0) return(false);
 
 MqlTradeRequest request = {0};
 MqlTradeResult result = {0};
 
 ENUM_ORDER_TYPE type;
 double price;
 
 if (volume > 0)
 {
  type = ORDER_TYPE_BUY;
  price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
 }
 else
 {
  type = ORDER_TYPE_SELL;
  price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
 }
 
 request.action = TRADE_ACTION_DEAL;
 request.symbol = m_symbol;
 request.volume = MathAbs(volume);
 request.price = price;
 request.sl = 0;
 request.tp = 0;
 request.deviation = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD); 
 request.type = type;
 request.type_filling = ORDER_FILLING_FOK;
 return (OrderSend(request, result));
}
