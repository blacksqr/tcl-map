set RootDir [file normalize [file dirname [info script]]]

append env(PATH) ";[file join $RootDir lib]"
foreach lib [glob -types d -nocomplain -- [file join $RootDir lib *]] {
	lappend auto_path $lib
	append env(PATH) ";$lib"
}
unset lib

source [file join $RootDir gisv.tcl]
