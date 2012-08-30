//+------------------------------------------------------------------+
//|                                                    GetLotsx2.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
#property copyright "Copyright � 2011, GIA"
#property link      "http://www.saita.net"

double GetLotsx2() {
  
  /*
  double one_lot_price=MarketInfo("EURUSD",MODE_MARGINREQUIRED); // ��������� 1 ����
  double Money=lotmin*one_lot_price;              // �������� ������
  double lot;
  
  if(Money<=AccountFreeMargin())           // ������� �������
   lot = lotmin;                           // ..��������� �������� 
  else  
   {
    Alert ("�� ������� �����");
    lot = 0;
    return (lot);
   }
  */
  
  double lot = lotmin;
  
  if (!uplot) return (lot); // �������� �� ��������� �������� ����
  
  int ticket = GetLastOrderHist(); // ����� ��������� ������
  if (ticket == -1) return (lot); // �� ���� ������
  
  if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) return (lot); // �� �������� ����� � ���������� �������
  if (OrderProfit()*lastprofit < 0) return (lot);  // lastprofit = -1, ����������� ��� ����� ������� ������ (���� lastprofit = 1, �� ��������� ����� ����� ������) 
  
  if (OrderLots() == lotmin) {lot = lotmin * 2; return(lot);}
  if (OrderLots() == lotmin * 2) {lot = lotmin * 4; return(lot);}
  if (OrderLots() == lotmin *4) {lot = lotmin * 8; return(lot);}
  if (OrderLots() == lotmin *8) {lot = lotmin * 10; return(lot);}
  if (OrderLots() == lotmin *10) {lot = lotmin *10; return(lot);}
  
  /*
  Money=lotmin*one_lot_price;
  if(Money>AccountFreeMargin())           // ������� �� �������
   {
    Alert ("�� ������� ����� �� ", lot/lotmin, " �����");
    lot = lotmin;
    return (lot);
   }
  */ 
  return (lot);
}