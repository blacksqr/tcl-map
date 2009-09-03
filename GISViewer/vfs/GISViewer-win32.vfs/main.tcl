package require starkit
starkit::startup
cd $starkit::topdir

set VRootDir [file normalize [file dirname [info script]]]
set RootDir [file dirname $VRootDir]

append env(PATH) ";[file join $RootDir lib]"

source [file join $VRootDir gisv.tcl]
