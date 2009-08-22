# my.tcl --
#
# Tailor Tcl to personal requirements
# Copy to your home directory
# Called by ~/.tclshrc or ~/tclshrc.tcl
#
# Copyright (c) 2003-2005, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: my.tcl,v 1.2 2005/01/18 05:36:32 dav480 Exp $

# Define simple aliases

proc define_alias {alias args} {proc $alias args "eval $args \$args"}

define_alias e expr
define_alias n nap
define_alias p pwd
define_alias cp file copy
define_alias md file mkdir
define_alias rm file delete
