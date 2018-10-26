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
 
int COMMENT_NESTED_DEPTH = 0;
char *TMP_STRING = NULL;
char STRING_ERR_FLAG = 0;

%}

%option yylineno
%option noyywrap

/*
 * Define names for regular expressions here.
 */
 
NEWLINE			\n
SPACECHAR		[ \n\f\r\t\v]*
NULLCHAR		\0
UNDERSCORE		_
COMMENT_SIMPLE		--.*


STRING_CONST_BEG	\"
COMMENT_NESTED_BEG	\(\*
NESTED_UNMATCHED	\*\)
%x STRING_CONST
%x COMMENT_NESTED


ASSIGN			<-
DARROW          	=>
LE			<=
SINGLE_CHAR_OPERATOR	[;{}(,):@.+\-*\/~<=]

CASE			(?i:case)
CLASS			(?i:class)
ELSE			(?i:else)
ESAC			(?i:esac)
FI			(?i:fi)
IF			(?i:if)
IN			(?i:in)
INHERITS		(?i:inherits)
ISVOID			(?i:isvoid)
LET			(?i:let)
LOOP			(?i:loop)
NEW			(?i:new)
NOT			(?i:not)
OF			(?i:of)
POOL			(?i:pool)
THEN			(?i:then)
WHILE			(?i:while)

true			t(?i:rue)
false			f(?i:alse)

TYPEID			[A-Z][a-zA-Z0-9_]*
OBJECTID		[a-z][a-zA-Z0-9_]*
INT_CONST		[0-9]+


%%

{NEWLINE}		curr_lineno++;
{SPACECHAR}
{UNDERSCORE}		{ BEGIN(INITIAL); cool_yylval.error_msg = strdup("_"); return (ERROR); }
{NULLCHAR}		{ cool_yylval.error_msg = strdup("\000"); return (ERROR);}
{COMMENT_SIMPLE}	
{NESTED_UNMATCHED}	{ cool_yylval.error_msg = strdup("Unmatched *)"); return (ERROR); }  

{COMMENT_NESTED_BEG}	{ COMMENT_NESTED_DEPTH = 1; BEGIN(COMMENT_NESTED); 	}
<COMMENT_NESTED>\\\*	;
<COMMENT_NESTED>\\\(	;
<COMMENT_NESTED>\\\)	;
<COMMENT_NESTED>\*\)	{ if (--COMMENT_NESTED_DEPTH == 0) BEGIN(INITIAL); 	}
<COMMENT_NESTED>\(\*	COMMENT_NESTED_DEPTH++;
<COMMENT_NESTED>\n	curr_lineno++;
<COMMENT_NESTED>(.)	;
<COMMENT_NESTED><<EOF>> { BEGIN(INITIAL); cool_yylval.error_msg = strdup("EOF in comment"); return (ERROR); }


{STRING_CONST_BEG}	{ STRING_ERR_FLAG = 0; TMP_STRING = (char*) calloc(1, sizeof(char)); BEGIN(STRING_CONST); }
<STRING_CONST>\\\n	{ if (!STRING_ERR_FLAG) asprintf(&TMP_STRING, "%s\n", TMP_STRING); curr_lineno++; }
<STRING_CONST>\\b	{ if (!STRING_ERR_FLAG) asprintf(&TMP_STRING, "%s\b", TMP_STRING); }
<STRING_CONST>\\t	{ if (!STRING_ERR_FLAG) asprintf(&TMP_STRING, "%s\t", TMP_STRING); }
<STRING_CONST>\\f	{ if (!STRING_ERR_FLAG) asprintf(&TMP_STRING, "%s\f", TMP_STRING); }
<STRING_CONST>\\n	{ if (!STRING_ERR_FLAG) asprintf(&TMP_STRING, "%s\n", TMP_STRING); }
<STRING_CONST>\\\\	{ if (!STRING_ERR_FLAG) asprintf(&TMP_STRING, "%s\\", TMP_STRING); } 
<STRING_CONST>\\\"	{ if (!STRING_ERR_FLAG) asprintf(&TMP_STRING, "%s\"",  TMP_STRING); }
<STRING_CONST>\\\0	{ STRING_ERR_FLAG = 1; cool_yylval.error_msg = strdup("String contains escaped null character"); }

<STRING_CONST>\"	{ BEGIN(INITIAL); if (STRING_ERR_FLAG) { free(TMP_STRING); return (ERROR); } \
			cool_yylval.symbol = inttable.add_string(TMP_STRING); free(TMP_STRING); return (STR_CONST); }
<STRING_CONST>\n	{ BEGIN(INITIAL); free(TMP_STRING); cool_yylval.error_msg = strdup("Unterminated string constant"); 	\
			curr_lineno++; printf("\\now:%s\n", TMP_STRING);	return (ERROR); }
<STRING_CONST><<EOF>>	{ BEGIN(INITIAL); free(TMP_STRING); cool_yylval.error_msg = strdup("EOF in string constant"); return (ERROR); }
<STRING_CONST>\0	{ STRING_ERR_FLAG = 1; cool_yylval.error_msg = strdup("String contains null character");}
<STRING_CONST>[^\"\n\0\\]	{ if (!STRING_ERR_FLAG) asprintf(&TMP_STRING, "%s%s", TMP_STRING, yytext);}
<STRING_CONST>(\\.)	{ if (!STRING_ERR_FLAG) asprintf(&TMP_STRING, "%s%c", TMP_STRING, yytext[1]);}


 /*
  *  The multiple-character operators.
  */

{ASSIGN}		{ return (ASSIGN); 	}
{DARROW}		{ return (DARROW); 	}
{LE}			{ return (LE); 		}

{SINGLE_CHAR_OPERATOR}	{ return (*yytext);	}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CASE}			{ return (CASE);	}
{CLASS}			{ return (CLASS);	}
{ELSE}			{ return (ELSE);	}
{ESAC}			{ return (ESAC);	}
{FI}			{ return (FI);		}
{IF}			{ return (IF);		}
{IN}			{ return (IN);		}
{INHERITS}		{ return (INHERITS);	}
{ISVOID}		{ return (ISVOID);	}
{LET}			{ return (LET);		}
{LOOP}			{ return (LOOP);	}
{NEW}			{ return (NEW);		}
{NOT}			{ return (NOT);		}
{OF}			{ return (OF);		}
{POOL}			{ return (POOL);	}
{THEN}			{ return (THEN);	}
{WHILE}			{ return (WHILE);	}
{true}			{ cool_yylval.boolean = true;  	return (BOOL_CONST); }	
{false}			{ cool_yylval.boolean = false; 	return (BOOL_CONST); }



 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
  
{TYPEID}		{ cool_yylval.symbol = inttable.add_string(yytext); return (TYPEID);	} 
{OBJECTID}		{ cool_yylval.symbol = inttable.add_string(yytext); return (OBJECTID);	} 

{INT_CONST}		{ cool_yylval.symbol = inttable.add_string(yytext); return (INT_CONST); }
 

%%
