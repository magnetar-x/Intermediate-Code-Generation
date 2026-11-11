%{
#include <stdio.h>
#include <string.h>
#include "helper.h"
#include "y.tab.h"
%}

%%

"if"        { return IF; }
"then"      { return THEN; }
"else"      { return ELSE; }

"&&"        { return AND; }
"||"        { return OR; }
"!"         { return NOT; }

"<="|">="|"=="|"!="|"<"|">" {
    strcpy(yylval.addr, yytext);
    return RELOP;
}

[a-zA-Z_][a-zA-Z0-9_]* {
    strcpy(yylval.addr, yytext);
    return ID;
}

[0-9]+ {
    strcpy(yylval.addr, yytext);
    return NUM;
}

[ \t\r\n]+  { ; }

.           { return yytext[0]; }

%%

int yywrap() {
    return 1;
}
