# stat.tcl --
# 
# Copyright (c) 2000, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: stat.tcl,v 1.28 2005/12/13 01:51:45 dav480 Exp $
#
# Statistics functions

namespace eval ::NAP {


    # STAT contains internal (private) procedures

    namespace eval STAT {

	# define_stat --
	#
	# This generalises vector definition to other ranks

	proc define_stat {
	    X
	    verb_rank
	    scalar_defn
	    vector_defn
	} {
	    set r [$X rank]
	    set vr [[nap "(verb_rank) % (r + 1)"]]
	    if {$vr == 0} {
		eval $scalar_defn
	    } elseif {$r == 1} {
		eval $vector_defn
	    } else {
		nap "s = shape X"
		nap "j = r - vr"
		nap "i = 0 .. (r - 1)"
		nap "ii = (i != j) # i"
		nap "result_shape = s(ii)"
		set result_nels [[nap "prod(result_shape)"]]
		nap "result = reshape(0.0, result_nels)"
		nap "XX = transpose(X, ii)"
		nap "XX = reshape(XX, result_nels // (nels(X) / result_nels))"
		for {set k 0} {$k < $result_nels} {incr k} {
		    nap "vector = XX(k,)"
		    $result set value [define_stat $vector 1 $scalar_defn $vector_defn] $k
		}
		nap "result = reshape(result, result_shape)"
		eval $result set coordinate [eval $X coordinate [$ii value]]
		eval $result set dimension  [eval $X dimension  [$ii value]]
		nap "result"
	    }
	}


	# var01 --
	#
	# internal function called by 'sd', 'sd1', 'var' & 'var1'
	# delta is 0 for var/sd and 1 for var1/sd1

	proc var01 {
	    X
	    vr
	    delta
	} {
	    set r [$X rank]
	    if [[nap "vr == 0"]] {
		nap "result = X * {0.0 _}(delta)"
	    } elseif {$r == 1} {
		nap "n = count(X)"
		nap "result = sum((X - sum(X) / n)**2) / (n - delta)"
	    } elseif {$r == 2} {
		if [[nap "vr == r"]] {
		    nap "n = count(X)"
		    nap "s = sum(X)"
		    nap "result = sum((X - s/n)**2, vr) / (n - delta)"
		} else {
		    nap "result = transpose(STAT::var01(transpose(X), r, delta))"
		}
	    } else {
		nap "result = [::NAP::STAT::define_stat $X $vr {nap "1nf64 * X"} \
		    "nap n = count(X); nap sum((X - sum(X) / n)**2) / (n-$delta)"]"
	    }
	    nap "result"
	}

    }


    # am --
    #
    # arithmetic mean

    proc am {
	X
	{verb_rank "rank(X)"}
    } {
	set r [$X rank]
	set vr [[nap "(verb_rank) % (r + 1)"]]
	if {$vr == 0} {
	    nap "result = X"
	} elseif {$r == 1} {
	    nap "result = sum(X) / count(X)"
	} else {
	    nap "result = sum(X, vr) / count(X, vr)"
	}
	$result set unit [$X unit]
	nap "result"
    }


    # CV --
    #
    # uncorrected coefficient of variation = sd/am

    proc CV {
	X
	{verb_rank "rank(X)"}
    } {
	nap "sd(X, verb_rank) / am(X, verb_rank) "
    }


    # CV1 --
    #
    # corrected coefficient of variation = sd1/am

    proc CV1 {
	X
	{verb_rank "rank(X)"}
    } {
	nap "sd1(X, verb_rank) / am(X, verb_rank) "
    }


    # fit_polynomial --
    #
    # Return coefficients of least squares polynomial of order n (default 1, giving straight line)
    # x and y are vectors with the same length
    #
    # Function 'polynomial' below can be used to evaluate the polynomial with the
    # resultant coefficients.

    proc fit_polynomial {
	x
	y
	{n 1}
    } {
	nap "solve_linear(outer('**', x, 0 .. n), y)"
    }


    # gm --
    #
    # geometric mean

    proc gm {
	X
	{verb_rank "rank(X)"}
    } {
	set r [$X rank]
	set vr [[nap "(verb_rank) % (r + 1)"]]
	if {$vr == 0} {
	    nap "result = X"
	} elseif {$r == 1} {
	    nap "result = prod(X) ** (1.0 / count(X))"
	} else {
	    nap "result = prod(X, vr) ** (1.0 / count(X, vr))"
	}
	$result set unit [$X unit]
	nap "result"
    }


    # median --

    proc median {
	X
	{verb_rank "rank(X)"}
    } {
	set r [$X rank]
	set vr [[nap "(verb_rank) % (r + 1)"]]
	if {$vr == 0} {
	    nap "result = X"
	} elseif {$r == 1} {
	    nap "result = (sort(count(X,0) # X)) (0.5 * (count(X) - 1))"
	} else {
	    nap "result = [::NAP::STAT::define_stat $X $vr {nap "X"} {
		nap "(sort(count(X,0) # X)) (0.5 * (count(X) - 1))"}]"
	}
	$result set unit [$X unit]
	nap "result"
    }


    # mode --
    #
    # Handle possibility of multiple modes by defining result as mean of values whose
    # frequency = max(frequency).
    #
    # n is number of class intervals, which is only used for floating-point data types.
    # (Default: 64)

    proc mode {
	X
	{verb_rank "rank(X)"}
	{n 64}
    } {
	set r [$X rank]
	set vr [[nap "(verb_rank) % (r + 1)"]]
	if {$vr == 0} {
	    nap "result = X"
	} elseif {$r == 1} {
	    nap "Xmin = min(X)"
	    if {[regexp {^f} [$X datatype]]} {
		nap "step = (max(X) - Xmin) / n"
		nap "f = # i32((X - Xmin) / step + 0.5f32)"
		nap "i = (f == max(f)) # (0 .. (nels(f) - 1))"
		nap "result = f32(am(i) * step + Xmin)"
	    } else {
		nap "f = # (X - Xmin)"
		nap "i = (f == max(f)) # (0 .. (nels(f) - 1))"
		nap "result = f32(am(i) + Xmin)"
	    }
	} else {
	    nap "result = f32([::NAP::STAT::define_stat $X $vr {nap "X"} {nap "mode(X)"}])"
	}
	$result set unit [$X unit]
	nap "result"
    }


    # moving_average --
    #
    # Move window of specified shape by specified step (can vary for each dimension).
    # Result is arithmetic mean of values in each window.
    #
    # 'shape_window' is either a scalar or a vector with an element for each dimension.
    # If it is a scalar then it is treated as a vector with rank(x) identical elements. 
    #
    # Similarly, 'step' is either a scalar or a vector with an element for each dimension.
    # If it is a scalar then it is treated as a vector with rank(x) identical elements. 
    # The value -1 is treated like 1, except that missing values are prepended & appended
    # (along this dimension of x) to produce a result with the same dimension size as x.
    #
    # x can have any rank > 0.

    proc moving_average {
	x
	shape_window
	{step 1}
    } {
	set r [$x rank]
	if {$r < 1} {
	    error "moving_average: x is scalar"
	}
	set unit [$x unit]
	nap "w = i32(reshape(shape_window, r))"
	nap "s = i32(reshape(step, r))"
	set expand 0
	for {set d 0} {$d < $r} {incr d} {
	    if {[$x coo $r] eq "(NULL)"} {
		lappend cv_list ""
	    } else {
		nap "old_cv = + coordinate_variable(x, d)"
		$old_cv set coo; # Ensure no coord. var. to prevent infinite recursion
		nap "cv$d = moving_average(old_cv, w(d), s(d))"
		lappend cv_list [set cv$d]
	    }
	    if {[[nap "s(d)"]] == -1} {
		set expand 1
		nap "n = (shape(x))(d) - 1"
		nap "i$d = ((w(d) / 2) # _) // (0 .. n) // (((w(d) - 1) / 2) # _)"
	    }
	}
	if {$expand} {
	    nap "i = (,){}"
	    for {set d 0} {$d < $r} {incr d} {
		nap "i = i , i$d"
	    }
	    nap "x = x(i)"
	}
	nap "s = abs(s)"
	nap "n = w + (shape(x) - w) / s * s"
	nap "p = (1 .. (r-1) ... 1) //  0"; # permutation of dimensions
	nap "c = count(x,0)";	# 0 if missing, 1 if present
	nap "px = psum(f64 x)";	# partial sum of x
	nap "pc = psum(f64 c)";	# partial sum of c
	for {set d 0} {$d < $r} {incr d} {
	    nap "i1_$d = w(d) .. n(d) ... s(d)"
	    nap "i0_$d = i1_$d - w(d)"
	    nap "px = 0f64 // transpose(px, p)"
	    nap "pc = 0f64 // transpose(pc, p)"
	}
	nap "moving_sum = moving_count = 0f64"
	set jj [expr "1 << $r"]
	for {set j 0} {$j < $jj} {incr j} {
	    set parity [expr "$r % 2"]
	    nap "i = (,){}"
	    for {set d 0} {$d < $r} {incr d} {
		set bit [expr "($j >> $d) & 1"]
		nap "i = i , i${bit}_$d"
		set parity [expr "$parity ^ $bit"]
	    }
	    if {$parity} {
		nap "moving_sum   = moving_sum   - px(i)"
		nap "moving_count = moving_count - pc(i)"
	    } else {
		nap "moving_sum   = moving_sum   + px(i)"
		nap "moving_count = moving_count + pc(i)"
	    }
	}
	nap "result = moving_count > 0 ? moving_sum / moving_count : _"
	eval $result set coo $cv_list
	if {$unit ne "(NULL)"} {
	    $result set unit $unit
	}
	nap "result"
    }


    # percentile --
    #
    # X = data array of any rank
    # pc = vector of required percentiles
    # nc = number of class intervals (default: 256)

    proc percentile {
	X
	pc
	{verb_rank "rank(X)"}
	{nc 256f32}
    } {
	set r [$X rank]
	set vr [[nap "(verb_rank) <<< r"]]
	nap "nc = f32 nc"
	if {$vr == $r} {
	    nap "xmin = f32(min X)"
	    nap "xmax = f32(max X)"
	    nap "c = (xmax - xmin) / nc"; # class width
	    nap "c1 = c == 0 ? 1f32 : c"; # Use c1 to prevent division by 0
	    nap "f = 0 // (# (i32(round((X - xmin) / c1))))"; # frequencies
	    nap "cf = psum1(f)"; # cumulative frequencies
	    nap "s = shape cf"
	    $s set value "nels(pc)" 0
	    # cf_pc = cumulative frequencies corresponding to pc
	    nap "cf_pc = count(X) * transpose(reshape(f32(pc) / 100f32, s(-)))"
	    nap "result = xmin + c * (cf @ cf_pc) >>> xmin <<< xmax"
	    eval $result set dim [lreplace [$X dim] 0 0 percentile]
	    eval $result set coo [lreplace [$X coo] 0 0 "reshape(pc)"]
	} else {
	    nap "d = r - vr"
	    nap "perm = 0 .. (r-1)"
	    nap "perm = d // (perm != d) # perm"
	    nap "result = percentile(transpose(X, perm), pc, r, nc)"
	}
	nap "result"
    }


    # polynomial --
    #
    # Evaluate polynomial for each value of x
    # Polynomial is defined by c, a vector of coefficients (e.g. given by function 'fit_polynomial')
    # Result has shape of x

    proc polynomial {
	c
	x
    } {
	nap "reshape(outer('**', reshape(x), 0 .. nels(c)-1) . c, shape(x))"
    }


    # regression --
    #
    # Multiple regression (predicting y from x)
    # If x & y are both vectors (of same length) then result is 2-element vector b which defines
    # predictive equation  Y = b(0) + b(1) * X
    # 
    # x & y can be matrices (with columns corresponding to variables)
    # If y is vector then result is vector b which defines
    # predictive equation  Y = b(0) + b(1) * X(0) + b(2) * X(1) + b(3) * X(2) + ...
    #                        = (1 // X) . b
    # 
    # If y is matrix then result is matrix with same number of columns (corresponding to variables)
    # predictive equation  Y = (1 // X) . b
    #                      where X is vector or matrix

    proc regression {
	x
	y
    } {
	switch [$x rank] {
	    1 {nap "A = transpose(1f32 /// x)"}
	    2 {nap "A = transpose(1f32 // transpose(x))"}
	    default {error "regression: rank of x is not 1 or 2"}
	}
	switch [$y rank] {
	    1 {}
	    2 {}
	    default {error "regression: rank of y is not 1 or 2"}
	}
	nap "solve_linear(A, y)"
    }


    # rms --
    #
    # root mean square 

    proc rms {
	X
	{verb_rank "rank(X)"}
    } {
	set r [$X rank]
	set vr [[nap "(verb_rank) % (r + 1)"]]
	if {$vr == 0} {
	    nap "result = X"
	} elseif {$r == 1} {
	    nap "result = sqrt(sum(X*X) / count(X))"
	} else {
	    nap "result = sqrt(sum(X*X, vr) / count(X, vr))"
	}
	$result set unit [$X unit]
	nap "result"
    }


    # sd --
    #
    # uncorrected standard-deviation (with division by n)

    proc sd {
	X
	{verb_rank "rank(X)"}
    } {
	nap "vr = (verb_rank) % (rank(X) + 1)"
	nap "v = STAT::var01(X, vr, 0)"
	nap "result = sqrt(v)"
	$result set unit [$X unit]
	nap "result"
    }


    # sd1 --
    #
    # corrected standard-deviation (with division by n-1)

    proc sd1 {
	X
	{verb_rank "rank(X)"}
    } {
	nap "vr = (verb_rank) % (rank(X) + 1)"
	nap "v = STAT::var01(X, vr, 1)"
	nap "result = sqrt(v)"
	$result set unit [$X unit]
	nap "result"
    }


    # var --
    #
    # uncorrected variance (with division by n)

    proc var {
	X
	{verb_rank "rank(X)"}
    } {
	nap "vr = (verb_rank) % (rank(X) + 1)"
	nap "STAT::var01(X, vr, 0)"
    }


    # var1 --
    #
    # corrected variance (with division by n-1)

    proc var1 {
	X
	{verb_rank "rank(X)"}
    } {
	nap "vr = (verb_rank) % (rank(X) + 1)"
	nap "STAT::var01(X, vr, 1)"
    }


}
