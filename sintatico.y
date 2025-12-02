/* Verificando a sintaxe de programas segundo GLC-C-minus */
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* --- TABELA DE SIMBOLOS --- */

struct symrec {
    char *name;
    struct symrec *next;
};
typedef struct symrec symrec;

symrec *sym_table = (symrec *)0;

symrec *putsym(char *sym_name) {
    symrec *ptr = (symrec *) malloc(sizeof(symrec));
    ptr->name = (char *) malloc(strlen(sym_name) + 1);
    strcpy(ptr->name, sym_name);
    ptr->next = (struct symrec *)sym_table;
    sym_table = ptr;
    return ptr;
}

symrec *getsym(char *sym_name) {
    symrec *ptr;
    for (ptr = sym_table; ptr != (symrec *)0; ptr = (symrec *)ptr->next)
        if (strcmp(ptr->name, sym_name) == 0)
            return ptr;
    return 0;
}

void install(char *sym_name) {
    symrec *s = getsym(sym_name);
    if (s == 0) {
        s = putsym(sym_name);
        printf("   [TABELA] -> Declaração de '%s' registrada.\n", sym_name);
    } else {
        printf("   [ERRO SEMANTICO] -> Variavel '%s' ja foi declarada antes!\n", sym_name);
    }
}

void context_check(char *sym_name) {
    if (getsym(sym_name) == 0)
        printf("   [ERRO SEMANTICO] -> Variavel '%s' usada mas NAO declarada.\n", sym_name);
    else
        printf("   [TABELA] -> Uso de '%s' verificado (OK).\n", sym_name);
}

extern int yylex();
extern char* yytext;
void yyerror(char *s);

%}

%union {
    char *cadeia;
}

%token INTEIRO VAZIO SE SENAO ENQUANTO RETORNA
%token LE GE EQ NE LT GT SOMA SUB MUL DIV
%token NUM

/* Token ID carrega o nome */
%token <cadeia> ID 
%type <cadeia> var

%left '='
%left EQ NE
%left LT GT LE GE
%left SOMA SUB
%left MUL DIV

%%
/* Regras Gramaticais */

programa: lista_de_declaracoes { 
    printf("\n[SINTATICO] === FIM: Programa analisado com sucesso ===\n"); 
}
;

lista_de_declaracoes: declaracao
    | lista_de_declaracoes declaracao
;

declaracao: declaracao_de_var
    | declaracao_de_funcao
;

declaracao_de_var: especificador_de_tipo ID ';' { 
    printf("[SINTATICO] Encontrei declaracao de variavel: %s\n", $2);
    install($2); 
}
;

especificador_de_tipo: INTEIRO 
    | VAZIO
;

declaracao_de_funcao: especificador_de_tipo ID '(' params ')' comando_composto { 
    printf("[SINTATICO] Encontrei funcao: %s\n", $2);
    install($2); 
}
;

params: VAZIO
;

/* TRUQUE PARA CORRIGIR O ERRO: Regra separada para o abre chaves */
l_brace: '{' { printf("[SINTATICO] -- Entrando no bloco '{' --\n"); }
;

comando_composto: l_brace declaracoes_locais lista_de_comandos '}' { 
    printf("[SINTATICO] -- Saindo do bloco '}' --\n"); 
}
;

declaracoes_locais: /* vazio */
    | declaracoes_locais declaracao_de_var
;

lista_de_comandos: /* vazio */
    | lista_de_comandos comando
;

comando: comando_de_expressao
    | comando_de_selecao
    | comando_de_iteracao
    | comando_de_retorno
;

comando_de_expressao: expressao ';' { printf("[SINTATICO] Comando executado.\n"); }
;

comando_de_selecao: SE '(' expressao ')' comando
    | SE '(' expressao ')' comando SENAO comando
;

comando_de_iteracao: ENQUANTO '(' expressao ')' comando
;

comando_de_retorno: RETORNA ';'
    | RETORNA expressao ';' { printf("[SINTATICO] Retorno encontrado.\n"); }
;

expressao: var '=' expressao {
    printf("[SINTATICO] Atribuicao realizada em: %s\n", $1);
}
    | expressao_simples
;

var: ID { 
    /* Aqui verificamos se a variavel existe antes de usar */
    context_check($1);
    $$ = $1; 
}
;

expressao_simples: expressao_aditiva relop expressao_aditiva
    | expressao_aditiva
;

relop: LE | GE | EQ | NE | LT | GT
;

expressao_aditiva: expressao_aditiva operacao_add termo
    | termo
;

operacao_add: SOMA | SUB
;

termo: termo mulop fator
    | fator
;

mulop: MUL | DIV
;

fator: NUM 
    | var
    | '(' expressao ')'
;

%%

int main(int argc, char **argv) {
    extern FILE *yyin;
    
    if(argc > 1) yyin = fopen(argv[1],"rt");
    else yyin = stdin;

    printf("\n--- INICIO DA ANALISE ---\n");
    yyparse();

    if(yyin != stdin) fclose(yyin);
    return 0;
}

void yyerror (char *s) {
    printf ("\n[ERRO FATAL] %s\n", s);
}