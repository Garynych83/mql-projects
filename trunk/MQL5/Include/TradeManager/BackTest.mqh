//+------------------------------------------------------------------+
//|                                                     BackTest.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include <TradeManager/TradeManagerEnums.mqh>
#include <TradeManager/PositionArray.mqh>
#define N_COLUMNS 17
//+------------------------------------------------------------------+
//| ����� ��� ������ � ���������                                     |
//+------------------------------------------------------------------+

class BackTest
 {
  private:
   CPositionArray _positionsHistory;        ///������ ������� ����������� �������
  public:
   //���� ��� ������� � ���������
   uint nTrades;                            //���������� �������
   uint nDeals;                             //���������� ������
   uint nWinTrades;            //���������� ���������� �������
   uint nLoseTrades;           //���������� ��������� �������
   double shortTradeWinPer;    //������� ���������� �������� ������ (�� ����������)
   double longTradeWinPer;     //������� ���������� ������� ������ (�� ����������)
   double profitTradesPer;     //������� ���������� ������� (�� ����)
   double loseTradesPer;       //������� ����������� ������� (�� ����)
   double maxWinTrade;         //����� ������� ���������� �����
   double maxLoseTrade;        //����� ������� ��������� �����
   double medWinTrade;         //������� ���������� �����
   double medLoseTrade;        //������� ������� �����
   uint maxWinTradesN;         //������������ ����� ����������� ���������
   uint maxLoseTradesN;        //������������ ����� ����������� ����������  
   double maxWinTradeSum;      //������������ ����������� �������
   double maxLoseTradeSum;     //������������ ����������� ������
  public:
   //������ ��������
   //������ ���������� �������� ������� � ������� �� �������
   uint GetNTrades(string symbol);     //��������� ���������� ������� �� �������
   uint GetNWinTrades(string symbol);  //��������� ���������� ���������� ������� �� �������
   uint GetNLoseTrades(string symbol); //��������� ���������� ��������� ������� �� �������
   //����� ������� �� �������
  private:
   int  GetSPosition(uint index);  //��������� ���� ������� 
  public:
   int  GetSignFirstPosition(string symbol); //��������� ���� ������ �������
   int  GetSignPosition(string symbol,uint index);      //��������� ���� ������� �� ������� 
   //������ ���������� ���������� �����������
   double GetIntegerPercent(uint value1,uint value2);  //����� ���������� ����������� ����������� value1 �� ���������  � value2
   double GetWinTradesPercent(string symbol,bool math=true);  //��������� ������� ���������� ������� � ������ �����
   double GetLoseTradesPercent(string symbol,bool math=true); //��������� ������� ��������� ������� � ������ ����� 
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
   bool LoadHistoryFromFile(string historyUrl);   //��������� ������� ������� �� �����
 };
//+------------------------------------------------------------------+
//| ��������� ���������� ������� �� �������                          |
//+------------------------------------------------------------------+
 uint BackTest::GetNTrades(string symbol)
  {
   uint index;
   uint total = _positionsHistory.Total();  //������ �������
   uint count=0; //���������� ������� � ������ ��������
   CPosition *pos;
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
   uint count=0; //���������� ������� � ������ ��������
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
   uint max = _positionsHistory.Total();
   while (index<total)
    {
     pos = _positionsHistory.Position(index);
     if (pos.getSymbol() == symbol)
      {
      pos_index++;
      }
     index--;
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
//| ��������� ���������� ����������� ���������� ������� � ������     |
//+------------------------------------------------------------------+

 double BackTest::GetWinTradesPercent(string symbol,bool math=true)
  {
   if (math == true)
    return GetIntegerPercent(GetNWinTrades(symbol),GetNTrades(symbol));
   return GetIntegerPercent(nWinTrades,nTrades);
  }  
  
//+------------------------------------------------------------------+
//| ��������� ���������� ����������� ��������� ������� � ������      |
//+------------------------------------------------------------------+

 double BackTest::GetLoseTradesPercent(string symbol,bool math=true)
  {
   if (math == true)
    return GetIntegerPercent(GetNLoseTrades(symbol),GetNTrades(symbol));
   return GetIntegerPercent(nLoseTrades,nTrades);
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
  
  
 bool BackTest::LoadHistoryFromFile(string historyUrl)   //��������� ������� ������� �� �����
 {
  int file_handle;   //�������� �����
  int ind;
  bool read_flag;  //���� ���������� ������ �� �����
  CPosition *pos;  

     if (!FileIsExist(historyUrl,FILE_COMMON) ) //�������� ������������� ����� ������� 
      return false;   
   file_handle = FileOpen(historyUrl, FILE_READ|FILE_COMMON|FILE_CSV|FILE_ANSI, ";");
   if (file_handle == INVALID_HANDLE) //�� ������� ������� ����
    return false;
   _positionsHistory.Clear(); //������� ������ ������� �������
   for(ind=0;ind<N_COLUMNS;ind++) //N_COLUMNS - ���������� �������� 
    {
     FileReadString(file_handle);  //������� ������ ������ �������
    } 
   read_flag = true;      //��� ������� ���� ������ �� ������ ���������� �������

   while (read_flag)
    {
     pos = new CPosition(0,"",OP_UNKNOWN,0);    //�������� ������ ��� ����� ������� 
     read_flag = pos.ReadFromFile(file_handle); //��������� ������ ��� ����� �������
     if (read_flag)                             //���� ������� ������� ������ 
      _positionsHistory.Add(pos);               //�� ��������� ������� � ������ ������� 
    }   
   FileClose(file_handle);  //��������� ���� ������� ������� 
  return true;
 }