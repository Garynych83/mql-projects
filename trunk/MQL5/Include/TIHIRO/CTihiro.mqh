//+------------------------------------------------------------------+
//|                                                      CTihiro.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Extrem.mqh" 
//+------------------------------------------------------------------+
//| ����� ��� �������� TIHIRO                                        |
//+------------------------------------------------------------------+

class CTihiro 
 {
    //��������� ���� ������
   private:
    //���������� ����� �������
    uint   _bars;  
    //������� ����� ������
    double _tg;
    //���������� �� ����� ������ �� ���������� ����������
    double _range;
    //����������
    Extrem extr_past,extr_present,extr_last;
    //��������� ������ ������
   private:
    //�������� �������� �������� ���� ������� ����� ������   
    double GetTan(Extrem * ext_past,Extrem * ext_present);  
    //���������� ���������� �� ���������� �� ����� ������
    double GetRange(Extrem * ext_past,Extrem * ext_present,double tg);
    //���������, ���� ��� ���� ����� ������ ��������� ������� �����
    int   TestPointLocate(Extrem * ext_past,Extrem * cur_point,double tg);
    
   public:
   //����������� ������ 
   CTihiro(uint bars):
     _bars(bars)
    {
    }; 
   //�������� �� �������� ��������� �� ������� ������������ � ����������� ��� �����
   //� ��������� ��� ����������� �������� �� ���
   //� ������ - ����������, ������� ��������� �����, ���������� �� ����� ������ �� ���������� ���������� 
   void OnNewBar(double  &price_max[],double  &price_min[]);
 };

//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+

double CTihiro::GetTan(Extrem *ext1,Extrem *ext2) 
//�������� �������� �������� ���� ������� ����� ������
 {
  return (ext2.price-ext1.price)/(ext2.time - ext1.time);
 }
 
double CTihiro::GetRange(Extrem *ext_past,Extrem *ext_present,double tg)
//���������� ���������� �� ���������� �� ����� ������
 {
  double L=ext_present.time-ext_past.time;  
  double H=ext_present.price-ext_past.price;
  return H-tg*L;
 }
 
int CTihiro::TestPointLocate(Extrem *ext_past,Extrem *cur_point,double tg)
//���������, ���� ��� ���� ����� ������ ��������� ������� �����
 {
   double line_level=ext_past.price+(cur_point.time-ext_past.time)*tg;  //��������  ����� ������ � ������ ����� 
   if (cur_point.price>line_level)
    return 1;  //����� ��������� ���� ����� ������
   if (cur_point.price<line_level)
    return -1; //����� ��������� ���� ����� ������
   return 0;   //����� ��������� �� ����� ������
 }
 
//+------------------------------------------------------------------+
//| �������� ��������� �������                                       |
//+------------------------------------------------------------------+ 

