//+------------------------------------------------------------------+
//|                                          DesepticonVariables.mq4 |
//|                                            Copyright � 2011, GIA |
//|                                             http://www.saita.net |
//+------------------------------------------------------------------+
// �������� ���������� ����������

extern int _MagicNumber = 1122;
extern int startTF = 1;
extern int finishTF = 2;
// ��������� ������
extern double StopLoss_5M_min = 150;
extern double StopLoss_5M_max = 150;
extern double TakeProfit_5M = 400;
extern double MACD_channel_5M = 0.0005;
/*
extern double StopLoss_15M = 250;
extern double TakeProfit_15M = 700;
extern double MACD_channel_15M = 0.001;
*/
extern double StopLoss_1H_min = 400;
extern double StopLoss_1H_max = 150;
extern double TakeProfit_1H = 1600;
extern double MACD_channel_1H = 0.002;

extern double StopLoss_1D_min = 400;
extern double StopLoss_1D_max = 150;
extern double TakeProfit_1D = 1600;
extern double MACD_channel_1D = 0.007;

// ��������� ���������
extern bool UseTrailing = true;
extern int MinProfit_5M = 300; // ����� ������ ��������� ��������� ���������� �������, �������� �������� ������
extern int TrailingStop_5M_min = 300; // �������� �����
extern int TrailingStop_5M_max = 300; // �������� �����
extern int TrailingStep_5M = 100; // �������� ����

extern int MinProfit_1H = 300; // ����� ������ ��������� ��������� ���������� �������, �������� �������� ������
extern int TrailingStop_1H_min = 300; // �������� �����
extern int TrailingStop_1H_max = 300; // �������� �����
extern int TrailingStep_1H = 100; // �������� ����

extern int MinProfit_1D = 300; // ����� ������ ��������� ��������� ���������� �������, �������� �������� ������
extern int TrailingStop_1D_min = 300; // �������� �����
extern int TrailingStop_1D_max = 300; // �������� �����
extern int TrailingStep_1D = 100; // �������� ����
// ��������� �����������
// EMA
extern int jr_EMA1 = 12;
extern int jr_EMA2 = 26;
extern int eld_EMA1 = 12;
extern int eld_EMA2 = 26;
extern double deltaEMAtoEMA = 5;
extern int deltaPriceToEMA = 5;
extern int hairLength = 250;

// MACD
extern int jrFastMACDPeriod = 12;
extern int jrSlowMACDPeriod = 26;
extern int eldFastMACDPeriod = 12;
extern int eldSlowMACDPeriod = 26;
extern int divergenceFastMACDPeriod = 12;
extern int divergenceSlowMACDPeriod = 26;
extern int depthMACD = 3;
extern int minorMACD = 0.0001;

// iStochastic
extern int Kperiod = 5;
extern int Dperiod = 3;
extern int slowing = 3;
extern int topStochastic = 80;
extern int bottomStochastic = 20;

// RSI
//extern int periodRSI = 15;

extern int deltaPrice = 50;
extern int depthPrice = 5;
extern int barsToWait = 60;

extern int depthDiv = 100;

// --- ��������� ���������� ��������� ---
extern bool uplot = true; // ���/���� ��������� �������� ����
extern int lastprofit = -1; // ��������� �������� -1/1. 
// -1 - ���������� ���� ����� ��������� ������ �� ������ ��������
//  1 - ���������� ���� ����� �������� ������ �� ������ ���������
extern double lotmin = 0.1; // ��������� �������� 
//extern double lotmax = 0.5; // �������
//extern double lotstep = 0.1; // ���������� ����

// ���������� ����������
bool   gbDisabled    = False;          // ���� ���������� ���������
color  clOpenBuy = Red;                // ���� ������ �������� �������
color  clOpenSell = Green;             // ���� ������ �������� �������
int    Slippage      = 3;              // ��������������� ����
int    NumberOfTry   = 5;              // ���������� �������� �������
bool   UseSound      = True;           // ������������ �������� ������
string NameFileSound = "expert.wav";   // ������������ ��������� �����
bool Debug = false;

int trendDirection[3][2]; // [][0] - ����� ���� ����. 0 - ������ ����; [][1] - �� ����� ���� 0 - ������ ���������� �����
double aCorrection[3][2]; // [][0] - ������� ���������, [][1] - �������� ����
int total;
int ticket;
int _GetLastError = 0;
double Lots;
double Current_fastEMA, Current_slowEMA;
double CurrentMACD;
double Stochastic;
double RSI;
double MACD_15M[30];
//double minPriceForFlat[2];
//double maxPriceForFlat[2];
double minPriceForDiv[3][2]; //[��][0] - ��������, [��][1] - ����� ����
double maxPriceForDiv[3][2]; //[��][0] - ��������, [��][1] - ����� ����
// ����������� ��� ������ �������
double minPrice;
double maxPrice;
bool waitForMACDMaximum[2] = {false, /*false,*/ false};
bool waitForMACDMinimum[2] = {false, /*false,*/ false};
///////////////
double minMACD[2][2]; //[0] - ��������, [1] - ����� ����
double maxMACD[2][2]; //[0] - ��������, [1] - ����� ����

int wantToOpen[3][2];
int buyCondition;
int sellCondition;
int barsCountToBreak[3][2];
int breakForMACD = 4;
int breakForStochastic = 2;

string openPlace;
//string sell_condition;
//string buy_condition;
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
int MinProfit;
double TrailingStop; 
int TrailingStop_min;
int TrailingStop_max; 
int TrailingStep;

static bool _isTradeAllow = true;

double aDivergence[3][60][5]; // [][0] - ������
                           // [][1] - ����-� MACD
                           // [][2] - ����-� ���� � ���������� MACD
                           // [][3] - ����� ����
                           // [][4] - ���� +/-                          