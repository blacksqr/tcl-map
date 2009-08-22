# cp2vfs.tcl --
#
# Copy NAP files to directory nap_installer.vfs
# This is run by 'make'
#
# Copyright (c) 2004, CSIRO Australia
# Author: Harvey Davies, CSIRO.

source ../library/proc_lib.tcl

set package nap
set version $env(VERSION)
set installer_name $env(INSTALLER_NAME)
set version_no_dot [string map {. _} $version]
set root ../..
set sle [info sharedlibextension]
set vfs ${installer_name}.vfs

# Like glob except that checks result contains exactly 1 file
proc glob1 pattern {
    set result [glob $pattern]
    set n [llength $result]
    if {$n != 1} {
	error "cp2vfs: $n files ($result) match pattern '$pattern'. Should be exactly 1!"
    }
    return $result
}

set include [file tail [lindex [glob $root/include*] end]]
if {$tcl_platform(machine) eq "ia64" } {
    file mkdir $vfs/home $vfs/tcl
    file copy $root/bin $root/$include $root/lib $root/man $vfs/tcl/
} else {
    file mkdir $vfs/home $vfs/tcl/bin $vfs/tcl/$include $vfs/tcl/lib/$package$version 
    foreach f [glob -nocomplain $root/$include/${package}*.h] {
	file copy $f $vfs/tcl/$include
    }
    copy_tree $root/lib/$package$version $vfs/tcl/lib/$package$version
    switch $tcl_platform(platform) {
	unix {
	    file copy ../installer/tclshrc.tcl $vfs/home/.tclshrc
	    file copy ../installer/wishrc.tcl  $vfs/home/.wishrc
	    file copy ../installer/tkcon.cfg   $vfs/home/.tkconrc
	    file copy $root/lib/lib$package$version$sle $vfs/tcl/lib
	}
	windows {
	    file copy ../installer/tclshrc.tcl $vfs/home
	    file copy ../installer/wishrc.tcl  $vfs/home
	    file copy ../installer/tkcon.cfg   $vfs/home
	    foreach f "$package$version_no_dot hd???m hm???m netcdf zlib1 szlibdll" { 
		file copy [glob1 $root/bin/$f$sle] $vfs/tcl/bin
	    }
	    set f [file tail [glob1 $root/lib/ezprint*]]
	    file mkdir $vfs/tcl/lib/$f
	    copy_tree $root/lib/$f $vfs/tcl/lib/$f
	    file copy $root/lib/$package$version_no_dot.lib $vfs/tcl/lib
	}
	default {
	    puts "Running on unsupported platform"
	}
    }
}
