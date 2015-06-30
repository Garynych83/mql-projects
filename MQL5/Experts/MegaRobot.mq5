//+------------------------------------------------------------------+
//|                                                    megathron.mq5 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

//����������� ����������� ���������


#include <SystemLib/IndicatorManager.mqh>   // ���������� �� ������ � ������������
#include <MoveContainer/CMoveContainer.mqh> // ������(�����) ��������� ��������
#include <CTrendChannel.mqh>                // ������(�� ��������) ��������� ���������
#include <Rabbit/RabbitsBrain.mqh>
#include <Hvost/HvostBrain.mqh>
#include <Chicken/ChickensBrain.mqh>
#include <RobotEvgeny/EvgenysBrain.mqh>
//#include <CExtrContainer.mgh>

//���������
#define SPREAD 30       // ������ ������ 

// ---------���������� ������------------------
CExtrContainer *extr_container;
CContainerBuffers *conbuf; // ����� ����������� �� ��������� ��, ����������� �� OnTick()
                           // highPrice[], lowPrice[], closePrice[] � �.�; 
                           
CRabbitsBrain  *rabbit;
CChickensBrain *chickenM5, *chickenM15, *chickenH1;
CHvostBrain    *hvostBrain;
CEvgenysBrain  *evgeny;

CTradeManager *ctm;        // �������� ����� 
     
datetime history_start;    // ����� ��� ��������� �������� �������
int robot_signal;
int handleDE; 
int moveSELL;
int moveBUY;  
double value;  // ����� �������                        

ENUM_TM_POSITION_TYPE opBuy, opSell; // ���������
ENUM_TIMEFRAMES TFs[7]    = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1};//, PERIOD_H4, PERIOD_D1, PERIOD_W1};
ENUM_TIMEFRAMES JrTFs[3]  = {PERIOD_M1, PERIOD_M5, PERIOD_M15};
ENUM_TIMEFRAMES MedTFs[2] = {PERIOD_H1, PERIOD_H4};
ENUM_TIMEFRAMES EldTFs[2] = {PERIOD_D1, PERIOD_W1};

//---------��������� ������� � ���������------------
SPositionInfo pos_info;
/*//---------������� ���������� � �������� ��������� �� ������ ������ ����������� ��------
SPositionInfo mass_pos_info_Old[];
SPositionInfo mass_pos_info_Mid[];
SPositionInfo mass_pos_info_Jun[]; // ���� ����� ������� ������ ������� 0, ����� �������� ������ ������� �� ������ ��*/
STrailing     trailing;
//--------------������ �������----------------------
CArrayObj *robots_OLD;
CArrayObj *robots_MID;
CArrayObj *robots_JUN;

CBrain *robot;


// ����������� �������� �������??
long magicAll[6] = {1111, 1112, 1113, 1114, 1115, 1116};


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
 Print("������������� ��������");
 ctm = new CTradeManager();
 history_start = TimeCurrent(); // �������� ����� ������� �������� ��� ��������� �������� �������

 //---------- ��������� ��������� ���� ������ �� ����----------------
 conbuf = new CContainerBuffers(TFs);
 for (int attempts = 0; attempts < 25; attempts++)
 {
  conbuf.Update();
  Sleep(100);
  if(conbuf.isFullAvailable())
  {
   PrintFormat("�������-�� ����������! attempts = %d", attempts);
   break;
  }
 }
  if(!conbuf.isFullAvailable())
   return (INIT_FAILED);
 //---------- ��������� ��������� ����������� ��� ������� �� �4----------------
 handleDE = DoesIndicatorExist(_Symbol, PERIOD_H4, "DrawExtremums");
 if (handleDE == INVALID_HANDLE)
 {
  handleDE = iCustom(_Symbol, PERIOD_H4, "DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   Print("�� ������� ������� ����� ���������� DrawExtremums");
   return (INIT_FAILED);
  }
 }   
 extr_container = new CExtrContainer(handleDE,_Symbol,PERIOD_H4,1000);
 if(!extr_container.Upload()) // ���� �� ���������� ������� ������
  return (INIT_FAILED);
 

 //-----------�������� ������ ������� �� ������� ��----------------
 robots_OLD = new CArrayObj();
              robots_OLD.Add(new  CEvgenysBrain(_Symbol,PERIOD_H4, extr_container, conbuf));
 //-----------�������� ������ ������� �� ������� ��----------------
 robots_MID = new CArrayObj();
              //robots_MID.Add(new CChickensBrain(_Symbol,PERIOD_H1, conbuf));
 //-----------�������� ������ ������� �� ������� ��----------------
 robots_JUN = new CArrayObj();
              //robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M5, conbuf));
              //robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M15, conbuf));
              //robots_JUN.Add(new  CRabbitsBrain(_Symbol, conbuf));
              
 pos_info.volume = 1;
 trailing.trailingType = TRAILING_TYPE_NONE;
 trailing.trailingStop = 0;
 trailing.trailingStep = 0;
 trailing.handleForTrailing = 0;
  
 moveSELL = 0;
 moveBUY = 0;
 Print("������������� ������� ���������");
 return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
 delete rabbit;
 delete chickenM5;
 delete chickenM15;
 delete chickenH1;
 delete evgeny;
 
 delete conbuf;
 delete ctm;
 delete extr_container;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
 conbuf.Update();
 ctm.OnTick();   
       
 MoveDown(robots_OLD);
 MoveUp(robots_JUN);
 //PrintFormat("moveSELL = %d moveBUY %d", moveSELL, moveBUY);
 
   //�������� ������� �� ������� ��, �������� ��������� � ��������������� ����������
    //
   //� ������������ �� �������� ���������, �������� ������ �� ������� ������� ��; ��������� ���������� ���������
    //����� ������� ���� ����� ������� ��� ��� ������� ������ ����?
    //���� ��������� ������� - ��� ��������� ��� ���� ��������� ������� �� ������ ��?
   //�������� ������� �� ������� ��
   
   //��������� ��������� �� ����, ������� �� ������� ��; ������� ������� � ������ ����� ���������
   //�� ���������� �������� ��������� ����������� �������� �� ������� ��
   //
   
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
//---
   
}
//+------------------------------------------------------------------+

void MoveDown (CArrayObj *robots) // �������� � ������������ ����������� ������� � �������� ������� SELL � OP_SELL
{
 FillTradeInfo(robots); // ��������� ���������� � �������� ��� ��
 
 // ���� �� ������� �� ���� �������� �������
 if(moveBUY != 0||moveSELL != 0)
 {
  pos_info.volume = value;
  // ��� ������� ������ �� ���� ��
  for(int i = 0; i < robots.Total(); i++)
  {
   robot = robots.At(i);
   // �������� �������� ������ �� ��������� ������
   robot_signal = robot.GetSignal();
   // ���� ������ ������ �� �������� �������
   if(robot_signal == SELL || robot_signal == BUY)
   {
    // ������� �������, � �������� ����� ������ �� ����������� SELL
     if(robot_signal == SELL && moveSELL == SELL) // ���� ���� ���������� � �������� �� �� �������� � ���� �����������
      pos_info.type = OP_SELL;
     else if(robot_signal == BUY && moveBUY == BUY)
      pos_info.type = OP_BUY;
     else
      continue;
    // ���� � ����� ������ ��� �������� �������
    if(ctm.GetPositionCount(robot.GetMagic()) <= 0)
    {
     // ������� ����������� ������ ��������� ������������� ��� ��� getSignal()
     ctm.OpenMultiPosition(_Symbol,robot.GetPeriod(),pos_info,trailing);
    }
    // ��-�������: ������ � ��������. ��� �� ��������� ������� ���������������� ����������� �� ������ �� ������������ � getSignal �� ���� �� ������
    
    // ���� ���������� �������� ������� � magic�� ����� ������ 
    // ��������� �� ��������� � ����� ������ � ��������� �����
    else 
    {
     // if (ctm.GetPositionType(_Symbol,robot.GetMagic()) != robot_signal)//�� �� ����������� ������������ ������������ �������
     // ctm.ClosePosition(robot.GetMagic());
     // ctm.OpenMultiPosition(_Symbol,robot.GetPeriod(),pos_info, trailing); + magic 
     // ������� ������� �� ���������������� ������� � ��� � ������� �� ������������, 
     // ���� �� ������� ���� ���������� �� �������� �� ���������������� �������
     // ��� ������ ������� �������������� ��� ������, � ��� ��� ����� ������� ������� ���� ��������� ����� (���������� �� �����������)
    }
   }
   else if (robot_signal == DISCORD)
   {
    // ������� ������� � �������� ����� ������
    // ctm.ClosePosition(robot.GetMagic());
   }
  }
 }
 if(robots != robots_JUN)
  MoveDown(GetNextTI(robots,true));
}

void MoveUp (CArrayObj *robots)
{
 for(int i = 0; i < robots.Total(); i++) 
 {
  robot = robots.At(i); // ��� ������� ������ �� ��
  // ���� ��� ������� ���������� � �������
  if(ctm.GetPositionCount(robot.GetMagic()) <= 0) 
  {
  }
  else
  {
   // �������� ����������� , SL � TP �������
   double curPrice;
   if(ctm.GetPositionType(_Symbol, robot.GetMagic()) == OP_SELL)
   {
    curPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    if(curPrice <= ctm.GetPositionTakeProfit(_Symbol, robot.GetMagic()))
    {
     // ��������� ����� �������
     // ctm.ClosePosition(robot.GetMagic(), value);
     // value = ? 
     // � ��������� ���������� ����� � ������ �������� ��
     // ctm.AddPositionValue(ChooseTheBrain(OP_SELL, GetNextTI(robots, false)) value);//up
     // ���� ������� ����� �� ��������� ������� �� ����������� � ���������� �������� �����
     // �� ������� "��������" �� ������ = 0;
    }
    // ���� ������� ��������� SL ��������� ������� ���������
    if(curPrice >= ctm.GetPositionStopLoss(_Symbol, robot.GetMagic()))
    {
     //ctm.ClosePosition(magic);
    }    
   }
   
   if(ctm.GetPositionType(_Symbol,robot.GetMagic()) == OP_BUY)
   {
    curPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    if(curPrice >= ctm.GetPositionTakeProfit(_Symbol, robot.GetMagic()))
    {
     // ��������� ����� �������
     // ctm.ClosePosition(robot.GetMagic(), value);
     // value = ? 
     // � ��������� ���������� ����� � ������ �������� ��
     // ctm.AddPositionValue(ChooseTheBrain(OP_SELL, GetNextTI(robots, false)) value);//up
    }
    // ���� ������� ��������� SL ��������� ������� ���������
    if(curPrice <= ctm.GetPositionStopLoss(_Symbol, robot.GetMagic()))
    {
     //ctm.ClosePosition(magic);
    }    
   }
  }
 }
 if(robots!=robots_OLD)
  MoveUp(GetNextTI(robots,false));
}


CArrayObj *GetNextTI(CArrayObj *robots, bool down)
{
 CBrain *robot = robots.At(0); 
 ENUM_TIMEFRAMES period = robot.GetPeriod();

 if(period >= PERIOD_H4)
  return down ? robots_MID  :  robots_OLD;
 if(period > PERIOD_M15 && period < PERIOD_H4)
  return down ? robots_JUN  :  robots_OLD;
 if(period <= PERIOD_M15)
  return down ? robots_JUN  :  robots_MID;
  
 return robots_JUN;  
}


void FillTradeInfo(CArrayObj *robots)
{ 
 moveSELL = 0;
 moveBUY = 0;
 CBrain *robot = robots.At(0);
 if(robot.GetPeriod() > PERIOD_M15)
  value = 0.0;
 else
  value = 1.0;
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  //moveSELL = robot.GetDirection();
  if(robot.GetDirection() == 1)
   moveBUY = 1;
  else if(robot.GetDirection() == -1)
   moveSELL = -1;
 }
 return;
}

int ChooseTheBrain(int pos_type, CArrayObj *robots)
{
 double volume = 0;
 int magic = 0;   // �� ��� - ���� ������ ������� �������������, ������� ��, �� ������� � ������
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  magic = robot.GetMagic();
  if(ctm.GetPositionCount(magic))
  {
   if(ctm.GetPositionType(magic) == pos_type)
   {
    if(ctm.GetPositionVolume(magic) >= volume)
    {
     magic = robot.GetMagic();
     volume = ctm.GetPositionVolume(magic);
    }
   }
  }
 }
 return magic;
}

// �������� ����������� ������� � �������� 

// ���������� ����� �������, ����� �� �������� � �������� ����� ������ ������� �������� ����� �����������
/*
void FillTradeMoveTI(CArrayObj *robots)
{ 
 moveSELL = 0;
 moveBUY = 0;
 CBrain *robot;
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  //moveSELL = robot.GetDirection();
  if(robot.GetDirection() == 1)
   moveBUY = 1;
  else if(robot.GetDirection() == -1)
   moveSELL = -1;
 }
 return;
}*/

//ctm.ShareWithDaddy()