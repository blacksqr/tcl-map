# bin_io.tcl --
#
# Binary input/output procedures oriented to Fortran unformatted IEEE files.
#
# Copyright (c) 1998, CSIRO Australia
# Author: Harvey Davies, CSIRO.
# $Id: bin_io.tcl,v 1.24 2007/11/09 04:04:42 dav480 Exp $


# byte_order_mode
#
# Result is "binary" or "swap"
#
# Argument has value "auto", "bigEndian", "binary", "littleEndian" or "swap"
# These can be abbreviated to unique prefix
# Note that "auto" is treated as "bigEndian" for historic reasons 

proc byte_order_mode {
    mode
} {
    switch -glob $mode {
	a*	{set mode bigEndian}
	big*	{set mode bigEndian}
	bin*	{return binary}
	l*	{set mode littleEndian}
	s*	{return swap}
	default	{error {byte_order_mode: illegal argument} }
    }
    if {$mode eq $::tcl_platform(byteOrder)} {
	return binary
    }
    return swap
}


# check --
#
# Check for error condition
#
# Usage
#   check <ok> <message>
#	<ok> is expr expression to be evaluated in caller name-space

proc check {
    ok
    message
} {
    if [uplevel expr !($ok)] {
	error $message
    }
    return
}


# size_of --
#
# Number of bytes in  <dataType>
#
# Usage
#   size_of <dataType>
#	<dataType> c8, u8, u16, u32,  i8, i16, i32, f32 or f64

proc size_of {
    dataType
} {
    switch -regexp $dataType {
	{^.8$}		{return 1}
	{^.16$}		{return 2}
	{^.32$}		{return 4}
	{^.64$}		{return 8}
	default		{error "size_of: Illegal dataType"}
    }
}


# get_bin --
#
# Read next binary record.
# If end of file then return empty vector.
# Otherwise return a vector of specified data type.
#
# Usage
#   get_bin <dataType> ?<fileId>? ?<mode>?
#	<dataType> c8, u8, u16, u32,  i8, i16, i32, f32 or f64
#	<fileId> defaults to "stdin"
#	<mode> is "binary" (default) or "swap"

proc get_bin {
    dataType
    {fileId stdin}
    {mode binary}
} {
    nap "nbytes1 = [nap_get $mode $fileId i32 1]"
    if {[$nbytes1 nels] == 1} {
	set result [nap_get $mode $fileId $dataType "nbytes1/[size_of $dataType]"]
	check {![eof $fileId]} "get_bin: Premature end of file"
	nap "nbytes2 = [nap_get $mode $fileId i32 1]"
	check {![eof $fileId]} "get_bin: Premature end of file"
	check [[nap "nbytes1 == nbytes2"]] "get_bin: Unequal byte counts"
    } else {
	set result [nap "{}"]
    }
    return $result
}


# put_bin --
#
# Write binary record
#
# Usage
#   put_bin <nap_expr> ?<fileId>? ?<mode>?
#	<nap_expr> is NAP expression to be evaluated in caller name-space
#	<fileId> defaults to "stdout"
#	<mode> is "binary" (default) or "swap"

proc put_bin {
    nap_expr
    {fileId stdout}
    {mode binary}
} {
    nap "nao = [uplevel "nap \"$nap_expr\""]"
    nap "nbytes = i32([size_of [$nao datatype]] * nels(nao))"
    $nbytes $mode $fileId
    $nao    $mode $fileId
    $nbytes $mode $fileId
    return
}


# get_cif1 --
#
# Read a matrix from cif (Conmap Input File) & return as NAO.
#
# Usage
#   get_cif1 ?<options>? <fileId>
#	<fileId>: defaults to stdin
#	Options
#	    -g 0|1: 1 (default) for geographic mode, 0 for non-geographic mode
#	    -m <real>: Input missing value (default: -7777777.0)
#	    -s 0|1: 0 (default) for binary mode, 1 for swap (byte swapping) mode.
#	    -um <text>: Units for matrix (default: none)
#	    -ux <text>: Units for x (default: if geographic mode then degrees_east, else none)
#	    -uy <text>: Units for y (default: if geographic mode then degrees_north, else none)
#	    -x <text>: Name of dimension x (default: if geographic mode then longitude else x)
#	    -y <text>: Name of dimension y (default: if geographic mode then latitude else x)
#
# If end of file then return empty vector.

proc get_cif1 {
    args
} {
    set swap_mode 0
    set is_geog 1
    set missing_value -7777777
    set name_x ""
    set name_y ""
    set unit_m (NULL)
    set unit_x (NULL)
    set unit_y (NULL)
    set options {
	{-g {set is_geog $option_value}}
	{-m {set missing_value $option_value}}
	{-s {set swap_mode $option_value}}
	{-um {set unit_m $option_value}}
	{-ux {set unit_x $option_value}}
	{-uy {set unit_y $option_value}}
	{-x {set name_x $option_value}}
	{-y {set name_y $option_value}}
    }
    set i [process_options $options $args]
    set rest [lrange $args $i end]
    check "[llength $rest] <= 1" "get_cif1: Illegal argument"
    if {[llength $rest] > 0} {
	set fileId $rest
    } else {
	set fileId stdin
    }
    if {$swap_mode} {
	set mode swap
    } else {
	set mode binary
    }
    if {$is_geog} {
	default name_x longitude
	default name_y latitude
	if {[string equal $unit_x (NULL)]} {
	    set unit_x degrees_east
	}
	if {[string equal $unit_y (NULL)]} {
	    set unit_y degrees_north
	}
    } else {
	default name_x x
	default name_y y
    }
    nap "ny = [get_bin i32 $fileId $mode]"
    if {[$ny nels] > 0} {
	nap "y  = [get_bin f32 $fileId $mode]"
	check [[nap "ny == nels(y)"]] "get_cif1: ny != nels(y)"
	$y set unit $unit_y
	nap "nx = [get_bin i32 $fileId $mode]"
	nap "x  = [get_bin f32 $fileId $mode]"
	check [[nap "nx == nels(x)"]] "get_cif1: nx != nels(x)"
	if {$name_x == "longitude"} {
	    nap "x = fix_longitude(x)"
	}
	$x set unit $unit_x
	nap "title = [get_bin c8 $fileId $mode]"
	nap "vec = [get_bin f32 $fileId $mode]"
	nap "mv = 0.9999f32 * f32(missing_value)"
	if [[nap "isnan(mv)"]] {
	    nap "is_missing = isnan(vec)"
	} elseif [[nap "mv < 0.0f32"]] {
	    nap "is_missing = vec < mv"
	} elseif [[nap "mv > 0.0f32"]] {
	    nap "is_missing = vec > mv"
	} else {
	    nap "is_missing = vec == mv"
	}
	nap "i = is_missing # (0 .. (nels(vec) - 1))"	;# indices of missing values
	$vec set value "" $i				;# set missing values to NaN
	set m [nap "reshape(vec, ny // nx)"]
	$m set count +1
	$m set coord y x
	set label [string trim [$title value]]
	if {"$label" != ""} {
	    $m set label $label
	}
	$m set unit $unit_m
	$m set dim $name_y $name_x
	$m set count 0 -keep
    } else {
	set m [nap "{}"]
    }
    return $m
}


# get_cif --
#
# Read one or more matrices from one or more cif (Conmap Input File) files (specified
# by one or more glob patterns).
# Result is 2D or 3D NAO.
# Check whether byte swapping is needed by examining 1st word in file.
#
# Usage
#   get_cif ?<options>? <file> <file> <file> ...
#	Options
#	    -g 0|1: 1 (default) for geographic mode, 0 for non-geographic mode
#	    -m <real>: Input missing value (default: -7777777.0)
#	    -um <text>: Units for matrix (default: none)
#	    -ux <text>: Units for x (default: if geographic mode then degrees_east, else none)
#	    -uy <text>: Units for y (default: if geographic mode then degrees_north, else none)
#	    -x <text>: Name of dimension x (default: if geographic mode then longitude else x)
#	    -y <text>: Name of dimension y (default: if geographic mode then latitude else x)
#
# Example reading from file abc.cif with NaN as missing value.
#   nap "in = [get_cif -m 1nf32 abc.cif]"

proc get_cif {
    args
} {
    set is_geog 1
    set missing_value -7777777
    set name_x ""
    set name_y ""
    set unit_m (NULL)
    set unit_x (NULL)
    set unit_y (NULL)
    set options {
	{-g {set is_geog $option_value}}
	{-m {set missing_value $option_value}}
	{-um {set unit_m $option_value}}
	{-ux {set unit_x $option_value}}
	{-uy {set unit_y $option_value}}
	{-x {set name_x $option_value}}
	{-y {set name_y $option_value}}
    }
    set i [process_options $options $args]
    set rest [lrange $args $i end]
    if {$is_geog} {
	default name_x longitude
	default name_y latitude
	if {[string equal $unit_x (NULL)]} {
	    set unit_x degrees_east
	}
	if {[string equal $unit_y (NULL)]} {
	    set unit_y degrees_north
	}
    } else {
	default name_x x
	default name_y y
    }
    nap "result = {}"
    set fileNames [eval glob $rest]
    foreach fileName $fileNames {
	if [catch {set fileId [open $fileName]} message] {
	    error $message
	}
	if [catch {nap "i = [nap_get binary $fileId i32 "{1}"]"} message] {
	    error $message
	}
	set swap_mode [[nap "i != 4"]]
	if [catch {seek $fileId 0} message] {
	    error $message
	}
	set end_of_file 0
	while {!$end_of_file} {
	    nap "mat = [get_cif1 \
		    -g $is_geog \
		    -m $missing_value \
		    -s $swap_mode \
		    -um $unit_m \
		    -ux $unit_x \
		    -uy $unit_y \
		    -x  $name_x \
		    -y  $name_y \
		    $fileId]"
	    set end_of_file [eof $fileId]
	    if {!$end_of_file} {
		if {[$result nels] == 0} {
		    nap "result = mat"
		    nap "x = coordinate_variable(mat,1)"
		    nap "y = coordinate_variable(mat,0)"
		    nap "nx = nels(x)"
		    nap "ny = nels(y)"
		} else {
		    nap "s = shape(mat)"
		    if {[[nap "s(0) == ny  &&  s(1) == nx"]]} {
			if {[$result rank] == 2} {
			    nap "result = result /// mat"
			} else {
			    nap "result = result // mat"
			}
		    } else {
			error "File $fileName has shape which is incompatible with previous files"
		    }
		}
	    }
	}
	close $fileId
    }
    if {[$result rank] == 3} {
	nap "frame = 1 .. (shape(result))(0)"
	$result set coo frame y x
    }
    nap "+result"
}


# get_nao --
#
# Read NAO from (binary) nao file
#
# Usage
#   get_nao ?<fileName>? ?<datatype>? ?<shape>? ?<mode>?
#	<fileName> defaults to standard input
#       <datatype> is NAP datatype which can be: character, i8, i16, i32, u8,
#                  u16, u32, f32 or f64 (Default: u8)
#       <shape> is shape of result (Default: number of elements until end)
#	<mode> is "binary" (default) or "swap"

proc get_nao {
    {fileName ""}
    {datatype u8}
    {shape ""}
    {mode binary}
} {
    if {"$fileName" == ""} {
	set fileId stdin
    } else {
	if [catch {set fileId [open $fileName]} message] {
	    error $message
	}
    }
    set result [eval nap_get $mode $fileId $datatype $shape]
    close $fileId
    return $result
}


# put_cif1 --
#
# Write NAO to cif (Conmap Input File)
#
# Usage
#   put_cif1 <nap_expr> ?<fileId>? ?<mode>? ?<missing_value>?
#	<nap_expr> is NAP expression to be evaluated in caller name-space
#	<fileId> defaults to stdout
#	<mode> is "auto" (default) "binary" or "swap"
#	<missing_value> for output (default: -7777777)

proc put_cif1 {
    nap_expr
    {fileId stdout}
    {mode auto}
    {missing_value -7777777f32}
} {
    set mode [byte_order_mode $mode]
    nap "nao = [uplevel "nap \"f32($nap_expr)\""]"
    set rank [$nao rank]
    check {$rank == 2} "put_cif1: rank is $rank but should be 2"
    foreach dim {0 1} {
	nap "cv = f32(coordinate_variable(nao, dim))"
	nap "ne = i32(nels(cv))"
	put_bin $ne $fileId $mode
	put_bin $cv $fileId $mode
    }
    nap "label = reshape(label(nao) // (80 # ' '), {80})"
    put_bin $label $fileId $mode
    nap "nao = isPresent(nao) ? nao : f32(missing_value)"
    put_bin $nao   $fileId $mode
    return
}


# put_cif --
#
# Write NAO as entire cif (Conmap Input File)
#
# Usage
#   put_cif <nap_expr> ?<fileName>? ?<mode>? ?<missing_value>?
#	<nap_expr> is NAP expression to be evaluated in caller name-space
#	<fileName> defaults to standard output
#	<mode> is "auto" (default) "binary" or "swap"
#	<missing_value> for output (default: -7777777)

proc put_cif {
    nap_expr
    {fileName ""}
    {mode auto}
    {missing_value -7777777f32}
} {
    if {"$fileName" eq ""} {
	set fileId stdout
    } else {
	if [catch {set fileId [open $fileName w]} message] {
	    error $message
	}
    }
    nap "nao = [uplevel "nap \"f32($nap_expr)\""]"
    put_cif1 $nao $fileId $mode $missing_value
    close $fileId
    return
}


# put_nao --
#
# Write NAO to (binary) nao file
#
# Usage
#   put_nao <nap_expr> ?<fileName>? ?<mode>
#	<nap_expr> is NAP expression to be evaluated in caller name-space
#	<fileName> defaults to standard output
#	<mode> is "binary" (default) or "swap"

proc put_nao {
    nap_expr
    {fileName ""}
    {mode binary}
} {
    if {"$fileName" == ""} {
	set fileId stdout
    } else {
	if [catch {set fileId [open $fileName w]} message] {
	    error $message
	}
    }
    nap "nao = [uplevel "nap \"$nap_expr\""]"
    $nao $mode $fileId
    close $fileId
    return
}


# put16 --
#
# Write automatically-scaled 16-bit variable to netCDF or HDF file
#
# Usage
#   put16 <nap_expr> <fileName> <variableName>
#	<nap_expr> is NAP expression to be evaluated in caller name-space
#	<fileName> is name of netCDF (.nc) or HDF (.hdf) file
#	<variableName> is name of 16-bit variable/SDS

proc put16 {
    nap_expr
    fileName
    variableName
} {
    set ext [string tolower [file extension $fileName]]; # ".nc" or ".hdf"
    nap "nao = f32([uplevel "nap \"$nap_expr\""])"
    nap "r = range(nao)"
    nap "data_min = r(0)"
    nap "data_max = r(1)"
    set valid_min -32500f32
    set valid_max  32500f32
    nap "valid_min1 = valid_min + 1f32"; # allow for rounding error
    nap "valid_max1 = valid_max - 1f32"
    if [[nap "data_min < data_max"]] {
	nap "scale_factor = (data_max - data_min) / (valid_max1 - valid_min1)"
	if {$ext eq ".nc"} {
	    nap "add_offset = data_min - valid_min1 * scale_factor"
	} else {
	    nap "add_offset = valid_min1 - data_min / scale_factor"
	}
    } else {
	# This happens if all data has same value or is missing
	nap "scale_factor = 1f32"
	nap "add_offset = 0f32"
    }
    set method(.nc) netcdf
    set method(.hdf) hdf
    $nao $method($ext) $fileName $variableName -datatype i16 \
	    -range "valid_min // valid_max" \
	    -scale scale_factor -offset add_offset 
    return
}
