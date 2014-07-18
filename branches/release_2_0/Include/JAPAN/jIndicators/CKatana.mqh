//+------------------------------------------------------------------+
//|                                                      CKatana.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
//+------------------------------------------------------------------+
//| ����� ���������� KATANA                                          |
//+------------------------------------------------------------------+

//---- ��������� ����������� 
 struct Extrem
  {
   uint   n_bar;             //����� ���� 
   double price;             //������� ��������� ����������
  };
  
 class CKatana
  {
   private:
    //---- ������� ���
    double _high[];
    double _low[];
    //---- ������� ��� ��� ������ �����������
    double _priceDifference;
    //---- �������� ���� ������� ����� ������
    double _tg_up; 
    double _tg_down;
   public:
    //---- ����� ����������
    Extrem _left_extr_up;         //����� ��������� ������ ����� (������ �����)
    Extrem _right_extr_up;        //������ ��������� ������ ����� (������ �����)
    Extrem _left_extr_down;       //����� ��������� ������ ���� (������� �����)
    Extrem _right_extr_down;      //������ ��������� ������ ���� (������� �����)
    //---- 
    
   public:
   
//+------------------------------------------------------------------+
//| ����������� � ����������                                         |
//+------------------------------------------------------------------+

   CKatana (double &high[],double &low[]):
   _high(high),
   _low(low) 
   //����������� ������
     {
     
     }
   ~CKatana ()
   //���������� ������
     {
      //������� ������ ��� ������������ �������
      ArrayFree(_high);
      ArrayFree(_low);
     }
   private:
   
//+------------------------------------------------------------------+
//| ��������� ������                                                 |
//+------------------------------------------------------------------+
  //---- ��������� ������� ����� ������ 
  void   GetPriceDifferences(bool trend_type);
   
//+------------------------------------------------------------------+
//| ��������� ������                                                 |
//+------------------------------------------------------------------+
   //---- ���������� �������� ������� ������ 
   double   GetTan(bool trend_type);
   //---- ���������� �������� ����� ������ �� ��������� ����
   double   GetLineY (bool trend_type,uint n_bar);
   //---- ��������� ����������
   void     GetExtrem();
   //---- ��������� �������� ����������
   void     SetExtrem(uint extr_type,uint n_bar,double price);
   
  };
  
//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+  

   void CKatana::GetPriceDifferences(bool trend_type)
   //���������� ������ ���
    {
     switch (trend_type)
      {
       //---- ����� ����� (������ �����)
       case 0:  
        priceDiff_left  = low[index+1]-low[index];
        priceDiff_right = low[index-1]-low[index]; 
       break;
       //---- ����� ���� (������� �����)
       case 1:
        priceDiff_left  = high[index]-high[index+1];
        priceDiff_right = high[index]-high[index-1];
       break;
      }
    }
  
//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+

   double  CKatana::GetTan(bool trend_type)
   //��������� �������� �������� ������� �����
    {
     //���� ����� ��������� ������� ������� ������ ����� (������ �����)
     if (trend_type == true)
      return ( _right_extr_up.price - _left_extr_up.price ) / ( _right_extr_up.n_bar - _left_extr_up.n_bar );
     //���� ����� ��������� ������� ������� ������ ���� (������� �����)
     return ( _right_extr_down.price - _left_extr_down.price ) / ( _right_extr_down.n_bar - _left_extr_down.n_bar );   
    } 
 
   double  CKatana::GetLineY (bool trend_type,uint n_bar)
   //���������� �������� Y ����� ������� �����
   {
   //���� ����� ��������� �������� ����� �� ����� ������ �����
    if (trend_type == true)
     return (_left_extr_up.price + (n_bar-_left_extr_up.n_bar)*_tg_up);
   //���� ����� ��������� �������� ����� �� ����� ������ ����
    return (_right_extr_down.price + (n_bar-_right_extr_down.n_bar)*_tg_down);
   }
   
   void   CKatana::GetExtrem()
   //��������� ����������
    {
      
    }
   
   void   CKatana::SetExtrem(uint extr_type,uint n_bar,double price)
   //��������� �������� ����������
    {
      switch (extr_type)
       {
        case 0:
         _left_extr_down.n_bar = n_bar;
         _left_extr_down.price = price;
        break;
        case 1:
         _right_extr_down.n_bar = n_bar;
         _right_extr_down.price = price;        
        break;
        case 2:
         _left_extr_up.n_bar = n_bar;
         _left_extr_up.price = price;        
        break;
        case 3:
         _right_extr_up.n_bar = n_bar;
         _right_extr_up.price = price;        
        break;
       }
    }