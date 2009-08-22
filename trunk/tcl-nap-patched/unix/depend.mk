napsh${OBJEXT}: ${GENERIC_DIR}/napsh.c \
  ${GENERIC_DIR}/napInt.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h
cart_proj${OBJEXT}: ${GENERIC_DIR}/cart_proj.c \
  ${PROJ_HEADER_DIR}/proj_api.h \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
eval_tree${OBJEXT}: ${GENERIC_DIR}/eval_tree.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/napParse.tab.h
land_flag${OBJEXT}: ${GENERIC_DIR}/land_flag.c \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/land_flag.h
land_flag_i${OBJEXT}: ${GENERIC_DIR}/land_flag_i.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/land_flag.h
napImgNAO${OBJEXT}: ${GENERIC_DIR}/napImgNAO.c \
  ${TCL_HEADER_DIR}/tk.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${TCL_HEADER_DIR}/tkDecls.h \
  ${GENERIC_DIR}/nap.h \
  ${GENERIC_DIR}/nap_check.h
napInit${OBJEXT}: ${GENERIC_DIR}/napInit.c \
  ${TCL_HEADER_DIR}/tk.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${TCL_HEADER_DIR}/tkDecls.h \
  ${GENERIC_DIR}/nap.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/napInt.h
napPolygon${OBJEXT}: ${GENERIC_DIR}/napPolygon.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/napPolygon.h
nap_get${OBJEXT}: ${GENERIC_DIR}/nap_get.c \
  ${GENERIC_DIR}/napInt.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_hdf.h \
  ${HDF_HEADER_DIR}/mfhdf.h ${HDF_HEADER_DIR}/hdf.h \
  ${HDF_HEADER_DIR}/h4config.h \
  ${HDF_HEADER_DIR}/hdfi.h \
  ${HDF_HEADER_DIR}/hlimits.h \
  ${HDF_HEADER_DIR}/hntdefs.h \
  ${HDF_HEADER_DIR}/htags.h \
  ${HDF_HEADER_DIR}/hbitio.h \
  ${HDF_HEADER_DIR}/hcomp.h \
  ${HDF_HEADER_DIR}/herr.h \
  ${HDF_HEADER_DIR}/hproto.h ${HDF_HEADER_DIR}/vg.h \
  ${HDF_HEADER_DIR}/mfgr.h \
  ${NC_HEADER_DIR}/netcdf.h \
  ${GENERIC_DIR}/nap.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/nap_netcdf.h
triangulate${OBJEXT}: ${GENERIC_DIR}/triangulate.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/triangulate.h
function${OBJEXT}: ${GENERIC_DIR}/function.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/linsys.h
geometry${OBJEXT}: ${GENERIC_DIR}/geometry.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
linsys${OBJEXT}: ${GENERIC_DIR}/linsys.c \
  ${GENERIC_DIR}/linsys.h \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
nap${OBJEXT}: ${GENERIC_DIR}/nap.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/napInt.h
napChoice${OBJEXT}: ${GENERIC_DIR}/napChoice.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
napDyad${OBJEXT}: ${GENERIC_DIR}/napDyad.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
napDyadLib${OBJEXT}: ${GENERIC_DIR}/napDyadLib.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
napLib${OBJEXT}: ${GENERIC_DIR}/napLib.c \
  ${GENERIC_DIR}/nap_hdf.h \
  ${HDF_HEADER_DIR}/mfhdf.h ${HDF_HEADER_DIR}/hdf.h \
  ${HDF_HEADER_DIR}/h4config.h \
  ${HDF_HEADER_DIR}/hdfi.h \
  ${HDF_HEADER_DIR}/hlimits.h \
  ${HDF_HEADER_DIR}/hntdefs.h \
  ${HDF_HEADER_DIR}/htags.h \
  ${HDF_HEADER_DIR}/hbitio.h \
  ${HDF_HEADER_DIR}/hcomp.h \
  ${HDF_HEADER_DIR}/herr.h \
  ${HDF_HEADER_DIR}/hproto.h ${HDF_HEADER_DIR}/vg.h \
  ${HDF_HEADER_DIR}/mfgr.h \
  ${NC_HEADER_DIR}/netcdf.h \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
napMonad${OBJEXT}: ${GENERIC_DIR}/napMonad.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/napParse.tab.h
napParseLib${OBJEXT}: ${GENERIC_DIR}/napParseLib.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/napParse.tab.h
napSpatial${OBJEXT}: ${GENERIC_DIR}/napSpatial.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
nap_netcdf${OBJEXT}: ${GENERIC_DIR}/nap_netcdf.c \
  ${GENERIC_DIR}/nap_netcdf.h \
  ${NC_HEADER_DIR}/netcdf.h \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
nap_ooc${OBJEXT}: ${GENERIC_DIR}/nap_ooc.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_hdf.h \
  ${HDF_HEADER_DIR}/mfhdf.h ${HDF_HEADER_DIR}/hdf.h \
  ${HDF_HEADER_DIR}/h4config.h \
  ${HDF_HEADER_DIR}/hdfi.h \
  ${HDF_HEADER_DIR}/hlimits.h \
  ${HDF_HEADER_DIR}/hntdefs.h \
  ${HDF_HEADER_DIR}/htags.h \
  ${HDF_HEADER_DIR}/hbitio.h \
  ${HDF_HEADER_DIR}/hcomp.h \
  ${HDF_HEADER_DIR}/herr.h \
  ${HDF_HEADER_DIR}/hproto.h ${HDF_HEADER_DIR}/vg.h \
  ${HDF_HEADER_DIR}/mfgr.h \
  ${NC_HEADER_DIR}/netcdf.h \
  ${GENERIC_DIR}/nap_check.h \
  ${GENERIC_DIR}/nap_netcdf.h \
  ${GENERIC_DIR}/napPolygon.h
nap_hdf${OBJEXT}: ${GENERIC_DIR}/nap_hdf.c \
  ${GENERIC_DIR}/nap_hdf.h \
  ${HDF_HEADER_DIR}/mfhdf.h ${HDF_HEADER_DIR}/hdf.h \
  ${HDF_HEADER_DIR}/h4config.h \
  ${HDF_HEADER_DIR}/hdfi.h \
  ${HDF_HEADER_DIR}/hlimits.h \
  ${HDF_HEADER_DIR}/hntdefs.h \
  ${HDF_HEADER_DIR}/htags.h \
  ${HDF_HEADER_DIR}/hbitio.h \
  ${HDF_HEADER_DIR}/hcomp.h \
  ${HDF_HEADER_DIR}/herr.h \
  ${HDF_HEADER_DIR}/hproto.h ${HDF_HEADER_DIR}/vg.h \
  ${HDF_HEADER_DIR}/mfgr.h \
  ${NC_HEADER_DIR}/netcdf.h \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
napParse.tab${OBJEXT}: ${GENERIC_DIR}/napParse.tab.c \
  ${GENERIC_DIR}/nap.h \
  ${TCL_HEADER_DIR}/tcl.h \
  ${TCL_HEADER_DIR}/tclDecls.h \
  ${TCL_HEADER_DIR}/tclPlatDecls.h \
  ${GENERIC_DIR}/nap_check.h
