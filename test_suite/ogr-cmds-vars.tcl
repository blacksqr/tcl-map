#!/usr/local/bin/tclsh8.5
load ../ogr.so

foreach a [lsort [info commands osgeo::*]] {
    puts "Command: $a"
}
foreach a [lsort [info procs osgeo::*]] {
    puts "Proc: $a {[info args $a]}"
}
foreach a [lsort [info vars osgeo::*]] {
    puts "Var: $a = [set $a]"
}
