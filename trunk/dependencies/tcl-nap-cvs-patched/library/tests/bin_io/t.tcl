source ../../bin_io.tcl

nap "m = reshape(1 .. 6, {2 3})"
$m set coo "{20 30}" "{60.0 70 90}"
$m set label "This is 2x3 matrix"
put_cif m m.cif
nap "i = [get_cif -f m.cif]"
file delete m.cif
set f [open new.txt w]
puts $f [$m]
puts $f [$m label]
puts $f [[$m coo 0]]
puts $f [[$m coo 1]]
close $f
