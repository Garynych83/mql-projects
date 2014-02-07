//+------------------------------------------------------------------+
//| ������ ��������� Unix time � ������ �������������� ���������     |
//+------------------------------------------------------------------+

 var N_DAYS = new Array // ������ ���� ���� � ����� ��  4-� �����
 (
  31,59,90,120,151,181,212,243,273,304,334,365,
  396,424,455,485,516,546,577,608,638,669,699,730,
  761,790,821,851,882,912,943,974,1004,1035,1065,1096,
  1127,1155,1186,1216,1247,1277,1308,1339,1369,1400,1430,1461 
 );

   var _4years_days = 1461;  // ���������� ���� � ������ 4-� ����� (������ �������� �� ����� �����������)


   // ��������� ���� 
   var _year;     // ���
   var _month;    // �����
   var _day;      // ����
   var _hours;    // ���
   var _minutes;  // ������
   var _seconds;  // �������

 // ���������� ��� ���������� �������� ��������� ������� (�������, �������)

   var _max_balance,_min_balance;
   var _start_time, _finish_time;
   var _balance_range,_time_range;

 //��� ������� ����� ��� �������
 function div(val, by)
  {
   return (val - val % by) / by;
  } 


 //���������� ����� � ���� ������
 function GetN4Years(last_days)
  {
	var index;   // ������� �� �����
	for (index=0;index<48;index++)
	{
	  if (N_DAYS[index] >= last_days)
           return index;
	}
   return 0;
  }

 //���������� ����� � ���� ������
 function   ConvertUnixToTime (unix_time)
  {
	var tmp;
	// �������� ���������� �����
	_minutes = div(unix_time, 60);
	// �������� ��������� ���������� ���������� ������
	_seconds = unix_time % 60;
	// �������� ���������� �����
	_hours   = div(_minutes , 60);
	// �������� ��������� ���������� ���������� �����
	_minutes = _minutes % 60;
	// �������� ���������� ����
	_day     = div(_hours , 24);
	// �������� ��������� ���������� ���������� �����
	_hours   =  _hours % 24;
	// �������� ���������� ����� �� 4-� �����
	_year    =  (div(_day , _4years_days) )*4+1970;
	// �������� �����, ���� � ������������ ���
	tmp      =  GetN4Years(_day % _4years_days);
	// ������������ ���
	_year    =  _year + div(tmp , 12);
	// ��������� �����
	_month   =  1 + tmp % 12;
	// ��������� ����
	if (tmp > 0)
	_day     =  _day % _4years_days - N_DAYS[tmp-1] + 1;
	else
        _day     =  _day % _4years_days + 1;

  }

 // ������� ��������� unix ����� � ������ �������������� ��������� � ���� ������
function   TimeToString (unix_time)
 {
   var returned_str="";
   ConvertUnixToTime (unix_time);
   if (_day < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _day+".";
   if (_month < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _month+".";
   returned_str = returned_str + _year+" "; 
   if (_hours < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _hours+":";
   if (_minutes < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _minutes+":";
   if (_seconds < 10)
    returned_str = returned_str + "0";
   returned_str = returned_str + _seconds+"";
  return returned_str;
   
 }
 
 // ������� �������� �������� ������� � ������� � ������� ��������� �������
function GetPoints() 
 {
  var x=event.x,y=event.y;
  var value_balance;
  var value_time; 
  if (y >= 20 && y <= 306 && x >= 0 && x <= 688) 
    { 
     value_balance = _min_balance + (286-y+20)/286*_balance_range;
     value_time    = _start_time  + Math.floor( x/688*_time_range );
     graph.alt = '������: '+ value_balance.toFixed(6)+'\n�����: '+ TimeToString(value_time); 
    } 
  }


//---- ������� ��� �������� ������� 
function     OnLoad (max_balance,min_balance,start_time,finish_time)
 {
  _max_balance   = max_balance;
  _min_balance   = min_balance;
  _start_time    = start_time;
  _finish_time   = finish_time;
  _balance_range = max_balance-min_balance;
  _time_range    = finish_time-start_time;

 }