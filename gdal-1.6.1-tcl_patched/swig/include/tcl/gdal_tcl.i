/*
 *
 * tcl specific code for gdal bindings.
 */

%{
#include<napInt.h>
#include<nap.h>
#include<nap_check.h>
%}

%init %{
  /* gdal_tcl.i %init code */
  if ( GDALGetDriverCount() == 0 ) {
    GDALAllRegister();
  }

  /* Setup exception handling */
  UseExceptions();
%}

%rename (DataTypeUnion) GDALDataTypeUnion;
GDALDataType GDALDataTypeUnion( GDALDataType, GDALDataType );

%include "cpl_exceptions.i";

%extend GDAL_GCP {
}

%extend GDALRasterBandShadow {
%apply ( int *nLen, char **pBuf, NapClientData *nap_cd, Nap_NAO *naoPtr ) { (int *buf_len, char **buf, NapClientData *napCD, Nap_NAO *nao ) };
%apply ( int *optional_int ) {(int*)};
%feature( "kwargs" ) ReadRasterNAP;
  CPLErr ReadRasterNAP( int xoff, int yoff, int xsize, int ysize,
                     int *buf_len, char **buf, NapClientData *napCD, Nap_NAO *nao,
                     int *buf_xsize = 0,
                     int *buf_ysize = 0,
                     int *buf_type = 0 ) {
    int nxsize = (buf_xsize==0) ? xsize : *buf_xsize;
    int nysize = (buf_ysize==0) ? ysize : *buf_ysize;
    GDALDataType ntype  = (buf_type==0) ? GDALGetRasterDataType(self)
                                        : (GDALDataType)*buf_type;
    Nap_dataType dataType;
    switch(ntype) {
        case GDT_Byte: dataType = NAP_U8; break;
        case GDT_Int16: dataType = NAP_I16; break;
        case GDT_UInt16: dataType = NAP_U16; break;
        case GDT_Int32: dataType = NAP_I32; break;
        case GDT_UInt32: dataType = NAP_U32; break;
        case GDT_Float32: dataType = NAP_F32; break;
        case GDT_Float64: dataType = NAP_F64; break;
        default:
            // ZZZ Not supported. Raise error.
            break;
    }

    int rank = 2;
    size_t shape[NAP_MAX_RANK];
    shape[0] = nxsize;
    shape[1] = nysize;

    nao = Nap_NewNAO(napCD, dataType, rank, shape);
    if (! nao) {
        /* ZZZ */
    }

    return ReadRaster_internal( self, xoff, yoff, xsize, ysize,
                                nxsize, nysize, ntype, buf_len, buf );
  }
%clear (int *buf_len, char **buf, NapClientData *napCD, Nap_NAO *nao );
%clear (int*);
}

%extend GDALDatasetShadow {
}

%extend GDALMajorObjectShadow {
}

%extend GDALDriverShadow {
}

/* ==================================================================== */
/*	Support function for progress callbacks to tcl.                     */
/* ==================================================================== */

%{

typedef struct {
    Tcl_Interp *interp;
    Tcl_Obj *psTclCallback;
    Tcl_Obj *psTclCallbackData;
    int nLastReported;
} TclProgressData;


/************************************************************************/
/*                         TclProgressProxy()                           */
/************************************************************************/

int CPL_STDCALL
TclProgressProxy( double dfComplete, const char *pszMessage, void *pData )
{
    TclProgressData *psInfo = (TclProgressData *) pData;

    if( psInfo->nLastReported == (int) (100.0 * dfComplete) )
        return TRUE;

    if( psInfo->psTclCallback == NULL || !strcmp(Tcl_GetString(psInfo->psTclCallback), "") )
        return TRUE;

    psInfo->nLastReported = (int) (100.0 * dfComplete);

    if( pszMessage == NULL )
        pszMessage = "";

    Tcl_Obj *objv[4];
    objv[0] = psInfo->psTclCallback;
    objv[1] = Tcl_NewDoubleObj(dfComplete);
    objv[2] = Tcl_NewStringObj(pszMessage, -1);
    objv[3] = psInfo->psTclCallbackData;

    int psResult;
    if( psInfo->psTclCallbackData == NULL )
        psResult = Tcl_EvalObjv( psInfo->interp, 3, objv, TCL_EVAL_GLOBAL ); 
    else
        psResult = Tcl_EvalObjv( psInfo->interp, 4, objv, TCL_EVAL_GLOBAL ); 

    Tcl_DecrRefCount(objv[1]);
    Tcl_DecrRefCount(objv[2]);

    if( psResult == TCL_BREAK )
        return FALSE;

    return TRUE;
}
%}

%import typemaps_tcl.i
