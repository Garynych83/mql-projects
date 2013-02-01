//+------------------------------------------------------------------+
//|                                                Lib CisNewBar.mqh |
//|                                            Copyright 2010, Lizar |
//|                                               Lizar-2010@mail.ru |
//|                                              Revision 2010.09.27 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Class CisNewBar.                                                 |
//| Appointment: ����� ������� ��� ����������� ��������� ������ ���� |
//+------------------------------------------------------------------+

class CisNewBar 
  {
   protected:
      datetime          m_lastbar_time;   // ����� �������� ���������� ����

      string            m_symbol;         // ��� �����������
      ENUM_TIMEFRAMES   m_period;         // ������ �������
      
      uint              m_retcode;        // ��� ���������� ����������� ������ ���� 
      int               m_new_bars;       // ���������� ����� �����
      string            m_comment;        // ����������� ����������
      
   public:
      void              CisNewBar();      // ����������� CisNewBar      
      //--- ������ ������� � ���������� ������:
      uint              GetRetCode() const      {return(m_retcode);     }  // ��� ���������� ����������� ������ ���� 
      datetime          GetLastBarTime() const  {return(m_lastbar_time);}  // ����� �������� ���������� ����
      int               GetNewBars() const      {return(m_new_bars);    }  // ���������� ����� �����
      string            GetComment() const      {return(m_comment);     }  // ����������� ����������
      string            GetSymbol() const       {return(m_symbol);      }  // ��� �����������
      ENUM_TIMEFRAMES   GetPeriod() const       {return(m_period);      }  // ������ �������
      //--- ������ ������������� ���������� ������:
      void              SetLastBarTime(datetime lastbar_time){m_lastbar_time=lastbar_time;                            }
      void              SetSymbol(string symbol)             {m_symbol=(symbol==NULL || symbol=="")?Symbol():symbol;  }
      void              SetPeriod(ENUM_TIMEFRAMES period)    {m_period=(period==PERIOD_CURRENT)?Period():period;      }
      //--- ������ ����������� ������ ����:
      bool              isNewBar(datetime new_Time);                       // ������ ��� ������� �� ��������� ������ ����.
      int               isNewBar();                                        // ������ ��� ������� �� ��������� ������ ����. 
  };
   
//+------------------------------------------------------------------+
//| ����������� CisNewBar.                                           |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CisNewBar::CisNewBar()
  {
   m_retcode=0;         // ��� ���������� ����������� ������ ���� 
   m_lastbar_time=0;    // ����� �������� ���������� ����
   m_new_bars=0;        // ���������� ����� �����
   m_comment="";        // ����������� ����������
   m_symbol=Symbol();   // ��� �����������, �� ��������� ������ �������� �������
   m_period=Period();   // ������ �������, �� ��������� ������ �������� �������    
  }

//+------------------------------------------------------------------+
//| ������ ��� ������� �� ��������� ������ ����.                     |
//| INPUT:  newbar_time - ����� �������� ���������������� ������ ����|
//| OUTPUT: true   - ���� �������� ����� ���(�)                      |
//|         false  - ���� �� �������� ����� ��� ��� �������� ������  |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CisNewBar::isNewBar(datetime newbar_time)
  {
   //--- ������������� ���������� ����������
   m_new_bars = 0;      // ���������� ����� �����
   m_retcode  = 0;      // ��� ���������� ����������� ������ ����: 0 - ������ ���
   m_comment  =__FUNCTION__+" �������� ��������� ������ ���� ����������� �������";
   //---
   
   //--- �� ������ ������ ��������: �� ��������� �� ����� ���������������� ������ ���� m_newbar_time ������ ������� ���� m_lastbar_time? 
   if(m_lastbar_time>newbar_time)
     { // ���� ����� ��� ������ ������� ����, �� ������ ��������� �� ������
      m_comment=__FUNCTION__+" ������ �������������: ����� ����������� ���� "+TimeToString(m_lastbar_time)+
                                                  ", ����� ������� ������ ���� "+TimeToString(newbar_time);
      m_retcode=-1;     // ��� ���������� ����������� ������ ����: ���������� -1 - ������ �������������
      return(false);
     }
   //---
        
   //--- ���� ��� ������ ����� 
   if(m_lastbar_time==0)
     {  
      m_lastbar_time=newbar_time; //--- ��������� ����� ���������� ���� � ������
      m_comment   =__FUNCTION__+" ������������� lastbar_time="+TimeToString(m_lastbar_time);
      return(false);
     }   
   //---

   //--- ��������� ��������� ������ ����: 
   if(m_lastbar_time<newbar_time)       
     { 
      m_new_bars=1;               // ���������� ����� �����
      m_lastbar_time=newbar_time; // ���������� ����� ���������� ����
      return(true);
     }
   //---
   
   //--- ����� �� ����� ����� - ������ ��� �� ����� ��� ������, ������ false
   return(false);
  }

//+------------------------------------------------------------------+
//| ������ ��� ������� �� ��������� ������ ����.                     |
//| INPUT:  no.                                                      |
//| OUTPUT: m_new_bars - ���������� ����� �����                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
int CisNewBar::isNewBar()
  {
   datetime newbar_time;
   datetime lastbar_time=m_lastbar_time;
      
   //--- ����������� ����� �������� ���������� ����:
   ResetLastError(); // ������������� �������� ���������������� ���������� _LastError � ����.
   if(!SeriesInfoInteger(m_symbol,m_period,SERIES_LASTBAR_DATE,newbar_time))
     { // ���� ������ ��� ���������, �� ������ ��������� �� ������:
      m_retcode=GetLastError();  // ��� ���������� ����������� ������ ����: ���������� �������� ���������� _LastError
      m_comment=__FUNCTION__+" ������ ��� ��������� ������� �������� ���������� ����: "+IntegerToString(m_retcode);
      return(0);
     }
   //---
   
   //---����� ���������� ������ ��� ������� �� ��������� ������ ���� ��� ���������� �������:
   if(!isNewBar(newbar_time)) return(0);
   
   //---������� ���������� ����� �����:
   m_new_bars=Bars(m_symbol,m_period,lastbar_time,newbar_time)-1;

   //--- ����� �� ����� ����� - ������ �������� ����� ���(�), ������ �� ����������:
   return(m_new_bars);
  }
  
