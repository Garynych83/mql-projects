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
//| ��������� ������                                                 |
//+------------------------------------------------------------------+
   //---- ���������� �������� ������� ������ 
   double   GetTan(bool trend_type);
   //---- ���������� �������� ����� ������ �� ��������� ����
   double   GetLineY (bool trend_type,uint n_bar);
   //---- ��������� ����������
   
   //---- ��������� �������� ����������
   void     SetExtrem(uint n_bar,double price);
   
  };
  
//+------------------------------------------------------------------+
//| ��������� ������                                                 |
//+------------------------------------------------------------------+

   double  CKatana::GetTan(bool trend_type)
   //��������� �������� �������� ������� �����
    {
     //���� ����� ��������� ������� ������� ������ ����� (������ �����)
     if (trend_type == true)
      return ( right_extr_up.price - left_extr_up.price ) / ( right_extr_up.n_bar - left_extr_up.n_bar );
     //���� ����� ��������� ������� ������� ������ ���� (������� �����)
     return ( right_extr_down.price - left_extr_down.price ) / ( right_extr_down.n_bar - left_extr_down.n_bar );   
    } 
 
   double  CKatana::GetLineY (bool trend_type,uint n_bar)
   //���������� �������� Y ����� ������� �����
   {
   //���� ����� ��������� �������� ����� �� ����� ������ �����
    if (trend_type == true)
     return (left_extr_up.price + (n_bar-left_extr_up.n_bar)*tg_up);
   //���� ����� ��������� �������� ����� �� ����� ������ ����
    return (right_extr_down.price + (n_bar-right_extr_down.n_bar)*tg_down);
   }
   
   void   CKatana::SetExtrem(uint n_bar,double price)
   //��������� �������� ����������
    {
    
    }