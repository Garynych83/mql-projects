//+------------------------------------------------------------------+
//|                                        TesterOfMoveContainer.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

// ����� ���������� �� ����������

#include <DrawExtremums/CExtrContainer.mqh> // ��������� �����������
#include <DrawExtremums/CExtremum.mqh> // ������ �����������
#include <SystemLib/IndicatorManager.mqh> // ���������� �� ������ � ������������
#include <ChartObjects/ChartObjectsLines.mqh> // ��� ��������� ����� ������
#include <TradeManager/TradeManager.mqh> // �������� ����������

input double percent = 0.1; // ������� �������� ������
input double volume = 1.0; // ���
// ������� �������
CExtrContainer *extr_container;
CTradeManager *ctm;
bool firstUploadedExtr = false;
int handleDE;
string cameHighEvent;  // ��� ������� ������� �������� ����������
string cameLowEvent;   // ��� ������� ������� ������� ����������
// ���������� ������
double h; // ������ ������ �����
double bottom_price; // ���� ������ ������� ������
double top_price; // ���� ������� ������� ������
// ���������� ��������
CExtremum trend_high0,trend_high1; 
CExtremum trend_low0,trend_low1;

CExtremum flat_high0,flat_high1;
CExtremum flat_low0,flat_low1;

// ������� ����������� ������ ������
CChartObjectTrend flatLine;    // ������ ������ �������� �����
CChartObjectTrend trendLine;   // ������ ������ ��������� �����
// ��������� �������
SPositionInfo pos_info;
STrailing trailing;
int mode = 0;  // 0 - ����� ������ ��������, 1 - ����� �������� ��������
int flat = 0; // ��� �����
int trend = 0; // ��� ������

int OnInit()
  {  
   // ���� 
   
   // ������� ������ ��������� ������
   ctm = new CTradeManager ();
   // ��������� ����� �������
   cameHighEvent = GenUniqEventName("EXTR_UP_FORMED");
   cameLowEvent  = GenUniqEventName("EXTR_DOWN_FORMED");
   // �������� ���������� DrawExtremums
   handleDE = DoesIndicatorExist(_Symbol, _Period, "DrawExtremums");
   if (handleDE == INVALID_HANDLE)
    {
     handleDE = iCustom(_Symbol, _Period, "DrawExtremums");
     if (handleDE == INVALID_HANDLE)
      {
       Print("�� ������� ������� ����� ���������� DrawExtremums");
       return (INIT_FAILED);
      }
     SetIndicatorByHandle(_Symbol, _Period, handleDE);
    }  
   extr_container = new CExtrContainer(handleDE,_Symbol,_Period);
   
   pos_info.volume = volume;
   pos_info.expiration = 0;
 
   trailing.trailingType = TRAILING_TYPE_NONE;
   trailing.handleForTrailing = 0;   
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   // ������� ������� �� ������
   delete extr_container;
   delete ctm;
  }

void OnTick()
  {
    ctm.OnTick();
    if (!firstUploadedExtr)
    {
     firstUploadedExtr = extr_container.Upload();
    }    
   if (!firstUploadedExtr)
    return;    
   // ���� ���� ����� mode = 1
   if (mode == 1)
    {
     // ���� ������� ��������� (�������� �� ����� ��� �����)
     if (ctm.GetPositionCount() == 0)
      mode = 0;
     
     /*
     // ���� ������ ����� � �� �������������� �����������
     if ( IsItTrend(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                    extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) == -trend)
                    {
                     // �� ��������� �������
                     ctm.ClosePosition(0);
                     mode = 0;
                    }
     */
    }
  }
  
// ������� ��������� ������� �������
void OnChartEvent(const int id,         // ������������� �������  
                  const long& lparam,   // �������� ������� ���� long
                  const double& dparam, // �������� ������� ���� double
                  const string& sparam  // �������� ������� ���� string 
                 )
  {
    // ��������� ��������� �����������
    extr_container.UploadOnEvent(sparam,dparam,lparam);
    // ���� ������ �������, ��� ������������� ������� ���������
    if (sparam == cameHighEvent)
     {
      // ���� ������ ����� 0, �� ���� ����
      if (mode == 0)
       {
        // ���� ������ ���� 
        if (flat = GetFlatMove(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                     extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                    {
                     // ���������, ��� ���������� �������� �� �������� �������
                     if (!IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                         extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                         {
                          // ���������, ��� ���� ����������� �������� - �����
                          if (trend = IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                                         {
                                           // ��������� ��������� ������
                                           CountFlatChannel();       
                                           // �������� ������� �������     
                                           if ( PositionOpen(flat,trend,1) )
                                            {
                                             DrawChannel ();                                
                                             mode = 1;
                                            }
                                         }
                         }
                    }
                    
       } // END OF MODE
     } // END OF SPARAM
    // ���� ������ �������, ��� ������������� ������ ���������
    if (sparam == cameLowEvent)
     {
      // ���� ������ ����� 0, �� ���� ����
      if (mode == 0)
       {
        // ���� ������ ���� 
        if (flat =  GetFlatMove(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                     extr_container.GetFormedExtrByIndex(0,EXTR_LOW),extr_container.GetFormedExtrByIndex(1,EXTR_LOW) ) )
                    {
                     // ���������, ��� ���������� �������� �� �������� �������
                     if (!IsItTrend(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH),extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),
                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                         {
                          // ���������, ��� ���� ����������� �������� - �����
                          if (trend = IsItTrend(extr_container.GetFormedExtrByIndex(1,EXTR_HIGH),extr_container.GetFormedExtrByIndex(2,EXTR_HIGH),
                                         extr_container.GetFormedExtrByIndex(1,EXTR_LOW),extr_container.GetFormedExtrByIndex(2,EXTR_LOW) ) )
                                         {
                                           // ��������� ��������� ������
                                           CountFlatChannel();      
                                           // �������� ������� �������
                                           if ( PositionOpen(flat,trend,-1) )
                                            {
                                             DrawChannel ();
                                             mode = 1;
                                            }
                                         }
                         }
                    }
                    
       } // END OF MODE
     } // END OF SPARAM     
  }
  
 // ������� ��������� ��������� ������ �����
 void CountFlatChannel ()
  {
   h = MathMax(extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price,extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price) -
       MathMin(extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price,extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price);
   top_price = extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price + 0.75*h;
   bottom_price = extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price - 0.75*h;
  } 
  
  
 // �������������� �������
 void  DrawChannel ()  // ������� ����� �����
  {
   DeleteAllLines ();
   flatLine.Create(0, "flatUp", 0, extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(0,EXTR_HIGH).price, 
                                   extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price); // ������� �����  
   
   flatLine.Color(clrYellow);
   flatLine.Width(2);
   flatLine.Create(0, "flatDown", 0, extr_container.GetFormedExtrByIndex(0,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(0,EXTR_LOW).price, 
                                     extr_container.GetFormedExtrByIndex(1,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price); // ������ �����  
   flatLine.Color(clrYellow);
   flatLine.Width(2);
   
   
   trendLine.Create(0, "trendUp", 0, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(1,EXTR_HIGH).price, 
                                   extr_container.GetFormedExtrByIndex(2,EXTR_HIGH).time, extr_container.GetFormedExtrByIndex(2,EXTR_HIGH).price); // ������� �����  
   
   trendLine.Color(clrLightBlue);
   trendLine.Width(2);
   trendLine.Create(0, "trendDown", 0, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(1,EXTR_LOW).price, 
                                     extr_container.GetFormedExtrByIndex(2,EXTR_LOW).time, extr_container.GetFormedExtrByIndex(2,EXTR_LOW).price); // ������ �����  
   trendLine.Color(clrLightBlue);
   trendLine.Width(2);   
   
  }
  
 // ������� ������� ����� � �������
 void DeleteAllLines ()
  {
   ObjectDelete(0,"flatUp");
   ObjectDelete(0,"flatDown");
   ObjectDelete(0,"trendUp");
   ObjectDelete(0,"trendDown");
  }

// ��������� �������� 
int GetFlatMove (CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1)
 {
  double height = MathMax(high0.price,high1.price) - MathMin(low0.price,low1.price);
   
  if ( LessOrEqualDoubles (MathAbs(high1.price-high0.price),percent*height) &&
       LessOrEqualDoubles (MathAbs(low0.price - low1.price),percent*height)
     )
     {
      return (1); // ���� C
     }

  /*
  
  if ( GreatOrEqualDoubles (high1.price - high0.price,percent*height) &&
       GreatOrEqualDoubles (low0.price - low1.price,percent*height)
     )
     {
      return (2); // ���� D
     }
  if ( GreatOrEqualDoubles (high0.price-high1.price,percent*height) &&
       GreatOrEqualDoubles (low1.price - low0.price,percent*height)
     )
     {
      return (3); // ���� E
     }

  if ( LessOrEqualDoubles (MathAbs(high1.price-high0.price), percent*height) &&
       GreatOrEqualDoubles (low1.price -low0.price , percent*height)
     )
     {
      return (4); // ���� F
     }
  
  */
  
  return (0);
 }  
     
int IsItTrend(CExtremum *high0,CExtremum *high1,CExtremum *low0, CExtremum *low1) // ���������, �������� �� ������ ����� ���������
 {
  double h1,h2;
  double H1,H2;
  // ���� ����� ����� 
  if ( GreatDoubles(high0.price,high1.price) && GreatDoubles(low0.price,low1.price))
   {
    // ���� ��������� ��������� - ����
    if (low0.time > high0.time)
     {
      H1 = high0.price - low1.price;
      H2 = high1.price - low1.price;
      h1 = MathAbs(low0.price - low1.price);
      h2 = MathAbs(high0.price - high1.price);
      // ���� ���� ��������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (1);
     }
    // ���� ��������� ��������� - �����
    if (low0.time < high0.time)
     {
      H1 = high1.price - low0.price;
      H2 = high1.price - low1.price;
      h1 = MathAbs(low0.price - low1.price);
      h2 = MathAbs(high0.price - high1.price);
      // ���� ���� ��������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )
       return (1);
     }
      
   }
  // ���� ����� ����
  if ( LessDoubles(high0.price,high1.price) && LessDoubles(low0.price,low1.price))
   {
    
    // ����  ��������� ��������� - �����
    if (high0.time > low0.time)
     {
      H1 = high1.price - low0.price;    
      H2 = high1.price - low1.price;
      h1 = MathAbs(high0.price - high1.price);
      h2 = MathAbs(low0.price - low1.price);
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h1,H1*percent) && GreatDoubles(h2,H2*percent) )    
       return (-1);
     }
    // ���� ��������� ��������� - ����
    else if (high0.time < low0.time)
     {
      H1 = high0.price - low1.price;    
      H2 = high1.price - low1.price;
      h1 = MathAbs(high0.price - high1.price);
      h2 = MathAbs(low0.price - low1.price);
      // ���� ���� ����������� ����� ��� �������������
      if (GreatDoubles(h2,H1*percent) && GreatDoubles(h1,H2*percent) )    
       return (-1);
     }
     
   }   
   
  return (0);
 } 
 
// ���������� ��� ������� 
string  GenUniqEventName(string eventName)
 {
  return (eventName + "_" + _Symbol + "_" + PeriodToString(_Period));
 }
 
// ������� ��������� �������
bool PositionOpen (int flat,int trend,int extr)
 { 
   // ���� ���� C, ����� ����� � ��������� ��������� - ������
   if (flat == 1 && trend == 1 && extr == -1)
    {
     pos_info.type = OP_BUY;
     pos_info.sl = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - bottom_price) /_Point)  );
     pos_info.tp = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - top_price)/_Point)  );
     pos_info.priceDifference = 0;
     pos_info.expiration = 0;
     trailing.minProfit = 0;                                         
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);  
     return (true);   
    }
    
   /* 
    
   // ���� ���� D, ����� ����� � ��������� ��������� - ������
   if (flat == 2 && trend == 1 && extr == -1)
    {
     pos_info.type = OP_BUY;
     pos_info.sl = int (  MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - bottom_price) /_Point)  );
     pos_info.tp = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - top_price)/_Point)  );
     pos_info.priceDifference = 0;
     pos_info.expiration = 0;
     trailing.minProfit = 0;                                         
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);   
     return (true);  
    }
        
   // ���� ���� E, ����� ����� � ��������� ��������� - ������
   if (flat == 3 && trend == 1 && extr == 1)
    {
     pos_info.type = OP_BUY;
     pos_info.sl = int (  MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - bottom_price) /_Point)  );
     pos_info.tp = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - top_price)/_Point)  );
     pos_info.priceDifference = 0;
     pos_info.expiration = 0;
     trailing.minProfit = 0;                                         
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);     
     return (true);
    } 
   // ���� ���� F, ����� ����� � ��������� ��������� - ������
   if (flat == 4 && trend == 1 && extr == -1)
    {
     pos_info.type = OP_SELL;
     pos_info.sl = int (  MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - top_price) /_Point)  );
     pos_info.tp = int ( MathAbs ( (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - bottom_price)/_Point)  );
     pos_info.priceDifference = 0;
     pos_info.expiration = 0;
     trailing.minProfit = 0;                                         
     ctm.OpenUniquePosition(_Symbol,_Period,pos_info,trailing);   
     return (true);  
    }   
     
   */
       
  return (false);    
 }