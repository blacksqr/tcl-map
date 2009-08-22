# wishrc.tcl --
#
# tcl/tk initialization script (for window shell "wish")
#
# For Windows this should be copied to C:\wishrc.tcl
# For  Unix   this should be copied to ~/.wishrc
#
# Copyright (c) 1999, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: wishrc.tcl,v 1.4 2006/06/27 06:17:26 dav480 Exp $

# Source initialization script for non-windows shell "tclsh" (unless already done).

if {$tcl_platform(platform) eq "unix"} {
    set script ~/.tclshrc
} else {
    set script ~/tclshrc.tcl
}
if {[file exists $script]} {
    source $script
}
unset script
caps_nap_menu
