source ../../plot_nao.tcl
source ../../plot_nao_procs.tcl

nap "m = reshape({0 255}, {5 5})"
nap "x = 1 .. 5"
nap "y = 1 .. 5"
$m set coo y x
set window [plot_nao m -ty z -menu 1 -scaling 0 -geom -0+20]

tkwait window $window
