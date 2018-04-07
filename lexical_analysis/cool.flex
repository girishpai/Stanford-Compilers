/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int multi_comment_count = 0;
char ret_str[MAX_STR_CONST];
char *ret_p = ret_str;
bool error_string = false;
int num_chars = 0;
%}

/*
 * Define names for regular expressions here.
 */

%Start L_COMMENT
%Start M_COMMENT
%Start COMMENT
%Start Quote

%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */
<L_COMMENT>\n	{ curr_lineno += 1; BEGIN 0;}
<M_COMMENT>\n 	{ curr_lineno += 1;}
<L_COMMENT>[^\n]*	{}
<M_COMMENT>[^\n"*)""(*"]*	{}
<M_COMMENT>["*""("")"]		{}
<M_COMMENT>"*)"	{ multi_comment_count -= 1; if(multi_comment_count == 0) BEGIN 0;}
<M_COMMENT><<EOF>> {yylval.error_msg = "EOF In Comment";BEGIN 0;return ERROR;}
"*)"  		{yylval.error_msg = "Unmatched *)";return ERROR;}


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

[cC][lL][aA][sS][sS]		{return (CLASS);}
[eE][lL][sS][eE]		{return (ELSE);}
[fF][iI]		{return (FI);}
[iI][fF]		{return (IF);}
[iI][nN]		{return (IN);}
[iI][nN][hH][eE][rR][iI][tT][sS]		{return (INHERITS);}
[lL][eE][tT]		{return (LET);}
[lL][oO][oO][pP]		{return (LOOP);}
[pP][oO][oO][lL]		{return (POOL);}
[tT][hH][eE][nN]		{return (THEN);}
[wW][hH][iI][lL][eE]		{return (WHILE);}
[cC][aA][sS][eE]		{return (CASE);}
[eE][sS][aA][cC]		{return (ESAC);}
[oO][fF]		{return (OF);}
[nN][eE][wW]		{return (NEW);}
[nN][oO][tT]		{return (NOT);}
[iI][sS][vV][oO][iI][dD]		{return (ISVOID);}
t[rR][uU][eE]		{yylval.boolean = true;return BOOL_CONST;}
f[aA][lL][sS][eE]	{yylval.boolean = false;return BOOL_CONST;}

 /*
  * White spaces
  * 
  */
[ \f\v\r\t]+		{}

<Quote><<EOF>> 		{yylval.error_msg = "EOF In String";ret_p = ret_str; *ret_p = '\0';BEGIN 0;return ERROR;}
<Quote>\n	       {BEGIN 0;ret_p = ret_str; *ret_p = '\0';
		       if(error_string == false) {
		       yylval.error_msg = "Unterminated string constant";return ERROR;}
		       }

<Quote>\\(.|\n)		{
			  
			  if(error_string == false) {
			  num_chars += 1;
			  if(num_chars >= MAX_STR_CONST) {
			    yylval.error_msg = "String too long2";error_string = true;
			   
			    return ERROR;
			  }	       
			  if(yytext[1] == '\0') {
			     yylval.error_msg = "Null In String";ret_p = ret_str; *ret_p = '\0';error_string = true;BEGIN 0;return ERROR;
                          }
			  if(yytext[1] != 'n' && yytext[1] != 't' && yytext[1] != 'b' && yytext[1] != 'f') {
			    *ret_p = yytext[1];
			  }
 			  else {
			    switch(yytext[1]) {
			      case 'n' :*ret_p = '\n';break;
			      case 't' :*ret_p = '\t';break;
			      case 'b' :*ret_p = '\b';break;
			      case 'f' :*ret_p = '\f';break;
			      }
			  }
			  ret_p += 1;
			  }
		       }


<Quote>[^"\\\n]*	{
			//cout << "Entered \n"; cout << yytext ;
			if(error_string == false) {
			num_chars += yyleng;
			  if(num_chars >= MAX_STR_CONST) {
			    yylval.error_msg = "String too long";error_string = true;return ERROR;
			   
			  }
			for(int i = 0; i < yyleng;i++) {
			  if(yytext[i] == '\0') {
			     yylval.error_msg = "Null In String";error_string = true;return ERROR;
                          }
			  *ret_p = yytext[i];
			  ret_p += 1;
			  }
			 }
		      }    

<Quote>\"	      {
		        *ret_p = '\0';
			BEGIN 0;
			num_chars = 0;
			if(error_string == false)
				{yylval.symbol = idtable.add_string(ret_str); ret_p = ret_str;return STR_CONST;}
			else {
			     error_string = false;
			     ret_p = ret_str;    
			}
			
		      }
\"		      { BEGIN Quote;}
"--"		{BEGIN L_COMMENT;}
"(*"		{ BEGIN M_COMMENT; multi_comment_count += 1;}
"=>"		      {return DARROW;}
"<-"		      {return ASSIGN;}
"<="		      {return LE;}
[a-z][a-zA-Z0-9_]*	{ yylval.symbol = idtable.add_string(yytext); return OBJECTID; }		
[A-Z][a-zA-Z0-9_]*    { yylval.symbol = idtable.add_string(yytext); return TYPEID; }
[0-9]+		      { yylval.symbol = idtable.add_string(yytext); return INT_CONST;}


"+"		{return ('+');}
"/"		{return ('/');}
"-"		{return ('-');}
"*"		{return ('*');}
"="		{return ('=');}
"<"		{return ('<');}
"."		{return ('.');}
"~"		{return ('~');}
","		{return (',');}
";"		{return (';');}
":"		{return (':');}
"("		{return ('(');}
")"		{return (')');}
"@"		{return ('@');}
"{"		{return ('{');}
"}"		{return ('}');}
\n		      {curr_lineno += 1;}
.		      { yylval.error_msg = yytext; return ERROR; }




 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%
