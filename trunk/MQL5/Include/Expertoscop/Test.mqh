//+------------------------------------------------------------------+
//|                                                  Expertoscop.mq4 |
//|                                                              GIA |
//|                                     http://www.rogerssignals.com |
//+------------------------------------------------------------------+
#property copyright "GIA"
#include <StringUtilities.mqh>  // ���������� ���������� ��������

 
#import "kernel32.dll"
   int  FindFirstFileW(string path, int& answer[]);
   bool FindNextFileW(int handle, int& answer[]);
   bool FindClose(int handle);
   int _lopen  (string path, int of);
   int _llseek (int handle, int offset, int origin);
   int _lread  (int handle, string fileContain, int bytes);
   int _lclose (int handle);
#import


//+------------------------------------------------------------------+
//| ��������� ����������                                             |
//+------------------------------------------------------------------+
 
struct ExpertoScopParams
 {
  string expert_name;
  string symbol;
  ENUM_TIMEFRAMES period;
 };
 
//+------------------------------------------------------------------+
//| ����� �������������                                              |
//+------------------------------------------------------------------+

class CExpertoscop
 {
 
  private:
   // ������ ���������� 
   ExpertoScopParams param[];
   // ������ ������� ����������
   uint params_size;
   string filename; 
  public:
  
//+------------------------------------------------------------------+
//| Get ������                                                       |
//+------------------------------------------------------------------+
   
   // ����� ��������� ����� �������� 
   string          GetExpertName(uint num){ return (param[num].expert_name ); };
   // ����� ��������� �������
   string          GetSymbol(uint num){ return (param[num].symbol); };
   // ����� ��������� ����������
   ENUM_TIMEFRAMES GetTimeFrame(uint num){ return (param[num].period); };

//+------------------------------------------------------------------+
//| ������ ������ � ��������� �������                                |
//+------------------------------------------------------------------+
   // ����� ������ ������ �� ����� (�������� ������� MQL FileReadString )
   string          ReadString(int handle); 
   // ����� ��������� ��������� �� ��������� �� ����� ������
   ENUM_TIMEFRAMES ReturnTimeframe(int period_type,int period_size);
//+------------------------------------------------------------------+
//| ������� ������                                                   |
//+------------------------------------------------------------------+
   
   // ����� ��������� ����� ������� ����������
   uint GetParamLength (){ return (ArraySize(param)); };
   // ����� ��������� ���� �������� ������������ - ��������� aFilesHandle �������� ������
   void DoExpertoScop();
   // ����� ��������� ���������� ��������
   void GetExpertParams(string fileHandle);
   // ����������� ������
   CExpertoscop()
   {
    double ArBuffer[1] = {0}; // ����� ��� ������ ��� ������.
     int    ArOutputByte[1]; 
    // ��������� ����� �����
    //StringConcatenate(filename, TerminalInfoString(TERMINAL_PATH),"\\profiles\\charts\\default\\");
    StringConcatenate(filename,"","C:\\Users\\����\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\");    
    // �������� ����� ������� ����������
    params_size = 0;
   };
   // ���������� ������
   ~CExpertoscop()
   {
    // ������� ������������ ������
    ArrayFree(param);
   };
 };
 

//+------------------------------------------------------------------+
//| ������ ������ � ��������� �������                                |
//+------------------------------------------------------------------+ 

// ����� ������������ ���������� �� ��������� �� ����� ������
ENUM_TIMEFRAMES CExpertoscop::ReturnTimeframe(int period_type,int period_size)
 {
  ENUM_TIMEFRAMES period=0;
  //������ ������ �������� ����������
  string aPeriod_type[4]=
   {
    "M",
    "H",
    "W",
    "MN"
   };
  // ���� "�������"
 // if (period_size == 24)
  // period = StringTo
  return period;
 }
 
//+------------------------------------------------------------------+
//| ������� ������                                                   |
//+------------------------------------------------------------------+

// ����� ��������� ���� �������� ������������ 
void CExpertoscop::DoExpertoScop()
{
 int win32_DATA[79];
 int handle;
 //��������� ����  
 ArrayInitialize(win32_DATA,0); 
 handle = FindFirstFileW(filename+"*.chr", win32_DATA);
 if(handle!=-1)
 {
  GetExpertParams(bufferToString(win32_DATA));  //�������� ��������� �������� �� �����
  ArrayInitialize(win32_DATA,0);
 // ��������� ��������� �����
 while(FindNextFileW(handle, win32_DATA))
 {
  GetExpertParams(bufferToString(win32_DATA));
  ArrayInitialize(win32_DATA,0);
 }
 if (handle > 0) FindClose(handle);
 }
}

//����� �������� ���������� �� �����
void CExpertoscop::GetExpertParams(string fileHandle)
{
 // ���� ������ ���� <expert>
 bool found_expert = false;
 // ���� ����������� ������ �����
 bool read_flag    = true;
 // ���������� ��� �������� �������
 string symbol;
 // ��� ����������
 string period_type;
 // ������ �������
 string period_size;
 // ������ 
 ENUM_TIMEFRAMES period;
 // ������ �����
 string str = " ";
 Print("������ ����� ����� = ",filename+fileHandle);
 int handle=FileOpen(fileHandle,FILE_READ|FILE_COMMON|FILE_ANSI|FILE_TXT,"");
 Alert("FILE HANDLE = ",fileHandle);
 if(handle!=INVALID_HANDLE)
 {
  Print("�������� ����� ����� ,���",filename+fileHandle);
  // ������������� ��������� � �������� ����� 
  FileSeek (handle,0,0);
  // ������ ������ �� ����� � ������������ ��
  do
  {
   // ��������� ������
   str = FileReadString(handle,-1);
   // ��������� �� ������ 
   if (StringFind(str, "symbol=")!=-1) symbol=StringSubstr(str, 7, -1);    
   // ��������� ��� ����������
   if (StringFind(str, "period_type=")!=-1) period_type=StringSubstr(str, 12, -1);    
   // ��������� ������ ����������
   if (StringFind(str, "period_size=")!=-1)
    {
     period_size=StringSubstr(str, 12, -1);
     period = ReturnTimeframe(StringToInteger(period_type),StringToInteger(period_size) ); 
    }         
   // ��������� ��� <expert>
   if (StringFind(str, "<expert>")!=-1 && found_expert==false)
     found_expert = true;
   // ��������� ��� ��������
   if (StringFind(str, "name=")!=-1 && found_expert == true)
     {
      //����� ��� ������, ������ ��������� �� 
      params_size++; //����������� ������ ���������� �� �������
      ArrayResize(param,params_size); //����������� ������ �� �������
      param[params_size-1].expert_name = StringSubstr(str, 5, -1); // ��������� ��� ��������
      param[params_size-1].period      = period;                   // ��������� ������
      param[params_size-1].symbol      = symbol;                   // ��������� ������
      read_flag = false; 
     }
      
  }
  while (!FileIsEnding(handle) && read_flag); 
  
  // ��������� ����
  FileClose(handle);                  
 }

}
  
//+------------------------------------------------------------------+
//|  ������� ����� �� ������                                         |
//+------------------------------------------------------------------+ 
string bufferToString(int &fileContain[])
   {
   string text="";
   
   int pos = 10;
   for (int i = 0; i < 64; i++)
      {
      pos++;
      int curr = fileContain[pos];
      text = text + CharToString(curr & 0x000000FF)
         +CharToString(curr >> 8 & 0x000000FF)
         +CharToString(curr >> 16 & 0x000000FF)
         +CharToString(curr >> 24 & 0x000000FF);
      }
   return (text);
   }  
//+------------------------------------------------------------------+
bool DecToBin(int dec)
   {
   int ch = 0, x = 3;
   bool res;
   dec-=3;
   while(x > 0)
      {
      ch = MathMod(dec,2);
      dec = MathFloor(dec/2);
      x--;
      }
   if(ch==0)res=false; else res=true;   
   return(res);
   }