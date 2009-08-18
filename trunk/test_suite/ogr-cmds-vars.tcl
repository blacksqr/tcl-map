#!/usr/bin/tclsh8.5
lappend auto_path /usr/local/lib
package require ogr

foreach a [lsort [info commands ::ogr::*]] {
    puts "Command: $a"
}
foreach a [lsort [info procs ::ogr::*]] {
    puts "Proc: $a {[info args $a]}"
}
foreach a [lsort [info vars ::ogr::*]] {
    puts "Var: $a = [set $a]"
}
