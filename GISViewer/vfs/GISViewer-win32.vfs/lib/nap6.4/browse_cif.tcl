# browse_cif.tcl --
#
# GUI for browsing CIF files.
#
# Copyright (c) 2003, CSIRO Australia
#
# Author:
# Harvey Davies, CSIRO Atmospheric Research
#
# $Id: browse_cif.tcl,v 1.4 2005/09/29 02:48:34 dav480 Exp $


# browse_cif --
#
# Create window with browse_cif menu, etc.
# Usage
#   browse_cif ?<PARENT>? ?<GEOMETRY>?
#
# Example
#   browse_cif .

proc browse_cif {
    args
} {
    eval ::Cif::main $args
}

namespace eval ::Cif {
    # main --
    #
    # Create window with browse_cif menu, etc.

    proc main {
	{parent {}}
	{geometry ""}
    } {
	set top [create_window cif $parent $geometry "CIF Browser"]
	set top_ns ::Cif::t[string map {. _} $top]; # top namespace
	namespace eval $top_ns {
	    variable filename ""
	    variable is_current 0;	# 1 means nao is up-to-date
	    variable is_geog 1;		# Is geographic mode?
	    variable mv -7777777;	# missing value
	    variable nao "";		# points to NAO
	}
	trace add variable ${top_ns}::filename write "::Cif::need_read $top_ns $top"
	set ${top_ns}::filename {}
        frame $top.head
        button $top.head.help -text "Help" -command {::Cif::help}
	button $top.head.cancel -text Cancel -command "destroy $top"
        pack $top.head.cancel $top.head.help -side right
	create_file_gui $top_ns $top $top.file cif
	grid $top.head  -sticky ew
	grid $top.file  -sticky ew
	bind $top.file <Enter> "destroy $top.tail"
	bind $top <Destroy> "::Cif::close_window $top_ns %W $top"
    }


    # close_window --
    #
    # Delete namespace associated with top-level window
    # Note that this is called for all sub-windows as well, so must test for top-level

    proc close_window {
	top_ns
	w
	top
    } {
	if {[string equal $w $top]} {
	    namespace delete $top_ns
	}
    }


    # create_file_gui --
    #
    # Create the GUI for the filename

    proc create_file_gui {
	top_ns
	top
	win
	extension
    } {
	destroy $win
	::ChooseFile::choose_file_gui $win "::Cif::open_file $top_ns $top" "" *.$extension
    }


    # open_file --

    proc open_file {
	top_ns
	top
	{new_filename ""}
    } {
	global ${top_ns}::filename
	if {$new_filename eq ""  ||  $new_filename eq "."} {
	    ::Cif::warn "Filename is blank"
	} else {
	    if {[file readable $new_filename] && ![file isdirectory $new_filename]} {
		set filename $new_filename
		create_tail $top_ns $top $top.tail
	    } else {
		::Cif::warn "Unable to read file $new_filename"
	    }
	}
    }


    # create_tail --
    #
    # Create part of gui below file selection

    proc create_tail {
	top_ns
	top
	tail
    } {
	destroy $tail
	frame $tail
	checkbutton $tail.geog -text "Geographic (latitude/longitude) mode" \
	    -variable ${top_ns}::is_geog -anchor w
	frame $tail.mv
	label $tail.mv.label -text "Missing value" 
	entry $tail.mv.entry -relief sunken -bd 2 -background white -textvariable ${top_ns}::mv 
	pack $tail.mv.label -side left
	pack $tail.mv.entry -side left -expand true -fill x
	frame $tail.do; # All the buttons along the bottom of the menu
	button $tail.do.range -text "Range" -command "::Cif::range $top_ns"
	button $tail.do.text -text "Text" -command "::Cif::text $top_ns"
	button $tail.do.image -text "Image" -command "::Cif::image $top_ns $top"
	button $tail.do.nao -text "NAO" -command "::Cif::create_nao $top_ns $top"
	pack \
	    $tail.do.range \
	    $tail.do.text \
	    $tail.do.image \
	    $tail.do.nao \
	    -side left \
	    -fill x \
	    -expand true \
	    -padx 1 \
	    -pady 2
	pack $tail.geog  $tail.mv $tail.do -expand true -fill x
	grid $tail -sticky ew
    }


    # image --
    #
    # Handle image button

    proc image {
	top_ns
	top
    } {
	global ${top_ns}::nao
	set parent $top.do.image
	set w $parent.menu
	destroy $w
	if [read $top_ns] {
	    if {[$nao rank] > 2} {
		menu $w
		menu_entry $top_ns $w "pseudo-colour image" 2 z
		menu_entry $top_ns $w "tiled pseudo-colour image" 3 tile
		menu_entry $top_ns $w "RGB image" 3 z
		$w add command -label cancel -command "destroy $w"
		$w post [winfo rootx $parent] [expr [winfo rooty $parent] + [winfo height $parent]]
	    } elseif {[$nao rank] > 1} {
		draw_image $top_ns 2 z
	    } else {
		::Cif::warn "rank < 2"
	    }
	}
    }


    # menu_entry --
    #
    # add entry to graph or image menu
    # return 1 if entry added, else 0

    proc menu_entry {
	top_ns
	w
	label
	rank_image
	type
    } {
	global ${top_ns}::nao
	nap "i = rank(nao) - rank_image"
	set n [[nap "i < 0 ? 0 : prod((shape(nao))(0 .. (i-1) ... 1))"]]
	if {$n > 1} {
	    set label "$n ${label}s"
	}
	if {$n > 0} {
	    $w add command -label $label -command "::Cif::draw_image $top_ns $rank_image $type"
	    return 1
	}
	return 0
    }

    # warn --
    #
    # Warn user of error

    proc warn {
	message
    } {
	message_window $message -label "Error!" -wait 1
    }


    # create_nao --
    #
    # Create NAO with name specified by user

    proc create_nao {
	top_ns
	top
	{geometry SW}
    } {
	global ${top_ns}::filename
	global ${top_ns}::nao
	set name [file rootname [file tail $filename]]
	set name [regsub -all {[^_a-zA-Z0-9]} $name _]
	if [regexp {^[0-9]} $name] {
	    set name _$name
	}
	set name [get_entry "NAO name: " -text $name -width 40 -parent $top -geometry $geometry]
	if [read $top_ns] {
	    if {[catch "nap ::$name = nao"]} {
		::Cif::warn "Unable to create NAO"
	    } else {
		message_window "Created NAO $nao named '$name'"
	    }
	}
    }


    # need_read --
    #
    # Called by write trace on variable filename

    proc need_read {
	top_ns
	top
	args
    } {
	global ${top_ns}::is_current
	set is_current 0
	destroy $top.tail
    }


    # read --
    #
    # If !is_current then read variable from CIF file into nao
    # Return 1 if OK, 0 for error

    proc read {
	top_ns
    } {
	global ${top_ns}::filename
	global ${top_ns}::is_geog
	global ${top_ns}::is_current
	global ${top_ns}::mv
	global ${top_ns}::nao
	if {! $is_current} {
	    set command {nap "nao = [get_cif -g $is_geog -m $mv $filename]"}
	    set is_current [expr "! [catch $command]"]
	    if {! $is_current} {
		::Cif::warn "Unable to read CIF file"
	    }
	}
	return $is_current
    }


    # help --
    #
    # Display help.

    proc help {} {
	message_window \
	     "1. Select a file using the choose_file GUI (which has its own help button).\
	    \n\
	    \n2. Press the 'Open' button to open this file.\
	    \n\
	    \n3. Change to non-geographic mode if the coordinate variables are not \
		    latitude & longitude.\
	    \n\
	    \n4. Change the missing value if necessary.\
	    \n\
	    \n5. Use the buttons along the bottom to initiate the following actions:\
	    \n   'Range'  button: Display minimum and maximum value.\
	    \n   'Text'   button: Display start of data as text.\
	    \n   'Image'  button: Display data as image(s).\
	    \n   'NAO'    button: Create N-dimensional Array Object." \
	    -label "CIF help"
    }


    # draw_image --
    #
    # View CIF var using plot_nao

    proc draw_image {
	top_ns
	rank
	type
    } {
	global ${top_ns}::nao
	if [read $top_ns] {
	    if {[catch {plot_nao $nao -rank $rank -type $type} result]} {
		::Cif::warn "Error in plot_nao:\n $result"
	    }
	}
    }


    # range --
    #
    # Display range

    proc range {
	top_ns
    } {
	global ${top_ns}::filename
	global ${top_ns}::nao
	if [read $top_ns] {
	    if [catch {nap "r = range(nao)"} result] {
		::Cif::warn "Error in nap command:\n $result"
	    } else {
		message_window \
			"File: $filename \
			\nRange: [$r]" \
			-label range
	    }
	}
    }

    # text --
    #
    # Read variable from CIF file into nao & then use specified method for this nao

    proc text {
	top_ns
	{method "all"}
	{c_format ""}
	{max_cols ""}
	{max_lines ""}
    } {
	global ${top_ns}::filename
	global ${top_ns}::nao
	if [read $top_ns] {
	    if [regexp c8 [$nao datatype]] {
		default max_cols -1
		default max_lines -1
	    } else {
		default max_cols 50
		default max_lines 100
	    }
	    message_window \
		    "File: $filename \
		    \n[$nao $method -format $c_format -columns $max_cols -lines $max_lines]" \
		    -label data
	}
    }

}
