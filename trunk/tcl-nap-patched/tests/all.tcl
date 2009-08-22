# all.tcl --
# 
# Test command 'nap'
#
# Copyright (c) 1999, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: all.tcl,v 1.30 2005/11/30 06:07:24 dav480 Exp $


if {[lsearch [namespace children] ::tcltest] == -1} {
    package require tcltest
    namespace import ::tcltest::*
}

set ::tcltest::testConstraints(tk) [info exists tk_version]
set ::tcltest::testsDirectory [file dir [info script]]
set shared_lib ""

::tcltest::configure -verbose bp;	# p = Print line for each  passed test
::tcltest::configure -verbose b;	# b = Print line for each  failed test

# if no nap then load nap shared lib from current working directory
if {![info exists nap_version]} {
    if {[info exists env(PACKAGE_SHLIB)]} {
        set shared_lib [file join $::tcltest::workingDirectory $env(PACKAGE_SHLIB)]
        puts "Loading shared library $shared_lib"
        load $shared_lib
    }
}

if {[info command nap] eq ""} {
    package require nap
    namespace import ::NAP::*
}

set files "\
	$env(LIBRARY_DIR)/nap_proc_lib.tcl \
	$env(LIBRARY_DIR)/proc_lib.tcl \
	$env(LIBRARY_DIR)/date.tcl \
	$env(LIBRARY_DIR)/geog.tcl \
	$env(LIBRARY_DIR)/land.tcl \
	$env(LIBRARY_DIR)/nap_function_lib.tcl \
	$env(LIBRARY_DIR)/old.tcl \
	$env(LIBRARY_DIR)/stat.tcl \
	[lsort [::tcltest::getMatchingFiles]]"
foreach file $files {
    puts stdout "[clock format [clock seconds] -format %H:%M:%S] CPU=[nap_info sec] sec.\
	    Sourcing file $file"
    if {[catch {source $file} msg]} {
	puts stdout "error processing file $file: $msg"
    }
    set b [nap_info bytes]
    puts "[llength [list_naos]] NAOs using [lindex $b 0] bytes.  Other = [lindex $b 2] bytes"
}

::tcltest::cleanupTests
