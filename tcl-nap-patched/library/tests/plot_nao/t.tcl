source ../../plot_nao.tcl
source ../../plot_nao_procs.tcl

nap m = reshape(ap(400,0,-2), 2 # 201)
$m set coo "ap_n(0.0, 50.0, 201)"
set window [plot_nao m -geom -0+20]

tkwait window $window
