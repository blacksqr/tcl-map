# mk3.tcl --
#
# NAP functions for processing data from Mark3 GCM.
# These are all concerned with hybrid sigma pressure vertical coordinate.
# See emails from Martin Dix to HD May 2004.
#
# Copyright (c) 2004, CSIRO Australia
#
# Harvey Davies, CSIRO Atmospheric Research
#
# $Id: mk3.tcl,v 1.2 2004/05/27 04:50:31 dav480 Exp $


# mk3pressure --
#
# Calculate pressure at each level (normally 3D with dimensions level, latitude, longitude)
# ps is surface pressure (hPa) (normally matrix, but can have any shape)
#
# Note that there are 19 levels starting from top of atmosphere & ending at surface.

proc mk3pressure {
    ps
} {
    nap "anf = f32{4.51701 21.8901 54.509 98.4744 147.66 194.133 229.797 248.522 247.788
	229.144 197.354 158.669 118.982 82.5753 51.8367 27.8074 11.0522 2.28062 0}"
    nap "bnf = f32{0 0 0.000384987 0.00294574 0.0116707 0.0323328 0.070865 0.131259 0.213945
	0.315337 0.428674 0.54573 0.658631 0.761093 0.848701 0.918371 0.967487 0.993291 1}"
    nap "n = nels(ps)"
    nap "s = 19 // shape(ps)"
    nap "reshape(n # anf, s) + reshape(n # bnf, s) * ps"
}

# mk3atPressure --
#
# Convert Mark 3 model output variable defined on hybrid sigma pressure levels to specified
# pressure levels
#
# Usage:
#    mk3atPressure(p, ps, var)
#    where p specifies desired new pressure levels (hPa) (scalar or vector)
#          ps is surface pressure (hPa) (normally matrix, but can be scalar or vector)
#          var is field to be converted (normally 3D, but in general rank(var) = rank(ps) + 1)
#
# The leading dimension of var is level (size 18). Remaining dimensions must match those of ps.
# If var has unit "K" it is assumed to be temperature & extrapolated using standard lapse rate.

proc mk3atPressure {
    p
    ps
    var
} {
    set c [commas [$ps rank]]
    switch [$p rank] {
	0 {
	    nap "p3 = mk3pressure(ps)"
	    nap "p0 = p3(-2$c)"; # pressure at bottom model level
	    # Define level k. Search each column of p3 for value p. 0 = bottom, 17 = top
	    nap "k = 17f32 - (p3 @ p) >>> 0f32 <<< 17f32"
	    switch [$ps rank] {
		0 {
		    nap "index = k"
		}
		1 {
		    nap "i = 0 .. (nels(ps) - 1)"
		    nap "index = transpose(k /// i)"
		}
		2 {
		    nap "s = shape(ps)"
		    nap "i = reshape(s(1) # (0 .. (s(0) - 1)), s)"
		    nap "j = 0 .. (s(1) - 1)"
		    nap "index = transpose(k /// i // j, {1 2 0})"
		}
		default {
		    error "mk3atPressure: ps has rank > 2"
		}
	    }
	    nap "result = var(index)"
	    if {[$var unit] eq "K"} {
		nap "result = p > p0 ? result * (p/p0) ** 0.1903f32 : result"
	    }
	}
	1 {
	    nap "pressure = +p"
	    $pressure set label "pressure level"
	    $pressure set unit hPa
	    nap "result = reshape(1nf32, shape(p) // shape(ps))"
	    eval $result set dim pressure [$ps dim]
	    eval $result set coo pressure [$ps coo]
	    for {set i 0} {$i < [$p nels]} {incr i} {
		$result set value "mk3atPressure(p(i), ps, var)" "i$c"
	    }
	}
	default {
	    error "mk3atPressure: p has rank > 1"
	}
    }
    $result set label [$var label]
    $result set unit  [$var unit]
    nap "result"
}
