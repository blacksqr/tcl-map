# create netcdf file with variables having variety of long_name & units atts.

set file t.nc
file delete $file
nap "x = 0"
set s(0) ""
set s(1) 0123456789
set s(2) [string repeat $s(1) 8]
foreach i "0 1 2" {
    set long_name $s($i)
    foreach j "0 1 2" {
	set units $s($j)
	set var "var$i$j"
	$x netcdf $file $var
	if {$long_name ne ""} {
	    [nap "'$long_name'"] netcdf $file ${var}:long_name
	}
	if {$units ne ""} {
	    [nap "'$units'"] netcdf $file ${var}:units
	}
    }
}
