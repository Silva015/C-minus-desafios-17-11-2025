# Makefile para compilar o analisador C-minus

# Compilador C
CC = gcc

# Flags do compilador (opcional, mas bom para evitar warnings chatos do Mac)
CFLAGS = -Wno-implicit-function-declaration

# Nome do executavel final
TARGET = compilador

# Regra padrao (o que acontece quando voce digita apenas 'make')
all: $(TARGET)

# Como gerar o executavel final
$(TARGET): sintatico.tab.c lex.yy.c
	$(CC) $(CFLAGS) -o $(TARGET) sintatico.tab.c lex.yy.c

# Como gerar os arquivos do Bison (sintatico.tab.c e sintatico.tab.h)
# A flag -d eh essencial, pois ela gera o .h que o lexico.l precisa
sintatico.tab.c sintatico.tab.h: sintatico.y
	bison -d sintatico.y

# Como gerar o arquivo do Flex (lex.yy.c)
# Ele depende do sintatico.tab.h existir
lex.yy.c: lexico.l sintatico.tab.h
	flex lexico.l

# Regra para limpar arquivos gerados (digite 'make clean')
clean:
	rm -f $(TARGET) sintatico.tab.c sintatico.tab.h lex.yy.c

# Regra para rodar o teste (digite 'make teste')
teste: $(TARGET)
	./$(TARGET) yujiprograma.txt