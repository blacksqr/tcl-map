# old.tcl --
# 
# Copyright (c) 2000, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: old.tcl,v 1.9 2002/08/28 01:50:42 dav480 Exp $
#
# Define functions & commands compatible with those defined in old versions of NAP.


namespace eval ::NAP {


    # ap0 --
    #
    # Function "ap0" gives same result as nap arithmetic progression function "ap"
    # if (z-a) is multiple of d.  Even if it is not a multiple, ap0 still gives
    # vector ending with z.

    proc ap0 {
	a
	z
	{d 1}
    } {
	nap "a .. z ... d"
    }


    # ap_n --
    #
    # Function "ap_n" gives arithmetic progression from a to z with n elements.

    proc ap_n {
	a 
	z 
	{n 2}
    } {
	nap "n ... a .. z"
    }


    # old type conversion functions --

    proc character	x {nap "c8(x)"}
    proc byte	x {nap "u8(x)"}
    proc short	x {nap "i16(x)"}
    proc integer	x {nap "i32(x)"}
    proc float	x {nap "f32(x)"}
    proc double	x {nap "f64(x)"}


    # nap_hdf --
    #
    # This provides compatibility with obsolete command "nap_hdf"

    proc nap_hdf {sub_command args} {
	switch -regexp $sub_command {
	    ^g              {uplevel nap_get hdf $args}
	    ^l              {uplevel nap_get hdf -list $args}
	    default         {return -code error "nap_hdf: Illegal sub_command"}
	}
    }


    # frequency --
    #
    # This provides compatibility with obsolete function "frequency"

    proc frequency {
	x
	n
	{low 0}
	{delta 1}
    } {
	nap "v = low .. (low + (n-1) * delta) ... delta"
	nap "f = # i32(floor(v @ x) <<< (n-1))"
	nap "m = (shape f)(0)"
	nap "f = sum(reshape(f, m // (nels(f) / m)), 1)"
	$f set coo v
	nap "f"
    }


}
