/*
 * napInt.h --
 *
 * Copyright (c) 1999, CSIRO Australia
 *
 * Author: Harvey Davies, CSIRO Atmospheric Research
 *
 * $Id: napInt.h,v 1.10 2002/06/03 06:53:49 dav480 Exp $
 */

#ifndef _NAP_INT_H
#define _NAP_INT_H

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <tcl.h>

/*
 * Following from Scriptics page headed "Building Extensions on Windows".
 */

#ifdef BUILD_nap
#  undef TCL_STORAGE_CLASS
#  define TCL_STORAGE_CLASS DLLEXPORT
#endif

/*
 * Function prototypes
 */

EXTERN int
Nap_Init(
    Tcl_Interp *interp)
;

EXTERN int
Nap_Cmd(
    ClientData          clientData,
    Tcl_Interp          *interp,
    int                 objc,
    Tcl_Obj *CONST      objv[])
;

EXTERN int
Nap_GetCmd(
    ClientData          clientData,
    Tcl_Interp          *interp,
    int                 objc,
    Tcl_Obj *CONST      objv[])
;

EXTERN int
Nap_InfoCmd(
    ClientData          clientData,
    Tcl_Interp          *interp,
    int                 objc,
    Tcl_Obj *CONST      objv[])
;

#endif /* _NAP_INT_H */
