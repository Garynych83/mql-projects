//+------------------------------------------------------------------+
//|                                                     BackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"//---


#include <TradeManager/TradeManagerEnums.mqh>  
#include <TradeManager/PositionArray.mqh>
#include <StringUtilities.mqh> 
#include <kernel32.mqh>
#include <Constants.mqh>  

//+------------------------------------------------------------------+
//| ��������� ��� ������ � ���������                                 |
//+------------------------------------------------------------------+

#define BT_COUNTWINS      0x1     // ����������  ���������� �������
#define BT_COUNTLOSS      0x2     // ����������  ��������� �������
#define BT_COUNTTOTAL     0x4     // ���������� ������� �����
#define BT_MAXWINPOS      0x8     // ������������ ���������� �������
#define BT_MINLOSEPOS     0x10    // ����������� ��������� �������
#define BT_MAXPROFIT      0x20    // ������������ ����������� �������
#define BT_MAXLOSS        0x40    // ������������ ����������� ������
#define BT_MAXCOUNTWIN    0x80    // ������������ ���������� ����������� ���������� �������
#define BT_MAXCOUNTLOSE   0x100   // ������������ ���������� ����������� ��������� �������
#define BT_AVERAGEPROFIT  0x200   // ������� ���������� �������
#define BT_AVERAGELOSS    0x400   // ������� ��������� �������
#define BT_CLEANPROFIT    0x800   // ������ �������
#define BT_GROSSPROFIT    0x1000  // ����� ������� 
#define BT_GROSSLOSS      0x2000  // ����� ������
#define BT_PROFITFACTOR   0x4000  // ������ ������������
#define BT_RECOVERYFACTOR 0x8000  // ������ �������������
#define BT_MATHAWAITING   0x10000 // ��� �������� ������
#define BT_ABSDRAWDOWN    0x20000 // ���������� ��������
#define BT_MAXDRAWDOWN    0x40000 // ������������ ��������
   
//+------------------------------------------------------------------+
//| ����� ��� ������ � ���������                                     |
//+------------------------------------------------------------------+

class BackTest
 {
  private:
   CPositionArray *_positionsHistory; // ������ ������� ����������� �������
   // ��������� ���� ������ ����������
   double   _balance;                 // ������
   datetime _start,_finish;           // ������� �������� �������
   string   _symbol;                  // ������
   double   _max_balance;             // ������������ ������� �������
   double   _min_balance;             // ����������� ������� �������
   double   _deposit;                 // �������
   ENUM_TIMEFRAMES _timeFrame;        // ���������
   string   _expertName;              // ��� ��������      
   // ���������� ����������   
   int    _countwins;       // ����������  ���������� �������
   int    _countloss;       // ����������  ��������� �������
   int    _counttotal;      // ���������� ������� �����
   double _maxwinpos;       // ������������ ���������� �������
   double _minlosepos;      // ����������� ��������� �������
   double _maxprofit;       // ������������ ����������� �������
   double _maxloss;         // ������������ ����������� ������
   int    _maxcountwin;     // ������������ ���������� ����������� ���������� �������
   int    _maxcountlose;    // ������������ ���������� ����������� ��������� �������
   double _averageprofit;   // ������� ���������� �������
   double _averageloss;     // ������� ��������� �������
   double _cleanprofit;     // ������ �������
   double _grossprofit;     // ����� ������� 
   double _grossloss;       // ����� ������
   double _profitfactor;    // ������ ������������
   double _recoveryfactor;  // ������ �������������
   double _mathawaiting;    // ��� �������� ������
   double _absdrawdown;     // ���������� ��������
   double _maxdrawdown;     // ������������ ��������  
   
  public:
   // Get-������ 
   int    GetCountWins () { return (_countwins); };
   int    GetCountLoss () { return (_countloss); };
   int    GetCountTotal() { return (_counttotal);};
   double GetMaxWinPos() { return (_maxwinpos); };
   double GetMinLossPos() { return (_minlosepos); };
   double GetMaxProfit() { return (_maxprofit); };
   double GetMaxLoss() { return (_maxloss); };   
   int    GetMaxCountWin () { return (_maxcountwin); };
   int    GetMaxCountLose () { return (_maxcountlose); };     
   double GetAverageProfit() { return (_averageprofit); };       
   double GetAverageLoss() { return (_averageloss); };  
   double GetCleanProfit() { return (_cleanprofit); };
   double GetGrossProfit() { return (_grossprofit); };
   double GetGrossLoss() { return (_grossloss); };
   double GetProfitFactor() { return (_profitfactor); };
   double GetRecoveryFactor() { return (_recoveryfactor); };
   double GetMathAwaiting() { return (_mathawaiting); };
   double GetAbsDrawdown() { return (_absdrawdown); };
   double GetMaxDrawDown() { return (_maxdrawdown); };                               
   //������������
   BackTest() { _positionsHistory = new CPositionArray(); };  
   BackTest(string file_url,datetime start,datetime finish)
    { 
     _positionsHistory = new CPositionArray(); 
     LoadHistoryFromFile(file_url,start,finish); 
    }; 
   // ����������
  ~BackTest() { delete _positionsHistory; };
   //������ ��������
   bool  MakeBackTest (long mode);  // ����� 
   
   
   //����� ����������� ������� ������� � ������� ������� �� �������
   int   GetIndexByDate(datetime dt,bool type);
   //������ ���������� �������� ������� � ������� �� �������
   uint   GetNTrades();     //��������� ���������� ������� �� �������
   uint   GetNSignTrades(int sign);  //��������� ���������� ���������� ������� �� �������
   //���������� ��������
   void GetProfits();           
   //����� ������� �� �������
   int    GetSignPosition(uint index);    //��������� ���� ������� �� ������� 
   //����� ���������� ���������� �����������
   double GetIntegerPercent(uint value1,uint value2);   //����� ���������� ����������� ����������� value1 �� ���������  � value2
   //������ ���������� ������������ � ������� �������
   double GetMaxTrade(int sign);          //��������� ����� �������  ����� �� �������
   double GetAverageTrade(int sign);      //��������� �������  �����
   //������ ���������� ��������� ������ ������ �������
   uint   GetMaxInARowTrades(int sign); 
   //������ ���������� ������������ ����������� ������� � ������
   double GetMaxInARow(int sign);  
   //������ ���������� �������� �������
   double GetAbsDrawdown ();              //��������� ���������� �������� �������
   double GetRelDrawdown ();              //��������� ������������� �������� �������
   double GetMaxDrawdown ();              //��������� ������������ �������� �������
   //����� ���������� �������� ������� 
   double GetTotalProfit ();  
   //����� ��������� ������������ � ����������� ������
   void   GetBalances ();   
   //����� ��������� ������ �������
   void   SaveBalanceToFile (int file_handle);
   //������ ��������� ������
   bool LoadHistoryFromFile(string file_url,datetime start,datetime finish);          //��������� ������� ������� �� �����
   void GetHistoryExtra(CPositionArray *array);        //�������� ������� ������� �����
 //  void Save
   bool SaveBackTestToFile (string file_name,string symbol,ENUM_TIMEFRAMES timeFrame,string expertName); //��������� ���������� ��������
   //�������������� ������
   string SignToString (int sign);                     //��������� ���� ������� � ������
   //��������� ������ � ���� 
 };

//+------------------------------------------------------------------+
//| ���������� ������ �� ����                                        |
//+------------------------------------------------------------------+

 int BackTest::GetIndexByDate(datetime dt,bool type)
  {
   int index;
   CPosition *pos;
   switch (type)
    {
     //���� ����� ����� ������ �������, ������� �������� ����
     case true:
      index = 0;
      //�������� �� ������� �������
      do 
       {
        pos = _positionsHistory.Position(index);
        index++;
       }
      while (index < _positionsHistory.Total() && pos.getOpenPosDT() < dt );
      //���� ������� �������, �� ������ � ������
      if (index <_positionsHistory.Total())
       return index;
     break; 
     //���� ����� ����� ������ ������� ����� �������� �����
     case false:
      index = _positionsHistory.Total();
      //�������� �� ������� �������
      do 
       {
        index--;
        pos = _positionsHistory.Position(index);
       }
      while (index >= 0 && pos.getOpenPosDT() > dt );
      //���� ������� �������, �� ������ � ������
      if (index >=  0)
       return index;     
     break;
    }
   return -1;  //���� ������� �� �������
  } 
 
 
//+------------------------------------------------------------------+
//| ��������� ���������� ������� � �������                           |
//+------------------------------------------------------------------+
 uint BackTest::GetNTrades()
  {
   return _positionsHistory.Total();  //������ �������
  }
//+------------------------------------------------------------------+
//| ��������� ���������� ������� �� �����                            |
//+------------------------------------------------------------------+
  uint BackTest::GetNSignTrades(int sign) // (1) - ���������� ������ (-1) - ���������
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   uint count=0; //���������� ������� � ������ ��������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� �������
     if (pos.getPosProfit()*sign > 0) //���� ������ ������� ��������� � ���������� � ������ �������������
      {
       count++; //����������� ���������� ����������� ������� �� �������
      }
    }
    return count;
  }

//+------------------------------------------------------------------+
//| ��������� �������                                                | 
//+------------------------------------------------------------------+

 void BackTest::GetProfits(void)
  {
   CPosition * pos;
   int length = _positionsHistory.Total(); 
   int index;
   // ���������� �� ��������� �������
   _clean_profit = 0;
   _gross_profit = 0;
   _gross_loss   = 0;
   for (index=0;index<length;index++)
    {
     pos = _positionsHistory.At(index);
     // ������������ ������ �������
     if (pos.getPosProfit()>=0)
      _gross_profit = _gross_profit + pos.getPosProfit();
     else
      _gross_loss   = _gross_loss + pos.getPosProfit();
     
    }
    _clean_profit = _gross_profit + _gross_loss;
  } 

    
//+------------------------------------------------------------------+
//| ���������� ����  ������� �� �������                              |  
//+------------------------------------------------------------------+   
 int  BackTest::GetSignPosition(uint index)
  {
   CPosition * pos;
   double profit;
     pos = _positionsHistory.Position(index);
     profit = pos.getPosProfit();
      if (profit>0)
        return 1;
      if (profit<0)
        return -1;
       return 0;
  }
//+------------------------------------------------------------------+
//| ��������� ���������� ����������� value1 � value2                 |
//+------------------------------------------------------------------+  

 double BackTest::GetIntegerPercent(uint value1,uint value2)
  {
   if (value2)
   return 1.0*value1/value2;
   return -1;
   
  }

//+------------------------------------------------------------------+
//| ��������� ����� ������� �� �����                                 |
//+------------------------------------------------------------------+    

double BackTest::GetMaxTrade(int sign) //sign = 1 - ����� ������� ����������, (-1) - ����� ������� ���������
 {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double maxTrade = 0;  //�������� ������������� ������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getPosProfit()*sign > maxTrade)
      {
       maxTrade = pos.getPosProfit();
      }
    }  
    return maxTrade;
 }
 

 
//+------------------------------------------------------------------+
//| ��������� ������� �������                                        |
//+------------------------------------------------------------------+

double BackTest::GetAverageTrade(int sign) // (1) - ������� ����������, (-1) - ������� ���������, (0) - ������� �� ����
 {
   uint index;
   uint total = _positionsHistory.Total();    //������ �������
   double tradeSum = 0;                       //����� ������� 
   uint count = 0;                            //���������� ����������� �������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (sign != 0)
      {
       if ( pos.getPosProfit()*sign > 0 ) 
        {
         count++; //����������� ������� ������� �� �������
         tradeSum = tradeSum + pos.getPosProfit(); //� ����� ����� ���������� �����
        }
      }
      else
      {
         count++; //����������� ������� ������� �� �������
         tradeSum = tradeSum + pos.getPosProfit(); //� ����� ����� ���������� �����
      }  
     }
   if (count)
    return tradeSum/count; //���������� �������
   return -1;
 }   
   
 
//+------------------------------------------------------------------+
//| ��������� ����. ���������� ������ ������ ������� �� �����        |
//+------------------------------------------------------------------+

 uint BackTest::GetMaxInARowTrades(int sign) //sign 1 - ���������� ������, (-1) - ��������� ������ 
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   uint max_count = 0; //������������ ���������� ������ ������ �������
   uint count = 0;     //������� ���� �������
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
       if (pos.getPosProfit()*sign > 0) 
         {
           count++; //����������� ����������
         }
        else
         {
          if (count>0)  
           {
            if (count > max_count) //���� ������� ���������� ������ �����������
             {
              max_count = count;   //�������� �������
             }
            count = 0;             //�������� �������
           }
         }   
    }   
    if (count>max_count)
    {
     max_count = count;
    }      
    return max_count; 
  }
  
  
//+------------------------------------------------------------------+
//| ��������� ������������ ����������� ������� (1) ��� ������ (-1)   |
//+------------------------------------------------------------------+

 double BackTest::GetMaxInARow(int sign)  //sign: 1 - �� ����������, (-1) - �� ���������
  {
   uint index;
   uint total = _positionsHistory.Total();            //������ �������
   double tradeSum = 0;                               //��������� ���������� 
   double maxTrade = 0;                               //������������ ����������� �����
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index);         //�������� ��������� �� ������� 
        if (pos.getPosProfit()*sign > 0)              
         {
           tradeSum = tradeSum + pos.getPosProfit();  //���������� ������ �������
         }
        else
         {
          if (tradeSum*sign>0)  
           {
            if (tradeSum*sign > maxTrade*sign)        
             {
              maxTrade = tradeSum; 
             }
            tradeSum = 0;
           }
         }
    }   
            if (tradeSum*sign > maxTrade*sign)
             maxTrade = tradeSum;
    return maxTrade; 
  }  

 
//+-------------------------------------------------------------------+
//| ��������� ���������� �������� �� �������                          |
//+-------------------------------------------------------------------+

double BackTest::GetAbsDrawdown(void)
 {
   if (_min_balance < 0)
    return -_min_balance; 
   return 0; 
 }

  
//+-------------------------------------------------------------------+
//| ��������� ������������ �������� �� �������                        |
//+-------------------------------------------------------------------+  
double BackTest::GetMaxDrawdown () //(������ ��� ����� ������ ������� - �������)
 {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double MaxBalance = 0;   //������������ ������ �� ������� ������ (������ ���� ����� �������� ��������� ������)
   double MaxDrawdown = 0;  //������������ �������� �������
  
   CPosition * pos;
   _balance = 0;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
       _balance = _balance + pos.getPosProfit(); //������������� ������� ������
       if (_balance > MaxBalance)  //���� ������ �������� ������� ������������ ������, �� �������������� ���
        {
          MaxBalance = _balance;
        }
       else 
        {
         if ((MaxBalance-_balance) > MaxDrawdown) //���� ���������� ������ ��������, ��� ����
          {
            MaxDrawdown = MaxBalance-_balance;  //�� ���������� ����� �������� �������
          }
        }
    }  
   return MaxDrawdown; //���������� ������������ �������� �� �������
 }
 
//+-------------------------------------------------------------------+
//| ���������� �������� ������                                        |
//+-------------------------------------------------------------------+

double BackTest::GetTotalProfit()
 {
  return _balance;
 }  
 
//+-------------------------------------------------------------------+
//| ��������� ������������ � ����������� �������                      |
//+-------------------------------------------------------------------+

void  BackTest::GetBalances()
 {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double balance  = 0;                     //������������ ������ �� ������� ������ (������ ���� ����� �������� ��������� ������)
   double sizeOfLot;   
   CPosition * pos;                         //��������� �� �������                                  
   //�������� ������
   _max_balance = 0;
   _min_balance = 0;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index);   //�������� ��������� �� ������� 
     sizeOfLot = GetLotBySymbol (_symbol)*pos.getVolume();     
        balance = balance + pos.getPosProfit()*sizeOfLot; // ������������ ������
        if (balance > _max_balance)  
         _max_balance = balance;
        if (balance < _min_balance)
         _min_balance = balance;
    }

 } 
 
//+-------------------------------------------------------------------+
//| ��������� � ���� ���������� ������ �������                        |
//+-------------------------------------------------------------------+ 

void BackTest::SaveBalanceToFile(int file_handle)
 {
  int    total = _positionsHistory.Total();                      // ����� ���������� ������� � �������
  double current_balance = 0;                                    // ������� ������
  CPosition *pos;                                                // ��������� �� �������  
  double sizeOfLot;   
  WriteTo  (file_handle,DoubleToString(current_balance)+" ");    // ��������� ����������� ������  
  for (int index=0;index<total;index++)
   {
    // �������� ��������� �� �������
    pos = _positionsHistory.Position(index);
    sizeOfLot = GetLotBySymbol (_symbol)*pos.getVolume();
    current_balance = current_balance + pos.getPosProfit()*sizeOfLot; // ���������  ������ � ������ �����, ��������� � ������� ������� �� �������
    WriteTo  (file_handle,DoubleToString(current_balance)+" "); 
   }
 }
  
//+-------------------------------------------------------------------+
//| ��������� ������� ������� �� �����                                |
//+-------------------------------------------------------------------+   
  
bool BackTest::LoadHistoryFromFile(string file_url,datetime start,datetime finish)
{

 if(MQL5InfoInteger(MQL5_TESTING) || MQL5InfoInteger(MQL5_OPTIMIZATION) || MQL5InfoInteger(MQL5_VISUAL_MODE))
 {
  FileDelete(file_url);
  return(true);
 }
 int file_handle;   //�������� �����  
 if (!FileIsExist(file_url, FILE_COMMON) ) //�������� ������������� ����� ������� 
 {

  PrintFormat("%s File %s doesn't exist", MakeFunctionPrefix(__FUNCTION__),file_url);
  return (false);
 }  
 file_handle = FileOpen(file_url, FILE_READ|FILE_COMMON|FILE_CSV, ";");
 if (file_handle == INVALID_HANDLE) //�� ������� ������� ����
 {
  FileClose(file_handle);
  PrintFormat("%s error: %s opening %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(::GetLastError()), file_url);
  return (false);
 }

 _positionsHistory.Clear();                   //������� ������
 _positionsHistory.ReadFromFile(file_handle,start,finish); //��������� ������ �� ����� 
 
 _start = start;
 _finish   = finish;
 
 FileClose(file_handle);                      //��������� ����  
 return (true);
}  
  
  
//+-------------------------------------------------------------------+
//| �������� ������� ������� �����                                    |
//+-------------------------------------------------------------------+

void BackTest::GetHistoryExtra(CPositionArray *array)
 {
  _positionsHistory = array;
 } 
 
//+-------------------------------------------------------------------+
//| ��������� ����������� ��������� ��������                          |
//+-------------------------------------------------------------------+
bool BackTest::SaveBackTestToFile (string file_name,string symbol,ENUM_TIMEFRAMES timeFrame,string expertName)
 {
  double current_balance;
  double sizeOfLot;      // ������ ����
  CPosition *pos;
  uint total = _positionsHistory.Total();  //����� ���������� ������� � �������
  //��������� ���� ��� ���-��� �������� �� ������
  int file_handle = CreateFileW(file_name, _GENERIC_WRITE_, _FILE_SHARE_WRITE_, 0, _CREATE_ALWAYS_, 128, NULL);  
  //���� �� ������� ������� ����
  if(file_handle <= 0 )
   {
    Alert("�� �������� ������� ���� ����������� ��������");
    return(false);
   }
  // ��������� ��������� ���������� ����������
  _timeFrame  = timeFrame;
  _expertName = expertName;
  _symbol     = symbol;
  // ��������� ����������� ������ ���� �� �������
  pos = _positionsHistory.Position(0);
  // ������ ���� �� �������
  sizeOfLot = GetLotBySymbol (_symbol)*pos.getVolume();
  //���������� ��� �������� ���������� ��������
  uint    n_trades           =  GetNTrades();                     //���������� �������
  uint    n_win_trades       =  GetNSignTrades(1);                //���������� ���������� �������
  uint    n_lose_trades      =  GetNSignTrades(-1);               //���������� ���������� �������
  int     sign_last_pos      =  GetSignPosition(_positionsHistory.Total()-1); //���� ��������� �������
  double  max_trade          =  GetMaxTrade(1)*sizeOfLot;                     //����� ������� ����� �� �������
  double  min_trade          =  GetMaxTrade(-1)*sizeOfLot;        //����� ��������� ����� �� �������
  double  aver_profit_trade  =  GetAverageTrade(1)*sizeOfLot;     //������� ���������� ����� 
  double  aver_lose_trade    =  GetAverageTrade(-1)*sizeOfLot;    //������� ��������� �����   
  uint    maxPositiveTrades  =  GetMaxInARowTrades(1);            //������������ ���������� ������ ������ ������������� �������
  uint    maxNegativeTrades  =  GetMaxInARowTrades(-1);           //������������ ���������� ������ ������ ������������� �������
  double  maxProfitRange     =  GetMaxInARow(1)*sizeOfLot;        //������������ ������
  double  maxLoseRange       =  GetMaxInARow(-1)*sizeOfLot;       //������������ ������
  double  maxDrawDown        =  GetMaxDrawdown()*sizeOfLot;       //������������ ��������
  double  absDrawDown;                                            //���������� ��������
  double  profitFactor;                                           //������ �������
  double  recoveryFactor;                                         //��������� ������ ������� � ���������� ������������ ��������
  double  mathAwaiting;                                           //����������� ������
   
  GetBalances();  // ��������� ������������ � ����������� ������
  
  GetProfits ();  // ��������� �������
  
  _clean_profit  = _clean_profit * sizeOfLot;
  _gross_loss    = _gross_loss * sizeOfLot;
  _gross_profit  = _gross_profit * sizeOfLot;
  profitFactor   = _gross_profit / _gross_loss;
  recoveryFactor = _clean_profit / maxDrawDown;
  mathAwaiting   = GetAverageTrade(0) * sizeOfLot;
  absDrawDown    = GetAbsDrawdown();
  
  //��������� � ���� ������ �� �������� , ���������� � ������
  WriteTo  (file_handle,_expertName+" ");                  // ��������� ��� ��������
  WriteTo  (file_handle,_symbol+" ");                      // ��������� ������
  WriteTo  (file_handle,IntegerToString(ArraySearchString(symArray,_symbol) )+" ");    // ��������� ������ (��� �������)
  WriteTo  (file_handle,PeriodToString(_timeFrame)+" ");   // ��������� ���������  
  pos = _positionsHistory.Position(_positionsHistory.Total()-1);         //�������� ��������� �� ������ �������   
  WriteTo  (file_handle,IntegerToString(pos.getOpenPosDT())+" ");      // ��������� ����� ������ ���������� ������� � Unix Time
  pos = _positionsHistory.Position(0);         //�������� ��������� �� ��������� �������    
  WriteTo  (file_handle,IntegerToString(pos.getOpenPosDT())+" ");     // ��������� ����� ����� ���������� ������� � Unix Time
  WriteTo  (file_handle,DoubleToString(_max_balance)+" "); // ������������ ������
  WriteTo  (file_handle,DoubleToString(_min_balance)+" "); // ����������� ������
  
  //��������� ���� ���������� ���������� ��������
  WriteTo  (file_handle,IntegerToString(n_trades+1)+" ");
  WriteTo  (file_handle,IntegerToString(n_win_trades)+" ");
  WriteTo  (file_handle,IntegerToString(n_lose_trades+1)+" ");
  WriteTo  (file_handle,IntegerToString(sign_last_pos)+" ");
  WriteTo  (file_handle,DoubleToString(max_trade)+" ");
  WriteTo  (file_handle,DoubleToString(min_trade)+" ");   
  WriteTo  (file_handle,DoubleToString(maxProfitRange)+" "); 
  WriteTo  (file_handle,DoubleToString(maxLoseRange)+" ");
  WriteTo  (file_handle,IntegerToString(maxPositiveTrades)+" ");  
  WriteTo  (file_handle,IntegerToString(maxNegativeTrades)+" ");
  WriteTo  (file_handle,DoubleToString(aver_profit_trade)+" ");
  WriteTo  (file_handle,DoubleToString(aver_lose_trade)+" ");    
  WriteTo  (file_handle,DoubleToString(maxDrawDown)+" ");
  WriteTo  (file_handle,DoubleToString(absDrawDown)+" ");
  WriteTo  (file_handle,DoubleToString(_clean_profit)+" ");
  WriteTo  (file_handle,DoubleToString(_gross_profit)+" ");
  WriteTo  (file_handle,DoubleToString(_gross_loss)+" ");
  WriteTo  (file_handle,DoubleToString(profitFactor)+" ");
  WriteTo  (file_handle,DoubleToString(recoveryFactor)+" ");  
  WriteTo  (file_handle,DoubleToString(mathAwaiting)+" "); 
                                         
  //��������� ����� �������� (�������, �����)
  SaveBalanceToFile(file_handle);
  //��������� ����
  CloseHandle(file_handle);
 return (true);
 }

//+-------------------------------------------------------------------+
//| �������������� ������                                             |
//+-------------------------------------------------------------------+

string BackTest::SignToString(int sign)
 //��������� ���� ������� � ������
 {
   if (sign == 1)
    return "positive";
   if (sign == -1)
    return "negative";
   return "no sign";
 }