//+------------------------------------------------------------------+
//|                                                CExtremum.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      ""
#property version   "1.01"

#include <CompareDoubles.mqh>  
#include <Lib CisNewBarDD.mqh>
#include <CEventBase.mqh>  // ��� ��������� �������     

#define ARRAY_SIZE 4                 // ���������� �������� �����������
#define DEFAULT_PERCENTAGE_ATR 1.0   // �� ��������� ����� ��������� ���������� ����� ������� ������ �������� ����

struct SExtremum 
{
 int direction;                      // ����������� ����������: 1 - max; -1 -min; 0 - null
 double price;                       // ���� ����������: ��� max - high; ��� min - low
 datetime time;                      // ����� ���� �� ������� ��������� ���������
};

// ����� ������� ������ � ��������� ��������� ARRAY_SIZE ����������� (����������� �� CEventBase)
class CExtremum : public CEventBase
{
 protected:
 string _symbol;
 int _digits;
 ENUM_TIMEFRAMES _tf_period;
 //--��������� ATR ��� difToNewExtremum-----
 int _handle_ATR;
 double _percentage_ATR;   // ���������� ���������� �� �� �� ������� ��� �������� ���� ������ ��������� ������� ��� ��� �� �������� ����� ���������
 double _averageATR;       // ������ ������� �������� ���
 MqlRates bufferRates[1];  // ����� ���������
 //-----------------------------------------
 SExtremum extremums[ARRAY_SIZE];
 
 public:
 CExtremum();
 CExtremum(string symbol, ENUM_TIMEFRAMES period, int handle_atr);
~CExtremum();

 int isExtremum(SExtremum& extr_array[], datetime start_pos_time = __DATETIME__,  bool now = true);  // ���� �� ��������� �� ������ ����
 int RecountExtremum(datetime start_pos_time = __DATETIME__, bool now = true);                       // �������� ������ �����������
 void RecountUpdated(datetime start_pos, bool now);  // ��������� �������� �����������, ��������� ��  � ������ ret_extremums
 double AverageBar (datetime start_pos);
 SExtremum getExtr(int i);
 void PrintExtremums();
 int  ExtrCount();
 double getPercentageATR() { return(_percentage_ATR); }
 void SetSymbol(string symb) { _symbol = symb; }
 void SetPeriod(ENUM_TIMEFRAMES tf) { _tf_period = tf; }
 void SetDigits(int digits) { _digits = digits; }
 void SetPercentageATR();
};

CExtremum::CExtremum(void)
           { // ��� ��� _handle_ATR �� ��������� �� ���������� ����� �� ������ ����
             // ������������� ������������ ����������� � �����������!
            _symbol = Symbol();
            _tf_period = Period();
            SetPercentageATR();
            _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
           }

CExtremum::CExtremum(string symbol, ENUM_TIMEFRAMES period, int handle_atr):
            _symbol (symbol),
            _tf_period (period),
            _handle_ATR(handle_atr)
            {
             SetPercentageATR();
             _averageATR = AverageBar(TimeCurrent());
             _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
            }
CExtremum::~CExtremum()
           {
           }             

//-----------------------------------------------------------------
// ������� ���������� ���������� ����� ����������� �� ������ ����
// ���������
// SExtremum& extr_array [] - ������ � ������� ������������ ����� ���������� � ������� �� ���������
// datetime start_pos_time  - ����� �� ������� ���� ����������
// bool now - ���� ��� ���� ��� �� �������� �������� �� �� ������� ��� � �������� �������(�� ������� �� ���� ��� ������� ������ ���� ���)
//-----------------------------------------------------------------
int CExtremum::isExtremum(SExtremum& extr_array [], datetime start_pos_time = __DATETIME__, bool now = true)
{
 SExtremum result1 = {0, -1}; // ��������� ���������� ��� ������ max ���� �� ����
 SExtremum result2 = {0, -1}; // ��������� ���������� ��� ������ min ���� �� ����
 int count = 0;               // ������� ������� ��������� �����������
 double high = 0, low = 0;    // ��������� ���������� � ������� ����� �������� ���� ��� ������� max � min ��������������
 

 if(CopyRates(_symbol, _tf_period, start_pos_time, 1, bufferRates) < 1)
 {
 // PrintFormat("%s %s Rates buffer: error = %d, calculated = %d, start_index = %s", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_tf_period), GetLastError(), Bars(_symbol, _tf_period), TimeToString(start_pos_time));
  return(-1); 
 }
 //CopyRates(_symbol, _tf_period, start_pos_time, 1, bufferRates);
 
 double aveBar = AverageBar(start_pos_time);
 if (aveBar > 0) _averageATR = aveBar; 
 double difToNewExtremum = _averageATR * _percentage_ATR;  // ������ ������������ ���������� ����� ������������
 
 if(extremums[0].time == bufferRates[0].time && !now) return(0); // �� ������� ���������� ����� ���������� ���������� � ����� �������� ����, �������� ��� ����� ��������� ����������� �����������
 
 if (now) // �� ����� ����� ���� ���� close �������� ��� ��� �������� �� low �� high
 {        // ������������ ���� �� ������ ���� ���� ������� ��������� �� �� ����� ��������� ����� close ����� max  � �������� � low
  high = bufferRates[0].close;
  low = bufferRates[0].close;
 }
 else    // �� ����� ������ �� ������� �� ������� �� ��� ���� ��� ������������� ��� ����� ����� ������ ��� �������� � �������
 {
  high = bufferRates[0].high;
  low = bufferRates[0].low;
 }
 
 if ((extremums[0].direction == 0 ) // ���� ����������� ��� ��� �� ������� ��� ������ ���������
   ||(extremums[0].direction >  0 && (GreatDoubles(high, extremums[0].price, _digits))) // ���� ���� ������� ��������� � �� �� �������
   ||(extremums[0].direction <  0 && (GreatDoubles(high, extremums[0].price + difToNewExtremum, _digits)))) // ���� ���� ������ �� ���������� �� ����������� ���������� � �������� �������
 { 
  result1.direction = 1;       // ���������� �����������, ���� � ����� ��������� ����������
  result1.price = high;
  result1.time = bufferRates[0].time;
  count++;
  //PrintFormat("%s %s start_pos_time = %s; max %0.5f", __FUNCTION__,  EnumToString((ENUM_TIMEFRAMES)_tf_period), TimeToString(start_pos_time), high);
 }
 
 if ((extremums[0].direction == 0 ) // ���� ����������� ��� ��� �� ������� ��� ������ ���������
   ||(extremums[0].direction <  0 && (LessDoubles(low, extremums[0].price, _digits))) //���� ���� ������� ���������� � �� �� �������                    
   ||(extremums[0].direction >  0 && (LessDoubles(low, extremums[0].price - difToNewExtremum, _digits)))) // ���� ���� ������ �� ���������� �� ����������� ���������� � �������� �������
 {
  result2.direction = -1;     // ���������� �����������, ���� � ����� ��������� ����������
  result2.price = low;
  result2.time = bufferRates[0].time;
  count++;
  //PrintFormat("%s %s start_pos_time = %s; min  %0.5f", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_tf_period), TimeToString(start_pos_time), low);
 }
 
 // �� ������� ����� ���������� �������� ����� ������������ �� ����� ���� ���������� ��� ����������
 // ��� ��� ��� ����� ������� �� ���������, �� ���� ����� ��������� ������� ��� ����������� ��� ������ ��������, � ��� ������
 if(bufferRates[0].close <= bufferRates[0].open && !now) //���� close ���� open �� ������� ����� max ����� min
 {
  extr_array[0] = result1;
  extr_array[1] = result2;
 }
 else                                                    //���� close ���� open �� ������� ����� min ����� max
 {
  extr_array[0] = result2;
  extr_array[1] = result1;
 }  
 
 return(count);
}


double cn = 1;

//-------------------------------------------------------------------------------------
// ������� ��������� ���� �� ������ ���� ���������� � ���� ���� ��������� � ������ �����������
// �� �������� ����� 
//-------------------------------------------------------------------------------------
int CExtremum::RecountExtremum(datetime start_pos_time = __DATETIME__, bool now = true)
{
 SExtremum new_extr[2] = {{0, -1}, {0, -1}}; //��������� ���������� � ������� isExtremum ������� �� ���������� ��� � ���� ���������
 int count_new_extrs = isExtremum(new_extr, start_pos_time, now);
 
 if(count_new_extrs > 0)   // ���� ��������� ����� ����������
 {
  for(int i = 0; i < 2; i++) // ���� �� ������� �����������
  {
   if (new_extr[i].direction != 0)
   {
    if (new_extr[i].direction == extremums[0].direction) // ���� ����� ��������� � ��� �� ����������, ��� � ���������, �� ���������
    {
     extremums[0] = new_extr[i];
    }
    else                                                 // ���� ����� ��������� � ��������������� ����������, �� ����������, �������� ��� � ��������� �����
    {
     for(int j = ARRAY_SIZE-1; j >= 1; j--)
     {
      extremums[j] = extremums[j-1];     
     }
     extremums[0] = new_extr[i];
    }       
   }
  }
 
 }
 
 return(count_new_extrs);
}

//-------------------------------------------------------------------------------------
// ���������� �������� �������� ���� ��� ������� ����
//-------------------------------------------------------------------------------------
double CExtremum::AverageBar (datetime start_pos)  // ���������� �������� � ����������
{
 int copied = 0;
 double buffer_average_atr[1];
 if (_handle_ATR == INVALID_HANDLE)
 {
  PrintFormat("%s ERROR. I have INVALID HANDLE = %d, %s", __FUNCTION__, GetLastError(), EnumToString((ENUM_TIMEFRAMES)_tf_period));
 }
 
 copied = CopyBuffer(_handle_ATR, 0, start_pos, 1, buffer_average_atr);
 if (copied == 1) 
  return(buffer_average_atr[0]);
 else
 {
  PrintFormat("%s ERROR. I have this error = %d, %s. copied = %d, calculated = %d, buf_num = %d start_pos = %s", __FUNCTION__, GetLastError(), EnumToString((ENUM_TIMEFRAMES)_tf_period), copied, BarsCalculated(_handle_ATR), _handle_ATR,TimeToString(start_pos));
  return(0);
 }
}

//-------------------------------------------------------------------------------------
// ���������� ���������� ����������� �����������
//-------------------------------------------------------------------------------------
int CExtremum::ExtrCount()      
{
 int count = 0;
 for(int i = 0; i < ARRAY_SIZE; i++)
 {
  if(extremums[i].direction != 0) 
    count++;      // ���� � �������� ������� ����������� ��������� ����������� ������ ��� ����������� ���������
 }
 return(count);
}

//-------------------------------------------------------------------------------------
// ���������� ��������� �� ��� ����������� ������
//-------------------------------------------------------------------------------------
SExtremum CExtremum::getExtr(int i)
{
 SExtremum zero = {0, 0};
 if(i < 0 || i >= ARRAY_SIZE)
  return zero;     // � ������ ��������� ������� ����������� ��������� �������
 return(extremums[i]);
}

//-------------------------------------------------------------------------------------
// �������� ���������� �� ���� �������� �����������
//-------------------------------------------------------------------------------------
void CExtremum::PrintExtremums()
{
 string result = "";
 for(int i = 0; i < ARRAY_SIZE; i++)
 {
  StringConcatenate(result, result, StringFormat("num%d = {%d %.05f %s ,(%.05f)}; ", i, extremums[i].direction, extremums[i].price, TimeToString(extremums[i].time), AverageBar(extremums[i].time)*_percentage_ATR));
 }
 PrintFormat("%s %s %s %s", __FUNCTION__, TimeToString(TimeCurrent()),EnumToString((ENUM_TIMEFRAMES)_tf_period), result);
}

//-------------------------------------------------------------------------------------+
// ������������� ������ �������� ���������� � ����������� �� ���������� ����������     |
//-------------------------------------------------------------------------------------+
void CExtremum::SetPercentageATR()
{
 switch(_tf_period)
 {
   case(PERIOD_M1):
      _percentage_ATR = 3.0;
      break;
   case(PERIOD_M5):
      _percentage_ATR = 3.0;
      break;
   case(PERIOD_M15):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_H1):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_H4):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_D1):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_W1):
      _percentage_ATR = 2.2;
      break;
   case(PERIOD_MN1):
      _percentage_ATR = 2.2;
      break;
   default:
      _percentage_ATR = DEFAULT_PERCENTAGE_ATR;
      break;
 }
}

// ��������� �������� �����������, �������� �� � ������ ret_extremums
void CExtremum::RecountUpdated(datetime start_pos,bool now)
 {
  int count_new_extrs = RecountExtremum(start_pos, now);
  if (count_new_extrs > 0)
   { //� ������� ������������ ����������� �� 0 ����� ����� max, �� ����� 1 ����� min
     // ���������� ������� ���������� ����������� ��� ���� �������� 
     SEventData data;
     // �������� �� ���� �������� �������� � ������� �������� � �� � ���������� ��� ��� �������
     long z = ChartFirst();
     // ��������� ����� ����������
     data.lparam = long(start_pos); 
     while (z>=0)
      {
       if (ChartSymbol(z) == _symbol && ChartPeriod(z) == _tf_period)  // ���� ������ ������ � ������� �������� � �������� 
         {
          // ���� ������ 1 ��������� � �� �������
          if (count_new_extrs == 1 && getExtr(0).direction == 1)
            {
             // �� ��������� ���� ����������
             data.dparam = getExtr(0).price;
             // � ������� ������� ��� �������� ������� ��� �������� ����������
             Generate(z,1,data);  
            }
          // ���� ������ 1 ��������� � �� ������
          if (count_new_extrs == 1 && getExtr(0).direction == -1)
            {
             // �� ��������� ���� ����������
             data.dparam = getExtr(1).price;
             // � ������� ������� ��� �������� ������� ��� ������� ����������
             Generate(z,2,data);  
            }
          // ���� ������ 2 ���������� � �� 0-�� ������� - �������
          if (count_new_extrs == 2 && getExtr(0).direction == 1)
            {
             // �� ��������� ���� ����������
             data.dparam = getExtr(0).price;
             // � ������� ������� ��� �������� ������� ��� �������� ����������
             Generate(z,1,data);  
             // �� ��������� ���� ����������
             data.dparam = getExtr(1).price;
             // � ������� ������� ��� �������� ������� ��� ������� ����������
             Generate(z,2,data);          
            }                
         // ���� ������ 2 ���������� � �� 0-�� ������� - �������
         if (count_new_extrs == 2 && getExtr(0).direction == -1)
            {
             // �� ��������� ���� ����������
             data.dparam = getExtr(1).price;
             // � ������� ������� ��� �������� ������� ��� �������� ����������
             Generate(z,1,data);  
             // �� ��������� ���� ����������
             data.dparam = getExtr(0).price;
             // � ������� ������� ��� �������� ������� ��� ������� ����������
             Generate(z,2,data);          
            }            
       //Print("HIGH = ",DoubleToString(bufferRates[0].high)," LOW = ",DoubleToString(bufferRates[0].low) );   
      }
   z = ChartNext(z);      
  }          
  }
 }