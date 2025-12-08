%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* --- TABELA DE SIMBOLOS --- */

// Nó da tabela de símbolos (antigo symrec)
struct registro_simbolo {
    char *nome;
    struct registro_simbolo *prox;
}; 

typedef struct registro_simbolo registro_simbolo;

// Ponteiro global para o início da tabela de símbolos
registro_simbolo *tabela_simbolos = (registro_simbolo *)0;

// Responsável por alocar memória e inserir um novo símbolo na tabela
registro_simbolo *inserir_simbolo(char *nome_simbolo) {
    // Aloca memória para o nó.
    registro_simbolo *ptr = (registro_simbolo *) malloc(sizeof(registro_simbolo));

    // Aloca memória para a string do nome do símbolo e copia o nome.
    ptr->nome = (char *) malloc(strlen(nome_simbolo) + 1);
    strcpy(ptr->nome, nome_simbolo);

    // Faz o novo nó apontar para o atual início da lista
    ptr->prox = (struct registro_simbolo *)tabela_simbolos;

    // Atualiza a cabeça da lista para ser o novo nó
    tabela_simbolos = ptr;
    return ptr;
}

// Responsável por procurar um símbolo existente pelo nome
registro_simbolo *buscar_simbolo(char *nome_simbolo) {
    registro_simbolo *ptr;

    // Percorre a lista encadeada nó por nó
    for (ptr = tabela_simbolos; ptr != (registro_simbolo *)0; ptr = (registro_simbolo *)ptr->prox)
        
        // Compara o nome buscado com o nome do nó atual
        if (strcmp(ptr->nome, nome_simbolo) == 0)
            return ptr;
    return 0;
}

// Responsável por garantir que um símbolo seja declarado apenas uma vez e registrá-lo
void registrar(char *nome_simbolo) {
    registro_simbolo *s = buscar_simbolo(nome_simbolo);

    if (s == 0) {
        s = inserir_simbolo(nome_simbolo);
        printf("   [TABELA] -> Declaração de '%s' registrada.\n", nome_simbolo);
    } else {
        printf("   [ERRO SEMANTICO] -> Variavel '%s' ja foi declarada antes!\n", nome_simbolo);
    }
}

// Responsável por verificar se um símbolo foi declarado antes de ser usado
void verificar_contexto(char *nome_simbolo) {
    if (buscar_simbolo(nome_simbolo) == 0)
        printf("   [ERRO SEMANTICO] -> Variavel '%s' usada mas NAO declarada.\n", nome_simbolo);
    else
        printf("   [TABELA] -> Uso de '%s' verificado (OK).\n", nome_simbolo);
}

void imprimir_tabela() {
    printf("\n===== TABELA DE SIMBOLOS FINAL =====\n");
    registro_simbolo *ptr = tabela_simbolos;
    while (ptr != NULL) {
        printf(" - %s\n", ptr->nome);
        ptr = ptr->prox;
    }
    printf("====================================\n");
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
    registrar($2); 
}
;

especificador_de_tipo: INTEIRO 
    | VAZIO
;

declaracao_de_funcao: especificador_de_tipo ID '(' params ')' comando_composto { 
    printf("[SINTATICO] Encontrei funcao: %s\n", $2);
    registrar($2); 
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
    /* Verifica se a variavel existe antes de usar */
    verificar_contexto($1); 
    
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
    printf ("\n[ERRO FATAL] %s\n", s);
}