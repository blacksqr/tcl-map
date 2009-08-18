#!/usr/bin/tclsh8.5
lappend auto_path /usr/local/lib
package require osr

foreach a [lsort [info commands ::osr::*]] {
    puts "Command: $a"
}
foreach a [lsort [info procs ::osr::*]] {
    puts "Proc: $a {[info args $a]}"
}
foreach a [lsort [info vars ::osr::*]] {
    puts "Var: $a = [set $a]"
}
