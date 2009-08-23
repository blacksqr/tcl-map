/*
 * land_flag.h --
 *
 * Copyright (c) 2001, CSIRO Australia
 *
 * Author: Peter Turner, CSIRO Atmospheric Research
 *
 * $Id: land_flag.h,v 1.2 2004/08/11 02:45:06 dav480 Exp $
 */

#include <tcl.h>

void
land_flag (
    unsigned char *dir,		/* data directory		*/
    int *max_y,			/* y dimension size		*/
    int *max_x,			/* x dimension size		*/
    float *latitude,		/* latitude array		*/
    float *longitude,           /* longitude array     		*/  
    signed char *surface_flag,	/* output mask          	*/
    int *err,			/* error state			*/
    unsigned char *msg,		/* error message		*/
    int *maxlen)		/* maximum error message size	*/
;

EXTERN int
Land_flag_Init(
    Tcl_Interp          *interp)
;
