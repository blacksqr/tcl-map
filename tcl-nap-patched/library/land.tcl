# land.tcl --
# 
# Copyright (c) 2002, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: land.tcl,v 1.9 2007/03/30 09:29:17 dav480 Exp $

namespace eval ::NAP {


    # is_land --
    #
    #	Produce i8 (8-bit signed integer) matrix with 1 for land and 0 for sea.
    #
    #   If latitude & longitude arguments are either both vectors (rank = 1) or one is a vector
    #   & other is a scalar (rank = 0) then they are used as the coordinate variables of the
    #   matrix (rank = 2) result. Otherwise the result has the same shape & coordinate variables
    #   as the one of higher rank.

    proc is_land {
	latitude
	longitude
	{data_dir "''"}
    } {
	if {[[nap "nels(data_dir) == 0"]]} {
	    if {[info exists ::env(LAND_FLAG_DATA_DIR)]} {
		nap "data_dir = '$::env(LAND_FLAG_DATA_DIR)'"
	    } else {
		nap "data_dir = '[file join $::nap_library data land_flag]'"
	    }
	}
	nap "err = 0"
	nap "maxlen = 100"
	nap "msg = reshape(' ', maxlen)"
	nap "lat = +f32(latitude)"
	nap "lon = +f32(longitude)"
	nap "slat = shape(lat)"
	nap "slon = shape(lon)"
	set rlat [$lat rank]
	set rlon [$lon rank]
	set rmax [expr $rlat > $rlon ? $rlat : $rlon]
	if {$rmax == 1} {
	    nap "lat = reshape(lat)"
	    nap "lon = reshape(lon)"
	    $lat set unit degrees_north
	    $lon set unit degrees_east
	    nap "nx = nels(lon)"
	    nap "ny = nels(lat)"
	    nap "result = reshape(0i8, ny // nx)"
	    $result set dim latitude longitude
	    $result set coo lat lon
	    nap "lat = transpose(reshape(lat <<< 89.9f32 >>> -89.9f32, nx // ny))"
	    nap "lon = reshape((lon + 180f32) % 360f32 - 180f32,       ny // nx)"
	    nap_land_flag data_dir ny nx lat lon result err msg maxlen
	} else {
	    nap "lat = lat <<< 89.9f32 >>> -89.9f32"
	    nap "lon = (lon + 180f32) % 360f32 - 180f32"
	    if {$rlat < $rmax} {
		if {[[nap "prod(slat == slon((-rlat) .. -1 ... 1))"]]} {
		    nap "lat = reshape(lat, slon)"
		    eval $lat set dim [$longitude dim]
		    eval $lat set coo [$longitude coo]
		} else {
		    error "latitude & longitude have incompatible shapes"
		}
	    }
	    if {$rlon < $rmax} {
		if {[[nap "prod(slon == slat((-rlon) .. -1 ... 1))"]]} {
		    nap "lon = reshape(lon, slat)"
		} else {
		    error "latitude & longitude have incompatible shapes"
		}
	    }
	    nap "present_lat = isPresent(lat)"
	    nap "present_lon = isPresent(lon)"
	    nap "lat = present_lat ? lat : 0.0f32"
	    nap "lon = present_lon ? lon : 0.0f32"
	    nap "result = reshape(0i8, shape(lat))"
	    eval $result set dim [$lat dim]
	    eval $result set coo [$lat coo]
	    nap_land_flag data_dir 1 nels(lat) lat lon result err msg maxlen
	    nap "result = present_lat && present_lon ? result : _"
	}
	if [[nap "err"]] {
	    error "[$msg]"
	}
	nap "result"
    }


    # fraction_land --
    #
    # Fraction of land in each cell.
    #
    # Cells are defined by functions 'merid_bounds' and 'zone_bounds'.
    # Use function 'is_land' to test nlat*nlon points within each cell.
    # Minimum resolution is 0.01 degrees even if specified nlat or nlon would give less.
    # nlat & nlon are automatically reduced if their specified value would give a resolution
    # of less than 0.01 degrees.

    proc fraction_land {
	latitude
	longitude
	{nlat 8}
	{nlon nlat}
	{data_dir "''"}
	{min_res 0.01}
    } {
	nap "lat = + latitude"
	nap "lon = + longitude"
	$lat set unit degrees_north
	$lon set unit degrees_east
	nap "latb = zone_bounds(lat)"
	nap "lonb = merid_bounds(lon)"
	nap "nlatb = nels(latb)"
	nap "nlonb = nels(lonb)"
	nap "nlat = i32(abs(lat(-1) - lat(0)) / (nels(lat) - 1) / min_res >>> 1 <<< nlat)"
	nap "nlon = i32(abs(lon(-1) - lon(0)) / (nels(lon) - 1) / min_res >>> 1 <<< nlon)"
	nap "dlat = 1f32 / nlat";  # step size of index AP
	nap "dlon = 1f32 / nlon";  # step size of index AP
	nap "fine_lat = latb((nlatb-1)/dlat ... dlat/2 ..  nlatb-1-dlat/2)"
	nap "fine_lon = lonb((nlonb-1)/dlon ... dlon/2 ..  nlonb-1-dlon/2)"
	nap "isLand = is_land(fine_lat, fine_lon, data_dir)"
	nap "n = nlat // nlon"
	nap "result = f32(moving_average(isLand, n, n))"
	$result set dim latitude longitude
	$result set coo lat lon
	nap "result"
    }


    # is_coast --
    #
    #	Produce i8 (8-bit signed integer) matrix with 1 for coast and 0 otherwise.
    #	The arguments (latitude & longitude) are used to define the coordinate variables of the
    #	result.

    proc is_coast {
	latitude
	longitude
	{nlat 8}
	{nlon nlat}
	{data_dir "''"}
    } {
	if {[$latitude rank] == 1  &&  [$longitude rank] == 1} {
	    nap "lat = +f32(latitude)"
	    nap "lon = +f32(longitude)"
	    $lat set unit degrees_north
	    $lon set unit degrees_east
	    nap "lat2 = (lat(0) + lat(0) - lat(1)) // lat // (lat(-1) + lat(-1) - lat(-2))"
	    nap "lon2 = (lon(0) + lon(0) - lon(1)) // lon // (lon(-1) + lon(-1) - lon(-2))"
	    nap "land = fraction_land(lat2, lon2, nlat, nlon, data_dir) > 0.5f32"
	    nap "se = {{0 1 0}{1 0 1}{0 1 0}}"
	    nap "result = (land && !erode(land, se, {1 1}))(1 .. nels(lat), 1 .. nels(lon))"
	    $result set dim latitude longitude
	    $result set coo lat lon
	} else {
	    nap "isLand = is_land(latitude, longitude, data_dir)"
	    nap "s = shape(isLand)"
	    nap "i1 = s(0) - 1"
	    nap "j1 = s(1) - 1"
	    nap "north = isLand(0 // 0 .. i1-1,)"
	    nap "south = isLand(1 .. i1 // i1,)"
	    nap "west  = isLand(, 0 // 0 .. j1-1)"
	    nap "east  = isLand(, 1 .. j1 // j1)"
	    nap "result = isLand && !(north && south && west && east)"
	}
	nap "result"
    }


}
