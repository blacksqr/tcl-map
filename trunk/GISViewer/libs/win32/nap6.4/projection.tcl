# projection.tcl --
#
# Copyright (c) 1998, CSIRO Australia
# Author: Harvey Davies, CSIRO.
# $Id: projection.tcl,v 1.5 2001/06/07 07:38:17 dav480 Exp $

# Define functions projection_x and projection_y for specified map projection.

# Usage
# projection ?<CODE>? ?<P0>? ?<P1>? ?<P2>? ...
#    where
#	<CODE> is map projection code (default: "CylindricalEquidistant") as
#	follows:
#	    "CylindricalEquidistant": <P0> = x-origin (default: "")
#	    "Mercator": <P0> = x-origin (default: "")
#	    "NorthPolarEquidistant": North Polar azimuthal equidistant
#	    "SouthPolarEquidistant": South Polar azimuthal equidistant
#	    "SouthPolarStereographic": As used by IASOS
#
#	<P0> <P1> <P2> ...  define parameters of the projection.
#	Some projections use <P0> to specify an "x-origin".  This is the
#	minimum result to be returned by projection_x.  If x-origin is "" then
#	there is no defined minimum result.

proc projection {{code CylindricalEquidistant} args} {
    define_projection $code 0 $args
}

# projection_transpose --
#
# Like projection except that x & y are interchanged i.e. x is vertical
# & y is horizontal.
#
# Usage
# projection_transpose ?<CODE>? ?<P0>? ?<P1>? ?<P2>? ...
#    where
#       <CODE> is map projection code
#       <P0> <P1> <P2> ...  define parameters of the projection

proc projection_transpose {{code CylindricalEquidistant} args} {
    define_projection $code 1 $args
}

# define_projection --
#
# Called by projection or projection_transpose to define projection_x &
# projection_y
#
# Usage
# define_projection ?<CODE>? <TRANSPOSE> ?<P0>? ?<P1>? ?<P2>? ...
#    where
#       <CODE> is map projection code
#       <TRANSPOSE> is 0 for normal orientation, 1 to interchange x and y
#       <P0> <P1> <P2> ...  define parameters of the projection

proc define_projection {code transpose args} {
    if $transpose {
	set horizontal y
	set vertical x
    } else {
	set horizontal x
	set vertical y
    }
    set P0 [lindex $args 0]
    if {$code == "CylindricalEquidistant"} {
	if {$P0 == ""} {
	    proc projection_$horizontal {lat_deg lon_deg} \
		"nap f32(lon_deg)"
	} elseif {$P0 == 0} {
	    proc projection_$horizontal {lat_deg lon_deg} \
		"nap f32(lon_deg % 360.0)"
	} else {
	    proc projection_$horizontal {lat_deg lon_deg} \
		"nap f32($P0 + (lon_deg - ($P0)) % 360.0)"
	}
	proc projection_$vertical {lat_deg lon_deg} \
	    "nap f32(lat_deg)"
    } elseif {$code == "Mercator"} {
	if {$P0 == ""} {
	    proc projection_$horizontal {lat_deg lon_deg} \
		"nap f32(lon_deg)"
	} elseif {$P0 == 0} {
	    proc projection_$horizontal {lat_deg lon_deg} \
		"nap f32(lon_deg % 360.0)"
	} else {
	    proc projection_$horizontal {lat_deg lon_deg} \
		"nap f32($P0 + (lon_deg - ($P0)) % 360.0)"
	}
	proc projection_$vertical {lat_deg lon_deg} \
	    "nap f32(180p-1 * log(tan(0.25p1 + 1r360p1 * lat_deg)))"
    } elseif {$code == "NorthPolarEquidistant"} {
	proc projection_$horizontal {lat_deg lon_deg} \
	    "nap f32((90.0 - lat_deg) * cos(1r180p1 * (lon_deg - 90.0)))"
	proc projection_$vertical {lat_deg lon_deg} \
	    "nap f32((90.0 - lat_deg) * sin(1r180p1 * (lon_deg - 90.0)))"
    } elseif {$code == "SouthPolarEquidistant"} {
	proc projection_$horizontal {lat_deg lon_deg} \
	    "nap f32((90.0 + lat_deg) * cos(1r180p1 * (90.0 - lon_deg)))"
	proc projection_$vertical {lat_deg lon_deg} \
	    "nap f32((90.0 + lat_deg) * sin(1r180p1 * (90.0 - lon_deg)))"
    } elseif {$code == "SouthPolarStereographic"} {

#       The equations are from the General Cartographic Transformation
#       Package (GCTP), U.S. Geological Survey - Snyder, Elassal and
#       Linck, 6/8/92
#
#       input:
#         lat_deg,lon_deg - the latitude, longitude of the point in degrees.
#       output:
#         x,y     - the polar stereographic coordinates of the point in km.
#
#       The standard latitude of the projection is fixed at -71.0 (slat) and
#       the central meridian at 0.0 (clon). Spheroid projection parameters
#       (a,e) are from "WGS 84". False easting and northing (x0,y0) are set
#       so the origin is approximately at (55.0S,180.0E).

	proc tsfn phi \
	    "nap e = 0.08181919
	    nap tan((0.5p1-phi)/2.0) / \
		    ((1.0-e*sin(phi))/(1.0+e*sin(phi)))**(e/2.0)"

	proc msfn phi \
	    "nap e = 0.08181919
	    nap cos(phi) / sqrt(1.0-(e*sin(phi))**2)"

	proc projection_$horizontal {lat_deg lon_deg} \
	    "nap a = 6378.137
	    nap slat = -71.0 / 180p-1
	    nap clon = 0.0
	    nap x0 = 0.0
	    nap sgn = sign(slat)
	    nap rhs = a * msfn(abs(slat)) / tsfn(abs(slat))
	    nap rh = sgn * rhs * tsfn(sgn*lat_deg/180p-1)
	    nap phi = sgn * (lon_deg/180p-1 - clon)
	    nap x0 + rh * sin(phi)"

	proc projection_$vertical {lat_deg lon_deg} \
	    "nap a = 6378.137
	    nap slat = -71.0 / 180p-1
	    nap clon = 0.0
	    nap y0 = 4000.0
	    nap sgn = sign(slat)
	    nap rhs = a * msfn(abs(slat)) / tsfn(abs(slat))
	    nap rh = sgn * rhs * tsfn(sgn*lat_deg/180p-1)
	    nap phi = sgn * (lon_deg/180p-1 - clon)
	    nap y0 - rh * cos(phi)"
    }
}
