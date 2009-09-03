/*
 *
 * tcl specific code for gdal bindings.
 */

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
