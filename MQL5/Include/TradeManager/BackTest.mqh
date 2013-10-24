//+------------------------------------------------------------------+
//|                                                     BackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <TradeManager/TradeManagerEnums.mqh>
#include <TradeManager/PositionArray.mqh>

//+------------------------------------------------------------------+
//| ����� ��� ������ � ���������                                     |
//+------------------------------------------------------------------+

class BackTest
 {
  private:
   CPositionArray *_positionsHistory;        ///������ ������� ����������� �������

  public:
   //�����������
   BackTest() { _positionsHistory = new CPositionArray(); };                             //����������� ������
  ~BackTest() { delete _positionsHistory; };
   //������ ��������
   //������ ���������� �������� ������� � ������� �� �������
   uint   GetNTrades(string symbol);     //��������� ���������� ������� �� �������
   uint   GetNWinTrades(string symbol);  //��������� ���������� ���������� ������� �� �������
   uint   GetNLoseTrades(string symbol); //��������� ���������� ��������� ������� �� �������
   //����� ������� �� �������
  private:
   int    GetSPosition(uint index);  //��������� ���� ������� 
  public:
   int    GetSignLastPosition(string symbol);  //���������� ���� ��������� ������� 
   int    GetSignPosition(string symbol,uint index);      //��������� ���� ������� �� ������� 
   //����� ���������� ���������� �����������
   double GetIntegerPercent(uint value1,uint value2);  //����� ���������� ����������� ����������� value1 �� ���������  � value2
   //������ ���������� ������������ � ������� �������
   double GetMaxWinTrade(string symbol);  //��������� ����� ������� ���������� ����� �� �������
   double GetMaxLoseTrade(string symbol); //��������� ����� ������� ��������� ����� �� �������
   double GetMedWinTrade(string symbol);  //��������� ������� ���������� �����
   double GetMedLoseTrade(string symbol);  //��������� ������� ��������� �����   
   //������ ���������� ��������� ������ ������ �������
   uint   GetMaxInARowWinTrades(string symbol);  //��������� ������������ ���������� ������ ������ ���������� ������� �� ��������� �������
   uint   GetMaxInARowLoseTrades(string symbol);  //��������� ������������ ���������� ������ ������ ��������� ������� �� ��������� �������   
   //������ ���������� ������������ ����������� ������� � ������
   double GetMaxinARowProfit(string symbol);   //��������� ������������ ����������� ������� 
   double GetMaxinARowLose(string symbol);     //��������� ������������ ����������� ������    
   //������ ���������� �������� �������
   double GetAbsDrawdown (string symbol);      //��������� ���������� �������� �������
   double GetRelDrawdown (string symbol);      //��������� ������������� �������� �������
   double GetMaxDrawdown (string symbol);      //��������� ������������ �������� �������
   //������ ��������� ������
   bool LoadHistoryFromFile(string file_url);   //��������� ������� ������� �� �����
   void GetHistoryExtra(CPositionArray *array); //�������� ������� ������� �����
   bool SaveBackTestToFile (string file_url);   //��������� ���������� ��������
   
 };
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
     pos = _positionsHistory.Position(index); //�������� ��������� �� �������
     if (pos.getSymbol() == symbol) //���� ������ ������� ��������� � ���������� 
      {
       count++; //����������� ���������� ����������� ������� �� �������
      }
    }
    return count;
  }
//+------------------------------------------------------------------+
//| ��������� ���������� ���������� ������� �� �������               |
//+------------------------------------------------------------------+
  uint BackTest::GetNWinTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   uint count=0; //���������� ������� � ������ ��������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� �������
     if (pos.getSymbol() == symbol && pos.getPosProfit() > 0) //���� ������ ������� ��������� � ���������� � ������ �������������
      {
       count++; //����������� ���������� ����������� ������� �� �������
      }
    }
    return count;
  }
//+------------------------------------------------------------------+
//| ��������� ���������� ��������� ������� �� �������                |
//+------------------------------------------------------------------+
  uint BackTest::GetNLoseTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   uint count = 0; //���������� ������� � ������ ��������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� �������
     if (pos.getSymbol() == symbol && pos.getPosProfit() < 0) //���� ������ ������� ��������� � ���������� � ������ �������������
      {
      count++; //����������� ���������� ����������� ������� �� �������
      }
    }
    return count;
  }  
//+------------------------------------------------------------------+
//| ���������� ���� �������                                          |  // ����������
//+------------------------------------------------------------------+  
 int BackTest::GetSPosition(uint index) 
  {
    CPosition * pos;
    double profit;
    pos = _positionsHistory.Position(index);  //�������� ��������� �� �������
    profit = pos.getPosProfit();  //�������� ������ �������
    if (profit > 0) //���� ������ �������������
     return 1;
    else if (profit < 0) //���� ������ �������������
     return -1;
    return 0;  //���� ������� ���
  }  
//+------------------------------------------------------------------+
//| ���������� ���� ��������� �������                                |  //����������
//+------------------------------------------------------------------+   
 int  BackTest::GetSignLastPosition(string symbol)
  {
   CPosition * pos;
   uint index = _positionsHistory.Total()-1;
   while (index>0)
    {
     pos = _positionsHistory.Position(index);
     if (pos.getSymbol() == symbol)
      return index;
     index--;
    }
   return 0;
  }
    
//+------------------------------------------------------------------+
//| ���������� ����  ������� �� �������                              |   //�������� � ����������
//+------------------------------------------------------------------+   
 int  BackTest::GetSignPosition(string symbol,uint index)
  {
   CPosition * pos;
   uint index = 0;
   uint pos_index=0;
   uint total = _positionsHistory.Total();
   while (index<total)
    {
     pos = _positionsHistory.Position(index);
     if (pos.getSymbol() == symbol)
      {
      pos_index++;
      }
     index++;
    }
   return 0;
  }
//+------------------------------------------------------------------+
//| ��������� ���������� ����������� value1 � value2                 |
//+------------------------------------------------------------------+  

 double BackTest::GetIntegerPercent(uint value1,uint value2)
  {
   return 1.0*value1/value2;
  }

//+------------------------------------------------------------------+
//| ��������� ����� ������� ���������� ����� �� �������              |
//+------------------------------------------------------------------+    

double BackTest::GetMaxWinTrade(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double maxTrade = 0;  //�������� ������������� ������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol && pos.getPosProfit() > maxTrade)
      {
       maxTrade = pos.getPosProfit();
      }
    }  
    return maxTrade;
 }
 
//+------------------------------------------------------------------+
//| ��������� ����� ������� ��������� ����� �� �������               |
//+------------------------------------------------------------------+    

double BackTest::GetMaxLoseTrade(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double minTrade = 0;  //�������� ������������� ������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol && pos.getPosProfit() < minTrade)
      {
       minTrade = pos.getPosProfit();
      }
    }  
    return minTrade;
 } 
 
//+------------------------------------------------------------------+
//| ��������� ������� ���������� �����                               |
//+------------------------------------------------------------------+

double BackTest::GetMedWinTrade(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double tradeSum = 0;  //����� ������� 
   uint count = 0;       //���������� ����������� �������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol && pos.getPosProfit() > 0) //���� ������ ��������� � ������ �������������
      {
       count++; //����������� ������� ������� �� �������
       tradeSum = tradeSum + pos.getPosProfit(); //� ����� ����� ���������� �����
      }
    }  
   return tradeSum/count; //���������� �������
 }   
 
//+------------------------------------------------------------------+
//| ��������� ������� ��������� �����                                |
//+------------------------------------------------------------------+

double BackTest::GetMedLoseTrade(string symbol)
 {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double tradeSum = 0;  //����� ������� 
   uint count = 0;       //���������� ����������� �������
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol && pos.getPosProfit() < 0) //���� ������ ��������� � ������ �������������
      {
       count++; //����������� ������� ������� �� �������
       tradeSum = tradeSum + pos.getPosProfit(); //� ����� ����� ���������� �����
      }
    }  
   return tradeSum/count; //���������� �������
 }    
 
//+------------------------------------------------------------------+
//| ��������� ����. ���������� ������ ������ ���������� �������      |
//+------------------------------------------------------------------+

 uint BackTest::GetMaxInARowWinTrades(string symbol)
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
        if (pos.getPosProfit() > 0) //���� ������ �������������
         {
           count++; //����������� ����������
         }
        else
         {
          if (count>0)  //���� ���������� ������� ����������
           {
            if (count > max_count) //���� ������� ���������� ������ �����������
             {
              max_count = count; //�������� �������
             }
            count = 0;  //�������� �������
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
//| ��������� ����. ���������� ������ ������ ��������� �������       |
//+------------------------------------------------------------------+

 uint BackTest::GetMaxInARowLoseTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   uint max_count = 0; //������������ ���������� ������ ������ �������
   uint count = 0;         //������� ���� �������
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol) //���� ������ ��������� 
      {
        if (pos.getPosProfit() < 0) //���� ������ �������������
         {
           count++; //����������� ����������
         }
        else
         {
          if (count>0)  //���� ���������� ������� ����������
           {
            if (count > max_count) //���� ������� ���������� ������ �����������
             {
              max_count = count; //�������� �������
             }
            count = 0;  //�������� �������
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
//| ��������� ������������ ����������� �������                       |
//+------------------------------------------------------------------+

 double BackTest::GetMaxinARowProfit(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double tradeSum = 0;            //��������� ���������� 
   double maxTrade = 0;        //������������ ����������� �����
   CPosition *pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol) //���� ������ ��������� 
      {
        if (pos.getPosProfit() > 0) //���� ������ �������������
         {
           tradeSum = tradeSum + pos.getPosProfit();  //���������� ������ �������
         }
        else
         {
          if (tradeSum>0)  //���� ���������� ������� ����������
           {
            if (tradeSum > maxTrade) //���� ������� ������� ������ ����������
             {
              maxTrade = tradeSum; //�������� �������
             }
            tradeSum = 0;
           }
         }
      }
    }   
            if (tradeSum > maxTrade)
             maxTrade = tradeSum;
    return maxTrade; 
  }  
//+-------------------------------------------------------------------+
//| ��������� ������������ ����������� ������                         |
//+-------------------------------------------------------------------+

 double BackTest::GetMaxinARowLose(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   double tradeSum = 0;            //��������� ���������� 
   double maxTrade = 0;        //������������ ����������� �����
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol) //���� ������ ��������� 
      {
        if (pos.getPosProfit() < 0) //���� ������ �������������
         {
           tradeSum = tradeSum + pos.getPosProfit();  //���������� ������ �������
         }
        else
         {
          if (tradeSum>0)  //���� ���������� ������� ����������
           {
            if (tradeSum < maxTrade) //���� ������� ������� ������ ����������
             {
              maxTrade = tradeSum; //�������� �������
             }
            tradeSum = 0;
           }
         }
      }
    }  
            if (tradeSum < maxTrade)
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
   double balance = 0;          //������ ������� 
  
   CPosition * pos;
   for (index=0;index<total;index++)
    {
     pos = _positionsHistory.Position(index); //�������� ��������� �� ������� 
     if (pos.getSymbol() == symbol) //���� ������ ������ � ������������ ��������
      {
       balance = balance + pos.getPosProfit(); //������������� ������� ������
       if (balance > MaxBalance)  //���� ������ �������� ������� ������������ ������, �� �������������� ���
        {
          MaxBalance = balance;
        }
       else 
        {
         if ((MaxBalance-balance) > MaxDrawdown) //���� ���������� ������ ��������, ��� ����
          {
            MaxDrawdown = MaxBalance-balance;  //�� ���������� ����� �������� �������
          }
        }
      }
    }  
   return MaxDrawdown; //���������� ������������ �������� �� �������
 }
  
//+-------------------------------------------------------------------+
//| ��������� ������� ������� �� �����                                |
//+-------------------------------------------------------------------+   
  
bool BackTest::LoadHistoryFromFile(string file_url)
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
 file_handle = FileOpen(file_url, FILE_READ|FILE_COMMON|FILE_CSV|FILE_ANSI, ";");
 if (file_handle == INVALID_HANDLE) //�� ������� ������� ����
 {
  PrintFormat("%s error: %s opening %s", MakeFunctionPrefix(__FUNCTION__), ErrorDescription(::GetLastError()), file_url);
  return (false);
 }
 _positionsHistory.Clear();                   //������� ������
 _positionsHistory.ReadFromFile(file_handle); //��������� ������ �� ����� 
 FileClose(file_handle);          //��������� ����  
 return (true);
 }  
 
//+-------------------------------------------------------------------+
//| �������� ������� ������� �����                                    |
//+-------------------------------------------------------------------+

void BackTest::GetHistoryExtra(CPositionArray *array)
 {
  CPosition * pos;
  _positionsHistory = array;
  if (_positionsHistory.Total()) 
   {
  pos = array.At(0);
  Alert("������� ������� = ",DoubleToString(pos.getPosProfit()));  
   }
 } 
 
//+-------------------------------------------------------------------+
//| ��������� ���������� �������� � ����                              |
//+-------------------------------------------------------------------+

bool BackTest::SaveBackTestToFile(string file_url)
 {
uint   NTrades;      //���������� �������
uint   NWinTrades;   //���������� ���������� ������
uint   NLoseTrades;  //���������� ��������� ������
int    SignLastPosition; //���� ��������� �������
int    SignPosition;     //���� ������� �� �������
double WinTradesPercent;  //������� ���������� ������� � ������ �����
double LoseTradesPercent; //������� ��������� ������� � ������ �����
double MaxWinTrade;  //����� ������� ���������� ����� �� �������
double MaxLoseTrade; //����� ������� ��������� ����� �� �������
double MedWinTrade;  //������� ���������� �����
double MedLoseTrade; //������� ��������� �����
uint   MaxInARowWinTrades; //��������� ������������ 
uint   MaxInARowLoseTrades;
double MaxInARowProfit;
double MaxInARowLose;
double MaxDrawdown;
 
NTrades             = GetNTrades(_Symbol);      //���������� �������
//NWinTrades          = GetNWinTrades(_Symbol);   //���������� ���������� ������
//NLoseTrades         = GetNLoseTrades(_Symbol);  //���������� ��������� ������
//SignLastPosition    = GetSignLastPosition(_Symbol); //���� ��������� �������
//SignPosition        = GetSignPosition(_Symbol,2);     //���� ������� �� �������
//WinTradesPercent    = GetIntegerPercent(NWinTrades,NTrades);  //������� ���������� ������� � ������ �����
//LoseTradesPercent   = GetIntegerPercent(NLoseTrades,NTrades); //������� ��������� ������� � ������ �����
//MaxWinTrade         = GetMaxWinTrade(_Symbol);  //����� ������� ���������� ����� �� �������
//MaxLoseTrade        = GetMaxLoseTrade(_Symbol); //����� ������� ��������� ����� �� �������
//MedWinTrade         = GetMedWinTrade(_Symbol);  //������� ���������� �����
//MedLoseTrade        = GetMedLoseTrade(_Symbol); //������� ��������� �����
//MaxInARowWinTrades  = GetMaxInARowWinTrades(_Symbol); //��������� ������������ 
//MaxInARowLoseTrades = GetMaxInARowLoseTrades(_Symbol);
//MaxInARowProfit     = GetMaxinARowProfit(_Symbol);
//MaxInARowLose       = GetMaxinARowLose(_Symbol);
//MaxDrawdown         = GetMaxDrawdown(_Symbol);
 
 int file_handle = FileOpen(file_url, FILE_WRITE|FILE_CSV|FILE_COMMON, ";");
 if(file_handle == INVALID_HANDLE)
 {
  log_file.Write(LOG_DEBUG, StringFormat("%s �� ���������� ������� ����: %s", MakeFunctionPrefix(__FUNCTION__), file_url));
  return(false);
 }
 FileWrite(file_handle,"���������� ������� = "+IntegerToString(NTrades));
 FileWrite(file_handle,"���������� ���������� ������� = "+IntegerToString(NWinTrades));
 FileWrite(file_handle,"���������� ��������� ������� = "+IntegerToString(NLoseTrades));
 FileWrite(file_handle,"���� ��������� ������� = "+IntegerToString(SignLastPosition));
 FileWrite(file_handle,"���� ������ ������� = "+IntegerToString(SignPosition ));
 FileWrite(file_handle,"������� ���������� ������� = "+DoubleToString(WinTradesPercent));
 FileWrite(file_handle,"������� ��������� ������� = "+DoubleToString(LoseTradesPercent));
 FileWrite(file_handle,"������������ ���������� ����� = "    +DoubleToString(MaxWinTrade ));
 FileWrite(file_handle,"������������ ��������� ����� = "     +DoubleToString(MaxLoseTrade));  
 FileWrite(file_handle,"������������ ��������� ����� = "     +DoubleToString(MaxLoseTrade));  
 FileWrite(file_handle,"�������� ������ ������ ���������� = "+IntegerToString(MaxInARowWinTrades));  
 FileWrite(file_handle,"�������� ������ ������ ���������� = "+IntegerToString(MaxInARowLoseTrades));  
 FileWrite(file_handle,"�������������� ����������� ������ = " +DoubleToString(MaxInARowProfit));   
 FileWrite(file_handle,"������������ ����������� ������ = " +DoubleToString(MaxInARowLose));    
 FileWrite(file_handle,"������������ �������� �� ������� = " +DoubleToString(MaxDrawdown));    
     
 FileClose(file_handle);
  return(true);  
 }
 
