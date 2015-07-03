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

class CTI 
{
 CArrayObj *robots;                        // ������ ������� �� ��� ��
 ENUM_SIGNAL_FOR_TRADE _moveBUY;            // ���������� �������� �� BUY �� ���� ��
 ENUM_SIGNAL_FOR_TRADE _moveSELL;           // ���������� �������� �� SeLL �� ���� ��
  public:
  CTI(){_moveBUY = 0; _moveSELL = 0; robots = new CArrayObj();};
  
  CObject *At(int i){return robots.At(i);}
  int  Total(){return robots.Total();}
  void Add(CBrain *brain);
  void SetMoves(ENUM_SIGNAL_FOR_TRADE moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY);
  ENUM_SIGNAL_FOR_TRADE GetMoveSell(){return _moveSELL;}
  ENUM_SIGNAL_FOR_TRADE GetMoveBuy(){return _moveBUY;}
};
CTI::Add(CBrain *brain)
{
 robots.Add(brain);
}
CTI::SetMoves(ENUM_SIGNAL_FOR_TRADE _moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY)
{
 _moveSELL = moveSELL;
 _moveBUY = moveBUY;
}


// ---------���������� ������------------------
CExtrContainer *extr_container;
CContainerBuffers *conbuf; // ����� ����������� �� ��������� ��, ����������� �� OnTick()
                           // highPrice[], lowPrice[], closePrice[] � �.�; 
                           
CRabbitsBrain  *rabbit;

CTradeManager *ctm;        // �������� ����� 
     
datetime history_start;    // ����� ��� ��������� �������� �������
ENUM_SIGNAL_FOR_TRADE robot_position;
int handleDE; 
ENUM_SIGNAL_FOR_TRADE moveSELL;
ENUM_SIGNAL_FOR_TRADE moveBUY;  
double vol;  // ����� �������                        

ENUM_TM_POSITION_TYPE opBuy, opSell; // ���������
ENUM_TIMEFRAMES TFs[7]    = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1};//, PERIOD_H4, PERIOD_D1, PERIOD_W1};/

//---------��������� ������� � ���������------------
SPositionInfo pos_tp;
SPositionInfo pos_give;
/*//---------������� ���������� � �������� ��������� �� ������ ������ ����������� ��------
SPositionInfo mass_pos_info_Old[];
SPositionInfo mass_pos_info_Mid[];
SPositionInfo mass_pos_info_Jun[]; // ���� ����� ������� ������ ������� 0, ����� �������� ������ ������� �� ������ ��*/
STrailing     trailing;
//--------------������ �������----------------------
CTI *robots_OLD;
CTI *robots_MID;
CTI *robots_JUN;

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
 robots_OLD = new CTI();
              robots_OLD.Add(new  CEvgenysBrain(_Symbol,PERIOD_H4, extr_container, conbuf));
 //-----------�������� ������ ������� �� ������� ��----------------
 robots_MID = new CTI();
              robots_MID.Add(new CChickensBrain(_Symbol,PERIOD_H1, conbuf));
 //-----------�������� ������ ������� �� ������� ��----------------
 robots_JUN = new CTI();
              robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M5, conbuf));
              robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M15, conbuf));
              robots_JUN.Add(new  CRabbitsBrain(_Symbol, conbuf));
              
 pos_tp.volume = 0;
 pos_give.volume = 0;
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

void MoveDown (CTI *robots) // �������� � ������������ ����������� ������� � �������� ������� SELL � OP_SELL
{
 ENUM_SIGNAL_FOR_TRADE moveSELL, moveBUY; 
 double vol_tp, vol_give;                       
 FillMoves(robots, moveSELL, moveBUY);    // ���������� ����������� �������� �������� ���������� ���������
 FillVolumes(robots, vol_tp, vol_give);   // ���������� ������ ������� � ������������� � ��������� ���������� (������� 0-0, ������� 0,9-0,1
 // ���� �� ������� �� ���� �������� �������
 if(moveBUY != 0||moveSELL != 0)
 {
  pos_tp.volume = vol_tp;               
  pos_give.volume = vol_give;
  // ��� ������� ������ �� ���� ��
  for(int i = 0; i < robots.Total(); i++)
  {
   robot = robots.At(i);
   // �������� �������� ������ �� ��������� ������ � �������� ��� ������� ���� ��� ����
   robot_position = robot.GetSignal();
   // ���� ������ ������ �� �������� ������� 
   if(robot_position != OP_UNKNOWN )
   {
    // ������� �������, � �������� ����� ������ �� ����������� SELL/BUY
    if(robot_position == SELL && moveSELL == SELL) // ���� ���� ���������� � �������� �� �� �������� � ���� �����������
    {
     pos_tp.type = robot_position;  // ��� ������ ���������� �������� ������
     pos_give.type = robot_position;
    }
    else if(robot_position == BUY && moveBUY == BUY)
    {
     pos_tp.type = robot_position;
     pos_give.type = robot_position;
    }
    else
     continue;
    // ? <�������� �������>
    ctm.OpenUniquePosition(_Symbol, robot.GetPeriod(), pos_tp, trailing);
    // ������ �������� ����� �������, ��� �� ����� ��� ������� ������ ��� ��� ������� � ����� �����������, 
    // �� ���� ��� ���������� ������ ��� ���� ������� ���� �� �����������
    // ctm.OpenMultiPosition(_Symbol,robot.GetPeriod(),pod_info1,trailing);magic!!
    // ctm.OpenMultiPosition(_Symbol,robot.GetPeriod(),pod_info1,trailing);magic!!
   }
   else if (robot_position == OP_UNKNOWN && robot.GetDirection() == NO_SIGNAL)
   {
    // ������� ������� � �������� ����� ������
    ctm.ClosePosition(robot.GetMagic()); // ���������, ���
   }
  }
 }
 if(robots != robots_JUN)
  MoveDown(GetNextTI(robots,true));
}

void MoveUp (CTI *robots)
{
 for(int i = 0; i < robots.Total(); i++) 
 {
  robot = robots.At(i); // ��� ������� ������ �� ��
  // ���� ��� ������� ���������� � �������
  if(ctm.GetPositionCount(robot.GetMagic()) <= 0) // ���� � ��� �� �� ��������� �������, �� pos_give ������ ������������ �� ��. �����
  {
  }
  else
  {
   // ���� ������� ����, ������ ����� �������� ������� ������
    //if(ctm.GetPositionCount(robot.GetMagic()) == 1)
    //{
    // long newmagic = ChoseTheBrain(ctm.GetPositionCount(robot.GetMagic()),GetNextTI(robots,false));
    // 
    // ctm.PositionChangeSize(_Symbol, ctm.GetPositionVolume(_Symbol, robot.GetMagic()));
    //}
   ctm.Positi
   double curPrice;
   
   /*ENUM_POSITION_TYPE pos_type = ctm.GetPositionType(_Symbol, robot.GetMagic());
   switch(pos_type)
   {
    case OP_SELL:
    case OP_SELLLIMIT: // ��� ����� �������� ��� ���?
    case OP_SELLSTOP:
    {
     // ������ ����� ����������� �������� �� pos_sl � pos_give !=0
     // ���� ��, �� 
     // ��������� ����� �������� � �������� ���������� ������� (���������� ��� ������ �� ��������)
     // ���� ���������� ����� ��������� �������� �� ��
     // ���� ��������, �� ���� ������� �������� ���� ( ��� ������, ��� ��� pos_give)
     // �������� ������, �������� ����� ��������� ��� �������, �������������� ������� ���������� � ��
     // ���� �� ������� ��� ������ ������, ��������� � ������� ������ � ���� �������� (chooseBrain) ����   
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
    }*/
   }  
   if(robots != robots_OLD)
   MoveUp(GetNextTI(robots,false));
  }
}

CTI *GetNextTI(CTI *robots, bool down)
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

void FillMoves(CTI *robots, ENUM_SIGNAL_FOR_TRADE moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY)
{
 moveSELL = 0;
 moveBUY = 0;
 // ���� ��� ������� �� ��� ��������� ��������� ������� �� ����� ��������
 if(robots == robots_OLD)// ���������� �� ��������� ��� ����������?
 {
  moveSELL = SELL; // ����������� ������ ��� �������� �� (������ 1)
  moveBUY = BUY;
 } 
 else
 {
  CTI *ElderTI;
  ElderTI = GetNextTI(robots, false);
  moveSELL = ElderTI.GetMoveSell();
  moveBUY = ElderTI.GetMoveBuy();
 } 

 for(int i = 0; i < robots.Total(); i++)      
 { 
  robot = robots.At(i);                         
  if(robot.GetDirection() == SELL && moveSELL == SELL)            
   moveSELL = SELL;
  else if(robot.GetDirection() == BUY && moveBUY == BUY)
   moveBUY = BUY;
 }  
 robots.SetMoves(moveSELL, moveBUY);
 return;
}


void FillVolumes(CTI *robots, double vol_tp, double vol_give)
{
  CBrain *robot = robots.At(0);
 if(robot.GetPeriod() > PERIOD_M15)
 {
  vol_tp = 0.0;
  vol_give = 0.0;
 }
 else
 {
  vol_tp = 0.9;
  vol_give = 0.1;
 }
}



long ChooseTheBrain(ENUM_TM_POSITION_TYPE pos_type, CArrayObj *robots) 
{
 double volume = 0;
 robot = robots.At(0);
 int magic =  robot.GetMagic();  
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  if(ctm.GetPositionCount(magic))
  {
   if(ctm.GetPositionType(magic) == pos_type)
   {
    if(ctm.GetPositionVolume(magic) >= volume)
    {
     magic = robot.GetMagic();
     volume = ctm.GetPositionVolume(magic);
    }
    else
     return magic;
   }
  }
 }
 return magic;
}

// �������� ����������� ������� � �������� 
//bool 

