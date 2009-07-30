/*
 *
 * tcl specific code for osr bindings.
 */


%include "cpl_exceptions.i";

%{
static Tcl_Obj *
tcl_OPTGetProjectionMethods(Tcl_Obj *self, Tcl_Obj *args) {
    Tcl_Obj *MList;
    char     **papszMethods;
    int      iMethod;

    self = self;
    args = args;

    papszMethods = OPTGetProjectionMethods();
    MList = Tcl_NewListObj(0, NULL);

    for( iMethod = 0; papszMethods[iMethod] != NULL; iMethod++ ) {
        char    *pszUserMethodName;
        char    **papszParameters;
        Tcl_Obj *PList;
        Tcl_Obj *val;
        int       iParam;

        papszParameters = OPTGetParameterList( papszMethods[iMethod],
                &pszUserMethodName );
        if( papszParameters == NULL )
            return NULL;

        PList = Tcl_NewListObj(0, NULL);
        for( iParam = 0; papszParameters[iParam] != NULL; iParam++ ) {
            char    *pszType;
            char    *pszUserParamName;
            double  dfDefault;

            OPTGetParameterInfo( papszMethods[iMethod],
                    papszParameters[iParam],
                    &pszUserParamName,
                    &pszType, &dfDefault );

            val = Tcl_NewStringObj( papszParameters[iParam], -1 );
            if (Tcl_ListObjAppendElement(NULL, PList, val) != TCL_OK) {
                Tcl_DecrRefCount(val);
                Tcl_DecrRefCount(PList);
                Tcl_DecrRefCount(MList);
                return NULL; /* signifies error */
            }
            val = Tcl_NewStringObj( pszUserParamName, -1 );
            if (Tcl_ListObjAppendElement(NULL, PList, val) != TCL_OK) {
                Tcl_DecrRefCount(val);
                Tcl_DecrRefCount(PList);
                Tcl_DecrRefCount(MList);
                return NULL; /* signifies error */
            }
            val = Tcl_NewStringObj( pszType, -1 );
            if (Tcl_ListObjAppendElement(NULL, PList, val) != TCL_OK) {
                Tcl_DecrRefCount(val);
                Tcl_DecrRefCount(PList);
                Tcl_DecrRefCount(MList);
                return NULL; /* signifies error */
            }
            val = Tcl_NewDoubleObj( dfDefault );
            if (Tcl_ListObjAppendElement(NULL, PList, val) != TCL_OK) {
                Tcl_DecrRefCount(val);
                Tcl_DecrRefCount(PList);
                Tcl_DecrRefCount(MList);
                return NULL; /* signifies error */
            }
        }

        CSLDestroy( papszParameters );

        val = Tcl_NewStringObj( papszMethods[iMethod], -1 );
        if (Tcl_ListObjAppendElement(NULL, MList, val) != TCL_OK) {
            Tcl_DecrRefCount(val);
            Tcl_DecrRefCount(PList);
            Tcl_DecrRefCount(MList);
            return NULL; /* signifies error */
        }
        val = Tcl_NewStringObj( pszUserMethodName, -1 );
        if (Tcl_ListObjAppendElement(NULL, MList, val) != TCL_OK) {
            Tcl_DecrRefCount(val);
            Tcl_DecrRefCount(PList);
            Tcl_DecrRefCount(MList);
            return NULL; /* signifies error */
        }
        if (Tcl_ListObjAppendElement(NULL, MList, PList) != TCL_OK) {
            Tcl_DecrRefCount(PList);
            Tcl_DecrRefCount(MList);
            return NULL; /* signifies error */
        }
    }

    CSLDestroy( papszMethods );

    return MList;
}
%}
%native(GetProjectionMethods) tcl_OPTGetProjectionMethods;

%include typemaps_tcl.i
