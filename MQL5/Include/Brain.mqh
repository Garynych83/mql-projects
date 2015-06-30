//+------------------------------------------------------------------+
//|                                                        Brain.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Constants.mqh>
#include <StringUtilities.mqh>               // ��������� ��������������
#include <CLog.mqh>                          // ��� ����
#include <Object.mqh>
#include <ContainerBuffers.mqh>       // ��������� ������� ��� �� ���� �� (No PBI) - ��� ������� � ��
#include <CompareDoubles.mqh>               // ��������� ������������ �����

class CBrain : public CObject
{
protected:
 //string          _symbol;
 //int             _magic;
 //int             _current_direction;
 
 
public:

virtual int  GetSignal()     { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 3;}
virtual int  GetMagic()      { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 3;}
virtual int  GetDirection()  { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 3;}
virtual void ResetDirection(){ PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return;}

virtual ENUM_TIMEFRAMES GetPeriod() { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 3;}

//---------------��� �������� ������� ��������---------------
//virtual int GetSL();

//virtual ENUM_TIMEFRAMES GetPeriod() {return _period;}
                    
};
