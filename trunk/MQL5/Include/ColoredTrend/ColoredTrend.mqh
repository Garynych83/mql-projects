//+------------------------------------------------------------------+
//|                                                 ColoredTrend.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.01"
// ����������� ���������
#include <CLog.mqh>                             // ��� ������� ����
#include <CompareDoubles.mqh>                   // ��� ��������� �������������� �����
#include <DrawExtremums/CExtrContainer.mqh>     // ��������� �����������
#include <StringUtilities.mqh>                  // ��������� � ������������ 
#include "ColoredTrendUtilities.mqh"            // ��������� � ������������� ��� ������ CColoredTrend


//------------------------------------------------------------------+
// ����� ������������ �������� ���� �������� �� �����               |
//------------------------------------------------------------------+
class CColoredTrend
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  ENUM_MOVE_TYPE enumMoveType[];
  ENUM_MOVE_TYPE previous_move_type;
  int      _digits;                        // ���������� ���� ����� ������� ��� ��������� ������������ �����
  int      _newTrend;                      // ���������� ��� �������� ������
  int      _depth;                         // ���������� ����� ��� ������� ����������
  double   _difToTrend;                    // �� ������� ��� ����� ��� ������ ��������� ���������� ���������, ��� �� ������� �����.   
  // ������ 
  double   buffer_ATR[];                   // ����� ATR
  MqlRates buffer_Rates[];                 // ����� ���������
  datetime time_buffer[];                  // ����� �������
  // ���������� ��� ����������� ��������
  
  CExtremum *_extr0, *_extr1,*_extr2;
  CExtremum *lastOnTrend;                  // ��������� ��������� �������� ������
  CExtremum *firstOnTrend;                 // ���� ������ ������ � ��� ����������� 
  // ������� �������
  CExtrContainer *_extrContainer;          // ��������� �����������
      
  int FillTimeSeries(ENUM_TF tfType, int count, datetime start_time, MqlRates &array[]);
  
  bool isCorrectionEnds  (double price, ENUM_MOVE_TYPE move_type, datetime start_time);
  bool isCorrectionWrong (int i);
  int  isLastBarHuge     (datetime start_time);
  int  isEndTrend();     
  

  
public:
  void CountTrend ();    // ����� �������� ������
  void CColoredTrend(string symbol, ENUM_TIMEFRAMES period,  int handle_atr, int depth,CExtrContainer *extrContainer);
  void ~CColoredTrend();
  bool FindExtremumInHistory(int depth);
  bool CountMoveType (int bar, datetime start_time, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);    // ����� ��������� ������� �������� �� �������  
  bool CountMoveTypeA(int bar, datetime start_time, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN);   // ����� ��������� ������� �������� � �������� �������
  ENUM_MOVE_TYPE GetMoveType(int i);
  void Zeros();
  int UpdateExtremums ();     // ����� ��������� �������� ��������� ���� ����������� (now = true - ��� ��������� �������, now = false - ��� �������� �� �������) 
  // ��������� ������
  CExtremum *GetExtr (int n);
  
  void ZeroTrend() { _newTrend = 0; };
  
  void PrintExtrInRealTime ();
  
};

//+-----------------------------------------+
//| �����������                             |
//+-----------------------------------------+
void CColoredTrend::CColoredTrend(string symbol, ENUM_TIMEFRAMES period, int handle_atr, int depth,CExtrContainer *extrContainer) : 
                   _symbol(symbol),
                   _period(period),
                   _depth(depth),
                   previous_move_type(MOVE_TYPE_UNKNOWN),
                   _extrContainer(extrContainer)
{
 _digits = (int)SymbolInfoInteger(_symbol, SYMBOL_DIGITS);
 firstOnTrend = new CExtremum(0,-1);
 lastOnTrend  = new CExtremum(0,-1);
 _difToTrend = SetDiffToTrend(period);
 _extr0 = new CExtremum(0,-1);
 _extr1 = new CExtremum(0,-1);
 _extr2 = new CExtremum(0,-1);
 ArrayResize(enumMoveType, depth);
 Zeros();  
 
}
void CColoredTrend::~CColoredTrend()
{
 delete _extr0;
 delete _extr1;
 delete _extr2;
 delete firstOnTrend;
 delete lastOnTrend;
}
//+-------------------------------------------------+
//| ������� ��������� ��� �������� ����� �� ������� |
//+-------------------------------------------------+
bool  CColoredTrend::CountMoveType(int bar, datetime start_time, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{ 
 int UpdateExtrCode;
 if(bar == 0) //�� "�������" ���� ������ ����������� �� ����� � ������ ������� ������� ��� �� ������ �������� � ����������
  {
   return (true); 
  }
 
 if(bar == ArraySize(enumMoveType))  // ���� ������ �������� �������� �������� ��� � ��� ����
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);
  
 if(FillTimeSeries(CURRENT_TF, AMOUNT_OF_PRICE, start_time, buffer_Rates) < 0) // ������� ������ ������������ �������
  { 
   return (false);
  } 
 CopyTime(_symbol, _period, start_time, 1, time_buffer);  
 enumMoveType[bar] = previous_move_type;             // ������� �������� ����� ����������� ��������
 
 _newTrend = 0;  // �������� �������� ������

 // �������� �������� ����������
 UpdateExtrCode = UpdateExtremums();
 
 // ���� �� ������� ���������� ����������
 if (UpdateExtrCode == 0)
  {
   //Print("�� ������� �������� ��������� 3 ����������");
   return (true);
  }
 // ���� ������� �������� ����������
 if (UpdateExtrCode == 1)
  {
   CountTrend();   // ���� ��������� ����� ����������, ��������� �� �������� �� ����� �����  
                                          
  }
 //��������� ����� �� ������������� ������ ���, ��� ��� �������� �� ������� ���������� �������� ��� �� � ������� ���� 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN   && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP; 
 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP   && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN; 
 
 // ���������� ������ ������ ������ ��� ��� ����� �� ������ �� ������ �� �������� �� ��������� ���� ��������
 if (_newTrend == -1 && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else if (_newTrend == 1 && enumMoveType[bar] != MOVE_TYPE_TREND_UP_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_UP)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else // ��������� ����� ���������� ������ � ������ ��� ����� (������ ������ ��� ��������� ��� ������ �� ������)
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   previous_move_type = enumMoveType[bar];
   return (true);
  }
 }
 //���� ���������� "���������" ����� �� ��� ������������ �� ����
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN || enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionWrong(bar))
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (1);
 }
 
 //������ ��������� ���� ���� � ����������� ���� ���� �������� ������ ���� �������� � ��� ���� ����� ������������ � ����������� ���� 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_UP || enumMoveType[bar-1] == MOVE_TYPE_TREND_UP_FORBIDEN) && // �������� �� ���������� ����
     (enumMoveType[bar]   == MOVE_TYPE_TREND_UP || enumMoveType[bar]   == MOVE_TYPE_TREND_UP_FORBIDEN) && // ������� ��������
     (previous_move_type  != MOVE_TYPE_FLAT)                                                              // ���������� �������� (����� ���� ���������� ��������� �������� ����)
      &&
     (LessDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))  // ���������� ��� ������ ������ ������
      &&
     ((buffer_Rates[0].high < buffer_Rates[1].high)))                                                     // ��������� high ������ ��������������
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;

  if (_extr0.direction > 0)  
  {
   lastOnTrend.price = _extr0.price;  
   lastOnTrend.direction = _extr0.direction; 
  } 
  else
  {
   lastOnTrend.price = _extr1.price;  
   lastOnTrend.direction = _extr1.direction; 
  } 
  
  previous_move_type = enumMoveType[bar];
  return (true);
 }
//������ ��������� ����� ���� � ����������� ���� ���� �������� ������ ���� �������� � ��� ���� ����� ������������ � ����������� ���� 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // �������� �� ���������� ����
     (enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN || enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // ������� ��������
     (previous_move_type != MOVE_TYPE_FLAT)                                                                   // ���������� �������� (����� ���� ���������� ��������� �������� ����)
      &&
     (GreatDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))     // ���������� ��� ������ ������ ������
      &&
     ((buffer_Rates[0].low > buffer_Rates[1].low)))                                                           // ��������� low ������ ��������������
 {
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;

  if (_extr0.direction < 0) 
  { 
   lastOnTrend.price = _extr0.price;  
   lastOnTrend.direction = _extr0.direction; 
  }  
  else 
  {
   lastOnTrend.price = _extr1.price;  
   lastOnTrend.direction = _extr1.direction; 
  }
   
  previous_move_type = enumMoveType[bar];
  return(true);
 }
 
 //��������� �������� �� ����� ���� ��� ����������� ������� isCorrectionEnds
 //���� ��������� ���� ������ ���������� ��������� ��� �� ������� �� "�������" ���
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))                       
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //��������� �������� �� ����� ����� ��� ����������� ������� isCorrectionEnds
 //���� ��������� ���� ������ ���������� ��������� ��� �� ������� �� "�������" ���
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }

 // ������� ����� ������ � ������ ����������� ������ ������� ����� ������ � �������*��������� ������
 if (((previous_move_type == MOVE_TYPE_TREND_DOWN || previous_move_type == MOVE_TYPE_TREND_DOWN_FORBIDEN || previous_move_type == MOVE_TYPE_CORRECTION_DOWN) && isEndTrend() ==  1) || 
     ((previous_move_type == MOVE_TYPE_TREND_UP   || previous_move_type == MOVE_TYPE_TREND_UP_FORBIDEN   || previous_move_type == MOVE_TYPE_CORRECTION_UP  ) && isEndTrend() == -1))   
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }

 return (true);
}

//+------------------------------------------------------+
//| �������, �������������� �������� � �������� �������  |
//+------------------------------------------------------+ 
bool CColoredTrend::CountMoveTypeA(int bar, datetime start_time, ENUM_MOVE_TYPE topTF_Movement = MOVE_TYPE_UNKNOWN)
{
 if (bar == 0)
  {
   return (true);
  }
 if(bar == ArraySize(enumMoveType))  // ���� ������ �������� �������� �������� ��� � ��� ����
  ArrayResize(enumMoveType, ArraySize(enumMoveType)*2, ArraySize(enumMoveType)*2);

 if(FillTimeSeries(CURRENT_TF, AMOUNT_OF_PRICE, start_time, buffer_Rates) < 0) // ������� ������ ������������ �������
  {
   log_file.Write(LOG_DEBUG,StringFormat("_count = %i �� �������� ������ ������������ �������",_count) ) ;  
   return (false);
  } 

 CopyTime(_symbol, _period, start_time, 1, time_buffer);  
 enumMoveType[bar] = previous_move_type;             // ������� �������� ����� ����������� ��������

 //��������� ����� �� ������������� ������ ���, ��� ��� �������� �� ������� ���������� �������� ��� �� � ������� ���� 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN_FORBIDEN && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP_FORBIDEN   && topTF_Movement != MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP; 
 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_DOWN && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_DOWN_FORBIDEN; 
 if (enumMoveType[bar] == MOVE_TYPE_TREND_UP   && topTF_Movement == MOVE_TYPE_FLAT) enumMoveType[bar] = MOVE_TYPE_TREND_UP_FORBIDEN; 
 
 // ���������� ������ ������ ������ ��� ��� ����� �� ������ �� ������ �� �������� �� ��������� ���� ��������
 if (_newTrend == -1 && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_DOWN)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else if (_newTrend == 1 && enumMoveType[bar] != MOVE_TYPE_TREND_UP_FORBIDEN && enumMoveType[bar] != MOVE_TYPE_TREND_UP)
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 else // ��������� ����� ���������� ������ � ������ ��� ����� (������ ������ ��� ��������� ��� ������ �� ������)
 {
  if(enumMoveType[bar] == MOVE_TYPE_UNKNOWN)
  {
   enumMoveType[bar] = MOVE_TYPE_FLAT;
   previous_move_type = enumMoveType[bar];
   return (true);
  }
 }
 
 //���� ���������� "���������" ����� �� ��� ������������ �� ����
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN || enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionWrong(bar))
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //������ ��������� ���� ���� � ����������� ���� ���� �������� ������ ���� �������� � ��� ���� ����� ������������ � ����������� ���� 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_UP || enumMoveType[bar-1] == MOVE_TYPE_TREND_UP_FORBIDEN) &&    // �������� �� ���������� ����
     (enumMoveType[bar]   == MOVE_TYPE_TREND_UP || enumMoveType[bar]   == MOVE_TYPE_TREND_UP_FORBIDEN) &&    // ������� ��������
     (previous_move_type  != MOVE_TYPE_FLAT)                                                                 // ���������� �������� (����� ���� ���������� ��������� �������� ����)
      &&
     (LessDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))     // ���������� ��� ������ ������ ������
      &&
     ( buffer_Rates[0].high < buffer_Rates[1].high ))                                                        // ��������� high ������ ��������������
 {
  /*
  Comment("������ � ���������� ��������� ����, ����� = ",TimeToString(TimeCurrent()),  
          "\n extr0 (",DoubleToString(_extr0.price),",",TimeToString(_extr0.time),",",_extr0.direction,")",
          "\n extr1 (",DoubleToString(_extr1.price),",",TimeToString(_extr1.time),",",_extr1.direction,")",          
          "\n extr2 (",DoubleToString(_extr2.price),",",TimeToString(_extr2.time),",",_extr2.direction,")"          
          );
  */
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_DOWN;

  if (_extr0.direction > 0)                  
  {
   lastOnTrend.price = _extr0.price;  
   lastOnTrend.direction = _extr0.direction; 
  }
  else
  { 
   lastOnTrend.price = _extr1.price;  
   lastOnTrend.direction = _extr1.direction;
  }
  
  previous_move_type = enumMoveType[bar];
  return (true);
 }
//������ ��������� ����� ���� � ����������� ���� ���� �������� ������ ���� �������� � ��� ���� ����� ������������ � ����������� ���� 
 if ((enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN || enumMoveType[bar-1] == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // �������� �� ���������� ����
     (enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN || enumMoveType[bar]   == MOVE_TYPE_TREND_DOWN_FORBIDEN) && // ������� ��������
     (previous_move_type != MOVE_TYPE_FLAT)                                                                   // ���������� �������� (����� ���� ���������� ��������� �������� ����)
      &&
     (GreatDoubles(buffer_Rates[AMOUNT_OF_PRICE-1].close, buffer_Rates[AMOUNT_OF_PRICE-1].open, _digits))     // ���������� ��� ������ ������ ������
      &&
     (buffer_Rates[0].low > buffer_Rates[1].low ))                                                            // ��������� low ������ ��������������
 {
  /*
  Comment("������ � ���������� ��������� �����, ����� = ",TimeToString(TimeCurrent()),  
          "\n extr0 (",DoubleToString(_extr0.price),",",TimeToString(_extr0.time),",",_extr0.direction,")",
          "\n extr1 (",DoubleToString(_extr1.price),",",TimeToString(_extr1.time),",",_extr1.direction,")",          
          "\n extr2 (",DoubleToString(_extr2.price),",",TimeToString(_extr2.time),",",_extr2.direction,")"          
          );
  */ 
  enumMoveType[bar] = MOVE_TYPE_CORRECTION_UP;
  
  if (_extr0.direction < 0)    
  {
   lastOnTrend.price = _extr0.price;  
   lastOnTrend.direction = _extr0.direction; 
  }
  else 
  {
   lastOnTrend.price = _extr1.price;  
   lastOnTrend.direction = _extr1.direction;
  }
   
  previous_move_type = enumMoveType[bar];
  return(true);
 }
 
 //��������� �������� �� ����� ���� ��� ����������� ������� isCorrectionEnds
 //���� ��������� ���� ������ ���������� ��������� ��� �� ������� �� "�������" ���
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_UP) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))                       
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_DOWN_FORBIDEN : MOVE_TYPE_TREND_DOWN;
  firstOnTrend.direction = -1;
  firstOnTrend.price = buffer_Rates[0].high;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 //��������� �������� �� ����� ����� ��� ����������� ������� isCorrectionEnds
 //���� ��������� ���� ������ ���������� ��������� ��� �� ������� �� "�������" ���
 if ((enumMoveType[bar] == MOVE_TYPE_CORRECTION_DOWN) && 
      isCorrectionEnds(buffer_Rates[0].close, enumMoveType[bar], start_time))
 {
  enumMoveType[bar] = (topTF_Movement == MOVE_TYPE_FLAT) ? MOVE_TYPE_TREND_UP_FORBIDEN : MOVE_TYPE_TREND_UP;
  firstOnTrend.direction = 1;
  firstOnTrend.price = buffer_Rates[0].low;
  firstOnTrend.time  = TimeCurrent();
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 
 // ������� ����� ������ � ������ ����������� ������ ������� ����� ������ � �������*��������� ������
 if (((previous_move_type == MOVE_TYPE_TREND_DOWN || previous_move_type == MOVE_TYPE_TREND_DOWN_FORBIDEN || previous_move_type == MOVE_TYPE_CORRECTION_DOWN) && isEndTrend() ==  1) || 
     ((previous_move_type == MOVE_TYPE_TREND_UP   || previous_move_type == MOVE_TYPE_TREND_UP_FORBIDEN   || previous_move_type == MOVE_TYPE_CORRECTION_UP  ) && isEndTrend() == -1))   
 {
  enumMoveType[bar] = MOVE_TYPE_FLAT;
  firstOnTrend.direction = 0;
  firstOnTrend.price = -1;
  firstOnTrend.time  = 0;
  previous_move_type = enumMoveType[bar];
  return (true);
 }
 return (true);
} 
 
//+----------------------------------------------------+
//| ������� �������� ������� �� ������� ����� �������� |
//+----------------------------------------------------+
ENUM_MOVE_TYPE CColoredTrend::GetMoveType(int i)
{
 if(i < 0 || i >= ArraySize(enumMoveType))
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s ������������� ������ ��� ������ ������� i = %d; period = %s; ArraySize = %d", MakeFunctionPrefix(__FUNCTION__), i, EnumToString((ENUM_TIMEFRAMES)_period), ArraySize(enumMoveType)));
  Print(StringFormat("%s ������������� ������ ��� ������ ������� i = %d; period = %s; ArraySize = %d", MakeFunctionPrefix(__FUNCTION__), i, EnumToString((ENUM_TIMEFRAMES)_period), ArraySize(enumMoveType)));
 }
 return(enumMoveType[i]);
}

//+-------------------------------------------------+
//| ������� ��������� ������ ��� �� �������         |
//+-------------------------------------------------+
int CColoredTrend::FillTimeSeries(ENUM_TF tfType, int count, datetime start_time, MqlRates &array[])
{
 if(count > _depth) count = _depth;
//--- ������� �����������
 int copied = 0;
 ENUM_TIMEFRAMES period;
 switch (tfType)
 {
  case BOTTOM_TF: 
   period = GetBottomTimeframe(_period);
   break;
  case CURRENT_TF:
   period = _period;
   break;
  case TOP_TF:
   period = GetTopTimeframe(_period);
   break;
 }
 
 copied = CopyRates(_symbol, period, start_time, count, array); // ������ ������ �� 0 �� count-1, ����� count ���������
//--- ���� �� ������� ����������� ����������� ���������� �����
 if(copied < count)
 {
  //--- ������� ���-�� ������������ �������� ����������
  //--- ������� ������ ���� ������ �������� ������� � ���������
  datetime firstdate_terminal=(datetime)SeriesInfoInteger(_symbol ,Period(), SERIES_TERMINAL_FIRSTDATE);
  //--- ������� ���������� ��������� ����� �� ��������� ����
  int available_bars=Bars(_symbol,Period(),firstdate_terminal,TimeCurrent());
  string comm = StringFormat("%s ��� ������� %s �������� %d ����� �� %d ������������� Rates. Period = %s. Error = %d | first date = %s, available = %d, start = %s, count = %d",
                             MakeFunctionPrefix(__FUNCTION__),
                             _symbol,
                             copied,
                             count,
                             EnumToString((ENUM_TIMEFRAMES)period),
                             GetLastError(),
                             TimeToString(firstdate_terminal, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                             available_bars,
                             TimeToString(start_time, TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                             count
                            );
  //--- ������� ��������� � ����������� �� ������� ���� �������
  log_file.Write(LOG_DEBUG, comm);
 }
 ArraySetAsSeries(array, true);
 return(copied);
}

//+------------------------------------------------------------------------+
//| ������� ��������� ������� ������ �� ��������� � ����������� ������     |
//+------------------------------------------------------------------------+
bool CColoredTrend::isCorrectionEnds(double price, ENUM_MOVE_TYPE move_type, datetime start_time)
{
 if (move_type == MOVE_TYPE_CORRECTION_UP)
 {
  if(LessDoubles(price, lastOnTrend.price, _digits))  // ���� ���� ���� ���������� ���������� �� ������
  {
   //Comment("���� ���� ���� ���������� ���������� �� ������");
   return(true);
  }
  if(isLastBarHuge(start_time) > 0)                    // ��������� �������� ���� �� ������� ��. ������� ��� - ����� ��� �� ��������� ������ �������� ���� �� ��������� ���������� �������
  {
   //Comment("��������� �������� ���� �� ������� ��. ������� ���");
   return(true);
  }
 }
 else if (move_type == MOVE_TYPE_CORRECTION_DOWN)
 {
  if(GreatDoubles(price, lastOnTrend.price, _digits)) // ���� ���� ���� ���������� ���������� �� �����
  {
   //Comment("���� ���� ���� ���������� ���������� �� ������");
   return(true);
  }
  if(isLastBarHuge(start_time) < 0)                   // ��������� �������� ���� �� ������� ��. ������� ��� - ����� ��� �� ��������� ������ �������� ���� �� ��������� ���������� �������
  {
   //Comment("��������� �������� ���� �� ������� ��. ������� ���");  
   return(true);
  }
 }
 else
  PrintFormat("%s %s �������� ��� ��������!", __FUNCTION__, EnumToString((ENUM_TIMEFRAMES)_period));
 
 return (false);
}

//+----------------------------------------------------------+
//| ������� ��������� ������� ������ �� ��������� �� ����.   |
//+----------------------------------------------------------+
bool CColoredTrend::isCorrectionWrong(int i)
{
 if (enumMoveType[i] == MOVE_TYPE_CORRECTION_UP)
 {
  if(buffer_Rates[0].close > firstOnTrend.price && firstOnTrend.direction == -1) 
  {
   return(true);
  }
 }
 if (enumMoveType[i] == MOVE_TYPE_CORRECTION_DOWN)
 {
  if(buffer_Rates[0].close < firstOnTrend.price && firstOnTrend.direction == 1) 
  {
   return(true);
  }
 }
 
 return(false);
}

//+----------------------------------------------------------------+
//| ������� ���������� �������� �� ��� "�������" � ��� ����������� |
//+----------------------------------------------------------------+
int CColoredTrend::isLastBarHuge(datetime start_time)
{
 double sum = 0;
 MqlRates rates[];
 datetime buffer_date[];
 CopyTime(_symbol, GetBottomTimeframe(_period),  start_time-PeriodSeconds(GetBottomTimeframe(_period)), AMOUNT_BARS_FOR_HUGE, buffer_date);
 if(FillTimeSeries(BOTTOM_TF, AMOUNT_BARS_FOR_HUGE, start_time-PeriodSeconds(GetBottomTimeframe(_period)), rates) < AMOUNT_BARS_FOR_HUGE) return(0);

 for(int i = 0; i < AMOUNT_BARS_FOR_HUGE - 1; i++)
 {
  sum = sum + rates[i].high - rates[i].low;  
 }
 double avgBar = sum / AMOUNT_BARS_FOR_HUGE;
 double lastBar = MathAbs(rates[0].open - rates[0].close);
    
 if(GreatDoubles(lastBar, avgBar*FACTOR_OF_SUPERIORITY))
 {
  if(GreatDoubles(rates[0].open, rates[0].close, _digits))
   return(1);
  if(LessDoubles(rates[0].open, rates[0].close, _digits))
   return(-1);
 }
 return(0);
}

//+----------------------------------------------------+
//| ������� ���������� ������ ������                   |
//+----------------------------------------------------+
void CColoredTrend::CountTrend()
{
 //Comment("_extr0 ",_extr0.price," ",TimeToString(_extr0.time)," ",_extr0.direction );
 
 if (_extr1.direction < 0 && 
     LessDoubles((_extr2.price - _extr1.price)*_difToTrend,
                 (_extr0.price - _extr1.price), 
                 _digits))
 {
  _newTrend = 1;
  return;
 }
 
 if (_extr1.direction > 0 && 
     LessDoubles((_extr1.price - _extr2.price)*_difToTrend, 
                 (_extr1.price - _extr0.price), 
                 _digits))
 {
  _newTrend = -1;
  return;
 }
 
 _newTrend = 0;
}
//+----------------------------------------------------------+
//| ������� ���������� ����� ������/��������� (������ �����) |
//+----------------------------------------------------------+
int CColoredTrend::isEndTrend()
{
 if (_extr1.direction < 0 && 
     GreatDoubles((_extr2.price - _extr1.price)*_difToTrend ,(_extr0.price - _extr1.price), _digits))
 {
  return(1);
 }
 if (_extr1.direction > 0 && GreatDoubles((_extr1.price - _extr2.price)*_difToTrend ,(_extr1.price - _extr0.price), _digits))
 {
  return(-1);
 }
 return(0);
}
//+-------------------------------------------------------------+
//| ������� ��������� ������ ����� �������� ��������� ��������� |
//+-------------------------------------------------------------+
void CColoredTrend::Zeros()
{
  for(int i = 0; i < ArraySize(enumMoveType); i++)
  {
   enumMoveType[i] = MOVE_TYPE_UNKNOWN;
  }
}

//+-------------------------------------------------------------+
//| ������� ��������� �������� ��������� ���� �����������       |
//+-------------------------------------------------------------+
int CColoredTrend::UpdateExtremums()
{
 CExtremum *extr0Temp,*extr1Temp,*extr2Temp;

 // �������� ��������� 3 ����������
 extr0Temp = _extrContainer.GetExtrByIndex(0,EXTR_BOTH);
 extr1Temp = _extrContainer.GetExtrByIndex(1,EXTR_BOTH);
 extr2Temp = _extrContainer.GetExtrByIndex(2,EXTR_BOTH);
  

 if (extr0Temp.direction == 0 || extr1Temp.direction == 0 || extr2Temp.direction == 0)
  return (0);
  
 /*Print("extr0Temp = ",DoubleToString(extr0Temp.price),
       "\nextr1 = ",DoubleToString(extr1Temp.price),
       "\nextr2 = ",DoubleToString(extr2Temp.price)
      );
 */
 // ���� ��������� ��������� 
 if (extr0Temp.price != _extr0.price)
  {
   _extr0.price = extr0Temp.price;
   _extr0.time  = extr0Temp.time;
   _extr0.direction = extr0Temp.direction;
   
   _extr1.price = extr1Temp.price;
   _extr1.time  = extr1Temp.time;
   _extr1.direction = extr1Temp.direction;
   
   _extr2.price = extr2Temp.price;
   _extr2.time  = extr2Temp.time;
   _extr2.direction = extr2Temp.direction;   
   return (1);
  }
 return (-1);
}

CExtremum *CColoredTrend::GetExtr(int n)
 {
  if (n == 0)
   return (_extr0);
  if (n == 1)
   return (_extr1);
  if (n == 2)
   return (_extr2);
  return (_extr0);
 }
 
void CColoredTrend::PrintExtrInRealTime(void)
 {
  Comment("������ � ���������� ��������� �����, ����� = ",TimeToString(TimeCurrent()),  
          "\n extr0 (",DoubleToString(_extr0.price),",",TimeToString(_extr0.time),",",_extr0.direction,")",
          "\n extr1 (",DoubleToString(_extr1.price),",",TimeToString(_extr1.time),",",_extr1.direction,")",          
          "\n extr2 (",DoubleToString(_extr2.price),",",TimeToString(_extr2.time),",",_extr2.direction,")"          
          );  
 }