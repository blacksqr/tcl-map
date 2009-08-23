# hdf.tcl --
#
# HDF/netCDF browser.
#
# Copyright (c) 1998-2002, CSIRO Australia
#
# Authors:
# Harvey Davies, CSIRO Atmospheric Research
# P.J. Turner, CSIRO Atmospheric Research
#
# $Id: hdf.tcl,v 1.126 2007/03/30 09:29:16 dav480 Exp $


# hdf --
#
# Run HDF browser.
#
# Usage
#   hdf ?<PARENT>? ?<GEOMETRY>?
#
# Example
#   hdf . +0+0

proc hdf {
    args
} {
    eval ::Hdf::main hdf $args
}

# netcdf --
#
# Run netCDF browser.
#
# Usage
#   netcdf ?<PARENT>? ?<GEOMETRY>?
#
# Example
#   netcdf . +0+0

proc netcdf {
    args
} {
    eval ::Hdf::main netcdf $args
}

package require BWidget

namespace eval ::Hdf {

    # main --
    #
    # Create window with HDF menu, etc.

    proc main {
	{hdf_or_netcdf hdf}
	{parent .}
	{geometry sw}
	{min_width 400}
	{font_family helvetica}
	{font_size 10}
    } {
	switch $hdf_or_netcdf {
	    hdf		{set extension hdf; set file_type HDF}
	    netcdf	{set extension nc ; set file_type netCDF}
	}
	    # Define fonts dnf (default normal font) & dbf (default bold font)
	foreach name {dnf dbf} weight {normal bold} {
	    if {[lsearch [font names] $name] < 0} {
		font create $name -family $font_family -size $font_size -weight $weight
	    }
	}
        set top [create_window $hdf_or_netcdf $parent $geometry "$file_type Browser" flat 2]
	set top_ns ::Hdf::t[string map {. _} $top]; # top namespace
	namespace eval $top_ns {
	    variable delay 500;		# time (msec) between windows (frames) of animation
	    variable filename ""
	    variable hdf_netcdf;	# "hdf" or "netcdf"
	    variable index "";		# subscript of NAO
	    variable is_current 0;	# 1 means nao is up-to-date
	    variable nao "";		# points to NAO
	    variable nao_name "";	# name specified by user
	    variable raw 0;		# 1 means want raw data (ignoring scale_factor, etc.)
	    variable save_from;		# array to save dim from values
	    variable save_to;		# array to save dim to values
	    variable save_step;		# array to save dim step values
	    variable sds_name "";	# sds-name : attribute-name
	    variable sds_rank ""
	    variable windows "";	# list of windows for animation
	    variable x0 "";		# coord of 1st corner of box defined by mouse
	    variable y0 "";		# coord of 1st corner of box defined by mouse
	}
	set ${top_ns}::hdf_netcdf $hdf_or_netcdf
	grid columnconfigure $top 0 -weight 1 -minsize $min_width
	create_head     $top_ns $top $extension
	create_file_gui $top_ns $top $extension
	trace add variable ${top_ns}::sds_name  write "::Hdf::need_read $top_ns"
	trace add variable ${top_ns}::index     write "::Hdf::need_read $top_ns"
	trace add variable ${top_ns}::raw       write "::Hdf::need_read $top_ns"
	# bind $top <Destroy> "if {[string equal %W $top]} {namespace delete $top_ns}"
	bind $top <Destroy> "::Hdf::close_window $top_ns %W $top"
	return $top
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


    # create_head --
    #
    # Create the row at the top containing: heading, help-button, cancel-button-button-button

    proc create_head {
	top_ns
	top
	extension
    } {
        destroy $top.head
        frame $top.head
        button $top.head.help -font dnf -text "Help" -command "::Hdf::hdf_help"
	button $top.head.cancel -font dnf -text Cancel -command "destroy $top"
        pack $top.head.cancel $top.head.help -side right
	grid $top.head -sticky ew
    }


    # create_file_gui --
    #
    # Create the GUI for the filename

    proc create_file_gui {
	top_ns
	top
	extension
    } {
	set all $top.file
	destroy $all
	::ChooseFile::choose_file_gui $all "::Hdf::open_file $top_ns $top" "" *.$extension dnf
	grid $all -sticky news
    }


    # create_tree --
    #
    # Create a tree structure for an HDF file

    proc create_tree {
	top_ns
	top
	{min_height 5}
	{max_height 16}
    } {
	global ${top_ns}::filename
	global ${top_ns}::hdf_netcdf
	. config -bd 3 -relief flat
	set all $top.tree
	destroy $top.tree $top.att_heading $top.sds_heading $top.index $top.do
	frame $all -background white; # HDF file tree
	set row [lindex [grid size $top] 1] 
	grid $all -sticky news
	grid rowconfigure $top $row -weight 1
	set tree $all.w
	set sbar $all.sb
	destroy $tree $sbar
        # Adjust the tree height (window size) using (number SDSs) + (number atts in final SDS)
	set SDSs [split [nap_get $hdf_netcdf -list $filename {^[^:]*$}] "\n"]
	set finalSDS [lindex $SDSs end]
	set atts [split [nap_get $hdf_netcdf -list $filename "^${finalSDS}:"] "\n"]
        set height [expr 1 + [llength $SDSs] + [llength $atts]]
	set height [expr $height < $min_height ? $min_height : $height]
	set height [expr $height > $max_height ? $max_height : $height]
	Tree $tree -height $height -background white -padx 2 -yscrollcommand "$sbar set"
	scrollbar $sbar -orient vertical -command "$tree yview"
	pack $sbar -side right -fill y
	pack $tree -expand true -fill both -anchor w
	set max_nels 0
	set default_item ""
        set dup 0
        set i 0
	set hdfList [split [nap_get $hdf_netcdf -list $filename] "\n"]
	foreach item $hdfList {
	    incr i
	    regsub {:.*} $item "" sds
	    regsub {[^:]*(:|$)} $item "" att
	    set eitem [encode $item]
	    if {"$sds" eq ""} {
		if {![$tree exists /]} {
		    $tree insert end root / -font dnf -text "Global attributes"
		}
		    # Catch problems caused by duplicate nodes.
		    # Add the characters " D<sequence number>" and set the displayed name to red.
		    # The encrypted name will include the " D<sequence number>" but the displayed
		    # screen tree title will be unchanged.
		if {[catch {$tree insert end / $eitem -font dnf -text $att} result]} {
                    incr dup
                    set eitem [encode "$item D$dup"]
                    if {[catch {$tree insert end / $eitem -font dnf -text $att} result]} {
                        tk_messageBox -type ok -icon warning -message \
                        "error $result \nadding duplicate $item D$dup to tree" 
                    } else {
	                $tree itemconfigure $eitem -fill red
                    }
                }
	    } else {
		if {"$att" eq ""} {
		    set shape [hdf_info $top_ns -shape "$filename" "$sds"]
		    if {[string match "$sds:*" [lindex $hdfList $i]]} {
			set drawcross allways; # Need this (wrong) spelling!
		    } else {
			set drawcross never
		    }
		    if {[catch {$tree insert end root $eitem \
			    -drawcross $drawcross -font dnf -text "$sds  $shape"} result]} {
                        incr dup
                        set eitem [encode "$item D$dup"]
		        if {[catch {$tree insert end root $eitem -font dnf \
				-text "$sds  $shape"} result]} {
                            tk_messageBox -type ok -icon warning -message \
                            "error $result \nadding duplicate $item D$dup to tree" 
                        } else {
        	            $tree itemconfigure $eitem -fill red
                        }
                    }
		    set nels [[nap "prod{$shape}"]]
		    if {$nels > $max_nels} {
			set max_nels $nels
			set default_item $sds
                    }
		} else {
		    if {[catch {$tree insert end [encode $sds] $eitem -font dnf \
			    -text $att} result]} {
                        incr dup
                        set eitem [encode "$item D$dup"]
		        if {[catch {$tree insert end [encode $sds] $eitem -font dnf \
				-text $att} result]} {
                            tk_messageBox -type ok -icon warning -message \
                            "error $result \nadding duplicate $item D$dup to tree" 
                        } else {
	                    $tree itemconfigure $eitem -fill red
                        }
                    }
		}
	    }
	    update idletasks
	}
	$tree bindText <ButtonPress-1> "::Hdf::button_command $top_ns $top $tree"
	if {$default_item ne ""} {
	    set ${top_ns}::sds_name $default_item
	    button_command $top_ns $top $tree [encode $default_item]
	}
        update idletasks
    }


    # create_index_widget --
    #
    # Create the index widget if rank > 0

    proc create_index_widget {
	top_ns
	top
	{ncols 7}
	{relief ridge}
    } {
	global ${top_ns}::filename
	global ${top_ns}::hdf_netcdf
	global ${top_ns}::sds_name
	global ${top_ns}::index
	global ${top_ns}::sds_rank
	set shp [hdf_info $top_ns -shape $filename $sds_name]
	if {[lsearch $shp 0] < 0} {
	    set sds_rank [hdf_info $top_ns -rank $filename $sds_name]
	} else {
	    set sds_rank 0; # Kludge to handle nels == 0
	}
	foreach name [namespace children ${top_ns}] {
	    eval namespace delete $name
	}
	if {$sds_rank > 0} {
		# Define new index grid "$win" (which is row of parent grid)
	    set win $top.index
	    frame $win -relief ridge -borderwidth 2
	    grid $win -sticky ew
	    grid columnconfigure $win 0 -weight 1
	    grid columnconfigure $win 2 -weight 1
	    grid columnconfigure $win 4 -weight 1
	    grid columnconfigure $win 6 -weight 1
		# From/To/Step headings
	    set row [lindex [grid size $win] 1]
	    set col 0
	    button $win.dim -font dnf -text Dimension -anchor w \
		    -command "::Hdf::init_dim $top_ns"
	    grid $win.dim -sticky w -row $row -column $col
	    set str(from) From
	    set str(to) "To (or expression)"
	    set str(step) "Step (0 = none)"
	    foreach var {from to step} {
		frame $win.${var}_vert_line -width 2 -relief $relief -bd 1
		grid $win.${var}_vert_line -sticky ns -row $row -column [incr col]
		button $win.$var -font dnf -text $str($var) -anchor w \
			-command "::Hdf::init_dim $top_ns all $var"
		grid $win.$var -sticky nsew -row $row -column [incr col]
	    }
		# 2 rows for each dimension
	    for {set i 0} {$i < $sds_rank} {incr i} {
		set cv [nap_get $hdf_netcdf -coordinate $filename $sds_name $i]
		if {$cv == ""} {
		    set cv$i ""
		    set unit($i) ""
		} else {
		    nap "cv$i = $cv"
		    set unit($i) [fix_unit [[set cv$i] unit]]
		    if {[string equal $unit($i) (NULL)]} {
			set unit($i) ""
		    }
		}
	    }
	    set dim_names [hdf_info $top_ns -dimension $filename $sds_name]
	    for {set i 0} {$i < $sds_rank} {incr i} {
		::Hdf::createDimWidget \
			$top_ns \
			${win} \
			$i \
			[lindex $dim_names $i] \
			[lindex $shp $i] \
			[set cv$i] \
			$unit($i) \
			$relief \
			$ncols
	    }
	}
    }


    # create_do_buttons --
    #
    # Create the 'do' buttons along the bottom

    proc create_do_buttons {
	top_ns
	top
    } {
	frame $top.do
	checkbutton $top.do.raw -font dnf -text Raw -variable ${top_ns}::raw -anchor w
	button $top.do.range -font dnf -text "Range" -command "::Hdf::hdf_range $top_ns $top"
	button $top.do.text -font dnf -text "Text" -command "::Hdf::hdf_text $top_ns $top"
	button $top.do.graph -font dnf -text "Graph" -command "::Hdf::hdf_graph $top_ns $top"
	button $top.do.image -font dnf -text "Image" -command "::Hdf::hdf_image $top_ns $top" 
	button $top.do.animate -font dnf -text "Animate" \
		-command "::Hdf::hdf_animate $top_ns $top"
	button $top.do.nao -font dnf -text "NAO" -command "::Hdf::hdf_create_nao $top_ns $top"
	button $top.do.reread -font dnf -text Re-read -command "::Hdf::need_read $top_ns"
	pack \
	    $top.do.raw \
	    $top.do.range \
	    $top.do.text \
	    $top.do.graph \
	    $top.do.image \
	    $top.do.animate \
	    $top.do.nao \
	    $top.do.reread \
	    -side left \
	    -fill x \
	    -expand true \
	    -padx 1 \
	    -pady 2
	grid $top.do -sticky ew
    }


    # need_read --
    #
    # Called by write trace on top namespace variables sds_name, index, raw
    # If any of these change we need to read variable again from file

    proc need_read {
	top_ns
	args
    } {
	set ${top_ns}::is_current 0
    }


    # open_file --

    proc open_file {
	top_ns
	top
	{new_filename ""}
    } {
	global ${top_ns}::filename
	if {$new_filename eq ""  ||  $new_filename eq "."} {
	    ::Hdf::hdf_warn "Filename is blank"
	} else {
	    if {[file readable $new_filename] && ![file isdirectory $new_filename]} {
		set filename $new_filename
		create_tree $top_ns $top
	    } else {
		::Hdf::hdf_warn "Unable to read file $new_filename"
	    }
	}
    }


    # hdf_graph --

    proc hdf_graph {
	top_ns
	top
    } {
	global ${top_ns}::nao
	set parent $top.do.graph
	set w $parent.menu
	destroy $w
	if [read_nao $top_ns $top] {
	    if {[$nao rank] > 1} {
		menu $w
		menu_entry $top_ns $top $w "graph" 1 xy
		menu_entry $top_ns $top $w "overlaid graph" 2 xy
		$w add command -label cancel -command "destroy $w"
		$w post [winfo rootx $parent] [expr [winfo rooty $parent] + [winfo height $parent]]
	    } else {
		draw_image $top_ns 1 xy $top
	    }
	}
    }

    # hdf_image --

    proc hdf_image {
	top_ns
	top
    } {
	global ${top_ns}::nao
	set parent $top.do.image
	set w $parent.menu
	destroy $w
	if [read_nao $top_ns $top] {
	    if {[$nao rank] > 2} {
		menu $w
		menu_entry $top_ns $top $w "pseudo-colour image" 2 z
		menu_entry $top_ns $top $w "tiled pseudo-colour image" 3 tile
		menu_entry $top_ns $top $w "RGB image" 3 z
		$w add command -label cancel -command "destroy $w"
		$w post [winfo rootx $parent] [expr [winfo rooty $parent] + [winfo height $parent]]
	    } elseif {[$nao rank] > 1} {
		draw_image $top_ns 2 z $top
	    } else {
		::Hdf::hdf_warn "rank < 2"
	    }
	}
    }

    # hdf_animate --

    proc hdf_animate {
	top_ns
	top
	{geometry SW}
    } {
	global ${top_ns}::windows
	set parent $top.do.animate
	set w $parent.menu
	destroy $w
	if {[llength $windows] > 1} {
	    menu $w
	    $w add command -label "animate last window-sequence" -command "::Hdf::animate $top_ns"
	    $w add command -label "set animation period" -command "set ${top_ns}::delay \
		    \[get_entry {period per window (msec)} -parent $top -font dnf \
		    -text \$${top_ns}::delay -geometry $geometry\]"
	    $w add command -label "delete last window-sequence" \
		    -command "eval destroy \$${top_ns}::windows; set ${top_ns}::windows {}"
	    $w add command -label cancel -command "destroy $w"
	    $w post [winfo rootx $parent] [expr [winfo rooty $parent] + [winfo height $parent]]
	} else {
	    ::Hdf::hdf_warn "no window-sequence"
	}
    }

    # proc menu_entry --
    #
    # add entry to graph or image menu
    # return 1 if entry added, else 0

    proc menu_entry {
	top_ns
	top
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
	    $w add command -label $label -command "::Hdf::draw_image $top_ns $rank_image $type $top"
	    return 1
	}
	return 0
    }

    # hdf_warn --
    #
    # Warn user of error

    proc hdf_warn {
	message
    } {
	handle_error $message
    }


    # hdf_info --
    #
    # get info on sds/var
    # flag can be -rank, -shape, -dimension, -coordinate

    proc hdf_info {
	top_ns
	flag
	filename
	var_name
    } {
	global ${top_ns}::hdf_netcdf
	set command [list nap_get $hdf_netcdf $flag $filename $var_name]
	if {[catch $command result]} {
	    ::Hdf::hdf_warn \
		    "hdf_info: Error executing following command:\
		    \n$command\
		    \nwhich produced result:\
		    \n$result"
	    set result undefined
	}
	return $result
    }


    # hdf_create_nao --
    #
    # Create NAO with name specified by user

    proc hdf_create_nao {
	top_ns
	top
	{geometry SW}
    } {
	global ${top_ns}::hdf_netcdf
	global ${top_ns}::nao
	global ${top_ns}::nao_name
	if [read_nao $top_ns $top] {
	    set str [::Hdf::hdf_var_name $top_ns $top]
	    if [regexp {^:} $str] {
		set str [string range $str 1 end]
	    }
	    regsub -all {[^_a-zA-Z0-9]} $str _ nao_name
	    if [regexp {^[0-9]} $nao_name] {
		set ::Hdf::nao_name _$nao_name
	    }
	    set nao_name [get_entry "NAO name: " -font dnf -text $nao_name -width 40 \
		-parent $top -geometry $geometry]
	    if {[catch {uplevel "nap $nao_name = $nao"}]} {
		::Hdf::hdf_warn "Unable to create NAO"
	    } else {
		puts "$hdf_netcdf browser created NAO $nao named '$nao_name'"
	    }
	}
    }


    # read_nao --
    #
    # Read variable from HDF file into nao
    # Return 1 if OK, 0 for error

    proc read_nao {
	top_ns
	top
    } {
	global ${top_ns}::filename
	global ${top_ns}::hdf_netcdf 
	global ${top_ns}::index
	global ${top_ns}::nao
	global ${top_ns}::sds_name
	global ${top_ns}::is_current
	global ${top_ns}::raw
	set status 0
	if {$is_current} {
	    set status 1
	} elseif {$filename ne ""} {
	    hdf_var_name $top_ns $top
	    setIndex $top_ns
	    if {[catch {nap "nao = [nap_get $hdf_netcdf $filename $sds_name $index $raw]"}]} {
		::Hdf::hdf_warn "Unable to read NAO"
	    } else {
		set status 1
		set is_current 1
		save_dims $top_ns
	    }
	}
	return $status
    }


    # hdf_help --
    #
    # Display help.

    proc hdf_help {
    } {
	set file [file join $::nap_library help_hdf.pdf]
	if {[file readable $file]} {
	    auto_open $file
	} else {
	    ::Hdf::hdf_warn "Unable to read file $file"
	}
    }


    # draw_image --
    #
    # View HDF var using plot_nao

    proc draw_image {
	top_ns
	rank
	type
	top
	{geometry -0+0}
    } {
	global ${top_ns}::nao 
	global ${top_ns}::sds_name
	global ${top_ns}::windows
	if [read_nao $top_ns $top] {
	    set label [string trim [$nao label]]
	    set unit  [string trim [$nao unit]]
	    if {[string equal $unit (NULL)]} {
		set unit ""
	    }
	    set title $sds_name
	    if {$unit != ""} {
		set title "$title ($unit)"
	    }
	    if {$label != ""} {
		set title "$label\n$title"
	    }
	    if {[catch {plot_nao $nao -geometry $geometry -parent $top \
		    -buttonPressCommand   "::Hdf::handle_button_press   $top_ns" \
		    -buttonReleaseCommand "::Hdf::handle_button_release $top_ns" \
		    -rank $rank -title $title -type $type} result]} {
		::Hdf::hdf_warn "Error in plot_nao:\n $result"
	    } else {
		if {[llength $result] > 1} {
		    set windows $result
		    raise .
		}
	    }
	}
    }


    # handle_button_press --
    #
    # Save mouse position when button pressed (start of box)

    proc handle_button_press {
	top_ns
    } {
	set ${top_ns}::x0 $::Plot_nao::x
	set ${top_ns}::y0 $::Plot_nao::y
    }


    # handle_button_release --
    #
    # Set from & to (of 2 least significant dims) based on box defined by mouse
    # If side of box has 0 length (e.g. after click without drag) then do not set from & to

    proc handle_button_release {
	top_ns
    } {
	global ${top_ns}::hdf_netcdf
	global ${top_ns}::sds_rank
	if {$sds_rank < 2} {
	    switch $hdf_netcdf {
		hdf	{error "Selected SDS has rank < 2"}
		netcdf	{error "Selected variable has rank < 2"}
	    }
	}
	nap "range_1 = ${top_ns}::x0 // ::Plot_nao::x"
	nap "range_2 = ${top_ns}::y0 // ::Plot_nao::y"
	foreach d {1 2} {
	    set dim_num [expr $sds_rank - $d]
	    set cv [set ${top_ns}::dim${dim_num}::cv]
	    set n  [set ${top_ns}::dim${dim_num}::n]
	    if {$cv eq ""} {
		nap "i = range_$d"
	    } else {
		nap "i = cv @@ range_$d"
	    }
	    set imin [[nap "min(i)"]]
	    set imax [[nap "max(i)"]]
	    if {$imin < $imax} {
		set ${top_ns}::dim${dim_num}::from $imin
		set ${top_ns}::dim${dim_num}::to   $imax
	    }
	}
	save_dims $top_ns
    }


    # animate --

    proc animate {
	top_ns
    } {
	global ${top_ns}::delay 
	global ${top_ns}::windows 
	set ms 0
	foreach win "$windows ." {
	    after $ms "raise $win; update idletasks"
	    incr ms $delay
	}
    }
    

    # hdf_range --
    #
    # Display range

    proc hdf_range {
	top_ns
	top
	{geometry SW}
    } {
	global ${top_ns}::filename
	global ${top_ns}::nao 
	global ${top_ns}::sds_name
	if [read_nao $top_ns $top] {
	    if [catch {nap "r = range(nao)"} result] {
		::Hdf::hdf_warn "Error in nap command:\n $result"
	    } else {
		message_window \
			"File: $filename \
			\nVariable: $sds_name \
			\nRange: [$r]" \
			-parent $top -geometry $geometry -label range
	    }
	}
    }


    # hdf_text --
    #
    # Read variable from HDF file into nao & then use specified method for this nao

    proc hdf_text {
	top_ns
	top
	{method "all"}
	{c_format ""}
	{max_cols ""}
	{max_lines ""}
	{geometry NW}
    } {
	global ${top_ns}::filename
	global ${top_ns}::nao 
	global ${top_ns}::sds_name
	if [read_nao $top_ns $top] {
	    if [regexp c8 [$nao datatype]] {
		default max_cols -1
		default max_lines -1
	    } else {
		default max_cols 50
		default max_lines 100
	    }
	    message_window \
		    "File: $filename \
		    \nVariable: $sds_name \
		    \n[$nao $method -format $c_format -columns $max_cols -lines $max_lines]" \
		    -parent $top -geometry $geometry -label data
	}
    }


    # hdf_var_name --
    #
    # Return value of sds_name (which combines names of both sds/var & attribute)
    #
    # Usage:
    #   hdf_var_name

    proc hdf_var_name {
	top_ns
	top
    } {
	global ${top_ns}::hdf_netcdf
	global ${top_ns}::sds_name
	if {![winfo exists $top.tree.w]} {
	    ::Hdf::create_tree $top_ns $top
	}
	if {$sds_name eq ""} {
	    switch $hdf_netcdf {
		hdf	{error "You have not chosen an SDS!"}
		netcdf	{error "You have not chosen a variable!"}
	    }
	}
	return  $sds_name
    }


    # encode --
    #
    # convert string to hex (doubling length of string)
    #
    # Example:
    # % encode abc
    # 616263
    # % decode 616263
    # abc

    proc encode {
	s
    } {
	binary scan $s "H*" hex
	return $hex
    }


    # decode --
    #
    # convert hex to string

    proc decode {
	h
    } {
	return [binary format "H*" $h]
    }


    # create_name_value_widget --
    #
    # Create frame containing labels for name & value
    # Return total number of characters in both

    proc create_name_value_widget {
	path
	name
	value
	{wraplength 500}
    } {
	destroy $path
	frame $path
	label $path.name  -font dbf -text $name  -wraplength $wraplength -justify left
	label $path.value -font dnf -text $value -wraplength $wraplength -justify left
	pack $path.name $path.value -anchor w -fill x -side left -pady 1
	return [string length "$name$value"]
    }


    # create_att_heading_widget --
    #
    # Create widget containing:
    #   name of SDS/variable
    #   name of attribute
    #   value of attribute

    proc create_att_heading_widget {
	top_ns
	top
    } {
	global ${top_ns}::filename
	global ${top_ns}::hdf_netcdf
	global ${top_ns}::sds_name
	set f $top.att_heading
	frame $f -relief ridge -borderwidth 2
	grid $f -sticky ew
	set att_head $f.att_head
	frame $att_head 
	set sds_att [split $sds_name :]
	set sds [lindex $sds_att 0]
	set att [lindex $sds_att 1]
	if {$sds eq ""} {
	    set att_name {Global attribute}
	} else {
	    set type(hdf) SDS
	    set type(netcdf) Variable
	    create_name_value_widget $att_head.sds $type($hdf_netcdf) $sds
	    pack $att_head.sds -side left
	    set att_name {  Attribute}
	}
	create_name_value_widget $att_head.att $att_name $att
	pack $att_head.att -side left
	label $f.att_value -font dnf -text [[nap_get $hdf_netcdf $filename $sds_name]]
	pack $f.att_head $f.att_value -anchor w
    }


    # create_sds_heading_widget --
    #
    # Create widget containing name of SDS/variable, long_name, units

    proc create_sds_heading_widget {
	top_ns
	top
	{max_width 70}
	{pad {  }}
    } {
	global ${top_ns}::filename
	global ${top_ns}::hdf_netcdf
	global ${top_ns}::sds_name
	set type(hdf) SDS
	set type(netcdf) Variable
	set f $top.sds_heading
	frame $f -relief ridge -borderwidth 2
	grid $f -sticky ew
	frame $f.pair
	label $f.pad0 -font dnf -text $pad
	label $f.pad1 -font dnf -text $pad
	set n(sds) [create_name_value_widget $f.sds $type($hdf_netcdf) $sds_name]
	if {[catch {[nap_get $hdf_netcdf $filename ${sds_name}:long_name]} text]} {
	    set n(long_name) 0
	} else {
	    set n(long_name) [create_name_value_widget $f.long_name long_name $text]
	}
	if {[catch {[nap_get $hdf_netcdf $filename ${sds_name}:units]} text]} {
	    set n(units) 0
	} else {
	    set n(units) [create_name_value_widget $f.units units $text]
	}
	if {$n(sds) + $n(long_name) + $n(units) < $max_width} {
	    pack $f.sds -side left -anchor w
	    if {$n(long_name) > 0} {
		pack $f.pad0 $f.long_name -side left -anchor w
	    }
	    if {$n(units) > 0} {
		pack $f.pad1 $f.units -side left -anchor w
	    }
	} elseif {$n(sds) + $n(long_name) < $max_width  &&  $n(long_name) > 0} {
	    pack $f.sds $f.pad0 $f.long_name -side left -anchor w -in $f.pair
	    pack $f.pair $f.units -anchor w
	} elseif {$n(sds) + $n(units) < $max_width  &&  $n(units) > 0} {
	    pack $f.sds $f.pad0 $f.units -side left -anchor w -in $f.pair
	    pack $f.pair $f.long_name -anchor w
	} elseif {$n(long_name) + $n(units) < $max_width
		    &&  $n(long_name) > 0  &&  $n(units) > 0} {
	    pack $f.long_name $f.pad0 $f.units -side left -anchor w -in $f.pair
	    pack $f.sds $f.pair -anchor w
	} else {
	    pack $f.sds -side top -anchor w
	    if {$n(long_name) > 0} {
		pack $f.long_name -side top -anchor w
	    }
	    if {$n(units) > 0} {
		pack $f.units -side top -anchor w
	    }
	}
    }


    # button_command --
    #
    # create_tree binds button_command to pressing mouse button 1 on sds/att

    proc button_command {
	top_ns
	top
	tree
	eitem
	{max_width 450}
    } {
	global ${top_ns}::sds_name
	if {$sds_name ne ""} {
	    set old [encode $sds_name]
	    if {![$tree exists $old]} {
		error "Tree item for $sds_name does not exist"
	    }
	    $tree itemconfigure $old -fill black
	}
	if {$eitem ne "/"} {
		# Entries in red are duplicates and should not be changed.
		# This is a temporary fix by Peter Turner
            set colour [$tree itemcget $eitem -fill]
            if {$colour ne "red"} {
	        $tree itemconfigure $eitem -fill blue
	        set sds_name [decode $eitem]
		if {$sds_name ne ""} {
		    destroy $top.att_heading $top.sds_heading $top.index $top.do
		    if {[string match "*:*" $sds_name]} {
			create_att_heading_widget $top_ns $top
		    } else {
			create_sds_heading_widget $top_ns $top
			create_index_widget $top_ns $top
		    }
		    create_do_buttons $top_ns $top
		}
            }
	}
    }

    # fix_unit --
    #
    # Return "°E" if arg is anything equivalent to this e.g. "degreeE"
    # Return "°N" if arg is anything equivalent to this e.g. "degreeN"
    # Return "" if arg is "(NULL)"
    # Otherwise just return arg

    proc fix_unit {
	unit
    } {
	set result [string trim $unit]
	set degree "\xb0"; # ISO-8859 code for degree symbol
	switch -regexp [string tolower $result] {
	    {^\(null\)$}	{set result ""}
	    {^degree.*e}	{set result "${degree}E"}
	    {^degree.*n}	{set result "${degree}N"}
	}
	return $result
    }

    # setIndex --
    #
    # Set index to "" or NAO ID of index (e.g. result of nap expression "5,0..9...1")

    proc setIndex {
	top_ns
    } {
	global ${top_ns}::sds_rank
	global ${top_ns}::sds_name
	set ${top_ns}::index ""
	    # Check for attribute
	if {![string match "*:*" $sds_name]} {
	    set list ""
	    for {set i 0} {$i < $sds_rank} {incr i} {
		set dim_ns "${top_ns}::dim$i"
		global ${dim_ns}::expr
		global ${dim_ns}::from
		global ${dim_ns}::n
		global ${dim_ns}::to
		global ${dim_ns}::step
		if {$step == 0} {
		    if {$expr eq ""} {
			lappend list "^ $from"
		    } else {
			lappend list $expr
		    }
		} elseif {$from == 0  &&  $to == $n-1  &&  $step == 1} {
		    lappend list ""
		} elseif {$from < $to} {
		    lappend list "^($from .. $to ... $step)"
		} elseif {$from > $to} {
		    lappend list "^($to .. $from ... $step)"
		} else {
		    lappend list "^ $from"
		}
	    }
	    set nap_expr [join $list ,]
	    if {![regexp {^,*$} $nap_expr]} {
		uplevel #0 "nap \"${top_ns}::index = $nap_expr\""
	    }
	}
    }

    # createDimWidget --
    #
    # Create a widget for specified dimension to allow user to set <from>, <to> & <step>

    proc createDimWidget {
	top_ns
	parent
	dim_num
	dim_name
	dim_size
	cvNao
	unit
	relief
	ncols
    } {
	global ${top_ns}::save_from
	global ${top_ns}::save_to
	global ${top_ns}::save_step
	set dim_ns "${top_ns}::dim$dim_num"
	namespace eval $dim_ns {
	    variable expr "";		# string containing nap expression
	    variable cv "";		# Main coordinate variable
	    variable cvs "";		# Coordinate variable for 'step'
	    variable from;		# subscript  variable for 'from' spinbox
	    variable from_cv;		# coordinate variable for 'from' entry
	    variable from_map;		# mapping for 'from' scale
	    variable n;			# = dim_size 
	    variable name;		# = dim_name 
	    variable step;		# subscript  variable for 'step' spinbox
	    variable step_cv;		# coordinate variable for 'step' entry
	    variable step_map;		# mapping for 'step' scale
	    variable to;		# subscript  variable for 'to' spinbox
	    variable to_cv;		# coordinate variable for 'to' entry
	    variable to_map;		# mapping for 'to' scale
	    variable within_set_scale 0; # flag to prevent infinite recursion
	}
	global ${dim_ns}::cv
	global ${dim_ns}::cvs
	set ${dim_ns}::n $dim_size
	set ${dim_ns}::name $dim_name
	if {$cvNao ne ""} {
	    nap "cv = cvNao"
	    if {[$cv step] eq "AP"} {
		nap "cvs = cv - cv(0)"
	    }
	}
	    # horizontal line
	set row [lindex [grid size $parent] 1]
	frame $parent.hor_line$dim_num -height 2 -relief $relief -bd 1
	grid $parent.hor_line$dim_num -sticky ew -row $row -columnspan $ncols
	    # main row
	incr row
	    # dim. name
	button $parent.dimname$dim_num -font dnf -text $dim_name -anchor w \
		-command "::Hdf::toggle_dim $top_ns $dim_num"
	grid $parent.dimname$dim_num -sticky news -row $row -column 0 -rowspan 2
	set col 1
	    # from, to, step
	foreach word {from to step} {
	    set saved_value [get_saved_dim $top_ns $dim_num $word]
	    if {$saved_value eq ""} {
		set init_value [get_default_dim $top_ns $dim_num $word]
	    } else {
		set init_value $saved_value
	    }
	    if {$word eq "step"} {
		set c $cvs
	    } else {
		set c $cv
	    }
	    set col [create_from_to_step $top_ns $word $init_value $parent \
		    $dim_num $unit $relief $row $col $c]
	}
    }

    # init_dim --
    #
    # Set specified columns (specified by words) of specified dim to defaults
    # If dim_num is "all" then do all dims
    # words can be "from", "to", "step"

    proc init_dim {
	top_ns
	{dim_num all}
	{words {from to step}}
    } {
	global ${top_ns}::sds_rank
	if {$dim_num eq "all"} {
	    for {set i 0} {$i < $sds_rank} {incr i} {
		init_dim $top_ns $i $words
	    }
	} else {
	    foreach word $words {
		set ${top_ns}::dim${dim_num}::$word [get_default_dim $top_ns $dim_num $word]
	    }
	}
    }

    # save_dims --
    #
    # Save current values of from, to & step

    proc save_dims {
	top_ns
    } {
	global ${top_ns}::sds_rank
	for {set dim_num 0} {$dim_num < $sds_rank} {incr dim_num} {
	    set dim_name [set ${top_ns}::dim${dim_num}::name]
	    set dim_size [set ${top_ns}::dim${dim_num}::n]
	    set array_index "$dim_name,$dim_size"
	    foreach word {from to step} {
		set current_value [set ${top_ns}::dim${dim_num}::$word]
		set ${top_ns}::save_${word}($array_index) $current_value
	    }
	}
    }

    # toggle_dim --
    #
    # Toggle from, to & step of specified dim
    # If all three are set to defaults then set them to saved values (if any)
    # Otherwise set them to defaults

    proc toggle_dim {
	top_ns
	dim_num
    } {
	set words {from to step}
	set count 0
	foreach word $words {
	    set current_value [set ${top_ns}::dim${dim_num}::$word]
	    set default_value [get_default_dim $top_ns $dim_num $word]
	    incr count [expr $current_value == $default_value]
	}
	if {$count == 3} {
	    foreach word $words {
		set saved_value [get_saved_dim $top_ns $dim_num $word]
		if {$saved_value ne ""} {
		    set ${top_ns}::dim${dim_num}::$word $saved_value
		}
	    }
	} else {
	    init_dim $top_ns $dim_num
	}
    }

    # get_saved_dim --
    #
    # Return saved from, to or step (specified by word) if it exists, else ""

    proc get_saved_dim {
	top_ns
	dim_num
	word
    } {
	set dim_name [set ${top_ns}::dim${dim_num}::name]
	set dim_size [set ${top_ns}::dim${dim_num}::n]
	set array_index "$dim_name,$dim_size"
	if {[array names ${top_ns}::save_${word} $array_index] eq ""} {
	    set result ""
	} else {
	    set result [set ${top_ns}::save_${word}($array_index)]
	}
	return $result
    }

    # get_default_dim --
    #
    # Return default value for from, to or step (specified by word)

    proc get_default_dim {
	top_ns
	dim_num
	word
    } {
	set dim_size [set ${top_ns}::dim${dim_num}::n]
	switch $word {
	    from {set result 0}
	    to   {set result [expr $dim_size - 1]}
	    step {set result [expr $dim_size > 1]}
	}
	return $result
    }

    # list_max_length --
    #
    # max. no. chars in any element of list

    proc list_max_length {
	list
    } {
	set result 0
	foreach element $list {
	    set length [string length $element]
	    if {$length > $result} {
		set result $length
	    }
	}
	return $result
    }

    # create_from_to_step --
    #
    # Create widget for from, to or step
    # Return index of final column used
    #
    # var is "from", "to" or "step"
    # row & col are those of first (north-west) element of grid to be used
    # If cv is "" then there is no coord variable

    proc create_from_to_step {
	top_ns
	var
	init_value
	parent
	dim_num
	unit
	relief
	row
	col
	{cv ""}
    } {
	set dim_ns "${top_ns}::dim$dim_num"
	set sub_var ${dim_ns}::${var};     # name of main (subscript) variable
	set cv_var  ${dim_ns}::${var}_cv;  # name of coordinate variable
	trace add variable $sub_var write "::Hdf::need_read $top_ns"
	set col1 [expr $col + 1]
	set n1 [expr [set ${dim_ns}::n] - 1]
	set expr_entry $parent.expr${dim_num}entry
	if {$var eq "step"} {
	    trace add variable $sub_var write \
		[list ::Hdf::raise_lower_expr_entry $expr_entry]
	}
	    # vertical line
	set vl $parent.$var${dim_num}vert_line
	frame $vl -width 2 -relief $relief -bd 1
	grid $vl -sticky ns -row $row -column $col -rowspan 2
	    # entry for nap expression (hidden at start)
	if {$var eq "to"} {
	    trace add variable ${dim_ns}::expr write "::Hdf::need_read $top_ns"
	    entry $expr_entry -textvariable ${dim_ns}::expr \
		-font dnf -borderwidth 1 \
		-background white -highlightthickness 1 -width 0
	    grid $expr_entry -sticky news -row $row -column $col1
	    bind $expr_entry <Enter> "focus $expr_entry"
	}
	    # frame for upper row of from/to/step
	set sub_upper $parent.$var${dim_num}sub_upper
	set sub_lower $parent.$var${dim_num}sub_lower
	frame $sub_upper
	grid $sub_upper -sticky news -row $row  -column $col1
	    # spinbox for subscript
	set sub_spin $sub_upper.spin
	spinbox $sub_spin \
	    -from 0 -to $n1 \
	    -width [expr 3 + [string length $n1]] \
	    -textvariable $sub_var \
	    -font dnf -borderwidth 1 \
	    -justify right -background white -highlightthickness 1
	pack $sub_spin -side left
	bind $sub_upper <Enter> "focus $sub_spin"
	    # scale (slider) for subscript
	set sub_scale $sub_upper.scale
	scale $sub_scale -showvalue 0 -orient horizontal -borderwidth 1 \
	    -from 0 -highlightthickness 1 \
	    -command "::Hdf::handle_scale_drag $dim_ns $var $sub_var"
	pack $sub_scale -side left -expand 1 -fill x
	trace add variable $sub_var write "::Hdf::set_scale $dim_ns $var $sub_scale"
	set m [[nap "49 >>> [$sub_scale cget -length]/2 - 1"]]; # max. no. steps on step scale
	if {$var eq "step"  &&  $n1 > 0} {
		# Define geometric progression (r=2) ending at max power of 2 <= n1/2
	    nap "gp = i32(2 ** (floor(log(n1, 2)) - (m .. 1)))"
	    nap "${dim_ns}::${var}_map = 0 // ((1 .. m) >>> gp)"
	    $sub_scale configure -to $m
	} else {
	    nap "${dim_ns}::${var}_map = 0 .. n1"
	    $sub_scale configure -to $n1
	}
	    # Default scale Up/Down bindings are reverse of what we want!
	bind $sub_scale <Up>   "[bind Scale <Down>]; break"
	bind $sub_scale <Down> "[bind Scale <Up>]  ; break"
	    # coord. var
	if {$cv ne ""} {
		# frame for lower (cv) row of from/to/step
	    incr row
	    frame $sub_lower
	    grid $sub_lower -sticky news -row $row -column $col1
		# entry for coord. var
	    set cv_entry $sub_lower.entry
	    entry $cv_entry -justify right -background white -highlightthickness 1 \
		-width [expr 2 + [list_max_length [[nap "cv(-9 .. 9)"] value]]] \
		-font dnf -borderwidth 1 -textvariable $cv_var
	    bind $sub_lower <Enter> "focus $cv_entry"
	    bind $cv_entry <Up>   "$sub_spin invoke buttonup"
	    bind $cv_entry <Down> "$sub_spin invoke buttondown"
	    bind $cv_entry <Leave>  [list ::Hdf::cv_entry_text $cv_var $sub_var $cv]
	    bind $cv_entry <Return> [list ::Hdf::cv_entry_text $cv_var $sub_var $cv]
	    trace add variable $sub_var write [list ::Hdf::set_cv_entry $cv_var $cv]
	    pack $cv_entry -side left
		# label for units of coord. var
	    set cv_unit $sub_lower.label
	    label $cv_unit -font dnf -text $unit -anchor w
	    pack $cv_unit -side left
	}
	    # initialise subscript variable
	set $sub_var $init_value
	return [expr $col + 2]
    }

    # raise_lower_expr_entry --
    #
    # If subscript is 0 then raise expr entry, else lower it to reveal subscript-spinbox & scale

    proc raise_lower_expr_entry {
	win
	name1
	name2
	op
    } {
	if {[set $name1] == 0} {
	    raise $win
	} else {
	    lower $win
	}
    }

    # handle_scale_drag --
    #
    # set subscript variable after user drags scale

    proc handle_scale_drag {
	dim_ns
	var
	sub_var
	value
    } {
	global ${dim_ns}::within_set_scale
	if {! $within_set_scale} {
	    set $sub_var [[nap "${dim_ns}::${var}_map(value)"]]
	}
    }

    # set_scale --
    #
    # Keep scale in sync with subscript variable

    proc set_scale {
	dim_ns
	var
	w
	name1
	name2
	op
    } {
	global ${dim_ns}::within_set_scale
	set v ${dim_ns}::${var}_map
	set within_set_scale 1
	$w set [[nap "nels(v) > 1 ? v @ name1 : 0"]]
	update idletasks
	set within_set_scale 0
    }

    # set_cv_entry --
    #
    # Keep cv entry in sync with subscript variable

    proc set_cv_entry {
	cv_var
	cv
	name1
	name2
	op
    } {
	set $cv_var [[nap "cv($name1)"]]
    }

    # cv_entry_text --
    #
    # Handle text typed into cv entry
    # Keeps subscript variable in sync with cv entry 
    # Use @ to set subscript to that of interpolated value in coord. var.
    # This causes text in entry to change to this value

    proc cv_entry_text {
	cv_var
	sub_var
	cv
    } {
	if {[string is double -strict [set $cv_var]]} {
	    set $sub_var [[nap "nels(cv) > 1 ? cv @ $cv_var : 0"]]
	}
    }

}
