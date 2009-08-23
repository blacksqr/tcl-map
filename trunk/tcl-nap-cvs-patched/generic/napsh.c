/* 
 * napTclsh.c --
 *
 * Copyright (c) 1999, CSIRO Australia
 *
 * Author: Harvey Davies, CSIRO Atmospheric Research
 */

#ifndef lint
static char *rcsid="@(#) $Id: napsh.c,v 1.7 2005/11/30 06:09:34 dav480 Exp $";
#endif /* not lint */

#if defined(USE_TCL_STUBS) && ! defined(MAKE_DEPEND)
    #error USE_TCL_STUBS should not be defined! Use 'configure --disable-load'. 
#endif /* USE_TCL_STUBS */

#include "napInt.h"
#include <tcl.h>

/*
 *  Tcl_AppInit --
 *      Initialise whole system
 */

EXTERN int
Tcl_AppInit(
    Tcl_Interp          *interp)        /* Interpreter for application. */
{
    int                 status;         /* return code */

    status = Tcl_Init(interp);
    if (status != TCL_OK) {
        return status;
    }
    Tcl_InitMemory(interp);
    status = Nap_Init(interp);
    if (status != TCL_OK) {
        return status;
    }
    Tcl_StaticPackage(interp, "Nap", Nap_Init, NULL);
    return TCL_OK;
}

/*
 *  main --
 *	This simply calls Tcl_Main.
 */

EXTERN int
main(
    int argc, 
    char *argv[])
{
    Tcl_Main(argc, argv, Tcl_AppInit);
    return 0;                   /* Needed only to prevent compiler warning. */
}
