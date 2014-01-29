//+------------------------------------------------------------------+
//|                                                     kernel32.mqh |
//|                        Copyright 2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2013, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

//+------------------------------------------------------------------+
//| ���������� Kernel32 �������                                      | 
//+------------------------------------------------------------------+

#import "kernel32.dll"

  bool CloseHandle                // �������� �������
       ( int hObject );                  // ����� �������
       
  int CreateFileW                 // �������� �������� �������
      ( string lpFileName,               // ������ ���� ������� � �������
        int    dwDesiredAccess,          // ��� ������� � �������
        int    dwShareMode,              // ����� ������ �������
        int    lpSecurityAttributes,     // ��������� ������������
        int    dwCreationDisposition,    // ��������� ��������
        int    dwFlagsAndAttributes,     // ����� ����������
        int    hTemplateFile );      
          
  bool WriteFile                  // ������ ������ � ����
       ( int    hFile,                   // handle to file to write to
         char    &dBuffer[],             // pointer to data to write to file
         int    nNumberOfBytesToWrite,   // number of bytes to write
         int&   lpNumberOfBytesWritten[],// pointer to number of bytes written
         int    lpOverlapped );          // pointer to structure needed for overlapped I/O   
        
  bool ReadFile                   // ������ ������ �� �����
       ( int    hFile,                 // handle of file to read
         char    &lpBuffer[],              // address of buffer that receives data 
         int    nNumberOfBytesToRead,  // number of bytes to read
         int&   lpNumberOfBytesRead[], // address of number of bytes read
         int    lpOverlapped );        // address of structure for data              
  
  int  RtlGetLastWin32Error();
  int  WinExec(uchar &NameEx[], int dwFlags);  // ��������� ���������� BackTest
    
#import

// ��� ������� � �������
#define _GENERIC_READ_       0x80000000
#define _GENERIC_WRITE_      0x40000000
// ����� ������ �������
#define _FILE_SHARE_READ_    0x00000001
#define _FILE_SHARE_WRITE_   0x00000002
// ��������� ��������
#define _OPEN_EXISTING_      3
#define _CREATE_ALWAYS_      2