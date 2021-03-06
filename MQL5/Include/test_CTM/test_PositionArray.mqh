//+------------------------------------------------------------------+
//|                                            VirtualOrderArray.mqh |
//|                                     Copyright Paul Hampton-Smith |
//|                            http://paulsfxrandomwalk.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Paul Hampton-Smith"
#property link      "http://paulsfxrandomwalk.blogspot.com"

#include <TradeManager\TradeManagerConfig.mqh>
//#include "Log.mqh"
#include <TradeManager\TradeManagerEnums.mqh>
#include "test_Position.mqh"
#include <Arrays/ArrayObj.mqh>
#include <StringUtilities.mqh>
//+------------------------------------------------------------------+
/// Stores an array of virtual orders.
//+------------------------------------------------------------------+
class test_CPositionArray : public CArrayObj
  {
private:
   string            m_strPersistFilename;

public:
   test_CPositionArray();
   test_CPosition    *AtTicket(long lTicket);
   int               OpenLots(string strSymbol);
   /// Count of orders.
   int               OrderCount(string strSymbol,long lMagic);
   int               OrderCount(string strSymbol,ENUM_TM_POSITION_TYPE eOrderType,long lMagic);
   string            PersistFilename(){return(m_strPersistFilename);}
   string            PersistFilename(string strFilename);
   int               TicketToIndex(long lTicket);
   bool              ReadFromFile(bool bCreateLineObjects=true);
   void              ReadAllVomOpenOrders(string strFolder);
   bool              WriteToFile();
   string            SummaryList();
   void              Clear(const long nMagic);
   void              Clear(const string strSymbol);
   test_CPosition    *Position(int nIndex){return((test_CPosition*)CArrayObj::At(nIndex));}

  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
test_CPositionArray::test_CPositionArray()
  {
   m_strPersistFilename="";
  }
//+------------------------------------------------------------------+
/// Searches for and returns the Position which matches ticket.
/// \param [in]	lTicket	Order ticket
/// \return						test_CPosition handle, or NULL if not found
//+------------------------------------------------------------------+
test_CPosition *test_CPositionArray::AtTicket(long lTicket)
  {
   for(int i=Total()-1;i>=0;i--)
     {
      test_CPosition *pos=Position(i);
      if(pos.getPositionTicket()==lTicket)
        {
         //LogFile.Log(LOG_VERBOSE,__FUNCTION__,StringFormat("(%d) returning valid test_CPosition",lTicket));
         return(pos);
        }
     }
   //LogFile.Log(LOG_PRINT,__FUNCTION__,StringFormat("(%d) error: could not find a valid test_CPosition",lTicket));
   return(NULL);
  }
//+------------------------------------------------------------------+
/// Returns positive lots if total virtual position is long and negative lots if short.
/// \param [in]   strSymbol   Symbol
/// \return       +/-Lots * 1000                                                                  |
//+------------------------------------------------------------------+
int test_CPositionArray::OpenLots(string strSymbol)
  {
   double dblTotalPosition=0.0;
   for(int i=Total()-1;i>=0;i--)
     {
      test_CPosition *pos=Position(i);
      if(pos.getSymbol()==strSymbol)
         switch(pos.getType())
           {
            case OP_BUY:
               dblTotalPosition+=pos.getVolume(); break;
            case OP_SELL:
               dblTotalPosition-=pos.getVolume();
           }
     }
   int nTotalPosition=(int)MathRound(dblTotalPosition*1000.0);
   //LogFile.Log(LOG_VERBOSE,__FUNCTION__,StringFormat("(%s) returning %d",strSymbol,nTotalPosition));
   return(nTotalPosition);
  }
//+------------------------------------------------------------------+
/// Count of orders.
/// \param [in] strSymbol
/// \param [in] nMagic
/// \return	Count of orders matching input criteria
//+------------------------------------------------------------------+
int test_CPositionArray::OrderCount(string strSymbol,long lMagic)
  {
   int nOrdersTotal=0;
   for(int i=Total()-1;i>=0;i--)
     {
      test_CPosition *pos=Position(i);
      if(pos.getMagic()==lMagic)
         if(pos.getSymbol()==strSymbol)
            nOrdersTotal++;
     }
   return(nOrdersTotal);
  }
//+------------------------------------------------------------------+
/// Count of orders of a certain type.
/// \param [in] strSymbol
/// \param [in] nMagic
/// \return	Count of orders matching input criteria
//+------------------------------------------------------------------+
int test_CPositionArray::OrderCount(string strSymbol, ENUM_TM_POSITION_TYPE eOrderType,long lMagic)
  {
   int nOrdersTotal=0;
   for(int i=Total()-1;i>=0;i--)
     {
      test_CPosition *pos=Position(i);
      if(pos.getMagic()==lMagic)
         if(pos.getType()==eOrderType)
            if(pos.getSymbol()==strSymbol)
               nOrdersTotal++;
     }
   return(nOrdersTotal);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string test_CPositionArray::PersistFilename(string strFilename)
  {
// need to start with a fresh file for every test
   if(MQL5InfoInteger(MQL5_TESTING) || MQL5InfoInteger(MQL5_OPTIMIZATION) || MQL5InfoInteger(MQL5_VISUAL_MODE))
      FileDelete(strFilename);

   return(m_strPersistFilename=strFilename);
  }
/*  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void test_CPositionArray::ReadAllVomOpenOrders(string strFolder)
  {
   Clear();
   string strFilenameWildcard=strFolder+"*_OpenOrders.csv";
   string strFoundFile="";

   long hFind=FileFindFirst(strFilenameWildcard,strFoundFile);
   if(hFind!=INVALID_HANDLE)
     {
      do
        {
         PersistFilename(strFolder+strFoundFile);
         // read without creating line objects
         ReadFromFile(false);
        }
      while(FileFindNext(hFind,strFoundFile));
      FileFindClose(hFind);
     }
  }
 
//+------------------------------------------------------------------+
/// Reads array contents from PersistFilename()
//+------------------------------------------------------------------+
bool test_CPositionArray::ReadFromFile(bool bCreateLineObjects=true)
  {
   if(!FileIsExist(PersistFilename()))
     {
      //LogFile.Log(LOG_VERBOSE,__FUNCTION__," warning: file "+PersistFilename()+" does not exist yet - assume zero orders");
      return(true);
     }

   int handle=-1;
   int nRepeatCount=Config.FileAccessRetries;
   while((handle=FileOpen(PersistFilename(),FILE_READ|FILE_CSV,Config.VirtualOrdersFileCsvDelimiter))<=0 && nRepeatCount>0)
     {
      Sleep(Config.FileAccessSleep_mSec);
      nRepeatCount--;
      //LogFile.Log(LOG_DEBUG,__FUNCTION__," retrying #"+(string)nRepeatCount);
     }

   if(handle<=0)
     {
      //LogFile.Log(LOG_PRINT,__FUNCTION__," error: "+ErrorDescription(::GetLastError())+" opening "+PersistFilename());
      return(false);
     }

// clear off header
   while(!FileIsLineEnding(handle)) FileReadString(handle);

   while(!FileIsEnding(handle))
     {
      test_CPosition *pos=new test_CPosition;
      // only add orders that don't already exist in the array
      if(pos.ReadFromFile(handle))
        {
         if(TicketToIndex(pos.getPositionTicket())==-1)
           {
            Add(pos);
           }
         else
           {
            delete pos;
           }
        }
     }
   FileClose(handle);
   //LogFile.Log(LOG_DEBUG,__FUNCTION__," successful reading from "+PersistFilename());
   return(true);
  }*/
//+------------------------------------------------------------------+
/// Searches for and returns the index of the Position which matches ticket.
/// \param [in]	lTicket	Order ticket
/// \return						Index, or -1 if not found
//+------------------------------------------------------------------+
int test_CPositionArray::TicketToIndex(long lTicket)
  {
   for(int i=Total()-1;i>=0;i--)
     {
      test_CPosition *pos=Position(i);
      //LogFile.Log(LOG_VERBOSE,__FUNCTION__,StringFormat("(%d) looking at open virtual order #%d",lTicket,pos.Ticket()));
      if(pos.getPositionTicket()==lTicket)
        {
         //LogFile.Log(LOG_VERBOSE,__FUNCTION__,StringFormat("(%d) returning %d",lTicket,i));
         return(i);
        }
     }
   //LogFile.Log(LOG_DEBUG,__FUNCTION__,StringFormat("(%d) warning: ticket not found, returning -1",lTicket));
   return(-1);
  }
//+------------------------------------------------------------------+
/// Saves array contents to PersistFilename()
//+------------------------------------------------------------------+
bool test_CPositionArray::WriteToFile()
  {
   int handle=-1;
   int nRepeatCount=Config.FileAccessRetries;
   while((handle=FileOpen(PersistFilename(),FILE_CSV|FILE_WRITE,Config.VirtualOrdersFileCsvDelimiter))<=0 && nRepeatCount>0)
     {
      Sleep(Config.FileAccessSleep_mSec);
      nRepeatCount--;
      //LogFile.Log(LOG_DEBUG,__FUNCTION__," retrying #"+(string)nRepeatCount);
     }

   if(handle<=0)
     {
      //LogFile.Log(LOG_PRINT,__FUNCTION__," error: "+ErrorDescription(::GetLastError())+" opening "+PersistFilename());
      return(false);
     }

   test_CPosition *tmp;
   //tmp.WriteToFile(handle,true);
   for(int i=0;i<Total();i++)
     {
      //Position(i).WriteToFile(handle, false);
     }
   FileClose(handle);
   //LogFile.Log(LOG_DEBUG,__FUNCTION__," successful writing to "+PersistFilename());
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string test_CPositionArray::SummaryList()
  {/*
   string strSummary; StringInit(strSummary);
   for(int i=0;i<Total();i++)
     {
      strSummary=strSummary+Position(i).SummaryString()+"\n";
     }
   return(strSummary);*/
   return("");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void test_CPositionArray::Clear(const long nMagic)
  {
   for(int i=Total()-1;i>=0;i--)
     {
      test_CPosition *pos=Position(i);
      if(pos.getMagic()==nMagic) Delete(i);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void test_CPositionArray::Clear(const string strSymbol)
  {
   for(int i=Total()-1;i>=0;i--)
     {
      test_CPosition *pos=Position(i);
      if(pos.getSymbol()==strSymbol) Delete(i);
     }
  }
//+------------------------------------------------------------------+
