#!/bin/sh
abspath="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"
path_only=`dirname "$abspath"`
export LD_LIBRARY_PATH=$path_only/lib
$path_only/GISViewer $@
