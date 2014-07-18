//+------------------------------------------------------------------+
//|                                                   divSignals.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Class divSignals.                                                |
//| Appointment: ����� ������� ��� ����������� �����������           |
//|              ����������� ���� � ����������                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"
#include <CompareDoubles.mqh>


class divSignals
  {
private:
   int    m_delta;                  // ������ � ����� ����� ������� ������������ ���� � ����������
   int    m_firstBarsCount;         // ���������� ������ ����� �� ������� ������ ���������� �������� ��� ������� ����
   int    m_rightIndexOfPrice;      // ������ ������ ����� ����� ���������/����������� ����
   int    m_leftIndexOfPrice;       // ������ ����� ����� ����� ���������/����������� ����
   int    m_rightIndexOfStochastic; // ������ ������ ����� ����� ���������/����������� ����������
   int    m_leftIndexOfStochastic;  // ������ ����� ����� ����� ���������/����������� ����������
   double m_highLineOfStochastic;   // ������� �������� ������� ����������
   double m_lowLineOfStochastic;    // ������ �������� ������� ����������
   double m_rightPointOfPrice;      // �������� ������ ����� ����� ���������/����������� ����
   double m_leftPointOfPrice;       // �������� ����� ����� ����� ���������/����������� ����
   double m_rightPointOfStochastic; // �������� ������ ����� ����� ���������/����������� ����������
   double m_leftPointOfStochastic;  // �������� ����� ����� ����� ���������/����������� ����������
   
   bool   FindMaxPrices (const double &price[], int indexOfFirstBar, int period);     // ����� ������ ���� ��� ���������� �����������
   bool   FindMinPrices (const double &price[], int indexOfFirstBar, int period);     // ����� ������ ���� ��� ���������� ���������
   bool   FindMaxStochastic (double &main[], int indexOfFirstBar, int period);        // ����� ������ ������ ���������� ��� ���������� �����������
   bool   FindMinStochastic (double &main[], int indexOfFirstBar, int period);        // ����� ������ ������ ���������� ��� ���������� ���������

public:

   bool   Divergence (const double &m_price[], double &main[], int indexOfFirstBar, int period);   // ����� ������ �����������
   bool   Convergence (const double &m_price[], double &main[], int indexOfFirstBar, int period);  // ����� ������ ���������

   int    GetRightIndexOfPrice()      {return(m_rightIndexOfPrice);}
   int    GetLeftIndexOfPrice()       {return(m_leftIndexOfPrice);}
   int    GetRightIndexOfStochastic() {return(m_rightIndexOfStochastic);}
   int    GetLeftIndexOfStochastic()  {return(m_leftIndexOfStochastic);}
   double GetRightPointOfPrice()      {return(m_rightPointOfPrice);} 
   double GetLeftPointOfPrice()       {return(m_leftPointOfPrice);}
   double GetRightPointOfStochastic() {return(m_rightPointOfStochastic);} 
   double GetLeftPointOfStochastic()  {return(m_leftPointOfStochastic);}
   
   void   SetHighLineOfStochastic(double hL) {m_highLineOfStochastic = hL;}
   void   SetLowLineOfStochastic(double lL)  {m_lowLineOfStochastic = lL;}
   void   SetDelta(int d)                    {m_delta = d;}
   void   SetFirstBarsCount(int fBC)         {m_firstBarsCount = fBC;}
  };

 
 /*bool divSignals::FindMaxPrices(const double &price[],int indexOfFirstBar,int period)
 {
  m_rightIndexOfPrice = ArrayMaximum(price, (indexOfFirstBar - (period - 1)), (period - 1)); // ������ ������������� �������� �� ���� ����� �������
  m_rightPointOfPrice = price[m_rightIndexOfPrice]; // ������������ ���� �� ���� ����� �������
  return ((m_rightIndexOfPrice > (indexOfFirstBar - (m_firstBarsCount + 1))) && (m_rightIndexOfPrice < indexOfFirstBar));
 }
 
 bool divSignals::FindMinPrices(const double &price[],int indexOfFirstBar,int period)
 {
  m_rightIndexOfPrice = ArrayMinimum(price, (indexOfFirstBar - (m_firstBarsCount + 1)), m_firstBarsCount); // ������ ������������ �������� �� ���� ����� �������
  m_rightPointOfPrice = price[m_rightIndexOfPrice]; // ����������� ���� �� ���� ����� �������
  return ((m_rightIndexOfPrice > (indexOfFirstBar - (m_firstBarsCount + 1))) && (m_rightIndexOfPrice < indexOfFirstBar));
 }*/
 
 bool divSignals::FindMaxPrices(const double &m_price[],int indexOfFirstBar,int period)
 {
  m_rightIndexOfPrice = ArrayMaximum(m_price, (indexOfFirstBar - (period - 2)) , m_firstBarsCount); // ������ ������������� �������� �� ������ m_firstBarsCount ���������������� �����
  m_leftIndexOfPrice = ArrayMaximum(m_price, (indexOfFirstBar - ((period - 1) - (m_firstBarsCount + 1))), (period - (m_firstBarsCount + 1))); // ������ ������������� �������� �� ���������� ����� �������
  m_rightPointOfPrice = m_price[m_rightIndexOfPrice]; // ������������ ���� �� ������ m_firstBarsCount ���������������� �����
  m_leftPointOfPrice = m_price[m_leftIndexOfPrice]; // ������������ ���� �� ���������� ����� �������
  return (GreatDoubles(m_rightPointOfPrice, m_leftPointOfPrice, 8));
 }
 
 bool divSignals::FindMinPrices(const double &m_price[],int indexOfFirstBar,int period)
 {
  m_rightIndexOfPrice = ArrayMinimum(m_price, (indexOfFirstBar - (period - 2)) , m_firstBarsCount); // ������ ������������ �������� �� ������ m_firstBarsCount ���������������� �����
  m_leftIndexOfPrice = ArrayMinimum(m_price, (indexOfFirstBar - ((period - 1) - (m_firstBarsCount + 1))), (period - (m_firstBarsCount + 1))); // ������ ������������ �������� �� ���������� ����� �������
  m_rightPointOfPrice = m_price[m_rightIndexOfPrice]; // ����������� ���� �� ������ m_firstBarsCount ���������������� �����
  m_leftPointOfPrice = m_price[m_leftIndexOfPrice]; // ����������� ���� �� ���������� ����� �������
  return (GreatDoubles(m_leftPointOfPrice, m_rightPointOfPrice, 8));
 }
  
 bool divSignals::FindMaxStochastic(double &main[],int indexOfFirstBar,int period)
  {
   m_rightPointOfStochastic = 0;
   m_leftPointOfStochastic = 0;
   m_rightIndexOfStochastic = 0;
   m_leftIndexOfStochastic = 0;
   
   for (int i = (period - 3); i > 0; i--)
   {
    if (GreatDoubles(main[indexOfFirstBar - i], main[indexOfFirstBar - (i-1)], 8) && GreatDoubles(main[indexOfFirstBar - i], main[indexOfFirstBar - (i+1)], 8)) // ������� �� ��������� ��� ���������� �����������
      {
       if ((m_rightPointOfStochastic == 0) && GreatDoubles(m_highLineOfStochastic, main[indexOfFirstBar - i], 8))
       {
        m_rightPointOfStochastic = main[indexOfFirstBar - i];
        m_rightIndexOfStochastic = indexOfFirstBar - i;
       }
       else
       {
        if (GreatDoubles(main[indexOfFirstBar - i], m_highLineOfStochastic, 8) && GreatDoubles(main[indexOfFirstBar - i], m_leftPointOfStochastic, 8) && (m_rightPointOfStochastic != 0))
        {
         m_leftPointOfStochastic = main[indexOfFirstBar - i];
         m_leftIndexOfStochastic = indexOfFirstBar - i;
        }
       }
      }
   }
   return ((m_rightPointOfStochastic > 0) && (m_leftPointOfStochastic > 0));   
  }
   
 bool divSignals::FindMinStochastic(double &main[],int indexOfFirstBar,int period)
  {
   m_rightPointOfStochastic = 0;
   m_leftPointOfStochastic = 101;
   m_rightIndexOfStochastic = 0;
   m_leftIndexOfStochastic = 0;
   
   for (int i = (period - 3); i > 0; i--)
   {
    if (LessDoubles(main[indexOfFirstBar - i], main[indexOfFirstBar - (i-1)], 8) && LessDoubles(main[indexOfFirstBar - i], main[indexOfFirstBar - (i+1)], 8)) // ������� �� ��������� ��� ���������� ���������
      {
       if ((m_rightPointOfStochastic == 0) && GreatDoubles(main[indexOfFirstBar - i], m_lowLineOfStochastic, 8))
       {
        m_rightPointOfStochastic = main[indexOfFirstBar - i];
        m_rightIndexOfStochastic = indexOfFirstBar - i;
       }
       else
       {
        if (LessDoubles(main[indexOfFirstBar - i], m_lowLineOfStochastic, 8) && GreatDoubles(m_leftPointOfStochastic, main[indexOfFirstBar - i], 8) && (m_rightPointOfStochastic != 0))
        {
         m_leftPointOfStochastic = main[indexOfFirstBar - i];
         m_leftIndexOfStochastic = indexOfFirstBar - i;
        }
       }
      }
   }
   return ((m_rightPointOfStochastic > 0) && (m_leftPointOfStochastic < 101));
  }
  
 bool divSignals::Divergence(const double &m_price[], double &main[], int indexOfFirstBar, int period)
  {
   return (FindMaxPrices(m_price, indexOfFirstBar, period) && FindMaxStochastic(main, indexOfFirstBar, period) && (MathAbs(m_rightIndexOfPrice - m_rightIndexOfStochastic) < (m_delta + 1)));
  }
 
 bool divSignals::Convergence(const double &m_price[], double &main[], int indexOfFirstBar, int period)
  {
   return (FindMinPrices(m_price, indexOfFirstBar, period) && FindMinStochastic(main, indexOfFirstBar, period) && (MathAbs(m_rightIndexOfPrice - m_rightIndexOfStochastic) < (m_delta + 1)));
  }