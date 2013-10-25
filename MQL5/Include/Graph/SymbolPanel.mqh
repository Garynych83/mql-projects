//+------------------------------------------------------------------+
//|                                                  SymbolPanel.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#include "Objects\Label.mqh"
#include "Objects\Input.mqh"
//+------------------------------------------------------------------+
//| ���������� ��� ������� ����������� ������� �������               |
//+------------------------------------------------------------------+

 void SymbolPanel(string symbol,
                    string caption,
                    uint x,
                    uint y,
                    long chart_id,
                    int sub_window,
                    ENUM_BASE_CORNER corner,
                    long z_order)
  {
    string magic         =   IntegerToString(pos.getMagic());  //���������� �����
    string symbol        =   pos.getSymbol(); //������
    string posType       =   GetNameOP(pos.getType());    //��� �������    
    string posStatus     =   PositionStatusToStr(pos.getPositionStatus());  //������ �������    
    string posProfit     =   DoubleToString(pos.getPosProfit(),5);  //������� �������
    string posPrice      =   DoubleToString(pos.getPositionPrice()); //���� �������
    string posPriceClose =   DoubleToString(pos.getPriceClose());   //���� �������� �������
    string posCloseTime  =   TimeToString(pos.getClosePosDT()); //����� �������� �������
    string posOpenTime   =   TimeToString(pos.getOpenPosDT());  //����� �������� �������    
    string posLot        =   DoubleToString(pos.getVolume());  //��� 
    
    //SymbolInfoString(
   

    new Input("PositionBody","",x,y,260,180,chart_id,sub_window,corner,z_order);
    new Input("PositionHead",caption,x,y,260,15,chart_id,sub_window,corner,z_order);    
    //���������� �����
    new Label("PositionMagic", "������:",x,y+15,250,15,chart_id,sub_window,corner,z_order);
    new Label("PositionMagic2",magic,x+150,y+15,250,15,chart_id,sub_window,corner,z_order);    
    //������
    new Label("PositionSymbol","������:",x,y+30,250,15,chart_id,sub_window,corner,z_order);
    new Label("PositionSymbol2",symbol,x+150,y+30,250,15,chart_id,sub_window,corner,z_order);
    //��� �������
    new Label("PositionType",  "��� �������:",x,y+45,250,15,chart_id,sub_window,corner,z_order);       
    new Label("PositionType2",posType,x+150,y+45,250,15,chart_id,sub_window,corner,z_order);      
    //������ �������     
    new Label("PositionStatus",  "������:",x,y+60,250,15,chart_id,sub_window,corner,z_order);     
    new Label("PositionStatus2",posStatus,x+150,y+60,250,15,chart_id,sub_window,corner,z_order);    
    //������� �������
    new Label("PositionProfit",  "�������:",x,y+75,250,15,chart_id,sub_window,corner,z_order);     
    new Label("PositionProfit2",posProfit,x+150,y+75,250,15,chart_id,sub_window,corner,z_order);  
    //���� ��������
    new Label("PositionPrOpen",  "���� ��������:",x,y+90,250,15,chart_id,sub_window,corner,z_order);     
    new Label("PositionPrOpen2",posPrice,x+150,y+90,250,15,chart_id,sub_window,corner,z_order);      
    //���� ��������
    new Label("PositionPrClose",  "���� ��������:",x,y+105,250,15,chart_id,sub_window,corner,z_order); 
    new Label("PositionPrClose2",posPriceClose,x+150,y+105,250,15,chart_id,sub_window,corner,z_order); 
    //����� ���� ��������
    new Label("PositionOTime",  "����� ���� ��������:",x,y+120,250,15,chart_id,sub_window,corner,z_order);   
    new Label("PositionOTime2",posOpenTime,x+150,y+120,250,15,chart_id,sub_window,corner,z_order);        
    //����� ���� ��������
    new Label("PositionCTime",  "����� ���� ��������:",x,y+135,250,15,chart_id,sub_window,corner,z_order);   
    new Label("PositionCTime2",posCloseTime,x+150,y+135,250,15,chart_id,sub_window,corner,z_order);        
    //���
    new Label("PositionLot",  "���:",x,y+150,250,15,chart_id,sub_window,corner,z_order);     
    new Label("PositionLot2",posLot,x+150,y+150,250,15,chart_id,sub_window,corner,z_order);                                      
  }