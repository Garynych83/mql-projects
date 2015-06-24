//+------------------------------------------------------------------+
//|                                                CTrendChannel.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ����� ��������� ����� � �������                                  |
//+------------------------------------------------------------------+
// ����������� ����������� ���������
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������
#include <DrawExtremums/CExtremum.mqh> // ����� �����������
#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <CompareDoubles.mqh> // ��� ��������� ������������ �����
#include <Arrays\ArrayObj.mqh> // ����� ������������ ��������
#include <StringUtilities.mqh> // ��������� �������
#include "CMove.mqh" // ����� ��������             

class CMoveContainer: public CObject
 {
  private:
   int    _handleDE; // ����� ���������� DrawExtremums
   int    _chartID;  // ID �������
   int    _countMoves; // ������� ��������
   string _symbol;   // ������
   string _eventExtrUp;   // ��� ������� ������� �������� ����������
   string _eventExtrDown; // ��� ������� ������� ������� ����������
   string _trend_up_name; // ��� ������� ����� �������� ������
   string _trend_down_name; // ��� ������ ����� �������� ������
   double _percent; // ������� �������� ������
   ENUM_TIMEFRAMES _period; // ������
   int    _trendNow; // ���� ����, ��� � ������ ������ ���� ��� ��� ������
   bool   _isHistoryUploaded; // ���� ����, ��� ������� ���� ���������� �������
   CExtrContainer *_container; // ��������� �����������
   CArrayObj _bufferMove;// ����� ��� �������� ��������
   CMove *_prevTrend; // ��������� �� ���������� �����
   CMove *_curTrend; // ������� �����
   CChartObjectTrend _currentTrendLine; // ������ ������ ����� �������� ������
   // ��������� ������ ������
   string GenEventName (string eventName) { return(eventName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
   string GenTrendLineName(string lineName) { return(lineName +"_"+ _symbol +"_"+ PeriodToString(_period) ); };
   void RemoveTrendLines (); // ������� � ������� ��������� ������
   void DrawCurrentTrendLines (); // ���������� ���� �������� ������
  public:
   // ��������� ������ ������
   CMoveContainer(int chartID,string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent); // ����������� ������
   ~CMoveContainer(); // ���������� ������
   // ������ ������
   CMove *GetMoveByIndex (int index); // ���������� ��������� �� �������� �� �������
   CMove *GetTrendByIndex (int index); // ���������� ����� �� �������
   CMove *GetLastTrend(void); // ���������� �������� ���������� ������
   double GetPriceLineUp(datetime time); // ���������� ���� �� ������� ����� �� �������
   double GetPriceLineDown(datetime time); // ���������� ���� �� ������ ����� �� �������     
   bool IsTrendNow () { return (_trendNow); }; // ���������� true, ���� � ������� ������ - �����, false - ���� � ������� ������ - ��� �����
   int  GetTotal () { return (_bufferMove.Total() ); }; // ���������� ���������� �������� �� ������� ������ � ������
   void RemoveAll (); // ������� ����� ��������
   void UploadOnEvent (string sparam,double dparam,long lparam); // ����� ��������� ���������� �� �������� 
   bool UploadOnHistory (); // ����� ��������� ������ � ����� �� ������� 
 };
 
// ����������� ��������� ������� ������
void CMoveContainer::RemoveTrendLines(void) // ����� �������� ����� ������
 {
  ObjectDelete(_chartID,_trend_up_name);
  ObjectDelete(_chartID,_trend_down_name);
 }

void CMoveContainer::DrawCurrentTrendLines(void) // ����� ���������� ����� �������� ������
 {
  CExtremum *high0,*high1; // ������� ���������� �������� ������
  CExtremum *low0,*low1; // ������ ���������� �������� ������
  CMove *lastMove;
  // �������� ��������� ��������
  lastMove = GetMoveByIndex(0);
  // ���� ������� �������� - �����
  if (lastMove.GetMoveType() == MOVE_TREND_UP || lastMove.GetMoveType() == MOVE_TREND_DOWN)
   {
    // �������� ��������� ���������� �� ���������� ��������
    high0 = lastMove.GetMoveExtremum(EXTR_HIGH_0);
    high1 = lastMove.GetMoveExtremum(EXTR_HIGH_1);
    low0  = lastMove.GetMoveExtremum(EXTR_LOW_0);
    low1  = lastMove.GetMoveExtremum(EXTR_LOW_1);            
    _currentTrendLine.Create(_chartID,_trend_up_name,0,high0.time,high0.price,high1.time,high1.price); // ������� �����
    ObjectSetInteger(_chartID,_trend_up_name,OBJPROP_COLOR,clrViolet);
    ObjectSetInteger(_chartID,_trend_up_name,OBJPROP_RAY_LEFT,1);
    _currentTrendLine.Create(_chartID,_trend_down_name,0,low0.time,low0.price,low1.time,low1.price); // ������� ����� 
    ObjectSetInteger(_chartID,_trend_down_name,OBJPROP_COLOR,clrViolet);  
    ObjectSetInteger(_chartID,_trend_down_name,OBJPROP_RAY_LEFT,1);    
   }
 }
 
// ����������� ������� ������ CTrendChannel
CMoveContainer::CMoveContainer(int chartID, string symbol,ENUM_TIMEFRAMES period,int handleDE,double percent)
 {
  _chartID = chartID;
  _handleDE = handleDE;
  _symbol = symbol;
  _period = period;
  _percent = percent;
  _countMoves = 0;
  _container = new CExtrContainer(handleDE,symbol,period);
  // ��������� ���������� ����� �������
  _eventExtrDown = GenEventName("EXTR_DOWN_FORMED");
  _eventExtrUp = GenEventName("EXTR_UP_FORMED");
  // ��������� ����� ��������� �����
  _trend_up_name = GenTrendLineName("CUR_TREND_UP");
  _trend_down_name = GenTrendLineName("CUR_TREND_DOWN");  
  _isHistoryUploaded = false;
 } 
  
// ���������� ������
CMoveContainer::~CMoveContainer()
 {
  _bufferMove.Clear();
  delete _container;
 }
 
// ���������� ��������� �� ����� �� �������
CMove * CMoveContainer::GetMoveByIndex(int index)
 {
  CMove *curTrend = _bufferMove.At(_bufferMove.Total()-1-index);
  if (curTrend == NULL)
   PrintFormat("%s �� ������� ������ i=%d, total=%d", MakeFunctionPrefix(__FUNCTION__), index, _bufferMove.Total());
  return (curTrend);
 }
 
// ���������� ����� �� �������
CMove * CMoveContainer::GetTrendByIndex(int index)
 {
  if (index == 0) // ���� ���� ������� ��������� �� ��������� �����
   {
    return (_curTrend);
   }
  if (index == 1) // ���� ���� ������� ��������� �� ���������� �����
   {
    return (_prevTrend); 
   }
  return NULL;
 }

// ���������� ��������� �� ��������� �����
CMove * CMoveContainer::GetLastTrend(void)
 {
  int total = _bufferMove.Total();
  CMove *tempMove;
  for (int i=0;i<total;i++)
   {
    tempMove = _bufferMove.At(i);
    if (tempMove.GetMoveType() == MOVE_TREND_DOWN || tempMove.GetMoveType() == MOVE_TREND_UP)
     {             
      return (tempMove); 
     }
   }
  return (NULL);
 } 
 
double CMoveContainer::GetPriceLineUp(datetime time) // ���������� ���� �� ������� ����� 
 {
  return (ObjectGetValueByTime(_chartID,_trend_up_name, time));
 } 
 
double CMoveContainer::GetPriceLineDown(datetime time) // ���������� ���� �� ������ �����
 {
  return (ObjectGetValueByTime(_chartID,_trend_down_name, time));
 } 
 
// ����� ������� ����� ��������
void CMoveContainer::RemoveAll(void)
 {
  int countTrend=0; // ���������� ��������� �������  
  int last_index; // ������ ������� ������
  CMove *move;
  // �������� �� ����� ������ �������� � ������� �� �� ����������� ������
  for(int i=0;i<_bufferMove.Total();i++)
   {
    move = _bufferMove.At(i);
    // ���� ����� �����
    if (move.GetMoveType() == MOVE_TREND_UP || move.GetMoveType() == MOVE_TREND_DOWN)
     countTrend++;
    // ���� ����� ������ �����
    if (countTrend == 2)
     {
      last_index = i-1;
      break;
     }
   }
  // Comment("���������� ��������� �������� = ",last_index);
  // ������� ����� �������� �� ������� ������
  _bufferMove.DeleteRange(0,last_index);
 }
 
// ����� ��������� ��������� � �����
void CMoveContainer::UploadOnEvent(string sparam,double dparam,long lparam)
 {
  CMove *temparyMove; 
  CMove *temparyTrend;
  ENUM_PRICE_MOVE_TYPE move_type;  // 
  ENUM_PRICE_MOVE_TYPE prev_move_type;
  // ��������� ����������
  _container.UploadOnEvent(sparam,dparam,lparam);
  // ���� ��������� ��������� - ������
  if (sparam == _eventExtrDown)
   {
    
     RemoveTrendLines ();
     // �������� �������� �������� ��������
     temparyMove = new CMove("move"+_countMoves++,_chartID, _symbol, _period,_container.GetFormedExtrByIndex(0,EXTR_HIGH),_container.GetFormedExtrByIndex(1,EXTR_HIGH),_container.GetFormedExtrByIndex(0,EXTR_LOW),_container.GetFormedExtrByIndex(1,EXTR_LOW),_percent );
     
     // ���� ������� �������� ������� ��������
     if (temparyMove != NULL)
        {
         move_type = temparyMove.GetMoveType();
         // ���� ������� �����
         if (move_type == MOVE_TREND_UP || move_type == MOVE_TREND_DOWN)
          {
          
           // ��������� ������� �����
           _trendNow = temparyMove.GetMoveType();
           // �� ������� �����
           RemoveAll();
           // � ��������� ����� � �����
           _bufferMove.Add(temparyMove);
           // � ���������� ���� �������� ������
           DrawCurrentTrendLines();
          }
         // ����� ����  ��� ����
         else if (move_type == MOVE_FLAT_A ||
                  move_type == MOVE_FLAT_B ||
                  move_type == MOVE_FLAT_C ||
                  move_type == MOVE_FLAT_D ||
                  move_type == MOVE_FLAT_E ||
                  move_type == MOVE_FLAT_F ||
                  move_type == MOVE_FLAT_G 
                 )
          {
          
           // ���� ���������� ��������  ����������         
           if ( _bufferMove.Total() > 0 )
            {
             // �������� ���������� ��������
             temparyTrend = _bufferMove.At(0);
             // ���� ���������� �������� - ����� ����� ��� ����
             if (temparyTrend.GetMoveType() != MOVE_TREND_UP && temparyTrend.GetMoveType() != MOVE_TREND_DOWN)
              {
               // �� ��������� ��� � �����
               _bufferMove.Add(temparyMove);

              }
             else
              {
               // ���� ���������� �������� �� �� �����, �� ���������, ��� �� � ���� ����� ������ � ������� �������
               if (temparyMove.GetMoveExtremum(EXTR_HIGH_0).time != temparyTrend.GetMoveExtremum(EXTR_HIGH_0).time &&
                   temparyMove.GetMoveExtremum(EXTR_LOW_0).time != temparyTrend.GetMoveExtremum(EXTR_LOW_0).time 
                  )
                   {
                    // �� ��������� ��� � ����� 
                    _bufferMove.Add(temparyMove);
                   }
               else
                delete temparyMove;  // ����� ������� 
              }
            }
           else
            {
             _bufferMove.Add(temparyMove);
            }
          }
        }     
   }
  // ���� ��������� ��������� - �������
  if (sparam == _eventExtrUp)
   {
     RemoveTrendLines ();
     temparyMove = new CMove("move"+_countMoves++,_chartID, _symbol, _period,_container.GetFormedExtrByIndex(0,EXTR_HIGH),_container.GetFormedExtrByIndex(1,EXTR_HIGH),_container.GetFormedExtrByIndex(0,EXTR_LOW),_container.GetFormedExtrByIndex(1,EXTR_LOW),_percent );
     if (temparyMove != NULL)
        {
         // ���� ������� �����
         if (temparyMove.GetMoveType() == MOVE_TREND_UP || temparyMove.GetMoveType() == MOVE_TREND_DOWN)
          {
           // �� ������� �����
           RemoveAll();          
           // � ��������� ����� � �����
           _bufferMove.Add(temparyMove);
           // � ���������� ���� �������� ������
           DrawCurrentTrendLines();           
          }
         // ����� ����  ��� ����
         else if (temparyMove.GetMoveType() == MOVE_FLAT_A || 
                  temparyMove.GetMoveType() == MOVE_FLAT_B || 
                  temparyMove.GetMoveType() == MOVE_FLAT_C || 
                  temparyMove.GetMoveType() == MOVE_FLAT_D || 
                  temparyMove.GetMoveType() == MOVE_FLAT_E || 
                  temparyMove.GetMoveType() == MOVE_FLAT_F || 
                  temparyMove.GetMoveType() == MOVE_FLAT_G 
                  )
          {
           // ���� ���� ���������� ��������
           if (_bufferMove.Total() > 0)
            {   
             // �������� ���������� ��������
             temparyTrend = _bufferMove.At(0);
             // ���� ���������� �������� - �� �����    
             if (temparyTrend.GetMoveType () != MOVE_TREND_UP && temparyTrend.GetMoveType() != MOVE_TREND_DOWN)
              {         
               // �� ��������� ��� � �����
               _bufferMove.Add(temparyMove);
              }
             // ���� �� �� �����
             else
              {
               // ���� ���������� �������� �� �� �����, �� ���������, ��� �� � ���� ����� ������ � ������� �������
               if (temparyMove.GetMoveExtremum(EXTR_HIGH_0).time != temparyTrend.GetMoveExtremum(EXTR_HIGH_0).time &&
                   temparyMove.GetMoveExtremum(EXTR_LOW_0).time != temparyTrend.GetMoveExtremum(EXTR_LOW_0).time 
                  )
                   {
                    // �� ��������� ��� � ����� 
                    _bufferMove.Add(temparyMove);
                   }
               else
                delete temparyMove;  // ����� ������� 
              }
            }
           else
            {
             // �� ��������� ��� � �����
             _bufferMove.Add(temparyMove);
            }
            
          }
        }   
   }

 }
  
 
// ����� ��������� ������ �� �������
bool CMoveContainer::UploadOnHistory(void)
 { 
  if(!_isHistoryUploaded || _bufferMove.Total()<=0)
  {
   int i; // ��� ������� �� �����
   int extrTotal; // ���������� ����������� � ���������� �����������
   int dirLastExtr; // ��� ����������� ���������� ����������
   int highIndex=0; 
   int lowIndex=0;
   int countTrend=0; // ������� ������� 
   bool jumper=true; 
   bool current_trend = false; // ����, ������������ ��� ������ ������ �������
   ENUM_PRICE_MOVE_TYPE move_type; // ��� �������� ��������
   ENUM_PRICE_MOVE_TYPE prevMove = MOVE_UNKNOWN; // ��� ����������� ��������   
   CMove *temparyMove;  // ���������� ��� �������� ����������� �������� 
   CMove *moveForPrevTrend = NULL; // ��������� ��� �������� ����������� ��������
   CMove *tempPrevTrend; // ��������� �� ���������� �����
   
   // ��������� ���������� 
   for (int attempts=0;attempts<25;attempts++)
   {
    _container.Upload(0);
    Sleep(100);
   }
   // ���� ������� ���������� ��� ���������� �� �������
   if (_container.isUploaded())
   {
    extrTotal = _container.GetCountFormedExtr(); // �������� ���������� �����������
    dirLastExtr = _container.GetLastFormedExtr(EXTR_BOTH).direction; // �������� ��������� �������� ����������
    Comment("extrTotal = ",extrTotal);
    // �������� �� ����������� � ��������� ����� ��������
    for (i=0; i < extrTotal-4; i++)
    {
     // ������� ������ ��������
     temparyMove = new CMove("move"+_countMoves++,_chartID,_symbol,_period,_container.GetFormedExtrByIndex(highIndex,EXTR_HIGH),
                                                      _container.GetFormedExtrByIndex(highIndex+1,EXTR_HIGH),
                                                      _container.GetFormedExtrByIndex(lowIndex,EXTR_LOW),
                                                      _container.GetFormedExtrByIndex(lowIndex+1,EXTR_LOW),_percent );
                                                      
     // ���� ������� ��������� ��������
     if (temparyMove != NULL)
     {
      // �������� ��� �������� ��������
      move_type = temparyMove.GetMoveType();
      // ���� ���������� ����� �����
      if (move_type == MOVE_TREND_UP)
      {
       Comment("������� ����� �����");
       // ��������� ����� � �����
       _bufferMove.Add(temparyMove);     
       // ���� ���������� �������� - �� ����� �����, �� ������ ��� ������ ��������� �����
       if (prevMove != MOVE_TREND_UP)
       {
        // ����������� ���������� ��������� �����
        countTrend ++;        
       }
       // ���� ���������� �������� ����� - 2, �� ������� �� �������� �������� �� �������
       if (countTrend == 2)
       {
        _isHistoryUploaded = true;
        return (true);
       }
       // ��������� ��� ����������� ��������
       prevMove = MOVE_TREND_UP;
      }
      // ���� ���������� ����� ����
      else if (move_type == MOVE_TREND_DOWN)
      {
       Comment("������� ����� ����");
       // ��������� ����� � �����
       _bufferMove.Add(temparyMove);     
       // ���� ���������� �������� - �� ����� ����, �� ������ ��� ������ ��������� �����
       if (prevMove != MOVE_TREND_DOWN)
       {
        // ����������� ���������� ��������� �����
        countTrend ++;        
       }
       // ���� ���������� �������� ����� - 2, �� ������� �� �������� �������� �� �������
       if (countTrend == 2)
       {
        _isHistoryUploaded = true;
        return (true);
       }
       // ��������� ��� ����������� ��������
       prevMove = MOVE_TREND_DOWN;
      }  
      // ���� ���������� ����    
      else if (move_type == MOVE_FLAT_A ||
               move_type == MOVE_FLAT_B ||
               move_type == MOVE_FLAT_C ||
               move_type == MOVE_FLAT_D ||
               move_type == MOVE_FLAT_E ||
               move_type == MOVE_FLAT_F ||
               move_type == MOVE_FLAT_G 
              )
      {
         // �� ������ ��������� ��� � ����� ��������
         _bufferMove.Add(temparyMove);                
         prevMove = move_type;
      }      
     } // END 
     
      // ���� ��������� ��������� �������
    if (dirLastExtr == 1)
    {
     // ���� jumper == true, �� ����������� ������ 
     if (jumper)
     {
      highIndex++;
     }
     else
     {
      lowIndex++;
     }
     jumper = !jumper;
    }
    // ���� ��������� ��������� ������
    if (dirLastExtr == -1)
    {
     // ���� jumper == true, �� ����������� ������ 
     if (jumper)
     {
      lowIndex++;
     }
     else
     {
      highIndex++;
     }
     jumper = !jumper;
    }        
     
    } // END FOR 
   
   }

  }
 _isHistoryUploaded = false;
 return (false);  
}