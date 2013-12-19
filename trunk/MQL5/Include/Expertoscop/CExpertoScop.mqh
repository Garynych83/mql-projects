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
   ENUM_TIMEFRAMES ReturnTimeframe(string period_type,string period_size);
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
ENUM_TIMEFRAMES CExpertoscop::ReturnTimeframe(string period_type,string period_size)
 {
  ENUM_TIMEFRAMES period=0;
  //���� "�������"
  if (period_type == "0")
   {
    if (period_size == "1") return PERIOD_M1;
    if (period_size == "2") return PERIOD_M2;
    if (period_size == "3") return PERIOD_M3;
    if (period_size == "4") return PERIOD_M4;
    if (period_size == "5") return PERIOD_M5;
    if (period_size == "6") return PERIOD_M6;
    if (period_size == "10") return PERIOD_M10;
    if (period_size == "12") return PERIOD_M12;  
    if (period_size == "15") return PERIOD_M15;
    if (period_size == "20") return PERIOD_M20;
    if (period_size == "30") return PERIOD_M30;                               
   } 
  //���� "�������"
  if (period_type == "1")
   {
    if (period_size == "1") return PERIOD_H1;
    if (period_size == "2") return PERIOD_H2;
    if (period_size == "3") return PERIOD_H3;
    if (period_size == "4") return PERIOD_H4;
    if (period_size == "6") return PERIOD_H6;  
    if (period_size == "8") return PERIOD_H8;    
    if (period_size == "24") return PERIOD_D1;                                           
   }    
  //���� "���������"
  if (period_type == "2")
    return PERIOD_W1;
  if (period_type == "3")
    return PERIOD_MN1;
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
 int handle=FileOpen(fileHandle,FILE_READ|FILE_COMMON|FILE_ANSI|FILE_TXT,"");
 if(handle!=INVALID_HANDLE)
 {
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
     period = ReturnTimeframe(period_type,period_size ); 
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
  while (!FileIsEnding(handle) && read_flag == true); 
  
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