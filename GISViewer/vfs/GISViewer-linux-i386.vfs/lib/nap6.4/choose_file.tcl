# choose_file.tcl --
#
# GUI for user to choose input file
# Use by calling either choose_file or choose_file_gui 
#
# Copyright (c) 2003, CSIRO Australia
#
# Harvey Davies, CSIRO Atmospheric Research
#
# $Id: choose_file.tcl,v 1.14 2007/03/30 09:29:16 dav480 Exp $

namespace eval ChooseFile {
    variable count 0;		# Increment each time choose_file_gui is called 

    # choose_file --
    #
    # Create a new temporary GUI window & return pathname of input file.
    #
    # Usage:
    #   choose_file ?<PARENT>? ?<FILTER>? ?<GEOMETRY>?
    #	    <PARENT>: See create_window (default ".")
    #	    <FILTER>: Initial glob filter (default "*")
    #	    <GEOMETRY>: See create_window (default NW)

    proc choose_file {
	{parent "."}
	{filter "*"}
	{geometry NW}
    } {
	set save_grab [grab current]
	set win [create_window choose_file $parent $geometry]
	grab set $win
	set cf $win.cf
	set ns ::ChooseFile::ns${::ChooseFile::count};	# new namespace
	choose_file_gui $cf "destroy $win; set ${ns}::result" "destroy $win" $filter
	pack $cf -expand 1 -fill x
	tkwait window $win
	trace remove variable ::ChooseFile::dir    write "::ChooseFile::trace_dir $ns"
	trace remove variable ::ChooseFile::filter write "::ChooseFile::set_tail_values $ns"
	trace remove variable ::ChooseFile::tail   write "::ChooseFile::trace_tail $ns"
	grab release $win
	grab set $save_grab
	return [set ${ns}::result]
    }

    # choose_file_gui --
    #
    # Create GUI to allow user to choose input file.
    #
    # Usage:
    #   choose_file_gui <pathName> <openCommand> ?<cancelCommand>? ?<filter>?
    #	    <pathName>: Name of new GUI window
    #	    <openCommand>: Start of command executed when user presses "Open" button
    #	    <cancelCommand>: Command executed when user presses "Cancel" button (Default: no
    #		button)
    #	    <filter>: Initial glob filter (default "*")

    proc choose_file_gui {
	pathName
	openCommand
	{cancelCommand ""}
	{filter "*"}
	{font {-family Helvetica -size 10}}
    } {
	set ns ::ChooseFile::ns${::ChooseFile::count};	# new namespace
	incr ::ChooseFile::count
	namespace eval $ns {
	    variable dir "";		# directory
	    variable filter "";		# glob expression
	    variable result "";		# filename to be returned
	    variable tail "";		# filename within directory
	    variable top "";		# topmost window
	}
	global ${ns}::top
	set top $pathName
	frame $top -relief ridge -bd 2
	set open_command [list ::ChooseFile::open_file $ns $openCommand]
	set help_command [list ::ChooseFile::display_help]
	#
	set tail_row $top.tail
	set dir_row $top.dir
	set filter_row $top.filter
	#
	button ${tail_row}_button -font $font -text Filename \
		-command [list ::ChooseFile::tail_gui $ns $openCommand]
	spinbox ${tail_row}_entry \
	    -font $font -relief sunken -bd 2 -background white -wrap 1 \
	    -textvariable ${ns}::tail
	bind ${tail_row}_entry <Key-Return> $open_command
	#
	button ${dir_row}_button -font $font -text Directory \
		-command "::ChooseFile::dir_gui $ns"
	entry ${dir_row}_entry \
	    -font $font -relief sunken -bd 2 -background white \
	    -textvariable ${ns}::dir
	#
	label ${filter_row}_label -font $font -text "GlobFilter"
	set f ${filter_row}_frame
	frame $f
	entry $f.entry \
	    -font $font -relief sunken -bd 2 -background white \
	    -textvariable ${ns}::filter
	button $f.open -font $font -text Open -command $open_command
	button $f.help -font $font -text Help -command $help_command
	pack $f.entry -side left -expand 1 -fill x
	pack $f.open $f.help -side left
	if {$cancelCommand ne ""} {
	    button $f.cancel -font $font -text Cancel -command $cancelCommand
	    pack $f.cancel -side left
	}
	#
	grid propagate $top 1
	grid columnconfigure $top 1 -weight 1
	grid ${tail_row}_button ${tail_row}_entry -sticky ew
	grid ${dir_row}_button ${dir_row}_entry -sticky ew
	grid ${filter_row}_label ${filter_row}_frame -sticky ew
	#
	trace add variable ${ns}::dir    write "::ChooseFile::trace_dir $ns"
	trace add variable ${ns}::filter write "::ChooseFile::set_tail_values $ns"
	trace add variable ${ns}::tail   write "::ChooseFile::trace_tail $ns"
	set ${ns}::dir [pwd]
	set ${ns}::filter $filter
	shift_entry ${dir_row}_entry
	shift_entry ${tail_row}_entry
	return $top
    }

    # dir_gui --
    #
    # Called by pressing 'Directory' button

    proc dir_gui {
	ns
    } {
	global ${ns}::top
	set path [tk_chooseDirectory -parent $top -mustexist 1]
	if {$path ne ""} {
	    set ${ns}::dir [file normalize $path]
	}
    }

    # tail_gui --
    #
    # Called by pressing 'Filename' button

    proc tail_gui {
	ns
	openCommand
    } {
	global ${ns}::top
	set types [list "Filter [set ${ns}::filter]" {{All Files} *}]
	set path [tk_getOpenFile -parent $top -filetypes $types -initialdir [set ${ns}::dir]]
	if {$path ne ""} {
	    set ${ns}::dir  [file normalize [file dirname $path]]
	    set ${ns}::tail [file tail $path]
	    open_file $ns $openCommand
	}
    }

    # set_tail_values --
    #
    # Set tail spinbox values to names of all ordinary files & links matching filter

    proc set_tail_values {
	ns
	args
    } {
	global ${ns}::top
	global ${ns}::dir
	global ${ns}::filter
	if {[file isdirectory $dir]} {
	    set tails [lsort [glob -nocomplain -tails -types {f l} -directory $dir $filter]]
	    $top.tail_entry configure -values $tails
	    set ${ns}::tail [lindex $tails 0]
	}
    }

    # shift_entry --
    #
    # Shift entry widget w, so rightmost char is visible

    proc shift_entry {
	w
    } {
	# Following seems to do what we want, although not quite what manual says
	# Trying to be more clever (& follow manual) did not work
	$w xview moveto 1
    }

    # trace_dir --
    #
    # Called whenever ${ns}::dir changes

    proc trace_dir {
	ns
	args
    } {
	global ${ns}::dir
	global ${ns}::top
	if {[file isdirectory $dir]} {
	    $top.dir_entry configure -foreground black
	} else {
	    $top.dir_entry configure -foreground red
	    $top.tail_entry configure -foreground red
	}
	set_tail_values $ns
    }

    # trace_tail --
    #
    # Called whenever ${ns}::tail changes

    proc trace_tail {
	ns
	args
    } {
	global ${ns}::top
	set file [file join [set ${ns}::dir] [set ${ns}::tail]]
	if {[file isfile $file]} {
	    $top.tail_entry configure -foreground black
	} else {
	    $top.tail_entry configure -foreground red
	}
    }

    # open_file --
    #
    # Called by pressing Open button.

    proc open_file {
	ns
	openCommand
    } {
	eval $openCommand [list [file normalize [file join [set ${ns}::dir] [set ${ns}::tail]]]]
    }

    # display_help --

    proc display_help {
    } {
	set file [file join $::nap_library help_choose_file.pdf]
	if {[file readable $file]} {
	    auto_open $file
	} else {
	    handle_error "Unable to read file $file"
	}
    }

}
