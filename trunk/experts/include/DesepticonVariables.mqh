//+------------------------------------------------------------------+
//|                                          DesepticonVariables.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
// �������� ���������� ����������

extern int _MagicNumber = 1122;
//extern
 int startTF = 1;
//extern
 int finishTF = 2;
// ��������� ������

//extern
 double StopLoss_5M_min = 150;
//extern
 double StopLoss_5M_max = 150;
//extern
 double TakeProfit_5M = 400;
//extern
 double MACD_channel_5M = 0.0005;

//extern double StopLoss_15M = 250;
//extern double TakeProfit_15M = 700;
//extern double MACD_channel_15M = 0.001;

extern double StopLoss_1H_min = 400;
extern double StopLoss_1H_max = 500;
extern double TakeProfit_1H = 1600;
extern double MACD_channel_1H = 0.002;

//extern
 double StopLoss_1D_min = 400;
//extern
 double StopLoss_1D_max = 500;
//extern
 double TakeProfit_1D = 1600;
//extern
 double MACD_channel_1D = 0.007;

// ��������� ���������
extern bool useTrailing = true;
//extern
 double MinProfit_5M = 300; // ����� ������ ��������� ��������� ���������� �������, �������� �������� ������
//extern
 double TrailingStop_5M_min = 300; // �������� �����
//extern
 double TrailingStop_5M_max = 300; // �������� �����
//extern
 double TrailingStep_5M = 100; // �������� ����

extern double MinProfit_1H = 300; // ����� ������ ��������� ��������� ���������� �������, �������� �������� ������
extern double TrailingStop_1H_min = 300; // �������� �����
extern double TrailingStop_1H_max = 300; // �������� �����
extern double TrailingStep_1H = 100; // �������� ����

//extern
 double MinProfit_1D = 300; // ����� ������ ��������� ��������� ���������� �������, �������� �������� ������
//extern
 double TrailingStop_1D_min = 300; // �������� �����
//extern
 double TrailingStop_1D_max = 300; // �������� �����
//extern
 double TrailingStep_1D = 100; // �������� ����
 
extern bool useLowTF_EMA_Exit = true; // ���/���� ������ �� ����������� ������� EMA
extern bool useTimeExit = true; // ���/���� ������ �� ������� ��� �������
extern int waitForMove = 6;
extern double MinimumLvl = 80;
// ��������� �����������
// EMA
extern int jr_EMA1 = 12;
extern int jr_EMA2 = 26;
extern int eld_EMA1 = 12;
extern int eld_EMA2 = 26;
extern double deltaEMAtoEMA = 5;
extern int deltaPriceToEMA = 5;

// MACD
extern int jrFastMACDPeriod = 12;
extern int jrSlowMACDPeriod = 26;
extern int eldFastMACDPeriod = 12;
extern int eldSlowMACDPeriod = 26;

// RSI
//extern int periodRSI = 15;

extern int deltaPrice = 50;
extern int depthPrice = 5;
extern int barsToWait = 60;

extern int depthDiv = 100;
extern double differenceMACD = 0.0001;
// --- ��������� ���������� ��������� ---
extern bool uplot = true; // ���/���� ��������� �������� ����
extern int lastprofit = -1; // ��������� �������� -1/1. 
// -1 - ���������� ���� ����� ��������� ������ �� ������ ��������
//  1 - ���������� ���� ����� �������� ������ �� ������ ���������
extern double lotmin = 0.1; // ��������� �������� 
//extern double lotmax = 0.5; // �������
//extern double lotstep = 0.1; // ���������� ����
extern bool useLimitOrders = false;
extern int priceDifference = 20;

// ���������� ����������
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

int trendDirection[3][2]; // [][0] - ����� ���� ����. 0 - ������ ����; [][1] - �� ����� ���� 0 - ������ ���������� �����
int total;
int ticket;
int _GetLastError = 0;
double lots;
double Current_fastEMA, Current_slowEMA;
double CurrentMACD;

///////////////
double minMACD[2][2]; //[0] - ��������, [1] - ����� ����
double maxMACD[2][2]; //[0] - ��������, [1] - ����� ����

bool isMinProfit;
int barNumber;
int wantToOpen[3][2];
int buyCondition;
int sellCondition;
int barsCountToBreak[3][2];
int breakForMACD = 4;
int breakForStochastic = 2;

string openPlace;
int frameIndex;
bool MACD_up, MACD_down;

double aTimeframe[3][11]; //

int Jr_Timeframe;
int Elder_Timeframe;
double StopLoss;
double StopLoss_min;
double StopLoss_max;
double TakeProfit;
double Jr_MACD_channel;
double Elder_MACD_channel;
int minProfit;
double trailingStop; 
int trailingStop_min;
int trailingStop_max; 
int trailingStep;

static bool _isTradeAllow = true;

double aDivergence[3][60][5]; // [][0] - ������
                           // [][1] - ����-� MACD
                           // [][2] - ����-� ���� � ���������� MACD
                           // [][3] - ����� ����
                           // [][4] - ���� +/-                          