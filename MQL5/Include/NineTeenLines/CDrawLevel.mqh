//+------------------------------------------------------------------+
//|                                                   CDrawLevel.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
// ���������� ����������� ����������
#include <ExtrLine\HLine.mqh>
// ����� ��������� ����� ������
class CDrawLevel 
 {
  private:
   // ������ �������
   double _levelPrices[];   // ����� ��� �������
   double _levelATR[];      // ����� ������ ������� �������
   color  _levelColor[];    // ����� ������ �������
   string _levelNames[];    // ����� ���� �������
   // ��������� ��������� ������ �������
   int    _levelCount;      // ���������� ������� 
   long   _chart_ID;        // id �������
   int    _sub_window;      // ����� �������
   bool   _back;   
   // ��������� ������ ������  
   int    GetIndexByName(string name);                                 // ����� ���������� ������ ������ � ������ �� �����        
  public:
   // ������ ��������� �������
   bool SetLevel (string name,double price,double atr,color clr);      // ����� ��������� ����������� ����������� ������
   bool MoveLevel (int index,double price);                            // ���������� �������� �� ������� �� �������� ����
   bool MoveLevel (string name,double price);                          // ���������� ������� �� ����� ������
   bool DeleteLevel (int index);                                       // ������� ������� �� �������
   bool DeleteLevel (string name);                                     // ������� ������� �� ����� ������
   bool ChangeLevel (int index,double atr);                            // �������� ������ ������ �� �������
   bool ChangeLevel (int index,color clr);                             // �������� ���� ������ �� �������       
   bool ChangeLevel (string name, double atr);                         // �������� ������ ������ �� �����
   bool ChangeColor (string name, color clr);                          // �������� ���� ������ �� �����  
   void DeleteAll   ();                                                // ������� ��� ������      
   CDrawLevel    (const long            chart_ID=0,                    // ID �������
                  const int             sub_window=0,                  // ����� �������
                  const bool            back=true                      // �� ������ �����
               );                                                      // ����������� ������ ��������� �������
  ~CDrawLevel ();                                                      // ���������� ������ ��������� �������
 };
 
 // ����������� ������� ������
 
 ////// ��������� ������ ������
 
 // ����� ���������� ������ ������ � ������  �� �����
 int CDrawLevel::GetIndexByName(string name)
  {
   // �������� �� ������ � ���� ������� � �������� �������
   for (int ind=0;ind<_levelCount;ind++)
    {
     //���� ����� ������� �� ��������� �����, �� ���������� ������ ������� ������
     if (_levelNames[ind] == name)
      return (ind);
    }
   return (-1); // �� ����� �������
  }
 
 ////// ��������� ������ ������ 
 
 // ����� ���������� ������������ ����������� ������
 bool CDrawLevel::SetLevel(string name,double price,double atr,color clr)
  {
   // ���� ������� ���������� �����
   if ( HLineCreate(_chart_ID,name,_sub_window,price,clr,1,STYLE_DASHDOT,_back) &&
        HLineCreate(_chart_ID,name+"+",_sub_window,price+atr,clr,1,STYLE_SOLID,_back) &&
        HLineCreate(_chart_ID,name+"-",_sub_window,price-atr,clr,1,STYLE_SOLID,_back)   
        )
        {
         ArrayResize(_levelPrices,_levelCount+1);
         ArrayResize(_levelColor,_levelCount+1);
         ArrayResize(_levelATR,_levelCount+1);   
         ArrayResize(_levelNames,_levelCount+1);
         _levelPrices[_levelCount] = price; // ��������� ���� ������
         _levelATR[_levelCount]    = atr;   // ��������� ������ ������
         _levelColor[_levelCount]  = clr;   // ��������� ���� �����
         _levelNames[_levelCount]  = name;  // ��������� ��� ������
         _levelCount ++;                    // ����������� ���������� �������
         return (true);
        }
   return (false);
  }
  
 // ����� ���������� ������� �� ������� �� �������� ����
 bool CDrawLevel::MoveLevel(int index,double price)
  {
   // ���� ��������� ����� ������ ������
   if (index >= 0 && index < _levelCount)
    {
      if ( HLineMove(_chart_ID,_levelNames[index],price)  &&
           HLineMove(_chart_ID,_levelNames[index]+"+",price+_levelATR[index])  &&
           HLineMove(_chart_ID,_levelNames[index]+"-",price-_levelATR[index]) 
         ) 
          {  
           _levelPrices[index] = price;
           return (true);
          }
    }
   return (false);
  }
  
 // ����� ���������� ������� �� ����� �� �������� ����
 bool CDrawLevel::MoveLevel(string name,double price)
  {
   // �������� ������ ������ �� ����� ������
   int ind = GetIndexByName(name);
   // ���� ������ ������� �����
   if (ind > -1)
    { 
     // �� ���������� ������� �� ������� 
     return (MoveLevel(ind,price));
    }
   return (false);
  }
 
 // ������� ������� �� �������
 bool CDrawLevel::DeleteLevel(int index)
  {
   // ���� ��������� ����� ������ ������
   if (index >=0 && index < _levelCount)
    {
     // ���� ������� ������� ����������� �������
     if ( HLineDelete(_chart_ID, _levelNames[index]) &&
          HLineDelete(_chart_ID, _levelNames[index]+"+") &&
          HLineDelete(_chart_ID, _levelNames[index]+"-")
        )
         {
          // ������� ������ �� ���� ������� �����
          for (int ind=index+1;ind<_levelCount;ind++)
           {

            _levelATR    [ind-1]  = _levelATR    [ind];
            _levelColor  [ind-1]  = _levelColor  [ind];
            _levelPrices [ind-1]  = _levelPrices [ind]; 
            _levelNames  [ind-1]  = _levelNames  [ind];
           }
          _levelCount--;  // ��������� ���������� ������� �� �������
          // �������� ������� ��������
          ArrayResize(_levelATR,_levelCount);
          ArrayResize(_levelColor,_levelCount);
          ArrayResize(_levelNames,_levelCount);
          ArrayResize(_levelPrices,_levelCount);
          return (true);
         }
     }
   return (false);
  }
 
 // ������� ������� �� ����� ������
 bool CDrawLevel::DeleteLevel(string name)
  {
   // �������� ������ ������ �� ����� ������
   int ind = GetIndexByName(name);
   // ���� ������ ������� �����
   if (ind > -1)
    { 
     // �� ������� ������� �� �������
     return (DeleteLevel(ind));
    }
   return (false);  
  }
  
 // �������� ������ ������ �� �������
 bool CDrawLevel::ChangeLevel(int index,double atr)
  {
   // ���� ���������� ������ ������ � ������
   if (index >=0 && index < _levelCount)
    {
     _levelATR[index] = atr;
     HLineMove(_chart_ID,_levelNames[index]+"+",_levelPrices[index]+atr);  
     HLineMove(_chart_ID,_levelNames[index]+"-",_levelPrices[index]-atr); 
     return (true);        
    }
   return (false);
  }
  
 // ������� ��� ������
 void CDrawLevel::DeleteAll(void)
  {
   // �������� �� ����� � ������� ��� ������
   for (int ind=0;ind<_levelCount;ind++)
    {
     HLineDelete(_chart_ID,_levelNames[ind]);
     HLineDelete(_chart_ID,_levelNames[ind]+"+");
     HLineDelete(_chart_ID,_levelNames[ind]+"-");
    }
    ArrayResize(_levelATR,0);
    ArrayResize(_levelColor,0);
    ArrayResize(_levelNames,0);
    ArrayResize(_levelPrices,0);
    _levelCount = 0;
  } 
  
 // �������� ������ ������ �� ����� ������
 bool CDrawLevel::ChangeLevel(string name,double atr)
  {
   // �������� ������ ������ �� ����� ������
   int ind = GetIndexByName(name);
   // ���� ������ ������� �����
   if (ind > -1)
    { 
     // �� �������� ������ ������ �� �������
     ChangeLevel(ind,atr);
    }
   return (false);    
  }
 
 // ����������� ������
 CDrawLevel::CDrawLevel(const long chart_ID=0,const int sub_window=0,const bool back=true)
  {
   _levelCount = 0;
  }
 
 // ���������� ������
 CDrawLevel::~CDrawLevel(void)
  {
   // ����������� ������ �������
   ArrayFree (_levelATR);
   ArrayFree (_levelColor);
   ArrayFree (_levelPrices);
  }