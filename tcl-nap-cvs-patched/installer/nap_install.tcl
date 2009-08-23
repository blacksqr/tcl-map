# nap_install.tcl --
#
# This is sourced by the NAP installation starpack (nap_install.exe for windows)
#
# Copyright (c) 2004, CSIRO Australia
# Author: Harvey Davies, CSIRO.

package provide app-nap_install 1.1
package require Tk
cd $::starkit::topdir

# copy_tree --
# src & dst are both existing directories
# copy recursively every file & directory in src to dst

proc copy_tree {
    src
    dst
} {
    if {![file isdirectory $src]} {
	error "copy_tree: '$src' is not directory"
    }
    if {![file isdirectory $dst]} {
	error "copy_tree: '$dst' is not directory"
    }
    foreach file [glob -nocomplain -tails -directory $src *] {
	if {[file isdirectory $src/$file]} {
	    if {![file isdirectory $dst/$file]} {
		if {[file exists $dst/$file]} {
		    file -force delete $dst/$file
		}
		file mkdir $dst/$file
	    }
	    copy_tree $src/$file $dst/$file
	} else {
	    file copy -force $src/$file $dst
	    switch $::tcl_platform(platform) {
		unix {
		    file attributes $dst/$file -permissions +r
		    if {[file tail $dst] eq "bin"} {
			file attributes $dst/$file -permissions +x
		    }
		}
	    }
	}
    }
}

switch $::tcl_platform(platform) {
    unix {
	set dir1 ~
	set dirs {/usr/tcl /usr/local/tcl ~/tcl}
    }
    windows {
	set dir1 "C:/"
	set dirs {{C:/Tcl} {C:/Program Files/Tcl}}
    }
    default {
	puts "Running on unsupported platform"
    }
}
foreach dir $dirs {
    if {[file isdirectory $dir]} {
	set dir1 $dir
    }
}
set dir [file nativename [lindex $dirs end]]
set dst [tk_chooseDirectory \
    -initialdir $dir1 \
    -title "directory in which to install nap"]
if {$dst ne ""} {
    if {$::tcl_platform(machine) eq "ia64" } {
	set include include
    } else {
	set include [file tail [lindex [glob $dst/include*] end]]
	foreach dir "bin $include lib" {
	    if {![file isdirectory $dst/$dir]} {
		set reply [tk_messageBox \
		    -message "Expected directory '$dst/$dir' not found! Continue?" \
		    -type yesno]
		if {$reply ne "yes"} {
		    exit
		}
	    }
	}
    }
    set bin_files     [glob -nocomplain -types f $dst/bin/nap*.dll]
    set include_files [glob -nocomplain -types f $dst/$include/nap*.h]
    set lib_files     [glob -nocomplain -types f $dst/lib/nap*.lib $dst/lib/libnap*.s?]
    set lib_dirs      [glob -nocomplain -types d $dst/lib/nap*]
    set files "$bin_files $include_files $lib_files $lib_dirs"
    if {[llength $files] > 0} {
	set reply [tk_messageBox \
	    -message "Found old nap files in '$dst'! Delete them?" \
	    -type yesno]
	if {$reply eq "yes"} {
	    foreach file $files {
		file delete -force $file
	    }
	}
    }
    puts "Installing nap in '[file nativename $dst]'"
    copy_tree tcl $dst
    cd home
    set files "[glob -nocomplain *] [glob -nocomplain -types {f hidden} *]"
    set files [string trim [lsort -unique $files]]
    foreach file $files {
	file copy -force $file $dst
    }
    set reply [tk_messageBox \
	-message "Install startup files ($files)?" \
	-type yesno]
    if {$reply eq "yes"} {
	set dst [tk_chooseDirectory \
	    -initialdir ~ \
	    -title "directory in which to install startup files ($files)"]
	foreach file $files {
	    file copy -force $file $dst
	}
    }
}
exit
