%{
#include <string.h>
#include "sintatico.tab.h" 

extern char *strdup(const char *s);

/* Sincroniza o numero da linha do Flex com a struct de localizacao do Bison */
#define YY_USER_ACTION yylloc.first_line = yylineno; 
%}

/* A opçao yylineno diz para o flex criar uma variavel int yylineno e manter atualizada */
%option yylineno

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

[a-zA-Z_][a-zA-Z0-9_]*      {
              yylval.cadeia = strdup(yytext);
              return ID;
            }

[0-9]+      {return NUM;}

[ \t\r]+    {;} 
\n          {;} 

.           {return yytext[0];}

%%

int yywrap() {
  return 1;
}