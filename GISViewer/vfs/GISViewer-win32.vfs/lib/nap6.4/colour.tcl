
#
# Colour manipulation routines.
#
#
# hsvtorgb--
#
# Converts hsv to rgb. hsv is a list composed of hue, h (0 to 360)
# saturation, s (0 to 1.0) and value, v (0 to 255). h and s are floating
# point values and v is an integer. The proceedure returns a list
# containing r, g and b values between 0 and 255.
#
# See Foley, vanDam, Feiner and Hughes, Computer Graphics
# Principles and Practice, Second Edition, 1990, ISBN 0201121107
# page 593. 
#
# Author: Peter Turner, CSIRO Atmospheric Research, October 1999
#
proc hsvtorgb {hsv} {

    set ul 255
    set ll 0
    set h [lindex $hsv 0]
    set s [lindex $hsv 1]
    set v [lindex $hsv 2]
#
# Check that we do not have a degenerate case
#
    if {$s == 0 || $v == 0 || $h == "u"} {
        set rgb [list $v $v $v]
    } else {

        if {$h == 360} {
            set h 0
        }

        set h [expr $h/60.0]
        set i [expr int($h)]
        set f [expr $h - $i]
        set p [expr int($v*(1.0 - $s))]
        set q [expr int($v*(1.0 - ($s*$f)))]
        set t [expr int($v*(1.0 - ($s*(1.0-$f))))]

        if {$v > $ul} {
            set v $ul
        }
        if {$p > $ul} {
            set p $ul
        }
        if {$q > $ul} {
            set q $ul
        }
        if {$t > $ul} {
            set t $ul
        }
       
        switch -exact -- $i {
            0 {set rgb [list $v $t $p]}
            1 {set rgb [list $q $v $p]}
            2 {set rgb [list $p $v $t]}
            3 {set rgb [list $p $q $v]}
            4 {set rgb [list $t $p $v]}
            5 {set rgb [list $v $p $q]}
        }
    }
    return $rgb
}


# rgbtohsv--
#
# Converts rgb to hsv. rgb is a list comprising red, green and
# blue component values between 0 and 255. The proceedure returns
# hue (0 to 360), saturation (0 to 1.0) and value (0 to 255)
# as a list.
#
# See Foley, vanDam, Feiner and Hughes, Computer Graphics
# Principles and Practice, Second Edition, 1990, ISBN 0201121107
# page 593. 
#
# Author: Peter Turner, CSIRO Atmospheric Research, October 1999
#
#
proc rgbtohsv {rgb} {

    set r [lindex $rgb 0]
    set g [lindex $rgb 1]
    set b [lindex $rgb 2]

    set mx $r
    set mn $r
#
# Find the maximum and minimum values for the 
# r,g and b components
#

    if {$g > $mx} {
        set mx $g
    }
    if {$b > $mx} {
        set mx $b
    }
    if {$g < $mn} {
        set mn $g
    }
    if {$b < $mn} {
        set mn $b
    }
#
# Value becomes the maximum
#
    set v $mx
    set delta [expr double($mx - $mn)]
    if {$mx > 0} {
        set s [expr $delta/$mx]
    } else {
        set s 0
    }
    if {$s > 1.0} {
        set $s 1.0
    }
#
# Set the hue to undefined
#
    set h u

    if {$s > 0.0} {
        if {$r == $mx} {
            set h [expr ($g - $b)/$delta]
        } elseif {$g == $mx} {
            set h [expr 2.0 + ($b - $r)/$delta]
        } elseif {$b == $mx} {
            set h [expr 4.0 + ($r - $g)/$delta]
        }
        set h [expr int($h*60)] 
        if {$h < 0} {
            set h [expr $h + 360]
        }
    }
    return [list $h $s $v]
}



