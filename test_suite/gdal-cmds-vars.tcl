#!/usr/bin/tclsh8.5
load [file join .. gdal swig tcl gdal.so]
load [file join .. gdal swig tcl gdalconst.so]

foreach a [lsort [info commands osgeo::*]] {
    puts "Command: $a"
}
foreach a [lsort [info procs osgeo::*]] {
    puts "Proc: $a {[info args $a]}"
}
foreach a [lsort [info vars osgeo::*]] {
    puts "Var: $a = [set $a]"
}
