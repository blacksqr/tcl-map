#
# Pal Description
#
# General
#
# This proceedure allows colours in a palette of between
# one and 256 colours to be manipulated using a GUI.
# The GUI allows individual colors to be set using
# RGB (red, green and blue) and/or HSV (hue, saturation
# and value) sliders entry boxes and colour wheel.
# Colour sequences can be set by interpolating around
# the colour wheel in constant saturation either
# clockwise or anticlockwise. Sequences of colour
# can be selected and copied to other parts of the
# palette.
# The GUI can be divided into 3 logical groups. The
# left most part of the GUI manages loading and saving
# the palette in a file, writing the palette in a NAO
# and setting the number of colours in the palette.
# The middle section of the palette
# provides controls to change a colour and create
# and copy colour sequences. The right most section
# displays a panel of colours. The top left box is
# colour index 0, with the index increasing left to
# right. The index continues from the end of a row
# at the first column in the row below. 
#
# Changing a single colour
#
# To change the colour of an element in the panel
# of colours click on the element using the left
# mouse button. A white highlight will appear around
# the cell selected. The colour sliders and the 
# HSV values will change to be the current setting for
# the selected colour. (Note, there is no indicalion
# on the colour wheel). The colour for the cell can
# now be changed using the RGB sliders, entries, and/or
# the HSV controlsi including clicking on the colour 
# wheel.
#
# Changing a sequence of colours
#
# To change a sequence of colours first select the
# starting cell of the sequence and change the colour
# as for changing a single colour. Then click on the
# end cell of the colour sequence using the middle
# or right mouse button. The start and end cells
# should now both be highlighted white. The colour
# controls can now be used to set the colour of the
# end of sequence cell. Clicking on the clockwise 
# and anti-clockwise arrow buttons will interpolate
# colours around the colour wheel between the start
# and end colours in the cell sequence.
#
# Copying a colour cell colour 
#
# Click on the colour cell to copy with the left mouse
# button. Left click on the copy button. Left click on
# the cell where the colour is to be copied. Left click
# on the paste button. Multiple pastes are permitted.
#
# Copying a sequence of colour cells  
#
# A sequence of colour cells can be copied by selecting
# and start and end cell as described in changing a sequence
# of colours. Left click on the copy button and then
# left click on the colour cell where the copied sequence
# should start. Left click on the paste button and the
# copied sequence will be pasted in the new position.
# Multiple pastes are permitted and the paste can
# overlap the original copied cells.
#
# Interactions with other proceedures
#
# Pal has a simple interface to allow interaction with
# other applications. The proceedure interface has the form:
#
# proc pal {{nao ""} {cmd ""} {cmdlbl "redraw"}}
#
# If the nao name variable is defined then this name will
# appear in the NAO name entry box. If cmd is defined then
# and extra button will appear and be given the name specified
# in cmdlbl (redraw, by default). If this new button is pressed
# the command defined in command will be executed and a NAO
# created with the specified name. In the case where the
# cmd is defined the NAO name does not appear in the NAO
# entry box. This functionality is use to interface with
# plot_nao which can dynamically load a new palette from
# pal using this interface.
#
# Peter Turner, CSIRO Atmospheric Research, Feburary 2001
#
# Programming Comments
#
# This proceedure is designed to allow multiple instances in
# one Tcl session. To this end data for each instance is contained
# in a namespace called Pal::<n>::<variable name> where <n> = 0,1,2,3..
# n is unique for each instance of pal. The toplevel window name
# will be .pal<n>, <n> = 0,1,2,3,4.. for each instance of pal.
# Support routines for pal all reside in the namespace Pal::.
#
# The tricky bits!
#
# The common parameters for each instance of pal are stored
# in a namespace called Pal::<n>:: where <n> = 0,1,2,3..
# In each supporting proceedure where particular namespace
# variables are needed they are made available locally by
# the use of the "global" command.
#
# For example:
#
# proc dummy {wid} {
#
#     global Pal::${wid}::ncolours
#
#     set ncol $ncolours
#
# }
#
# Here wid is the window id (n, which is 0,1,2,3..). The global
# command allows the ncolours variable to be referred to simply
# as ncolours without the need for the namespace qualification
# withn the proceedure. Unfortunately this technique does not work
# for array variables. The array variable "colours" is therefore
# represented by the full path name in each proceedure.
# This creates some problems in the length and complexity of
# commands. The form:
#
# set value [set Pal::${wid}::colours($index)]
#
# is used to place the value contained in the variable in "value".
# $value is then that value. There are some cases where the substituted
# name is required:
#
# set name [subst Pal::${wid}::colours($index)]
#
# If wid and index had a value of 0 then name would
# contain Pal::0::colours(0).
#
# In other cases the substituted name is required preceeded
# by a $.
#
# set name $[subst Pal::${wid}::colours($index)]
#
# If wid and index are 0 then name will contain
# $Pal::0::colours(0). Note that the leading $ does
# not cause the value of the variable to be returned
# because of the one pass nature of the Tcl parser.
#
# Where operations relate to buttons and
# entries full namespace names are required.
#
# Peter Turner, CSIRO Atmospheric Research  February 2001
#


#
#
# pal--
#
# main palette  proceedure
#
# If called with a NAO name only a NAO of this
# name will be created when the NAO button is selected.
# If the cmd parameter is defined an extra button will 
# appear and if selected create a nao and execute the command
# provided in cmd. The button will be labelled by cmdlbl
#
    proc pal {{nao ""} {cmd ""} {cmdlbl "redraw"}} {

        set geometry ""
        set parent ""

        set t [Pal::create_window $geometry $parent]
#
# Set wid to the last character in the menu name
#
        set wid [string index $t end]
#
# Declare the namespace for this particular 
# instance of Pal
#
        namespace eval Pal::${wid} {

            variable nrows
            variable ncolumns
            variable nels
            variable wrow
            variable wcol
            variable xo
            variable yo
            variable localIndexList
            variable selection
            variable selection2 ""
            variable rectId
            variable colours
            variable tmpCol
            variable red
            variable green
            variable blue
            variable hue
            variable saturation
            variable value
            variable width 200
            variable height 200
            variable directory "/"
            variable file ""
            variable ncolours 256
            variable newncolours 256
            variable NAOname
            variable pvtNAOname
        }
#
# Gain access to local instance variables
#

        global Pal::${wid}::red
        global Pal::${wid}::green
        global Pal::${wid}::blue
        global Pal::${wid}::width
        global Pal::${wid}::height
        global Pal::${wid}::directory
        global Pal::${wid}::file
        global Pal::${wid}::ncolours
        global Pal::${wid}::newncolours
        global Pal::${wid}::NAOname
        global Pal::${wid}::pvtNAOname
#
# We are going to have four frames to accomodate:
#
# 1. Palette file loading and save
# 2. Interpolation, copy and paste and HSV
# 3. RGB change, display and index display
# colour matrix
#
# These components are arranged left to right in the
# palette window.
#
        
#
# Palette file control
#
        frame $t.p
        set p $t.p
#
# Copy/paste and HSV
#
        frame $t.hsv
        set h $t.hsv 
#
# RGB slider frame
#
        frame $t.f
        set s $t.f 
#
# canvas where colour matrix is drawn
#
        frame $t.c
        set c $t.c

#
# Deal with start argument
#
        if {$nao != ""} {
            if {"$cmd" == ""} {
                set NAOname $nao
            } else {
                set pvtNAOname $nao
                set NAOname "palette"
            }
        } else {
            set NAOname "palette"
        }

        canvas $c.can  -width $width -height $height
        label $c.sel -text "select colour cell" -anchor w

#
# Setup the control panel (p)
# Palette file loading etc
#
        button $p.l1 -text "current directory" -padx 2 -pady 2\
            -command "set Pal::${wid}::directory \[tk_chooseDirectory\]"
        entry $p.d -width 20 -textvariable Pal::${wid}::directory
        label $p.l2 -text "palette file" -anchor e
        entry $p.f -width 20 -textvariable Pal::${wid}::file
        button $p.load -text load -padx 2 -pady 2\
            -command "Pal::loadPal $wid $c.can"
        set dir $[subst Pal::${wid}::directory]
        set fnm $[subst Pal::${wid}::file]
        button $p.save -text save -padx 2 -pady 2\
            -command "Pal::save_pal $wid $dir $fnm"
#
# Write NAO button
#
        set name [set Pal::${wid}::NAOname]
        button $p.nao -text NAO -padx 2 -pady 2\
            -command "Pal::writeNAO $wid $name"
        entry $p.enao -width 8 -textvariable Pal::${wid}::NAOname

        label $p.l3 -text colours -anchor e
        entry $p.c -width 3 -textvariable Pal::${wid}::newncolours
        bind $p.c <Key-Return> "Pal::changeNcolours $wid $c.can" 
        button $p.cancel -text cancel -padx 2 -pady 2\
            -command "Pal::destroyPal $wid $t"
        button $p.help -text help -padx 2 -pady 2\
            -command "Pal::helpPal $wid $t"


        grid $p.l1 -row 0 -column 0 -columnspan 2 -sticky nws -pady 2 -padx 2
        grid $p.d -row 1 -column 0 -columnspan 2 -sticky news -pady 2 -padx 2
        grid $p.l2 -row 2 -column 0 -columnspan 2 -sticky nws -pady 2 -padx 2
        grid $p.f -row 3 -column 0 -columnspan 2 -sticky news -pady 2 -padx 2
        grid $p.load -row 4 -column 0 -sticky news -pady 2 -padx 2
        grid $p.save -row 4 -column 1 -sticky news -pady 2 -padx 2
        grid $p.nao -row 5 -column 0 -sticky news -padx 2 -pady 4
        grid $p.enao -row 5 -column 1 -sticky news -padx 2 -pady 4
        grid $p.l3 -row 6 -column 0 -sticky news -padx 2 -pady 4
        grid $p.c -row 6 -column 1 -sticky nws -padx 2 -pady 4
        grid $p.cancel -row 7 -column 0 -sticky nws -padx 2 -pady 4
        grid $p.help -row 7 -column 1 -sticky nws -padx 2 -pady 4
#
# Optional extra button if command is defined
#
        if {"$cmd" != ""} {
            set name [set Pal::${wid}::pvtNAOname]
            button $p.cmd -text $cmdlbl -pady 2\
            -command "Pal::writeNAO $wid $name; $cmd"
            destroy $p.enao
            destroy $p.nao
            grid $p.cmd -row 5 -column 0 -sticky news -padx 2 -pady 4
        }

#
# Interpolation
#
        label $h.in -text "Fill" -anchor w

        set cwa "#define cwa_width 16\n#define cwa_height 16"
        append cwa {
        static unsigned char cwa_bits[] = {
           0x00, 0x00, 0x60, 0x00, 0x98, 0x01, 0x04, 0x02, 0x02,
           0x04, 0x01, 0x08, 0x00, 0x08, 0x00, 0x08, 0x80, 0xff,
           0x00, 0x7f, 0x00, 0x3e, 0x00, 0x3e, 0x00, 0x1c, 0x00,
           0x1c, 0x00, 0x08, 0x00, 0x08
       };
        }
        image create bitmap bcwa -data $cwa
    
        set acwa "#define acwa_width 16\n#define acwa_height 16"
        append acwa {
        static unsigned char acwa_bits[] = {
           0x00, 0x00, 0x00, 0x06, 0x80, 0x19, 0x40, 0x20, 0x20,
           0x40, 0x10, 0x80, 0x10, 0x00, 0x10, 0x00, 0xff, 0x01,
           0xfe, 0x00, 0x7c, 0x00, 0x7c, 0x00, 0x38, 0x00, 0x38,
           0x00, 0x10, 0x00, 0x10, 0x00
           };
        }
        image create bitmap bacwa -data $acwa

        frame $h.int
        button $h.int.ic -image bacwa -padx 2 -pady 2\
            -command "Pal::interpolate_colour $wid $c.can clockwise"
        button $h.int.ia -image bcwa -padx 2 -pady 2\
            -command "Pal::interpolate_colour $wid $c.can anticlockwise"
        button $h.cp -text copy -padx 2 -pady 2\
            -command "Pal::copyColours $wid"
        button $h.p -text paste -padx 2 -pady 2\
            -command "Pal::pasteColours $wid $c.can"
        label $h.l0 -text "hue/saturation" -anchor center
        canvas $h.hs -width 120 -height 100
        nap "backgroundColour = {[winfo rgb $h.hs [$h.hs cget -background]]}"
        nap "white = {[winfo rgb $h.hs white]}"
        nap cw = "color_wheel(100, 255, 255.0 * backgroundColour / white)"
        set imageName [image create photo -format NAO -data $cw]
        unset cw
        $h.hs create image 10 0 -image $imageName -anchor nw
#        $h.hs create oval 20 10 100 90 -width 1
        bind $h.hs <Button-1> "Pal::hueSaturation $wid %W %y %x"

        pack $h.int.ic $h.int.ia -side left

        set sl 128
        set sw 4
        scale $h.sv -from 0 -to 255 -length $sl -variable Pal::${wid}::value \
                -orient horizontal -width $sw\
                -showvalue true -troughcolor black
        

        grid $h.in -row 0 -column 0 -sticky w -padx 4 -pady 4
        grid $h.int -row 0 -column 1 -sticky w -padx 4 -pady 4
        grid $h.cp -row 1 -column 0 -sticky news -padx 4 -pady 4
        grid $h.p -row 1 -column 1 -sticky news -padx 4 -pady 4
        grid $h.l0 -row 2 -column 0 -columnspan 2 -sticky news
        grid $h.hs -row 3 -column 0 -columnspan 2 -sticky news
        grid $h.sv -row 4 -column 0 -columnspan 2 -sticky news
#
# Set the length of the colour sliders
# Note that the colour quantisation depends on the slider
# length. Choose 256 for every value
#
        set sl 128
        set sw 4
        scale $s.sr -from 255 -to 0 -length $sl -variable Pal::${wid}::red \
                -orient vertical -width $sw\
                -showvalue false -troughcolor red
        scale $s.sg -from 255 -to 0 -length $sl -variable Pal::${wid}::green \
                -orient vertical -width $sw\
                -showvalue false -troughcolor green
        scale $s.sb -from 255 -to 0 -length $sl -variable Pal::${wid}::blue \
                -orient vertical -width $sw\
                -showvalue false -troughcolor blue

        label $s.il -text indx -anchor w
        label $s.h -text H -anchor w
        label $s.s -text S -anchor w
        label $s.v -text V -anchor w
        entry $s.r -width 3 -textvariable Pal::${wid}::red -foreground red
        entry $s.g -width 3 -textvariable Pal::${wid}::green -foreground green
        entry $s.b -width 3 -textvariable Pal::${wid}::blue -foreground blue
        entry $s.eh -width 3 -textvariable Pal::${wid}::hue
        entry $s.es -width 8 -textvariable Pal::${wid}::saturation
        entry $s.ev -width 3 -textvariable Pal::${wid}::value
        
        bind $s.sr <ButtonRelease-1> "Pal::changeColour $wid $c.can"
        bind $s.sr <ButtonRelease-2> "Pal::changeColour $wid $c.can"
        bind $s.sg <ButtonRelease-1> "Pal::changeColour $wid $c.can"
        bind $s.sg <ButtonRelease-2> "Pal::changeColour $wid $c.can"
        bind $s.sb <ButtonRelease-1> "Pal::changeColour $wid $c.can"
        bind $s.sb <ButtonRelease-2> "Pal::changeColour $wid $c.can"
        bind $h.sv <ButtonRelease-1> "Pal::changeColour $wid $c.can 0"
        bind $h.sv <ButtonRelease-2> "Pal::changeColour $wid $c.can 0"

        bind $s.eh <KeyRelease> "Pal::changeColour $wid $c.can 0"
        bind $s.es <KeyRelease> "Pal::changeColour $wid $c.can 0"
        bind $s.ev <KeyRelease> "Pal::changeColour $wid $c.can 0"
        
        bind $s.r <KeyRelease> "Pal::changeColour $wid $c.can"
        bind $s.g <KeyRelease> "Pal::changeColour $wid $c.can"
        bind $s.b <KeyRelease> "Pal::changeColour $wid $c.can"

        pack $c.can -side top
        pack $c.sel -side top
        grid $s.sr $s.sg $s.sb -sticky news
        grid $s.r $s.g $s.b -sticky news -padx 2 -pady 2
        grid $s.h $s.v
        grid $s.eh $s.ev
        grid $s.s -row 7 -column 0
        grid $s.es -row 7 -column 1 -columnspan 2 

#        pack $s.sr $s.sg $s.sb -side left
         grid $p $h $s $c -sticky nw -padx 4 -pady 4
#        pack $p $s $c -side left 
        
        bind $c.can <Button-1> "Pal::chipSelect $wid %x %y %W 1" 
        bind $c.can <Button-2> "Pal::chipSelect $wid %x %y %W 2" 
        bind $c.can <Button-3> "Pal::chipSelect $wid %x %y %W 3" 
        
        set ilist ""
        for {set i 0} {$i < $ncolours} {incr i} { 
           lappend ilist $i 
        }
        Pal::init_pal $wid $c.can 20 10 $ilist
#
# Initialise the colours
#
        set indexEnd [expr $ncolours-1]
        foreach index [list 0 $indexEnd] {
            set col [list 255 100 100]
            Pal::addChip $wid $c.can $index $col 0
        }
#
        Pal::interpolate_colour $wid $c.can clockwise 
    
    }

#
# Now create the namespace Pal in which all the supporting
# proceedures reside.
#
namespace eval Pal {
    variable frame_id 0;

#
# create_window--
#
# Create a unique toplevel window name of the form
#     .pal<n>, n=0,1,2,3,4,5..
#
# Note that n is never reset
# 
#
    proc create_window { geometry parent } { 

        set all ".pal$Pal::frame_id"
        incr Pal::frame_id
	set parent [string trim $parent]
	if {$parent != ""  &&  $parent != "."} {
	    set all $parent$all
	}
	destroy $all
	if {$parent == ""} {
	    toplevel $all
	    eval wm geometry $all $geometry
	    wm title $all "Palette $all"
	} else {
	    frame $all -relief raised -borderwidth 4
	    pack $all
	}
        return $all
    }

#
# init_pal--
#
# Initialise the palette colours
#

    proc init_pal {wid c xorigin yorigin indexList} {

        global Pal::${wid}::localIndexList
        global Pal::${wid}::ncolumn
        global Pal::${wid}::ncolours
        global Pal::${wid}::nrow
        global Pal::${wid}::nel
        global Pal::${wid}::wrow
        global Pal::${wid}::wcol
        global Pal::${wid}::xo
        global Pal::${wid}::yo
        global Pal::${wid}::selection
        global Pal::${wid}::selection2
        global Pal::${wid}::width
        global Pal::${wid}::height
        global Pal::${wid}::directory

        set xo $xorigin
        set yo $yorigin
        set directory [pwd]
    
        set localIndexList $indexList
        set selection ""
        set selection2 ""

        set nel [llength $localIndexList]
        set ncolumn 16
        if {$nel <= 16} {
            set ncolumn 4
        } elseif {$nel <= 64} {
            set ncolumn 8
        }
        set nrow [expr $nel/$ncolumn]
        if {[expr $nrow*$ncolumn] < $nel} {
            incr nrow
        }
        set wrow [expr ($height - $yo)/$nrow]
        set wcol [expr ($width - $xo)/$ncolumn]
        if {$wrow < $wcol} {
            set wcol $wrow
        }
        if {$wcol < $wrow} {
            set wrow $wcol
        }
    } 

#
# changeNcolours--
#
# Change the number of colours
#
    proc changeNcolours {wid can} {

        global Pal::${wid}::ncolours
        global Pal::${wid}::newncolours
        global Pal::${wid}::selection
        global Pal::${wid}::selection2
       
        if {$newncolours <= 0} {
            set newncolours $ncolours
        }
        if {$newncolours > 256} {
            set newncolours 256
        }
        if {$ncolours != $newncolours} {
#
# Clear selections
#
            if {$selection != ""} {
                set col [set Pal::${wid}::colours($selection)]
                Pal::addChip $wid $can $selection $col 0
                set selection "" 
            }
            if {$selection2 != ""} {
                set col [set Pal::${wid}::colours($selection2)]
                Pal::addChip $wid $can $selection2 $col 0
                set selection2 "" 
            }
#
# WARNING Needs to be derived from canvas
#
# Correction made
#
            set endIndex [expr [string length $can] - 4]
            set sel [string range $can 0 $endIndex]sel
            $sel configure -text "select colour cell"
#           .pal${wid}.c.sel configure -text "select colour cell"
#
# If we want less colours then we just delete
# the ones we do not want
#
            if {$ncolours > $newncolours} {
                for {set i $newncolours} {$i < $ncolours} {incr i} {
                    Pal::delChip $wid $can $i
                }
            } else {
#
# More colours - add them with the same colour as the last colour
#
                set last [expr $ncolours - 1]
                set col [set Pal::${wid}::colours($last)]
                set lastColour $col
                for {set i $ncolours} {$i < $newncolours} {incr i} {
                    Pal::addChip $wid $can $i $lastColour 0
                }
            }
            set ncolours $newncolours
        }    
    }

#
# copyColours--
#
# copy the colurs between the selection points
#
    proc copyColours {wid} {

        global Pal::${wid}::tmpCol
        global Pal::${wid}::selection
        global Pal::${wid}::selection2
#
# Get rid of any previous saved colours
#
        if [array exists tmpCol] {
            unset tmpCol
        }
#
# Get the selection range
#
        if {"$selection" == ""} {
            return
        }
        set indx0 $selection
#
# We may only have one colour selected
#
        if {"$selection2" == ""} {
            set col [set Pal::${wid}::colours($indx0)] 
            set tmpCol(0) $col
        } else {
            set indx1 $selection2
            if {$indx1 < $indx0} {
                set tmp $indx0
                set indx0 $indx1
                set indx1 $tmp
            }
            set j 0
            for {set i $indx0} {$i <= $indx1} {incr i} {
                set col [set Pal::${wid}::colours($i)] 
                set tmpCol($j) $col
                incr j
            }
        }
    }
#
# pasteColours--
#
# paste the colours between the selection points
#
    proc pasteColours {wid can} {

        global Pal::${wid}::tmpCol
        global Pal::${wid}::selection
        global Pal::${wid}::ncolours
        global Pal::${wid}::localIndexList
#
# find out if there are any colours saved!
#
        if [array exists tmpCol] {
            set size [array size tmpCol]
            set start $selection
            set stop [expr $start + $size]
            if {$stop > $ncolours} {
                set stop $ncolours
            }
            set sel 1
            set j 0 
            for {set i $start} {$i < $stop} {incr i} {
                Pal::addChip $wid $can [lindex $localIndexList $i] $tmpCol($j) $sel
                incr j
                set sel 0
            } 
        }
    }

#
# hueSaturation--
#
# Event driven proceedure to modify hue and
# saturation acccording to position in colour 
# wheel.
#
    proc hueSaturation {wid w yc xc} {

        global Pal::${wid}::hue
        global Pal::${wid}::saturation

#
# Correct for center of colour wheel
#
        set x [expr $xc - 60]
        set y [expr 49 - $yc] 
        set wrad 50.0
        set radius [expr sqrt($y*$y + $x*$x)]
#
# Do nothing unless the radius is less than
# wrad
#
        if {$radius <= $wrad} {
            set saturation [expr $radius/$wrad]
            if {$y == 0} {
                set hue 0
                if {$x < 0} {
                    set hue 180
                }
                if {$x == 0} {
                    set hue "u"
                }
            } else {
                if {$x != 0} {
                    set hue [expr round(57.29577951*atan(double($y)/$x))]
                }
                if {$x < 0} {
                    set hue [expr 180 + $hue]
                }
                if {$hue < 0} {
                    set hue [expr 360 + $hue]
                }
            }
#
# Force a colour change
#
# WARNING HARD CODED CANVAS NAME
#
# Correction made!
#
            set endIndex [expr [string length $w] - 7]
            set sel [string range $w 0 $endIndex]c.can
            Pal::changeColour $wid $sel 0
#            Pal::changeColour $wid .pal${wid}.c.can 0
        }
    }
#
# limitHSV--
#
# Make sure HSV values are sensible
#
proc limitHSV {wid} {

    global Pal::${wid}::hue
    global Pal::${wid}::saturation
    global Pal::${wid}::value

    if {$hue != "u"} {
        if {$hue < 0} {
            set hue 0
        }
        if {$hue > 360} {
            set hue 360
        }
    }
    if {$saturation < 0} {
        set saturation 0
    }
    if {$saturation > 1} {
        set saturation 1
    }
    if {$value < 0} {
        set value 0
    }
    if {$value > 255} {
        set value 255
    }
}

#
#  interpolate_colour--
#
# Given a start selection and an end selection interpolate
# colours around the colour wheel. This operation is
# performed by converting the colours to HSV and then
# moving around the Hue direction in equal increments
# to generate the intermmediate colours.
#
    proc interpolate_colour {wid c direction} {

        global Pal::${wid}::selection
        global Pal::${wid}::selection2
        global Pal::${wid}::localIndexList
        global Pal::${wid}::ncolours

        set indx0 0
        set indx1 [expr $ncolours-1]
        if {"$selection" != ""} {
            set indx0 $selection
        }
        if {"$selection2" != ""} {
            set indx1 $selection2
        }
#
# Calculate the number of divisions between the
# start and end points
#
        if {$indx0 > $indx1} {
            set tmp $indx0
            set indx0 $indx1
            set indx1 $tmp
            unset tmp
        }
        set ndiv [expr $indx1 - $indx0]
#
# We cannot interpolate one chip
#
        if {$ndiv <= 0} {
            return
        }
        set col [set Pal::${wid}::colours($indx0)]
        set hsv [rgbtohsv $col]
        set col [set Pal::${wid}::colours($indx1)]
        set hsv2 [rgbtohsv $col]
        set s [lindex $hsv 1]
        set s2 [lindex $hsv2 1]
        set sinc [expr double($s2 - $s)/$ndiv]
        set h [lindex $hsv 0]
        set h2 [lindex $hsv2 0]
        if {$h == "u" && $h2 != "u"}  {
            set h $h2
        }
        if {$h2 == "u" && $h != "u"}  {
            set h2 $h
        }
        if {$h != "u"} {
            set hdiff [expr double($h2 - $h)]
            if {$direction == "clockwise" && $hdiff <= 0.0} {
                set hdiff [expr 360 + $hdiff]
            } 
            if {$direction == "anticlockwise" && $hdiff > 0.0} {
                set hdiff [expr $hdiff - 360]
            } 
            set hinc [expr $hdiff/$ndiv]
        } else {
            set hinc 0
        }
        set start [expr $indx0 + 1]
        set v [lindex $hsv 2]
        set v2 [lindex $hsv2 2]
        set vinc [expr double($v2 - $v)/$ndiv]

        set hf $h
        set vf $v
        for {set i $start} {$i < $indx1} {incr i} {
            if {$h != "u"} {
                set hf [expr $hf + $hinc] 
                if {$hf > 360.0} {
                    set hf 0
                }
                if {$hf < 0} {
                    set hf [expr $hf + 360]
                }
                set h [expr int($hf)]
            }
            set s [expr $s + $sinc] 
            set vf [expr $vf + $vinc] 
            set v [expr int($vf)]
            set Pal::${wid}::colours($i) [hsvtorgb [list $h $s $v]]
            set col [set Pal::${wid}::colours($i)]
#
# Draw the colour chip in the new colour
#
            Pal::addChip $wid $c [lindex $localIndexList $i] $col 0
        }

    }
#
# addChip--
#
# Given a canvas, index and colour draw the requisit chip
#
    proc addChip {wid c index col select} {

        global Pal::${wid}::localIndexList
        global Pal::${wid}::ncolumn
        global Pal::${wid}::ncolours
        global Pal::${wid}::nrow
        global Pal::${wid}::nel
        global Pal::${wid}::wrow
        global Pal::${wid}::wcol
        global Pal::${wid}::xo
        global Pal::${wid}::yo
        global Pal::${wid}::rectId
    
        set indexIndex [lsearch $localIndexList $index]
        if {$indexIndex < 0} return
        set row [expr $indexIndex/$ncolumn]
        set column [expr $indexIndex - $row*$ncolumn]
    
        set xpos [expr $xo + $wcol*$column]
        set ypos [expr $yo + $wrow*$row]
#
# If this chip is already defined then delete it before
# writing a new one
#
        Pal::delChip $wid $c $index
        set Pal::${wid}::colours($index) $col
#
# draw a new chip
#
        set rectId($index) [Pal::drawChip $c $xpos $ypos $wcol $wrow $col $select]

    }

#
# delChip--
#
# Delete the colour chip at index position
#
# c		canvas
# index		chip index
#
    proc delChip {wid c index} {

        global Pal::${wid}::rectId

        if [info exists rectId($index)] {
            $c delete rect $rectId($index)
            unset rectId($index)
            unset Pal::${wid}::colours($index)
        }
    }

#
# Namespace independent routines


#
# drawChip--
#
# Draw a colour chip on a canvas with specified
# size at a specified position.
#
# c		canvas
# x		x position (left)
# y		y position (top)
# xs		x size
# ys		y size
# col		colour of the chips "r g b"
# select	highlight border colour
#
# When the colour chip is created an id for the chip
# is returned by the proceedure.
#
# Author Peter Turner CSIRO Atmospheric Research 1999-2000
#
    proc drawChip {c x y xs ys col select} {

        set red [Pal::dtoh [lindex $col 0]]
        set green [Pal::dtoh [lindex $col 1]]
        set blue [Pal::dtoh [lindex $col 2]]
        set hcol "#$red$green$blue"
    
        set xh [expr $x + $xs]
        set yh [expr $y + $ys]
        set oc black
        if {$select > 0} {
           set oc white
        }
    
        set id [$c create rect $x $y $xh $yh -fill $hcol -outline $oc]
        return $id
    }
#
# dtoh--
#
# Awful routine to convert decimal to hexadecimal
#
    proc dtoh {decimal} {
    
        set hex [list 0 1 2 3 4 5 6 7 8 9 a b c d e f]
        set high [expr $decimal/16]
        set low  [expr $decimal - $high*16]
    
        return [lindex $hex $high][lindex $hex $low]
    }




#
# chipSelect--
#
# Select a particular chip.
#
    proc chipSelect {wid x y W n} {
#
# x = x position
# y = y position
# W is the window id
# n is the mouse button
#
        global Pal::${wid}::localIndexList
        global Pal::${wid}::ncolumn
        global Pal::${wid}::ncolours
        global Pal::${wid}::nrow
        global Pal::${wid}::nel
        global Pal::${wid}::wrow
        global Pal::${wid}::wcol
        global Pal::${wid}::xo
        global Pal::${wid}::yo
        global Pal::${wid}::rectId
        global Pal::${wid}::hue
        global Pal::${wid}::saturation
        global Pal::${wid}::value
        global Pal::${wid}::selection
        global Pal::${wid}::selection2
        global Pal::${wid}::red
        global Pal::${wid}::green
        global Pal::${wid}::blue
#
# Calculate chip index
#
        set nx [expr $x - $xo]
        set ny [expr $y - $yo]
        set row [expr $ny/$wrow]
        set col [expr $nx/$wcol]
#
# Check that we have not gone out of range
# in the x dimension
#
        if {$col >= 0 && $col < $ncolumn} {
            set el [expr $row *$ncolumn + $col]
            if {$el < 0 || $el >= $nel} {
                set index -1
            } else {
                set index [lindex $localIndexList $el]
            }
        } else {
            set index -1
        }
#
# If the index is sensible then change the selection
#
        if {$index >= 0 && $index < $ncolours} {
            if {$n == 1} {
#
# deselect the old chip
#
                if {$selection != ""} {
                    set col [set Pal::${wid}::colours($selection)]
                    Pal::addChip $wid $W $selection $col 0
                }
#
# Select the new chip
#
                set col [set Pal::${wid}::colours($index)]
                Pal::addChip $wid $W $index $col 1
                set selection $index
                if {$selection2 != ""} {
                    set col [set Pal::${wid}::colours($selection2)]
                    Pal::addChip $wid $W $selection2 $col 0
                    set selection2 ""
                }
            } else {
#
# Deal with selection 2
#
                if {$selection2 != ""} {
                    set col [set Pal::${wid}::colours($selection2)]
                    Pal::addChip $wid $W $selection2 $col 0
                }
                set col [set Pal::${wid}::colours($index)]
                Pal::addChip $wid $W $index $col 1
                set selection2 $index
            }
#
# bindings on these parameters should cause the scale to reset
#
            set col [set Pal::${wid}::colours($index)]
            set red [lindex $col 0]
            set green [lindex $col 1]
            set blue [lindex $col 2]
#
# Calculate corresponding HSV and reset too!
#
            set hsv [rgbtohsv $col]
            set hue [lindex $hsv 0]
            set saturation [lindex $hsv 1]
            set value [lindex $hsv 2]
#
# Report selection values
#
            set s $selection
            if {"$s" == ""} {
                set s "  "
            }
            if {"$selection2" == ""} {
                set selText "select $s"
            } else {
                set selText "select $s to $selection2"
            }
#
# Have fixed this!
#
             set endIndex [expr [string length $W] - 4]
             set sel [string range $W 0 $endIndex]sel
             $sel configure -text $selText
#            .pal${wid}.c.sel configure -text $selText
        }
    }

#
# changeColour--
#
# Changes the colour of a chip given 
#
    proc changeColour {wid c {rgb 1}} {

        global Pal::${wid}::hue
        global Pal::${wid}::saturation
        global Pal::${wid}::value
        global Pal::${wid}::selection
        global Pal::${wid}::selection2
        global Pal::${wid}::red
        global Pal::${wid}::green
        global Pal::${wid}::blue

        if {$rgb == "1"} {
            set colour [list $red $green $blue]
            set hsv [rgbtohsv $colour]
            set hue [lindex $hsv 0]
            set saturation [lindex $hsv 1]
            set value [lindex $hsv 2]
        } else {
#
# Make sure the values are OK
#
            Pal::limitHSV $wid 
            set colour [hsvtorgb [list $hue $saturation $value]]
            set red [lindex $colour 0]
            set green [lindex $colour 1]
            set blue [lindex $colour 2]
        }

        if {$selection != ""} {
            if {$selection2 != ""} {
                Pal::addChip $wid $c $selection2 $colour 1
            } else {
                Pal::addChip $wid $c $selection $colour 1
            }
        }
  
    }

        
proc loadPal {wid can} {

    global Pal::${wid}::file
    global Pal::${wid}::directory
    global Pal::${wid}::ncolours
    global Pal::${wid}::newncolours
    global Pal::${wid}::selection
    global Pal::${wid}::selection2
    global Pal::${wid}::localIndexList

#
# If the file name is not defined then use the
# tk widget to define the file name. Note that
# we redefine the directory and file according to
# what we did in the Tk widget
#
    if {"$file" == ""} {
        set typelist {
            {"palette file" {".pal"}}
        }
        set nfile [tk_getOpenFile -defaultextension ".pal"\
           -initialdir $directory -filetypes $typelist]
        set path [split $nfile /]
        set nels [llength $path]
        set file [lindex $path end]
        set directory [join [lrange $path 0 [expr $nels - 2]] /]
    }
#
    cd $directory 
    if {"$file" != ""} {
        set indices [array names Pal::${wid}::colours]
        foreach index $indices {
            Pal::delChip $wid $can $index
        }
        array set Pal::${wid}::colours [read_pal $file]
        set indices [array names Pal::${wid}::colours]
        set selection ""
        set selection2 ""
        foreach index $indices {
            set sel 0
            set col [set Pal::${wid}::colours($index)]
            Pal::addChip $wid $can $index $col $sel
        }
        set ncolours [array size Pal::${wid}::colours]
        set newncolours $ncolours
#
# Change the text message
#
        set endIndex [expr [string length $can] - 4]
        set sel [string range $can 0 $endIndex]sel
        $sel configure -text "select colour cell"
    }
}
#
# save_pal--
#
# Save the palette as a file
#
proc save_pal {wid dir lfile} {

    cd $dir
    if {$lfile == ""} {
        set typelist {
            {"palette file" {".pal"}}
        }
        set lfile [tk_getSaveFile -defaultextension ".pal" -filetypes $typelist]
    }
    
    write_pal $lfile Pal::${wid}::colours

}
#
# writeNAO--
#
# Write the colour table to a NAO
#
proc writeNAO {wid {name palette}} {

    global Pal::${wid}::ncolour

    set indices [array names Pal::${wid}::colours]
    if {"$name" == ""} {
        set name palette
    }

    set elements ""
    foreach index $indices {
        set col [set Pal::${wid}::colours($index)]
        lappend elements "$index $col"
    }
    set elements [lsort -index 0 -integer -increasing  $elements]
    uplevel #0 "nap \"$name = {$elements}\""
}

# helpPal--
#
# destroyu the window and associated data
#
proc helpPal {wid win} {

set help "Functions
 - can manipulate a palette of 1 to 256 colours
 - can interpolate a sequence of colours around
   the colour wheel in constant saturation
 - can copy colour sequences
 - can save and retrieve colours from file
 - can write colours into a NAO
 - can interact with other proceedures

Changing a single colour 
 - left click on the colour cell to be changed
 - the cell will be highlighted with a white border
 - use the sliders, entry boxes and colour wheel
   to select a new colour

Changing a sequence of colours
 - select and set the colour of the start cell
 - middle or right click on the end cell
 - use sliders, entry boxes and colour wheel
   to set the end colour
 - left click on the clockwise or anti-clockwise
   arrow buttons to interpolate colours between
   cells.

Copying a colour sequence
 - select a cell sequence using left and right
   mouse clicks
 - left click on the copy button
 - left click on the start cell to copy to
 - left click on the paste button"
    
   message_window $help

}
#
# destroyPal--
#
# destroyu the window and associated data
#
proc destroyPal {wid win} {

    destroy $win
#
# Get rid of all the associated namespace variables
#
    namespace delete ::Pal::${wid}::
}
#
#
# End of Namespace
#
}


