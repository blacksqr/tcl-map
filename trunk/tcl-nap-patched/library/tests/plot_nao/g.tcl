source ../../plot_nao.tcl
source ../../plot_nao_procs.tcl

nap "m = {100#{100#0}100#{100#255}}"
nap "x = 101 .. 200"
nap "y = 501 .. 700"
$m set coo y x
set window0 [plot_nao m -geom +0+20]

nap "mm = +m"
$mm set coo -y -x
set window1 [plot_nao mm -geom -0+20]

tkwait window $window1
destroy $window0
