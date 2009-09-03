# wrap_geog_polylines --

proc wrap_geog_polylines {
    polylines
    {min_longitude 0}
} {
    set proc_name wrap_geog_polylines 
    nap "p = f64(polylines)"
    nap "xmin = f64(min_longitude)"
    nap "xmax = xmin + 360.0"
    nap "xmid = xmin + 180.0"
    nap "result = emptyBoxedVector = (,){}"
    set n [$p nels]
    for {set k 0} {$k < $n} {incr k} {
	nap "xy = open_box(p k)"
	nap "x = (xy(0,) - xmin) % 360.0 + xmin"
	nap "y = xy(1,)"
	nap "i = 0 .. nels(x)-2 ... 1"
	nap "wrap = abs(x(i+1) - x(i)) > 180.0"
	set nwrap [[nap "sum wrap"]]
	nap "iwrap = wrap # i"
	nap "i0 = 0"
	for {set j 0} {$j < $nwrap} {incr j} {
	    nap "iwrap0 = iwrap(j)"
	    nap "iwrap1 = iwrap0 + 1"
	    nap "x0 = x(iwrap0)"
	    nap "x1 = x(iwrap1)"
	    nap "y0 = y(iwrap0)"
	    nap "y1 = y(iwrap1)"
	    nap "x10 = x1 - x0"
	    nap "y10 = y1 - y0"
	    nap "i = i0 .. iwrap0 ... 1"
	    if {[[nap "x0 < xmid"]]} {
		nap "x1new = x1 - 360.0"
		nap "x2 = xmin"
		nap "x3 = xmax"
	    } else {
		nap "x1new = x1 + 360.0"
		nap "x2 = xmax"
		nap "x3 = xmin"
	    }
	    nap "xy1 = xy2 = {}"
	    if {[[nap "x0 == x1new"]]} {
		nap "xy1 = x(i) /// y(i)"
	    } elseif {[[nap "x3 != x1"]]} {
		nap "xy1 = x(i) /// y(i)"
		nap "y2 = y0 + (x2 - x0) * y10 / (x1new - x0)"
		nap "xy1 = (x(i) // x2) /// (y(i) // y2)"
		nap "xy2 = (x3 // x1) /// (y2 // y1)"
	    }
	    $xy1 set unit degrees
	    $xy2 set unit degrees
	    nap "b12 = emptyBoxedVector"
	    if {[$xy1 nels] > 0} {
		nap "b12 = b12 , xy1"
	    }
	    if {[$xy2 nels] > 0} {
		nap "b12 = b12 , xy2"
	    }
	    if {[$b12 nels] > 0} {
		nap "result = result , b12"
	    }
	    nap "i0 = icow1"
	}
	nap "i = i0 .. nels(x)-1 ... 1"
	if {[$i nels] > 1} {
	    nap "xy1 = x(i) /// y(i)"
	    $xy1 set unit degrees
	    nap "result = result , xy1"
	}
    }
    nap "result"
}
