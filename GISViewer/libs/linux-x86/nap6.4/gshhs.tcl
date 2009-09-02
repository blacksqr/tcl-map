# gshhs.tcl --
# 
# GSHHS = 'Global Self-consistent Hierarchical High-resolution Shorelines'
# http://www.ngdc.noaa.gov/mgg/shorelines/gshhs.html
#
# Copyright (c) 2006, CSIRO Australia
# Author: Harvey Davies, CSIRO Marine and Atmospheric Research
# $Id: gshhs.tcl,v 1.22 2007/11/10 04:27:10 dav480 Exp $

namespace eval ::NAP {

    namespace export choose_gshhs_file dmp_gshhs list_gshhs_resolutions

    # choose_gshhs_file --
    #
    # Return path of chosen GSHHS file
    # Called by dmp_gshhs & get_gshhs (see below)

    proc choose_gshhs_file {
	{resolution 1}
	{data_dir "''"}
    } {
	set proc_name choose_gshhs_file
	set resolution [[nap "resolution"]]
	set data_dir [[nap "$data_dir"]]
	if {$data_dir eq ""} {
	    if {[info exists ::env(GSHHS_DATA_DIR)]} {
		set data_dir $::env(GSHHS_DATA_DIR)
	    } else {
		set data_dir [file join $::nap_library data gshhs]
	    }
	}
	set old_dir [pwd]
	cd $data_dir 
	set files [glob -nocomplain gshhs_?.b]
	if {$files eq ""} {
	    error "$proc_name: no files matching gshhs_?.b in directory $data_dir"
	}
	set tol(gshhs_f.b)  0
	set tol(gshhs_h.b)  0.2
	set tol(gshhs_i.b)  1
	set tol(gshhs_l.b)  5
	set tol(gshhs_c.b) 25
	set chosen_file gshhs_f.b
	foreach file $files {
	    if {$tol($file) <= $resolution  &&  $tol($file) > $tol($chosen_file)} {
		set chosen_file $file
	    }
	}
	if {![file readable $chosen_file]} {
	    error "$proc_name: cannot read file $chosen_file in directory $data_dir"
	}
	cd $old_dir 
	return [file join $data_dir $chosen_file]
    }

    # dmp_gshhs --
    #
    # Dump gshhs data file
    #
    # nrecords_max is max. no. records to dump. Default: -1 (all).
    #
    # npoints_max is max. no. points (in each record) to print.
    # If too many points then print 1st & last (npoints_max+1)/2 points
    # Default: -1 (all).  Value of -2 means print only record count.

    proc dmp_gshhs {
	{nrecords_max -1}
	{npoints_max -1}
	{out_file_name ""}
	{resolution 25}
	{min_area -1}
	{min_longitude 0}
	{max_longitude "min_longitude + 360.0"}
	{min_latitude -90}
	{max_latitude  90}
	{data_dir "''"}
    } {
	set proc_name dmp_gshhs
	if {$nrecords_max < 0} {
	    set nrecords_max [expr {~(1<<31)}]
	}
	set filename [choose_gshhs_file $resolution $data_dir]
	set channelId [open $filename]
	if {$out_file_name eq ""} {
	    set fout stdout
	} else {
	    set fout [open $out_file_name w]
	}
	puts $fout "GSHHS File $filename"
	nap "i0 = 0 .. (npoints_max-1)/2"
	nap "i1 = -(npoints_max+1)/2  .. -1"
	set id -1
	nap "min_area = min_area < 0 ? 0.25 * resolution ** 2 : min_area"
	nap "a = '$channelId', min_area, min_longitude, max_longitude, min_latitude, max_latitude"
	while {$id + 1 < $nrecords_max  &&  [[nap "in = read_gshhs(a)"] nels]} {
	    set id    [[nap "open_box(in 0)"]]
	    set area  [[nap "open_box(in 1)"] -f %.1f]
	    set level [[nap "open_box(in 2)"]]
	    set west  [[nap "open_box(in 3)"] -f %.6f]
	    set east  [[nap "open_box(in 4)"] -f %.6f]
	    set south [[nap "open_box(in 5)"] -f %.6f]
	    set north [[nap "open_box(in 6)"] -f %.6f]
	    nap "lat = open_box(in 10)"
	    nap "lon = open_box(in 11)"
	    if {$npoints_max > -2} {
		set npoints [$lat nels]
		puts $fout ""
		puts $fout "record $id, $npoints points, level=$level, area=$area km^2"
		puts $fout "west=$west east=$east south=$south north=$north"
		if {$npoints_max < 0  ||  $npoints <= $npoints_max} {
		    puts $fout "[$lat v -f %.6f]"
		    puts $fout "[$lon v -f %.6f]"
		} elseif {$npoints_max > 0} {
		    puts $fout "start:"
		    puts $fout "[[nap "lat(i0)"] v -f %.6f]"
		    puts $fout "[[nap "lon(i0)"] v -f %.6f]"
		    puts $fout "end:"
		    puts $fout "[[nap "lat(i1)"] v -f %.6f]"
		    puts $fout "[[nap "lon(i1)"] v -f %.6f]"
		}
	    }
	}
	close $channelId
	incr id
	puts $fout "$id records read"
	if {$fout ne "stdout"} {
	    close $fout
	}
    }

    # get_gshhs --
    #
    # NAP function to read GSHHS shoreline data.
    #
    # Result is linked list of f64 matrices with two rows.
    # Row 0 contains longitudes.
    # Row 1 contains latitudes.
    #
    # Usage
    #    get_gshhs(resolution, min_area, min_longitude, max_longitude,
    #	     min_latitude, max_latitude, data_dir)
    # where
    # resolution: required accuracy (km). This determines which file is used. (default: 1)
    #
    # min_area: scalar or vector with up to 4 elements. Default is "{-1 -1 -1 -1}".
    # If there are less than 4 elements then the final element is repeated to give 4.
    # The four elements respectively specify the minimum area (square km) of:
    # 0: land with sea boundary,
    # 1: lake (including inland sea),
    # 2: island in lake,
    # 3: pond in island in lake
    # A value of -1 is treated as 0.25 * resolution**2
    #
    # min_longitude: left boundary of region (default: -180)
    #
    # max_longitude: right boundary of region (default: "min_longitude + 360.0")
    #
    # min_latitude: bottom boundary of region (default: -90)
    #
    # max_latitude: top boundary of region (default: 90)
    #
    # data_dir: directory containing GSHHS files with various resolutions. The default is
    #     $::nap_library/data/gshhs unless environment variable GSHHS_DATA_DIR is
    #     defined to overide this.

    proc get_gshhs {
	{resolution 1}
	{min_area -1}
	{min_longitude 0}
	{max_longitude "min_longitude + 360.0"}
	{min_latitude -90}
	{max_latitude  90}
	{data_dir "''"}
    } {
	set proc_name get_gshhs
	nap "min_area = reshape(min_area)"
	nap "min_area = min_area < 0 ? 0.25 * resolution ** 2 : min_area"
	nap "xmin = f64(min_longitude)"
	nap "xmax = f64(max_longitude)"
	nap "ymin = f64(min_latitude)"
	nap "ymax = f64(max_latitude)"
	set file_path [choose_gshhs_file $resolution $data_dir]
	set channelId [open $file_path]
	nap "b = emptyBoxedVector = (,){}"
	nap "old = start = reshape(0.0, {2 0})"
	nap "d360 = 360.0"
	nap "d180 = 180.0"
	nap "xmid = xmin + d180"
	nap "rectangle = (xmin // ymin) /// (xmax // ymax)"
	nap "a = '$channelId', min_area, xmin, xmax, ymin, ymax"
	while {[[nap "in = read_gshhs(a)"] nels]} {
	    nap "west  = open_box(in 3)"
	    nap "east  = open_box(in 4)"
	    nap "south = open_box(in 5)"
	    nap "north = open_box(in 6)"
	    nap "y     = open_box(in 10)"
	    nap "x     = open_box(in 11)"
	    nap "i1 = 0 .. nels(x)-1 ... 1"
	    nap "i2 = 0 .. nels(x)-2 ... 1"
	    nap "wrap = (abs(x(i2+1) - x(i2)) > d180) // 1"
	    nap "i = wrap # i1"
	    set ni [$i nels]
	    nap "ij1 = 0"
	    for {set j 0} {$j < $ni} {incr j} {
		nap "ij = i(j)"
		nap "i0 = ij1 .. ij ... 1"
		nap "ij1 = ij + 1"
		nap "xv = x(i0)"
		nap "yv = y(i0)"
		nap "x1 = x(ij1) + d360 * sign(xmid - x(ij))"
		$x set value x1 ij1
		nap "xregion = (xv > xmax) - (xv < xmin)"
		nap "yregion = (yv > ymax) - (yv < ymin)"
		nap "inside = 0 // (xregion == 0  &&  yregion == 0) // 0"
		nap "xv = xv(0) // xv // xv(-1)"
		nap "yv = yv(0) // yv // yv(-1)"
		nap "k = 1 .. nels(xv) ... 1"
		nap "from = (!inside(k-1)  &&  inside(k)) # k"
		nap "to   = (inside(k)  &&  !inside(k+1)) # k"
		set ns [$from nels]
		for {set s 0} {$s < $ns} {incr s} {
		    nap "fs = from(s)"
		    nap "ts = to(s)"
		    nap "ss = fs .. ts ... 1"
		    nap "xxv = xv(ss)"
		    nap "yyv = yv(ss)"
		    nap "line = (xv(fs-1) // yv(fs-1)) /// (xxv(0) // yyv(0))"
		    nap "line0 = clip2d(rectangle, line)"
		    nap "line = (xxv(-1) // yyv(-1)) /// (xv(ts+1) // yv(ts+1))"
		    nap "line1 = clip2d(rectangle, line)"
		    nap "polyline = transpose(line0 // transpose(xxv /// yyv) // line1)"
		    $polyline set unit degrees
		    $old set link $polyline
		    nap "old = polyline"
		}
	    }
	}
	close $channelId
	nap "start"
    }

    # list_gshhs_resolutions --
    #
    # Return sorted list of resolutions (km) corresponding to the GSHHS data files

    proc list_gshhs_resolutions {
	{data_dir "''"}
    } {
	set proc_name list_gshhs_resolutions 
	set data_dir [[nap "$data_dir"]]
	if {$data_dir eq ""} {
	    if {[info exists ::env(GSHHS_DATA_DIR)]} {
		set data_dir $::env(GSHHS_DATA_DIR)
	    } else {
		set data_dir [file join $::nap_library data gshhs]
	    }
	}
	set old_dir [pwd]
	cd $data_dir 
	set files [glob -nocomplain gshhs_?.b]
	if {$files eq ""} {
	    error "$proc_name: no files matching gshhs_?.b in directory $data_dir"
	}
	set tol(gshhs_f.b)  0
	set tol(gshhs_h.b)  0.2
	set tol(gshhs_i.b)  1
	set tol(gshhs_l.b)  5
	set tol(gshhs_c.b) 25
	foreach file $files {
	    lappend result $tol($file)
	}
	cd $old_dir 
	return [lsort -real $result]
    }

    # read_gshhs --
    #
    # NAP function to read next record of GSHHS shoreline data which satifies specified
    # conditions.
    #
    # min_area: scalar or vector with up to 4 elements. Default is "{0 0 0 0}".
    # If there are less than 4 elements then the final element is repeated to give 4.
    # The four elements respectively specify the minimum area (square km) of:
    # 0: land with sea boundary,
    # 1: lake (including inland sea),
    # 2: island in lake,
    # 3: pond in island in lake
    #
    # min_longitude: left boundary of region (default: -180)
    #
    # max_longitude: right boundary of region (default: "min_longitude + 360.0")
    #
    # min_latitude: bottom boundary of region (default: -90)
    #
    # max_latitude: top boundary of region (default: 90)
    #
    # Return boxed NAO.
    #
    # For normal record this contains following:
    # id, area, level, west, east, south, north, version, greenwich, source, lat, lon
    #
    # At end of file the boxed NAO is empty.

    proc read_gshhs {
	channelId
	{min_area 0}
	{min_longitude 0}
	{max_longitude "min_longitude + 360.0"}
	{min_latitude -90}
	{max_latitude  90}
    } {
	set proc_name read_gshhs
	nap "min_area = reshape(min_area)"
	nap "min_area = min_area // 3 # min_area(-1)"
	nap "lon_min = f64(min_longitude)"
	nap "lon_max = f64(max_longitude)"
	nap "lat_min = f64(min_latitude)"
	nap "lat_max = f64(max_latitude)"
	set lon_min_non0 [[nap "lon_min != 0"]]
	set method [byte_order_mode bigEndian]
	set f [[nap "channelId"]]
	nap "v1 = {1}"
	nap "mil = 1e-6"
	nap "tenth = 0.1"
	nap "d360 = 360.0"
	set match 0
	set at_eof 0
	while {!$match && !$at_eof} {
	    nap "id = [nap_get $method $f i32 $v1]"
	    set at_eof [expr {[$id nels] == 0}]
	    if {$at_eof} {
		nap "b = (,){}"; # empty boxed vector (for eof)
	    } else {
		nap "npoints = [nap_get $method $f i32 $v1]"
		nap "level   = [nap_get $method $f i32 $v1]"
		nap "west    = [nap_get $method $f i32 $v1] * mil"
		nap "east    = [nap_get $method $f i32 $v1] * mil"
		nap "south   = [nap_get $method $f i32 $v1] * mil"
		nap "north   = [nap_get $method $f i32 $v1] * mil"
		nap "area    = [nap_get $method $f i32 $v1] * tenth"
		if {$lon_min_non0} {
		    nap "west = (west - lon_min) % d360 + lon_min"
		    nap "east = (east - lon_min) % d360 + lon_min"
		}
		set match [[nap "area >= min_area(level-1)
			    &&  east  >= lon_min  &&  west  <= lon_max
			    &&  north >= lat_min  &&  south <= lat_max"]]
		if {$match} {
		    nap "version   = [nap_get $method $f i32 $v1]"
		    nap "greenwich = [nap_get $method $f i16 $v1]"
		    nap "source    = [nap_get $method $f i16 $v1]"
		    nap "lon_lat   = [nap_get $method $f i32 "npoints // 2"] * mil"
		    if {$lon_min_non0} {
			nap "lon = (lon_lat(,0) - lon_min) % d360 + lon_min"
		    } else {
			nap "lon = lon_lat(,0)"
		    }
		    nap "lat = lon_lat(,1)"
		    nap "b = id, area, level, west, east, south, north,
			    version, greenwich, source, lat, lon"
		} else {
		    seek $f [[nap "8 + 8 * npoints"]] current; # skip rest of record
		}
	    }
	}
	nap "b"
    }

}
