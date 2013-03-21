//+------------------------------------------------------------------+
//|                                               BasicVariables.mq4 |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
//------- ������� ��������� ��������� -----------------------------------------+
extern string Basic_Parameters = "Basic_Parameters";
extern int _MagicNumber = 1122;
extern int timeframe = 60;

extern double stopLoss = 400;
extern double takeProfit = 1600;

extern bool useTrailing = true;

extern double minProfit = 300; // ����� ������ ��������� ��������� ���������� �������, �������� �������� ������
extern double trailingStop = 300; // �������� �����
extern double trailingStep = 100; // �������� ����

// --- ��������� ���������� ��������� ---
extern bool uplot = true; // ���/���� ��������� �������� ����
extern int lastprofit = -1; // ��������� �������� -1/1. 
// -1 - ���������� ���� ����� ��������� ������ �� ������ ��������
//  1 - ���������� ���� ����� �������� ������ �� ������ ���������
extern double lotmin = 0.1; // ��������� �������� 
//extern double lotmax = 0.5; // �������
//extern double lotstep = 0.1; // ���������� ����

// --- ��������� ������������� ���������� ������� ---
extern bool useLimitOrders = false;
extern int limitPriceDifference = 20;

extern bool useStopOrders = false;
extern int stopPriceDifference = 20;

//------- ���������� ���������� ��������� -------------------------------------+
string _symbol = "";

bool   gbDisabled    = False;          // ���� ���������� ���������
color  clOpenBuy = Red;                // ���� ������ �������� �������
color  clOpenSell = Green;             // ���� ������ �������� �������
color  clCloseBuy    = Blue;           // ���� ������ �������� �������
color  clCloseSell   = Blue;           // ���� ������ �������� �������
color  clDelete      = Black;          // ���� ������ ������ ����������� ������
int    Slippage      = 3;              // ��������������� ����
int    NumberOfTry   = 5;              // ���������� �������� �������
bool   UseSound      = True;           // ������������ �������� ������
string NameFileSound = "expert.wav";   // ������������ ��������� �����
bool Debug = false;

int total = 0;
int ticket = -1;
int _GetLastError = 0;
double lots = 0;
string openPlace;

