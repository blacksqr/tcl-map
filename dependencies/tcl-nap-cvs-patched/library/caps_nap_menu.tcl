# caps_nap_menu.tcl --
#
# Copyright (c) 1998-2003, CSIRO Australia
# Author: Harvey Davies, CSIRO.
# $Id: caps_nap_menu.tcl,v 1.20 2007/03/30 09:29:16 dav480 Exp $


# caps_nap_menu --

proc caps_nap_menu {
    args
} {
    eval ::NAP::create_main_menu $args
}


namespace eval NAP {

    proc create_main_menu {
	{geometry +0+20}
	{parent "."}
        {font {-family Helvetica -size 10}}
    } {
	set title ""
	if {[info exists ::caps_patchLevel]} {
	    lappend title CAPS$::caps_patchLevel
	}
	if {[info exists ::nap_patchLevel]} {
	    lappend title NAP$::nap_patchLevel
	}
	if {$parent eq "."} {
	    set m ""
	    set p .
	} else {
	    set m [create_window caps_nap_menu $parent $geometry $title]
	    set p $m
	}
	create_logo $m.caps_logo
	frame $m.mbar -relief raised
	menubutton $m.mbar.browse -font $font \
		-text "Browse" -menu $m.mbar.browse.menu -relief raised
	menubutton $m.mbar.command -font $font \
		-text "Command" -menu $m.mbar.command.menu -relief raised
	menubutton $m.mbar.help -font $font \
		-text "Help" -menu $m.mbar.help.menu -relief raised
	create_browse_menu $m.mbar.browse.menu $p SW
	create_command_menu $m.mbar.command.menu
	create_help_menu $m.mbar.help.menu
	pack $m.mbar.browse $m.mbar.command $m.mbar.help -side left -fill y
	pack $m.caps_logo $m.mbar -side left -fill y
	update idletasks
	if {$parent eq "."} {
	    wm geometry . $geometry 
	    wm title . $title 
	}
    }

    # create_logo --
    # Try to create PJT's famous caps logo
    # If something goes wrong with the logo then keep going

    proc create_logo {
	frame
    } {
	if {![info exists ::caps_directory]  ||
		[catch {image create photo -file $::caps_directory/caps.gif} imageName]} {
	    frame $frame -width 0 -height 0
	} else {
	    frame $frame -borderwidth 2 -relief raised
	    set canvas $frame.canvas
	    canvas $canvas \
		    -relief raised \
		    -width 21 \
		    -height 30
	    $canvas create image 2 2 -image $imageName -anchor nw
	    pack $canvas
	    bind $canvas <Button-1> {
		::NAP::display_help \
			http://www.eoc.csiro.au/cats/caps/capshome.html \
			"CAPS Web documentation"
	    }
	}
    }


    proc create_browse_menu {
	menu_name
	parent
	geometry
    } {
	set browse [menu $menu_name]
	$browse add command \
		-label "Variables" \
		-command [list browse_var $parent $geometry]
	if {[info exists ::caps_patchLevel]} {
	    $browse add command \
		    -label "AVHRR" \
		    -command [list get_avhrr_gui $parent $geometry]
	    $browse add command \
		    -label "ATSR" \
		    -command [list get_atsr_gui $parent $geometry]
	}
	$browse add command \
		-label "CIF files" \
		-command [list browse_cif $parent $geometry]
	$browse add command \
		-label "HDF" \
		-command [list hdf $parent $geometry]
	$browse add command \
		-label "image files" \
		-command [list vif "" -parent $parent -geometry $geometry]
	$browse add command \
		-label "netCDF" \
		-command [list netcdf $parent $geometry]
    }


    proc create_command_menu {
	menu_name
    } {
	set m [menu $menu_name]
	$m add command -label "History" -command {message_window "[history]" -label history}
	# $m add command -label "Destroy menu bar" -command "destroy .menu"
	$m add command -label "Exit" -command exit
    }


    proc create_help_menu {
	menu_name
    } {
	set help [menu $menu_name]
	#
	$help add command \
		-label "Help for Main CAPS/NAP Menu" \
		-command ::NAP::help_caps_nap_menu
	#
	set doc_dir "[file dirname [file dirname $::tcl_library]]/doc"
	if {$::tcl_platform(platform) eq "windows"} {
	    set file [lindex [glob -nocomplain $doc_dir/ActiveTclHelp*.chm] end]
	} else {
	    set file "$doc_dir/html/index.html"
	}
	set label "Tcl/Tk Local documentation"
	if {[file readable $file]} {
	    $help add command -label $label -command [list ::NAP::display_help $file $label]
	}
	#
	set file http://aspn.activestate.com/ASPN/Tcl/Reference/
	set label "Tcl/Tk Web documentation"
	$help add command -label $label -command [list ::NAP::display_help $file $label]
	#
	set file [file join $::nap_library nap_users_guide.pdf]
	if {[file readable $file]} {
	    set label "NAP Local documentation"
	    $help add command -label $label -command [list ::NAP::display_help $file $label]
	}
	#
	set file http://tcl-nap.sourceforge.net/nap_users_guide.pdf
	set label "NAP Web documentation"
	$help add command -label $label -command [list ::NAP::display_help $file $label]
	#
	set file http://www.eoc.csiro.au/cats/caps/capshome.html
	set label "CAPS Web documentation"
	$help add command -label $label -command [list ::NAP::display_help $file $label]
    }


    proc help_caps_nap_menu {} {
	set file [file join $::nap_library help_caps_nap_menu.pdf]
	if {[file readable $file]} {
	    ::NAP::display_help $file "Help on CAPS/NAP Main Menu"
	} else {
	    message_window \
		"The buttons have the following functions:\
		\n'Browse': Select from browsers for:\
		\n    - Tcl variables (including those referencing NAOs)\
		\n    - AVHRR satellite files\
		\n    - ATSR satellite files\
		\n    - CIF files (used mainly in Melbourne)\
		\n    - HDF files\
		\n    - netCDF files\
		\n    - image files (e.g. GIF, JPEG)\
		\n'Command':\
		\n    'History': Display command history in scrolled window.\
		\n    'Exit': Quit.\
		\n'Help': Documentation (including access to Web)." \
		-label "Main Menu Help"
	}
    }


    proc display_help {
	file
	description
    } {
	if [catch {auto_open $file}] {
	    message_window "Unable to access $file ($description)"
	}
    }

}
