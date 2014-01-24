#pragma once

#include<stdio.h>
#include <string>

#ifndef BACKTEST
#define BACKTEST


// �������� ������� ��� �������� �����
typedef struct point
 {
  double value;        // �������� � �����
  struct point * next; // ��������� �� ��������� �������
 }Point;

// ��������� �� ������ �������
Point * root = NULL;
// ��������� �� ��������� ������� �������
Point * current;
// ��������� ����������� ��������
int graphW = 688; // ������ ����������� ������� � ��������
int graphH = 286; // ������ ����������� ������� � ��������
int n_positions; // ���������� ������� (�����) �������
double top_value = -100.0 ; // ������������ ��������
double low_value = 100.0 ;   // ����������� ��������
double range;        // ������ � ������� �� low �� top
double rangeX;       // ������ ���������� ������� �� �
// ��������� ��������
int    n_win_pos;      // ����� ���������� �������
int    n_lose_pos;     // ����� ��������� �������
int    sign_last_pos;  // ���� ��������� �������
float  max_win_pos;    // ������������ ���������� �������
float  min_lose_pos;   // ����������� ��������� �������
float  max_profit;     // ������������ ����������� �������
float  max_lose;       // ������������ ����������� ������
int    max_n_win;      // ������������ ���������� ������ ������ ���������� �������
int    max_n_lose;     // ������������ ���������� ������ ������ ��������� �������
float  average_profit; // ������� ���������� �������
float  average_lose;   // ������� ��������� �������
float  max_drawdown;   // ������������ ��������
float  abs_drawdown;   // ���������� ��������
float  rel_drawdown;   // ������������� ��������

// ���������� ��� �������������� �������

unsigned char IMAGE[286][688][3];  // ������ ��� �������� 

// ������� ���������� �������� � �������. ���������� ��������� �� ��������� ��������� �������

void SetPoint (double value)
 {
   Point * new_point;           // ��������� �� ����� ������� �������
   new_point = new Point();     // �������� ������ ��� ����� �������
   new_point->next = NULL;      // ��������� �� ��������� ������� �������
   new_point->value = value;    // ��������� � ������� ������� �������� ���� value
   if (root == NULL)            // ���� ��� ������ �������
     {
       root = new_point;
     }
   else
     {
       current->next = new_point;
     }
   current = new_point;
}

// ������� �������� ��������� �������

 void  RemovePoints (Point * root)
  {
   Point * pn; // ��������� �� ������� �����
   while (root)
    {
      pn = root;
      root= root->next;
      delete pn;
    }
  }

// ������� ���� ������������ � ����������� �������� ��������� ������

void  GetTopAndLow (double value)
 {
  if (value > top_value)
     top_value = value;
  if (value < low_value)
     low_value = value;
 }

// ������� ���������� ��������� ����� �� ��� Y � ��������

int  GetY (double value)
 {
  return graphH - (int)(double)(graphH*(value-low_value)/range);
 }

// ������� ��������� ������ � �������� �� � ���������� �������

void GetRangeX ()
 {
  rangeX = (int)(double)(1.0*graphW/(n_positions-1));
 }

// ������� ��������� ������ � ������� �� � ���������� �������

void GetRangeXFloat ()
 {
  rangeX = 1.0*graphW/(n_positions-1);
 }

// ������� ��������� ���� �� ��������� �� ���� ������

 bool ReadFile (char * url)
  {
   FILE * fp; // ����� �����
   int index;
   float tmp_value;   // ���������� ���������� �������� ������
   fp = fopen(url,"r");
   if (fp == NULL) // ���� ���� �� ������� �������
    return false;

   fscanf(fp,"%i",&n_positions);    // ��������� ���������� ������� �� �����
   fscanf(fp,"%i",&n_win_pos);      // ��������� ���������� ���������� ������� �� �����
   fscanf(fp,"%i",&n_lose_pos);     // ��������� ���������� ��������� ������� �� �����
   fscanf(fp,"%i",&sign_last_pos);  // ��������� ���� ��������� �������
   fscanf(fp,"%f",&max_win_pos);    // ��������� ������������ ���������� �������
   fscanf(fp,"%f",&min_lose_pos);   // ��������� ����������� ��������� �������
   fscanf(fp,"%f",&max_profit);     // ��������� ������������ ����������� �������
   fscanf(fp,"%f",&max_lose);       // ��������� ������������ ����������� ������
   fscanf(fp,"%i",&max_n_win);      // ��������� ������������ ����� ����������� ���������� �������
   fscanf(fp,"%i",&max_n_lose);     // ��������� ������������ ����� ����������� ��������� �������
   fscanf(fp,"%f",&average_profit); // ��������� ������� ���������� �������
   fscanf(fp,"%f",&average_lose);   // ��������� ������� ��������� �������
   fscanf(fp,"%f",&max_drawdown);   // ��������� ������������ ��������
   fscanf(fp,"%f",&abs_drawdown);   // ��������� ���������� ��������
   fscanf(fp,"%f",&rel_drawdown);   // ��������� ������������� ��������

   // �������� � ���������
   for (index=0;index<(n_positions-1) && !feof(fp); index++)
     {

      fscanf(fp,"%f",&tmp_value); // ��������� �������� ����� 1-�� �������
      SetPoint(tmp_value);        // �������� ������ ��� ����� ������� ����� � ���������� ��������� ��������
      GetTopAndLow (tmp_value);   // ��������� top � low
     }
   range = top_value - low_value;  // ��������� ���������� � ������� �� top �� low
   fclose(fp);  // ��������� ����
   return true;
 }

 
  // �������������� �������
 
 // ����� ��������� ����� ����� ����� ������� �� ����������� X,Y �������� ������
 void drawLine(int x1, int y1, int x2, int y2,unsigned char r,unsigned char g, unsigned char b) {
    const int deltaX = abs(x2 - x1);
    const int deltaY = abs(y2 - y1);
    const int signX = x1 < x2 ? 1 : -1;
    const int signY = y1 < y2 ? 1 : -1;
    //
    int error = deltaX - deltaY;
    //
	    IMAGE[y2][x2][0] = r;
	    IMAGE[y2][x2][1] = g;
	    IMAGE[y2][x2][2] = b;
    while(x1 != x2 || y1 != y2) {

	    IMAGE[y1][x1][0] = r;
	    IMAGE[y1][x1][1] = g;
	    IMAGE[y1][x1][2] = b;

        const int error2 = error * 2;
        //
        if(error2 > -deltaY) {
            error -= deltaY;
            x1 += signX;
        }
        if(error2 < deltaX) {
            error += deltaX;
            y1 += signY;
        }
    }
 
}


 // ������� ����������� � �������� ����
 void ClearDESK (unsigned char r,unsigned char g, unsigned char b)
 {
   int x,y;
   for (y=0;y<graphH;y++)
   {
	for (x=0;x<graphW;x++)
	{
	  IMAGE[y][x][0] = r;
	  IMAGE[y][x][1] = g;
	  IMAGE[y][x][2] = b;
	}
   }
 }
 
 // ������ ������ �� ����� ��� ���������� � ����
 void DrawGraphOnDESK (unsigned char r,unsigned char g, unsigned char b) 
  {
	  
	// ����������� ��������� ����������
   int     rgX;                     // �������� �� ��� � � ��������
   double  rgXFloat;                // �������� �� ��� X � �������
   int     x0,y0;
   int     x1,y1;
   // ��������� �� ������� �������
   struct point * elem;

   // ������� ����� � ������������
  ClearDESK(0,0,0);
   // ������������� ������ �������
   
 if (root)
   {	
     x0 = 0;
	 y0 = GetY(root->value);
    if (graphW >= (n_positions-1) )
     {
     GetRangeX ();
     rgX = rangeX;

     for (elem = root->next; elem; elem = elem->next)
       {

        x1 = rgX;
        y1 = GetY(elem->value);

		drawLine(x0,y0,x1,y1,r,g,b);

        x0 = x1;
		y0 = y1;
        rgX+=rangeX;  // ������� �� ����� ���������� �������
       }
     }
    else
     {
     GetRangeXFloat();
     rgX = 1;
     rgXFloat = rangeX;
     for (elem = root->next; elem; elem = elem->next)
       {
        if (rgXFloat >= 1)
          {
           rgXFloat-=1;
        x1 = rgX;
        y1 = GetY(elem->value);

		drawLine(x0,y0,x1,y1,r,g,b);

        x0 = x1;
		y0 = y1;
           rgX++;
          }
        rgXFloat+=rangeX;  // ������� �� ����� ���������� �������
       }
     }
  }
 }
  
 // ������� BMP ���� �� ������� �������
 bool  CreateBitmapFile (char * bmp_url)
  {
    FILE * fp;
	// ��������� ���� �� ������ BMP �����
	fp = fopen (bmp_url,"rb");
	if (fp != NULL)
	 {
      // ��������� 
      // ��������� ����
	  fclose(fp);
	 }
    return true;
  }
  
 // ��������� ���������� � ���� HTML ��������
 bool  SaveBacktestAsHTML (char * html_url)
  {
    FILE * fp;
    fp = fopen(html_url,"w");
    fprintf(fp,"<HTML>");
    fprintf(fp,"<title>����������</title>");
    fprintf(fp,"<body>");
    // �������� �������� ������� � �����
    fprintf(fp,"<img></img>");
    fprintf(fp,"<br>");
    // �������� ������� ����������
    fprintf(fp,"�������:<br>");
    fprintf(fp,"<table border=1 style=border-style:double;>");
    fprintf(fp,"<tr>");
    fprintf(fp,"<td>��������</td>");
    fprintf(fp,"<td>��������</td>");
    fprintf(fp,"</tr>");
    fprintf(fp,"</table>");
    fprintf(fp,"</body></HTML>");
    fclose(fp);
    return true;
  }

  
#endif

namespace WE_ARE_THE_PRISONERS {

	using namespace System;
	using namespace System::ComponentModel;
	using namespace System::Collections;
	using namespace System::Windows::Forms;
	using namespace System::Data;
	using namespace System::Drawing;

	/// <summary>
	/// ������ ��� Form1
	/// </summary>
	public ref class Form1 : public System::Windows::Forms::Form
	{
	public:
		Form1(void)
		{
			InitializeComponent();
			//
			//TODO: �������� ��� ������������
			//
		}

	protected:
		/// <summary>
		/// ���������� ��� ������������ �������.
		/// </summary>
		~Form1()
		{
			if (components)
			{
				delete components;
			}
		}
	private: System::Windows::Forms::Label^  label1;

	private: System::Windows::Forms::GroupBox^  groupBox1;
	private: System::Windows::Forms::GroupBox^  groupBox2;
	private: System::Windows::Forms::PictureBox^  pictureBox1;
	private: System::Windows::Forms::Button^  button1;
	private: System::Windows::Forms::GroupBox^  groupBox5;
	private: System::Windows::Forms::GroupBox^  groupBox4;
	private: System::Windows::Forms::GroupBox^  groupBox3;
	private: System::Windows::Forms::Label^  n_profit;
	private: System::Windows::Forms::Label^  n_all;


	private: System::Windows::Forms::Label^  n_lose;
	private: System::Windows::Forms::Label^  max_dd;
	private: System::Windows::Forms::Label^  rel_dd;





	private: System::Windows::Forms::Label^  abs_dd;
	private: System::Windows::Forms::Label^  max_n_lose_;



	private: System::Windows::Forms::Label^  max_range_lose;
	private: System::Windows::Forms::Label^  max_n_profit;


	private: System::Windows::Forms::Label^  max_range_profit;

	private: System::Windows::Forms::Label^  min_lose;
	private: System::Windows::Forms::Label^  max_profit_;



	private: System::Windows::Forms::Label^  last_sign;
	private: System::Windows::Forms::Label^  a_lose;
	private: System::Windows::Forms::Label^  a_profit;
	private: System::Windows::Forms::Button^  button2;

	protected: 

	private:
		/// <summary>
		/// ��������� ���������� ������������.
		/// </summary>
		System::ComponentModel::Container ^components;

#pragma region Windows Form Designer generated code
		/// <summary>
		/// ������������ ����� ��� ��������� ������������ - �� ���������
		/// ���������� ������� ������ ��� ������ ��������� ����.
		/// </summary>
		void InitializeComponent(void)
		{
			this->label1 = (gcnew System::Windows::Forms::Label());
			this->groupBox1 = (gcnew System::Windows::Forms::GroupBox());
			this->button1 = (gcnew System::Windows::Forms::Button());
			this->groupBox2 = (gcnew System::Windows::Forms::GroupBox());
			this->groupBox5 = (gcnew System::Windows::Forms::GroupBox());
			this->max_dd = (gcnew System::Windows::Forms::Label());
			this->rel_dd = (gcnew System::Windows::Forms::Label());
			this->abs_dd = (gcnew System::Windows::Forms::Label());
			this->groupBox4 = (gcnew System::Windows::Forms::GroupBox());
			this->a_lose = (gcnew System::Windows::Forms::Label());
			this->a_profit = (gcnew System::Windows::Forms::Label());
			this->max_n_lose_ = (gcnew System::Windows::Forms::Label());
			this->max_range_lose = (gcnew System::Windows::Forms::Label());
			this->max_n_profit = (gcnew System::Windows::Forms::Label());
			this->max_range_profit = (gcnew System::Windows::Forms::Label());
			this->min_lose = (gcnew System::Windows::Forms::Label());
			this->max_profit_ = (gcnew System::Windows::Forms::Label());
			this->last_sign = (gcnew System::Windows::Forms::Label());
			this->groupBox3 = (gcnew System::Windows::Forms::GroupBox());
			this->n_profit = (gcnew System::Windows::Forms::Label());
			this->n_all = (gcnew System::Windows::Forms::Label());
			this->n_lose = (gcnew System::Windows::Forms::Label());
			this->pictureBox1 = (gcnew System::Windows::Forms::PictureBox());
			this->button2 = (gcnew System::Windows::Forms::Button());
			this->groupBox1->SuspendLayout();
			this->groupBox2->SuspendLayout();
			this->groupBox5->SuspendLayout();
			this->groupBox4->SuspendLayout();
			this->groupBox3->SuspendLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->BeginInit();
			this->SuspendLayout();
			// 
			// label1
			// 
			this->label1->AutoSize = true;
			this->label1->Location = System::Drawing::Point(3, 2);
			this->label1->Name = L"label1";
			this->label1->Size = System::Drawing::Size(90, 13);
			this->label1->TabIndex = 0;
			this->label1->Text = L"������ �������";
			this->label1->Click += gcnew System::EventHandler(this, &Form1::label1_Click);
			// 
			// groupBox1
			// 
			this->groupBox1->Controls->Add(this->button2);
			this->groupBox1->Controls->Add(this->button1);
			this->groupBox1->Location = System::Drawing::Point(700, 12);
			this->groupBox1->Name = L"groupBox1";
			this->groupBox1->Size = System::Drawing::Size(294, 292);
			this->groupBox1->TabIndex = 2;
			this->groupBox1->TabStop = false;
			this->groupBox1->Text = L"������ ������������";
			this->groupBox1->Enter += gcnew System::EventHandler(this, &Form1::groupBox1_Enter);
			// 
			// button1
			// 
			this->button1->Location = System::Drawing::Point(6, 30);
			this->button1->Name = L"button1";
			this->button1->Size = System::Drawing::Size(180, 23);
			this->button1->TabIndex = 0;
			this->button1->Text = L"������������";
			this->button1->UseVisualStyleBackColor = true;
			this->button1->Click += gcnew System::EventHandler(this, &Form1::button1_Click);
			// 
			// groupBox2
			// 
			this->groupBox2->Controls->Add(this->groupBox5);
			this->groupBox2->Controls->Add(this->groupBox4);
			this->groupBox2->Controls->Add(this->groupBox3);
			this->groupBox2->Location = System::Drawing::Point(6, 310);
			this->groupBox2->Name = L"groupBox2";
			this->groupBox2->Size = System::Drawing::Size(999, 181);
			this->groupBox2->TabIndex = 3;
			this->groupBox2->TabStop = false;
			this->groupBox2->Text = L"���������� ��������";
			// 
			// groupBox5
			// 
			this->groupBox5->Controls->Add(this->max_dd);
			this->groupBox5->Controls->Add(this->rel_dd);
			this->groupBox5->Controls->Add(this->abs_dd);
			this->groupBox5->Location = System::Drawing::Point(769, 19);
			this->groupBox5->Name = L"groupBox5";
			this->groupBox5->Size = System::Drawing::Size(227, 156);
			this->groupBox5->TabIndex = 5;
			this->groupBox5->TabStop = false;
			this->groupBox5->Text = L"�������� �� �������";
			// 
			// max_dd
			// 
			this->max_dd->AutoSize = true;
			this->max_dd->Location = System::Drawing::Point(6, 75);
			this->max_dd->Name = L"max_dd";
			this->max_dd->Size = System::Drawing::Size(86, 13);
			this->max_dd->TabIndex = 2;
			this->max_dd->Text = L"������������:";
			// 
			// rel_dd
			// 
			this->rel_dd->AutoSize = true;
			this->rel_dd->Location = System::Drawing::Point(6, 51);
			this->rel_dd->Name = L"rel_dd";
			this->rel_dd->Size = System::Drawing::Size(86, 13);
			this->rel_dd->TabIndex = 1;
			this->rel_dd->Text = L"�������������:";
			// 
			// abs_dd
			// 
			this->abs_dd->AutoSize = true;
			this->abs_dd->Location = System::Drawing::Point(6, 27);
			this->abs_dd->Name = L"abs_dd";
			this->abs_dd->Size = System::Drawing::Size(71, 13);
			this->abs_dd->TabIndex = 0;
			this->abs_dd->Text = L"����������:";
			// 
			// groupBox4
			// 
			this->groupBox4->Controls->Add(this->a_lose);
			this->groupBox4->Controls->Add(this->a_profit);
			this->groupBox4->Controls->Add(this->max_n_lose_);
			this->groupBox4->Controls->Add(this->max_range_lose);
			this->groupBox4->Controls->Add(this->max_n_profit);
			this->groupBox4->Controls->Add(this->max_range_profit);
			this->groupBox4->Controls->Add(this->min_lose);
			this->groupBox4->Controls->Add(this->max_profit_);
			this->groupBox4->Controls->Add(this->last_sign);
			this->groupBox4->Location = System::Drawing::Point(144, 19);
			this->groupBox4->Name = L"groupBox4";
			this->groupBox4->Size = System::Drawing::Size(619, 156);
			this->groupBox4->TabIndex = 4;
			this->groupBox4->TabStop = false;
			this->groupBox4->Text = L"���������� �� ��������";
			// 
			// a_lose
			// 
			this->a_lose->AutoSize = true;
			this->a_lose->Location = System::Drawing::Point(260, 129);
			this->a_lose->Name = L"a_lose";
			this->a_lose->Size = System::Drawing::Size(156, 13);
			this->a_lose->TabIndex = 8;
			this->a_lose->Text = L"������� ��������� �������: ";
			// 
			// a_profit
			// 
			this->a_profit->AutoSize = true;
			this->a_profit->Location = System::Drawing::Point(6, 130);
			this->a_profit->Name = L"a_profit";
			this->a_profit->Size = System::Drawing::Size(165, 13);
			this->a_profit->TabIndex = 7;
			this->a_profit->Text = L"������� ���������� �������: ";
			// 
			// max_n_lose_
			// 
			this->max_n_lose_->AutoSize = true;
			this->max_n_lose_->Location = System::Drawing::Point(260, 103);
			this->max_n_lose_->Name = L"max_n_lose_";
			this->max_n_lose_->Size = System::Drawing::Size(212, 13);
			this->max_n_lose_->TabIndex = 6;
			this->max_n_lose_->Text = L"����. ����� ��������� ������� ������:";
			// 
			// max_range_lose
			// 
			this->max_range_lose->AutoSize = true;
			this->max_range_lose->Location = System::Drawing::Point(6, 103);
			this->max_range_lose->Name = L"max_range_lose";
			this->max_range_lose->Size = System::Drawing::Size(151, 13);
			this->max_range_lose->TabIndex = 5;
			this->max_range_lose->Text = L"����. ����������� ������:";
			// 
			// max_n_profit
			// 
			this->max_n_profit->AutoSize = true;
			this->max_n_profit->Location = System::Drawing::Point(260, 75);
			this->max_n_profit->Name = L"max_n_profit";
			this->max_n_profit->Size = System::Drawing::Size(221, 13);
			this->max_n_profit->TabIndex = 4;
			this->max_n_profit->Text = L"����. ����� ���������� ������� ������:";
			// 
			// max_range_profit
			// 
			this->max_range_profit->AutoSize = true;
			this->max_range_profit->Location = System::Drawing::Point(6, 75);
			this->max_range_profit->Name = L"max_range_profit";
			this->max_range_profit->Size = System::Drawing::Size(157, 13);
			this->max_range_profit->TabIndex = 3;
			this->max_range_profit->Text = L"����. ����������� �������:";
			// 
			// min_lose
			// 
			this->min_lose->AutoSize = true;
			this->min_lose->Location = System::Drawing::Point(260, 51);
			this->min_lose->Name = L"min_lose";
			this->min_lose->Size = System::Drawing::Size(134, 13);
			this->min_lose->TabIndex = 2;
			this->min_lose->Text = L"���. ��������� �������:";
			// 
			// max_profit_
			// 
			this->max_profit_->AutoSize = true;
			this->max_profit_->Location = System::Drawing::Point(6, 50);
			this->max_profit_->Name = L"max_profit_";
			this->max_profit_->Size = System::Drawing::Size(149, 13);
			this->max_profit_->TabIndex = 1;
			this->max_profit_->Text = L"����. ���������� �������:";
			// 
			// last_sign
			// 
			this->last_sign->AutoSize = true;
			this->last_sign->Location = System::Drawing::Point(6, 24);
			this->last_sign->Name = L"last_sign";
			this->last_sign->Size = System::Drawing::Size(136, 13);
			this->last_sign->TabIndex = 0;
			this->last_sign->Text = L"���� ��������� �������:";
			// 
			// groupBox3
			// 
			this->groupBox3->Controls->Add(this->n_profit);
			this->groupBox3->Controls->Add(this->n_all);
			this->groupBox3->Controls->Add(this->n_lose);
			this->groupBox3->Location = System::Drawing::Point(6, 19);
			this->groupBox3->Name = L"groupBox3";
			this->groupBox3->Size = System::Drawing::Size(132, 156);
			this->groupBox3->TabIndex = 3;
			this->groupBox3->TabStop = false;
			this->groupBox3->Text = L"���������� �������";
			// 
			// n_profit
			// 
			this->n_profit->AutoSize = true;
			this->n_profit->Location = System::Drawing::Point(6, 51);
			this->n_profit->Name = L"n_profit";
			this->n_profit->Size = System::Drawing::Size(64, 13);
			this->n_profit->TabIndex = 2;
			this->n_profit->Text = L"���������:";
			// 
			// n_all
			// 
			this->n_all->AutoSize = true;
			this->n_all->Location = System::Drawing::Point(6, 75);
			this->n_all->Name = L"n_all";
			this->n_all->Size = System::Drawing::Size(39, 13);
			this->n_all->TabIndex = 0;
			this->n_all->Text = L"�����:";
			// 
			// n_lose
			// 
			this->n_lose->AutoSize = true;
			this->n_lose->Location = System::Drawing::Point(6, 27);
			this->n_lose->Name = L"n_lose";
			this->n_lose->Size = System::Drawing::Size(76, 13);
			this->n_lose->TabIndex = 1;
			this->n_lose->Text = L"����������: ";
			// 
			// pictureBox1
			// 
			this->pictureBox1->BackColor = System::Drawing::SystemColors::ActiveCaptionText;
			this->pictureBox1->Location = System::Drawing::Point(6, 18);
			this->pictureBox1->Name = L"pictureBox1";
			this->pictureBox1->Size = System::Drawing::Size(688, 286);
			this->pictureBox1->TabIndex = 4;
			this->pictureBox1->TabStop = false;
			// 
			// button2
			// 
			this->button2->Location = System::Drawing::Point(7, 60);
			this->button2->Name = L"button2";
			this->button2->Size = System::Drawing::Size(179, 23);
			this->button2->TabIndex = 1;
			this->button2->Text = L"��������� ����� ";
			this->button2->UseVisualStyleBackColor = true;
			// 
			// Form1
			// 
			this->AutoScaleDimensions = System::Drawing::SizeF(6, 13);
			this->AutoScaleMode = System::Windows::Forms::AutoScaleMode::Font;
			this->ClientSize = System::Drawing::Size(1029, 516);
			this->Controls->Add(this->pictureBox1);
			this->Controls->Add(this->groupBox2);
			this->Controls->Add(this->groupBox1);
			this->Controls->Add(this->label1);
			this->Name = L"Form1";
			this->Text = L"����������";
			this->Load += gcnew System::EventHandler(this, &Form1::Form1_Load);
			this->groupBox1->ResumeLayout(false);
			this->groupBox2->ResumeLayout(false);
			this->groupBox5->ResumeLayout(false);
			this->groupBox5->PerformLayout();
			this->groupBox4->ResumeLayout(false);
			this->groupBox4->PerformLayout();
			this->groupBox3->ResumeLayout(false);
			this->groupBox3->PerformLayout();
			(cli::safe_cast<System::ComponentModel::ISupportInitialize^  >(this->pictureBox1))->EndInit();
			this->ResumeLayout(false);
			this->PerformLayout();

		}
#pragma endregion
	private: System::Void Form1_Load(System::Object^  sender, System::EventArgs^  e) {
  
			 }
	private: System::Void label1_Click(System::Object^  sender, System::EventArgs^  e) {
			 }
	private: System::Void groupBox1_Enter(System::Object^  sender, System::EventArgs^  e) {
			 }
	private: System::Void button1_Click(System::Object^  sender, System::EventArgs^  e) {

   int     rgX;                     // �������� �� ��� � � ��������
   double  rgXFloat;                // �������� �� ��� X � �������
   int x0,y0;
   int x1,y1;
   Graphics ^gr;
   FILE * fp; // ����� ���� ������ URL
   char url[80]; // url ����� ��������
   // ��������� �� ������� �������
   struct point * elem;
   
   gr = pictureBox1->CreateGraphics();

 // ��������� ������ URL �����
 fp = fopen("C:\\_backtest_.dat","r");
 if (fp != NULL)
   {
    fscanf(fp,"%s",&url);
	fclose(fp);
	
  // ��������� ���� ����������
  if (ReadFile(url) )
   {

	// ���������� ��������� 
	Form1::n_all->Text = "�����: "+Convert::ToString(n_positions);
	Form1::n_profit->Text = "����������: "+Convert::ToString(n_win_pos);
	Form1::n_lose->Text = "���������: "+Convert::ToString(n_lose_pos);
	switch (sign_last_pos)
	{
	case 1:
     Form1::last_sign->Text = "���� ��������� �������: ����������";
	break;
	case -1:
     Form1::last_sign->Text = "���� ��������� �������: ���������";
	break;
	case 0:
     Form1::last_sign->Text = "���� ��������� �������: �������";
	break;
	}
	
	Form1::max_profit_->Text = "����. ���������� �������: "+Convert::ToString(max_win_pos);
	Form1::min_lose->Text = "���. ��������� �������: "+Convert::ToString(min_lose_pos);
	Form1::max_range_profit->Text = "����. ����������� �������: "+Convert::ToString(max_profit);
	Form1::max_range_lose->Text = "����. ����������� ������: "+Convert::ToString(max_lose);
	Form1::max_n_profit->Text = "����. ����� ���������� ������� ������: "+Convert::ToString(max_n_win);
	Form1::max_n_lose_->Text = "����. ����� ��������� ������� ������: "+Convert::ToString(max_n_lose);
	Form1::a_profit->Text = "������� ���������� �������: "+Convert::ToString(average_profit);
	Form1::a_lose->Text = "������� ��������� �������: "+Convert::ToString(average_lose);
	Form1::abs_dd->Text = "����������: "+Convert::ToString(abs_drawdown);
	Form1::rel_dd->Text = "�������������: "+Convert::ToString(rel_drawdown);
	Form1::max_dd->Text = "������������: "+Convert::ToString(max_drawdown);
	// ������ ������ �������
 	 if (root)
   {

					
     x0 = 0;
	 y0 = GetY(root->value);
    if (graphW >= (n_positions-1) )
     {
     GetRangeX ();
     rgX = rangeX;

     for (elem = root->next; elem; elem = elem->next)
       {

        x1 = rgX;
        y1 = GetY(elem->value);

		//gr->DrawLine(pen,x0,y0,x1,y1);
		gr->DrawLine( System::Drawing::Pens::Red,x0,y0,x1,y1);

        x0 = x1;
		y0 = y1;
        rgX+=rangeX;  // ������� �� ����� ���������� �������
       }
     }
    else
     {
     GetRangeXFloat();
     rgX = 1;
     rgXFloat = rangeX;
     for (elem = root->next; elem; elem = elem->next)
       {
        if (rgXFloat >= 1)
          {
           rgXFloat-=1;
        x1 = rgX;
        y1 = GetY(elem->value);

		gr->DrawLine( System::Drawing::Pens::Red,x0,y0,x1,y1);
        x0 = x1;
		y0 = y1;
           rgX++;
          }
        rgXFloat+=rangeX;  // ������� �� ����� ���������� �������
       }
     }

   }
 
   }
  else
  {
	  	  	   MessageBox::Show("�� ������� ��������� ���� ����������!", 
			  					  "������!", 
								  System::Windows::Forms::MessageBoxButtons::OK, 
								  System::Windows::Forms::MessageBoxIcon::Error);
			   Close();
  }

 }
 else
 {
	  	   MessageBox::Show("���� �� ������� url ������� ���������� �� ������!", 
			  					  "������!", 
								  System::Windows::Forms::MessageBoxButtons::OK, 
								  System::Windows::Forms::MessageBoxIcon::Error);
		   Close();
 }



			 }
};
}

