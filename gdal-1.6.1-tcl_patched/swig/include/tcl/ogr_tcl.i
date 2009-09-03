/*
 *
 * tcl specific code for ogr bindings.
 */

%include "cpl_exceptions.i";

%init %{
  /* ogr_tcl.i %init code */
  if ( OGRGetDriverCount() == 0 ) {
    OGRRegisterAll();
  }
  
  /* Setup exception handling */
  UseExceptions();
%}


%rename (GetDriverCount) OGRGetDriverCount;
%rename (GetOpenDSCount) OGRGetOpenDSCount;
%rename (SetGenerate_DB2_V72_BYTE_ORDER) OGRSetGenerate_DB2_V72_BYTE_ORDER;
%rename (RegisterAll) OGRRegisterAll();

%extend OGRDataSourceShadow {
//SWIG_exception(SWIG_TypeError, "Value must be a string or integer.");
}

%extend OGRLayerShadow {

}

%extend OGRFeatureShadow {

}

%extend OGRGeometryShadow {
}


%extend OGRFieldDefnShadow {
}

%extend OGRFeatureDefnShadow {
}

%extend OGRFieldDefnShadow {
}

%import typemaps_tcl.i
