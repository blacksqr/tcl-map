%{

/*
 * napParse.y --
 *
 * Copyright (c) 1998, CSIRO Australia
 *
 * bison source code defining expression parser
 * bison is a gnu's yacc
 *
 * Author: Harvey Davies, CSIRO Mathematical and Information Sciences
 *
 */

#ifndef lint
static char *rcsid="@(#) $Id: napParse.y,v 1.69 2005/11/26 11:20:10 dav480 Exp $";
#endif /* not lint */

#ifdef WIN32
#include <malloc.h>
#endif /* WIN32 */

#include "nap.h"
#include "nap_check.h"

#define YYERROR_VERBOSE 1
#define YYSTYPE Nap_stype
#define YYPARSE_PARAM Nap_param
#define YYLEX_PARAM Nap_param
#undef  YYSTACK_USE_ALLOCA
#define malloc(N)	ckalloc(N)
#define free(P)		if (P) ckfree((char *) P)

%}

%pure_parser

%token <op>	NULL_OP			/* Null operator */
%token <str>	ID			/* ID of nao  e.g. "nao.42" */
%token <str>	NAME			/* of nao or function */
%token <str>	STRING			/* e.g. 'hello world', `abc` */
%token <str>	UNUMBER			/* unsigned float */
%token <op>	CAT			/* // */
%token <op>	LAMINATE		/* /// */
%token <op>	CLOSEST			/* @@ */
%token <op>	MATCH			/* @@@ */
%token <op>	TO			/* .. */
%token <op>	AP3			/* ... */
%token <op>	EQ			/* == */
%token <op>	NE			/* != */
%token <op>	LE			/* <= */
%token <op>	GE			/* >= */
%token <op>	SHIFT_LEFT		/* << */
%token <op>	LESSER_OF		/* <<< */
%token <op>	SHIFT_RIGHT		/* >> */
%token <op>	GREATER_OF		/* >>> */
%token <op>	AND			/* && */
%token <op>	OR			/* || */
%token <op>	POWER			/* ** */
%token <op>	INNER_PROD		/* . (or +* for compatibility) */
%token <op>	FUNCTION		/* used only for prec */
%token <op> ' ' '!' '"' '#' '$' '%' '&' '(' ')' '*' '+' ',' '-' '.' '/'
%token <op> ':' ';' '<' '=' '>' '?' '@'
%token <op> '[' ']' '^' '_' '`'
%token <op> '{' '|' '}' '~'

%right '='
%left ','
%left CAT LAMINATE
%right '?' ':'
%left TO
%left AP3
%left OR
%left AND
%left '|'
%left '^'
%left '&'
%left EQ NE
%left LE GE '<' '>'
%left LESSER_OF GREATER_OF
%left SHIFT_LEFT SHIFT_RIGHT
%left '-' '+'
%left '*' '/' '%'
%left INNER_PROD
%left '#'
%left '@' CLOSEST MATCH
%right '!' '~'
%right POWER
%right FUNCTION

%type <str>	result			/* final result (nao ID) */
%type <pnode>	expr			/* nao ID of expression */
%type <pnode>	FuncArg1		/* 1st arg of Nap_Func */
%type <pnode>	FuncArg2		/* 2nd arg of Nap_Func */
%type <str>	naoID			/* nao->ID */
%type <str>	arrayConst		/* nao ID of encList */
%type <str>	stringConst		/* nao ID of string */
%type <pnode>	encList			/* enclosed list i.e. {list} */
%type <pnode>	list			/* what is inside braces */
%type <pnode>	element			/* of list (number or encList) */
%type <number>	ssnv			/* signed scalar numeric value */
%type <number>	usnv			/* unsigned scalar numeric value */

%%

result	: /* empty */			{$$ = Nap_SetParseResult(Nap_param, NULL);}
	| expr				{$$ = Nap_SetParseResult(Nap_param, $1);}
	;

expr	: naoID				{$$ = Nap_NewNaoPNode(Nap_param, $1);}
	| arrayConst			{$$ = Nap_NewNaoPNode(Nap_param, $1);}
	| stringConst			{$$ = Nap_NewNaoPNode(Nap_param, $1);}
	| usnv				{$$ = Nap_NewNaoPNode(Nap_param,
					    Nap_ScalarConstant(Nap_param, $1));}
	| NAME				{$$ = Nap_NewNamePNode(Nap_param, $1);}
	| NAME '=' expr			{$$ = Nap_NewExprPNode(Nap_param, 
					    Nap_NewNamePNode(Nap_param, $1), $2, $3);}
	| expr ',' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr CAT expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr LAMINATE expr		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '@' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '#' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr CLOSEST expr		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr MATCH expr		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '?' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr ':' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr TO expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr AP3 expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr OR expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr AND expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr EQ expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr NE expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr LE expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr LESSER_OF expr		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr GREATER_OF expr		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '<' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr GE expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '>' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '+' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '-' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '*' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '/' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '%' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr INNER_PROD expr		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr POWER expr		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '&' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '|' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr '^' expr			{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr SHIFT_LEFT expr		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| expr SHIFT_RIGHT expr		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, $3);}
	| '!' expr			{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| '#' expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| '-' expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| '~' expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| '+' expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| '^' expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| '<' expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| '>' expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| '|' expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| '@' expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| CLOSEST expr %prec '!'	{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| MATCH expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| LE expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| GE expr %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| ',' expr %prec ','		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, $2);}
	| expr ',' %prec ','		{$$ = Nap_NewExprPNode(Nap_param, $1, $2, NULL);}
	| ','				{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, NULL);}
	| '-'	   %prec '!'		{$$ = Nap_NewExprPNode(Nap_param, NULL, $1, NULL);}
	| '(' expr ')'			{$$ = $2;}
	| NAME NAME %prec FUNCTION	{$$ = Nap_NewExprPNode(Nap_param, 
					    Nap_NewNamePNode(Nap_param, $1), NULL_OP,
					    Nap_NewNamePNode(Nap_param, $2));}
	| NAME FuncArg2 %prec FUNCTION	{$$ = Nap_NewExprPNode(Nap_param, 
					    Nap_NewNamePNode(Nap_param, $1), NULL_OP, $2);}
	| FuncArg1 NAME %prec FUNCTION	{$$ = Nap_NewExprPNode(Nap_param, $1, NULL_OP,
					    Nap_NewNamePNode(Nap_param, $2));}
	| FuncArg1 FuncArg2 %prec FUNCTION
					{$$ = Nap_NewExprPNode(Nap_param, $1, NULL_OP, $2);}
	;

FuncArg1: arrayConst			{$$ = Nap_NewNaoPNode(Nap_param, $1);}
	| stringConst			{$$ = Nap_NewNaoPNode(Nap_param, $1);}
	| naoID				{$$ = Nap_NewNaoPNode(Nap_param, $1);}
	| '(' expr ')'			{$$ = $2;}
	| usnv				{$$ = Nap_NewNaoPNode(Nap_param,
					    Nap_ScalarConstant(Nap_param, $1));}
	;

FuncArg2: arrayConst			{$$ = Nap_NewNaoPNode(Nap_param, $1);}
	| stringConst			{$$ = Nap_NewNaoPNode(Nap_param, $1);}
	| naoID				{$$ = Nap_NewNaoPNode(Nap_param, $1);}
	| '(' expr ')'			{$$ = $2;}
	| '(' ')'			{$$ = Nap_NewExprPNode(Nap_param, NULL, NULL_OP, NULL);}
	| usnv				{$$ = Nap_NewNaoPNode(Nap_param,
					    Nap_ScalarConstant(Nap_param, $1));}
	;

naoID:	ID				{$$ = Nap_GetNaoIdFromId(Nap_param, $1);}
	;

stringConst: STRING			{$$ = Nap_StringConstant(Nap_param, $1);}
	;

arrayConst: encList			{$$ = Nap_ArrayConstant(Nap_param, $1);}
	;

encList : '{' list '}'			{$$ = $2 ? $2 :
						Nap_NewListPNode(Nap_param, "0", NULL);}
	;

list	: /* empty */			{$$ = NULL;}
	| list element			{$$ = Nap_AppendToPNodeList(Nap_param, $1, $2);}
	| list ',' element		{$$ = Nap_AppendToPNodeList(Nap_param, $1, $3);}
	;

element : ssnv				{$$ = Nap_NewValuePNode(Nap_param, "1", $1);}
	| UNUMBER '#' ssnv		{$$ = Nap_NewValuePNode(Nap_param, $1, $3);}
	| encList			{$$ = Nap_NewListPNode(Nap_param, "1", $1);}
	| UNUMBER '#' encList		{$$ = Nap_NewListPNode(Nap_param, $1, $3);}
	;

ssnv	: usnv
	| '-' usnv			{$$ = Nap_NegateNumber(Nap_param, $2);}
	| '+' usnv			{$$ = $2;}
	;

usnv	: UNUMBER			{(void) Nap_StringToNumber(Nap_param, $1, &($$));}
	;

%%
