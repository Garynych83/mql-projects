//+------------------------------------------------------------------+
//|                                               �NineTeenLines.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <NineTeenLines/CDrawLevel.mqh>
#include <ExtrLine\CLevel.mqh>
// ����� ������ ����������� NineTeenLines
class CNineTeenLines
 {
  private:
   CDrawLevel *    _level;    // ����� �������
   ENUM_TIMEFRAMES _period;   // ������ ��������� �������
   string          _name;     // ��� �������
  public:
   // ��������� ������ ������ 
   void MoveExtrLines(const SLevel &te[]);
   void DeleteExtrLines();
   CNineTeenLines (ENUM_TIMEFRAMES period,const SLevel &te,color clr=clrRed,const long chart_ID=0,const int sub_window=0,const bool back=true);  // ����������� ������
  ~CNineTeenLines ();  // ���������� ������
 };  
 
 // ����������� ������� 
 
 // ���������� ������ 
 void CNineTeenLines::MoveExtrLines(const SLevel &te[])
  {
    _level.MoveLevel(_name+"one",te[0].extr.price);
    _level.ChangeLevel(_name+"one",te[0].channel);
    _level.MoveLevel(_name+"two",te[1].extr.price);
    _level.ChangeLevel(_name+"two",te[1].channel); 
    _level.MoveLevel(_name+"three",te[2].extr.price);
    _level.ChangeLevel(_name+"three",te[2].channel); 
    _level.MoveLevel(_name+"four",te[3].extr.price);
    _level.ChangeLevel(_name+"four",te[3].channel); 
  }
 // ������� ������ 
 void CNineTeenLines::DeleteExtrLines(void)
  {
   // �������� ����� �������� ���� �������
   _level.DeleteAll();
  }
 // ����������� ������
 CNineTeenLines::CNineTeenLines(ENUM_TIMEFRAMES period,const SLevel &te,color clr=clrRed,const long chart_ID=0,const int sub_window=0,const bool back=true)
  {
   _name = "extr_" + EnumToString(period) + "_"; 
   _period = period;
   // ������� ������� �������
   _level.CDrawLevel(chart_ID,sub_window,back);
   // ������� ������
   _level.SetLevel(_name+"one",te[0].extr.price,te[0].channel,clr);   // ������ �������
   _level.SetLevel(_name+"two",te[1].extr.price,te[1].channel,clr);   // ������ �������
   _level.SetLevel(_name+"three",te[2].extr.price,te[2].channel,clr); // ������ �������
   _level.SetLevel(_name+"four",te[3].extr.price,te[3].channel,clr);  // ������ �������            
  }
 
 // ���������� ������
 CNineTeenLines::~CNineTeenLines()
  {
   delete _level;
  }
 