package require starkit
starkit::startup
foreach lib [glob -type d [file join lib *]] {
    starkit::autoextend [file join $starkit::topdir $lib]
}
cd $starkit::topdir
source gisv.tcl

