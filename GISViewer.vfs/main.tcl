package require starkit
starkit::startup
starkit::autoextend [file join $starkit::topdir lib]
foreach lib [glob -nocomplain -type d [file join lib *]] {
    starkit::autoextend [file join $starkit::topdir $lib]
}
cd $starkit::topdir
source gisv.tcl
