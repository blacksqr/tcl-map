package require starkit
starkit::startup
cd $starkit::topdir

set VRootDir [file normalize [file dirname [info script]]]
set RootDir [file dirname $VRootDir]

append env(PATH) ";[file join $RootDir lib]"
set env(GDAL_DATA) [file join $RootDir lib gdal]

source [file join $VRootDir gisv.tcl]
