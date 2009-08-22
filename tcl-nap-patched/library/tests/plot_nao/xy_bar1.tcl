source ../../plot_nao.tcl
source ../../plot_nao_procs.tcl

nap "x = 101 .. 120"
nap "y = sqrt x"
$y set coo x
plot_nao y
plot_nao y -ty b
