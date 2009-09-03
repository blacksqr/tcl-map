/******************************************************************************
 *
 * Name:     typemaps_tcl.i
 * Project:  GDAL Tcl Interface
 * Purpose:  GDAL Core SWIG Interface declarations.
 * Author:   Alexandros Stergiakis, alsterg@gmail.com
 *
*/
// XXX find a better way for this:
//  if (!strcmp(Tcl_GetString($input), "")) 

/*
 * Include the typemaps from swig library for returning of
 * standard types through arguments.
 */
%include "typemaps.i"

%apply (double *OUTPUT) { double *argout };

/*
 * double *val, int*hasval, is a special contrived typemap used for
 * the RasterBand GetNoDataValue, GetMinimum, GetMaximum, GetOffset, GetScale methods.
 * In the tcl bindings, the variable hasval is tested.  If it is 0 (is, the value
 * is not set in the raster band) then an empty list is returned.  If is is != 0, then
 * the value is coerced into a long and returned.
 */
%typemap(in,numinputs=0) (double *val, int*hasval) ( double tmpval, int tmphasval ) {
  /* %typemap(tcl,in,numinputs=0) (double *val, int*hasval) */
  $1 = &tmpval;
  $2 = &tmphasval;
}
%typemap(argout) (double *val, int*hasval) {
  /* %typemap(tcl,argout) (double *val, int*hasval) */
  Tcl_Obj *r;
  if ( !*$2 ) {
    r = Tcl_NewObj(); /* NONE */
  } else {
    r = Tcl_NewDoubleObj( *$1 );
  }
  %append_output(r);
}

/*
 *
 * Define a simple return code typemap which checks if the return code from
 * the wrapped method is non-zero. If zero, return None.  Otherwise,
 * return any argout or None.
 *
 * Applied like this:
 * %apply (IF_FALSE_RETURN_NONE) {int};
 * int function_to_wrap( );
 * %clear (int);
 */
/*
 * The out typemap prevents the default typemap for output integers from
 * applying.
 */
%typemap(out) IF_FALSE_RETURN_NONE "/*%typemap(out) IF_FALSE_RETURN_NONE */"
%typemap(ret) IF_FALSE_RETURN_NONE
{
 /* %typemap(ret) IF_FALSE_RETURN_NONE */
  if ($1 == 0 ) {
    Tcl_ResetResult(interp); /* NONE = Empty string */
  }
}


%typemap(out) IF_ERROR_RETURN_NONE
{
  /* %typemap(out) IF_ERROR_RETURN_NONE */
  /* (do not return the error code) */
}


/* --------  OGR Error Handling --------------- */
%import "ogr_error_map.i"

%typemap(out,fragment="OGRErrMessages") OGRErr
{
  /* %typemap(out) OGRErr */
  if (result != 0) {
    Tcl_SetResult(interp, (char*) OGRErrMessages(result), TCL_STATIC);
    SWIG_fail;
  }
}

%typemap(ret) OGRErr
{
  /* %typemap(ret) OGRErr */
  if (!strcmp(Tcl_GetStringResult(interp), "{}") || !strcmp(Tcl_GetStringResult(interp), "")) {
    Tcl_SetObjResult(interp, Tcl_NewLongObj( $1 ));
  }
}

%fragment("CreateListFromDoubleArray","header") %{
static Tcl_Obj*
CreateListFromDoubleArray(Tcl_Interp *interp, double *first, unsigned int size ) {
  Tcl_Obj *out = Tcl_NewListObj(0, NULL);
  for( unsigned int i=0; i<size; i++ ) {
    Tcl_Obj *val = Tcl_NewDoubleObj( *first );
    ++first;
    if (Tcl_ListObjAppendElement(interp, out, val) != TCL_OK) {
        Tcl_DecrRefCount(val);
        Tcl_DecrRefCount(out);
        /* Error msg in interp result */
        return NULL; /* signifies error */
    }
  }
  return out;
}
%}

%typemap(in,numinputs=0) ( double argout[ANY]) (double argout[$dim0])
{
  /* %typemap(in,numinputs=0) (double argout[ANY]) */
  $1 = argout;
}
%typemap(argout,fragment="CreateListFromDoubleArray") ( double argout[ANY])
{
  /* %typemap(argout) (double argout[ANY]) */
  Tcl_Obj *out = CreateListFromDoubleArray( interp, $1, $dim0 );
  if (out == NULL) SWIG_fail;
  %append_output(out);
}

%typemap(in,numinputs=0) ( double *argout[ANY]) (double *argout)
{
  /* %typemap(in,numinputs=0) (double *argout[ANY]) */
  $1 = &argout;
}
%typemap(argout,fragment="CreateListFromDoubleArray") ( double *argout[ANY])
{
  /* %typemap(argout) (double *argout[ANY]) */
  Tcl_Obj *out = CreateListFromDoubleArray( interp, *$1, $dim0 );
  if (out == NULL) SWIG_fail;
  %append_output(out);
}
%typemap(freearg) (double *argout[ANY])
{
  /* %typemap(freearg) (double *argout[ANY]) */
  CPLFree(*$1);
}
%typemap(in) (double argin[ANY]) (double argin[$dim0])
{
  /* %typemap(in) (double argin[ANY]) */
  $1 = argin;
  int lst_size;
  /* The following also checks if input is a list */
  if (Tcl_ListObjLength(interp, $input, &lst_size) != TCL_OK) {
    /* Error msg in interp result */
    SWIG_fail;
  }
  if ( lst_size != $dim0 ) {
    Tcl_SetResult(interp, (char*) "List must have length ##size", TCL_STATIC);
    SWIG_fail;
  }
  for (unsigned int i=0; i<$dim0; i++) {
    Tcl_Obj **o = NULL;
    if (Tcl_ListObjIndex(interp, $input, i, o) != TCL_OK) { /* ref count is not incremented */
        /* Error msg in interp result */
        SWIG_fail;
    }

    double val;
    if (Tcl_GetDoubleFromObj(interp, *o, &val ) != TCL_OK) {
        /* Error msg in interp result */
        SWIG_fail;
    }
    $1[i] = val;
  }
}

/*
 *  Typemap for counted arrays of ints <- list
 */
%typemap(in,numinputs=1) (int nList, int* pList)
{
  /* %typemap(in,numinputs=1) (int nList, int* pList)*/
  /* The following also checks if input is a list */
  if (Tcl_ListObjLength(interp, $input, &$1) != TCL_OK) {
    /* Error msg in interp result */
    SWIG_fail;
  }
  if ( !$1 ) {
      Tcl_SetResult(interp, (char*) "Input list mustn't be empty", TCL_STATIC);
      SWIG_fail;
  }

  $2 = (int*) CPLMalloc($1*sizeof(int));

  for( int i = 0; i<$1; i++ ) {
    Tcl_Obj **o = NULL;
    if (Tcl_ListObjIndex(interp, $input, i, o) != TCL_OK) { /* ref count is not incremented */
        /* Error msg in interp result */
        SWIG_fail;
    }

    int val;
    if (Tcl_GetIntFromObj(interp, *o, &val ) != TCL_OK) {
        /* Error msg in interp result */
        SWIG_fail;
    }
    $2[i] = val;
  }
}

%typemap(freearg) (int nList, int* pList)
{
  /* %typemap(freearg) (int nList, int* pList) */
  if ($2) {
    CPLFree((void*) $2);
  }
}

/*
 *  Typemap for counted arrays of doubles <- list
 */
%typemap(in,numinputs=1) (int nList, double* pList)
{
  /* %typemap(in,numinputs=1) (int nList, double* pList)*/
  /* The following also checks if input is a list */
  if (Tcl_ListObjLength(interp, $input, &$1) != TCL_OK) {
    /* Error msg in interp result */
    SWIG_fail;
  }
  if ( !$1 ) {
      Tcl_SetResult(interp, (char*) "Input list mustn't be empty", TCL_STATIC);
      SWIG_fail;
  }

  $2 = (double*) CPLMalloc($1*sizeof(double));

  for( int i = 0; i<$1; i++ ) {
    Tcl_Obj **o = NULL;
    if (Tcl_ListObjIndex(interp, $input, i, o) != TCL_OK) { /* ref count is not incremented */
        /* Error msg in interp result */
        SWIG_fail;
    }

    double val;
    if (Tcl_GetDoubleFromObj(interp, *o, &val ) != TCL_OK) {
        /* Error msg in interp result */
        SWIG_fail;
    }
    $2[i] = val;
  }
}

%typemap(freearg) (int nList, double* pList)
{
  /* %typemap(freearg) (int nList, double* pList) */
  if ($2) {
    CPLFree((void*) $2);
  }
}

/*
 * Typemap for buffers with length <-> string
 * Used in Band::ReadRaster() and Band::WriteRaster()
 *
 * This typemap has a typecheck also since the WriteRaster()
 * methods are overloaded.
 */
%typemap(in,numinputs=0) (int *nLen, char **pBuf ) ( int nLen = 0, char *pBuf = 0 )
{
  /* %typemap(in,numinputs=0) (int *nLen, char **pBuf ) */
  $1 = &nLen;
  $2 = &pBuf;
}
%typemap(argout) (int *nLen, char **pBuf )
{
  /* %typemap(argout) (int *nLen, char **pBuf ) */
  Tcl_SetObjResult(interp, Tcl_NewByteArrayObj( (unsigned char*) *$2, *$1 ));
}
%typemap(freearg) (int *nLen, char **pBuf )
{
  /* %typemap(freearg) (int *nLen, char **pBuf ) */
  if( *$1 ) {
    CPLFree( *$2 );
  }
}
%typemap(in,numinputs=1) (int nLen, char *pBuf )
{
  /* %typemap(in,numinputs=1) (int nLen, char *pBuf ) */
  /* Storage is handled by the respective Tcl_Obj. It should considered read-only. */
  $2 = Tcl_GetStringFromObj($input, &$1);
}
%typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER)
        (int nLen, char *pBuf)
{
  /* %typecheck(SWIG_TYPECHECK_POINTER) (int nLen, char *pBuf) */
  $1 = 1; /* Everything in Tcl is a string */
}

/*
 * Typemap argout used in Feature::GetFieldAsIntegerList()
 */
%typemap(in,numinputs=0) (int *nLen, const int **pList) (int nLen, int *pList)
{
  /* %typemap(in,numinputs=0) (int *nLen, const int **pList) (int nLen, int *pList) */
  $1 = &nLen;
  $2 = &pList;
}

%typemap(argout) (int *nLen, const int **pList )
{
  /* %typemap(argout) (int *nLen, const int **pList ) */
  Tcl_Obj *out = Tcl_NewListObj(0, NULL);
  for( int i=0; i<*$1; i++ ) {
    Tcl_Obj *val = Tcl_NewLongObj( (*$2)[i] );
    if (Tcl_ListObjAppendElement(interp, out, val) != TCL_OK) {
        Tcl_DecrRefCount(val);
        Tcl_DecrRefCount(out);
        /* Error msg in interp result */
        SWIG_fail;
    }
  }
  Tcl_SetObjResult(interp, out);
}

/*
 * Typemap argout used in Feature::GetFieldAsDoubleList()
 */
%typemap(in,numinputs=0) (int *nLen, const double **pList) (int nLen, double *pList)
{
  /* %typemap(in,numinputs=0) (int *nLen, const double **pList) (int nLen, double *pList) */
  $1 = &nLen;
  $2 = &pList;
}

%typemap(argout) (int *nLen, const double **pList )
{
  /* %typemap(argout) (int *nLen, const double **pList ) */
  Tcl_Obj *out = Tcl_NewListObj(0, NULL);
  for( int i=0; i<*$1; i++ ) {
    Tcl_Obj *val = Tcl_NewDoubleObj( (*$2)[i] );
    if (Tcl_ListObjAppendElement(interp, out, val) != TCL_OK) {
        Tcl_DecrRefCount(val);
        Tcl_DecrRefCount(out);
        /* Error msg in interp result */
        SWIG_fail;
    }
  }
  Tcl_SetObjResult(interp, out);
}
/*
 * Typemap argout of GDAL_GCP* used in Dataset::GetGCPs( )
 */
%typemap(in,numinputs=0) (int *nGCPs, GDAL_GCP const **pGCPs ) (int nGCPs=0, GDAL_GCP *pGCPs=0 )
{
  /* %typemap(in,numinputs=0) (int *nGCPs, GDAL_GCP const **pGCPs ) */
  $1 = &nGCPs;
  $2 = &pGCPs;
}
%typemap(argout) (int *nGCPs, GDAL_GCP const **pGCPs )
{
  /* %typemap(argout) (int *nGCPs, GDAL_GCP const **pGCPs ) */
  Tcl_Obj *out = Tcl_NewListObj(0, NULL);
  for( int i = 0; i < *$1; i++ ) {
    /* We dublicate every GCP (seperate object in memory) */
    GDAL_GCP *o = new_GDAL_GCP( (*$2)[i].dfGCPX,
                                (*$2)[i].dfGCPY,
                                (*$2)[i].dfGCPZ,
                                (*$2)[i].dfGCPPixel,
                                (*$2)[i].dfGCPLine,
                                (*$2)[i].pszInfo,
                                (*$2)[i].pszId );
    if (Tcl_ListObjAppendElement(interp, out, SWIG_NewPointerObj((void*)o,SWIGTYPE_p_GDAL_GCP,1)) != TCL_OK) {
        delete_GDAL_GCP(o);
        /* Note: XXX I assume here that by freeing this list, the respective GDAL_GCP memory of each pointer is fred automatically */
        Tcl_DecrRefCount(out);
        /* Error msg in interp result */
        SWIG_fail;
    }
  }
  Tcl_SetObjResult(interp, out);
}
%typemap(in,numinputs=1) (int nGCPs, GDAL_GCP const *pGCPs ) ( GDAL_GCP *tmpGCPList )
{
  /* %typemap(in,numinputs=1) (int nGCPs, GDAL_GCP const *pGCPs ) */
  /* The following also checks if input is a list */
  if (Tcl_ListObjLength(interp, $input, &$1) != TCL_OK) {
    /* Error msg in interp result */
    SWIG_fail;
  }
  if ( !$1 ) {
      Tcl_SetResult(interp, (char*) "Input list mustn't be empty", TCL_STATIC);
      SWIG_fail;
  }

  tmpGCPList = (GDAL_GCP*) CPLMalloc($1*sizeof(GDAL_GCP));
  $2 = tmpGCPList;
  for( int i = 0; i<$1; i++ ) {
    Tcl_Obj **o = NULL;
    /* The reference count for the list element is not incremented with the following */
    if (Tcl_ListObjIndex(interp, $input, i, o) != TCL_OK) {
        /* Error msg in interp result */
        SWIG_fail;
    }

    GDAL_GCP *item = 0;
    SWIG_ConvertPtr( *o, (void**)&item, SWIGTYPE_p_GDAL_GCP, SWIG_POINTER_EXCEPTION | 0 );
    if ( ! item ) {
      SWIG_fail;
    }

    memcpy( (void*) tmpGCPList, (void*) item, sizeof( GDAL_GCP ) );
    ++tmpGCPList;
  }
}
%typemap(freearg) (int nGCPs, GDAL_GCP const *pGCPs )
{
  /* %typemap(freearg) (int nGCPs, GDAL_GCP const *pGCPs ) */
  if ($2) {
    CPLFree( (void*) $2 );
  }
}

/*
 * Typemap for GDALColorEntry* <-> tuple
 */
%typemap(out) GDALColorEntry*
{
    /* %typemap(out) GDALColorEntry* */
    Tcl_Obj *out = Tcl_NewListObj(0, NULL);
    Tcl_Obj *val;
    val  = Tcl_NewIntObj((*$1).c1);
    if (Tcl_ListObjAppendElement(interp, out, val) != TCL_OK) {
        Tcl_DecrRefCount(val);
        Tcl_DecrRefCount(out);
        SWIG_fail;
    }
    val = Tcl_NewIntObj((*$1).c2);
    if (Tcl_ListObjAppendElement(interp, out, val) != TCL_OK) {
        Tcl_DecrRefCount(val);
        Tcl_DecrRefCount(out);
        SWIG_fail;
    }
    val = Tcl_NewIntObj((*$1).c3);
    if (Tcl_ListObjAppendElement(interp, out, val) != TCL_OK) {
        Tcl_DecrRefCount(val);
        Tcl_DecrRefCount(out);
        SWIG_fail;
    }
    val = Tcl_NewIntObj((*$1).c4);
    if (Tcl_ListObjAppendElement(interp, out, val) != TCL_OK) {
        Tcl_DecrRefCount(val);
        Tcl_DecrRefCount(out);
        SWIG_fail;
    }
    Tcl_SetObjResult(interp, out);

    /* More compact: (If used, the next typemap must be modified as well)
       Tcl_SetObjResult(interp, Tcl_ObjPrintf("%x%x%x%x", (*$1).c1, (*$1).c2, (*$1).c3, (*$1).c4));
     */
}

%typemap(in) GDALColorEntry* (GDALColorEntry ce)
{
    /* %typemap(in) GDALColorEntry* */
    ce.c1 = 0;
    ce.c2 = 0;
    ce.c3 = 0;
    ce.c4 = 255;
    /* The following also checks if input is a list */
    int size;
    if (Tcl_ListObjLength(interp, $input, &size) != TCL_OK) {
        /* Error msg in interp result */
        SWIG_fail;
    }
    if ( size > 4 ) {
        Tcl_SetResult(interp, (char*) "ColorEntry sequence too long", TCL_STATIC);
        SWIG_fail;
    }
    if ( size < 3 ) {
        Tcl_SetResult(interp, (char*) "ColorEntry sequence too short", TCL_STATIC);
        SWIG_fail;
    }
    for( int i = 0; i<size; i++ ) {
        Tcl_Obj **o = NULL;
        int val;
        /* The reference count for the list element is not incremented with the following */
        if (Tcl_ListObjIndex(interp, $input, i, o) != TCL_OK) {
            /* Error msg in interp result */
            SWIG_fail;
        }

        if (Tcl_GetIntFromObj(interp, *o, &val) != TCL_OK) {
            /* Error msg in interp result */
            SWIG_fail;
        }
        switch (i) {
            case 1: ce.c1 = (short) val; break;
            case 2: ce.c2 = (short) val; break;
            case 3: ce.c3 = (short) val; break;
            case 4: ce.c4 = (short) val; break;
        }
    }
    $1 = &ce;
}

/*
 * Typemap char ** -> dict
 */
%typemap(out) char **dict
{
  /* %typemap(out) char **dict */
    char **stringarray = $1;
    Tcl_Obj *out = Tcl_NewDictObj();
    if ( stringarray != NULL ) {
        while (*stringarray != NULL ) {
            char const *valptr;
            char *keyptr;
            valptr = CPLParseNameValue( *stringarray, &keyptr );
            if ( valptr != 0 ) {
                Tcl_Obj *nm = Tcl_NewStringObj( keyptr, -1 );
                Tcl_Obj *val = Tcl_NewStringObj( valptr, -1 );
                if (Tcl_DictObjPut(interp, out, nm, val) != TCL_OK) {
                    Tcl_DecrRefCount(nm);
                    Tcl_DecrRefCount(val);
                    Tcl_DecrRefCount(out);
                    /* Error msg in interp result */
                    SWIG_fail;
                }
                CPLFree( keyptr );
            }
            stringarray++;
        }
    }
    Tcl_SetObjResult(interp, out);
}

/*
 * Typemap char **<- dict. 
 */
%typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) (char **dict)
{
  /* %typecheck(SWIG_TYPECHECK_POINTER) (char **dict) */
  int size;
  $1 = (Tcl_DictObjSize(interp, $input, &size) == TCL_OK || Tcl_ListObjLength(interp, $input, &size) == TCL_OK) ? 1 : 0;
}
%typemap(in) char **dict
{
  /* %typemap(in) char **dict */
  $1 = NULL;
  int size;
  if (Tcl_DictObjSize(interp, $input, &size) != TCL_OK) {
    if ( size > 0 ) {
        Tcl_DictSearch search;
        Tcl_Obj *key, *value;
        int done;

        if (Tcl_DictObjFirst(interp, $input, &search, &key, &value, &done) != TCL_OK) {
            SWIG_fail;;
        }
        for (; !done ; Tcl_DictObjNext(&search, &key, &value, &done)) {
            char *nm = Tcl_GetString(key);
            char *val = Tcl_GetString(value);
            $1 = CSLAddNameValue( $1, nm, val );
        }
        Tcl_DictObjDone(&search);
    }
  }
  else {
    Tcl_SetResult(interp, (char*) "Argument must be a dictionary", TCL_STATIC);
    SWIG_fail;
  }
}
%typemap(freearg) char **dict
{
  /* %typemap(freearg) char **dict */
  CSLDestroy( $1 );
}

/*
 * Typemap maps char** arguments from Tcl List Object
 */
%typemap(in) char **options
{
    /* %typemap(in) char **options */
    int size;
    if (Tcl_ListObjLength(interp, $input, &size) != TCL_OK) {
        /* Error msg in interp result */
        SWIG_fail;
    }
    if ( !size ) {
        Tcl_SetResult(interp, (char*) "Input list mustn't be empty", TCL_STATIC);
        SWIG_fail;
    }

    for (int i = 0; i < size; i++) {
        Tcl_Obj **o = NULL;
        /* The reference count for the list element is not incremented with the following */
        if (Tcl_ListObjIndex(interp, $input, i, o) != TCL_OK) {
            /* Error msg in interp result */
            SWIG_fail;
        }
        char *pszItem = Tcl_GetString(*o);
        $1 = CSLAddString( $1, pszItem );
    }
}
%typemap(freearg) char **options
{
  /* %typemap(freearg) char **options */
  CSLDestroy( $1 );
}


/*
 * Typemap converts an array of strings into a list of strings
 * with the assumption that the called object maintains ownership of the
 * array of strings.
 */
%typemap(out) char **options
{
  /* %typemap(out) char **options -> ( string ) */
  char **stringarray = $1;
  if ( stringarray == NULL ) {
    Tcl_ResetResult(interp); /* NONE = Empty string */
  } else {
      int len = CSLCount( stringarray );
      Tcl_Obj *out = Tcl_NewListObj(0, NULL);
      for ( int i = 0; i < len; ++i ) {
          Tcl_Obj *o = Tcl_NewStringObj( stringarray[i], -1 );
          if (Tcl_ListObjAppendElement(interp, out, o) != TCL_OK) {
              Tcl_DecrRefCount(o);
              Tcl_DecrRefCount(out);
              /* Error msg in interp result */
              SWIG_fail;
          }
      }
      Tcl_SetObjResult(interp, out);
  }
}

/*
 * The return value is a list that is copied into a Tcl list and then CSLDestroyed
 */
%typemap(out) (char **CSL)
{
/*XXX Test it*/
    /* %typemap(out) char **CSL */
    char **stringarray = $1;
    if ( stringarray == NULL ) {
        Tcl_ResetResult(interp); /* NONE = Empty string */
    } else {
        int len = CSLCount( stringarray );
        Tcl_Obj *out = Tcl_NewListObj(0, NULL);
        for ( int i = 0; i < len; ++i ) {
            Tcl_Obj *o = Tcl_NewStringObj( stringarray[i], -1 );
            if (Tcl_ListObjAppendElement(interp, out, o) != TCL_OK) {
                Tcl_DecrRefCount(o);
                Tcl_DecrRefCount(out);
                /* Error msg in interp result */
                SWIG_fail;
            }
        }
        CSLDestroy($1);
        Tcl_SetObjResult(interp, out);
    }
}

/*
 * Typemaps map mutable char ** arguments from string.  Does not
 * return the modified argument
 */
%typemap(in) (char **ignorechange) ( char *val )
{
  /* %typemap(in) (char **ignorechange) */
  val = Tcl_GetString($input);
  $1 = &val;
}

/*
 * Typemap for char **argout.
 */
%typemap(in,numinputs=0) (char **argout) ( char *argout=0 )
{
  /* %typemap(in,numinputs=0) (char **argout) */
  $1 = &argout;
}
%typemap(argout) (char **argout)
{
  /* %typemap(argout) (char **argout) */
  Tcl_Obj *o;
  if ( $1 ) {
    o = Tcl_NewStringObj( *$1, -1 );
  } else {
    o = Tcl_NewObj();
  }
  %append_output(o);
}
%typemap(freearg) (char **argout)
{
  /* %typemap(freearg) (char **argout) */
  if ( *$1 )
    CPLFree( *$1 );
}

%apply int *INPUT {int* optional_int};

/*
 * Typedef const char * <- Any object.
 *
 * Formats the object using str and returns the string representation
 */


%typemap(in) (tostring argin)
{
  /* %typemap(in) (tostring argin) */
  $1 = Tcl_GetString( $input ); 
}
%typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) (tostring argin)
{
  /* %typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) (tostring argin) */
  $1 = 1;
}

/* No "%typemap(ret) CPLErr" because we always raise an exception. */

/*
 * Typemaps for minixml:  CPLXMLNode* input, CPLXMLNode *ret
 */

%fragment("TclListToXMLTree","header") %{
/************************************************************************/
/*                          TclListToXMLTree()                           */
/************************************************************************/
static CPLXMLNode *TclListToXMLTree( Tcl_Interp *interp, Tcl_Obj *tclList )
{
    int      nChildCount = 0, iChild, nType;
    CPLXMLNode *psThisNode;
    CPLXMLNode *psChild;
    char       *pszText = NULL;

    if (Tcl_ListObjLength(interp, tclList, &nChildCount) != TCL_OK) {
        /* Error msg in interp result */
        return NULL;
    }
    nChildCount = nChildCount - 2;
    if( nChildCount < 0 )
    {
        Tcl_SetResult(interp, (char*) "Error in input XMLTree.", TCL_STATIC);
        return NULL;
    }

    Tcl_Obj **o = NULL;
    if (Tcl_ListObjIndex(interp, tclList, 0, o) != TCL_OK) { /* ref count is not incremented */
        /* Error msg in interp result */
        return NULL;
    }
    if (Tcl_GetIntFromObj(interp, *o, &nType) != TCL_OK) {
        /* Error msg in interp result */
        return NULL;
    }
    if (Tcl_ListObjIndex(interp, tclList, 1, o) != TCL_OK) { /* ref count is not incremented */
        /* Error msg in interp result */
        return NULL;
    }
    pszText = Tcl_GetStringFromObj(*o, NULL);
    psThisNode = CPLCreateXMLNode( NULL, (CPLXMLNodeType) nType, pszText );

    for( iChild = 0; iChild < nChildCount; iChild++ )
    {
        if (Tcl_ListObjIndex(interp, tclList, iChild+2, o) != TCL_OK) { /* ref count is not incremented */
            /* Error msg in interp result */
            return NULL;
        }
        psChild = TclListToXMLTree( interp, *o );
        CPLAddXMLChild( psThisNode, psChild );
    }

    return psThisNode;
}
%}

%typemap(in,fragment="TclListToXMLTree") (CPLXMLNode* xmlnode )
{
  /* %typemap(tcl,in) (CPLXMLNode* xmlnode ) */
  $1 = TclListToXMLTree( interp, $input );
  if ( !$1 ) SWIG_fail;
}
%typemap(freearg) (CPLXMLNode *xmlnode)
{
  /* %typemap(freearg) (CPLXMLNode *xmlnode) */
  if ( $1 ) CPLDestroyXMLNode( $1 );
}

%fragment("XMLTreeToTclList","header") %{
/************************************************************************/
/*                          XMLTreeToTclList()                           */
/************************************************************************/
static Tcl_Obj *XMLTreeToTclList( Tcl_Interp *interp, CPLXMLNode *psTree )
{
    Tcl_Obj *tclList;
    int      nChildCount = 0, iChild;
    CPLXMLNode *psChild;

    for( psChild = psTree->psChild; 
         psChild != NULL; 
         psChild = psChild->psNext )
        nChildCount++;

    tclList = Tcl_NewListObj(0, NULL);
    if (Tcl_ListObjAppendElement(interp, tclList, Tcl_NewIntObj((int) psTree->eType)) != TCL_OK) {
        Tcl_DecrRefCount(tclList);
        /* Error msg in interp result */
        return NULL; /* signifies error */
    }
    if (Tcl_ListObjAppendElement(interp, tclList, Tcl_NewStringObj(psTree->pszValue, -1)) != TCL_OK) {
        Tcl_DecrRefCount(tclList);
        /* Error msg in interp result */
        return NULL; /* signifies error */
    }

    for( psChild = psTree->psChild, iChild = 2; 
         psChild != NULL; 
         psChild = psChild->psNext, iChild++ )
    {
        if (Tcl_ListObjAppendElement(interp, tclList, XMLTreeToTclList( interp, psChild )) != TCL_OK) {
            Tcl_DecrRefCount(tclList);
            /* Error msg in interp result */
            return NULL; /* signifies error */
        }
    }

    return tclList; 
}
%}

%typemap(out,fragment="XMLTreeToTclList") (CPLXMLNode*)
{
  /* %typemap(out) (CPLXMLNode*) */

  Tcl_Obj *out;
  CPLXMLNode *psXMLTree = $1;
  int         bFakeRoot = FALSE;

  if( psXMLTree != NULL && psXMLTree->psNext != NULL )
  {
      CPLXMLNode *psFirst = psXMLTree;

      /* create a "pseudo" root if we have multiple elements */
      psXMLTree = CPLCreateXMLNode( NULL, CXT_Element, "" );
      psXMLTree->psChild = psFirst;
      bFakeRoot = TRUE;
  }

  out = XMLTreeToTclList( interp, psXMLTree );
  if ( !out ) SWIG_fail;

  if( bFakeRoot )
  {
        psXMLTree->psChild = NULL;
        CPLDestroyXMLNode( psXMLTree );
  }

  Tcl_SetObjResult(interp, out);
}
%typemap(ret) (CPLXMLNode*)
{
  /* %typemap(ret) (CPLXMLNode*) */
  if ( $1 ) CPLDestroyXMLNode( $1 );
}

/* Check inputs to ensure they are not NULL but instead empty #1775 */
%define CHECK_NOT_UNDEF(type, param, msg)
%typemap(check) (const char *pszNewDesc)
{
    /* %typemap(check) (type *param) */
    if (!$1) {
        Tcl_SetResult(interp, (char*) "Variable cannot be None", TCL_STATIC);
        SWIG_fail;
    }
}
%enddef

//CHECK_NOT_UNDEF(char, method, method)
//CHECK_NOT_UNDEF(const char, name, name)
//CHECK_NOT_UNDEF(const char, request, request)
//CHECK_NOT_UNDEF(const char, cap, capability)
//CHECK_NOT_UNDEF(const char, statement, statement)
CHECK_NOT_UNDEF(const char, pszNewDesc, description)
CHECK_NOT_UNDEF(OSRCoordinateTransformationShadow, , coordinate transformation)
CHECK_NOT_UNDEF(OGRGeometryShadow, other, other geometry)
CHECK_NOT_UNDEF(OGRGeometryShadow, other_disown, other geometry)
CHECK_NOT_UNDEF(OGRGeometryShadow, geom, geometry)
CHECK_NOT_UNDEF(OGRFieldDefnShadow, defn, field definition)
CHECK_NOT_UNDEF(OGRFieldDefnShadow, field_defn, field definition)
CHECK_NOT_UNDEF(OGRFeatureShadow, feature, feature)


/* ==================================================================== */
/*	Support function for progress callbacks to tcl.                     */
/* ==================================================================== */

/*                                                                      */
/*  A number of things happen as part of callbacks in GDAL.  First,     */
/*  there is a generic callback function internal to GDAL called        */
/*  GDALTermProgress, which just outputs generic progress counts to the */
/*  terminal as you would expect.  This callback function is a special  */
/*  case.  Alternatively, a user can pass in a Tcl procedure that       */
/*  can be used as a callback, and it will be eval'd by GDAL during     */
/*  its update loop.  The typemaps here handle taking in                */
/*  GDALTermProgress and the Tcl procedure.                             */

/*  This arginit does some magic because it must create a               */
/*  psProgressInfo that is global to the wrapper function.  The noblock */
/*  option here allows it to end up being global and not being          */
/*  instantiated within a {} block.  Both the callback_data and the     */
/*  callback typemaps will then use this struct to hold pointers to the */
/*  callback and callback_data Tcl_Obj*'s.                              */

%typemap(arginit, noblock=1) ( void* callback_data=NULL)
{
    /* %typemap(arginit) ( const char* callback_data=NULL)  */
        TclProgressData *psProgressInfo;
        psProgressInfo = (TclProgressData *) CPLCalloc(1,sizeof(TclProgressData));
        psProgressInfo->nLastReported = -1;
        psProgressInfo->interp = interp;
        psProgressInfo->psTclCallback = NULL;
        psProgressInfo->psTclCallbackData = NULL;

}

/*  This is kind of silly, but this typemap takes the $input'ed         */
/*  Tcl_Obj * and hangs it on the struct's callback data *and* sets     */
/*  the argument to the tclProgressInfo void* that will eventually be   */
/*  passed into the function as its callback data.  Confusing.  Sorry.  */
%typemap(in) (void* callback_data=NULL) 
{
    /* %typemap(in) ( void* callback_data=NULL)  */
    psProgressInfo->psTclCallbackData = $input;
    Tcl_IncrRefCount(psProgressInfo->psTclCallbackData);
    $1 = psProgressInfo;

}

/*  Here is our actual callback function.  It could be a generic GDAL   */
/*  callback function like GDALTermProgress, or it might be a user-     */
/*  defined callback function that is actually a Tcl procedure.         */
/*  If we were the generic function, set our argument to that,          */
/*  otherwise, setup the tclProgressInfo's callback to be our Tcl_Obj*  */
/*  and set our callback function to be TclProgressProxy, which is      */
/*  defined in gdal_tcl.i                                               */
%typemap(in) (GDALProgressFunc callback = NULL) 
{
    /* %typemap(in) (GDALProgressFunc callback = NULL) */
    /* callback_func typemap */
    if ($input && !strcmp(Tcl_GetString($input), "")) {
        void* cbfunction = NULL;
        SWIG_ConvertPtr( $input, 
                         (void**)&cbfunction, 
                         SWIGTYPE_p_f_double_p_q_const__char_p_void__int, 
                         SWIG_POINTER_EXCEPTION | 0 );

        if ( cbfunction == GDALTermProgress ) {
            $1 = GDALTermProgress;
        } else if ( cbfunction == GDALDummyProgress) {
            $1 = GDALDummyProgress;
        } else if ( cbfunction == GDALScaledProgress) {
            $1 = GDALScaledProgress;
        } else {
            psProgressInfo->psTclCallback = $input;
            Tcl_IncrRefCount(psProgressInfo->psTclCallback);
            $1 = TclProgressProxy;
        }
    }
}

/*  clean up our global (to the wrapper function) psProgressInfo        */
/*  struct now that we're done with it.                                 */
%typemap(freearg) (void* callback_data=NULL) 
{
    /* %typemap(freearg) ( void* callback_data=NULL)  */
    Tcl_DecrRefCount(psProgressInfo->psTclCallback);
    Tcl_DecrRefCount(psProgressInfo->psTclCallbackData);
    CPLFree(psProgressInfo);
}


%typemap(arginit) ( GUInt32 ) 
{
    /* %typemap(out) ( GUInt32 )  */
    $1 = 0;
}

%typemap(out) ( GUInt32 ) 
{
    /* %typemap(out) ( GUInt32 )  */
    Tcl_SetObjResult(interp, Tcl_NewIntObj($1));
}

%typemap(in) ( GUInt32 ) 
{
    /* %typemap(in) ( GUInt32 )  */
    if (Tcl_GetLongFromObj(interp, $input, &$1) != TCL_OK) {
        /* Error in interp result */
        // SWIG_fail;
    }
}

%define OBJECT_LIST_INPUT(type, pointertype)
%typemap(in, numinputs=1) (int object_list_count, type **poObjects)
{
    /*  OBJECT_LIST_INPUT %typemap(in) (int itemcount, type *optional_##type)*/
    if (Tcl_ListObjLength(interp, $input, &$1) != TCL_OK) {
        /* Error msg in interp result */
        SWIG_fail;
    }
    if ( !$1 ) {
        Tcl_SetResult(interp, (char*) "Input list mustn't be empty", TCL_STATIC);
        SWIG_fail;
    }

    $2 = (type**) CPLMalloc($1*sizeof(type*));

    for( int i = 0; i<$1; i++ ) {
        Tcl_Obj **o = NULL;
        if (Tcl_ListObjIndex(interp, $input, i, o) != TCL_OK) { /* ref count is not incremented */
            /* Error msg in interp result */
            SWIG_fail;
        }
        /* No equivalent of SWIG_Python_GetSwigThis for Tcl in SWIG, but we can still use this */
//XXX
        type* pointer = NULL;
        SWIG_ConvertPtr( *o, (void**)&pointer, pointertype, SWIG_POINTER_EXCEPTION | 0 );
        if (!pointer) {
            SWIG_fail;
        }
        $2[i] = pointer;
    }
}

%typemap(freearg)  (int object_list_count, type **poObjects)
{
  /* OBJECT_LIST_INPUT %typemap(freearg) (int object_list_count, type **poObjects)*/
  CPLFree( $2 );
}
%enddef

OBJECT_LIST_INPUT(GDALRasterBandShadow, SWIGTYPE_p_GDALRasterBandShadow);

/* ***************************************************************************
 *                       GetHistogram()
 * Tcl is somewhat special in that we don't want the caller
 * to pass in the histogram array to populate.  Instead we allocate
 * it internally, call the C level, and then turn the result into 
 * a list object. 
 */

%typemap(arginit) (int buckets, int* panHistogram)
{
  /* %typemap(in) int buckets, int* panHistogram -> list */
  $2 = (int *) CPLCalloc(sizeof(int),$1);
}

%typemap(in, numinputs=1) (int buckets, int* panHistogram)
{
  /* %typemap(in) int buckets, int* panHistogram -> list */
  int requested_buckets;
  SWIG_AsVal_int(interp, $input, &requested_buckets);
  if( requested_buckets != $1 )
  { 
    $1 = requested_buckets;
    $2 = (int *) CPLRealloc($2,sizeof(int) * requested_buckets);
  }
}

%typemap(freearg)  (int buckets, int* panHistogram)
{
  /* %typemap(freearg) (int buckets, int* panHistogram)*/
  if ( $2 ) {
    CPLFree( $2 );
  }
}

%typemap(argout) (int buckets, int* panHistogram)
{
    /* %typemap(out) int buckets, int* panHistogram -> list */
    int *integerarray = $2;
    if ( integerarray == NULL ) {
        Tcl_ResetResult(interp); /* NONE = Empty string */
    } else {
        Tcl_Obj *out = Tcl_NewListObj(0, NULL);
        for( int i=0; i < $1; i++ ) {
            Tcl_Obj *o = Tcl_NewLongObj( integerarray[i] );
            if (Tcl_ListObjAppendElement(interp, out, o) != TCL_OK) {
                Tcl_DecrRefCount(o);
                Tcl_DecrRefCount(out);
                /* Error msg in interp result */
                SWIG_fail;
            }
        }
        Tcl_SetObjResult(interp, out);
    }
}

/* ***************************************************************************
 *                       GetDefaultHistogram()
 */

%typemap(arginit, noblock=1) (double *min_ret, double *max_ret, int *buckets_ret, int **ppanHistogram)
{
   double min_val, max_val;
   int buckets_val;
   int *panHistogram;

  /* frankwdebug */

   $1 = &min_val;
   $2 = &max_val;
   $3 = &buckets_val;
   $4 = &panHistogram;
}

%typemap(argout) (double *min_ret, double *max_ret, int *buckets_ret, int** ppanHistogram)
{
  int i;
  Tcl_Obj *o, *psList = NULL;

  /* frankwdebug */

  psList = Tcl_NewListObj(0, NULL);

  o = Tcl_NewDoubleObj( min_val );
  if (Tcl_ListObjAppendElement(interp, psList, o) != TCL_OK) {
      Tcl_DecrRefCount(o);
      Tcl_DecrRefCount(psList);
      /* Error msg in interp result */
      SWIG_fail;
  }
  o = Tcl_NewDoubleObj( max_val );
  if (Tcl_ListObjAppendElement(interp, psList, o) != TCL_OK) {
      Tcl_DecrRefCount(o);
      Tcl_DecrRefCount(psList);
      /* Error msg in interp result */
      SWIG_fail;
  }
  o = Tcl_NewLongObj( buckets_val );
  if (Tcl_ListObjAppendElement(interp, psList, o) != TCL_OK) {
      Tcl_DecrRefCount(o);
      Tcl_DecrRefCount(psList);
      /* Error msg in interp result */
      SWIG_fail;
  }

  for( i = 0; i < buckets_val; i++ ) {
      o = Tcl_NewLongObj( panHistogram[i] );
      if (Tcl_ListObjAppendElement(interp, psList, o) != TCL_OK) {
          Tcl_DecrRefCount(o);
          Tcl_DecrRefCount(psList);
          /* Error msg in interp result */
          SWIG_fail;
      }
  }

  Tcl_SetObjResult(interp, psList);
  CPLFree( panHistogram );
}

/***************************************************
 * Typemaps for CoordinateTransformation.TransformPoints()
 ***************************************************/
%typemap(in,numinputs=1) (int nCount, double *x, double *y, double *z)
{
  /*  typemap(in,numinputs=1) (int nCount, double *x, double *y, double *z) */
    if (Tcl_ListObjLength(interp, $input, &$1) != TCL_OK) {
        /* Error msg in interp result */
        SWIG_fail;
    }
    if ( !$1 ) {
        Tcl_SetResult(interp, (char*) "Input list mustn't be empty", TCL_STATIC);
        SWIG_fail;
    }
    $2 = (double*) CPLMalloc($1*sizeof(double));
    $3 = (double*) CPLMalloc($1*sizeof(double));
    $4 = (double*) CPLMalloc($1*sizeof(double));

    for( int i = 0; i<$1; i++ ) {

        Tcl_Obj **o = NULL;
        if (Tcl_ListObjIndex(interp, $input, i, o) != TCL_OK) { /* ref count is not incremented */
            /* Error msg in interp result */
            SWIG_fail;
        }

        int size;
        if (Tcl_ListObjLength(interp, *o, &size) != TCL_OK) {
            /* Error msg in interp result */
            SWIG_fail;
        }
        if ( size < 2 || size > 3 ) {
            Tcl_SetResult(interp, (char*) "Not a list of 2 or 3 doubles", TCL_STATIC);
            SWIG_fail;
        }

        double x, y, z = 0;
        Tcl_Obj **o2 = NULL;
        if (Tcl_ListObjIndex(interp, *o, 0, o2) != TCL_OK) { /* ref count is not incremented */
            /* Error msg in interp result */
            SWIG_fail;
        }
        if (Tcl_GetDoubleFromObj(interp, *o2, &x ) != TCL_OK) {
            /* Error msg in interp result */
            SWIG_fail;
        }

        if (Tcl_ListObjIndex(interp, *o, 1, o2) != TCL_OK) { /* ref count is not incremented */
            /* Error msg in interp result */
            SWIG_fail;
        }
        if (Tcl_GetDoubleFromObj(interp, *o2, &y ) != TCL_OK) {
            /* Error msg in interp result */
            SWIG_fail;
        }

        if (size == 3) {
            if (Tcl_ListObjIndex(interp, *o, 2, o2) != TCL_OK) { /* ref count is not incremented */
                /* Error msg in interp result */
                SWIG_fail;
            }
            if (Tcl_GetDoubleFromObj(interp, *o2, &z ) != TCL_OK) {
                /* Error msg in interp result */
                SWIG_fail;
            }
        }

        ($2)[i] = x;
        ($3)[i] = y;
        ($4)[i] = z;
    }
}

%typemap(argout)  (int nCount, double *x, double *y, double *z)
{
  /* %typemap(argout)  (int nCount, double *x, double *y, double *z) */
  Tcl_Obj *out = Tcl_NewListObj(0, NULL);
  for( int i=0; i< $1; i++ ) {
      Tcl_Obj *tuple = Tcl_NewListObj(0, NULL);
      Tcl_Obj *val = Tcl_NewDoubleObj(($2)[i] );
      if (Tcl_ListObjAppendElement(interp, tuple, val) != TCL_OK) {
          Tcl_DecrRefCount(val);
          Tcl_DecrRefCount(tuple);
          Tcl_DecrRefCount(out);
          /* Error msg in interp result */
          SWIG_fail;
      }
      val = Tcl_NewDoubleObj(($3)[i] );
      if (Tcl_ListObjAppendElement(interp, tuple, val) != TCL_OK) {
          Tcl_DecrRefCount(val);
          Tcl_DecrRefCount(tuple);
          Tcl_DecrRefCount(out);
          /* Error msg in interp result */
          SWIG_fail;
      }
      val = Tcl_NewDoubleObj(($4)[i] );
      if (Tcl_ListObjAppendElement(interp, tuple, val) != TCL_OK) {
          Tcl_DecrRefCount(val);
          Tcl_DecrRefCount(tuple);
          Tcl_DecrRefCount(out);
          /* Error msg in interp result */
          SWIG_fail;
      }
      if (Tcl_ListObjAppendElement(interp, out, tuple) != TCL_OK) {
          Tcl_DecrRefCount(tuple);
          Tcl_DecrRefCount(out);
          /* Error msg in interp result */
          SWIG_fail;
      }
  }
  Tcl_SetObjResult(interp, out);
}

%typemap(freearg)  (int nCount, double *x, double *y, double *z)
{
    /* %typemap(freearg)  (int nCount, double *x, double *y, double *z) */
    CPLFree($2);
    CPLFree($3);
    CPLFree($4);
}

/***************************************************
 * Typemaps for Transform.TransformPoints()
 ***************************************************/

%typemap(in,numinputs=1) (int nCount, double *x, double *y, double *z, int* panSuccess)
{
  /*  typemap(in,numinputs=1) (int nCount, double *x, double *y, double *z, int* panSuccess) */
  /* The following also checks if input is a list */
  if (Tcl_ListObjLength(interp, $input, &$1) != TCL_OK) {
    /* Error msg in interp result */
    SWIG_fail;
  }
  if ( !$1 ) {
      Tcl_SetResult(interp, (char*) "Input list mustn't be empty", TCL_STATIC);
      SWIG_fail;
  }
  $2 = (double*) CPLMalloc($1*sizeof(double));
  $3 = (double*) CPLMalloc($1*sizeof(double));
  $4 = (double*) CPLMalloc($1*sizeof(double));
  $5 = (int*) CPLMalloc($1*sizeof(int));

  for( int i = 0; i<$1; i++ ) {

        Tcl_Obj **o = NULL;
        if (Tcl_ListObjIndex(interp, $input, i, o) != TCL_OK) { /* ref count is not incremented */
            /* Error msg in interp result */
            SWIG_fail;
        }

        int size;
        if (Tcl_ListObjLength(interp, *o, &size) != TCL_OK) {
            /* Error msg in interp result */
            SWIG_fail;
        }
        if ( size < 2 || size > 3 ) {
            Tcl_SetResult(interp, (char*) "Not a list of 2 or 3 doubles", TCL_STATIC);
            SWIG_fail;
        }

        double x, y, z = 0;
        Tcl_Obj **o2 = NULL;
        if (Tcl_ListObjIndex(interp, *o, 0, o2) != TCL_OK) { /* ref count is not incremented */
            /* Error msg in interp result */
            SWIG_fail;
        }
        if (Tcl_GetDoubleFromObj(interp, *o2, &x ) != TCL_OK) {
            /* Error msg in interp result */
            SWIG_fail;
        }

        if (Tcl_ListObjIndex(interp, *o, 1, o2) != TCL_OK) { /* ref count is not incremented */
            /* Error msg in interp result */
            SWIG_fail;
        }
        if (Tcl_GetDoubleFromObj(interp, *o2, &y ) != TCL_OK) {
            /* Error msg in interp result */
            SWIG_fail;
        }

        if (size == 3) {
            if (Tcl_ListObjIndex(interp, *o, 2, o2) != TCL_OK) { /* ref count is not incremented */
                /* Error msg in interp result */
                SWIG_fail;
            }
            if (Tcl_GetDoubleFromObj(interp, *o2, &z ) != TCL_OK) {
                /* Error msg in interp result */
                SWIG_fail;
            }
        }

        ($2)[i] = x;
        ($3)[i] = y;
        ($4)[i] = z;
  }
}

%typemap(argout)  (int nCount, double *x, double *y, double *z, int* panSuccess)
{
  /* %typemap(argout)  (int nCount, double *x, double *y, double *z, int* panSuccess) */
  Tcl_Obj *xyz = Tcl_NewListObj(0, NULL);
  Tcl_Obj *success = Tcl_NewListObj(0, NULL);
  for( int i=0; i< $1; i++ ) {
      Tcl_Obj *tuple = Tcl_NewListObj(0, NULL);
      Tcl_Obj *val = Tcl_NewDoubleObj(($2)[i] );
      if (Tcl_ListObjAppendElement(interp, tuple, val) != TCL_OK) {
          Tcl_DecrRefCount(val);
          Tcl_DecrRefCount(tuple);
          Tcl_DecrRefCount(xyz);
          Tcl_DecrRefCount(success);
          /* Error msg in interp result */
          SWIG_fail;
      }
      val = Tcl_NewDoubleObj(($3)[i] );
      if (Tcl_ListObjAppendElement(interp, tuple, val) != TCL_OK) {
          Tcl_DecrRefCount(val);
          Tcl_DecrRefCount(tuple);
          Tcl_DecrRefCount(xyz);
          Tcl_DecrRefCount(success);
          /* Error msg in interp result */
          SWIG_fail;
      }
      val = Tcl_NewDoubleObj(($4)[i] );
      if (Tcl_ListObjAppendElement(interp, tuple, val) != TCL_OK) {
          Tcl_DecrRefCount(val);
          Tcl_DecrRefCount(tuple);
          Tcl_DecrRefCount(xyz);
          Tcl_DecrRefCount(success);
          /* Error msg in interp result */
          SWIG_fail;
      }

      if (Tcl_ListObjAppendElement(interp, xyz, tuple) != TCL_OK) {
          Tcl_DecrRefCount(tuple);
          Tcl_DecrRefCount(xyz);
          Tcl_DecrRefCount(success);
          /* Error msg in interp result */
          SWIG_fail;
      }

      val = Tcl_NewIntObj(($5)[i] );
      if (Tcl_ListObjAppendElement(interp, success, val) != TCL_OK) {
          Tcl_DecrRefCount(val);
          Tcl_DecrRefCount(xyz);
          Tcl_DecrRefCount(success);
          /* Error msg in interp result */
          SWIG_fail;
      }
  }

  Tcl_Obj *out = Tcl_NewListObj(0, NULL);
  if (Tcl_ListObjAppendElement(interp, out, xyz) != TCL_OK) {
      Tcl_DecrRefCount(xyz);
      Tcl_DecrRefCount(out);
      Tcl_DecrRefCount(success);
      /* Error msg in interp result */
      SWIG_fail;
  }
  if (Tcl_ListObjAppendElement(interp, out, success) != TCL_OK) {
      Tcl_DecrRefCount(success);
      Tcl_DecrRefCount(out);
      /* Error msg in interp result */
      SWIG_fail;
  }
  Tcl_SetObjResult(interp, out);
}

%typemap(freearg)  (int nCount, double *x, double *y, double *z, int* panSuccess)
{
    /* %typemap(freearg)  (int nCount, double *x, double *y, double *z, int* panSuccess) */
    CPLFree($2);
    CPLFree($3);
    CPLFree($4);
    CPLFree($5);
}
