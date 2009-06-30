#!/usr/local/bin/tclsh8.5
package require gdal
gdal map tests/map.png
puts [map info]
puts [map band 1 info]
puts [map band 2 info]
puts [map band 3 info]
binary scan [map band 1 read] cu* band1_big
binary scan [map band 1 read 20 20] cu* band1_small
puts [llength $band1_big]
puts [llength $band1_small]
puts \n\nDRIVER
puts [map meta driver ""]
puts \n\nDATASET
puts [map meta dataset ""]
puts \n\nBAND
puts [map meta band 1 ""]
puts \n\nDRIVER:IMAGE_STRUCTURE
puts [map meta dataset IMAGE_STRUCTURE]
