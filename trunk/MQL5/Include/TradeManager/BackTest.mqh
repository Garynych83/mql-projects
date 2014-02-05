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

//+------------------------------------------------------------------+
//| ������ WIN API ����������                                        |
//+------------------------------------------------------------------+

#import "kernel32.dll"

  bool CloseHandle                // �������� �������
       ( int hObject );                  // ����� �������
       
  int CreateFileW                 // �������� �������� �������
      ( string lpFileName,               // ������ ���� ������� � �������
        int    dwDesiredAccess,          // ��� ������� � �������
        int    dwShareMode,              // ����� ������ �������
        int    lpSecurityAttributes,     // ��������� ������������
        int    dwCreationDisposition,    // ��������� ��������
        int    dwFlagsAndAttributes,     // ����� ����������
        int    hTemplateFile );      
          
  bool WriteFile                  // ������ ������ � ����
       ( int    hFile,                   // handle to file to write to
         char    &dBuffer[],             // pointer to data to write to file
         int    nNumberOfBytesToWrite,   // number of bytes to write
         int&   lpNumberOfBytesWritten[],// pointer to number of bytes written
         int    lpOverlapped );          // pointer to structure needed for overlapped I/O    
  
  int  RtlGetLastWin32Error();
  
  int  RtlSetLastWin32Error (int dwErrCode);       
    
#import

//+------------------------------------------------------------------+
//| ����������� ���������                                            |
//+------------------------------------------------------------------+

// ��� ������� � �������
#define _GENERIC_WRITE_      0x40000000
// ����� ������ �������
#define _FILE_SHARE_WRITE_   0x00000002
// ��������� ��������
#define _CREATE_ALWAYS_      2

//+------------------------------------------------------------------+
//| ����� ��� ������ � ���������                                     |
//+------------------------------------------------------------------+

class BackTest
 {
  private:
   CPositionArray *_positionsHistory; // ������ ������� ����������� �������
   double  _balance;                  // ������
   datetime _start,_finish;           // ������� �������� �������
   string   _symbol;                  // ������
   double   _max_balance;             // ������������ ������� �������
   double   _min_balance;             // ����������� ������� �������
   double   _deposit;                 // �������
   ENUM_TIMEFRAMES _timeFrame;        // ���������
   string   _expertName;              // ��� ��������   
  public:
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
   //����� ����������� ������� ������� � ������� ������� �� �������
   int   GetIndexByDate(datetime dt,bool type);
   //������ ���������� �������� ������� � ������� �� �������
   uint   GetNTrades(string symbol);     //��������� ���������� ������� �� �������
   uint   GetNSignTrades(string symbol,int sign);  //��������� ���������� ���������� ������� �� �������
   //����� ������� �� �������
   int    GetSignLastPosition(string symbol);           //���������� ���� ��������� ������� 
   int    GetSignPosition(string symbol,uint index);    //��������� ���� ������� �� ������� 
   //����� ���������� ���������� �����������
   double GetIntegerPercent(uint value1,uint value2);   //����� ���������� ����������� ����������� value1 �� ���������  � value2
   //������ ���������� ������������ � ������� �������
   double GetMaxTrade(string symbol,int sign);          //��������� ����� �������  ����� �� �������
   double GetAverageTrade(string symbol,int sign);      //��������� �������  �����
   //������ ���������� ��������� ������ ������ �������
   uint   GetMaxInARowTrades(string symbol,int sign); 
   //������ ���������� ������������ ����������� ������� � ������
   double GetMaxInARow(string symbol,int sign);  
   //������ ���������� �������� �������
   double GetAbsDrawdown (string symbol);              //��������� ���������� �������� �������
   double GetRelDrawdown (string symbol);              //��������� ������������� �������� �������
   double GetMaxDrawdown (string symbol);              //��������� ������������ �������� �������
   //����� ���������� �������� ������� 
   double GetTotalProfit (string symbol);  
   //����� ��������� ������������ � ����������� ������
   void   GetBalances (string symbol);   
   //����� ��������� ������ �������
   void   SaveBalanceToFile (int file_handle);
   //������ ��������� ������
   bool LoadHistoryFromFile(string file_url,datetime start,datetime finish);          //��������� ������� ������� �� �����
   void DeleteHistory ();   // ������� ������ ������� 
   void GetHistoryExtra(CPositionArray *array);        //�������� ������� ������� �����
 //  void Save
   bool SaveBackTestToFile (string file_name,string symbol,ENUM_TIMEFRAMES timeFrame,string expertName); //��������� ���������� ��������
   void WriteTo (int handle,string buffer);            // ��������� � ���� ������ �� ��������� ������
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
//| ��������� ���������� ������� �� �������                          |
//+------------------------------------------------------------------+
 uint BackTest::GetNTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   CPosition *pos;
   uint count=0; //���������� ������� � ������ ��������   
   for (index=0;index<total;index++)
    {
    // pos = _positionsHistory.Position(index); //�������� ��������� �� �������
     pos = _positionsHistory.At(index);
  //   Alert("<SYMBOL> ",pos.getSymbol());
     if (pos.getSymbol() == symbol) //���� ������ ������� ��������� � ���������� 
      {
       count++; //����������� ���������� ����������� ������� �� �������
      }
    }
    return count;
  }
//+------------------------------------------------------------------+
//| ��������� ����������  ������� �� �������                         |
//+------------------------------------------------------------------+
  uint BackTest::GetNSignTrades(string symbol,int sign) // (1) - ���������� ������ (-1) - ���������
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   uint count=0; //���������� ������� � ������ ��������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� �������
     if (pos.getSymbol() == symbol && pos.getPosProfit()*sign > 0) //���� ������ ������� ��������� � ���������� � ������ �������������
      {
       count++; //����������� ���������� ����������� ������� �� �������
      }
    }
    return count;
  }


//+------------------------------------------------------------------+
//| ���������� ���� ��������� �������                                |  
//+------------------------------------------------------------------+   
 int  BackTest::GetSignLastPosition(string symbol)
  {
   CPosition * pos;
   double profit;
   int index = _positionsHistory.Total()-1;
   
   while (index>=0)
    {
     pos = _positionsHistory.At(index);
     if (pos.getSymbol() == symbol)
      {
       profit = pos.getPosProfit();
       if (profit>0)
        return 1;
       if (profit<0)
        return -1;
       return 0;
      }
     index--;
    }
   return 2;
  }
    
//+------------------------------------------------------------------+
//| ���������� ����  ������� �� �������                              |  
//+------------------------------------------------------------------+   
 int  BackTest::GetSignPosition(string symbol,uint index)
  {
   CPosition * pos;
   uint ind = 0;
   uint pos_index=-1;
   double profit;
   uint total = _positionsHistory.Total();
   while (ind<total)
    {
     pos = _positionsHistory.Position(ind);
     if (pos.getSymbol() == symbol)
      {
      pos_index++;
      if (pos_index == index)
       {
        profit = pos.getPosProfit();
        if (profit>0)
         return 1;
        if (profit<0)
         return -1;
        return 0;
       }
      }
     ind++;
    }
   return 2;
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
//| ��������� ����� �������  ����� �� �������                        |
//+------------------------------------------------------------------+    

double BackTest::GetMaxTrade(string symbol,int sign) //sign = 1 - ����� ������� ����������, (-1) - ����� ������� ���������
 {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double maxTrade = 0;  //�������� ������������� ������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol && pos.getPosProfit()*sign > maxTrade)
      {
       maxTrade = pos.getPosProfit();
      }
    }  
    return maxTrade;
 }
 

 
//+------------------------------------------------------------------+
//| ��������� �������  �����                                         |
//+------------------------------------------------------------------+

double BackTest::GetAverageTrade(string symbol,int sign) // (1) - ������� ����������, (-1) - ������� ���������
 {
   uint index;
   uint total = _positionsHistory.Total();    //������ �������
   double tradeSum = 0;                       //����� ������� 
   uint count = 0;                            //���������� ����������� �������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol && pos.getPosProfit()*sign > 0) 
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
//| ��������� ����. ���������� ������ ������  �������                |
//+------------------------------------------------------------------+

 uint BackTest::GetMaxInARowTrades(string symbol,int sign) //sign 1 - ���������� ������, (-1) - ��������� ������ 
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   uint max_count = 0; //������������ ���������� ������ ������ �������
   uint count = 0;     //������� ���� �������
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol) //���� ������ ��������� 
      {
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

 double BackTest::GetMaxInARow(string symbol,int sign)  //sign: 1 - �� ����������, (-1) - �� ���������
  {
   uint index;
   uint total = _positionsHistory.Total();            //������ �������
   double tradeSum = 0;                               //��������� ���������� 
   double maxTrade = 0;                               //������������ ����������� �����
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index);         //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol)                   //���� ������ ��������� 
      {
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
    }   
            if (tradeSum*sign > maxTrade*sign)
             maxTrade = tradeSum;
    return maxTrade; 
  }  

  
//+-------------------------------------------------------------------+
//| ��������� ������������ �������� �� �������                        |
//+-------------------------------------------------------------------+  
double BackTest::GetMaxDrawdown (string symbol) //(������ ��� ����� ������ ������� - �������)
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
     if (pos.getSymbol() == symbol) //���� ������ ������ � ������������ ��������
      {
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
    }  
   return MaxDrawdown; //���������� ������������ �������� �� �������
 }
 
//+-------------------------------------------------------------------+
//| ���������� �������� ������                                        |
//+-------------------------------------------------------------------+

double BackTest::GetTotalProfit(string symbol)
 {
  return _balance;
 }  
 
//+-------------------------------------------------------------------+
//| ��������� ������������ � ����������� �������                      |
//+-------------------------------------------------------------------+

void  BackTest::GetBalances(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double balance  = 0;                     //������������ ������ �� ������� ������ (������ ���� ����� �������� ��������� ������)
   CPosition * pos;                         //��������� �� �������
                                            //�������� ������
   _max_balance = 0;
   _min_balance = 0;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol) //���� ������ ������ � ������������ ��������
      {
        balance = balance + pos.getPosProfit(); // ������������ ������
        if (balance > _max_balance)  
         _max_balance = balance;
        if (balance < _min_balance)
         _min_balance = balance;
      }
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
  WriteTo  (file_handle,DoubleToString(current_balance)+" ");    // ��������� ����������� ������  
  for (int index=0;index<total;index++)
   {
    // �������� ��������� �� �������
    pos = _positionsHistory.Position(index);
    current_balance = current_balance + pos.getPosProfit(); // ���������  ������ � ������ �����, ��������� � ������� ������� �� �������
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
//| ������� ������ �������                                            |
//+-------------------------------------------------------------------+ 

void BackTest::DeleteHistory(void)
 {
   // ������� ������
   _positionsHistory.Clear();
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
  //���������� ��� �������� ���������� ��������
  uint    n_trades           =  GetNTrades(symbol);            //���������� ������� 
  uint    n_win_trades       =  GetNSignTrades(symbol,1);      //���������� ���������� �������
  uint    n_lose_trades      =  GetNSignTrades(symbol,-1);     //���������� ���������� �������
  int     sign_last_pos      =  GetSignLastPosition(symbol);   //���� ��������� �������
  double  max_trade          =  GetMaxTrade(symbol,1);         //����� ������� ����� �� �������
  double  min_trade          =  GetMaxTrade(symbol,-1);        //����� ��������� ����� �� �������
  double  aver_profit_trade  =  GetAverageTrade(symbol,1);     //������� ���������� ����� 
  double  aver_lose_trade    =  GetAverageTrade(symbol,-1);    //������� ��������� �����   
  uint    maxPositiveTrades  =  GetMaxInARowTrades(symbol,1);  //������������ ���������� ������ ������ ������������� �������
  uint    maxNegativeTrades  =  GetMaxInARowTrades(symbol,-1); //������������ ���������� ������ ������ ������������� �������
  double  maxProfitRange     =  GetMaxInARow(symbol,1);        //������������ ������
  double  maxLoseRange       =  GetMaxInARow(symbol,-1);       //������������ ������
  double  maxDrawDown        =  GetMaxDrawdown(symbol);        //������������ ��������
  double  absDrawDown        =  0;                             //���������� ��������
  double  relDrawDown        =  0;                             //������������� �������� 
  
    Alert("��� ��� ��� ���� ������� = ",file_name);
  
  GetBalances(symbol);  // ��������� ������������ � ����������� ������
  
  //��������� � ���� ������ �� �������� , ���������� � ������
  WriteTo  (file_handle,_expertName+" ");                  // ��������� ��� ��������
  WriteTo  (file_handle,_symbol+" ");                      // ��������� ������
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
  WriteTo  (file_handle,DoubleToString(relDrawDown)+" ");   
  

                                         
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
 
 
   // ��������� ������ � ����
void BackTest::WriteTo(int handle, string buffer) 
{
  int    nBytesRead[1]={1};
  char   buff[]; 
  StringToCharArray(buffer,buff);
  if(handle>0) 
  {
    Comment(" ");
    WriteFile(handle, buff, StringLen(buffer), nBytesRead, NULL);
    
  } 
  else
   Print("�������. ������ ����� ��� ����� SPEAKER");
}