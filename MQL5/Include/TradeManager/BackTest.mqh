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
   BackTest() { _positionsHistory = new CPositionArray(); };  //����������� ������
  ~BackTest() { delete _positionsHistory; };
   //������ ��������
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
   //������ ��������� ������
   bool LoadHistoryFromFile(string file_url);          //��������� ������� ������� �� �����
   void GetHistoryExtra(CPositionArray *array);        //�������� ������� ������� �����
   bool SaveBackTestToFile (string file_url);          //��������� ���������� ��������
   
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
  _positionsHistory = array;
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
NWinTrades          = GetNSignTrades(_Symbol,1);   //���������� ���������� ������
NLoseTrades         = GetNSignTrades(_Symbol,-1);  //���������� ��������� ������
SignLastPosition    = GetSignLastPosition(_Symbol); //���� ��������� �������
SignPosition        = GetSignPosition(_Symbol,2);     //���� ������� �� �������
WinTradesPercent    = GetIntegerPercent(NWinTrades,NTrades);  //������� ���������� ������� � ������ �����
LoseTradesPercent   = GetIntegerPercent(NLoseTrades,NTrades); //������� ��������� ������� � ������ �����
MaxWinTrade         = GetMaxTrade(_Symbol,1);  //����� ������� ���������� ����� �� �������
MaxLoseTrade        = GetMaxTrade(_Symbol,-1); //����� ������� ��������� ����� �� �������
MedWinTrade         = GetAverageTrade(_Symbol,1);  //������� ���������� �����
MedLoseTrade        = GetAverageTrade(_Symbol,-1); //������� ��������� �����
MaxInARowWinTrades  = GetMaxInARowTrades(_Symbol,1); //��������� ������������ 
MaxInARowLoseTrades = GetMaxInARowTrades(_Symbol,-1);
MaxInARowProfit     = GetMaxInARow(_Symbol,1);
MaxInARowLose       = GetMaxInARow(_Symbol,-1);
MaxDrawdown         = GetMaxDrawdown(_Symbol);
 
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
 
