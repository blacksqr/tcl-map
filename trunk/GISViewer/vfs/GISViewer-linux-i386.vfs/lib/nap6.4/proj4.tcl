# proj4.tcl --
#
# Define NAP functions related to PROJ.4 cartographic projections library
#
# Copyright (c) 2006, CSIRO Australia
# Author: Harvey Davies, CSIRO.
# $Id: proj4.tcl,v 1.13 2007/11/08 10:08:15 dav480 Exp $

namespace eval ::NAP {

    # proj4gshhs --
    #
    # General projection with GSHHS shoreline overlay
    #
    # Usage
    #   proj4gshhs(in, projection_spec, want_lat_lon, nx, s, min_area, resolution, data_dir,
    #		lat_min, lat_max, lon_min, lon_max)
    # where
    #   in: Input matrix with coordinate variables latitude and longitude
    #   projection_spec: PROJ.4 specification. (default: 'proj=eqc')
    #   want_lat_lon: Want latitude and longitude as coordinate variables of result? (default: 0)
    #   nx: Number of output columns (default: no. input columns)
    #	s: shoreline value. No shorelines if s is {} (empty vector). (default: missing value)
    #	min_area: Exclude shoreline polygons whose area (square km) < min_area (default: 0)
    #	resolution: required shoreline accuracy (km). (default: mean input latitude step)
    #	data_dir: directory containing GSHHS files. (default: "''")
    #   lat_min: minimum latitude in result
    #   lat_max: maximum latitude in result
    #   lon_min: minimum longitude in result
    #   lon_max: maximum longitude in result

    proc proj4gshhs {
	in
	{projection_spec ''}
	{want_lat_lon 0}
	{nx 0}
	{s _}
	{min_area 0}
	{resolution -1}
	{data_dir "''"}
	{lat_min ""}
	{lat_max ""}
	{lon_min ""}
	{lon_max ""}
    } {
	set proc_name proj4gshhs
	nap "sv = s"
	if {[$sv rank] != 0  &&  [$sv nels] > 0} {
	    error "$proc_name: argument s is neither scalar nor empty"
	}
	nap "lat_in = coordinate_variable(in,0)"
	nap "lon_in = fix_longitude(coordinate_variable(in,1))"
	set lat_ascending [[nap "lat_in(-1) > lat_in(0)"]]
	nap "nx = nx > 0 ? nx : nels(lon_in)"
	if {[[nap "resolution"]] < 0} {
	    nap "mean_lat_step = abs(lat_in(-1) - lat_in(0)) / (nels(lat_in) - 1.0)"
	    nap "resolution = mean_lat_step * 111.045"; # convert to km
	}
	if {$lat_min eq ""} {
	    nap "lat_min = min(lat_in)"
	}
	if {$lat_max eq ""} {
	    nap "lat_max = max(lat_in)"
	}
	if {$lon_min eq ""} {
	    nap "lon_min = min(lon_in)"
	}
	if {$lon_max eq ""} {
	    nap "lon_max = max(lon_in)"
	}
	set lon_mid [[nap "lon_min + 180"]]
	nap "spec = projection_spec"
	if {[$spec nels] == 0} {
	    nap "spec = 'proj=eqc'"
	}
	nap "spec = spec // ' lon_0=$lon_mid'"
	nap "lon = nx ... lon_min .. lon_max"
	if {$lat_ascending} {
	    nap "lat = lat_min .. lat_max ... lon(1) - lon(0)"
	} else {
	    nap "lat = lat_max .. lat_min ... lon(0) - lon(1)"
	}
	nap "zin = in(@lat, @lon)"
	nap "lat = coordinate_variable(zin,0)"
	nap "lon = coordinate_variable(zin,1)"
	nap "nlat = nels(lat)"
	nap "nlon = nels(lon)"
	nap "latmat = reshape(nlon # lat, nlat // nlon)"
	$latmat set coo lat lon
	nap "xy = cart_proj_fwd(spec, latmat, lon)"
	nap "x = xy(,,0)"
	nap "y = xy(,,1)"
	nap "xmin = min(min(x))"
	nap "xmax = max(max(x))"
	nap "ymin = min(min(y))"
	nap "ymax = max(max(y))"
	nap "xcv = nx ... xmin .. xmax"
	if {$lat_ascending} {
	    nap "ycv = ymin .. ymax ... xcv(1) - xcv(0)"
	} else {
	    nap "ycv = ymax .. ymin ... xcv(0) - xcv(1)"
	}
	$xcv set unit metres
	$ycv set unit metres
	nap "nx = nels(xcv)"
	nap "ny = nels(ycv)"
	nap "ymat = reshape(nx # ycv, ny // nx)"
	nap "latlon = cart_proj_inv(spec, xcv, ymat)"
	nap "result = zin(@latlon)"
	$result set dim northing easting
	$result set coo ycv xcv
	nap "tmp = latlon(,,0)"
	nap "latmin = min(min(tmp))"
	nap "latmax = max(max(tmp))"
	nap "tmp = (latlon(,,1) - lon_min) % 360.0 + lon_min"
	nap "lonmin = min(min(tmp))"
	nap "lonmax = max(max(tmp))"
	unset tmp
	if {[$sv rank] == 0} {
	    nap "lon_lat = get_gshhs(resolution, min_area, lonmin, lonmax,
		    latmin, latmax, data_dir)"
	    while {$lon_lat ne "(NULL)"} {
		nap "xy = cart_proj_fwd(spec, lon_lat(1,), lon_lat(0,))"
		nap "i = ycv @ xy(,1)"
		nap "j = xcv @ xy(,0)"
		nap "ok = i >= 0  &&  i <= ny-1  &&  j >= 0  &&  j <= nx-1"
		nap "poly = ok # ^j  ///  ok # ^i"
		$result draw poly sv
		set lon_lat [$lon_lat link]
		if {$lon_lat ne "(NULL)"} {
		    nap "lon_lat = $lon_lat"
		}
	    }
	}
	if {[[nap "want_lat_lon"]]} {
	    nap "latitude  = (cart_proj_inv(spec, 0.0, ycv))(,0)"
	    nap "longitude = (cart_proj_inv(spec, xcv, 0.0))(,1)"
	    $result set dim latitude longitude
	    $result set coo latitude longitude
	}
	nap "result"
    }

}
