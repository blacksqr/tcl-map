proc read_pal { file } {

    if [catch {open $file r} inId] {
        return "Error opening $file\n $inId"
    }

    set palette ""
    foreach line [split [read $inId] \n] {
        if {$line != "" && [lindex $line 0] != "#"} {
            set index [lindex $line 0]
            set red [lindex $line 1]
            set green [lindex $line 2]
            set blue [lindex $line 3]
            set palette [concat $palette [list $index "$red $green $blue"]]
        } else {
            if {$line != "" && [lindex $line 1] == "end"} {
                break
            }
        }
        
    }
    close $inId
    return $palette
}
#
# write_pal--
#
# Write a palette file given an array of
# colour values.
#
proc write_pal { file colourArray} {

    upvar $colourArray col

    if [catch {open $file w} outId] {
        return "Error opening $file\n $outId"
    }

    puts $outId "# Palette"
    puts $outId "# index  red  green  blue"
    set table ""
    foreach {index value} [array get col] {
        lappend table "$index $value"
    }
    set otable [lsort -increasing -integer -index 0 $table]
    unset table
    foreach {element} $otable {
        puts $outId $element
    }
    puts $outId "# end"
    close $outId
    return 
}
