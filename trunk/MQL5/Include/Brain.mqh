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
#include <ContainerBuffers.mqh>              // ��������� ������� ��� �� ���� �� (No PBI) - ��� ������� � ��
#include <CompareDoubles.mqh>                // ��������� ������������ �����
#include <TradeManager/TradeManager.mqh>     // �������� ����������
class CBrain : public CObject
{
protected:
 //string          _symbol;
 //int             _magic;
 //int             _current_direction;
 
 
public:

virtual ENUM_TM_POSITION_TYPE  GetSignal()     { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 2;}
virtual long  GetMagic()                       { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 2;}
virtual ENUM_SIGNAL_FOR_TRADE    GetDirection(){ PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 2;}
virtual int  CountTakeProfit()        { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 0;}
virtual int  CountStopLoss()          { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 0;}
virtual int  GetPriceDifference()   { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 0;}
virtual int  GetExpiration()        { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 0;}
virtual ENUM_TIMEFRAMES GetPeriod() { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return 2;}
virtual string GetName()            { PrintFormat("%s ����� �� CBrain, � �� ������ ���", MakeFunctionPrefix(__FUNCTION__));return "Brain";}
//---------------��� �������� ������� ��������---------------
//virtual int GetSL();

//virtual ENUM_TIMEFRAMES GetPeriod() {return _period;}
                    
};
