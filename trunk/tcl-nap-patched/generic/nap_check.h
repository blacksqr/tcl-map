/* 
 * nap_check.h --
 *
 * Define macros for error handling using macros CHECK, CHECK2, CHECK3, ...
 * Also define memory allocation macros NAP_ALLOC, NAP_REALLOC, NAP_FREE.
 *
 * Copyright (c) 1997, CSIRO Australia
 *
 * Author: Harvey Davies, CSIRO Mathematical and Information Sciences
 *
 * $Id: nap_check.h,v 1.27 2006/10/09 07:40:27 dav480 Exp $
 */

#include <tcl.h>
#include "nap.h"

#ifndef _NAP_CHECK
#define _NAP_CHECK

#ifndef TRUE
#define TRUE 1
#endif /* TRUE */

#ifndef FALSE
#define FALSE 0
#endif /* FALSE */

#ifndef TCL_OK
#define TCL_OK 0
#endif /* TCL_OK */

#ifndef TCL_ERROR
#define TCL_ERROR 1
#endif /* TCL_ERROR */

#ifndef NAP_ALLOC
#define NAP_ALLOC(nap_cd, n) Nap_Alloc(nap_cd, __FILE__, __LINE__, n)
#endif /* NAP_ALLOC */

#ifndef NAP_REALLOC
#define NAP_REALLOC(nap_cd, p, n) Nap_Realloc(nap_cd, __FILE__, __LINE__, (void *) p, n)
#endif /* NAP_REALLOC */

#ifndef NAP_FREE
#define NAP_FREE(nap_cd, p) Nap_Free(nap_cd, __FILE__, __LINE__, (void *) p)
#endif /* NAP_FREE */

#ifndef Nap_StrDup
#define Nap_StrDup(nap_cd, src) Nap_StrDup0(nap_cd, __FILE__, __LINE__, src)
#endif /* Nap_StrDup */

/*
 *  CHECK_PRE & CHECK_POST can be defined to do error handling, etc.
 *  See nap_hdf.c,m4 for example
 */

#ifndef CHECK_PRE
#define CHECK_PRE
#endif /* CHECK_PRE */

#ifndef CHECK_POST
#define CHECK_POST
#endif /* CHECK_POST */

#define CHECK(OK) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, ""); \
	CHECK_POST \
	return TCL_ERROR; \
    }

#define CHECK2(OK, FORMAT) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT); \
	CHECK_POST \
	return TCL_ERROR; \
    }

#define CHECK3(OK, FORMAT, A) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A); \
	CHECK_POST \
	return TCL_ERROR; \
    }

#define CHECK4(OK, FORMAT, A, B) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B); \
	CHECK_POST \
	return TCL_ERROR; \
    }

#define CHECK5(OK, FORMAT, A, B, C) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B, C); \
	CHECK_POST \
	return TCL_ERROR; \
    }

#define CHECK6(OK, FORMAT, A, B, C, D) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B, C, D); \
	CHECK_POST \
	return TCL_ERROR; \
    }

#define CHECK7(OK, FORMAT, A, B, C, D, E) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B, C, D, E); \
	CHECK_POST \
	return TCL_ERROR; \
    }

#define CHECK8(OK, FORMAT, A, B, C, D, E, F) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B, C, D, E, F); \
	CHECK_POST \
	return TCL_ERROR; \
    }

#define CHECK1NULL(OK) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, ""); \
	CHECK_POST \
	return NULL; \
    }

#define CHECK2NULL(OK, FORMAT) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT); \
	CHECK_POST \
	return NULL; \
    }

#define CHECK3NULL(OK, FORMAT, A) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A); \
	CHECK_POST \
	return NULL; \
    }

#define CHECK4NULL(OK, FORMAT, A, B) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B); \
	CHECK_POST \
	return NULL; \
    }

#define CHECK5NULL(OK, FORMAT, A, B, C) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B, C); \
	CHECK_POST \
	return NULL; \
    }

#define CHECK6NULL(OK, FORMAT, A, B, C, D) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B, C, D); \
	CHECK_POST \
	return NULL; \
    }

#define CHECK7NULL(OK, FORMAT, A, B, C, D, E) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B, C, D, E); \
	CHECK_POST \
	return NULL; \
    }

#define CHECK8NULL(OK, FORMAT, A, B, C, D, E, F) \
    if (! (OK)) { \
	CHECK_PRE \
	Nap_Check(nap_cd, __FILE__, __LINE__, FORMAT, A, B, C, D, E, F); \
	CHECK_POST \
	return NULL; \
    }

/* Nap_error is error handler called by yacc/bison */
#define Nap_error(message) \
    Nap_Check(Nap_param, __FILE__, __LINE__, message)

/*
 *  CHECK_NUM_ARGS provides interface to Tcl_WrongNumArgs.
 *  Assume objv contains arguments.
 *  Error message contains first N elements of objv followed by MSG.
 *  Example:
 *    CHECK_NUM_ARGS(objc > 1, 1, "<SUB-COMMAND> ...");
 */

#define CHECK_NUM_ARGS(OK, N, MSG) \
    if (! (OK)) { \
	Tcl_WrongNumArgs(nap_cd->interp, N, objv, MSG); \
	Nap_Check(nap_cd, __FILE__, __LINE__, ""); \
	return TCL_ERROR; \
    }

EXTERN void	Nap_Check(NapClientData *nap_cd, const char *file, const int line,
			const char *format, ...);
EXTERN void	Nap_CheckAppendLine(NapClientData *nap_cd, char *str);
EXTERN void	*Nap_Alloc(NapClientData *nap_cd, const char *file, const int line, size_t size);
EXTERN void	Nap_Free(NapClientData *nap_cd, const char *file, const int line, void *p);
EXTERN void	*Nap_Realloc(NapClientData *nap_cd, const char *file, const int line, void *p,
	size_t size);

#endif /* _NAP_CHECK */
