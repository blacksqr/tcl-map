/*
 *	nap_get.c --
 *
 *	nap_get command
 *
 *	Copyright 2000, CSIRO Australia
 *	Author: Harvey Davies, CSIRO Atmospheric Research.
 */

#ifndef lint
static char *rcsid="@(#) $Id: nap_get.c,v 1.30 2006/11/09 06:21:13 dav480 Exp $";
#endif /* not lint */

#include "napInt.h"
#include "nap_hdf.h"
#include "nap_netcdf.h"

/*
 * Nap_GetBinary --
 *
 *  "nap_get binary" command.
 *
 *  Usage:
 *	nap_get binary|swap <CHANNEL> ?<DATATYPE>? ?<SHAPE>?
 *	    Get data from binary file & create nao.
 *	    <DATATYPE> is NAP datatype which can be: character, i8, i16, i32, u8,
 *		    u16, u32, f32 or f64 (Default: u8)
 *	    <SHAPE> is shape of result (Default: number of elements until end)
 *
 *  If premature end of file encountered then result is empty u8 vector.
 */

#undef TEXT0
#define TEXT0 "Nap_GetBinary: "

static int
Nap_GetBinary(
    NapClientData	*nap_cd,
    Tcl_Interp		*interp,
    int			objc,
    Tcl_Obj *CONST	objv[])
{
    Tcl_Channel		channel;	/* Tcl I/O channel */
    char		*channelName;	/* Tcl I/O channel ID */
    Nap_dataType	dataType;
    int			fileSize;
    int			i;
    char		io_error[] = TEXT0 "Error calling %s for channel %s";
    int			mode = TCL_READABLE;
    int			n;
    Nap_NAO		*naoPtr;
    int			rank;
    size_t		shape[NAP_MAX_RANK];
    Nap_NAO		*shape_NAO;
    size_t		size;
    int			start;		/* initial disk address */
    int			status;
    char		*subCommand; 	/* "binary" or "swap" */
    char		*str;
    int			toRead;		/* # bytes to read */

    CHECK_NUM_ARGS(objc >= 3  &&  objc <= 5, 2, "<CHANNEL> ?<DATATYPE>? ?<SHAPE>?");
    subCommand = Tcl_GetStringFromObj(objv[1], NULL);
    channelName = Tcl_GetStringFromObj(objv[2], NULL);
    str = objc < 4 ? "u8" : Tcl_GetStringFromObj(objv[3], NULL);
    dataType = Nap_TextToDataType(str);
    CHECK3(Nap_ValidDataType(dataType), TEXT0 "Invalid data-type %s", str);
    size = Nap_SizeOf(dataType);
    channel = Tcl_GetChannel(nap_cd->interp, channelName, &mode);
    CHECK4(channel, io_error, "Tcl_GetChannel", channelName);
    status = Tcl_SetChannelOption(nap_cd->interp, channel, "-translation", "binary");
    CHECK(status == TCL_OK);
    if (objc < 5) {
	rank = 1;
	start = Tcl_Tell(channel);
	CHECK4(start >= 0, io_error, "Tcl_Tell", channelName);
	status = Tcl_Seek(channel, 0, SEEK_END);
	fileSize = Tcl_Tell(channel);
	CHECK4(fileSize >= 0, io_error, "Tcl_Tell", channelName);
	status = Tcl_Seek(channel, start, SEEK_SET);
	shape[0] = (fileSize - start) / size;
    } else {
	naoPtr = Nap_GetNaoFromObj(nap_cd, objv[4]);
	CHECK2(naoPtr, TEXT0 "Error evaluating subscript");
	Nap_IncrRefCount(nap_cd, naoPtr);
	shape_NAO = Nap_CastNAO(nap_cd, naoPtr, NAP_I32);
	CHECK2(shape_NAO, TEXT0 "Error calling Nap_CastNAO");
	Nap_IncrRefCount(nap_cd, shape_NAO);
	Nap_DecrRefCount(nap_cd, naoPtr);
	rank = shape_NAO->nels;
	for (i = 0; i < rank; i++) {
	    shape[i] = shape_NAO->data.I32[i];
	}
	Nap_DecrRefCount(nap_cd, shape_NAO);
    }
    naoPtr = Nap_NewNAO(nap_cd, dataType, rank, shape);
    CHECK2(naoPtr, TEXT0 "Error calling Nap_NewNAO");
    toRead = naoPtr->nels * size;
    n = Tcl_Read(channel, naoPtr->data.c, toRead);
    if (n != toRead) {
	Nap_DecrRefCount(nap_cd, naoPtr);
	shape[0] = 0;
	naoPtr = Nap_NewNAO(nap_cd, NAP_U8, 1, shape);
    }
    if (subCommand[0] == 's'  &&  size > 1) {		/* swap bytes */
	status = Nap_swap_bytes(nap_cd, naoPtr->data.c, naoPtr->nels, size);
    }
    Nap_AppendStr(nap_cd, naoPtr->id);
    return TCL_OK;
}

/*
 *  Nap_GetHDF_metaVar --
 *
 *  Get meta-data for HDF variable (SDS).
 *
 *  Called by Nap_GetHDF_meta for following options:
 *	nap_get hdf -datatype <FILENAME> <NAME>
 *	nap_get hdf -dimension <FILENAME> <SDS_NAME>
 *	nap_get hdf -rank <FILENAME> <NAME>
 *	nap_get hdf -shape <FILENAME> <NAME>
 */

#undef TEXT0
#define TEXT0 "Nap_GetHDF_metaVar: "

static int
Nap_GetHDF_metaVar(
    NapClientData       *nap_cd,
    int			objc,
    Tcl_Obj *CONST	objv[],
    int			index)
{
    Nap_dataType	externalDataType;
    char		*fileName;
    int			i;
    Nap_dataType	internalDataType;
    char		*name;		/* <SDS_NAME>, <SDS_NAME>:<ATT_NAME> or :<ATT_NAME> */
    int			rank;
    char		s[999];
    size_t		shape[NAP_MAX_RANK];
    int			status;
    char		*str;

    fileName = Tcl_GetStringFromObj(objv[3], NULL);
    CHECK_NUM_ARGS(objc == 5, 4, "<NAME>");
    name = Tcl_GetStringFromObj(objv[4], NULL);
    status = Nap_HdfInfo(nap_cd, fileName, name, 0, &rank, shape, 
	    &externalDataType, &internalDataType);
    CHECK(status == TCL_OK);
    switch (index) {
    case 1: /* -datatype */
	str = Nap_DataTypeToText(nap_cd, externalDataType);
	CHECK2(str, TEXT0 "error calling Nap_DataTypeToText");
	status = Nap_AppendLines(nap_cd, str);
	CHECK(status == 0);
	NAP_FREE(nap_cd, str);
	break;
    case 2: /* -dimension */
	status = Nap_HdfDimNames(nap_cd, fileName, name);
	CHECK(status == TCL_OK);
	break;
    case 4: /* -rank */
	status = sprintf(s, "%d", rank);
	CHECK2(status > 0, TEXT0 "Error calling sprintf");
	status = Nap_AppendLines(nap_cd, s);
	CHECK(status == 0);
	break;
    case 5: /* -shape */
	for (i = 0; i < rank; i++) {
	    status = sprintf(s, "%d", (int) shape[i]);
	    CHECK2(status > 0, TEXT0 "Error calling sprintf");
	    status = Nap_AppendWords(nap_cd, s);
	    CHECK(status == 0);
	}
	break;
    default:
	assert(0);
    }
    return TCL_OK;
}

/*
 *  Nap_GetHDF_meta --
 *
 *  Get HDF meta-data.
 *
 *  Called by Nap_GetHDF for following options:
 *	nap_get hdf -coordinate <FILENAME> <SDS_NAME> <DIM_NAME>|<DIM_NUMBER>
 *	nap_get hdf -datatype <FILENAME> <NAME>
 *	nap_get hdf -dimension <FILENAME> <SDS_NAME>
 *	nap_get hdf -list <FILENAME> ?<REGULAR_EXPRESSION>?
 *	nap_get hdf -rank <FILENAME> <NAME>
 *	nap_get hdf -shape <FILENAME> <NAME>
 */

#undef TEXT0
#define TEXT0 "Nap_GetHDF_meta: "

static int
Nap_GetHDF_meta(
    NapClientData       *nap_cd,
    int			objc,
    Tcl_Obj *CONST	objv[])
{
    char		*dim_str;
    char		*fileName;
    int			index;
    char		*name_sds;
    CONST char		*option[] = {
				"-coordinate",
				"-datatype",
				"-dimension",
				"-list",
				"-rank",
				"-shape",
				(char *) NULL};
    char		*reg_exp;		/* regular expression */
    int			status;
    CONST char		*str;

    CHECK_NUM_ARGS(objc > 3, 2, "-<OPTION> <FILENAME> ...");
    status = Tcl_GetIndexFromObj(nap_cd->interp, objv[2], option, "option", 0, &index);
    if (status != TCL_OK) {
	CHECK(FALSE);
    }
    switch (index) {
    case 0: /* -coordinate */
	CHECK_NUM_ARGS(objc == 6, 4, "<SDS_NAME> <DIM_NAME>|<DIM_NUMBER>");
	fileName = Tcl_GetStringFromObj(objv[3], NULL);
	name_sds = Tcl_GetStringFromObj(objv[4], NULL);
	dim_str  = Tcl_GetStringFromObj(objv[5], NULL);
	status = Nap_HdfCoordVar(nap_cd, fileName, name_sds, dim_str);
	CHECK(status == TCL_OK);
	break;
    case 3: /* -list */
	CHECK_NUM_ARGS(objc == 4  ||  objc == 5, 3, "<FILENAME> ?<REGULAR_EXPRESSION>?");
	fileName = Tcl_GetStringFromObj(objv[3], NULL);
	if (objc == 5) {
	    reg_exp = Tcl_GetStringFromObj(objv[4], NULL);
	} else {
	    reg_exp = "";
	}
	status = Nap_HdfList(nap_cd, fileName, reg_exp);
	CHECK(status == TCL_OK);
	break;
    default:
	status = Nap_GetHDF_metaVar(nap_cd, objc, objv, index);
	CHECK(status == 0);
    }
    return TCL_OK;
}

/*
 * Nap_GetHDF --
 *
 *  "nap_get hdf" command.
 *
 *  Called by Nap_GetCmd for following options:
 *	nap_get hdf <FILENAME> <NAME> ?<INDEX>? ?<RAW>?
 *	nap_get hdf -coordinate <FILENAME> <SDS_NAME> <DIM_NAME>|<DIM_NUMBER>
 *	nap_get hdf -datatype <FILENAME> <NAME>
 *	nap_get hdf -dimension <FILENAME> <SDS_NAME>
 *	nap_get hdf -list <FILENAME> ?<REGULAR_EXPRESSION>?
 *	nap_get hdf -rank <FILENAME> <NAME>
 *	nap_get hdf -shape <FILENAME> <NAME>
 */

#undef TEXT0
#define TEXT0 "Nap_GetHDF: "

static int
Nap_GetHDF(
    NapClientData	*nap_cd,
    Tcl_Interp		*interp,
    int			objc,
    Tcl_Obj *CONST	objv[])
{
    int			exists;			/* SDS exists? */
    Nap_dataType	externalDataType;
    char		*fileName;
    size_t		hdf_shape[NAP_MAX_RANK];
    int			i;
    Nap_dataType	internalDataType;
    int			j;
    Nap_NAO		*naoPtr;
    Nap_NAO		*new_nao;
    size_t		new_shape[NAP_MAX_RANK];
    int			new_rank;
    int			rank;
    int			raw = 0;		/* 1 to request raw data */
    int32		sd_id;
    int32		sds_id;
    char		*sds_name;
    size_t		shape[NAP_MAX_RANK];
    int			status;
    int			status2;
    char		*str;
    Nap_NAO		*subscript_NAO = NULL;	/* pointer to subscript nao */
    Nap_NAO		*tmp_NAO;		/* pointer to temporary nao */
    int			want_dim[NAP_MAX_RANK];	/* Include this dimension? */

    CHECK_NUM_ARGS(objc > 2, 2, "?-<OPTION>? <FILENAME> ...");
    str = Tcl_GetStringFromObj(objv[2], NULL);
    if (str[0] == '-') {
	status = Nap_GetHDF_meta(nap_cd, objc, objv);
	CHECK(status == TCL_OK);
    } else {
	CHECK_NUM_ARGS(objc >= 4  &&  objc <= 6, 2, "<FILENAME> <SDS_NAME> ?<INDEX>? ?<RAW>?");
	fileName = Tcl_GetStringFromObj(objv[2], NULL);
	sds_name = Tcl_GetStringFromObj(objv[3], NULL);
	if (objc > 5  &&  Tcl_GetCharLength(objv[5]) > 0) {
	    status = Tcl_GetBooleanFromObj(interp, objv[5], &raw);
	    CHECK2(status == TCL_OK  &&  (raw == 0  ||  raw == 1),
		    TEXT0 "Argument <RAW> is not 0 or 1");
	}
	status = Nap_HdfInfo(nap_cd, fileName, sds_name, raw, &rank,
		hdf_shape, &externalDataType, &internalDataType);
	CHECK(status == TCL_OK);
	if (objc > 4  &&  Tcl_GetCharLength(objv[4]) > 0) {
	    status = Nap_HdfOpenFile(nap_cd, fileName, 'r', &sd_id);
	    CHECK3(status == TCL_OK, TEXT0 "Error opening file %s", fileName);
	    status = Nap_HdfOpenSDS(nap_cd, sd_id, sds_name, &exists, &sds_id);
	    if (!exists) {
		status = Nap_HdfCloseFile(nap_cd, sd_id);
		CHECK3(0, "TEXT0: SDS %s not found", sds_name);
	    }
	    status = nap_HdfGetIndex(nap_cd, sds_id, objv[4], &subscript_NAO);
	    CHECK2(status == 0, TEXT0 "Error evaluating index");
	    Nap_IncrRefCount(nap_cd, subscript_NAO);
	    CHECK2(subscript_NAO->rank <= 1, TEXT0 "Subscript rank > 1");
	    CHECK2(subscript_NAO->nels <= rank, TEXT0 "# elements in subscript > hdf rank");
	    for (i = 0; i < rank; i++) {
		if (i < subscript_NAO->nels  &&	 subscript_NAO->data.Boxed[i]) {
		    tmp_NAO = Nap_GetNaoFromSlot(subscript_NAO->data.Boxed[i]);
		    CHECK2(tmp_NAO->rank <= 1, TEXT0 "Subscript element rank > 1");
		    shape[i] = tmp_NAO->nels;
		    want_dim[i] = tmp_NAO->rank;
		} else {
		    shape[i] = hdf_shape[i];
		    want_dim[i] = 1;
		}
	    }
	    naoPtr = Nap_NewNAO(nap_cd, internalDataType, rank, shape);
	    status = Nap_HdfCloseSDS(nap_cd, sds_id);
	    CHECK(status == TCL_OK);
	    status = Nap_HdfCloseFile(nap_cd, sd_id);
	    CHECK(status == TCL_OK);
	} else {
	    for (i = 0; i < rank; i++) {
		shape[i] = hdf_shape[i];
		want_dim[i] = 1;
	    }
	    naoPtr = Nap_NewNAO(nap_cd, internalDataType, rank, shape);
	}
	status = Nap_HdfOpenFile(nap_cd, fileName, 'r', &sd_id);
	CHECK3(status == TCL_OK, TEXT0 "Error opening file %s", fileName);
	status = Nap_HdfGet(nap_cd, sd_id, sds_name, subscript_NAO, raw, naoPtr);
	status2 = Nap_HdfCloseFile(nap_cd, sd_id);
	CHECK2(status == 0, TEXT0 "Error calling Nap_HdfGet");
	CHECK(status2 == TCL_OK);
	new_rank = 0;
	for (i = 0; i < rank; i++) {
	    if (want_dim[i]) {
		new_shape[new_rank++] = shape[i];
	    }
	}
	if (new_rank == rank) {
	    Nap_AppendStr(nap_cd, naoPtr->id);
	} else {
	    new_nao = Nap_ReshapeNAO(nap_cd, naoPtr, internalDataType, new_rank, new_shape);
	    CHECK2(new_nao, TEXT0 "Error calling Nap_ReshapeNAO");
	    status = Nap_SetMissing(nap_cd, new_nao, naoPtr->missingValueSlot);
	    CHECK2(status == TCL_OK, "m4NAME: Error calling Nap_SetMissing");
	    for (i = j = 0; i < rank; i++) {
		if (want_dim[i]) {
		    tmp_NAO = Nap_GetCoordVar(nap_cd, naoPtr, i);
		    status = Nap_AttachCoordVar(nap_cd, new_nao, tmp_NAO, naoPtr->dimName[i], j++);
		    CHECK2(status == 0, TEXT0 "Error calling Nap_AttachCoordVar");
		}
	    }
	    Nap_FreeNAO(nap_cd, naoPtr);
	    Nap_AppendStr(nap_cd, new_nao->id);
	}
	Nap_DecrRefCount(nap_cd, subscript_NAO);
    }
    return TCL_OK;
}

/*
 *  Nap_GetNetcdf_metaVar --
 *
 *  Get meta-data for netCDF variable.
 *
 *  Called by Nap_GetNetcdf_meta for following options:
 *	nap_get netcdf -datatype <FILENAME> <NAME>
 *	nap_get netcdf -dimension <FILENAME> <VAR_NAME>
 *	nap_get netcdf -rank <FILENAME> <NAME>
 *	nap_get netcdf -shape <FILENAME> <NAME>
 */

#undef TEXT0
#define TEXT0 "Nap_GetNetcdf_metaVar: "

static int
Nap_GetNetcdf_metaVar(
    NapClientData       *nap_cd,
    int			objc,
    Tcl_Obj *CONST	objv[],
    int			index)
{
    Nap_dataType	externalDataType;
    char		*fileName;
    int			i;
    Nap_dataType	internalDataType;
    char		*name;		/* <VAR_NAME>, <VAR_NAME>:<ATT_NAME> or :<ATT_NAME> */
    int			rank;
    char		s[999];
    size_t		shape[NAP_MAX_RANK];
    int			status;
    char		*str;

    fileName = Tcl_GetStringFromObj(objv[3], NULL);
    CHECK_NUM_ARGS(objc == 5, 4, "<NAME>");
    name = Tcl_GetStringFromObj(objv[4], NULL);
    status = Nap_NetcdfInfo(nap_cd, fileName, name, 0, &rank, shape,
	    &externalDataType, &internalDataType);
    CHECK(status == TCL_OK);
    switch (index) {
    case 1: /* -datatype */
	str = Nap_DataTypeToText(nap_cd, externalDataType);
	CHECK2(str, TEXT0 "error calling Nap_DataTypeToText");
	status = Nap_AppendLines(nap_cd, str);
	CHECK(status == 0);
	NAP_FREE(nap_cd, str);
	break;
    case 2: /* -dimension */
	status = Nap_NetcdfDimNames(nap_cd, fileName, name);
	CHECK(status == TCL_OK);
	break;
    case 4: /* -rank */
	status = sprintf(s, "%d", rank);
	CHECK2(status > 0, TEXT0 "Error calling sprintf");
	status = Nap_AppendLines(nap_cd, s);
	CHECK(status == 0);
	break;
    case 5: /* -shape */
	for (i = 0; i < rank; i++) {
	    status = sprintf(s, "%d", (int) shape[i]);
	    CHECK2(status > 0, TEXT0 "Error calling sprintf");
	    status = Nap_AppendWords(nap_cd, s);
	    CHECK(status == 0);
	}
	break;
    default:
	assert(0);
    }
    return TCL_OK;
}

/*
 *  Nap_GetNetcdf_meta --
 *
 *  Get netCDF meta-data.
 *
 *  Called by Nap_GetNetcdf for following options:
 *	nap_get netcdf -coordinate <FILENAME> <VAR_NAME> <DIM_NAME>|<DIM_NUMBER>
 *	nap_get netcdf -datatype <FILENAME> <NAME>
 *	nap_get netcdf -dimension <FILENAME> <VAR_NAME>
 *	nap_get netcdf -list <FILENAME> ?<REGULAR_EXPRESSION>?
 *	nap_get netcdf -rank <FILENAME> <NAME>
 *	nap_get netcdf -shape <FILENAME> <NAME>
 */

#undef TEXT0
#define TEXT0 "Nap_GetNetcdf_meta: "

static int
Nap_GetNetcdf_meta(
    NapClientData       *nap_cd,
    int			objc,
    Tcl_Obj *CONST	objv[])
{
    char		*dim_str;
    char		*fileName;
    int			index;
    char		*name_var;
    CONST char		*option[] = {
				"-coordinate",
				"-datatype",
				"-dimension",
				"-list",
				"-rank",
				"-shape",
				(char *) NULL};
    char		*reg_exp;		/* regular expression */
    int			status;
    CONST char		*str;

    CHECK_NUM_ARGS(objc > 3, 2, "-<OPTION> <FILENAME> ...");
    status = Tcl_GetIndexFromObj(nap_cd->interp, objv[2], option, "option", 0, &index);
    if (status != TCL_OK) {
	CHECK(FALSE);
    }
    switch (index) {
    case 0: /* -coordinate */
	CHECK_NUM_ARGS(objc == 6, 4, "<VAR_NAME> <DIM_NAME>|<DIM_NUMBER>");
	fileName = Tcl_GetStringFromObj(objv[3], NULL);
	name_var = Tcl_GetStringFromObj(objv[4], NULL);
	dim_str  = Tcl_GetStringFromObj(objv[5], NULL);
	status = Nap_NetcdfCoordVar(nap_cd, fileName, name_var, dim_str);
	CHECK(status == TCL_OK);
	break;
    case 3: /* -list */
	CHECK_NUM_ARGS(objc == 4  ||  objc == 5, 3, "<FILENAME> ?<REGULAR_EXPRESSION>?");
	fileName = Tcl_GetStringFromObj(objv[3], NULL);
	if (objc == 5) {
	    reg_exp = Tcl_GetStringFromObj(objv[4], NULL);
	} else {
	    reg_exp = "";
	}
	status = Nap_NetcdfList(nap_cd, fileName, reg_exp);
	CHECK(status == 0);
	break;
    default:
	status = Nap_GetNetcdf_metaVar(nap_cd, objc, objv, index);
	CHECK(status == 0);
    }
    return TCL_OK;
}

/*
 * Nap_GetNetcdf --
 *
 *  "nap_get netcdf" command.
 *
 *  Called by Nap_GetCmd for following options:
 *	nap_get netcdf <FILENAME> <NAME> ?<INDEX>? ?<RAW>?
 *	nap_get netcdf -coordinate <FILENAME> <VAR_NAME> <DIM_NAME>|<DIM_NUMBER>
 *	nap_get netcdf -datatype <FILENAME> <NAME>
 *	nap_get netcdf -dimension <FILENAME> <VAR_NAME>
 *	nap_get netcdf -list <FILENAME> ?<REGULAR_EXPRESSION>?
 *	nap_get netcdf -rank <FILENAME> <NAME>
 *	nap_get netcdf -shape <FILENAME> <NAME>
 */

#undef TEXT0
#define TEXT0 "Nap_GetNetcdf: "

static int
Nap_GetNetcdf(
    NapClientData	*nap_cd,
    Tcl_Interp		*interp,
    int			objc,
    Tcl_Obj *CONST	objv[])
{
    Nap_dataType	externalDataType;
    int			exists;			/* Var exists? */
    char		*fileName;
    Nap_dataType	internalDataType;
    size_t		netcdf_shape[NAP_MAX_RANK];
    int			i;
    int			j;
    int			ncid;			/* file handle */
    Nap_NAO		*naoPtr;
    Nap_NAO		*new_nao;
    int			new_rank;
    size_t		new_shape[NAP_MAX_RANK];
    int			rank;
    int			raw = 0;		/* 1 to request raw data */
    char		*var_name;
    size_t		shape[NAP_MAX_RANK];
    int			status;
    int			status2;
    char		*str;
    Nap_NAO		*subscript_NAO = NULL;	/* pointer to subscript nao */
    Nap_NAO		*tmp_NAO;		/* pointer to temporary nao */
    int			want_dim[NAP_MAX_RANK]; /* Include this dimension? */
    int			varid;			/* Var handle */

    CHECK_NUM_ARGS(objc > 2, 2, "?-<OPTION>? <FILENAME> ...");
    str = Tcl_GetStringFromObj(objv[2], NULL);
    if (str[0] == '-') {
	status = Nap_GetNetcdf_meta(nap_cd, objc, objv);
	CHECK(status == TCL_OK);
    } else {
	CHECK_NUM_ARGS(objc >= 4  &&  objc <= 6, 2, "<FILENAME> <VAR_NAME> ?<INDEX>? ?<RAW>?");
	fileName = Tcl_GetStringFromObj(objv[2], NULL);
	var_name = Tcl_GetStringFromObj(objv[3], NULL);
	if (objc > 5  &&  Tcl_GetCharLength(objv[5]) > 0) {
	    status = Tcl_GetBooleanFromObj(interp, objv[5], &raw);
	    CHECK2(status == TCL_OK  &&  (raw == 0  ||  raw == 1),
		    TEXT0 "Argument <RAW> is not 0 or 1");
	}
	status = Nap_NetcdfInfo(nap_cd, fileName, var_name, raw,
		&rank, netcdf_shape, &externalDataType, &internalDataType);
	CHECK(status == TCL_OK);
	if (objc > 4  &&  Tcl_GetCharLength(objv[4]) > 0) {
	    status = Nap_NetcdfOpenFile(nap_cd, fileName, 'r', &ncid);
	    CHECK3(status == TCL_OK, TEXT0 "Error opening file %s", fileName);
	    status = Nap_NetcdfOpenVar(nap_cd, ncid, var_name, &exists, &varid);
	    if (!exists) {
		status = Nap_NetcdfCloseFile(nap_cd, ncid);
		CHECK3(0, "TEXT0: Variable %s not found", var_name);
	    }
	    status = nap_NetcdfGetIndex(nap_cd, ncid, varid, objv[4], &subscript_NAO);
	    CHECK2(status == 0, TEXT0 "Error evaluating index");
	    Nap_IncrRefCount(nap_cd, subscript_NAO);
	    CHECK2(subscript_NAO->rank <= 1, TEXT0 "Subscript rank > 1");
	    CHECK2(subscript_NAO->nels <= rank, TEXT0 "# elements in subscript > netCDF rank");
	    for (i = 0; i < rank; i++) {
		if (i < subscript_NAO->nels  &&	 subscript_NAO->data.Boxed[i]) {
		    tmp_NAO = Nap_GetNaoFromSlot(subscript_NAO->data.Boxed[i]);
		    CHECK2(tmp_NAO->rank <= 1, TEXT0 "Subscript element rank > 1");
		    shape[i] = tmp_NAO->nels;
		    want_dim[i] = tmp_NAO->rank;
		} else {
		    shape[i] = netcdf_shape[i];
		    want_dim[i] = 1;
		}
	    }
	    naoPtr = Nap_NewNAO(nap_cd, internalDataType, rank, shape);
	    status = Nap_NetcdfCloseFile(nap_cd, ncid);
	    CHECK(status == TCL_OK);
	} else {
	    for (i = 0; i < rank; i++) {
		shape[i] = netcdf_shape[i];
		want_dim[i] = 1;
	    }
	    naoPtr = Nap_NewNAO(nap_cd, internalDataType, rank, shape);
	}
	status = Nap_NetcdfOpenFile(nap_cd, fileName, 'r', &ncid);
	CHECK3(status == TCL_OK, TEXT0 "Error opening file %s", fileName);
	status = Nap_NetcdfGet(nap_cd, ncid, var_name, subscript_NAO, raw, naoPtr);
	status2 = Nap_NetcdfCloseFile(nap_cd, ncid);
	CHECK2(status == TCL_OK, TEXT0 "Error calling Nap_NetcdfGet");
	CHECK(status2 == TCL_OK);
	new_rank = 0;
	for (i = 0; i < rank; i++) {
	    if (want_dim[i]) {
		new_shape[new_rank++] = shape[i];
	    }
	}
	if (new_rank == rank) {
	    Nap_AppendStr(nap_cd, naoPtr->id);
	} else {
	    new_nao = Nap_ReshapeNAO(nap_cd, naoPtr, internalDataType, new_rank, new_shape);
	    CHECK2(new_nao, TEXT0 "Error calling Nap_ReshapeNAO");
	    status = Nap_SetMissing(nap_cd, new_nao, naoPtr->missingValueSlot);
	    CHECK2(status == TCL_OK, "m4NAME: Error calling Nap_SetMissing");
	    for (i = j = 0; i < rank; i++) {
		if (want_dim[i]) {
		    tmp_NAO = Nap_GetCoordVar(nap_cd, naoPtr, i);
		    status = Nap_AttachCoordVar(nap_cd, new_nao, tmp_NAO, naoPtr->dimName[i], j++);
		    CHECK2(status == 0, TEXT0 "Error calling Nap_AttachCoordVar");
		}
	    }
	    Nap_FreeNAO(nap_cd, naoPtr);
	    Nap_AppendStr(nap_cd, new_nao->id);
	}
	Nap_DecrRefCount(nap_cd, subscript_NAO);
    }
    return TCL_OK;
}

/*
 *  Nap_GetCmd --
 *
 *  nap_get command.
 *
 *  Usage can be any of the following:
 *	(Note that in following 'variable' means 'SDS' in HDF context.)
 *
 *	nap_get binary <CHANNEL> ?<DATATYPE>? ?<SHAPE>?
 *	    Get data from binary file & create nao.
 *	    <DATATYPE> is NAP datatype which can be: c8, i8, i16, i32, u8,
 *		    u16, u32, f32 or f64 (Default: u8)
 *	    <SHAPE> is shape of result (Default: number of elements until end)
 *
 *	nap_get swap <CHANNEL> ?<DATATYPE>? ?<SHAPE>?
 *	    Same as sub-command "binary" except that that reverse order of bytes within elements
 *
 *	nap_get <FORMAT> <FILENAME> <NAME> ?<INDEX>? ?<RAW>?
 *		where <FORMAT> is hdf or netcdf
 *		      <NAME> is <VAR_NAME>, <VAR_NAME>:<ATT_NAME> or :<ATT_NAME>
 *		      <INDEX> selects using cross-product indexing. Unary @@ is allowed.
 *			    Default: whole array
 *		      <RAW> 1: Ignore attributes (scale_factor, add_offset, valid_range, etc.)
 *			    0 (default): Use these attributes.
 *	    Result is nao-id of new nao containing data read from hdf or netCDF file.
 *
 *	nap_get <FORMAT> -coordinate <FILENAME> <VAR_NAME> <DIM_NAME>|<DIM_NUMBER>
 *		where <FORMAT> is hdf or netcdf
 *	    Result is nao-id of new nao containing coordinate variable.
 *
 *	nap_get <FORMAT> -datatype <FILENAME> <NAME>
 *		where <FORMAT> is hdf or netcdf
 *		      <NAME> is <VAR_NAME>, <VAR_NAME>:<ATT_NAME> or :<ATT_NAME>
 *	    Result is external (file) datatype.
 *
 *	nap_get <FORMAT> -dimension <FILENAME> <VAR_NAME>
 *		where <FORMAT> is hdf or netcdf
 *	    Result is list of names of dimensions.
 *
 *	nap_get <FORMAT> -list <FILENAME> ?<REGULAR_EXPRESSION>?
 *		where <FORMAT> is hdf or netcdf
 *	    List selected variables and attributes in specified file.
 *	    Attributes have form <VAR_NAME>:<ATT_NAME>.
 *
 *	    A <REGULAR_EXPRESSION> can be specified to filter these as in
 *	    the following examples:
 *	    nap_get hdf -list abc.hdf {^xyz(:.*)?$} ;# SDS xyz & its attributes
 *	    nap_get hdf -list abc.hdf {:}	    ;# no SDSs, all attributes
 *	    nap_get netcdf -list abc.nc {^[^:]*$}   ;# all variables, no attributes
 *
 *	nap_get <FORMAT> -rank <FILENAME> <NAME>
 *		where <FORMAT> is hdf or netcdf
 *		      <NAME> is <VAR_NAME>, <VAR_NAME>:<ATT_NAME> or :<ATT_NAME>
 *	    Result is rank (number of dimensions).
 *
 *	nap_get <FORMAT> -shape <FILENAME> <NAME>
 *		where <FORMAT> is hdf or netcdf
 *		      <NAME> is <VAR_NAME>, <VAR_NAME>:<ATT_NAME> or :<ATT_NAME>
 *	    Result is shape (dimension sizes).
 */

#undef TEXT0
#define TEXT0 "Nap_GetCmd: "

EXTERN int
Nap_GetCmd(
    ClientData		clientData,
    Tcl_Interp		*interp,
    int			objc,
    Tcl_Obj		*CONST objv[])
{
    int			index;
    NapClientData	*nap_cd = (NapClientData *) clientData;
    int			status;
    CONST char		*str;

    CONST char		*subCommands[] = {
				"binary",
				"swap",
				"hdf",
				"netcdf",
				(char *) NULL};

    nap_cd->errorCode = 0;
    CHECK_NUM_ARGS(objc > 1, 1, "binary|hdf|netcdf ...");
    Nap_InitTclResult(nap_cd);
    status = Tcl_GetIndexFromObj(interp, objv[1], subCommands, "sub-command", 0, &index);
    if (status != TCL_OK) {
	CHECK(FALSE);
    }
    switch (index) {
    case 0: /* binary */
    case 1: /* swap */
	status = Nap_GetBinary((NapClientData  *) clientData, interp, objc, objv);
	CHECK(status == TCL_OK);
	break;
    case 2: /* hdf */
	status = Nap_GetHDF(   (NapClientData  *) clientData, interp, objc, objv);
	CHECK(status == TCL_OK);
	break;
    case 3: /* netcdf */
	status = Nap_GetNetcdf((NapClientData  *) clientData, interp, objc, objv);
	CHECK(status == TCL_OK);
	break;
    default:
	assert(0);
    }
    Nap_SetTclResult(nap_cd);
    return TCL_OK;
}
