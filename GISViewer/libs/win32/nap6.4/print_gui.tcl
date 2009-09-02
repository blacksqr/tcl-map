# print_gui.tcl --
# 
# Copyright (c) 2002, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: print_gui.tcl,v 1.9 2004/06/04 02:10:31 dav480 Exp $
#
# GUI for printing
# If under Unix then use standard commands 'lp' (or 'lpr'), lpstat.
# If under MS-Windows then use package 'ezprint'.
#
# Usage
#
#   ::Print_gui::init
#	Must be called at start
#
#   ::Print_gui::widget <COMMAND> <PARENT>
#	Main procedure which creates widget, etc.
#       <COMMAND>: command to create postScript string
#           This command returns postScript string as result & is called as follows:
#               eval <COMMAND> <PAPER_HEIGHT> <PAPER_WIDTH> <MAXPECT>
#                   <PAPER_HEIGHT>: e.g. "297m" (mm) for A4
#                   <PAPER_WIDTH>:  e.g. "210m" (mm) for A4
#                   <MAXPECT>: 1 = expand/contract to fit page
#       <PARENT>: parent window (default: ".")
#
#   ::Print_gui::print <COMMAND>
#	Allows printing without using GUI (useful for batch mode)
#
#   ::Print_gui::write <COMMAND>
#	Allows writing of postScript to file without using GUI (useful for batch mode)

namespace eval Print_gui {

    variable filename "tmp.ps";	# name of output postScript file
    variable maxpect 0;		# Expand PostScript to fit page?
    variable paperheight 297m;	# A4
    variable paperwidth  210m;	# A4
    variable printer_name "";	# Printer which is currently selected


    # init --
    #
    # Create namespace 'Print_gui'.
    # If Windows then load ezprint.
    # Define ::Print_gui::printer_name.
    # Return 0 if OK, 1 if no ezprint under Windows.

    proc init {
    } {
	global ::Print_gui::printer_name
	set result 0
	switch $::tcl_platform(platform) {
	    unix {
		if {$printer_name eq ""} {
		    if {[lsearch [array names ::env] PRINTER] >= 0} {
			set printer_name $::env(PRINTER)
		    } else {
			if {[catch {exec lpstat -d} str] == 0} {
			    set printer_name [lindex $str end]
			}
		    }
		}
	    }
	    windows {
		if {[catch {package require Ezprint}]} {
		    set result 1
		} else {
		    if {$printer_name eq ""} {
			set printer_name [ezprint defaultprinter]
		    }
		}
	    }
	    default {
		error "::Print_gui::init. Unsupported platform"
	    }
	}
	return $result
    }


    # list_printers --
    #
    # List of available printers

    proc list_printers {
    } {
	set result ""
	switch $::tcl_platform(platform) {
	    unix {
		if {[catch {exec lpstat -a} str] == 0} {
		    set result [split [regsub -all -line { .*$} $str ""]]
		}
	    }
	    windows {
		set result [ezprint listprinters]
	    }
	    default {
		error "::Print_gui::list_printers. Unsupported platform"
	    }
	}
	return $result
    }


    # widget --

    proc widget {
	create_ps_command
	{parent .}
    } {
	if {$parent == "."} {
	    set f .print
	} else {
	    set f $parent.print
	}
	destroy $f
	toplevel $f -relief raised -borderwidth 4
	wm geometry $f +[winfo rootx $parent]+[winfo rooty $parent]
	#
	label $f.width_label -text "paper width"
	entry $f.width_entry -textvariable ::Print_gui::paperwidth
	grid x $f.width_label $f.width_entry -sticky we
	#
	label $f.height_label -text "paper height"
	entry $f.height_entry -textvariable ::Print_gui::paperheight
	grid x $f.height_label $f.height_entry -sticky we
	#
	checkbutton $f.scale -text "Scale to fill page?" \
		-variable ::Print_gui::maxpect -anchor w
	grid $f.scale -column 1 -sticky we
	#
	button $f.select_printer_button -text "select printer" \
		-command "::Print_gui::select_printer $parent $f"
	grid $f.select_printer_button -sticky we
	#
	button $f.print_button -text print -command "::Print_gui::print $create_ps_command"
	label $f.print_label -text "using printer "
	entry $f.printer -textvariable ::Print_gui::printer_name
	grid $f.print_button $f.print_label $f.printer -sticky we
	#
	button $f.write_button -text write -command "::Print_gui::write $create_ps_command"
	label $f.write_label -text "PostScript file named "
	entry $f.write_file -textvariable ::Print_gui::filename
	grid $f.write_button $f.write_label $f.write_file -sticky we
	#
	button $f.cancel -text cancel -command "destroy $f"
	grid $f.cancel -sticky we
    }


    # select_printer --

    proc select_printer {
	parent
	f
    } {
	set printers [list_printers]
	if {[llength $printers] == 0} {
	    error "::Print_gui::select_printer. No known printers"
	} else {
	    if {$parent == "."} {
		set m .printer_menu
	    } else {
		set m $parent.printer_menu
	    }
	    if {![winfo exists $m]} {
		menu $m -tearoff 0 -background white
		foreach p $printers {
		    $m add radiobutton -label $p -value $p \
			    -variable ::Print_gui::printer_name
		}
	    }
	    set x [winfo rootx $f]
	    set y [winfo rooty $f]
	    tk_popup $m $x $y
	}
    }


    # print --
    #
    # Send postScript to printer

    proc print {
	args
    } {
	global ::Print_gui::maxpect
	global ::Print_gui::paperwidth
	global ::Print_gui::paperheight
	global ::Print_gui::printer_name
	if {[lsearch -exact [list_printers] $printer_name] < 0} {
	    error "::Print_gui::print_graph. Illegal printer name"
	} else {
	    switch $::tcl_platform(platform) {
		unix {
		    if {[catch {open "| lp -d $printer_name" w} channel]} {
			if {[catch {open "| lpr -P $printer_name" w} channel]} {
			    error "::Print_gui::print. Unable to execute lp or lpr"
			}
		    }
		}
		windows {
		    set channel [ezprint open $printer_name]
		}
		default {
		    error "::Print_gui::print. Unsupported platform"
		}
	    }
	}
	fconfigure $channel -translation binary
	puts -nonewline $channel [eval [join $args] $paperheight $paperwidth $maxpect]
	close $channel
    }


    # write --
    #
    # Write postScript to file

    proc write {
	args
    } {
	global ::Print_gui::filename;		# name of output postScript file
	global ::Print_gui::maxpect
	global ::Print_gui::paperwidth
	global ::Print_gui::paperheight
	if {$filename ne ""} {
	    set f [open $filename w]
	    puts -nonewline $f [eval [join $args] $paperheight $paperwidth $maxpect]
	    close $f
	} else {
	    error "::Print_gui::write. Filename for output PostScript is not defined"
	}
    }


    # canvas2ps --
    #
    # create postScript from canvas

    proc canvas2ps {
	can
	border
	image_height
	image_width
	paperheight
	paperwidth
	maxpect
    } {
	if {$image_height == 0} {
	    set image_height [$can cget -height]
	}
	if {$image_width == 0} {
	    set image_width [$can cget -width]
	}
	set paper_border [expr 2.0 * [winfo fpixels . $border]]
	set paper_height [expr [winfo fpixels . $paperheight] - $paper_border]
	set paper_width  [expr [winfo fpixels . $paperwidth]  - $paper_border]
	set is_landscape [expr $image_width > $image_height]
	if {$is_landscape} {
	    set tmp $paper_height
	    set paper_height $paper_width
	    set paper_width $tmp
	}
	if {$maxpect} {
	    if {$image_height/$image_width > $paper_height/$paper_width} {
		set pageheight $paper_height
		set pagewidth [expr $pageheight * $image_width / $image_height]
	    } else {
		set pagewidth $paper_width
		set pageheight [expr $pagewidth * $image_height / $image_width]
	    }
	    set pageheight "[expr $pageheight / [winfo fpixels . 1m]]m"
	    set pagewidth  "[expr $pagewidth  / [winfo fpixels . 1m]]m"
	    $can postscript -rotate $is_landscape -pageheight $pageheight -pagewidth $pagewidth
	} else {
	    $can postscript -rotate $is_landscape
	}
    }

}
