/*
 * nap_hdf.h --
 *
 * Copyright (c) 2000, CSIRO Australia
 *
 * NAP interface to HDF.
 *
 * Author: Harvey Davies, CSIRO Atmospheric Research
 *
 * $Id: nap_hdf.h,v 1.14 2005/05/27 02:19:11 dav480 Exp $
 */

#ifndef _NAP_HDF
#define _NAP_HDF

#define MAX_NC_NAME 128

#undef VOID
#undef VOIDP
#include <mfhdf.h>

#include "nap.h"
#include "nap_check.h"

#define NAP_NULL_HDF_DATA_TYPE		DFNT_NONE
#define NAP_C8_HDF_DATA_TYPE		DFNT_CHAR
#define NAP_I8_HDF_DATA_TYPE		DFNT_INT8
#define NAP_U8_HDF_DATA_TYPE		DFNT_UINT8
#define NAP_I16_HDF_DATA_TYPE		DFNT_INT16
#define NAP_U16_HDF_DATA_TYPE		DFNT_UINT16
#define NAP_I32_HDF_DATA_TYPE		DFNT_INT32
#define NAP_U32_HDF_DATA_TYPE		DFNT_UINT32
#define NAP_F32_HDF_DATA_TYPE		DFNT_FLOAT32
#define NAP_F64_HDF_DATA_TYPE		DFNT_FLOAT64

EXTERN Nap_dataType
Nap_Hdf2NapDataType(
    int32 dataType);

EXTERN int
Nap_HdfOpenFile(
    NapClientData       *nap_cd,
    char		*fileName,		/* HDF file name */
    char		mode,			/* 'r' = read, 'w' = write */
    int32		*sd_id)			/* file handle (out) */
;

EXTERN int
Nap_HdfCloseFile(
    NapClientData       *nap_cd,
    int32		sd_id)			/* file handle */
;

EXTERN int
Nap_HdfOpenSDS(
    NapClientData       *nap_cd,
    int32		sd_id,			/* file handle */
    char		*name_sds,		/* SDS name */
    int			*exists,		/* SDS exists? (out) */
    int32		*sds_id)		/* SDS handle (out) */
;

EXTERN int
Nap_HdfCloseSDS(
    NapClientData       *nap_cd,
    int32		sds_id)			/* SDS handle */
;

EXTERN int
Nap_HdfCoordVar(
    NapClientData       *nap_cd,
    char		*fileName,		/* HDF file name */
    char		*name_sds,		/* HDF sds (var) name */
    char		*dim_str);		/* dimension name or number */

EXTERN int
Nap_HdfDimNames(
    NapClientData *nap_cd,
    char *fileName,
    char *name_sds);

EXTERN int
Nap_HdfGet(
    NapClientData       *nap_cd,
    int32		sd_id,		/* file handle */
    char                *sds_name,      /* HDF sds (var) name */
    Nap_NAO             *subscript_NAO, /* pointer to subscript nao */
    int                 raw,            /* 1 to request raw data */
    Nap_NAO             *main_NAO)      /* pointer to main nao (out) */
;

EXTERN int
Nap_HdfInfo(
    NapClientData	*nap_cd,
    char		*fileName,		/* HDF file name */
    char		*sds_name,		/* HDF sds (var) name */
    int                 raw,			/* 1 to request raw data */
    int			*rank,			/* rank of sds (out) */
    size_t		shape[NAP_MAX_RANK],	/* shape of sds (out) */
    Nap_dataType	*externalDataType,	/* datatype of sds (out) */
    Nap_dataType	*internalDataType)	/* datatype of NAO (out) */
;

EXTERN int
nap_HdfGetIndex(
    NapClientData       *nap_cd,
    int32		sds_id,
    Tcl_Obj		*indexObj,		/* index arg. */
    Nap_NAO		**index_nao)		/* result (out) */
;

EXTERN int
Nap_HdfList(
    NapClientData *nap_cd,
    char *fileName,
    char *reg_exp);

EXTERN int
Nap_HdfPut(
    NapClientData       *nap_cd,
    int32		sd_id,			/* File handle */
    char		*sds_name,		/* HDF sds (var) name */
    Nap_dataType	sds_dataType,		/* HDF data type for new SDS */
    Nap_NAO		*scale_factor_NAO,	/* for new SDS */
    Nap_NAO		*add_offset_NAO,	/* for new SDS */
    Nap_NAO		*valid_range_NAO,	/* for new SDS */
    Nap_NAO		*main_NAO,		/* pointer to main nao */
    Nap_NAO		*boxed_cv_hdf,		/* pointers to CV NAOs */
    Tcl_Obj		*indexObj,		/* index */
    int			isRecord)		/* Want unlimited dim in new sds? */
;

EXTERN int32
Nap_Nap2HdfDataType(
    Nap_dataType dataType);

EXTERN int
Nap_OOC_hdf(
    NapClientData *nap_cd,
    int objc,
    Tcl_Obj *CONST objv[],
    Nap_NAO *naoPtr);

#endif /* _NAP_HDF */
