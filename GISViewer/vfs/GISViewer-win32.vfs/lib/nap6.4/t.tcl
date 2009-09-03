source gshhs.tcl
source plot_nao_procs.tcl
source proj4.tcl
nap "in = [nap_get net uv.nc u 0,0,,]"
foreach r {5} {
    puts "r=$r [time {plot_nao in -use 1 -gshhs_res $r}]"
}
