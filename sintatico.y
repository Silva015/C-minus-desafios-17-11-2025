%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylineno; /* Variavel que o Flex mantem */
extern int yylex();
extern char* yytext;
void yyerror(char *s);

/* --- TABELA DE SIMBOLOS --- */

struct registro_simbolo {
    char *nome;
    char *tipo;
    int linha;
    int endereco;
    struct registro_simbolo *prox;
}; 

typedef struct registro_simbolo registro_simbolo;

registro_simbolo *tabela_simbolos = (registro_simbolo *)0;

int contador_endereco = 0;

registro_simbolo *inserir_simbolo(char *nome_simbolo, char *tipo_simbolo, int linha_declaracao) {
    registro_simbolo *ptr = (registro_simbolo *) malloc(sizeof(registro_simbolo));
    ptr->nome = (char *) malloc(strlen(nome_simbolo) + 1);
    strcpy(ptr->nome, nome_simbolo);
    ptr->tipo = (char *) malloc(strlen(tipo_simbolo) + 1);
    strcpy(ptr->tipo, tipo_simbolo);
    ptr->linha = linha_declaracao;

    ptr->endereco = contador_endereco;
    contador_endereco++; 

    ptr->prox = (struct registro_simbolo *)tabela_simbolos;
    tabela_simbolos = ptr;
    return ptr;
}

registro_simbolo *buscar_simbolo(char *nome_simbolo) {
    registro_simbolo *ptr;
    for (ptr = tabela_simbolos; ptr != (registro_simbolo *)0; ptr = (registro_simbolo *)ptr->prox)
        if (strcmp(ptr->nome, nome_simbolo) == 0) return ptr;
    return 0;
}

void registrar(char *nome_simbolo, char *tipo_simbolo, int linha_atual) {
    registro_simbolo *s = buscar_simbolo(nome_simbolo);
    if (s == 0) {
        s = inserir_simbolo(nome_simbolo, tipo_simbolo, linha_atual);
        printf("   [TABELA] -> Declaracao de '%s' (Tipo: %s, Linha: %d) registrada.\n", nome_simbolo, tipo_simbolo, linha_atual);
    } else {
        printf("   [ERRO SEMANTICO] Linha %d -> Variavel '%s' ja declarada na linha %d!\n", linha_atual, nome_simbolo, s->linha);
    }
}

void verificar_contexto(char *nome_simbolo, int linha_uso) {
    registro_simbolo *s = buscar_simbolo(nome_simbolo);
    if (s == 0)
        printf("   [ERRO SEMANTICO] Linha %d -> Variavel '%s' usada mas NAO declarada.\n", linha_uso, nome_simbolo);
    else
        printf("   [TABELA] -> Uso de '%s' verificado na linha %d. (Declarada na linha %d)\n", nome_simbolo, linha_uso, s->linha);
}

void imprimir_tabela() {
    printf("\n===== TABELA DE SIMBOLOS FINAL =====\n");
    printf("%-20s | %-10s | %-5s | %-8s\n", "NOME", "TIPO", "LINHA", "ENDERECO");
    printf("----------------------------------------------------------\n");
    registro_simbolo *ptr = tabela_simbolos;
    while (ptr != NULL) {
        printf("%-20s | %-10s | %-5d | %-8d\n", ptr->nome, ptr->tipo, ptr->linha, ptr->endereco);
        ptr = ptr->prox;
    }
    printf("====================================\n");
}
%}

/* Habilita o recurso de localizacao do Bison */
%locations

%union {
    char *cadeia;
}

%token INTEIRO VAZIO SE SENAO ENQUANTO RETORNA
%token LE GE EQ NE LT GT SOMA SUB MUL DIV
%token NUM
%token <cadeia> ID 
%type <cadeia> especificador_de_tipo
%type <cadeia> var

%left '='
%left EQ NE
%left LT GT LE GE
%left SOMA SUB
%left MUL DIV

%%

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
    /* @2.first_line pega a linha do ID ($2), nao a linha atual */
    registrar($2, $1, @2.first_line); 
}
;

especificador_de_tipo: INTEIRO { $$ = "inteiro"; }
    | VAZIO   { $$ = "vazio"; }
;

declaracao_de_funcao: especificador_de_tipo ID '(' params ')' comando_composto { 
    printf("[SINTATICO] Encontrei funcao: %s\n", $2);
    /* AQUI ESTA A CORRECAO: @2 pega a linha do ID da funcao */
    registrar($2, $1, @2.first_line); 
}
;

params: VAZIO
;

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
    /* Aqui usamos @1.first_line porque ID e o primeiro elemento da regra */
    verificar_contexto($1, @1.first_line); 
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
    imprimir_tabela();
    return 0;
}

void yyerror (char *s) {
    /* Agora usamos yylineno na mensagem de erro */
    printf ("\n[ERRO FATAL] Linha %d: %s\n", yylineno, s);
}