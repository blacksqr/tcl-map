# tclshrc.tcl --
#
# tcl initialization script
#
# For Windows this should be copied to C:\tclshrc.tcl
# For  Unix   this should be copied to ~/.tclshrc
#
# Copyright (c) 1999-2001, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: tclshrc.tcl,v 1.4 2005/07/13 02:24:11 dav480 Exp $
#
# Increase size of history list to 999 (instead of default of 20).
# Load package 'nap'.
#
# Try to load package 'caps'. If this succeeds then try to find sensible
# value for variable 'caps_directory' (e.g. $env(CAPS)).
#
# Use existence of variable 'tclshrc_done' as indicator that this script has already been
# executed and should not be exectuted again.

if {![info exists ::tclshrc_done]} {
    set ::tclshrc_done 1
    history keep 999
    namespace eval TMP {
	if {[info exists ::env(TCLSHRC_MUTE)] && $::env(TCLSHRC_MUTE) || !$tcl_interactive} {
	    proc puts args {}
	}
	puts "home directory = [file nativename ~]"
	puts "tcl_library = $::tcl_library"
	if {[catch "package require nap" msg]} {
	    puts $msg
	} else {
	    puts "loaded nap$::nap_patchLevel"
	}
	if {[catch "package require caps" msg]} {
	} else {
	    puts "loaded caps$::caps_patchLevel"
	    if {[info exists ::env(CAPS)]} {
		set ::caps_directory $::env(CAPS)
	    } else {
		set ::caps_directory [file dirname [file dirname $::tcl_library]]/caps
	    }
	    puts "caps_directory = $::caps_directory"
	}
    }
    namespace delete TMP
    namespace import ::NAP::*
    if {[file readable ~/my.tcl]} {
	source ~/my.tcl
    }
}
