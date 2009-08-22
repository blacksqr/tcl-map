/*
 * nap_netcdf.h --
 *
 * Copyright (c) 2000, CSIRO Australia
 *
 * NAP interface to netCDF.
 *
 * Author: Harvey Davies, CSIRO Atmospheric Research
 *
 * $Id: nap_netcdf.h,v 1.10 2005/05/27 02:22:46 dav480 Exp $
 */

#ifndef _NAP_NETCDF
#define _NAP_NETCDF

#define NO_NETCDF_2
#include <netcdf.h>
#include "nap.h"
#include "nap_check.h"

EXTERN int
Nap_NetcdfOpenFile(
    NapClientData       *nap_cd,
    char		*fileName,		/* netCDF file name */
    char		mode,			/* 'r' = read, 'w' = write */
    int			*nc_id)			/* file handle (out) */
;

EXTERN int
Nap_NetcdfCloseFile(
    NapClientData       *nap_cd,
    int			ncid)			/* file handle */
;

EXTERN int
Nap_NetcdfOpenVar(
    NapClientData       *nap_cd,
    int			ncid,			/* file handle */
    char		*name_var,		/* Var name */
    int			*exists,		/* Var exists? (out) */
    int			*varid)			/* Var handle (out) */
;

EXTERN int
Nap_NetcdfCoordVar(
    NapClientData       *nap_cd,
    char		*fileName,		/* netCDF file name */
    char		*name_var,		/* netCDF variable name */
    char		*dim_str)		/* dimension name or number */
;

EXTERN int
Nap_NetcdfDimNames(
    NapClientData       *nap_cd,
    char		*fileName,		/* netCDF file name */
    char		*name_var)		/* netCDF variable name */
;

EXTERN int
Nap_NetcdfGet(
    NapClientData       *nap_cd,
    int			ncid,			/* file handle */
    char		*var_name,		/* netCDF var (var) name */
    Nap_NAO		*subscript_NAO, 	/* pointer to subscript nao */
    int			raw,			/* 1 to request raw data */
    Nap_NAO		*main_NAO)		/* pointer to main nao (out) */
;

EXTERN int
Nap_NetcdfInfo(
    NapClientData       *nap_cd,
    char		*fileName,		/* netCDF file name */
    char		*var_name,		/* netCDF var (var) name */
    int                 raw,            	/* 1 to request raw data */
    int			*rank,			/* rank of var (out) */
    size_t		shape[NAP_MAX_RANK],	/* shape of var (out) */
    Nap_dataType	*externalDataType,	/* datatype of var (out) */
    Nap_dataType	*internalDataType)	/* datatype of NAO (out) */
;

EXTERN int
nap_NetcdfGetIndex(
    NapClientData       *nap_cd,
    int			ncid,			/* file handle */
    int			varid,			/* netCDF var ID */
    Tcl_Obj		*indexObj,		/* index arg. */
    Nap_NAO		**index_nao)		/* result (out) */
;

EXTERN int
Nap_NetcdfList(
    NapClientData       *nap_cd,
    char		*fileName,		/* netCDF file name */
    char		*reg_exp)		/* regular expression */
;

EXTERN int
Nap_OOC_netcdf(
    NapClientData       *nap_cd,
    int			objc,
    Tcl_Obj *CONST	objv[],
    Nap_NAO		*naoPtr)
;

#endif /* _NAP_NETCDF */
