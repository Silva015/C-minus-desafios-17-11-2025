%{
#include <string.h>
#include "sintatico.tab.h" 

extern char *strdup(const char *s);
%}

%%
inteiro     {return INTEIRO;}
vazio       {return VAZIO;}
se          {return SE;}
senao       {return SENAO;}
enquanto    {return ENQUANTO;}
retorna     {return RETORNA;}
"<="        {return LE;}
">="        {return GE;}
"=="        {return EQ;}
"!="        {return NE;}
"<"         {return LT;}
">"         {return GT;}
"+"         {return SOMA;}
"-"         {return SUB;}
"*"         {return MUL;}
"/"         {return DIV;}
";"         {return yytext[0];}
","         {return yytext[0];}
"("         {return yytext[0];}
")"         {return yytext[0];}
"{"         {return yytext[0];}
"}"         {return yytext[0];}
"="         {return yytext[0];}

[a-z]+      {
              yylval.cadeia = strdup(yytext);
              return ID;
            }

[0-9]+      {return NUM;}
[ \t\n\r]+  {;}
.           {return yytext[0];}

%%

int yywrap() {
  return 1;
}