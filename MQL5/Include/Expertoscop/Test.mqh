//+------------------------------------------------------------------+
//|                                                  Expertoscop.mq4 |
//|                                                              GIA |
//|                                     http://www.rogerssignals.com |
//+------------------------------------------------------------------+
#property copyright "GIA"

 
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
   // ����� ������� ����������
   uint   param_length;
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
//| ������ ������ � �������                                          |
//+------------------------------------------------------------------+
   // ����� ������ ������ �� ����� (�������� ������� MQL FileReadString )
   string          ReadString(int handle); 
   
//+------------------------------------------------------------------+
//| ������� ������                                                   |
//+------------------------------------------------------------------+
   
   // ����� ��������� ����� ������� ����������
   uint GetParamLength (){ return (/*param_length*/ArraySize(param)); };
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
    param_length = 0;
   };
   // ���������� ������
   ~CExpertoscop()
   {
    // ������� ������������ ������
    ArrayFree(param);
   };
 };

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
 bool flag;
 int cnt, pos;
 //���������� ��� �������� ������ �����
 string word, symbol;
 ENUM_TIMEFRAMES period;
 string ch = " ";
 int count;
 Print("������ ����� ����� = ",filename+fileHandle);
 int handle=FileOpen(fileHandle,FILE_READ|FILE_COMMON|FILE_ANSI|FILE_TXT,"");
 Alert("FILE HANDLE = ",fileHandle);
 if(handle!=INVALID_HANDLE)
 {
  Print("�������� ����� ����� ,���",filename+fileHandle);
  // ������������� ��������� � �������� ����� 
  FileSeek (handle,0,0);
  fileContain = "";
  count = 0;
  // ������ ��������� �� �����
  do
  {
   fileContain = fileContain + ch;
   count++;
   ch = FileReadString(handle,-1);
   Print("���� = ",ch);
  }
  while (/*handle!=INVALID_HANDLE*/count<1);
  
  Alert("���� �������� = ",fileContain);
  // ��������� ����
  FileClose(handle);                  
 }
 pos = 0; flag = false;
 symbol="";
 //period="";
 // �� ����� ����������� �����
 for(cnt = 0; cnt < StringLen(fileContain); cnt++)
 {
  if(StringGetCharacter(fileContain, cnt)==13) // ������� ������ (Enter), ����� �� ����� ������
  {
   // ����� ������
   word = StringSubstr(fileContain, pos, cnt - pos); 
   // �������� ��� �������
   if(StringFind(word, "symbol=") != -1 && cnt != pos && symbol == "") symbol = StringSubstr(word, 7); 
   // �������� ������
   //if(StringFind(word, "period=") != -1 && cnt != pos && period == "") period = StringSubstr(word, 7);  
   
   if(StringFind(word, "</window>") != -1 && cnt != pos) flag = true; 
   if(StringFind(word, "<expert>") != -1 && cnt != pos && flag)
   {
    
    ArrayResize(param, ++param_length);
    // �� ����� ����������� ����� ����� ���� <expert>
    for(cnt = cnt; cnt < StringLen(fileContain); cnt++) 
    {
     if(StringGetCharacter(fileContain, cnt) == 13)
     {
      word = StringSubstr(fileContain, pos, cnt-pos);
      if(StringSubstr(word, 0, 4) == "name")
      {
       int basa[];
       param[param_length - 1].expert_name = StringSubstr(word, 5); // ��� �������� 
       param[param_length - 1].symbol = symbol;
       //param[expNumber - 1].period = period;
      }
     }
    }
    break;   
   }
   pos=cnt+2;
  }
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