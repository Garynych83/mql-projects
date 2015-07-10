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
#include <CLog.mqh>  
//#include <CExtrContainer.mgh>

//���������
#define SPREAD 30       // ������ ������ 
#define rat_pos_tp 0.9;
#define rat_pos_give 0.1;


class CTI  // ����� - ������ ��� ��
{
 CArrayObj *robots;                         // ������ ������� �� ��� ��
 ENUM_SIGNAL_FOR_TRADE _moveBUY;            // ���������� �������� �� BUY ��� ����� ��
 ENUM_SIGNAL_FOR_TRADE _moveSELL;           // ���������� �������� �� SeLL ��� ����� ��
  public:
  CTI(){_moveBUY = 0; _moveSELL = 0; robots = new CArrayObj();}
  ~CTI(){delete robots;}
  
  CObject *At(int i){return robots.At(i);}
  int  Total(){return robots.Total();}
  void Add(CBrain *brain);
  void SetMoves(ENUM_SIGNAL_FOR_TRADE moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY);
  ENUM_SIGNAL_FOR_TRADE GetMoveSell(){ return _moveSELL;}
  ENUM_SIGNAL_FOR_TRADE GetMoveBuy(){return _moveBUY;}
};
CTI::Add(CBrain *brain)
{
 robots.Add(brain);
}
CTI::SetMoves(ENUM_SIGNAL_FOR_TRADE moveSELL, ENUM_SIGNAL_FOR_TRADE moveBUY)
{
 _moveSELL = moveSELL;
 _moveBUY = moveBUY;
}


// ---------���������� ������------------------
CExtrContainer    *extr_container;
CContainerBuffers *conbuf; // ����� ����������� �� ��������� ��, ����������� �� OnTick()
                           // highPrice[], lowPrice[], closePrice[] � �.�;            
CRabbitsBrain     *rabbit;

CTradeManager     *ctm;        // �������� ����� 
     
datetime history_start;    // ����� ��� ��������� �������� �������
ENUM_TM_POSITION_TYPE position_type_signal;
int handleDE; 
ENUM_SIGNAL_FOR_TRADE moveSELL;
ENUM_SIGNAL_FOR_TRADE moveBUY;  
double volume_ratio;                       
bool log_flag = false;
ENUM_TM_POSITION_TYPE opBuy, opSell; // ���������
ENUM_TIMEFRAMES TFs[5]    = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M20, PERIOD_M30};//, PERIOD_H4, PERIOD_D1, PERIOD_W1};/

//---------��������� ������� � ���������------------
SPositionInfo pos_info;

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
 handleDE = DoesIndicatorExist(_Symbol, PERIOD_M30, "DrawExtremums");
 if (handleDE == INVALID_HANDLE)
 {
  handleDE = iCustom(_Symbol, PERIOD_M30, "DrawExtremums");
  if (handleDE == INVALID_HANDLE)
  {
   Print("�� ������� ������� ����� ���������� DrawExtremums");
   return (INIT_FAILED);
  }
 }   
 extr_container = new CExtrContainer(handleDE,_Symbol,PERIOD_M30,1000);
 if(!extr_container.Upload()) // ���� �� ���������� ������� ������
  return (INIT_FAILED);
 

 //-----------�������� ������ ������� �� ������� ��----------------
 robots_OLD = new CTI();
              robots_OLD.Add(new  CEvgenysBrain(_Symbol,PERIOD_M30, extr_container, conbuf));
 //-----------�������� ������ ������� �� ������� ��----------------
 robots_MID = new CTI();
              robots_MID.Add(new CChickensBrain(_Symbol,PERIOD_M20, conbuf));
 //-----------�������� ������ ������� �� ������� ��----------------
 robots_JUN = new CTI();
              robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M5, conbuf));
              robots_JUN.Add(new CChickensBrain(_Symbol,PERIOD_M1, conbuf));
              robots_JUN.Add(new CRabbitsBrain(_Symbol, conbuf));
              
 pos_info.volume = 0;

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
 delete robots_OLD;
 delete robots_MID;
 delete robots_JUN;
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
 log_file.Write(LOG_DEBUG, "\n-------------------------MoveDown------------------------------------");
 MoveDown(robots_OLD);
 log_file.Write(LOG_DEBUG, "--------------------------MoveUp------------------------------------");
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
 //-----------
 robot = robots.At(0);
 log_file.Write(LOG_DEBUG, StringFormat("MoveDown: --- ������ �� �� = %s", PeriodToString(robot.GetPeriod())));
 //-----------
 double vol_tp, vol_give;                       
 FillMoves(robots);    // ���������� ����������� �������� �������� ���������� ���������
 // ���� �� ������� �� ���� �������� �������
 if(robots.GetMoveBuy() != 0||robots.GetMoveSell() != 0)
 {
  log_file.Write(LOG_DEBUG, StringFormat("��� �������� ������ moveBUY = %d moveSELL = %d",robots.GetMoveBuy(),robots.GetMoveSell()));
  volume_ratio = CountTradeRate(robots);   // ��������� ���������� ��� ������� �� �� (��� ������� = 0)         

  // ��� ������� ������ �� ���� ��
  for(int i = 0; i < robots.Total(); i++)
  {
   robot = robots.At(i);
   // �������� �������� ������ �� ��������� ������ � �������� ��� ������� ���� ��� ����
   position_type_signal = robot.GetSignal();
   // ���� ������ ������ �� �������� ������� 
   if(position_type_signal != OP_UNKNOWN)
   {
    log_file.Write(LOG_DEBUG, StringFormat("��� �������� ������ %d �� ������(%s)",position_type_signal, robot.GetName()));
    // ������� �������, � �������� ����� ������ �� ����������� SELL/BUY
    // �������� �������
    if((position_type_signal == OP_SELL || position_type_signal == OP_SELLSTOP) && robots.GetMoveSell() == SELL) // ���� ���� ���������� � �������� �� �� �������� � ���� �����������
    {
     log_file.Write(LOG_DEBUG,StringFormat("������ �� SELL position_type_signal  = %d",position_type_signal));
     pos_info.type = position_type_signal;  // ��� ������ ���������� �������� ������
     pos_info.tp   = robot.CountTakeProfit();
     pos_info.sl   = robot.CountStopLoss();
     pos_info.volume = 1 * volume_ratio;
    }
    else if((position_type_signal == OP_BUY || position_type_signal == OP_BUYSTOP) && robots.GetMoveBuy() == BUY)
    {
     log_file.Write(LOG_DEBUG,StringFormat("������ �� BUY position_type_signal  = %d", position_type_signal));
     pos_info.type = position_type_signal;  // ��� ������ ���������� �������� ������
     pos_info.tp   = robot.CountTakeProfit();
     pos_info.sl   = robot.CountStopLoss();
     pos_info.volume = 1 * volume_ratio;
     
    }
    else
     continue;
    // ? <�������� �������>
    log_flag = true;
    ctm.OpenPairPosition(_Symbol, robot.GetPeriod(), pos_info, trailing, volume_ratio);
    // ������ �������� ����� �������, ��� �� ����� ��� ������� ������ ��� ��� ������� � ����� �����������, 
    // �� ���� ��� ���������� ������ ��� ���� ������� ���� �� �����������
   }
   else if (position_type_signal == OP_UNKNOWN && robot.GetDirection() == NO_SIGNAL&&log_flag)// ������ �������
   {
    log_file.Write(LOG_DEBUG, "������ �������, �������� �������: position_type_signal == OP_UNKNOWN && robot.GetDirection() == NO_SIGNAL");
    // ������� ������� � �������� ����� ������
    //if(ctm.
    //ctm.ClosePosition(robot.GetMagic()); // ���������, ���
   }
  }
 }
 if(robots != robots_JUN)
  MoveDown(GetNextTI(robots,true));
}

void MoveUp (CTI *robots)
{
 //-----------
 robot = robots.At(0);
 log_file.Write(LOG_DEBUG, StringFormat("MoveUp: --- ������ �� �� = %s", PeriodToString(robot.GetPeriod())));
 //-----------
 for(int i = 0; i < robots.Total(); i++) 
 {
  robot = robots.At(i); // ��� ������� ������ �� ��
  // ���� ��� ������� ���������� � �������
  int positionCount = ctm.GetPositionCount(robot.GetMagic());
  if(positionCount <= 0 && log_flag) // ���� � ��� �� �� ��������� �������, �� pos_give ������ ������������ �� ��. �����
  {
   log_file.Write(LOG_DEBUG, StringFormat("� ����� ������(%s) ��� �������� �������", robot.GetName()));
  }
  else if(positionCount == 1) // ��� ������ ��� �������� ������ pos_give
  { 
   double vol = ctm.GetPositionVolume(_Symbol, robot.GetMagic());
   log_file.Write(LOG_DEBUG, StringFormat("� ����� ������(%s) ���� �������� �������(������ give) vol = ", robot.GetName(), vol));
   long magicEld = ChooseTheBrain(ctm.GetPositionType(),GetNextTI(robots,false));
   log_file.Write(LOG_DEBUG, StringFormat("��������� ������� ������ ������ � magic =  � ������� ������� �� �������", magicEld));
   OpenPosition(magicEld, vol); // �������� ������� �� ������� ���������� ������
  }
  else if (positionCount == 2 && log_flag)  // ������� - ������� ��� ����
  {
   long magicEld = ChooseTheBrain(ctm.GetPositionType(),GetNextTI(robots,false));
   for(int i = 0; i < ctm.GetPositionCount() && magicEld != 0; i++)
   {
    ctm.PositionSelect(i, SELECT_BY_POS);
    if(ctm.GetPositionMagic() == robot.GetMagic())
    {
     if(ctm.GetPositionTakeProfit() != 0)
        log_file.Write(LOG_DEBUG, StringFormat("� ������ (%d)  ���������� 2 ������� ����:  �������� (profit) %f", robot.GetMagic(), ctm.GetPositionTakeProfit()));
     else
        log_file.Write(LOG_DEBUG, StringFormat("� ������ (%d)  ���������� 2 ������� ������:  �������� (profit) %f", robot.GetMagic(), ctm.GetPositionTakeProfit()));
    }
   }
  }
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

CTI *GetNextTI(CTI *robots, bool down)
{
 CBrain *robot = robots.At(0); 
 ENUM_TIMEFRAMES period = robot.GetPeriod();

 if(period >= PERIOD_M30)
  return down ? robots_MID  :  robots_OLD;
 if(period > PERIOD_M15 && period < PERIOD_M30)
  return down ? robots_JUN  :  robots_OLD;
 if(period <= PERIOD_M15)
  return down ? robots_JUN  :  robots_MID;
  
 return robots_JUN;  
}

void FillMoves(CTI *robots)
{
 ENUM_SIGNAL_FOR_TRADE newMoveSELL = NO_SIGNAL;
 ENUM_SIGNAL_FOR_TRADE newMoveBUY = NO_SIGNAL;
 ENUM_SIGNAL_FOR_TRADE moveSELL = SELL;
 ENUM_SIGNAL_FOR_TRADE moveBUY = BUY;
 // ���� ��� ������� �� ��� ��������� ��������� ������� �� ����� ��������
 if(robots == robots_OLD)// ��������� ��-������� ������ ������ ��������������� �� ������� ������
 {
  moveSELL = SELL; // ����������� ������ ��� �������� �� (������ 1)
  moveBUY = BUY;
  //------
  newMoveSELL = SELL;
  newMoveBUY = BUY;
 } 
 else
 {
  CTI *ElderTI;
  ElderTI = GetNextTI(robots, false);
  moveSELL = ElderTI.GetMoveSell();
  moveBUY = ElderTI.GetMoveBuy();
  log_file.Write(LOG_DEBUG, StringFormat("������ �� �� �������� ������: moveSEL = %d, MoveBUY = %d", moveSELL, moveBUY));
 } 

 for(int i = 0; i < robots.Total(); i++)      
 { 
  robot = robots.At(i); 
  //log_file.Write(LOG_DEBUG, StringFormat("��� ����� ��(%s) robot.GetDirection() = %d",robot.GetName(), robot.GetDirection()));                      
  if(robot.GetDirection() == SELL && moveSELL == SELL)            
   newMoveSELL = SELL;
  else if(robot.GetDirection() == BUY && moveBUY == BUY)
   newMoveBUY = BUY;
 }  
 robots.SetMoves(newMoveSELL, newMoveBUY);
 return;
}

double CountTradeRate(CTI *robots)
{
  CBrain *robot = robots.At(0);
 if(robot.GetPeriod() > PERIOD_M15)
  return 0.0;
 else
  return 0.9;
}



long ChooseTheBrain(ENUM_TM_POSITION_TYPE pos_type, CTI *robots) 
{
 double volume = 0;
 robot = robots.At(0);
 int type = pos_type % 2;
 int magic =  robot.GetMagic();  
 for(int i = 0; i < robots.Total(); i++)
 {
  robot = robots.At(i);
  if(ctm.GetPositionCount(magic) == 2)// ���� �� 2, ����� �� ����� ����������� � �������� ������� �����
  {
   if(ctm.GetPositionType(magic) % 2 == type && ctm.GetPositionType(magic) != OP_UNKNOWN) 
   {
    if(ctm.GetPositionVolume(magic) >= volume)
    {
     magic = robot.GetMagic();
     volume = ctm.GetPositionVolume(magic);
     log_file.Write(LOG_DEBUG, StringFormat("%s ������� ������, ������� ����� - %s, magic = ", robot.GetName(), magic));
    }
    else
     return magic;
   }
  }
 }
 return magic;
}

void OpenPosition(long magicEld, double vol)
{ 
 double temp;
 for(int i = 0; i < ctm.GetPositionCount() && magicEld != 0; i++)
 {
  ctm.PositionSelect(i, SELECT_BY_POS);
  if(ctm.GetPositionMagic() == magicEld)
  {
   if(ctm.GetPositionTakeProfit() != 0)
   {
    temp = vol * volume_ratio;
    ctm.PositionChangeSize(temp);
   }
   else
   {
    temp = vol * (1-volume_ratio);
    ctm.PositionChangeSize(temp);
   }
  }
 }
 return;
}
// �������� ����������� ������� � �������� 
//bool 

