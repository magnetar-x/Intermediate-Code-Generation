%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "helper.h"

int yylex();
void yyerror(const char *s);

char code[1000][100];
int start_label = 0;
int nextinstr = 0;
int temp_count = 1;
%}

%union {
    char addr[20];
    int instr;
    struct {
        List truelist;
        List falselist;
        List nextlist;
    } list_attr;
}

%token IF THEN ELSE AND OR NOT
%token <addr> ID NUM RELOP

%type <addr> E
%type <instr> M
%type <list_attr> B S L N

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

L : L M S {
        backpatch($1.nextlist, $2);
        $$.nextlist = $3.nextlist;
    }
    | S {
        $$.nextlist = $1.nextlist;
    }
    ;

S : IF '(' B ')' THEN M S ELSE N M S {
        backpatch($3.truelist, $6);
        backpatch($3.falselist, $10);
        print_lists($3.truelist, $3.falselist);
        $$.nextlist = merge(merge($7.nextlist, $9.nextlist), $11.nextlist);
    }
    | ID '=' E ';' {
        sprintf(code[nextinstr], "%s := %s", $1, $3);
        nextinstr++;
        $$.nextlist = emptylist();
    }
    | '{' L '}' {
        $$.nextlist = $2.nextlist;
    }
    ;

B : B AND M B {
        backpatch($1.truelist, $3);
        $$.truelist = $4.truelist;
        $$.falselist = merge($1.falselist, $4.falselist);
    }
    | B OR M B {
        backpatch($1.falselist, $3);
        $$.truelist = merge($1.truelist, $4.truelist);
        $$.falselist = $4.falselist;
    }
    | NOT B {
        $$.truelist = $2.falselist;
        $$.falselist = $2.truelist;
    }
    | '(' B ')' {
        $$.truelist = $2.truelist;
        $$.falselist = $2.falselist;
    }
    | E RELOP E {
        $$.truelist = makelist(nextinstr);
        sprintf(code[nextinstr], "if %s%s%s goto _", $1, $2, $3);
        nextinstr++;

        $$.falselist = makelist(nextinstr);
        sprintf(code[nextinstr], "goto _");
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
    }
    ;

N : {
        $$.nextlist = makelist(nextinstr);
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
