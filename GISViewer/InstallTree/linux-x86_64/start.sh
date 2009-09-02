#!/bin/sh
echo $@
abspath="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"
ROOTDIR=`dirname "$abspath"`
export GDAL_DATA=$ROOTDIR/lib/gdal
(LD_LIBRARY_PATH=$ROOTDIR/lib $ROOTDIR/tclkit $ROOTDIR/gisv.tcl $@ &)
