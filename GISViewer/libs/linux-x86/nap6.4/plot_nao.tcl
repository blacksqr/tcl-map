# plot_nao.tcl --
# 
# Copyright (c) 2001, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: plot_nao.tcl,v 1.124 2004/10/19 01:34:44 dav480 Exp $


# plot_nao --
#
# This defines global cover procedure plot_nao which calls Plot_nao::plot_nao which
# is defined in file plot_nao_procs.tcl
#
# Usage
#   See plot_nao.html
#
# This is defined in a separate file to facilitate re-definition (e.g. with different defaults)

proc plot_nao {
    args
} {
    eval ::Plot_nao::plot_nao $args
}


# animate --
# Animate frames produced by plot_nao
#
# Usage (See also plot_nao.html)
#   set frames [plot_nao ...]
#   animate $frames ?period?
#	period is time in milliseconds for each frame

proc animate {
    frames
    {period 500}
} {
    foreach frame $frames {
	raise $frame
	update
	after $period
    }
}
