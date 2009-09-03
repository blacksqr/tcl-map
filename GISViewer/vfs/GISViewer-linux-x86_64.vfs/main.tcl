package require starkit
starkit::startup
cd $starkit::topdir

set VRootDir [file normalize [file dirname [info script]]]
set RootDir [file dirname $VRootDir]

if {! [info exists env(LD_LIBRARY_PATH)] || $env(LD_LIBRARY_PATH) ne [file join $RootDir lib]} {
    exec sh [file join $RootDir start.sh] $::argv &
} else {
    set env(GDAL_DATA) [file join $RootDir lib gdal]
    source [file join $VRootDir gisv.tcl]
}
