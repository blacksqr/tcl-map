package require starkit
starkit::startup
cd $starkit::topdir

set VfsRootDir [file normalize [file dirname [info script]]]
set RootDir [file dirname $VfsRootDir]

set env(LD_LIBRARY_PATH) [file join $RootDir lib]
foreach lib [glob -types d -nocomplain -- [file join $RootDir lib *]] {
    lappend auto_path $lib
    append env(PATH) ";$lib"
}
unset lib

source [file join $RootDir gisv.tcl]
