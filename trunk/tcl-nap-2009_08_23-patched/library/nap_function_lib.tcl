# nap_function_lib.tcl --
#
# Define various NAP functions
#
# Copyright (c) 2001, CSIRO Australia
# Author: Harvey Davies, CSIRO.
# $Id: nap_function_lib.tcl,v 1.55 2006/11/21 00:32:00 dav480 Exp $


namespace eval ::NAP {


    # ap --
    #
    # Arithmetic Progression
    #
    # If (to-from)/step is not integer value then round to nearest integer value

    proc ap {
	{from ""}
	{to ""}
	{step 1}
    } {
	if {$from == ""} {
	    nap "{}"
	} elseif {$to == ""} {
	    if {[$from rank] == 0} {
		nap "1 .. from"
	    } elseif {[$from nels] == 1} {
		nap "1 .. from(0)"
	    } else {
		nap "v = from // 1"
		nap "v(0) .. v(1) ... v(2)"
	    }
	} else {
	    if {[[nap "(to - from) % step != 0"]]} {
		nap "to = from + step * i32(nint(f64(to - from) / step))"
	    }
	    nap "from .. to ... step"
	}
    }


    # boxed2mask --
    #
    # Convert boxed polylines in some coordinate system to single matrix with coordinate
    # variables corresponding to that coordinate system
    #
    # Usage
    #   boxed2mask(x, y, b)
    #   where
    #	    x is desired coordinate variable in x direction
    #	    y is desired coordinate variable in y direction
    #	    b is a boxed vector pointing to boxed polylines in x,y coordinate system
    #
    # Example
    #   nap "longitude = -180 .. 180"
    #   nap "latitude  =  -90 .. 90"
    #   $longitude set unit degrees_east
    #   $latitude  set unit degrees_north
    #   nap "m = boxed2mask(longitude, latitude, get_gshhs(25))"
    #
    # Note that the fact that b is boxed means that x, y and b are merged into a single
    # argument 'args' which is Tcl list of OOC-names.

    proc boxed2mask {
	args
    } {
	set proc_name boxed2mask
	nap "x = [lindex $args 0]"
	if {[$x rank] != 1} {
	    error "$proc_name: argument x is not vector"
	}
	nap "y = [lindex $args 1]"
	if {[$y rank] != 1} {
	    error "$proc_name: argument y is not vector"
	}
	nap "result = reshape(0f32, nels(y) // nels(x))"
	$result set coord y x
	foreach arg $args {
	    switch [$arg rank] {
		1	{}
		2	{$result draw "x @@ arg(0,) /// y @@ arg(1,)" 1f32}
		default {error "$proc_name: argument b points to NAO with rank other than 1 or 2"}
	    }
	}
	nap "u8 result"
    }


    # color_wheel --
    #
    # nap function giving square containing color wheel.
    #
    # Usage
    #   color_wheel(size, value, background_rgb)
    #     where
    #	size is number of rows & columns (scalar integer)
    #	value is desired "value" level (scalar)
    #	background_rgb is colour outside circle (3-element vector in range 0 to 255)
    #
    # Example
    #   plot_nao "color_wheel(100, 255, 3 # 150)"
    #   This produces a u8 array with shape {3 100 100} with values from 0 to 255.
    #
    # Use coordinate system with x and y ranging from -1 to +1.
    # Circle has radius 1 and its centre is the origin.

    proc color_wheel {
	size value background_rgb
    } {
	nap "n = size - 1"
	nap "i = 0 .. n"
	nap "x = reshape(2f32 * i / n - 1f32, size // size)"
	nap "y = -transpose(x)"
	nap "h = 180p-1 * atan2(y, x)"
	nap "s = sqrt(x * x + y * y)"
	nap "v = reshape(f32(value), shape(h))"
	nap "hsv = h /// s // v"
	nap "s < 1f32 ? u8(hsv2rgb(hsv)) : transpose(reshape(u8(background_rgb), shape(h) // 3))"
    }


    # cpi --
    #
    # Nap function for cross-product indexing without the need to specify trailing
    # dimensions that are to be fully selected.
    # This is useful when the rank of the array can vary.
    #
    # Usage:
    #	cpi(array [,i [,j [,k ... ]]])
    #
    # Examples:
    #
    # % [nap "m = {{1 3 5}{6 8 9}}"]
    # 1 3 5
    # 6 8 9
    # % [nap "cpi(m, {1 0})"]
    # 6 8 9
    # 1 3 5
    # % [nap "cpi(m, 1, {2 0})"]
    # 9 6
    # % [nap "cpi(m, , 1)"]
    # 3 8
    # % [nap "cpi(m,0,)"]
    # 1 3 5
    # % [nap "cpi(m,0)"]
    # 1 3 5
    # % [nap "cpi(m)"]
    # 1 3 5
    # 6 8 9
    # % [nap "cpi(m,)"]
    # 1 3 5
    # 6 8 9
    # % [nap "cpi(m,,)"]
    # 1 3 5
    # 6 8 9

    proc cpi {
	array
	args
    } {
	nap "index = (,){}"; # empty boxed vector
	foreach i $args {
	    if {$i eq "NULL"} {
		nap "index = index ,"
	    } else {
		nap "index = index , i"
	    }
	}
	set n [$index nels]
	if {$n > 0} {
	    set nc [[nap "rank(array) - $n"]]; # number commas needed
	    nap "result = array(index [string repeat , $nc])"
	} else {
	    nap "result = array"
	}
	nap "result"
    }


    # cv --
    #
    # Alias for long word 'coordinate_variable'
    #
    # Usage:
    #	cv(x, d)
    # or
    #	cv(x)
    #
    # Examples (assuming matrix has dimensions 'latitude' & 'longitude'):
    #	cv(matrix, 'latitude'); # result is coordinate variable of dimension 0
    #	cv(matrix);             # result is coordinate variable of dimension 0
    #	cv(matrix,  1);         # result is coordinate variable of dimension 1
    #	cv(matrix, -1);         # result is coordinate variable of dimension 1

    proc cv {
	x
	{d 0}
    } {
	nap "coordinate_variable(x, d)"
    }


    # derivative --
    #
    # Estimate derivative along dimension 'd' (default is 0) of array 'a'.
    # Result has same shape as array.
    #
    # Usage:
    #	derivative(a, d)
    #
    # Example (assuming 'vector' has dimension (& coordinate variable) 'time'
    #	derivative(vector); # result is derivative with respect to time
    #
    # Examples (assuming 'matrix' has dimensions 'latitude' & 'longitude'):
    #	derivative(matrix, 'latitude');	# result is derivative with respect to latitude
    #	derivative(matrix, 0);		# result is derivative with respect to latitude
    #	derivative(matrix);		# result is derivative with respect to latitude
    #	derivative(matrix,'longitude');	# result is derivative with respect to longitude
    #	derivative(matrix, 1);		# result is derivative with respect to longitude
    #
    # Based on quadratic through 3 points (provided size of dimension is > 2 -- if only 2 then
    # based on straight line). These always include the point corresponding to the result.
    # For interior points, the other 2 are the closest neighbour on each side.  For boundry
    # points, these are the 2 closest neighbours.
    #
    # Let D(x) be the derivative of quadratic through points (x0,y0), (x1,y1), (x2,y2)
    # D1 = D(x1) = a0 * y0 + a1 * y1 + a2 * y2
    # where the coefficients a0, a1, a2 are defined by:
    #	a0 = (x1 - x2) / ((x1 - x0) * (x2 - x0))
    #	a1 = 1 / (x1 - x0) - 1 / (x2 - x1)
    #	a2 = (x1 - x0) / ((x2 - x0) * (x2 - x1))

    proc derivative {
	a
	{d 0}
    } {
	set r [$a rank]
	if {$r == 0} {
	    error "derivative: x is scalar"
	}
	set dn [[nap "dimension_number(a, d)"]]
	if {$dn < $r - 1} {
	    nap "p = (0 .. (dn-1) ... 1) // (r-1) // ((dn+1) .. (r-2) ... 1) // dn"; # permutation
	    nap "D1 = transpose(derivative(transpose(a, p), -1), p)"
	} else {
	    nap "x = coordinate_variable(a, dn)"
	    if {[$x datatype] eq "f64"  ||  [$a datatype] eq "f64"} {
		nap "x = f64 x"
		nap "y = f64 a"
	    } else {
		nap "x = f32 x"
		nap "y = f32 a"
	    }
	    nap "s = shape(a)"
	    set c [commas [expr "$r - 1"]]
	    set n [[nap "s(dn) - 1"]]
	    switch $n {
		-1 {
		    error "derivative: x is empty"
		}
		0 {
		    error "derivative: dimension size = 1"
		}
		1 {
		    nap "i0 = {1 0}"
		    nap "i1 = {0 1}"
		    nap "y0 = y($c i0)"
		    nap "y1 = y($c i1)"
		    nap "D1 = (y1 - y0) / (x(i1) - x(i0))"
		}
		default {
		    nap "i0 = 2 // (0 .. (n-1))"
		    nap "i1 = 0 .. n"
		    nap "i2 = (1 .. n) // -3"
		    nap "x0 = x(i0)"
		    nap "x1 = x(i1)"
		    nap "x2 = x(i2)"
		    nap "d10 = x1 - x0" 
		    nap "d20 = x2 - x0" 
		    nap "d21 = x2 - x1" 
		    nap "a0 = - d21 / (d10 * d20)"
		    nap "a1 = 1/d10 - 1/d21"
		    nap "a2 = d10 / (d20 * d21)"
		    nap "y0 = y($c i0)"
		    nap "y1 = y($c i1)"
		    nap "y2 = y($c i2)"
		    nap "D1 = a0 * y0 + a1 * y1 + a2 * y2"
		}
	    }
	    eval $D1 set coo [$a coo]
	    eval $D1 set dim [$a dim]
	}
	nap "D1"
    }


    # dimension_number --
    #
    # Result is index of dimension
    #
    # Usage:
    #	dimension_number(x, d)
    #	where:
    #	- 'x' is main array
    #	- d is either integer (giving result "d % rank(x)") or name of dimension.
    #
    # Examples (assuming matrix has dimensions 'latitude' & 'longitude'):
    #	dimension_number(matrix, 'latitude'); # result is 0
    #	dimension_number(matrix, 'longitude'); # result is 1
    #	dimension_number(matrix, 2); # result is 0
    #	dimension_number(matrix, -1); # result is 1

    proc dimension_number {
	x
	d
    } {
	if {[$d datatype] eq "c8"} {
	    set result [lsearch [$x dimension] [$d]]
	} else {
	    nap "result = d % rank(x)"
	}
	nap "result"
    }


    # fill_holes --
    #
    # Replace missing values by estimates based on means of neighbours
    #
    # Usage:
    #	fill_holes(x, max_nloops)
    #	where:
    #	- x is array to be filled
    #	- max_nloops is max. no. iterations (Default is to keep going until
    #     there are no missing values)

    proc fill_holes {
	x
	{max_nloops -1}
    } {
	set max_nloops [[nap "max_nloops"]]
	set n [$x nels]
	set n_present 0; # ensure at least one loop
	for {set nloops 0} {$n_present < $n  &&  $nloops != $max_nloops} {incr nloops} {
	    nap "ip = count(x, 0)"; # Is present? (0 = missing, 1 = present)
	    set n_present [[nap "sum_elements(ip)"]]
	    if {$n_present == 0} {
		error "fill_holes: All elements are missing"
	    } elseif {$n_present < $n} {
		nap "x = ip ? x : moving_average(x, 3, -1)"
	    }
	}
	nap "x"
    }


    # fuzzy_ceil --
    #
    # Same as ceil() except that allow for some rounding error

    proc fuzzy_ceil {
	x
	{eps 1e-9}
    } {
	nap "ceil(x - eps)"
    }


    # fuzzy_floor --
    #
    # Same as floor() except that allow for some rounding error

    proc fuzzy_floor {
	x
	{eps 1e-9}
    } {
	nap "floor(x + eps)"
    }


    # gets_matrix --
    #
    # Read text file and return NAO f64 matrix whose rows correspond to the lines in the file.
    # Ignore:
    #   - first 'n_header_lines' (default 0) lines 
    #   - blank lines 
    #   - lines whose first non-whitespace character is '#'

    proc gets_matrix {
	file_name_nao
	{n_header_lines 0}
    } {
	set n_header_lines [[nap "n_header_lines"]]
	if [catch {set f [open [$file_name_nao value] r]} message] {
	    error $message
	}
	for {set line_number 1} {[gets $f line] >= 0} {incr line_number} {
	    set line [string trim $line]
	    if {$line_number > $n_header_lines  &&  $line ne ""  &&  ![regexp {^#} $line]} {
		if {[info exists ncols]} {
		    if {[llength $line] != $ncols} {
			error "Following line has wrong number of fields\n$line"
		    }
		} else {
		    set ncols [llength $line]
		}
		lappend lines $line
	    }
	}
	close $f
	set nrows [llength $lines]
	nap "result = reshape(0.0, nrows // ncols)"
	for {set i 0} {$i < $nrows} {incr i} {
	    $result set value "{[lindex $lines $i]}" i,
	}
	nap "result"
    }


    # head --
    #
    # If n >= 0 then result is 1st n elements of x, cycling if n > nels(x)
    # If n <  0 then result is 1st nels(x)+n elements of x i.e. drop -n from end

    proc head {
	x
	{n 1}
    } {
	nap "n = n < 0 ? n % nels(x) : n"
	nap "x(0 .. (n-1))"
    }


    # hsv2rgb --
    #
    # nap function to convert hsv to rgb
    #
    # Usage
    #   hsv2rgb(hsv)
    #     where hsv is an array whose leading dimension has size 3.
    #	Layer 0 along this dimension corresponds to hue as an angle in degrees.
    #	  Angles of any sign or magnitude are allowed.
    #	  Red = 0, yellow = 60, green = 120, cyan = 180, blue = -120, magenta = -60.
    #	Layer 1 along this dimension corresponds to saturation in range 0.0 to 1.0.
    #	Layer 2 along this dimension corresponds to "value". This has the same
    #	  range as the RGB values, normally either 0.0 to 1.0 or 0 to 255.
    #	  If you are casting the result to an integer & want a maximum of 255 then
    #	  set the maximum to say 255.999. Otherwise you will get few if any 255s.
    #  The result has the same shape as the argument (hsv).
    #
    # Example
    #   nap "hsv2rgb {180.0 0.5 100.0}"
    #   This produces the vector {50 100 100}
    #
    # See Foley, vanDam, Feiner and Hughes, Computer Graphics
    # Principles and Practice, Second Edition, 1990, ISBN 0201121107
    # page 593. 

    proc hsv2rgb {hsv} {
	nap "hsv = f32(hsv)"
	set r [$hsv rank]
	set c [commas "$r - 1"]
	nap "h = hsv(0$c)"
	nap "s = hsv(1$c)"
	nap "v = hsv(2$c)"
	nap "h = (h % 360f32) / 60f32"
	nap "i = floor(h)"
	nap "f = h - i"
	nap "p = v * (1f32 - s)"
	nap "p = v * (1f32 - s)"
	nap "q = v * (1f32 - (s * f))"
	nap "t = v * (1f32 - (s * (1f32 - f)))"
	nap "i == 0 ? (v /// t // p) :
	     i == 1 ? (q /// v // p) :
	     i == 2 ? (p /// v // t) :
	     i == 3 ? (p /// q // v) :
	     i == 4 ? (t /// p // v) :
		      (v /// p // q)"
    }


    # IBMfp32tof32 --
    #
    # Converts a single-precision IBM floating point to an f32
    #
    #
    #   1    7              24                width in bits
    #  +-+-------+------------------------+
    #  |S| Exp   |   Mantissa             |
    #  +-+-------+------------------------+
    #  31 30   24 23                     0    bit index (0 on right)
    #    bias +70
    #
    # The exponent is to the base 16 (16**(Exp - 70))
    # The mantissa is unsigned integer (binary point on right)
    #
    # Test input 3259367424u32  and get back -70.0
    #
    # input u32 containing the IBM float in appropriate byte order
    #
    # output f32
    #
    # P.J. Turner CMAR March 2006

    proc IBMfp32tof32 {ibm} {
	nap "sign = 1 - 2 * (ibm >> 31)"; # -1 or +1
	nap "exp = i32((ibm & 0x7F000000) >> 24) - 70"
	nap "mantissa = i32(ibm & 0x00FFFFFF)"
	nap "f32((sign * mantissa) * 16f64 ** exp)"
    }


    # isInsidePolygon --
    #
    # This function is deprecated.
    # It has been replaced by the built-in function 'inPolygon'.
    # This version of isInsidePolygon calls inPolygon.
    #
    # Usage: isInsidePolygon(x, y, poly)
    # Tests whether points defined by x & y are inside polygon defined by poly.
    # Result is 0 for outside, 1 for inside, 1 for exactly on edge.
    #
    # poly is normally matrix with 2 columns.  Each row corresponds to a point.
    # Column 0 contains x values & column 1 contains y values.
    # If poly is a vector then it will be reshaped to a matrix with same number of elements.
    #
    # x & y must have shapes which are compatible with each other.
    # Result has the same shape as x or y (whichever has the higher rank)

    proc isInsidePolygon {
	x
	y
	poly
    } {
	if {[$poly rank] == 1} {
	    nap "poly = reshape(poly, (nels(poly) / 2) // 2)"
	}
	nap "inPolygon(x, y, poly) >= 0"
    }


    # isMember --
    #
    # isMember(a,v) tests whether elements of array a are members of vector v.
    # Result has shape of a.

    proc isMember {
	a
	v
    } {
	nap "count(v @@@ a, 0)"
    }


    # isMissing --
    #
    # nap function giving 1 if element is missing, 0 if present.

    proc isMissing nao {
	nap "!count(nao,0)"
    }


    # isPresent --
    #
    # nap function giving 0 if element is missing, 1 if present.

    proc isPresent nao {
	nap "count(nao,0)"
    }


    # magnify_generic --
    #
    # Called by magnify_nearest & magnify_interp

    proc magnify_generic {
	x
	mag_factor
	want_nearest
    } {
	set want_nearest [$want_nearest]
	set rank [$x rank]
	switch [$mag_factor rank] {
	    0 {nap "mag_factor = rank # mag_factor"}
	    1 {}
	    default {error "magnify_generic: mag_factor is not scalar or vector"}
	}
	if {[$mag_factor nels] != $rank} {
	    error "magnify_generic: nels(mag_factor) != rank"
	}
	nap "old_shape = shape(x)"
	nap "i = (,){}"
	for {set d 0} {$d < $rank} {incr d} {
	    nap "n0 = old_shape(d)"
	    nap "n1 = nint(1 + mag_factor(d) * (n0 - 1))"
	    nap "s = n1 ... 0 .. (n0-1)"
	    nap "new_cv$d = (coordinate_variable(x, d))(s)"
	    lappend cv_list [set new_cv$d]
	    if {$want_nearest} {
		nap "s = i32(nint(s))"
	    }
	    nap "i = i , s"
	}
	nap "result = x(i)"
	eval $result set coo $cv_list
	nap "result"
    }


    # magnify_interp --
    #
    # Magnify array by specified factor mag_factor.
    # Contract if mag_factor < 1.0.
    # Border elements magnify only inwards not outwards.
    # mag_factor is either scalar or vector with element for each dimension.
    # Use interpolation to define new values.

    proc magnify_interp {
	x
	mag_factor
    } {
	nap "magnify_generic(x, mag_factor, 0)"
    }


    # magnify_nearest --
    #
    # Magnify array by specified factor mag_factor.
    # Contract if mag_factor < 1.0.
    # Border elements magnify only inwards not outwards.
    # mag_factor is either scalar or vector with element for each dimension.
    # Use nearest neigbours to define new values.
    # Define CVs of result using interpolation.

    proc magnify_nearest {
	x
	mag_factor
    } {
	nap "magnify_generic(x, mag_factor, 1)"
    }


    # mixed_base --
    #
    # convert scalar value to mixed base (defined by vector)
    #
    # Example
    # Following converts 87 inches to yards, feet & inches, giving the result {2 1 3}
    # nap "mixed_base(87, {3 12})"

    proc mixed_base {
	x
	b
    } {
	if {[$x rank] != 0} {
	    error "mixed_base: 1st argument not scalar"
	}
	if {[$b rank] != 1} {
	    error "mixed_base: 2nd argument (base) not vector"
	}
	nap "result = {}"
	for {set i [expr [$b nels] - 1]} {$i >= 0} {incr i -1} {
	    nap "rem = x % b(i)"
	    nap "x = (x - rem) / b(i)"
	    nap "result = rem // result"
	}
	nap "x // result"
    }


    # nub --
    #
    # Result is vector of distinct values in argument (in same order)

    proc nub {
	x
    } {
	nap "v = reshape(x)"
	nap "v = isPresent(v) # v"
	nap "result = v{}"
	while {[$v nels] > 0} {
	    nap "result = result // v(0)"
	    nap "v = (v != v(0)) # v"
	}
	nap "result"
    }


    # outer --
    #
    # tensor outer-product
    #
    # dyad can be name of function or operand
    # In either case there must be two operands/arguments
    # x and y must be vectors
    # Result is cross-product of x and y (applying dyad to each combination of x & y)
    # x & y are the coordinate variables of the result

    proc outer {
	dyad
	y
	{x y}
    } {
	set d [$dyad value]
	nap "ymat = transpose(reshape(y, nels(x) // nels(y)))"
	if {[string is alpha [string index $d 0]]} {
	    nap "result = ${d}(ymat, x)"
	} else {
	    nap "result = ymat $d x"
	}
	$result set coo y x
	nap "result"
    }


    # palette_interpolate --
    #
    # Define palette by interpolating round colour wheel (with s = v = 1)
    # Args 'from' & 'to' are angles in degrees (Red = 0, green = -240, blue = 240)

    proc palette_interpolate {
	from
	to
    } {
	nap "n = 255"
	nap "h = f32(n ... from .. to)"
	nap "s = v = 1f32"
	nap "mat = transpose(hsv2rgb(h /// s // v))"
	nap "white = 3 # 1f32"
	nap "u8(255.999f32 * (mat // white))"
    }


    # reverse --
    #
    # nap function to reverse order of items in array

    proc reverse {
	x
	{verb_rank "rank(x)"}
    } {
	set r [$x rank]
	set vr [[nap "verb_rank"]]
	if {$vr == 0} {
	    nap "x"
	} else {
	    set vr [[nap "1 + (vr - 1) % r"]]
	    nap "x([commas "$r - $vr"]-[commas "$vr - 1"])"
	}
    }


    # scaleAxis --
    #
    #   Find suitable values for axis.
    #   Normal result is the arithmetic progression (AP) which:
    #   - has increment equal to an element of NICE times a power (-30 .. 30) of 10
    #   - has elements equal to integer multiple of this increment
    #   - has same order (ascending/descending) as {XSTART, XEND}
    #   - has as many elements as possible, but no more than NMAX
    #   - is within the interval from XSTART to XEND if MODE is 0
    #   - contains  the interval from XSTART to XEND if MODE is 1
    #	If no such AP exists but one or more exist for N > NMAX, then the one with minimum
    #	N is selected and the result is the 2-element vector containing its range.
    #   If no such AP with at least 2 elements exists, then the result is set to an empty vector.
    #
    # Usage
    #   scaleAxis(XSTART, XEND ?,NMAX? ?,NICE? ?,MODE?)
    #       XSTART: 1st data value
    #       XEND: Final data value
    #       NMAX: Max. allowable number of elements in result (Default: 10)
    #       NICE: Allowable increments (Default: {1 2 5})
    #       MODE: Want axis to contain START & XEND? (Default: 0)
    #
    # Example
    #   nap "axis = scaleAxis(-370, 580, 10, {10 20 25 50})"
    # This sets axis to vector {-300 -200 -100 0 100 200 300 400 500}

    proc scaleAxis {
	xstart
	xend
	{nmax 10}
	{nice "{1 2 5}"}
	{mode 0}
    } {
	if {[[nap "xstart == xend"]]} {
	    if {[[nap "mode"]]} {
		nap "x = sort(0 // (xstart == 0 ? 1 : xstart))"
		nap "result = scaleAxis(x(0), x(1), nmax, nice, mode)"
	    } else {
		nap "result = reshape(xstart)"
	    }
	} else {
	    if {[[nap "mode"]]} {
		set f0 fuzzy_floor
		set f1 fuzzy_ceil
	    } else {
		set f0 fuzzy_ceil
		set f1 fuzzy_floor
	    }
	    nap "xmin = f64(xstart <<< xend)"
	    nap "xmax = f64(xstart >>> xend)"
	    nap "p = 10.0 ** (-30 .. 30)"
	    nap "nn = nels(nice)"
	    nap "nice_vec = sort(reshape(f64(nice), nels(p) * nn) * (nn # p))"
	    nap "nv0 =  f0(xmin/nice_vec)"
	    nap "nv1 =  f1(xmax/nice_vec)"
	    nap "nv = 1.0 + (nv1 - nv0)"
	    nap "max32 = 2e9"; # near limit for i32 number
	    nap "mask = abs(nv0) < max32  &&  abs(nv1) < max32"
	    nap "mask = mask  &&  nv > 1.5  &&  nv <= (nmax >>> min(nv))"
	    nap "j = mask @@@ 1"
	    if {[[nap "isMissing(j)"]]} {
		nap "result = xstart // xend"
	    } else {
		nap "d = nice_vec(j)"
		nap "n = i32(nv(j))"
		nap "i = i32(nv0(j) + (0 // (n-1)))"
		nap "n = n > nmax ? 2 : n"
		nap "result = d * (n ... i(xstart > xend) .. i(xstart < xend))"
	    }
	}
	nap "result"
    }


    # scaleAxisSpan --
    #
    #   Find suitable values for axis which includes XSTART & XEND
    #
    # Usage
    #   scaleAxisSpan(XSTART, XEND ?,NMAX? ?,NICE?)
    #       XSTART: 1st data value
    #       XEND: Final data value
    #       NMAX: Max. allowable number of elements in result (Default: 10)
    #       NICE: Allowable increments (Default: {1 2 5})
    #
    # Example
    #   nap "axis = scaleAxisSpan(-370, 580, 10, {10 20 25 50})"
    # This sets axis to vector {-400 -200 0 200 400 600}

    proc scaleAxisSpan {
	xstart
	xend
	{nmax 10}
	{nice "{1 2 5}"}
    } {
	nap "scaleAxis(xstart, xend, nmax, nice, 1)"
    }


    # scattered2grid --
    #
    # Produce matrix grid from scattered x-y-z data.
    #
    # Method
    # 1. (x,y) points are triangulated. 
    # 2. Loop over triangles.
    #      For each triangle define plane through its 3 vertices.
    #      Define interpolated grid values within each triangle using this plane.
    #
    # Usage
    #   scattered2grid(XYZ, YCV, XCV)
    #       XYZ: matrix containing scattered data. Columns 0, 1, 2 contain x, y, z respectively.
    #       YCV: y coordinate variable for grid
    #       XCV: x coordinate variable for grid

    proc scattered2grid {
	xyz
	ycv
	xcv
    } {
	set vars {xyz ycv xcv}
	set dataType f32
	foreach var $vars {
	    set dt [[set $var] datatype]
	    if {[lsearch {f64 i32 u32} $dt] >= 0} {
		set dataType f64
	    }
	}
	foreach var $vars {
	    nap "$var = ${dataType}($var)"
	}
	nap "nx = nels(xcv)"
	nap "ny = nels(ycv)"
	nap "s = ny // nx"; # shape of result
	nap "x = reshape(xcv, s)"
	nap "y = reshape(nx # ycv, s)"
	nap "result = reshape(dataType(_), s)"
	$result set dim y x
	$result set coord ycv xcv
	nap "A = reshape(dataType(1), {3 3})"; # Use for LHS of 3 linear equations
	nap "triangles = triangulate(xyz)"
	set nt [[nap "(shape triangles)(0)"]]; # no. triangles
	for {set i 0} {$i < $nt} {incr i} {
	    nap "j = triangles(i,)"
	    nap "xy = xyz(j, {0 1})"
	    $A set value xy ",{1 2}"
	    nap "abc = solve_linear(A, xyz(j,2))"
	    nap "z = abc(0) + abc(1) * x + abc(2) * y"
	    nap "ip = inPolygon(x, y, xy)"
	    nap "result = ip < 0 ? result : z"
	}
	nap "result"
    }


    # range --
    #
    # Find min & max of any NAO.  Result is 2-element vector containing min & max.

    proc range nao {
	nap "minValue = maxValue = nao"
	while {[$maxValue rank] > 0} {
	    nap "maxValue = max(maxValue)"
	    nap "minValue = min(minValue)"
	}
	nap "minValue // maxValue"
    }


    # sum_elements --
    #
    # Sum of elements of x
    # i.e. scalar value defined by "sum(reshape(x))"

    proc sum_elements {
	x
    } {
	while {[$x rank] > 0} {
	    nap "x = sum x"
	}
	nap "x"
    }


    # tail --
    #
    # If n >= 0 then result is final n elements of x, cycling if n > nels(x)
    # If n <  0 then result is final nels(x)+n elements of x i.e. drop -n from start

    proc tail {
	x
	{n 1}
    } {
	nap "n = n < 0 ? n % nels(x) : n"
	nap "x((-n) .. -1)"
    }


}
