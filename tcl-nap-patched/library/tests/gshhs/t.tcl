source ../../gshhs.tcl
set min_area 1e5
set max_level 2
set min_longitude 0
set tolerance 25
nap "u = [nap_get net ../../uv.nc u "0,0,,"]"
nap "c = get_gshhs(tolerance, min_area, max_level, min_longitude)"
plot_nao u -overlay "E c"

nap "j = (90 .. 179) // (0 .. 89)"
nap "ur = u(,j)"
set min_longitude -180
set max_longitude  180
nap "lat = cv(ur,0)"
nap "lon = (cv(ur,1) - min_longitude) % 360 + min_longitude"
$lon set unit degrees_east
$ur set coo lat lon
nap "c = get_gshhs(tolerance, min_area, max_level, min_longitude)"
plot_nao ur -overlay "E c"
