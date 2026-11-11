%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(const char *s);

char code[1000][100];
int start_label = 30;
int nextinstr = 30;
int temp_count = 1;
%}

%union {
    char addr[20];
    int instr;
}

%token IF THEN ELSE AND OR NOT
%token <addr> ID NUM RELOP

%type <addr> E B
%type <instr> M N

%left OR
%left AND
%right NOT
%left '+' '-'
%left '*' '/' '%'

%%

prog : L {
        for (int i = start_label; i < nextinstr; i++) {
            printf("%d: %s\n", i, code[i]);
        }
    }
    ;

L : L S
    | S
    ;

S : IF '(' B ')' THEN M S ELSE N M S {
        sprintf(code[$6], "if %s!=0 goto %d", $3, $6 + 2);
        sprintf(code[$6 + 1], "goto %d", $10);
    }
    | ID '=' E ';' {
        sprintf(code[nextinstr], "%s := %s", $1, $3);
        nextinstr++;
    }
    | '{' L '}'
    ;

B : B AND B {
        sprintf($$, "t%d", temp_count++);
        sprintf(code[nextinstr], "%s := %s && %s", $$, $1, $3);
        nextinstr++;
    }
    | B OR B {
        sprintf($$, "t%d", temp_count++);
        sprintf(code[nextinstr], "%s := %s || %s", $$, $1, $3);
        nextinstr++;
    }
    | NOT B {
        sprintf($$, "t%d", temp_count++);
        sprintf(code[nextinstr], "%s := ! %s", $$, $2);
        nextinstr++;
    }
    | '(' B ')' {
        strcpy($$, $2);
    }
    | E RELOP E {
        sprintf($$, "t%d", temp_count++);
        sprintf(code[nextinstr], "if %s%s%s goto %d", $1, $2, $3, nextinstr + 3);
        nextinstr++;
        sprintf(code[nextinstr], "%s := 0", $$);
        nextinstr++;
        sprintf(code[nextinstr], "goto %d", nextinstr + 2);
        nextinstr++;
        sprintf(code[nextinstr], "%s := 1", $$);
        nextinstr++;
    }
    ;

E : E '+' E {
        sprintf($$, "t%d", temp_count++);
        sprintf(code[nextinstr], "%s := %s + %s", $$, $1, $3);
        nextinstr++;
    }
    | E '-' E {
        sprintf($$, "t%d", temp_count++);
        sprintf(code[nextinstr], "%s := %s - %s", $$, $1, $3);
        nextinstr++;
    }
    | E '*' E {
        sprintf($$, "t%d", temp_count++);
        sprintf(code[nextinstr], "%s := %s * %s", $$, $1, $3);
        nextinstr++;
    }
    | E '/' E {
        sprintf($$, "t%d", temp_count++);
        sprintf(code[nextinstr], "%s := %s / %s", $$, $1, $3);
        nextinstr++;
    }
    | E '%' E {
        sprintf($$, "t%d", temp_count++);
        sprintf(code[nextinstr], "%s := %s %% %s", $$, $1, $3);
        nextinstr++;
    }
    | '(' E ')' {
        strcpy($$, $2);
    }
    | ID {
        strcpy($$, $1);
    }
    | NUM {
        strcpy($$, $1);
    }
    ;

M : {
        $$ = nextinstr;
        if (nextinstr > start_label && strcmp(code[nextinstr - 1], "goto _") != 0) {
            nextinstr += 2;
        }
    }
    ;

N : {
        $$ = nextinstr;
        sprintf(code[nextinstr], "goto _");
        nextinstr++;
    }
    ;

%%

void yyerror(const char *s) {
    printf("Syntax Error: %s\n", s);
}

int main() {
    printf("Give start label number : ");
    if (scanf("%d", &start_label) == 1) {
        printf("%d\n", start_label);
    } else {
        printf("%d\n", start_label);
    }
    nextinstr = start_label;
    yyparse();
    return 0;
}
