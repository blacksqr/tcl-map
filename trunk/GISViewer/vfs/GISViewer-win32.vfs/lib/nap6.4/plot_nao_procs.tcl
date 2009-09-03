# plot_nao_procs.tcl --
# 
# Copyright (c) 2000, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: plot_nao_procs.tcl,v 1.151 2007/11/08 10:09:44 dav480 Exp $
#
# Produce xy-graph, barchart (histogram), z-plot (image) or tiled-plot (multiple images).

namespace eval Plot_nao {
	# Following variables do not need namespace for each graph window
    variable buttonIsDown 0;		# 0 = mouse button-1 up, 1 = down
    variable control_c_pressed 0;	# 1 if control-c pressed
    variable frame_id 0;		# Number of previous graphs created
    variable image_format_list;		# list of supported image formats
    variable x "";			# Current x coord under crosshairs
    variable y "";			# Current y coord under crosshairs
    variable z "";			# Current z values under crosshairs
    variable xyz "";			# "$x $y $z" (for user convenience)

    proc plot_nao {
	{nao_expr ""}
	args
    } {
	if {![info exists ::tk_version]} {
	    error "No tk! You should be running wish not tclsh!"
	}
	if [catch "uplevel 2 [list nap "{$nao_expr}"]" nao] {
	    if {$nao_expr == ""  ||  [regexp -nocase {^-h} $nao_expr]} {
		display_help
	    } else {
		handle_error $nao
	    }
	    return
	}
	nap "nao = pad(nao)"
	if {[$nao rank] == 0} {
	    handle_error "Value is scalar"
	    return
	}
	nap "r = range(nao)"
	if {[[nap "r(1) - r(0) == 1i"]]} {
	    handle_error "data includes infinity!"
	    return
	}
	set ::Plot_nao::image_format_list "ppm gif"
	if {[catch "package require Img"] == 0} {
	    lappend ::Plot_nao::image_format_list bmp xbm xpm png jpeg tiff
	}
	set ::Plot_nao::image_format_list [lsort $::Plot_nao::image_format_list]
	if {[::Print_gui::init]} {
	    message_window "Error in Print_gui::init. Unable to initialise printing."
	}
	nap "shape_nao = shape(nao)"
	if [[nap "rank(nao) == 3  &&  shape_nao(0) == 1"]] {
	    nap "nao = nao(0,,)"
	    nap "shape_nao = shape(nao)"
	}
	set window_id "win$Plot_nao::frame_id"
	    # Following variables exist in namespace for each graph window
	namespace eval ${window_id} {
	    variable allow_scroll 0;	# Use scrolling if oversize? (Otherwise compress.)
	    variable auto_print 0;	# automatic printing? Useful for batch processing
	    variable auto_redraw 1;	# automatic redraw (after changing relevant parameters)?
	    variable barwidth 1.0;	# width of each bar of barchart
	    variable box_x0 "";		# canvas x coord of initial corner of box
	    variable box_y0 "";		# canvas y coord of initial corner of box
	    variable colors "black red green blue yellow orange purple grey aquamarine beige"
					# colors of xy graphs or bars
	    variable cvz "";		# coord. var. for z (key) axis
	    variable dash_patterns "";	# Dash patterns of xy-lines.
	    variable discrete_colors 0;	# 0 = continuous, 1 = discrete
	    variable font_standard "courier 10";
	    variable font_title    "courier 16";
	    variable gap_height "";	# height (pixels) of horizontal white space between tiles
	    variable gap_width  "";	# width (pixels) of vertical white space
	    variable gshhs_min_area -1;	# Exclude polygons with area (square km) < this
	    variable gshhs_resolution -1; # Required resolution of GSHHS shoreline (km)
	    variable histograms "";	# List of histogram IDs (so can destroy at end)
	    variable image_format gif;	# format of output image file
	    variable image_nao "";	# Image NAO after any inversion
	    variable key_width 30;	# width (pixels) of image or XY key
	    variable labels "";		# for xy-graphs, bars or tiles
	    variable magnification "";	# magnification factor (relative to original NAO)
	    variable main_palette "";	# NAO defining color mapping for 2D images
	    variable major_tick_length 6; # length (pixels) of major tick marks (constant)
	    variable major_ticks_x "";	# major tick positions for x axis
	    variable major_ticks_x_from ""; # Used in create_major_ticks_entry
	    variable major_ticks_x_step ""; # Used in create_major_ticks_entry
	    variable major_ticks_x_to   ""; # Used in create_major_ticks_entry
	    variable major_ticks_y "";	# major tick positions for y axis
	    variable major_ticks_y_from ""; # Used in create_major_ticks_entry
	    variable major_ticks_y_step ""; # Used in create_major_ticks_entry
	    variable major_ticks_y_to   ""; # Used in create_major_ticks_entry
	    variable major_ticks_z "";	# specified major tick positions for z (key) axis
	    variable major_ticks_z_from ""; # Used in create_major_ticks_entry
	    variable major_ticks_z_step ""; # Used in create_major_ticks_entry
	    variable major_ticks_z_to   ""; # Used in create_major_ticks_entry
	    variable major_ticks_z_use  ""; # Value to be actually used
	    variable mapping "";	# Used to produce histogram equalisation
	    variable max_canvas_height ""; # max height (pixels) of canvas ("" = maximise)
	    variable max_canvas_width  ""; # max width  (pixels) of canvas ("" = maximise)
	    variable ncols  "";		# no. columns in tile plot
	    variable new_height "";	# current image height
	    variable new_width "";	# current image width
	    variable orientation "A";	# P = portrait, L = landscape, A = automatic
	    variable overlay_nao "";	# overlay (e.g. coastline)
	    variable overlay_option A;	# C = coast, L = land, S = sea, N = none, A = auto, E = expr
	    variable overlay_palette;	# NAO defining color mapping for overlay (e.g. coastline)
	    variable oversize_prompt 1;	# Prompt if image is bigger than screen?
	    variable percentileFrom;	# Used to define scalingFromZ
	    variable percentileTo;	# Used to define scalingToZ
	    variable plot_type "";	# "bar", "tile", "xy" or "z"
	    variable print_command "";	# 
	    variable projection "";	# Map projection name for PROJ.4
	    variable proj4spec "";	# PROJ.4 specification
	    variable save "";		# Used to save crosshair data
	    variable save_nao_ids "";	# List of nao ids to be saved until end.
	    variable symbols "";	# Symbol drawn at each point of xy-graph
	    variable scalingFromZ;	# Used to scale z plots (tcl array)
	    variable scalingFromIsNext;	# 0: scalingToZ next, 1: scalingFromZ next (array)
	    variable scalingFromTitle;	# Histogram title when scalingFromIsNext == 1
	    variable scalingFromU;	# Used to scale z plots (NAO)
	    variable scalingIntercept;	# Used to scale z plots (NAO)
	    variable scalingSlope;	# Used to scale z plots (NAO)
	    variable scalingToZ;	# Used to scale z plots (tcl array)
	    variable scalingToTitle;	# Histogram title when scalingFromIsNext == 0
	    variable scalingToU;	# Used to scale z plots (NAO)
	    variable title "";		# Main title
	    variable upper 255;		# Upper limit of mapping
	    variable use_gshhs 0;	# 0 = Use nap_land_flag, 1 = use gshhs
	    variable want_equalise 0;	# 1 = equalise histogram
	    variable want_menu_bar 1;	# Display menu bar at top?
	    variable want_scaling_widget 1; # Display scaling widget?
	    variable want_x_axis 1;	# Draw x-axis?
	    variable want_y_axis 1;	# Draw y-axis?
	    variable xflip 0;		# 1 = flip image left-right
	    variable xlabel "";		# label of x-axis
	    variable xproc "";		# name of procedure to format x-axis tick values
	    variable yflip 0;		# 1 = flip image upside down
	    variable ylabel "";		# label of y-axis
	    variable yproc "";		# name of procedure to format y-axis tick values
	    variable zlabels "";	# labels of categories for z-axis
		# set default overlay_palette  to {black white red green blue}
	    nap "overlay_palette = f32{{3#0}{3#1}{1 0 0}{0 1 0}{0 0 1}}";
	    for {set layer 0} {$layer < 3} {incr layer} {
		set percentileFrom($layer) 0
		set percentileTo($layer) 100
		set scalingFromZ($layer) ""
		set scalingFromIsNext($layer) 1
		set scalingToZ($layer) ""
	    }
	}
	    # Make these available locally without namespace prefix
	foreach var [info vars ::Plot_nao::${window_id}::*] {
	    global $var
	}
	    # set default main_palette to "blue to red"
	Plot_nao::paletteInterpolate main_palette $window_id 240 0
	set buttonPressCommand "lappend Plot_nao::$window_id\::save \$Plot_nao::xyz"
	set buttonReleaseCommand ""
	set geometry ""
	set height "";			# height (in pixels) of image (can be "min max" for image)
	set parent ""
	set range_nao ""
	set rank_nao 3
	set type "";			# "bar", "tile", "xy" or "z" (copy to plot_type)
	set want_yflip geog; # Reverse row dimension? 0 = no, 1 = yes,
		    # ascending = "if y ascending",
		    # geog = "if ascending & (dimname = latitude|nothing or unit = degrees_north")
	set width "";			# width (in pixels) of image (can be "min max" for image)
	set dim_names [$nao dim]
	set title [$nao label]
	if {$title eq ""} {
	    set title "$nao_expr"
	}
	if {![string equal [$nao unit] (NULL)]} {
	    set title "$title ([$nao unit])"
	}
	if {[$nao nels] == 0} {
	    handle_error "Data array is empty!"
	    return
	}
	set call_level "#[expr [info level]-2]"; # stack level from which plot_nao called
	proc palette_option {name expr} "Plot_nao::set_palette \$name $window_id \$expr $call_level"
	set str [lindex $dim_names end]
	if {$str ne "(NULL)"} {
	    if {[$nao rank] == 1} {
		set cv [$nao coord]
		if {$cv eq "(NULL)"} {
		    set str ""
		} else {
		    set xunit [fix_unit [$cv unit]]
		    if {$xunit ne ""  &&  $xunit ne "degrees_east"} {
			append str " ($xunit)"
		    }
		}
	    }
	    set xlabel $str
	}
	set str [lindex $dim_names end-1]
	if {$str ne "(NULL)"} {
	    set ylabel $str
	}
	unset str
	set ::Print_gui::filename ""
	set i [process_options {
		{-barwidth {set barwidth $option_value}}
		{-buttonPressCommand {set buttonPressCommand $option_value}}
		{-buttonReleaseCommand {set buttonReleaseCommand $option_value}}
		{-colors {set colors $option_value}}
		{-columns	{set ncols $option_value}}
		{-dash {set dash_patterns $option_value}}
		{-discrete {set discrete_colors $option_value}}
		{-filename {set ::Print_gui::filename $option_value}}
		{-fill {set ::Print_gui::maxpect $option_value}}
		{-font_standard {set font_standard $option_value}}
		{-font_title {set font_title $option_value}}
		{-gap_height {set gap_height $option_value}}
		{-gap_width  {set gap_width  $option_value}}
		{-geometry {set geometry $option_value}}
		{-gshhs_min_area {nap "gshhs_min_area = [uplevel 3 "nap \"$option_value\""]"}}
		{-gshhs_resolution {set gshhs_resolution $option_value}}
		{-height {set height $option_value}}
		{-key {set key_width $option_value}}
		{-labels {set labels $option_value}}
		{-menu {set want_menu_bar $option_value}}
		{-orientation {set orientation $option_value}}
		{-overlay {set overlay_option $option_value}}
		{-oversize_prompt {set oversize_prompt $option_value}}
		{-ovpal   {palette_option overlay_palette $option_value}}
		{-palette {palette_option main_palette    $option_value}}
		{-paperheight {set ::Print_gui::paperheight $option_value}}
		{-paperwidth {set ::Print_gui::paperwidth $option_value}}
		{-parent {set parent $option_value}}
		{-print {set auto_print $option_value}}
		{-printer {set ::Print_gui::printer_name $option_value}}
		{-proj4spec {set proj4spec $option_value}}
		{-range {nap "range_nao = [uplevel 3 "nap \"$option_value\""]"}}
		{-rank  {nap "rank_nao  = [uplevel 3 "nap \"$option_value\""]"}}
		{-scaling {set want_scaling_widget $option_value}}
		{-sub_titles {set labels $option_value}}
		{-symbols {set symbols $option_value}}
		{-title {set title $option_value}}
		{-type {set type $option_value}}
		{-use_gshhs {set use_gshhs $option_value}}
		{-width {set width $option_value}}
		{-xaxis {set want_x_axis $option_value}}
		{-xflip {set xflip $option_value}}
		{-xlabel {set xlabel $option_value}}
		{-xproc {set xproc $option_value}}
		{-xticks {nap "major_ticks_x = [uplevel 3 "nap \"$option_value\""]"}}
		{-yaxis {set want_y_axis $option_value}}
		{-yflip {set want_yflip $option_value}}
		{-ylabel {set ylabel $option_value}}
		{-yproc {set yproc $option_value}}
		{-yticks {nap "major_ticks_y = [uplevel 3 "nap \"$option_value\""]"}}
		{-zlabels {set zlabels $option_value}}
		{-zticks {nap "major_ticks_z = [uplevel 3 "nap \"$option_value\""]"}}
	    } $args]
	if {$i != [llength $args]} {
	    handle_error "Illegal option"
	    return
	}
	if {$::Print_gui::filename eq ""  &&  !$auto_print} {
	    set ::Print_gui::filename tmp.ps
	}
	Plot_nao::incrRefCount $window_id $nao
	set rank_nao [[nap "i32(rank_nao <<< rank(nao))"]]
	nap "shape_frame = (shape(nao))(0 .. (rank(nao) - rank_nao - 1) ... 1)"
	set nplots [[nap "prod(shape_frame)"]]
	if {$nplots > 1} {
	    if {$geometry == ""} {
		set geometry "+[winfo rootx .]+[winfo rooty .]"
	    }
	    if {$range_nao == ""} {
		nap "range_nao = range(nao)"
	    }
	    set all ""
	    set cv0 [$nao coord 0]
	    set ::Plot_nao::control_c_pressed 0
	    bind all <Control-c> {set ::Plot_nao::control_c_pressed 1}
	    set title_copy $title
	    for {set i 0} {$i < $nplots  &&  ! $::Plot_nao::control_c_pressed} {incr i} {
		nap "tmp = (mixed_base(i, shape_frame))(1 .. nels(shape_frame) ... 1)"
		set cell_subscript "[$tmp value -format "%g,"][commas "$rank_nao-1"]"
		nap "cell = nao(cell_subscript)"
		if {$cv0 eq "(NULL)"} {
		    set cell_title "{$title_copy\n($cell_subscript)}"
		} else {
		    set cell_title "{$title_copy\n(@[[nap "cv0(tmp)"]])}"
		}
		unset tmp
		lappend all [eval Plot_nao::plot_nao $cell $args \
			-geometry $geometry \
			-oversize_prompt [expr "$i == 0"] \
			-range $range_nao \
			-title $cell_title]
	    }
	    set ::Plot_nao::control_c_pressed 0
	} else {
	    if {$type == ""} {
		switch $rank_nao {
		    1 {set type xy}
		    2 {set type [lindex "xy z" [[nap "shape_nao(-2) > 8"]]]}
		    3 {set type z}
		    default {handle_error "rank_nao has value other than 1, 2 or 3!"; return}
		}
	    }
	    set all [create_window plot_nao $parent $geometry]
	    $all configure -background white
	    incr Plot_nao::frame_id
	    set main $all.main
	    frame $main
	    set graph $main.canvas
	    canvas $graph -background white
	    pack $main -side left -expand 1 -fill both
	    $graph configure -xscrollcommand [list $main.xscroll set]
	    $graph configure -yscrollcommand [list $main.yscroll set]
	    scrollbar $main.xscroll -orient horizontal -command [list $graph xview]
	    scrollbar $main.yscroll -orient vertical   -command [list $graph yview]
	    grid $graph $main.yscroll -sticky news
	    grid $main.xscroll -sticky ew
	    grid rowconfigure $main 0 -weight 1
	    grid columnconfigure $main 0 -weight 1
	    grid remove $main.xscroll $main.yscroll
	    set ::Plot_nao::${window_id}::print_command "::Print_gui::canvas2ps $graph 0 0 0"
	    switch -glob $type {
		b* {
		    set plot_type bar
		    Plot_nao::draw_xy $all $window_id $graph $nao $range_nao $height $width
		}
		t* {
		    set plot_type tile
		    Plot_nao::draw_tiles   $all $window_id $graph $nao \
			    $range_nao $want_yflip
		}
		x* {
		    set plot_type xy
		    set barwidth 0
		    Plot_nao::draw_xy $all $window_id $graph $nao $range_nao $height $width
		}
		z  {
		    set plot_type z
		    Plot_nao::draw_z  $all $window_id $graph $nao $height $width \
			    $range_nao $want_yflip
		}
		default {
		    handle_error "Illegal graph-type"
		    return
		}
	    }
	    bind $graph <Destroy> "Plot_nao::close_window $window_id"
	    bind $graph <ButtonPress-1>  \
		    "Plot_nao::handle_button_press $window_id $graph %x %y; $buttonPressCommand"
	    bind $graph <ButtonRelease-1> \
		    "set ::Plot_nao::buttonIsDown 0; $buttonReleaseCommand"
	    bind $all <ButtonPress-3> "tk_popup $all.popup %X %Y"
	    update idletasks
	    if {$auto_print} {
		print_write $all $window_id $graph
		destroy $all
	    }
	}
	return $all
    }

    # check_cvs --
    # Check that xcv & ycv are monotonically ascending or descending.
    # If so (OK) return 0, else (error) return 1.

    proc check_cvs {
	nao
    } {
	foreach cv [lrange [$nao coord] end-1 end] {
	    if {![string equal $cv (NULL)]} {
		if {[string equal [$cv step] +-]} {
		    return 1
		}
	    }
	}
	return 0
    }

    # handle_button_press --

    proc handle_button_press {
	window_id
	graph
	screen_x
	screen_y

    } {
	set ::Plot_nao::buttonIsDown 1
	set ::Plot_nao::${window_id}::box_x0 [$graph canvasx $screen_x]
	set ::Plot_nao::${window_id}::box_y0 [$graph canvasy $screen_y]
	$graph delete box
    }

    # print_write --

    proc print_write {
	all
	window_id
	graph
    } {
	global Plot_nao::${window_id}::print_command
	global Print_gui::filename
	global Plot_nao::image_format_list
	set ext [string range [file extension $filename] 1 end]
	if {$filename == ""} {
	    ::Print_gui::print $print_command
	} elseif {[lsearch $image_format_list $ext] >= 0} {
	    write_image $window_id $all $graph $filename $ext
	} else {
	    ::Print_gui::write $print_command
	}
    }


    # close_window --
    #
    # Do things needed at end

    proc close_window {
	window_id
    } {
	global Plot_nao::${window_id}::histograms
	global Plot_nao::${window_id}::save_nao_ids
	foreach nao $save_nao_ids {
	    $nao set count -1
	}
	eval destroy $histograms
	namespace delete ::Plot_nao::$window_id
    }


    # create_main_menu --
    #
    # Create main menu as menu bar at top if wanted.
    # Also create similar pop-up menu (since main menu may not exist)
    #
    # Create "options", "cancel" and "help" buttons.
    # If argument "redraw_command" is defined then also create "redraw" button.
    # Argument "redraw_command" is defined when called from draw_z & draw_tiles.

    proc create_main_menu {
	all
	window_id
	graph
	{redraw_command ""}
	{nao ""}
    } {
	    # main menu
	global Plot_nao::${window_id}::want_menu_bar
	set m $all.main_menu
	frame $m
	if {$redraw_command eq ""} {
	    set cond_redraw_command ""
	} else {
	    button $m.redraw -text redraw -command $redraw_command
	    pack $m.redraw -side left -expand 1 -fill both
	    set name ::Plot_nao::${window_id}::auto_redraw
	    set cond_redraw_command [list if $$name $redraw_command]
	}
	menubutton $m.options -text options -menu $m.options.options_menu -relief raised
	button $m.cancel -text cancel -command "destroy $all"
	button $m.help   -text help   -command "Plot_nao::display_help"
	pack $m.options $m.cancel $m.help -side left -expand 1 -fill both
	pack $m -fill x -before $all.main -anchor n
	if {!$want_menu_bar} {
	    pack forget $m
	}
	create_options_menu $all $m.options $window_id $graph \
		$cond_redraw_command $redraw_command $nao
	    # pop-up menu
	set m $all.popup
	menu $m
	if {$redraw_command != ""} {
	    $m add command -label redraw -command $redraw_command
	}
	$m add cascade -label options -menu $m.options_menu
	$m add command -label "raise window" -command "raise $all"
	$m add command -label "move window" -command "Plot_nao::move_window $all $m"
	$m add command -label cancel -command "destroy $all"
	$m add cascade -label help -command "Plot_nao::display_help"
	create_options_menu $all $m $window_id $graph $cond_redraw_command $redraw_command
    }


    # create_options_menu --

    proc create_options_menu {
	all
	parent
	window_id
	graph
	{cond_redraw_command ""}
	{redraw_command ""}
	{nao ""}
    } {
	global Plot_nao::${window_id}::plot_type
	set options_menu $parent.options_menu
	menu $options_menu
	$options_menu add checkbutton -label "automatic redraw?" \
		-variable Plot_nao::${window_id}::auto_redraw
	$options_menu add checkbutton -label "allow scrolling?" \
		-variable Plot_nao::${window_id}::allow_scroll \
		-command $cond_redraw_command
	$options_menu add checkbutton -label "display menu-bar?" \
		-variable Plot_nao::${window_id}::want_menu_bar \
		-command [list Plot_nao::toggle_menu_bar $all $window_id]
	if {$plot_type eq "z"} {
	    $options_menu add checkbutton -label "display scaling widget?" \
		    -variable Plot_nao::${window_id}::want_scaling_widget \
		    -command [list Plot_nao::toggle_scaling $all $window_id]
	}
	if {[lsearch "tile z" $plot_type] >= 0} {
	    $options_menu add checkbutton -label "discrete colors?" \
		    -variable Plot_nao::${window_id}::discrete_colors \
		    -command $cond_redraw_command
	    $options_menu add checkbutton -label "flip left-right?" \
		    -variable Plot_nao::${window_id}::xflip \
		    -command $cond_redraw_command
	    $options_menu add checkbutton -label "flip upside down?" \
		    -variable Plot_nao::${window_id}::yflip \
		    -command $cond_redraw_command
	    set command "[list Plot_nao::create_overlay_menu $all $options_menu \
		    $window_id $cond_redraw_command $redraw_command $nao]; $cond_redraw_command"
	    $options_menu add checkbutton -label "use GSHHS shorelines?" \
		    -variable Plot_nao::${window_id}::use_gshhs \
		    -command $command
	}
	$options_menu add separator
	#
	$options_menu add cascade -label "axes" -menu $options_menu.axis
	create_axis_menu $all $options_menu $window_id $cond_redraw_command
	#
	$options_menu add cascade -label "fonts" -menu $options_menu.font
	create_font_menu $all $options_menu $window_id $cond_redraw_command
	#
	$options_menu add cascade -label "size" -menu $options_menu.size
	create_size_menu $all $options_menu $window_id $cond_redraw_command
	#
	create_enter $all $window_id $options_menu $cond_redraw_command "title" title
	#
	$options_menu add separator
	if {[lsearch "tile z" $plot_type] >= 0} {
	    $options_menu add cascade -label "map projection" \
		    -menu $options_menu.projection
	    create_projection_menu $all $options_menu $window_id $cond_redraw_command $nao
	    $options_menu add cascade -label "overlay (eg coasts)" \
		    -menu $options_menu.overlay
	    create_overlay_menu $all $options_menu $window_id $cond_redraw_command \
		    $redraw_command $nao
	    $options_menu add cascade -label "palette" \
		    -menu $options_menu.main_palette
	    create_palette_menu main_palette $all $options_menu $window_id \
		    $cond_redraw_command $redraw_command
	}
	#
	switch $plot_type {
	    bar {
		$options_menu add cascade -label "configure bars" -menu $options_menu.xy
		create_xy_menu $all $options_menu $window_id $cond_redraw_command
	    }
	    xy {
		$options_menu add cascade -label "configure graph lines" -menu $options_menu.xy
		create_xy_menu $all $options_menu $window_id $cond_redraw_command
	    }
	    tile {
		$options_menu add cascade -label "configure tile plot" -menu $options_menu.tile
		create_tile_menu $all $options_menu $window_id $cond_redraw_command
	    }
	}
	#
	$options_menu add separator
	#
	$options_menu add command -label print \
		-command [list Print_gui::widget \$Plot_nao::${window_id}::print_command $all]
	#
	$options_menu add command -label "write image file" \
		-command [list Plot_nao::write_image_gui $window_id $all $graph]
	#
	if {$plot_type eq "z"} {
	    $options_menu add command -label "write clicked (x,y,z) values" \
		    -command [list Plot_nao::write_xyz $window_id $all $graph]
	}
    }

 
    # move_window --

    proc move_window {
	all
	menu
    } {
	set label {geometry (e.g. '+0+0' for top left corner)}
	wm geometry $all [get_entry $label -geometry NW -parent $all -text +0+0]
    }

 
    # create_enter --
    # Create menu item to define standard namespace variable 'var'

    proc create_enter {
	all
	window_id
	menu
	cond_redraw_command
	label
	var
	{title ""}
    } {
	if {$title eq ""} {
	    set title $label
	}
	set v ::Plot_nao::${window_id}::$var
	set command "set $v \[get_entry [list $title] -geometry NW -parent $all "
	append command "-text \$$v\]; $cond_redraw_command"
	$menu add command -label $label -command $command
    }


    # create_xy_menu --
    # create menu for xy-graphs & barcharts

    proc create_xy_menu {
	all
	options_menu
	window_id
	cond_redraw_command
    } {
	global Plot_nao::${window_id}::plot_type
	set m $options_menu.xy
	menu $m
	set word(bar) bar
	set word(xy)  xy-graph
	switch $plot_type {
	    bar {
		create_enter $all $window_id $m $cond_redraw_command "bar width" barwidth
	    }
	    xy {
		create_enter $all $window_id $m $cond_redraw_command \
			"xy-graph dash-patterns" dash_patterns
		create_enter $all $window_id $m $cond_redraw_command \
			"xy-graph symbols" symbols
	    }
	}
	create_enter $all $window_id $m $cond_redraw_command "$word($plot_type) colors" colors
	create_enter $all $window_id $m $cond_redraw_command "$word($plot_type) labels" labels
    }


    # create_size_menu --

    proc create_size_menu {
	all
	options_menu
	window_id
	cond_redraw_command
    } {
	set m $options_menu.size
	menu $m
	#
	set name ::Plot_nao::${window_id}::magnification
	set command "set $name"
	append command { [get_entry "magnification factor (relative to original NAO)"}
	append command " -geometry NW -parent $all -text \[expr {$$name eq \"\" ? 1 : $$name}]]"
	append command "; $cond_redraw_command"
	$m add command -label "adjust height & width of image" -command $command
	#
	set command "set $name {}; $cond_redraw_command"
	create_enter $all $window_id $m $command "image width in pixels" new_width
	create_enter $all $window_id $m $command "image height in pixels" new_height
	create_enter $all $window_id $m $cond_redraw_command \
		"key width in pixels (no key if blank)" key_width
	create_enter $all $window_id $m $cond_redraw_command \
		"width of vertical gaps (pixels)" gap_width
	create_enter $all $window_id $m $cond_redraw_command \
		"height of horizontal gaps (pixels)" gap_height
    }


    # define_major_ticks --
    #
    # used by create_major_ticks_entry

    proc define_major_ticks {
	window_id
	xyz
    } {
	set from [set ::Plot_nao::${window_id}::major_ticks_${xyz}_from]
	set to   [set ::Plot_nao::${window_id}::major_ticks_${xyz}_to]
	set step [set ::Plot_nao::${window_id}::major_ticks_${xyz}_step]
	if {$from eq ""} {set from 0}
	if {$to   eq ""} {set to   1}
	if {$step eq ""  ||  $step == 0} {set step 1}
	nap "step = sign(to-from) * abs(step)"
	nap "::Plot_nao::${window_id}::major_ticks_$xyz = from .. to ... step"
    }


    # valid_double --
    #
    # used by create_major_ticks_entry

    proc valid_double {
	value
    } {
	expr [string is double $value] || [string match {[-+]} $value]
    }


    # create_major_ticks_entry --
    #
    # Create widget for entry of: from, to, step

    proc create_major_ticks_entry {
	all
	window_id
	xyz
	title
	cond_redraw_command
    } {
	if {[yes_no "Do you want equal steps (arithmetic progression)?" \
		-geometry NW -parent $all]} {
	    set name "::Plot_nao::${window_id}::major_ticks_$xyz"
	    nap "ticks = name"
	    set value(from) [[nap "ticks(0)"]]
	    set value(to)   [[nap "ticks(-1)"]]
	    set value(step) [[nap "ticks(1) - ticks(0)"]]
	    set w [create_window ticks $all NW]
	    label $w.title -text $title
	    grid $w.title -columnspan 2
	    foreach what {from to step} {
		label $w.${what}_label -text ${what} -justify right
		set var "${name}_${what}"
		set $what $var
		set $var $value($what)
		entry $w.${what}_entry -textvariable $var -width 16 \
			-validate all -vcmd {::Plot_nao::valid_double %P}
		grid $w.${what}_label $w.${what}_entry -sticky w
	    }
	    frame $w.buttons
	    set command "::Plot_nao::define_major_ticks $window_id $xyz; \
		    destroy $w; $cond_redraw_command"
	    button $w.buttons.accept -text accept -command $command
	    bind $w <Return> $command
	    set command "set $name {}; destroy $w; $cond_redraw_command"
	    button $w.buttons.auto -text automatic -command $command
	    set command "destroy $w"
	    button $w.buttons.cancel -text cancel -command $command
	    pack $w.buttons.accept $w.buttons.auto $w.buttons.cancel -side left
	    grid $w.buttons -columnspan 2
	} else {
	    set expr [get_entry expression -geometry NW -parent $all -width 40]
	    nap "::Plot_nao::${window_id}::major_ticks_$xyz = expr"
	    eval $cond_redraw_command
	}
    }


    # clear_z_categories --

    proc clear_z_categories {
	all
	window_id
	cond_redraw_command
    } {
	set ::Plot_nao::${window_id}::cvz ""
	set ::Plot_nao::${window_id}::discrete_colors 0
	set ::Plot_nao::${window_id}::major_ticks_z ""
	set ::Plot_nao::${window_id}::mapping ""
	set ::Plot_nao::${window_id}::zlabels ""
	set ::Plot_nao::${window_id}::range_nao ""
	set ::Plot_nao::${window_id}::scalingFromU ""
	set ::Plot_nao::${window_id}::scalingToU ""
	for {set layer 0} {$layer < 3} {incr layer} {
	    set ::Plot_nao::${window_id}::scalingFromZ($layer) ""
	    set ::Plot_nao::${window_id}::scalingToZ($layer) ""
	}
	eval $cond_redraw_command
    }


    # create_axis_menu --

    proc create_axis_menu {
	all
	options_menu
	window_id
	cond_redraw_command
    } {
	set r [list $cond_redraw_command]
	set m $options_menu.axis
	menu $m
	foreach xyz {x y} {
	    $m add checkbutton -label "Draw $xyz-axis?" \
		    -variable ::Plot_nao::${window_id}::want_${xyz}_axis \
		    -command $cond_redraw_command
	}
	foreach xyz {x y} {
	    create_enter $all $window_id $m $cond_redraw_command "${xyz}-axis label" ${xyz}label
	}
	foreach xyz {x y z} {
	    set label "${xyz}-axis major ticks"
	    set command "::Plot_nao:::create_major_ticks_entry $all $window_id $xyz {$label} $r"
	    $m add command -label $label -command $command
	}
	create_enter $all $window_id $m $cond_redraw_command "z-category labels" zlabels
	set command "::Plot_nao:::clear_z_categories $all $window_id $r"
	$m add command -label "clear z-category labels" -command $command
    }


    # create_font_menu --

    proc create_font_menu {
	all
	options_menu
	window_id
	cond_redraw_command
    } {
	set m $options_menu.font
	menu $m
	#
	set label "standard font (axes, etc.)"
	set varname ::Plot_nao::${window_id}::font_standard
	set command "[list select_font $all $label $varname]; $cond_redraw_command"
	$m add command -label $label -command $command
	#
	set label "title font (top of page)"
	set varname ::Plot_nao::${window_id}::font_title
	set command "[list select_font $all $label $varname]; $cond_redraw_command"
	$m add command -label $label -command $command
    }


    # create_palette_menu --

    proc create_palette_menu {
	name
	all
	parent
	window_id
	cond_redraw_command
	redraw_command
    } {
	set palette_menu $parent.$name
	menu $palette_menu
	$palette_menu add command -label "black to white" \
		-command "Plot_nao::set_palette $name $window_id {}; $cond_redraw_command"
	$palette_menu add command -label "white to black" \
		-command "Plot_nao::set_palette $name $window_id \
			\"transpose(reshape(255 .. 0 ... -1, 3 // 256))\"; $cond_redraw_command"
	$palette_menu add command -label "blue to red (white = missing)" -command \
		"Plot_nao::paletteInterpolate $name $window_id 240 0; $cond_redraw_command"
	$palette_menu add command -label "red to blue (white = missing)" -command \
		"Plot_nao::paletteInterpolate $name $window_id 0 240; $cond_redraw_command"
	$palette_menu add command -label "green to red (white = missing)" -command \
		"Plot_nao::paletteInterpolate $name $window_id -240 0; $cond_redraw_command"
	$palette_menu add command -label "red to green (white = missing)" -command \
		"Plot_nao::paletteInterpolate $name $window_id 0 -240; $cond_redraw_command"
	$palette_menu add command \
		-label "default overlay palette: 0=black, 1=white, 2=red, 3=green, 4=blue" \
		-command "nap \"::Plot_nao::${window_id}::overlay_palette =
			f32{{3#0}{3#1}{1 0 0}{0 1 0}{0 0 1}}\"; $cond_redraw_command"
	$palette_menu add command -label "define palette using 'pal' GUI" \
		-command [list pal ::Plot_nao::${window_id}::$name $redraw_command]
	$palette_menu add command -label "define palette using NAP expression" \
		-command "Plot_nao::palette_nap $name $all $window_id; $cond_redraw_command"
	$palette_menu add command -label "read palette from text file" \
		-command "Plot_nao::palette_file $name $all $window_id; $cond_redraw_command"
    }


    # create_orientation_menu --

    proc create_orientation_menu {
	all
	parent
	window_id
    } {
	set m $parent.orientation
	menu $m
	set var ::Plot_nao::${window_id}::orientation
	$m add radiobutton -label portrait  -variable $var -value P
	$m add radiobutton -label landscape -variable $var -value L
	$m add radiobutton -label automatic -variable $var -value A
    }


    # create_tile_menu --
    # create menu for tiles

    proc create_tile_menu {
	all
	parent
	window_id
	cond_redraw_command
    } {
	global Plot_nao::${window_id}::plot_type
	set m $parent.tile
	menu $m
	create_enter $all $window_id $m $cond_redraw_command "number of tile columns" ncols
	create_enter $all $window_id $m $cond_redraw_command "tile labels" labels
	$m add cascade -label "set orientation of page" -menu $m.orientation
	create_orientation_menu $all $m $window_id
    }


    # create_overlay_menu --

    proc create_overlay_menu {
	all
	parent
	window_id
	cond_redraw_command
	redraw_command
	nao
    } {
	global Plot_nao::${window_id}::use_gshhs
	set m $parent.overlay
	destroy $m
	menu $m
	$m add command -label "set overlay NAO coast values to 0" \
		-command "set ::Plot_nao::${window_id}::overlay_option C; $cond_redraw_command"
	if {$use_gshhs} {
	    create_enter $all $window_id $m $cond_redraw_command \
		"minimum area of GSHHS polygons" gshhs_min_area \
		"Enter up to 4 values ('-1' means 'automatic') to specify minimum area (km**2) of:\
		\nland, lakes, islands in lakes, ponds in such islands"
	    create_enter $all $window_id $m $cond_redraw_command \
		"GSHHS resolution" gshhs_resolution \
		"Enter resolution in km ('-1' means 'automatic')"
	} else {
	    $m add command -label "set overlay NAO land values to 2" \
		    -command "set ::Plot_nao::${window_id}::overlay_option L; $cond_redraw_command"
	    $m add command -label "set overlay NAO sea values to 4" \
		    -command "set ::Plot_nao::${window_id}::overlay_option S; $cond_redraw_command"
	}
	$m add command -label "set overlay NAO using NAP expression" \
		-command "::Plot_nao::overlay_nap $all $window_id $nao; $cond_redraw_command"
	#
	$m add command -label "clear overlay NAO" \
		-command "set ::Plot_nao::${window_id}::overlay_option N; $cond_redraw_command"
	#
	$m add separator
	#
	$m add cascade -label "define overlay palette" -menu $m.overlay_palette
	create_palette_menu overlay_palette $all $m $window_id $cond_redraw_command $redraw_command
    }


    # select_utm_zone_ok --
    # Procedure called by select_utm_zone ok button

    proc select_utm_zone_ok {
	window_id
	cond_redraw_command
	nao
	win
    } {
	global ::Plot_nao::${window_id}::proj4spec
	set zone [$win.spin set]
	set proj4spec "proj=utm zone=$zone"
	destroy $win
	eval $cond_redraw_command
    }


    # select_utm_zone --

    proc select_utm_zone {
	all
	window_id
	cond_redraw_command
	nao
    } {
	set win [create_window plot_nao_zone $all NW]
	label $win.label -text "Select UTM zone"
	spinbox $win.spin -from 1 -to 60 -state readonly -wrap 1
	nap "longitude = coordinate_variable(nao, -1)"
	nap "lon_mid = 0.5 * (longitude(0) + longitude(-1))"
	set zone [[nap "<((lon_mid + 180.0) % 360.0 / 6.0) + 1"]]
	$win.spin set $zone
	set command [list Plot_nao::select_utm_zone_ok $window_id $cond_redraw_command $nao $win]
	button $win.ok -text OK -command $command
	pack $win.label $win.spin $win.ok
    }


    # set_proj4spec --
    # Used by create_projection_menu

    proc set_proj4spec {
	window_id
	cond_redraw_command
	nao
    } {
	global ::Plot_nao::${window_id}::projection
	global ::Plot_nao::${window_id}::proj4spec
	nap "longitude = coordinate_variable(nao, -1)"
	nap "lon_mid = longitude(0) + 180"
	if {$projection eq "eqc"} {
	    set proj4spec ""
	} else {
	    set proj4spec "proj=$projection lon_0=[$lon_mid]"
	}
	eval $cond_redraw_command
    }


    # create_projection_menu --

    proc create_projection_menu {
	all
	parent
	window_id
	cond_redraw_command
	nao
    } {
	set m $parent.projection
	menu $m
	set var ::Plot_nao::${window_id}::projection
	set $var [proj4parameter $window_id proj]
	if {[set $var] eq ""} {
	    set $var eqc
	}
	set command [list Plot_nao::set_proj4spec $window_id $cond_redraw_command $nao]
	$m add radiobutton -variable $var -command $command \
		-value eqc -label "Equidistant Cylindrical"
	foreach lat_ts {0 30 45} {
	    $m add radiobutton -variable $var -command $command \
		    -value "cea lat_ts=$lat_ts" \
		    -label "Lambert Cylindrical Equal-Area with true scale at latitude $lat_ts"
	}
	$m add radiobutton -variable $var -command $command \
		-value "laea lat_0=90" -label "Lambert Azimuthal Equal-Area North"
	$m add radiobutton -variable $var -command $command \
		-value "laea lat_0=-90" -label "Lambert Azimuthal Equal-Area South"
	$m add radiobutton -variable $var -command $command \
		-value merc -label "Mercator"
	$m add radiobutton -variable $var -command $command \
		-value moll -label "Mollweide"
	$m add radiobutton -variable $var -command $command \
		-value ortho -label "Orthographic"
	$m add radiobutton -variable $var -command $command \
		-value robin -label "Robinson"
	$m add radiobutton -variable $var -command $command \
		-value "sinu" -label "Sinusoidal Equal-Area"
	$m add radiobutton -variable $var -command $command \
		-value "ups" -label "Universal Polar Stereographic (UPS) North"
	$m add radiobutton -variable $var -command $command \
		-value "ups south" -label "Universal Polar Stereographic (UPS) South"
	set command [list Plot_nao::select_utm_zone $all $window_id $cond_redraw_command $nao]
	$m add radiobutton -variable $var -value utm \
		-label "Universal Transverse Mercator (UTM)" -command $command
	create_enter $all $window_id $m $cond_redraw_command other proj4spec "PROJ.4 specification" 
    }


    # write_image --
    # write canvas to image file

    proc write_image {
	window_id
	all
	graph
	filename
	image_format
    } {
	global Plot_nao::image_format_list
	if {[lsearch $image_format_list $image_format] < 0} {
	    handle_error "image format '$image_format' is not supported"
	    return
	}
	raise $all
	update
	if [catch {image create photo -format window -data $graph} img] {
	    handle_error "error creating image"
	    return
	}
	if [catch {$img write $filename -format $image_format} msg] {
	    handle_error "Error writing image file $filename\n$msg"
	    return
	}
    }


    # write_image_save --
    # Write canvas to image file

    proc write_image_save {
	window_id
	all
	graph
    } {
	global Plot_nao::${window_id}::image_format
	set top .image_tmp_top
	toplevel $top
	wm geometry $top "+[winfo x $all]+[winfo y $all]"
	switch $image_format {
	    jpeg    {set ext jpg}
	    tiff    {set ext tif}
	    default {set ext $image_format}
	}
	set filename "plot.$ext"
	set filename [tk_getSaveFile -initialfile $filename -title "Image Filename" \
		-parent $top]
	destroy $top
	if {$filename ne ""} {
	    write_image $window_id $all $graph $filename $image_format
	}
    }


    # write_image_gui --
    # Create GUI to write canvas to image file

    proc write_image_gui {
	window_id
	all
	graph
    } {
	global Plot_nao::${window_id}::image_format
	global Plot_nao::image_format_list
	set top .image_tmp_top
	toplevel $top
	wm geometry $top "+[winfo x $all]+[winfo y $all]"
	wm title $top "Select format"
	label $top.label -text "Select format of output image file"
	pack $top.label
	foreach fmt $image_format_list {
	    radiobutton $top.$fmt -text $fmt -value $fmt \
		    -variable ::Plot_nao::${window_id}::image_format
	    pack $top.$fmt -anchor w
	}
	set buttons $top.buttons
	frame $buttons
	button $buttons.ok -text OK -command \
		"destroy $top; Plot_nao::write_image_save $window_id $all $graph"
	button $buttons.cancel -text Cancel -command "destroy $top"
	pack $buttons.ok $buttons.cancel -side left -fill x -expand 1
	pack $buttons -anchor w -fill x -expand 1
	tkwait window $top
    }


    # write_xyz --
    # write saved (x,y,z) values to file

    proc write_xyz {
	window_id
	all
	graph
    } {
	global Plot_nao::${window_id}::save
	set top .xyz_tmp_top
	toplevel $top
	wm geometry $top "+[winfo x $all]+[winfo y $all]"
	set filename xyz.txt
	set filename [tk_getSaveFile -initialfile $filename -title "(x,y,z) Filename" \
		-parent $top]
	destroy $top
	if {$filename ne ""} {
	    set f [open $filename w]
	    puts $f [join $save "\n"]
	    close $f
	}
    }


    # isCoast --

    proc isCoast {
	latitude
	longitude
	{nlat 1}
    } {
	nap "is_coast(latitude, longitude, nlat)"
    }


    # isSea --

    proc isSea {
	latitude
	longitude
    } {
	nap "! is_land(latitude, longitude)"
    }


    # overlay_land_flag --

    proc overlay_land_flag {
	window_id
	f
	value
	nao
	{latitude ""}
	{longitude ""}
    } {
	global Plot_nao::${window_id}::use_gshhs
	global Plot_nao::${window_id}::gshhs_min_area
	global Plot_nao::${window_id}::gshhs_resolution
	global Plot_nao::${window_id}::overlay_nao
	global Plot_nao::${window_id}::proj4spec
	if {$overlay_nao == ""  ||
		[[nap "! prod((shape overlay_nao){-2 -1} == (shape nao){-2 -1})"]]} {
	    nap "overlay_nao = 255u8"
	    $overlay_nao set missing 255
	}
	nap "area = {[[nap "reshape{$gshhs_min_area}"] value]}"
	switch [projection_type $window_id] {
	    0 -
	    1 {
		nap "longitude = coordinate_variable(nao, -1)"
		nap "latitude  = coordinate_variable(nao, -2)"
		if {$use_gshhs} {
		    nap "tmp = reshape(255f32, nels(latitude) // nels(longitude))"
		    $tmp set coo latitude longitude
		    nap "o = u8(^proj4gshhs(tmp, '$proj4spec', 0, 0, value, area,
			    gshhs_resolution))"
		} else {
		    if [catch "nap o = ${f}(latitude, longitude) ? u8(value) : overlay_nao" r] {
			handle_error "overlay_land_flag: Error defining overlay"
			nap "o = reshape(255u8, nels(latitude) // nels(longitude))"
		    }
		}
		nap "overlay_nao = o"
		$overlay_nao set coo latitude longitude
	    }
	    2 {
		if {$use_gshhs} {
		    if {$latitude ne ""  &&  $longitude ne ""} {
			nap "tmp = reshape(255f32, nels(latitude) // nels(longitude))"
			$tmp set coo latitude longitude
			$tmp set missing 255f32
			nap "o = proj4gshhs(tmp, '$proj4spec', 0, 0, value, area, gshhs_resolution)"
			nap "overlay_nao = u8(^o)"
		    } else {
			handle_error "overlay_land_flag: latitude or longitude not defined"
		    }
		} else {
		    nap "easting  = coordinate_variable(nao, -1)"
		    nap "northing = coordinate_variable(nao, -2)"
		    nap "ymat = reshape(nels(easting) # northing, nels(northing) // nels(easting))"
		    nap "latlon = cart_proj_inv('$proj4spec', easting, ymat)"
		    nap "latitude  = latlon(,,0)"
		    nap "longitude = latlon(,,1)"
		    if [catch "nap o = ${f}(latitude, longitude) ? u8(value) : overlay_nao" r] {
			handle_error "overlay_land_flag: Error defining overlay"
			nap "o  = reshape(255u8, nels(northing) // nels(easting))"
		    }
		    nap "overlay_nao = o"
		    $overlay_nao set coo northing easting
		}
	    }
	}
	$overlay_nao set missing 255
    }


    # proj4parameter --
    # Extract value of 1st parameter 'name' from variable 'proj4spec'
    # If 'name' exists without '=' then return "yes"
    # If no 'name' exists then return ""

    proc proj4parameter {
	window_id
	name
    } {
	global ::Plot_nao::${window_id}::proj4spec
	set exp "^$name="
	foreach s $proj4spec {
	    if {[regexp $exp $s]} {
		return [regsub $exp $s {}]
	    } elseif {$s eq $name} {
		return yes
	    }
	}
	return
    }


    # projection_type --
    #
    # Return 0 if none, 1 if simple cylindrical projection, 2 if other projection

    proc projection_type {
	window_id
    } {
	switch -regexp [proj4parameter $window_id proj] {
	    {^$}		{return 0}
	    {cea.*|eqc|merc}	{return 1}
	    default		{return 2}
	}
    }


    # display_help --

    proc display_help {
    } {
	set file [file join $::nap_library help_plot_nao.pdf]
	if {[file readable $file]} {
	    auto_open $file
	} else {
	    handle_error "Unable to read file $file"
	}
    }


    # toggle_menu_bar --
    #
    # Make menu-bar visible or invisible

    proc toggle_menu_bar {
	all
	window_id
    } {
	global Plot_nao::${window_id}::want_menu_bar
	set m $all.main_menu
	if {$want_menu_bar} {
	    pack $m -before [lindex [pack slaves $all] 0] -fill x -anchor n
	} else {
	    pack forget $m
	}
	update idletasks
    }


    # toggle_scaling --
    #
    # Make scaling_range widget visible or invisible

    proc toggle_scaling {
	all
	window_id
    } {
	global Plot_nao::${window_id}::want_scaling_widget
	if {$want_scaling_widget} {
	    pack $all.scaling_range -before $all.main -anchor n -fill x
	} else {
	    pack forget $all.scaling_range
	}
	update idletasks
    }


    # create_scaling_range --
    #
    # Create "histogram menu" button & entry widgets for min & max values defining
    # scaling for z plots

    proc create_scaling_range {
	all
	window_id
	frame
	nao
	layer
	color
	redraw_command
    } {
	destroy $frame
	frame $frame -relief ridge -borderwidth 3
	set menu $frame.histogram.menu 
	menubutton $frame.histogram -text "histogram menu" -pady 0.3m -relief raised -menu $menu
	menu $menu -tearoff 0
	$menu add command -label "Display histogram" -command \
	    [list Plot_nao::plot_histogram $all $window_id $nao $layer $color $redraw_command]
	$menu add command -label "Display ogive" -command \
	    [list Plot_nao::plot_ogive $all $window_id $nao $layer $color $redraw_command]
	$menu add command -label "Trim tails of histogram" -command \
	    [list Plot_nao::trim_histogram $all $window_id $nao $layer $color $redraw_command]
	$menu add checkbutton -label "Equalise histogram?" \
	    -variable Plot_nao::${window_id}::want_equalise \
	    -command \
	    [list Plot_nao::equalise_histogram $all $window_id $nao $layer $color $redraw_command]
	label $frame.from -text "Scale from"
	entry $frame.from_entry -relief sunken -width 10 \
		-textvariable Plot_nao::${window_id}::scalingFromZ($layer)
	label $frame.to -text "to"
	entry $frame.to_entry -relief sunken -width 10 \
		-textvariable Plot_nao::${window_id}::scalingToZ($layer)
	pack $frame.histogram $frame.from $frame.from_entry $frame.to $frame.to_entry \
		-side left -anchor w -fill y
	if {$color != "black"} {
	    $frame configure -background $color
	}
	pack $frame -anchor w -fill x -expand 1
    }


    # overlay_nap --
    #
    # Get NAP expression from user & use it to define overlay_nao

    proc overlay_nap {
	all
	window_id
	nao
    } {
	set expr [get_entry expression -geometry NW -parent $all -width 40]
	set ::Plot_nao::${window_id}::overlay_option "E $expr"
	set_overlay $window_id $nao
    }


    # palette_file --
    #
    # Read palette from file

    proc palette_file {
	name 
	all
	window_id
    } {
	set filename [tk_getOpenFile \
		-defaultextension .pal \
		-filetypes {{{Palette Files} {.pal}}} \
		-parent $all \
		-title "palette file" \
	]
	set_palette $name $window_id "gets_matrix('$filename')"
    }


    # palette_nap --
    #
    # Get NAP expression from user & use it to define palette

    proc palette_nap {
	name 
	all
	window_id
    } {
	set expr [get_entry expression -geometry NW -parent $all -width 40]
	set_palette $name $window_id $expr
    }


    # set_palette --
    #
    # Define either main_palette or overlay_palette using specified NAP expression, which
    # is evaluated in caller's namespace
    # If expr is "" then set palette to ""

    proc set_palette {
	name 
	window_id
	expr
	{call_level #0}
    } {
	set n ::Plot_nao::${window_id}::$name
	if {$expr == ""} {
	    set $n ""
	} else {
	    if [catch "uplevel $call_level nap \"$n = $expr\"" result] {
		handle_error $result
		return
	    }
	}
    }


    # paletteInterpolate --
    #
    # Define palette by interpolating round colour wheel (with s = v = 1)
    # from & to are angles in degrees (Red = 0, green = -240, blue = 240)

    proc paletteInterpolate {
	name
	window_id
	from
	to
    } {
	nap "::Plot_nao::${window_id}::$name = palette_interpolate(from, to)"
    }


    # set_overlay --
    #
    # Define overlay_nao.
    # If overlay_option is "none" then set overlay_nao to "".
    # If overlay_option is "coast", "land" or "sea" then set overlay_nao using "land_flag", using
    #   coordinate vars of <nao> for latitude & longitude.
    # If overlay_option is "auto" then treat as "coast" if cv units are geographic
    # If overlay_option is "expr" then set overlay_nao using NAP expression specified by <nao>.
    #    This expression is evaluated in caller's namespace.
    # overlay_option can be abbreviated to 1st letter.

    proc set_overlay {
	window_id
	nao
	{latitude ""}
	{longitude ""}
	{call_level #0}
    } {
	global Plot_nao::${window_id}::overlay_nao
	global Plot_nao::${window_id}::overlay_option
	global Plot_nao::${window_id}::proj4spec
	switch [string toupper [string index $overlay_option 0]] {
	    N	{set overlay_nao ""}
	    C	{overlay_land_flag $window_id isCoast 0 $nao $latitude $longitude}
	    L	{overlay_land_flag $window_id is_land  2 $nao $latitude $longitude}
	    S	{overlay_land_flag $window_id isSea 4 $nao $latitude $longitude}
	    A	{
		set overlay_nao ""
		set unit_x [fix_unit [[nap "coordinate_variable(nao,-1)"] unit]]
		set unit_y [fix_unit [[nap "coordinate_variable(nao,-2)"] unit]]
		if {$unit_x eq "degrees_east" && $unit_y eq "degrees_north" || $proj4spec ne ""} {
		    overlay_land_flag $window_id isCoast 0 $nao $latitude $longitude
		}
	    }
	    E	{
		set expr [lrange $overlay_option 1 end]
		set tmp ::Plot_nao::${window_id}::overlay_nao
		if [catch "uplevel $call_level nap $tmp = $expr" result] {
		    handle_error $result
		    return
		}
	    }
	}
	if {$overlay_nao != ""} {
	    nap "x = coordinate_variable(nao,-1)"
	    nap "y = coordinate_variable(nao,-2)"
	    # If overlay_nao is boxed (polyline) then convert to overlay matrix
	    if {[$overlay_nao datatype] == "boxed"} {
		nap "box = $overlay_nao"
		nap "overlay_nao = reshape(f32(_), (shape(nao)){-2 -1})"
		$overlay_nao set coord $y $x
		set n [$box nels]
		for {set i 0} {$i < $n} {incr i} {
		    nap "xy = open_box(box(i))"
		    nap "col = x @@ xy(0,)"
		    nap "row = y @@ xy(1,)"
		    nap "col_row = col /// row"
		    $overlay_nao draw col_row 0
		}
	    } else {
		nap "cvx = coordinate_variable(overlay_nao,-1)"
		nap "cvy = coordinate_variable(overlay_nao,-2)"
		nap "overlay_nao = overlay_nao(@@$y,@@$x)"
		nap "cvx = coordinate_variable(overlay_nao,-1)"
		nap "cvy = coordinate_variable(overlay_nao,-2)"
		if {[fix_unit [$cvx unit]] == "degrees_east"} {
		    nap "cvx = fix_longitude(cvx)"
		}
		$overlay_nao set coord $cvy $cvx
	    }
	}
    }


    # plot_histogram --
    #
    # Plot histogram (frequencies)

    proc plot_histogram {
	all
	window_id
	nao
	layer
	color
	redraw_command
	{n 100}
	{height 250}
	{width  300}
    } {
	global Plot_nao::${window_id}::histograms
	global Plot_nao::${window_id}::scalingFromTitle
	global Plot_nao::${window_id}::scalingToTitle
	set main $all.main
	set geometry +[winfo rootx $main]+[winfo rooty $main]
	if [[nap "rank(nao) == 3"]] {
	    set text "Histogram of layer $layer"
	    nap "data = f32(nao(layer,,))"
	} else {
	    set text "Histogram"
	    nap "data = f32(nao)"
	}
	set scalingFromTitle "$text\nLeft click to set 'from' value"
	set scalingToTitle "$text\nLeft click to set 'to' value"
	set color [color_of_layer $nao $layer]
	nap "f = define_histogram(data, 0, n)"
	nap "tmp = coordinate_variable(f)"
	nap "delta = tmp(1) - tmp(0)"
	set buttonPressCommand \
		"Plot_nao::histogram_button_command $window_id $layer [llength $histograms]"
	set histogram [::Plot_nao::plot_nao $f \
		-barwidth [$delta] \
		-buttonPressCommand $buttonPressCommand \
		-colors $color \
		-geometry $geometry \
		-height $height \
		-title $scalingFromTitle \
		-type bar \
		-width $width \
	]
	lappend histograms $histogram
    }


    # plot_ogive --
    #
    # Plot ogive (relative cumulative frequencies)

    proc plot_ogive {
	all
	window_id
	nao
	layer
	color
	redraw_command
	{n 100}
	{height 250}
	{width  300}
    } {
	global Plot_nao::${window_id}::histograms
	global Plot_nao::${window_id}::scalingFromTitle
	global Plot_nao::${window_id}::scalingToTitle
	set main $all.main
	set geometry +[winfo rootx $main]+[winfo rooty $main]
	if [[nap "rank(nao) == 3"]] {
	    set text "Ogive of layer $layer"
	    nap "data = f32(nao(layer,,))"
	} else {
	    set text "Ogive"
	    nap "data = f32(nao)"
	}
	set scalingFromTitle "$text\nLeft click to set 'from' value"
	set scalingToTitle "$text\nLeft click to set 'to' value"
	set color [color_of_layer $nao $layer]
	nap "f = define_histogram(data, 0, n)"
	nap "tmp = coordinate_variable(f)"
	nap "delta = tmp(1) - tmp(0)"
	nap "rcf = 100f32 * psum(f) / sum(f)"
	$rcf set coo $tmp
	set buttonPressCommand \
		"Plot_nao::histogram_button_command $window_id $layer [llength $histograms]"
	set ogive [::Plot_nao::plot_nao $rcf \
		-buttonPressCommand $buttonPressCommand \
		-colors $color \
		-geometry $geometry \
		-height $height \
		-title $scalingFromTitle \
		-width $width \
		-ylabel "percentile" \
	]
	lappend histograms $ogive
    }


    # trim_histogram --
    #
    # Adjust scalingFromZ & scalingToZ to specified percentiles

    proc trim_histogram {
	all
	window_id
	nao
	layer
	color
	redraw_command
	{top .trimTop}
    } {
	destroy $top
	toplevel $top
	wm geometry $top "+[winfo x $all]+[winfo y $all]"
	wm title $top "Trim Histogram"
	set frame $top.trim
	frame $frame -relief ridge -borderwidth 3
	label $frame.from -text "Scale from percentile"
	spinbox $frame.from_entry -relief sunken -width 10 -from 0 -to 100 \
		-validate all -vcmd "Plot_nao::validate_percentile %P" \
		-textvariable Plot_nao::${window_id}::percentileFrom($layer)
	label $frame.to -text "to percentile"
	spinbox $frame.to_entry -relief sunken -width 10 -from 0 -to 100 \
		-validate all -vcmd "Plot_nao::validate_percentile %P" \
		-textvariable Plot_nao::${window_id}::percentileTo($layer)
	pack $frame.from $frame.from_entry $frame.to $frame.to_entry \
		-side left -anchor w -fill y
	if {$color != "black"} {
	    $frame configure -background $color
	}
	set buttons $top.buttons
	frame $buttons
	set command "destroy $top; \
		[list Plot_nao::trim_histogram_ok $window_id $layer $nao $redraw_command]"
	bind $top <Return> $command
	button $buttons.ok -text OK -command $command
	button $buttons.cancel -text Cancel -command "destroy $top"
	pack $buttons.ok $buttons.cancel -side left -fill x -expand 1
	pack $frame $buttons -anchor w -fill x -expand 1
    }


    # validate_percentile --

    proc validate_percentile {
	percentile
    } {
	if {$percentile eq ""} {
	    return 1
	}
	return [expr [string is double $percentile]  &&  $percentile >= 0  &&  $percentile <= 100]
    }


    # trim_histogram_ok --
    #
    # called by trim_histogram as command when user presses "OK'

    proc trim_histogram_ok {
	window_id
	layer
	nao
	redraw_command
    } {
	global Plot_nao::${window_id}::auto_redraw
	global Plot_nao::${window_id}::percentileFrom
	global Plot_nao::${window_id}::percentileTo
	global Plot_nao::${window_id}::scalingFromZ
	global Plot_nao::${window_id}::scalingToZ
	if {$percentileFrom($layer) eq ""} {
	    set percentileFrom($layer) 0
	}
	if {$percentileTo($layer) eq ""} {
	    set percentileTo($layer) 0
	}
	if [[nap "rank(nao) == 3"]] {
	    nap "data = f32(nao(layer,,))"
	} else {
	    nap "data = f32(nao)"
	}
	nap "f = f32(define_histogram(data))"
	nap "rcf = psum(f) / sum(f)"
	set tmp [expr 0.01 * $percentileFrom($layer)]
	set scalingFromZ($layer) [[nap "(coordinate_variable(f))(rcf @ tmp)"]]
	set tmp [expr 0.01 * $percentileTo($layer)]
	set scalingToZ($layer)   [[nap "(coordinate_variable(f))(rcf @ tmp)"]]
	if {$auto_redraw} {
	    eval $redraw_command
	}
    }


    # equalise_histogram --
    #
    # Perform/prevent histogram equalisation

    proc equalise_histogram {
	all
	window_id
	nao
	layer
	color
	redraw_command
	{m 255}
	{n 32000}
    } {
	global Plot_nao::${window_id}::discrete_colors
        global Plot_nao::${window_id}::mapping
        global Plot_nao::${window_id}::upper
        global Plot_nao::${window_id}::want_equalise
	if {$want_equalise} {
	    if [[nap "rank(nao) == 3"]] {
		nap "data = f32(nao(layer,,))"
	    } else {
		nap "data = f32(nao)"
	    }
	    nap "f = f32(define_histogram(data, 0, n))"
	    nap "rcf_old = 0f32 // (psum(f) / sum(f))"
	    nap "rcf_new = (m+1) ... 0f32 .. 1f32"
	    nap "i = rcf_old @@ rcf_new"
	    nap "j = 0 .. (m-1)"
	    nap "mapping = (i(j+1) - i(j)) # j"
	    set upper $n
	    set discrete_colors 0
	} else {
	    set mapping ""
	    set upper 255
	}
	eval $redraw_command
    }


    # define_histogram --
    #
    # Function giving frequencies
    # n = no. classes
    #
    # If full is 0 then 
    #    - CV contains middle values of each class
    #    - min(data) = min of first class 
    #    - max(data) = max of final class
    # If full is 1 then 
    #    - CV contains max values of each class
    #    - min(data) = min of first class = max of first class 
    #    - max(data) = max of final class

    proc define_histogram {
	data
	{full 1}
	{n 32000}
    } {
	nap "x = reshape(f32(data))"
	nap "r = range(x)"
	if {[[nap "r(0) == r(1)"]]} {
	    nap "f = n # 0"
	} else {
	    nap "delta = (r(1) - r(0)) / f32(n)"
	    nap "v = n ... (r(0) + delta) .. r(1)"
	    nap "f = # ((i32(ceil((x - r(0)) / delta)) >>> 1 <<< n) - 1)"
	    if {[[nap "full"]]} {
		if {[[nap "r(0) < v(0)"]]} {
		    nap "f = 0 // f"
		    nap "v = r(0) // v"
		}
	    } else {
		nap "v = v - 0.5 * delta"
	    }
	    $f set coo $v
	}
	nap "f"
    }


    # histogram_button_command --
    #
    # This is executed when mouse button in pressed when cross-hairs are over histogram.
    # The x position of cross-hairs alternately defines scalingFromZ & scalingToZ.

    proc histogram_button_command {
	window_id
	layer
	index
    } {
	global Plot_nao::${window_id}::histograms
	global Plot_nao::${window_id}::scalingFromZ
	global Plot_nao::${window_id}::scalingFromIsNext
	global Plot_nao::${window_id}::scalingFromTitle
	global Plot_nao::${window_id}::scalingToZ
	global Plot_nao::${window_id}::scalingToTitle
	global Plot_nao::x
	if {$scalingFromIsNext($layer)} {
	    set scalingFromZ($layer) $x
	    set scalingFromIsNext($layer) 0
	} else {
	    set scalingToZ($layer) $x
	    set scalingFromIsNext($layer) 1
	}
	set histogram [lindex $histograms $index]
	if {$scalingFromIsNext($layer)} {
	    $histogram.main.canvas itemconfigure title -text $scalingFromTitle
	} else {
	    $histogram.main.canvas itemconfigure title -text $scalingToTitle
	}
    }


    # create_xyz --
    #
    # Create widget $all.xyz to display x, y and z values defined by crosshairs
    # Only get z values if $want_z

    proc create_xyz {
	all
	window_id
	graph
	want_z
    } {
        global Plot_nao::${window_id}::xlabel
        global Plot_nao::${window_id}::ylabel
	set w $all.xyz
	frame $w -relief raised -borderwidth 4
	    # 20 is default height of label (need to specify since using placer not packer)
	frame $w.xy -height 20
	frame $w.xy.x
	frame $w.xy.y
	if {$xlabel eq ""} {
	    set text x
	} else {
	    set text $xlabel
	}
	label $w.xy.x.label -text $text -anchor w
	label $w.xy.x.value -textvariable Plot_nao::x \
		-anchor w -relief sunken -background white -foreground black
	if {$ylabel eq ""} {
	    set text y
	} else {
	    set text $ylabel
	}
	label $w.xy.y.label -text $text -anchor w
	label $w.xy.y.value -textvariable Plot_nao::y \
		-anchor w -relief sunken -background white -foreground black
	pack $w.xy.x.value -side right -anchor w -expand 1 -fill x
	pack $w.xy.x.label -side right -anchor w
	pack $w.xy.y.value -side right -anchor w -expand 1 -fill x
	pack $w.xy.y.label -side right -anchor w
	place $w.xy.x -relwidth 0.5 -relx 0 -rely 0 -anchor nw
	place $w.xy.y -relwidth 0.5 -relx 1 -rely 0 -anchor ne
	pack $w.xy -expand 1 -fill x
	if {$want_z} {
	    label $w.z -textvariable Plot_nao::z \
		    -anchor w -relief sunken -background white -foreground black
	    pack $w.z -expand 1 -fill x
	}
	place $w -x 0 -y 0 -relwidth 1
	bind $graph <Leave> "destroy $all.xyz; $graph delete lines"
    }


    # draw_xy --
    #
    # Draw XY graph defined by 1D or 2D NAO.

    proc draw_xy {
	all
	window_id
	graph
	nao
	range_nao
	height
	width
	{default_height_width 512}
    } {
	global Plot_nao::${window_id}::plot_type
	if {"$height" eq ""} {
	    if {"$width" eq ""} {
		set width $default_height_width
	    }
	    set height $width
	} else {
	    if {"$width" eq ""} {
		set width $height
	    }
	}
	if {$range_nao == ""} {
	    nap "range_nao = nao"
	}
	if {$plot_type eq "bar"} {
	    nap "range_nao = range_nao // 0"
	}
	    # This graph widget points to nao, so increment ref. count
	    # Decrement when widget destroyed (in procedure "close_window")
	Plot_nao::incrRefCount $window_id $nao
	Plot_nao::incrRefCount $window_id $range_nao
	set redraw_command [list Plot_nao::redraw_xy $all $window_id $graph $nao \
		$range_nao $height $width]
	create_main_menu $all $window_id $graph $redraw_command $nao
	eval $redraw_command
    }


    # redraw_xy --
    #
    # Draw XY graph defined by 1D or 2D NAO.
    #
    # Called by draw_xy
    # Delete points whose x or y value is missing.

    proc redraw_xy {
	all
	window_id
	graph
	nao
	range_nao
	height
	width
    } {
	global Plot_nao::${window_id}::barwidth
	global Plot_nao::${window_id}::colors
	global Plot_nao::${window_id}::dash_patterns
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::font_title
	global Plot_nao::${window_id}::gap_height
	global Plot_nao::${window_id}::gap_width
	global Plot_nao::${window_id}::key_width
	global Plot_nao::${window_id}::labels
	global Plot_nao::${window_id}::magnification
	global Plot_nao::${window_id}::major_tick_length
	global Plot_nao::${window_id}::major_ticks_x 
	global Plot_nao::${window_id}::new_height
        global Plot_nao::${window_id}::new_width
	global Plot_nao::${window_id}::plot_type
	global Plot_nao::${window_id}::symbols
	global Plot_nao::${window_id}::title
	global Plot_nao::${window_id}::want_x_axis
	global Plot_nao::${window_id}::want_y_axis
	global Plot_nao::${window_id}::xlabel
	global Plot_nao::${window_id}::xproc
	global Plot_nao::${window_id}::ylabel
	$graph delete all
	if {$magnification ne ""} {
	    set new_width  [expr {round($magnification * $width)}]
	    set new_height [expr {round($magnification * $height)}]
	}
	if {$new_width eq ""} {
	    set new_width $width
	}
	if {$new_height eq ""} {
	    set new_height $height
	}
	if {$gap_height eq ""} {
	    set gap_height 10
	}
	if {$gap_width eq ""} {
	    set gap_width 10
	}
	if {$key_width eq ""} {
	    set key_width 0
	}
	nap "cvx = coordinate_variable(nao, -1)"
	if {$title ne ""} {
	    set width_char [font measure $font_title A]
	    set width_title [expr {$width_char * [text_width $title]}]
	    set linespace [font metrics $font_title -linespace]
	    set height_title [expr {$linespace * [text_height $title]}]
	    set margin_top [expr {$height_title + 2 * $gap_height}]
	} else {
	    set width_title 0
	    set margin_top [expr {2 * $gap_width}]
	}
	set linespace [font metrics $font_standard -linespace]
	set margin_bottom [expr {2 * $gap_width}]
	if {$want_x_axis} {
	    set margin_bottom [expr {$margin_bottom + $linespace
		    + $gap_height + $major_tick_length}]
	}
	set width_char [font measure $font_standard A]
	set margin_left [expr {2 * $gap_width}]
	if {$want_y_axis} {
	    set margin_left [expr {$margin_left + $major_tick_length + 10 * $width_char}]
	}
	set height_total [expr {$margin_top + $new_height + $margin_bottom}]
	set margin_right [expr {2 * $gap_width}]
	switch [$nao rank] {
	    1 {
	    }
	    2 {
		set nrows [[nap "(shape(nao))(0)"]]
		if {$labels eq ""} {
		    for {set i  0} {$i < $nrows} {incr i} {
			lappend labels y$i
		    }
		}
		set max_width_label 0
		for {set i  0} {$i < $nrows} {incr i} {
		    set label [lindex $labels $i]
		    set width_label [font measure $font_standard $label]
		    if {$width_label > $max_width_label} {
			set max_width_label $width_label 
		    }
		}
		if {$key_width > 0} {
		    set margin_right [expr {4 * $gap_width + $key_width + $max_width_label}]
		}
	    }
	    default {handle_error "Illegal rank"; return}
	}
	set width_total [expr {$margin_left + $new_width + $margin_right}]
	if {$width_title > $width_total} {
	    set width_total $width_title
	}
	set unit [$nao unit]
	$graph delete all
	set tmp [resize_canvas $all $window_id $width_total $height_total]
	set delta_width  [expr {[lindex $tmp 0] -  $width_total}]
	set new_width [expr {$new_width + $delta_width}]
	set width_total [expr {$width_total + $delta_width}]
	set delta_height [expr {[lindex $tmp 1] - $height_total}]
	set new_height [expr {$new_height + $delta_height}]
	set height_total [expr {$height_total + $delta_height}]
	set tmp [draw_y_axis_for_xy $window_id $graph $ylabel $margin_left $margin_top \
		$new_height $range_nao $unit]
	set y0 [lindex $tmp 0]
	set yend [lindex $tmp 1]
	# Following just to define max_width
	if {$major_ticks_x eq ""} {
	    nap "major_ticks_x = axis_major_ticks_span(cvx, 32)"
	    set max_width [font measure $font_standard \
		    "[longest_element [axis_tick_text $major_ticks_x $xproc]] "]
	    nap "major_ticks_x = axis_major_ticks_span(cvx, i32(new_width / max_width - 1))"
	} else {
	    nap "tick_step = major_ticks_x(1) - major_ticks_x(0)"
	    nap "cv_range = cvx(-1) - cvx(0)"
	    nap "major_ticks_x = tick_step * cv_range > 0 ?  major_ticks_x : major_ticks_x(-)"
	}
	set x0   [[nap "major_ticks_x(0)"]]
	set xend [[nap "major_ticks_x(-1)"]]
	nap "xslope = new_width / f64(xend - x0)"; # slope for x mapping
	set width_bar [[nap "xslope * barwidth"]]
	set width_total [expr {round($width_total + $width_bar)}]
	nap "x_b = margin_left + 0.5 * width_bar - xslope * x0"; # y-intercept for x mapping
	nap "yslope = new_height / f64(y0 - yend)"; # slope for y mapping
	nap "y_b = margin_top - yslope * yend"; # y-intercept for y mapping
	if {[llength $dash_patterns] == 0} {
	    set dash_patterns [list $dash_patterns]
	}
	set x [expr {round($margin_left + 0.5 * $width_bar)}]
	set y [expr {$margin_top + $new_height + 2 * ($width_bar > 0)}]
	draw_x_axis_for_xy $window_id $graph $xlabel $x $y $new_width
	set x [expr {$width_total / 2}] 
	set y [expr {$margin_top/2}]
	$graph create text $x $y -font $font_title -text $title -tags title -width $width_total
	switch [$nao rank] {
	    1 {
		set color [lindex $colors 0]
		set symbol [lindex $symbols 0]
		set dash_pattern [lindex $dash_patterns 0]
		nap "mask = count(cvx,0) && count(nao,0)"
		nap "ratio = i32(sum(mask) / new_width) >>> 1"
		nap "mask = mask && ((0 .. (nels(mask) - 1)) % ratio == 0)"
		nap "x = x_b + xslope * (mask # cvx)"
		nap "y = y_b + yslope * (mask # nao)"
		draw_xy_or_bar $width_bar $graph 1 0 $color $symbol $dash_pattern $x $y \
			$new_height $margin_top $font_standard
	    }
	    2 {
		set ncolors [llength $colors]
		set n_dash_patterns [llength $dash_patterns]
		set x1 [expr {$margin_left + $width_bar + $new_width + $gap_width}]
		set x3 [expr {$x1 + $key_width}]
		set x2 [expr {0.5 * ($x1 + $x3)}]
		set x4 [expr {$x3 + $gap_width}]
		for {set i  0} {$i < $nrows} {incr i} {
		    set label [lindex $labels $i]
		    set color [lindex $colors [expr {$i % $ncolors}]]
		    set symbol [lindex $symbols $i]
		    set dash_pattern [lindex $dash_patterns [expr {$i % $n_dash_patterns}]]
		    if {$width > 0} {
			nap "mask = count(cvx,0) && count(nao(i,),0)"
			nap "ratio = i32(sum(mask) / new_width) >>> 1"
			nap "mask = mask && ((0 .. (nels(mask) - 1)) % ratio == 0)"
			nap "x = x_b + xslope * (mask # cvx)"
			nap "y = y_b + yslope * (mask # nao(i,))"
			draw_xy_or_bar $width_bar $graph $nrows $i $color $symbol \
				$dash_pattern $x $y $new_height $margin_top $font_standard
		    }
		    set y [expr {$margin_top + $linespace * (0.5 + $i)}]
		    if {$key_width > 0} {
			if {$plot_type eq "bar"} {
			    $graph create rectangle \
				    $x1 [expr {$y - 0.5 * $linespace}] \
				    $x3 [expr {$y + 0.5 * $linespace}] \
				    -fill $color -width 0
			} else {
			    nap "xlegend = x1 // x2 // x3"
			    nap "ylegend = 3 # y"
			    draw_xy_or_bar $width_bar $graph $nrows $i $color $symbol \
				    $dash_pattern $xlegend $ylegend $new_height $margin_top \
				    $font_standard
			}
			set id [$graph create text $x4 $y -anchor w -text $label \
				-font $font_standard]
			set x5 [expr {[lindex [$graph bbox $id] 2] + $gap_width}]
			if {$x5 > [$graph cget -width]} {
			    $graph configure -width $x5
			}
		    }
		}
	    }
	}
	# Following define inverse tranformation
	if {[[nap "xslope != 0  &&  yslope != 0"]]} {
	    set x_b [[nap "-f64(x_b) / xslope"]]
	    set xslope [[nap "1.0 / xslope"]]
	    set y_b [[nap "-f64(y_b) / yslope"]]
	    set yslope [[nap "1.0 / yslope"]]
	    bind $graph <Motion> "Plot_nao::crosshairs_xy \
		    [list $all $window_id $graph $x_b $xslope $y_b $yslope %x %y]"
	}
	$graph configure -height $height_total -width $width_total  
    }


    # draw_xy_or_bar --

    proc draw_xy_or_bar {
	width_bar
	graph
	nrows
	i
	color
	symbol
	dash_pattern
	x
	y
	height
	margin_top
	font
    } {
	set n [$x nels]
	if {$width_bar == 0} {
	    nap "xy = reshape(transpose(x /// y))"
	    switch -- $dash_pattern {
		{ }	{}
		{}	{$graph create line [$xy value] -fill $color}
		default	{$graph create line [$xy value] -fill $color -dash $dash_pattern}
	    }
	    if {"$symbol" ne ""} {
		for {set j 0} {$j < $n} {incr j} {
		    draw_symbol $graph $symbol $color [[nap "xy(2*j)"]] [[nap "xy(2*j+1)"]] \
			    $font
		}
	    }
	} else {
	    nap "x0 = f64(width_bar) / nrows * (i - 0.5 * nrows)"
	    nap "x1 = f64(width_bar) / nrows * (i - 0.5 * nrows + 1.0)"
	    set y1 [expr "$height + $margin_top"]
	    for {set j 0} {$j < $n} {incr j} {
		set xj0 [[nap "x(j) + x0"]]
		set xj1 [[nap "x(j) + x1"]]
		set yj  [[nap "y(j)"]]
		$graph create rectangle $xj0 $yj $xj1 $y1 -fill $color -width 0
		if {$xj1 > [$graph cget -width]} {
		    $graph configure -width $xj1
		}
	    }
	}
    }


    # draw_symbol --
    #
    # Draw specified symbol at specified point.
    # Intended for marking data points on graph.
    # Symbol names (plus, square, circle, cross, splus, scross, triangle) are from BLT graph.
    # If symbol is "" then do nothing.
    # symbol can also be single character e.g. "*".

    proc draw_symbol {
	graph
	symbol
	color
	x
	y
	font
	{width 1}
	{h 8.0}
    } {
	switch -glob $symbol {
	    circle {
		$graph create oval \
			[expr $x - $h/2] \
			[expr $y - $h/2] \
			[expr $x + $h/2] \
			[expr $y + $h/2] \
			-fill $color \
			-width 0
	    }
	    cross {
		    draw_symbol $graph scross $color $x $y $font 2
		}
	    plus {
		    draw_symbol $graph splus $color $x $y $font 2
	    }
	    scross {
		$graph create line \
			[expr $x - $h/2] [expr $y - $h/2] \
			[expr $x + $h/2] [expr $y + $h/2] \
			-fill $color \
			-width $width
		$graph create line \
			[expr $x - $h/2] [expr $y + $h/2] \
			[expr $x + $h/2] [expr $y - $h/2] \
			-fill $color \
			-width $width
	    }
	    splus {
		$graph create line \
			[expr $x - $h/2] $y \
			[expr $x + $h/2] $y \
			-fill $color \
			-width $width
		$graph create line \
			$x [expr $y - $h/2] \
			$x [expr $y + $h/2] \
			-fill $color \
			-width $width
	    }
	    square {
		$graph create rectangle \
			[expr $x - $h/2] \
			[expr $y - $h/2] \
			[expr $x + $h/2] \
			[expr $y + $h/2] \
			-fill $color \
			-width 0
	    }
	    triangle {
		set R [expr $h / 2 / 0.866025]; # sin(pi/3)
		$graph create polygon \
			[expr $x - $h/2] [expr $y + $R/2] \
			$x               [expr $y - $R] \
			[expr $x + $h/2] [expr $y + $R/2] \
			-fill $color \
			-width 0
	    }
	    ? {
		$graph create text $x $y -justify center -text $symbol -fill $color -font $font
	    }
	    "" {
	    }
	    default {
		handle_error "Illegal symbol"
		return
	    }
	}
    }


    # draw_z --
    #
    # Draw grey-scale or color image defined by 2D or 3D NAO.
    #
    # Image is grey-scale if 2D and no palette.
    # 3D NAO can have any number of layers. Only 1st three layers affect image
    # but values of others are displayed using cross-hairs.

    proc draw_z {
	all
	window_id
	graph
	nao
	height
	width
	range_nao
	want_yflip
    } {
        global Plot_nao::${window_id}::new_height
        global Plot_nao::${window_id}::new_width
        global Plot_nao::${window_id}::main_palette
        global Plot_nao::${window_id}::want_scaling_widget
	if {[[nap "rank(nao) < 2  ||  rank(nao) > 3"]]} {
	    handle_error "Illegal rank"
	    return
	}
	if {[check_cvs $nao]} {
	    handle_error "Illegal coordinate variable"
	    return
	}
	set new_width $width
	set new_height $height
	set cvx [$nao coord -1]
	set cvy [$nao coord -2]
	set cv0 [$nao coord  0]
	if {$cvx ne "(NULL)"  &&  [fix_unit [$cvx unit]] == "degrees_east"} {
	    nap "cvx = fix_longitude(cvx)"
	}
	if {[[nap "rank(nao) == 2"]]} {
	    $nao set coord $cvy $cvx
	} else {
	    $nao set coord $cv0 $cvy $cvx
	}
	    # This graph widget points to nao, so increment ref. count
	    # Decrement when widget destroyed (in procedure "close_window")
	Plot_nao::incrRefCount $window_id $nao
	Plot_nao::incrRefCount $window_id $range_nao
	set redraw_command \
		[list Plot_nao::redraw_z $all $window_id $graph $nao $range_nao $want_yflip]
	create_main_menu $all $window_id $graph $redraw_command $nao
	frame $all.scaling_range
	if {$want_scaling_widget} {
	    pack $all.scaling_range -before $all.main -anchor n -fill x
	}
	set nlayers [[nap "rank(nao) == 2 ? 1 : (3 <<< (shape(nao))(0))"]]
	for {set layer 0} {$layer < $nlayers} {incr layer} {
	    set color [color_of_layer $nao $layer]
	    set frame $all.scaling_range.$color
	    create_scaling_range $all $window_id $frame $nao $layer $color $redraw_command
	}
	eval $redraw_command
    }


    # set_yflip --
    #
    # set Plot_nao::${window_id}::yflip

    proc set_yflip {
	window_id
	want_yflip
	nao
    } {
	global Plot_nao::${window_id}::yflip
	set row_cv [$nao coord -2]
	if {$row_cv == "(NULL)"} {
	    set ascending 0
	    set unit (NULL)
	} else {
	    set ascending [[nap "row_cv(0) < row_cv(-1)"]]
	    set unit [fix_unit [$row_cv unit]]
	}
	switch [string tolower [string index $want_yflip 0]] {
	    a {
		set yflip $ascending
	    }
	    g {
		set dimname [$nao dim -2]
		if {$ascending  && \
			([regexp {latitude|northing} $dimname]  ||  $unit == "degrees_north")} {
		    set yflip 1
		} else {
		    set yflip 0
		}
	    }
	    default {
		set yflip $want_yflip
	    }
	}
    }


    # axis_tick_text --
    #
    # Format a scalar or vector nao for axis tick text.
    #
    # Use formatting procedure format_proc (defined by options -xproc and -yproc) if defined.
    # Otherwise:
    #	if latitude  (defined by unit) then append degree symbol & N
    #	if longitude (defined by unit) then append degree symbol & E
    #	else normal

    proc axis_tick_text {
	nao
	format_proc
    } {
	set n [$nao nels]
	nap "s = n // 1"
	if {$format_proc eq ""} {
	    set degree "\xb0"; # ISO-8859 code for degree symbol
	    switch [fix_unit [$nao unit]] {
		degrees_north {
		    set a [[nap "reshape(abs(nao), s)"] value]
		    set j [[nap "1 + sign(nao)"] value]
		    set suffix {S { } N}
		    for {set i 0} {$i < $n} {incr i} {
			lappend result "[lindex $a $i]$degree[lindex $suffix [lindex $j $i]]"
		    }
		}
		degrees_east {
		    nap "lon = (nao + 180f32) % 360f32 - 180f32"
		    set a [[nap "reshape(abs(lon), s)"] value]
		    set j [[nap "abs(lon) == 180 ? 1 : 1 + sign(lon)"] value]
		    set suffix {W {} E}
		    for {set i 0} {$i < $n} {incr i} {
			lappend result "[lindex $a $i]$degree[lindex $suffix [lindex $j $i]]"
		    }
		}
		default {
		    set result [[nap "reshape(nao, s)"] value]
		}
	    }
	} else {
	    foreach word [[nap "reshape(nao, s)"] value] {
		lappend result [$format_proc $word]
	    }
	}
	return $result
    }


    # fix_unit --
    #
    # Return "degrees_east"  if arg is anything equivalent to this e.g. "degreeE"
    # Return "degrees_north" if arg is anything equivalent to this e.g. "degreeN"
    # Return "" if arg is "(NULL)"
    # Otherwise just return arg

    proc fix_unit {
	unit
    } {
	set unit [string trim $unit]
	if {"$unit" eq "(NULL)"} {
	    return ""
	}
	switch -regexp [string tolower $unit] {
	    ^degree.*e	{return degrees_east}
	    ^degree.*n	{return degrees_north}
	    default	{return $unit}
	}
    }


    # color_of_layer --
    #
    # Return color of specified layer of 3D-plot

    proc color_of_layer {
	nao layer
    } {
	set color black
	if {[$nao rank] == 3} {
	    set nlayers [[nap "(shape(nao))(0)"]]
	    if {$layer < $nlayers} {
		switch $nlayers {
		    1		{}
		    2		{set color [lindex "yellow    blue" $layer]}
		    default	{set color [lindex "red green blue" $layer]}
		}
	    }
	}
	return $color
    }


    # redraw_z --
    #
    # Draw grey-scale or color image
    # Called by draw_z, "redraw" button, etc.

    proc redraw_z {
	all
	window_id
	graph
	nao
	range_nao
	want_yflip
	{min_dim 360}
    } {
	global Plot_nao::${window_id}::allow_scroll
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::font_title
	global Plot_nao::${window_id}::gap_width
	global Plot_nao::${window_id}::image_nao
	global Plot_nao::${window_id}::key_width
	global Plot_nao::${window_id}::magnification
	global Plot_nao::${window_id}::major_tick_length
	global Plot_nao::${window_id}::main_palette
	global Plot_nao::${window_id}::new_height
	global Plot_nao::${window_id}::new_width
	global Plot_nao::${window_id}::proj4spec
	global Plot_nao::${window_id}::title
	global Plot_nao::${window_id}::want_x_axis
	global Plot_nao::${window_id}::want_y_axis
	global Plot_nao::${window_id}::xflip
	global Plot_nao::${window_id}::xlabel
	global Plot_nao::${window_id}::yflip
	global Plot_nao::${window_id}::ylabel

	set rank_nao [$nao rank]
	if {$gap_width eq ""} {
	    set gap_width 20
	}
	set comma(2) ""
	set comma(3) ","
	nap "latitude = coordinate_variable(nao, -2)"
	nap "longitude = coordinate_variable(nao, -1)"
	switch [proj4parameter $window_id proj] {
	    ups {
		if {[proj4parameter $window_id south] eq "yes"} {
		    if {[[nap "max(latitude)"]] > 0} {
			nap "nao = nao($comma($rank_nao) @@-90 .. @@0,)"
		    }
		} else {
		    if {[[nap "min(latitude)"]] < 0} {
			nap "nao = nao($comma($rank_nao) @@0 .. @@90,)"
		    }
		}
	    }
	    utm {
		set zone [proj4parameter $window_id zone]
		set lon0 [[nap "longitude(0)"]]
		set lon1 [[nap "longitude(-1)"]]
		set lon_min [[nap "lon0 >>> ((6 * zone + 162 - lon0) % 360.0 + lon0)"]]
		set lon_max [[nap "lon1 <<< ((6 * zone + 192 - lon0) % 360.0 + lon0)"]]
		if {$lon_min > $lon0  ||  $lon_max < $lon1} {
		    nap "nao = nao($comma($rank_nao), @@lon_min .. @@lon_max)"
		}
	    }
	}
	nap "latitude = coordinate_variable(nao, -2)"
	nap "longitude = coordinate_variable(nao, -1)"
	if {[$latitude nels] < 2} {
	    handle_error "Only [$latitude nels] latitudes!"
	}
	if {[$longitude nels] < 2} {
	    handle_error "Only [$longitude nels] longitudes!"
	}
	switch [projection_type $window_id] {
	    0	{nap "proj_nao = nao"}
	    1	{nap "proj_nao = proj4gshhs(nao, '$proj4spec', 1, 0, {})"}
	    2	{
		    nap "proj_nao = proj4gshhs(nao, '$proj4spec', 0, 0, {})"
		    set want_x_axis 0
		    set want_y_axis 0
		    set xlabel [$proj_nao dim -1]
		    set ylabel [$proj_nao dim -2]
		}
	}
	set_yflip $window_id $want_yflip $nao
	set nx [[nap "(shape proj_nao)(-1)"]]
	set ny [[nap "(shape proj_nao)(-2)"]]
	set nxy [expr $nx > $ny ? $nx : $ny]; # greater of nx & ny
	if {$nxy < $min_dim  &&  $new_width eq ""  &&  $new_height eq ""} {
	    set magnification [expr round(($min_dim - 1.0) / ($nxy - 1.0))]
	}
	if {$magnification ne ""} {
	    set new_width  [expr 1 + round($magnification * ($nx-1))]
	    set new_height [expr 1 + round($magnification * ($ny-1))]
	} elseif {$allow_scroll} {
	    set new_width  $nx
	    set new_height $ny
	}
	if {$new_width eq ""} {
	    set new_width  $nx
	}
	if {$new_height eq ""} {
	    set new_height $ny
	}
	if {$new_width != $nx  ||  $new_height != $ny} {
	    nap "magnification_x = (new_width  - 1f32) / (nx - 1f32)"
	    nap "magnification_y = (new_height - 1f32) / (ny - 1f32)"
	    if {[[nap "magnification_x == magnification_y"]]} {
		set magnification [$magnification_x]
	    }
	    nap "nao = magnify_nearest(nao, (rank_nao-2) # 1 // magnification_y // magnification_x)"
	    nap "latitude = coordinate_variable(nao, -2)"
	    nap "longitude = coordinate_variable(nao, -1)"
	    switch [projection_type $window_id] {
		1	{nap "nao = proj4gshhs(nao, '$proj4spec', 1, 0, {})"}
		2	{nap "nao = proj4gshhs(nao, '$proj4spec', 0, 0, {})"}
	    }
	    nap "cvx = coordinate_variable(nao, -1)"
	    nap "cvy = coordinate_variable(nao, -2)"
	    set new_width  [$cvx nels]
	    set new_height [$cvy nels]
	}
	set nx [[nap "(shape nao)(-1)"]]
	set ny [[nap "(shape nao)(-2)"]]
	set xend [[nap "nx - 1"]]
	set xflip [expr $xflip != 0]; # ensure either 0 or 1
	set yflip [expr $yflip != 0]; # ensure either 0 or 1
	if {$xflip || $yflip} {
	    set reverse(0) ""
	    set reverse(1) "-"
	    nap "nao = nao($comma($rank_nao)$reverse($yflip),$reverse($xflip))"
	}
	set_scaling $window_id $nao $range_nao
	if [[nap "rank_nao == 3  &&  (shape(nao))(0) > 3"]] {
	    nap "nao = nao(0 .. 2, , )"
	}
	set linespace_standard [font metrics $font_standard -linespace]
	set linespace_title    [font metrics $font_title    -linespace]
	set width_title [font measure $font_title $title]
	set width_char [font measure $font_standard A]
	set margin_left  [expr $linespace_standard + $major_tick_length + 10 * $width_char]
	set width_total  [expr "$new_width + $margin_left + $gap_width"]
	set have_key [expr {$key_width ne ""  &&  $key_width > 0  &&  $rank_nao == 2}]
	if {$have_key} {
	    incr width_total [expr $key_width + $margin_left]
	}
	set margin_top [expr $linespace_title * int(ceil(2 + double($width_title) / $width_total))]
	set margin_bottom [expr 3 * $linespace_standard + $major_tick_length]
	set height_total [expr "$new_height + $margin_top + $margin_bottom"]
	$graph delete all
	set tmp [resize_canvas $all $window_id $width_total $height_total]
	set new_width_total  [lindex $tmp 0]
	set new_height_total [lindex $tmp 1]
	if {$new_width_total < $width_total  ||  $new_height_total < $height_total} {
	    nap "rx = new_width  / f32(new_width  + new_width_total  - width_total)"
	    nap "ry = new_height / f32(new_height + new_height_total - height_total)"
	    set magnification [[nap "1.0 / ceil(rx >>> ry)"]]
	    nap "nao = magnify_nearest(nao, (rank_nao-2) # 1 // 2 # magnification)"
	    nap "cvx = coordinate_variable(nao, -1)"
	    nap "cvy = coordinate_variable(nao, -2)"
	    set new_width  [$cvx nels]
	    set new_height [$cvy nels]
	    set height_total [expr "$new_height + $margin_top + $margin_bottom"]
	    set width_total  [expr "$new_width + $margin_left + $gap_width"]
	    if {$have_key} {
		incr width_total [expr $key_width + $margin_left]
	    }
	    $graph configure -height $height_total -width $width_total  
	}
	z_major_ticks_mapping $window_id $new_height 
	if {$have_key} {
	    set x [expr $margin_left + $new_width + $gap_width]
	    draw_key $window_id $graph $x $margin_top $new_height
	}
	nao2image u $window_id $nao 1 $latitude $longitude
	set x [expr $width_total / 2] 
	set y [expr $margin_top/2]
	$graph create text $x $y -font $font_title -text $title -tags title -width $width_total
	set x $margin_left
	set y [expr $margin_top + $new_height + 2]
	nap "cvx = coordinate_variable(nao, -1)"
	nap "cvy = coordinate_variable(nao, -2)"
	draw_x_axis_for_image $window_id $graph $xlabel $x $y $new_width $cvx
	set x [expr $margin_left - 2]
	set y $margin_top
	draw_y_axis_for_image $window_id $graph $ylabel $x $y $new_height $cvy
	update
	set imageName [image create photo -format NAO -data $u]
	$graph create image $margin_left $margin_top -image $imageName -anchor nw
	nap "image_nao = nao"
	bind $graph <Motion> "Plot_nao::crosshairs_xyz \
		[list $all $window_id $graph $margin_left $margin_top %x %y]"
	raise $all
	update
    }


    # z_major_ticks_mapping --
    #
    # Define:
    #	major_ticks_z_use
    #	cv for this z-axis
    #	mapping

    proc z_major_ticks_mapping {
	window_id
	nrows
    } {
	global Plot_nao::${window_id}::cvz
	global Plot_nao::${window_id}::discrete_colors
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::major_ticks_z
	global Plot_nao::${window_id}::major_ticks_z_use
        global Plot_nao::${window_id}::mapping
	global Plot_nao::${window_id}::scalingFromZ
	global Plot_nao::${window_id}::scalingToZ
        global Plot_nao::${window_id}::want_equalise
	global Plot_nao::${window_id}::zlabels

	if {[string is double -strict $scalingFromZ(0)]} {
	    set ymin $scalingFromZ(0)
	} else {
	    set ymin 0
	}
	if {[string is double -strict $scalingToZ(0)]} {
	    set ymax $scalingToZ(0)
	} else {
	    set ymax 0
	}
	if {$ymin == $ymax} {
	    incr ymax
	}
	nap "cvz = nrows ... ymax .. ymin"
	Plot_nao::incrRefCount $window_id $cvz
	if {$zlabels ne ""} {
	    nap "major_ticks_z_use = cvz(0) .. cvz(-1)"
	} elseif {$major_ticks_z eq ""} {
	    nap "nmax = i32(nrows / [font metrics $font_standard -linespace] - 1)"
	    nap "nmax = nmax > 4 ? nmax/2 + 2 : nmax"
	    nap "major_ticks_z_use = axis_major_ticks(cvz, nmax)"
	} else {
	    nap "tick_step = major_ticks_z(1) - major_ticks_z(0)"
	    nap "cv_range = cvz(-1) - cvz(0)"
	    nap "major_ticks_z_use = tick_step * cv_range > 0 ?  major_ticks_z : major_ticks_z(-)"
	}
	if {$discrete_colors} {
	    set want_equalise 0
	    nap "i = 0 // (cvz @@ major_ticks_z_use) * 255 / (nrows-1) // 255"
	    nap "j = 0 .. (nels(i) - 2)"
	    nap "count = (i(j+1) - i(j))(-)"
	    nap "count = (count > 0) # count"
	    nap "value  = i32(nint(nels(count) ... 0 .. 254))"
	    nap "mapping = count # value // 255"
	} elseif {! $want_equalise} {
	    set mapping ""
	}
    }


    # draw_key --
    #
    # Draw key relating z values to colours
    # (x,y) is left top corner

    proc draw_key {
	window_id
	graph
	x
	y
	nrows
    } {
	global Plot_nao::${window_id}::cvz
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::key_width
	global Plot_nao::${window_id}::major_ticks_z_use
	global Plot_nao::${window_id}::zlabels

	nap "key_nao = transpose(reshape(cvz, key_width // nrows))"
	nao2image u $window_id $key_nao 0
	set imageName [image create photo -format NAO -data $u]
	$graph create image $x $y -image $imageName -anchor nw
	if {$zlabels eq ""} {
	    set x2 [expr $x + $key_width + 2]
	    draw_y_axis $window_id $graph "" $x2 $y $nrows $cvz 1 $major_ticks_z_use "" 0.5
	} else {
	    set n [llength $zlabels]
	    if {$n != [$major_ticks_z_use nels] - 1} {
		handle_error "Error with z categories!"
	    }
	    set x2 [expr $x + $key_width + 4]
	    nap "y1 = y + nrows"
	    for {set j 0} {$j < $n} {incr j} {
		nap "tmp = 0.5 * (major_ticks_z_use(j) + major_ticks_z_use(j+1))"
		set y2 [[nap "y1 - (cvz @@ tmp)"]]
		$graph create text $x2 $y2 -anchor w -font $font_standard -justify left \
			-text [lindex $zlabels $j]
	    }
	}
    }


    # resize_canvas --
    #
    # Change width & height of canvas to specified values if possible.
    # Create scrollbars if needed.
    # Return new width & height (which may be less than requested)

    proc resize_canvas {
	all
	window_id
	width
	height
	{width_scrollbar 21}
	{scrolled_fraction_window 0.75}
	{unscrolled_fraction_window 0.95}
    } {
	global Plot_nao::${window_id}::allow_scroll
	global Plot_nao::${window_id}::auto_print
	global Plot_nao::${window_id}::oversize_prompt
	global Plot_nao::${window_id}::max_canvas_width
	global Plot_nao::${window_id}::max_canvas_height
	set main $all.main
	set canvas $main.canvas
	set xscroll $main.xscroll
	set yscroll $main.yscroll
	set top [winfo toplevel $all]
	set max_width  $max_canvas_width
	set max_height $max_canvas_height
	grid remove $xscroll $yscroll
	set max_width_window  [lindex [wm maxsize $top] 0]
	set max_height_window [lindex [wm maxsize $top] 1]
	if {$max_width eq ""} {
	    set max_width [expr int($unscrolled_fraction_window * $max_width_window)]
	}
	if {$max_height eq ""} {
	    set max_height [expr int($unscrolled_fraction_window * $max_height_window)]
	    update idletasks
	    foreach w "$all.main_menu $all.scaling_range" {
		if {[winfo exists $w]  &&  [winfo ismapped $w]} {
		    incr max_height -[winfo height $w]
		}
	    }
	}
	if {$oversize_prompt  &&  ! $auto_print \
		&& ($height > $max_height  ||  $width > $max_width)} {
	    set allow_scroll \
		    [tk_dialog .tk_dialog "compress scroll" \
		    "Image is bigger than screen!" \
		    "" $allow_scroll "Compress (sample)" Scroll]
	    set oversize_prompt 0
	}
	if {$height > $max_height} {
	    if {$allow_scroll} {
		set max_height [expr int($scrolled_fraction_window * $max_height_window)]
		set new_height  $height
		grid $yscroll -row 0 -column 1
	    } else {
		set new_height  $max_height
	    }
	    $canvas configure -height $max_height
	} else {
	    set new_height  $height
	    $canvas configure -height $height
	}
	if {$width > $max_width} {
	    if {$allow_scroll} {
		set max_width [expr int($scrolled_fraction_window * $max_width_window)]
		set new_width  $width
		grid $xscroll -row 1 -column 0
	    } else {
		set new_width  $max_width
	    }
	    $canvas configure -width $max_width
	} else {
	    set new_width  $width
	    $canvas configure -width $width
	}
	$canvas configure -scrollregion "0 0 $new_width $new_height"
	update idletasks
	set width_canvas [winfo width $canvas]
	if {$width_canvas > $new_width} {
	    set new_width $width_canvas
	    $canvas configure -scrollregion "0 0 $new_width $new_height"
	}
	return "$new_width $new_height"
    }


    # vertical_text  --
    #
    # Write vertical text onto canvas.
    # Try to rotate 90 degrees via image using package Img.
    # If this fails, use 'HOTEL' writing.

    proc vertical_text {
	canvas
	text
	x
	y
	{font "courier 12"}
	{anchor e}
	{tags ""}
	{tmp_top .tmpTop}
    } {
	catch "package require Img"
	toplevel $tmp_top
	update; # Needed on Linux for some unknown reason
	set tmp_can $tmp_top.canvas
	set w [expr 1 + [font measure $font $text]]
	set h [font metrics $font -linespace]
	canvas $tmp_can -height $h -width $w -highlightthickness 0
	$tmp_can configure -background [$canvas cget -background]
	$tmp_can create text 1 0 -anchor nw -font $font -text $text
	pack $tmp_can
	update 
	set status [catch {image create photo -format window -data $tmp_can} img1]
	if {$status == 0} {
	    $img1 write u -format NAO
	    image delete $img1
	    nap "u = (transpose(u, {0 2 1}))(,-,)"
	    set img2 [image create photo -format NAO -data $u]
	    $canvas create image $x $y -anchor $anchor -tags $tags -image $img2
	} else {
	    set text [join [split $text {}] \n]
	    $canvas create text $x $y -anchor $anchor -tags $tags -font $font -text $text
	}
	destroy $tmp_top
    }


    # longest_element --
    #
    # Return longest (max. no. characters) element of list

    proc longest_element {
	list
    } {
	set max_n 0
	set longest ""
	foreach e $list {
	    set n [string length $e]
	    if {$n > $max_n} {
		set max_n $n
		set longest $e
	    }
	}
	return $longest
    }


    # axis_major_ticks --
    #
    # nap function giving vector of axis major ticks based on given coord. var. cv
    # Assume axis has same length as cv, so major ticks are within range of cv
    # Treat specially if cv has geographic (lat/lon) unit

    proc axis_major_ticks {
	cv
	nmax
	{nice_geog "{30 45 90 180 360}"}
    } {
	nap "nmax = 2 >>> i32(nmax)"
	nap "geog_nice = nice_geog"
	nap "major_ticks = scaleAxis(cv(0), cv(-1), nmax)"
	set step [[nap "major_ticks(1) - major_ticks(0)"]]
	set unit [fix_unit [$cv unit]]
	if {abs($step) > 10  &&  [regexp {^degrees_(east|north)$} $unit]} {
	    nap "cv_min = cv(0) <<< cv(-1)"
	    nap "cv_max = cv(0) >>> cv(-1)"
	    nap "label_min = geog_nice * ceil (cv_min/geog_nice)"
	    nap "label_max = geog_nice * floor(cv_max/geog_nice)"
	    nap "n = nint((label_max - label_min) / geog_nice)"
	    if [[nap "min(n) <= nmax"]] {
		nap "i = n @@@ max((n <= nmax) # n)"
		nap "geog_labels = label_min(i) .. label_max(i) ... geog_nice(i)"
		if [[nap "nels(geog_labels) > 1"]] {
		    nap "major_ticks = cv(0) < cv(1) ? geog_labels : geog_labels(-)"
		}
	    }
	}
	$major_ticks set unit $unit
	nap "major_ticks"
    }


    # axis_major_ticks_span --
    #
    # nap function giving vector of axis major ticks based on given coord. var. cv
    # Axis may be longer than cv
    # Treat specially if cv has geographic (lat/lon) unit

    proc axis_major_ticks_span {
	cv
	nmax
	{nice_geog "{30 45 90 180 360}"}
    } {
	nap "nmax = 2 >>> i32(nmax)"
	if {[$cv step] eq "+-"} {
	    nap "from = min cv"
	    nap "to   = max cv"
	} else {
	    nap "from = cv(0)"
	    nap "to   = cv(-1)"
	}
	nap "major_ticks = scaleAxisSpan(from, to, nmax)"
	set step [[nap "major_ticks(1) - major_ticks(0)"]]
	set unit [fix_unit [$cv unit]]
	if {abs($step) > 10  &&  [regexp {^degrees_(east|north)$} $unit]} {
	    nap "major_ticks = scaleAxisSpan(from, to, nmax, nice_geog)"
	}
	$major_ticks set unit $unit
	nap "major_ticks"
    }


    # axis_minor_ticks --
    #
    # nap function giving vector of axis minor tick marks based on cv & major tick marks

    proc axis_minor_ticks {
	cv
	major_ticks
	{min_interval 6}
    } {
	if {[$major_ticks step] == "AP"} {
	    nap "step_major = major_ticks(1) == major_ticks(0)
		    ? 1f32
		    : f32(major_ticks(1) - major_ticks(0))"
	    set abs_step_major [[nap "abs(step_major)"]]
	    set unit [fix_unit [$cv unit]]
	    # Define possible values for n = no. minor intervals per major interval
	    nap "n = {1}"; # Just in case not defined below for some weird reason
	    if {$abs_step_major > 10  &&  [regexp {^degrees_(east|north)$} $unit]} {
		switch $abs_step_major {
		    30	{nap "n = {1 2 3}"}
		    45	{nap "n = {1 3}"}
		    90	{nap "n = {1 2 3}"}
		    180	{nap "n = {1 2 3 4}"}
		    360	{nap "n = {1 2 4}"}
		}
	    } else {
		set normalised_step_major [[nap "nint(10.0 ** (log10(abs_step_major) % 1.0))"]]
		switch $normalised_step_major {
		    1	{nap "n = {1 2 4 5}"}
		    2	{nap "n = {1 2 4}"}
		    5	{nap "n = {1 5}"}
		}
	    }
	    nap "i = cv @@ major_ticks"
	    nap "j = 0 .. (nels(major_ticks) - 1)"
	    nap "max_n = 1 >>> i32(nint(min(abs(i(j+1) - i(j))) / min_interval))"
	    nap "step = step_major / max((n <= max_n) # n)"
	    nap "from = major_ticks(0) - <((major_ticks(0) - cv(0))  / step) * step"
	    nap "to   = major_ticks(0) + <((cv(-1) - major_ticks(0)) / step) * step"
	    nap "result = from .. to ... step"
	} else {
	    nap "result = {}"
	}
	nap "result"
    }


    # draw_x_axis --
    #
    # Draw x-axis with origin at (x0,y0), given a coord. var. defining value at each pixel.
    # sign is -1 for ticks above axis, 1 for ticks below axis

    proc draw_x_axis {
	window_id
	graph
	label
	x0
	y0
	length
	cv
	sign
	major_ticks
	{tick_offset 0}
    } {
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::major_tick_length
	global Plot_nao::${window_id}::xproc
	global Plot_nao::${window_id}::want_x_axis
	if {$want_x_axis} {
	    set unit [fix_unit [$cv unit]]
	    set is_geog [regexp {degrees_(east|north)} $unit]
	    set linespace [font metrics $font_standard -linespace]
	    $graph create line $x0 $y0 [expr $x0 + $length] $y0
	    nap "tick_step = major_ticks(1) - major_ticks(0)"
	    nap "cv_range = cv(-1) - cv(0)"
	    nap "major_ticks = tick_step * cv_range > 0 ?  major_ticks : major_ticks(-)"
	    nap "minor_ticks = axis_minor_ticks(cv, major_ticks)"
	    set n [$major_ticks nels]
	    nap "step_major = f64(major_ticks(1) - major_ticks(0))"
	    nap "normalised = nint(10.0 ** (log10(abs(step_major)) % 1.0))"
	    nap "want_text = normalised != 5 ||  nint(major_ticks / step_major) % 2 == 0"
	    if {[[nap "is_geog  ||  sum(want_text) < 4"]]} {
		nap "want_text = n # 1"
	    }
	    nap "x1 = x0 + tick_offset"
	    set y1 [expr $y0 + $sign * $major_tick_length]
	    set y2 [expr $y1 + $sign * $linespace * 3/4]
	    nap "i = cv @ major_ticks"
	    nap "tmp = want_text * major_ticks"
	    $tmp set unit $unit
	    set labels [axis_tick_text $tmp $xproc]
	    for {set j 0} {$j < $n} {incr j} {
		set x [[nap "x1 + i(j)"]]
		$graph create line $x $y1 $x $y0
		if {[[nap "want_text(j)"]]} {
		    set text [lindex $labels $j]
		    $graph create text $x $y2 -font $font_standard -justify center -text $text
		}
	    }
	    set y1 [expr $y0 + $sign * $major_tick_length/2]
	    nap "i = cv @ minor_ticks"
	    set n [$minor_ticks nels]
	    for {set j 0} {$j < $n} {incr j} {
		set x [[nap "x1 + i(j)"]]
		$graph create line $x $y1 $x $y0
	    }
	    if {$label ne ""  &&  $unit ne "degrees_east"} {
		set x [expr $x0 + 0.5 * $length]
		set y [expr $y2 + $sign * $linespace]
		$graph create text $x $y -font $font_standard -justify center \
			-tags xlabel -text $label
	    }
	}
    }


    # draw_x_axis_for_xy --
    #
    # Draw linear x-axis with origin at (x0,y0)

    proc draw_x_axis_for_xy {
	window_id
	graph
	label
	x0
	y0
	length
	{sign 1}
    } {
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::major_ticks_x
	nap "cv = (length + 1) ... major_ticks_x(0) .. major_ticks_x(-1)"
	$cv set unit [fix_unit [$major_ticks_x unit]]
	draw_x_axis $window_id $graph $label $x0 $y0 $length $cv $sign $major_ticks_x
    }


    # draw_x_axis_for_image --
    #
    # Draw x-axis with origin at (x0,y0), given a coord. var. defining value at each pixel.
    # sign is -1 for ticks above axis, 1 for ticks below axis
    # length is # columns in matrix

    proc draw_x_axis_for_image {
	window_id
	graph
	label
	x0
	y0
	length
	cv
	{sign 1}
    } {
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::major_ticks_x
	global Plot_nao::${window_id}::xproc
	set unit [fix_unit [$cv unit]]
	if {$major_ticks_x eq ""} {
	    nap "major_ticks_x = axis_major_ticks(cv, 32)"; # Just to define max_width
	    $major_ticks_x set unit $unit
	    set max_width [font measure $font_standard \
		    "[longest_element [axis_tick_text $major_ticks_x $xproc]] "]
	    nap "major_ticks_x = axis_major_ticks(cv, length / max_width - 1)"
	} else {
	    nap "tick_step = major_ticks_x(1) - major_ticks_x(0)"
	    nap "cv_range = cv(-1) - cv(0)"
	    nap "major_ticks_x = tick_step * cv_range > 0 ?  major_ticks_x : major_ticks_x(-)"
	}
	$major_ticks_x set unit $unit
	draw_x_axis $window_id $graph $label $x0 $y0 $length $cv $sign $major_ticks_x 0.5
    }


    # draw_y_axis --
    #
    # Draw y-axis with origin at (x0,y0), given a coord. var. defining value at each pixel.
    # sign is -1 for ticks on left of axis, 1 for ticks on right of axis
    # y0 is y-coord. of top of axis

    proc draw_y_axis {
	window_id
	graph
	label
	x0
	y0
	length
	cv
	sign
	major_ticks
	format_proc
	{tick_offset 0}
    } {
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::major_tick_length
	set linespace [font metrics $font_standard -linespace]
	set spacing [expr $linespace / 4]
	$graph create line $x0 $y0 $x0 [expr $y0 + $length]
	nap "minor_ticks = axis_minor_ticks(cv, major_ticks)"
	set unit [fix_unit [$cv unit]]
	set is_geog [regexp {degrees_(east|north)} $unit]
	$major_ticks set unit $unit
	set labels [axis_tick_text $major_ticks $format_proc]
	set max_width [font measure $font_standard [longest_element $labels]]
	set x1 [expr $x0 + $sign * $major_tick_length]
	nap "y1 = y0 + tick_offset"
	if {$sign < 0} {
	    set x2 [expr $x1 - $spacing]
	    set x3 [expr $x2 - $max_width - 2 * $spacing]
	    set anchor e
	} else {
	    set x2 [expr $x1 + $spacing + $max_width]
	    set x3 [expr $x2 + 2 * $spacing]
	    set anchor w
	}
	nap "i = cv @ major_ticks"
	set n [$major_ticks nels]
	nap "step_major = f64(major_ticks(1) - major_ticks(0))"
	nap "normalised = nint(10.0 ** (log10(abs(step_major)) % 1.0))"
	nap "want_text = normalised != 5 ||  nint(major_ticks / step_major) % 2 == 0"
	if {[[nap "is_geog  ||  sum(want_text) < 4"]]} {
	    nap "want_text = n # 1"
	}
	nap "tmp = want_text * major_ticks"
	$tmp set unit $unit
	set labels [axis_tick_text $tmp $format_proc]
	for {set j 0} {$j < $n} {incr j} {
	    set y [[nap "y1 + i(j)"]]
	    $graph create line $x1 $y $x0 $y
	    if {[[nap "want_text(j)"]]} {
		set text [lindex $labels $j]
		$graph create text $x2 $y -anchor e -font $font_standard -justify right -text $text
	    }
	}
	set x1 [expr $x0 + $sign * $major_tick_length/2]
	nap "i = cv @ minor_ticks"
	set n [$minor_ticks nels]
	for {set j 0} {$j < $n} {incr j} {
	    set y [[nap "y1 + i(j)"]]
	    $graph create line $x1 $y $x0 $y
	}
	if {$label ne ""  &&  $unit ne "degrees_north"} {
	    set y [expr $y0 + 0.5 * $length]
	    vertical_text $graph $label $x3 $y $font_standard $anchor ylabel
	}
    }


    # draw_y_axis_for_xy --
    #
    # Draw linear y-axis with origin at (x0,y0)

    proc draw_y_axis_for_xy {
	window_id
	graph
	label
	x0
	y0
	length
	range_y
	unit
	{sign -1}
    } {
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::major_ticks_y
	global Plot_nao::${window_id}::want_y_axis
	global Plot_nao::${window_id}::yproc
	if {$major_ticks_y eq ""} {
	    nap "range_y = range(range_y)"
	    if {[[nap "range_y(0) == range_y(1)"]]} {
		nap "range_y = range_y + {0 1}"
	    }
	    nap "nmax = i32(length / [font metrics $font_standard -linespace] - 1)"
	    nap "nmax = nmax > 4 ? nmax/2 + 2 : nmax"
	    nap "major_ticks_y = scaleAxisSpan(range_y(1), range_y(0), nmax)"
	} else {
	    nap "major_ticks_y = (sort(major_ticks_y))(-)"
	}
	$major_ticks_y set unit $unit
	nap "cv = (length + 1) ... major_ticks_y(0) .. major_ticks_y(-1)"
	$cv set unit $unit
	if {$want_y_axis} {
	    draw_y_axis $window_id $graph $label $x0 $y0 $length $cv $sign $major_ticks_y $yproc
	}
	return [[nap "major_ticks_y{-1 0}"]]
    }


    # draw_y_axis_for_image --
    #
    # Draw y-axis with origin at (x0,y0), given a coord. var. defining value at each pixel.
    # y0 is y-coord. of top of axis
    # length is # rows in matrix

    proc draw_y_axis_for_image {
	window_id
	graph
	label
	x0
	y0
	length
	cv
    } {
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::major_ticks_y
	global Plot_nao::${window_id}::yproc
	global Plot_nao::${window_id}::want_y_axis
	if {$want_y_axis} {
	    if {$major_ticks_y eq ""} {
		nap "nmax = i32(length / [font metrics $font_standard -linespace] - 1)"
		nap "nmax = nmax > 4 ? nmax/2 + 2 : nmax"
		nap "major_ticks_y = axis_major_ticks(cv, nmax)"
	    } else {
		nap "tick_step = major_ticks_y(1) - major_ticks_y(0)"
		nap "cv_range = cv(-1) - cv(0)"
		nap "major_ticks_y = tick_step * cv_range > 0 ?  major_ticks_y : major_ticks_y(-)"
	    }
	    set unit [$cv unit]
	    if {$unit ne "(NULL)"} {
		$major_ticks_y set unit $unit
	    }
	    draw_y_axis $window_id $graph $label $x0 $y0 $length $cv -1 $major_ticks_y $yproc 0.5
	}
    }


    # crosshairs_xy --
    #
    # called when pointer moves within xy-plot or barchart

    proc crosshairs_xy {
	all
	window_id
	graph
	x_b
	xslope
	y_b
	yslope 
	screen_x
	screen_y
	{color_crosshair red}
    } {
	global Plot_nao::x
	global Plot_nao::y
	global Plot_nao::xyz
	if {![winfo exists $all.xyz]} {
	    Plot_nao::create_xyz $all $window_id $graph 0
	    $graph config -cursor crosshair
	}
	set width_total  [lindex [$graph cget -scrollregion] 2]
	set height_total [lindex [$graph cget -scrollregion] 3]
	set can_x [$graph canvasx $screen_x]
	set can_y [$graph canvasy $screen_y]
	$graph delete lines
	set x [format %0.6g [expr "$xslope * $can_x + $x_b"]]
	set y [format %0.6g [expr "$yslope * $can_y + $y_b"]]
	set xyz "$x $y"
	$graph create line $can_x 0 $can_x $height_total -fill $color_crosshair -tag lines
	$graph create line 0 $can_y $width_total $can_y  -fill $color_crosshair -tag lines
    }


    # crosshairs_xyz --
    #
    # called when pointer moves within z-plot (image plot)

    proc crosshairs_xyz {
	all
	window_id
	graph
	margin_left
	margin_top
	screen_x
	screen_y
	{color_crosshair red}
    } {
	global Plot_nao::buttonIsDown
	global Plot_nao::x
	global Plot_nao::y
	global Plot_nao::z
	global Plot_nao::xyz
	global Plot_nao::${window_id}::box_x0
	global Plot_nao::${window_id}::box_y0
	global Plot_nao::${window_id}::gap_width
        global Plot_nao::${window_id}::image_nao
	if {$gap_width eq ""} {
	    set gap_width 20
	}
	if {![winfo exists $all.xyz]} {
	    Plot_nao::create_xyz $all $window_id $graph 1
	    $graph config -cursor crosshair
	}
	set scroll_region [$graph cget -scrollregion]
	set width_total  [lindex $scroll_region 2]
	set height_total [lindex $scroll_region 3]
	set can_x [$graph canvasx $screen_x]
	set can_y [$graph canvasy $screen_y]
	$graph delete lines
	$graph create line $can_x 0 $can_x $height_total -fill $color_crosshair -tag lines
	$graph create line 0 $can_y $width_total $can_y  -fill $color_crosshair -tag lines
	nap "cvx = coordinate_variable(image_nao,-1)"
	nap "cvy = coordinate_variable(image_nao,-2)"
	nap "nx = nels(cvx)"
	nap "ny = nels(cvy)"
	nap "i = can_y - $margin_top  >>> 0 <<< ny - 1"
	nap "j = can_x - $margin_left >>> 0"
	set x [[nap "cvx(j <<< nx - 1)"] -format %0.6g]
	set y [[nap "cvy(i)"] -format %0.6g]
	if {[$image_nao rank] == 3} {
	    set z [[nap "image_nao(, i, j <<< nx - 1)"] value -format %0.6g]
	} else {
	    if [[nap "j < nx + gap_width/2"]] {
		set z [[nap "image_nao(i, j <<< nx - 1)"] -format %0.6g]
	    } else {
		global Plot_nao::${window_id}::scalingFromZ
		global Plot_nao::${window_id}::scalingToZ
		if {$scalingFromZ(0) == ""} {
		    set zmin 0
		} else {
		    set zmin [string map {Inf 1nf32} $scalingFromZ(0)]
		}
		if {$scalingToZ(0) == ""} {
		    set zmax 255
		} else {
		    set zmax [string map {Inf 1nf32} $scalingToZ(0)]
		}
		set z [[nap "zmax - i * (zmax - zmin) / (ny - 1f32)"] -format %0.6g]
	    }
	}
	if {$buttonIsDown} {
	    $graph delete box
	    $graph create rectangle $box_x0 $box_y0 $can_x $can_y -tag box
	}
	set xyz "$x $y $z"
    }


    # set_scaling --
    #
    # Set scalingFromZ, scalingToZ, scalingFromU, scalingToU, scalingIntercept, scalingSlope
    # May also set want_equalise, upper, discrete_colors
    #
    # tol is tolerance to allow for rounding:
    # scalingFromU = tol
    # scalingToU = (1f32 - tol) * upper

    proc set_scaling {
	window_id
	nao
	range_nao
	{tol 1e-6f32}
    } {
	global Plot_nao::${window_id}::discrete_colors
	global Plot_nao::${window_id}::scalingFromZ
	global Plot_nao::${window_id}::scalingFromU
	global Plot_nao::${window_id}::scalingIntercept
	global Plot_nao::${window_id}::scalingSlope
	global Plot_nao::${window_id}::scalingToZ
	global Plot_nao::${window_id}::scalingToU
        global Plot_nao::${window_id}::upper
        global Plot_nao::${window_id}::want_equalise
	global Plot_nao::${window_id}::zlabels
	if {$zlabels ne ""} {
	    set discrete_colors 1
	    nap "range_nao = (0 // [llength $zlabels]) - 0.5"
	}
	if {$discrete_colors} {
	    set want_equalise 0
	}
	if {! $want_equalise} {
	    set upper 255
	}
	set nlayers [[nap "rank(nao) == 2 ? 1 : (3 <<< (shape(nao))(0))"]]
	set any_blank 0
	for {set layer 0} {$layer < $nlayers} {incr layer} {
	    set any_blank [expr {$any_blank  ||  $scalingFromZ($layer) eq ""}]
	    set any_blank [expr {$any_blank  ||  $scalingToZ($layer)   eq ""}]
	}
	if {! $any_blank} {
	    set range_nao ""
	}
	nap "scalingFromU = tol"
	if {[$nao datatype] eq "u8"  &&  [$nao missing] eq "(NULL)"} {
	    if {$range_nao eq ""} {
		for {set layer 0} {$layer < $nlayers} {incr layer} {
		    if {$scalingFromZ($layer) eq ""} {
			set scalingFromZ($layer) 0
		    }
		    if {$scalingToZ($layer) eq ""} {
			set scalingToZ($layer) 255
		    }
		}
	    }
	    nap "scalingToU = (1f32 - tol) * 256f32"
	} else {
	    nap "scalingToU = (1f32 - tol) * upper"
	}
	if {$range_nao eq ""} {
	    nap "range_nao = reshape(0f32, {0 2})"
	    for {set layer 0} {$range_nao != ""  &&  $layer < $nlayers} {incr layer} {
		if {$scalingFromZ($layer) eq ""  ||  $scalingToZ($layer) eq ""} {
		    set range_nao ""
		} else {
		    nap "range_nao = range_nao // ($scalingFromZ($layer) // $scalingToZ($layer))"
		}
	    }
	}
	if {$range_nao eq ""} {
	    nap "range_nao = nao"
	}
	if [[nap "rank(range_nao) == 0"]] {
	    handle_error "range array is scalar!"
	    return
	}
	nap "same_shape = rank(nao) == rank(range_nao)"
	if [$same_shape] {
	    nap "same_shape = prod(shape(nao) == shape(range_nao))"
	}
	if [[nap "same_shape  &&  rank(nao) == 3"]] {
	    nap "minValue = f32(min(min(range_nao, 2), 1))"
	    nap "maxValue = f32(max(max(range_nao, 2), 1))"
	} elseif [[nap "rank(nao) == 3  &&  rank(range_nao) == 2
		&&  (3 <<< (shape(nao))(0)) == (shape(range_nao))(0)"]] {
	    nap "minValue = f32(min(range_nao, 1))"
	    nap "maxValue = f32(max(range_nao, 1))"
	} elseif [[nap "rank(nao) == 2"]] {
	    nap "range_vector = f32(range(range_nao))"
	    nap "minValue = range_vector(0)"
	    nap "maxValue = range_vector(1)"
	} else {
	    nap "range_vector = f32(range(range_nao))"
	    nap "minValue = (shape(nao))(0) # range_vector(0)"
	    nap "maxValue = (shape(nao))(0) # range_vector(1)"
	}
	set nlayers [$minValue nels]
	if {$nlayers > 3} {
	    set nlayers 3
	    nap "minValue = reshape(minValue, 3)"
	    nap "maxValue = reshape(maxValue, 3)"
	}
	nap "maxValue = maxValue > minValue ? maxValue : maxValue + 1"
	nap "span = maxValue - minValue"
	nap "scalingSlope = span == 0f32 ? 1f32 : (scalingToU - scalingFromU) / span"
	nap "scalingSlope = min(scalingSlope) < max(scalingSlope)
		? scalingSlope : min(scalingSlope)"
	nap "scalingIntercept = scalingFromU - scalingSlope * minValue"
	nap "scalingIntercept = min(scalingIntercept) < max(scalingIntercept)
		? scalingIntercept : min(scalingIntercept)"
	nap "minValue = reshape(minValue)"
	nap "maxValue = reshape(maxValue)"
	for {set layer 0} {$layer < $nlayers} {incr layer} {
	    set scalingFromZ($layer) [[nap "minValue(layer)"]]
	    set scalingToZ($layer) [[nap "maxValue(layer)"]]
	}
    }

    # incrRefCount --


    proc incrRefCount {
	window_id
	nao
    } {
	global Plot_nao::${window_id}::save_nao_ids
	if {$nao ne ""} {
	    $nao set count +1
	    lappend save_nao_ids $nao
	}
    }


    # palette3 --
    #
    # nap function to convert palette to standard form with 3 columns
    # If argument has 4 columns then column 0 contains colour index (0 to 255)
    # The three RGB columns normally have values in range 0 to 255.  But if the argument is
    # of type f32 or f64 & the RGB values do not exceed 1.0 then they will be multiplied by 256.
    # Result has type u8 & shape {256 3}. Values range from 0 to 255.
    # Undefined rows are set to {255 255 255}.
    # If error return matrix with shape {0 3}

    proc palette3 {
	palette
    } {
	nap "s = shape(palette)"
	if {[[nap "rank(palette) == 2  &&  s(0) <= 256  &&  s(1) >= 3  &&  s(1) <= 4"]]} {
	    nap "index = (s(1) == 4 ? i32(palette(,0)) : (0 .. (s(0) - 1))) >>> 0 <<< 255"
	    nap "rgb   = palette(,-3 .. -1)"
		# range01 is true (1) if have fractional values from 0.0 to 1.0 rather than whole
		# numbers from 0 to 255
	    nap "range01 = max(max(rgb)) <= 1  &&  [string match f* [$palette datatype]]"
	    nap "rgb = u8(range01 ? (256.0 * rgb >>> 0.0 <<< 255.0) : rgb)"
	    nap "result = {256 # {3 # 255u8}}"
	    $result set value rgb index,
	} else {
	    nap "result = reshape(0u8, {0 3})"
	}
	nap "result"
    }

    # draw_tiles --
    #
    # Plot 3-D NAO as grid of coloured 'tiles' corresponding to levels

    proc draw_tiles {
	all
	window_id
	graph
	nao
	range_nao
	want_yflip
    } {
        global Plot_nao::${window_id}::want_scaling_widget
	if {[check_cvs $nao]} {
	    handle_error "Illegal coordinate variable"
	    return
	}
	    # This graph widget points to nao, so increment ref. count
	    # Decrement when widget destroyed (in procedure "close_window")
	Plot_nao::incrRefCount $window_id $nao
	set nlevels [[nap "(shape(nao))(0)"]]
	set ny [[nap "(shape(nao))(1)"]]
	set nx [[nap "(shape(nao))(2)"]]
	set_yflip $window_id $want_yflip $nao
	frame $all.scaling_range
	if {$want_scaling_widget} {
	    pack $all.scaling_range -before $all.main -anchor n -fill x
	}
	nap "nao2d = reshape(nao, (nlevels * ny) // nx)"
	Plot_nao::incrRefCount $window_id $nao2d
	set color black
	set frame $all.scaling_range.$color
	set redraw_command [list Plot_nao::redraw_tiles $all $window_id $graph $nao \
		$nlevels $ny $nx $nao2d $range_nao]
	create_scaling_range $all $window_id $frame $nao2d 0 $color $redraw_command
	create_main_menu $all $window_id $graph $redraw_command $nao
	eval $redraw_command
    }

    # redraw_tiles --

    proc redraw_tiles {
	all
	window_id
	graph
	nao
	nlevels
	ny
	nx
	nao2d
	range_nao
    } {
	global Plot_nao::${window_id}::font_standard
	global Plot_nao::${window_id}::font_title
	global Plot_nao::${window_id}::gap_height
	global Plot_nao::${window_id}::gap_width
	global Plot_nao::${window_id}::key_width
        global Plot_nao::${window_id}::labels
        global Plot_nao::${window_id}::magnification
	global Plot_nao::${window_id}::major_tick_length
	global Plot_nao::${window_id}::ncols
        global Plot_nao::${window_id}::new_height
        global Plot_nao::${window_id}::new_width
	global Plot_nao::${window_id}::orientation
	global Plot_nao::${window_id}::title
	global Plot_nao::${window_id}::xflip
	global Plot_nao::${window_id}::yflip
	global Print_gui::paperheight 
	global Print_gui::paperwidth
	if {$gap_height eq ""} {
	    set gap_height 20
	}
	if {$gap_width eq ""} {
	    set gap_width 20
	}
	if {$labels eq ""} {
	    set tile_labels [[nap "coordinate_variable(nao, -3)"] value]
	} else {
	    set tile_labels $labels
	}
	set screen_height [winfo screenheight $all]
	set screen_width  [winfo screenwidth  $all]
	set screen_ratio [expr double($screen_height) / double($screen_width)]
	set paper_ratio [expr double([winfo fpixels . $paperheight]) \
			    / double([winfo fpixels . $paperwidth])]
	if {$orientation eq "L"} {
	    set paper_ratio [expr 1.0 / $paper_ratio]
	}
	if {$orientation ne "A"} {
	    if {$screen_ratio > $paper_ratio} {
		set screen_height [expr $screen_width * $paper_ratio]
	    } else {
		set screen_width [expr $screen_height / $paper_ratio]
	    }
	    set new_width  ""
	    set new_height ""
	}
	if {$magnification ne ""} {
	    set new_width  [expr int($magnification * $nx)]
	    set new_height [expr int($magnification * $ny)]
	}
	$graph delete all
	set_scaling $window_id $nao2d $range_nao
	set axis_text_width [expr 10 * [font measure $font_standard A]]
	set width_title [font measure $font_title $title]
	set linespace [font metrics $font_title -linespace]
	set title_height [expr $linespace * 4]
	set ncols [layout_tiles $window_id $nlevels $ncols $screen_height $screen_width \
		$ny $nx $key_width $title_height \
		$axis_text_width]
	nap "j = 0 // (nx - 1)"
	nap "j = i32(nint(ap_n(j(xflip), j(!xflip), nint(new_width))))"
	nap "i = 0 // (ny - 1)"
	nap "i = i32(nint(ap_n(i(yflip), i(!yflip), nint(new_height))))"
	nap "mat = nao(0,i,j)"
	set image_height "[$i nels]"
	set image_width  "[$j nels]"
	set nrows [expr ($nlevels + $ncols - 1) / $ncols]
	set key_height [expr ($image_height + $gap_height) * $nrows - $gap_height]
	    # Create canvas & key
	set can_height [expr $title_height + $nrows * ($image_height + $gap_height)]
	set can_width  [expr $ncols * ($image_width + $gap_width) + $gap_width]
	$graph configure -width  $can_width -height $can_height
	if {$key_width > 0} {
	    set x $can_width
	    incr can_width [expr $key_width + $major_tick_length + $axis_text_width]
	    $graph configure -width  $can_width -height $can_height
	    z_major_ticks_mapping $window_id $key_height
	    draw_key $window_id $graph $x $title_height $key_height
	}
	for {set level 0} {$level < $nlevels} {incr level} {
	    nap "mat = nao(level,i,j)"
	    nao2image u $window_id $mat 1
	    set img [image create photo -format NAO -data $u]
	    set row [expr $level / $ncols]
	    set col [expr $level % $ncols]
	    set x [expr $gap_width + ($image_width + $gap_width) * $col]
	    set y [expr $title_height + ($image_height + $gap_height) * $row]
	    $graph create image $x $y -image $img -anchor nw
	    set x [expr $x + $image_width / 2]
	    set y [expr $y + $image_height + $gap_height * 5 / 12]
	    $graph create text $x $y -text [lindex $tile_labels $level] -font $font_standard 
	}
	set x [expr $can_width / 2]
	set y [expr $title_height / 2]
	$graph create text $x $y -text $title -font $font_title
    }

    # layout_tiles --
    #
    # Return # columns (if ncols arg defined then this is result)
    # Also if both are undefined then set new_height & new_width

    proc layout_tiles {
	window_id
	nlevels
	ncols
	screen_height
	screen_width
	image_height
	image_width
	key_width
	title_height
	axis_text_width
    } {
	global Plot_nao::${window_id}::gap_height
	global Plot_nao::${window_id}::gap_width
	global Plot_nao::${window_id}::major_tick_length
        global Plot_nao::${window_id}::new_height
        global Plot_nao::${window_id}::new_width
	if {$gap_height eq ""} {
	    set gap_height 20
	}
	if {$gap_width eq ""} {
	    set gap_width 20
	}
	if {$ncols eq ""} {
	    set nc_min 1
	    set nc_max $nlevels
	} else {
	    set nc_min $ncols
	    set nc_max $ncols
	}
	if {$new_height eq ""  &&  $new_width eq ""} {
	    for {set step 1} {1} {incr step} {
		set min_area 1e9
		for {set nc $nc_min} {$nc <= $nc_max} {incr nc} {
		    set nrows [expr ($nlevels + $nc - 1) / $nc]
		    set new_height [expr ($image_height + $step - 1) / $step]
		    set new_width [expr ($image_width  + $step - 1) / $step]
		    set can_height [expr $title_height + $nrows * ($new_height + $gap_height)]
		    set can_width  [expr $nc * ($new_width + $gap_width) + $gap_width]
		    if {$key_width > 0} {
			incr can_width [expr $key_width + $major_tick_length + $axis_text_width]
		    }
		    if {$can_width <= $screen_width  &&  $can_height <= $screen_height} {
			set area [expr $can_height * $can_width]
			if {$area < $min_area} {
			    set min_area $area
			    set ncols $nc
			}
		    }
		}
		if {$ncols ne ""} {
		    return $ncols
		}
	    }
	} else {
	    set min_area_fits 1e9; # for case where fits on screen
	    set min_area 1e9; #  all cases
	    set ncols_fits ""
	    for {set nc $nc_min} {$nc <= $nc_max} {incr nc} {
		set nrows [expr ($nlevels + $nc - 1) / $nc]
		set can_height [expr $title_height + $nrows * ($new_height + $gap_height)]
		set can_width  [expr $nc * ($new_width + $gap_width) + $gap_width]
		if {$key_width > 0} {
		    incr can_width [expr $key_width + $major_tick_length + $axis_text_width]
		}
		set area [expr $can_height * $can_width]
		if {$area < $min_area} {
		    set min_area $area
		    set ncols $nc
		}
		if {$can_width <= $screen_width  &&  $can_height <= $screen_height  && \
			$area < $min_area_fits} {
		    set min_area_fits $area
		    set ncols_fits $nc
		}
	    }
	    if {$ncols_fits ne ""} {
		return $ncols_fits
	    } else {
		return $ncols
	    }
	}
    }

    # nao2image --
    #
    # Produce 3D image NAO from:
    #   - 2D or 3D data NAO (nao) with main palette NAO (main_palette)
    #   - overlay_NAO with overlay_palette

    proc nao2image {
	name_result
	window_id
	nao
	{allow_overlay 0}
	{latitude ""}
	{longitude ""}
    } {
        global Plot_nao::${window_id}::main_palette
        global Plot_nao::${window_id}::mapping
	global Plot_nao::${window_id}::overlay_nao
        global Plot_nao::${window_id}::overlay_palette
        global Plot_nao::${window_id}::scalingFromU
	global Plot_nao::${window_id}::scalingIntercept
	global Plot_nao::${window_id}::scalingSlope
	global Plot_nao::${window_id}::scalingToU
	upvar $name_result u
	set rank [$nao rank]
	if {[[nap "scalingToU <= 255"]]} {
	    set dataType u8
	} elseif {[[nap "scalingToU <= 65535"]]} {
	    set dataType u16
	} else {
	    set dataType u32
	}
	if {$rank == 2} {
	    nap "u = dataType((scalingSlope * nao + scalingIntercept) 
		    >>> scalingFromU <<< scalingToU)"
	} else {
	    nap "s = shape(nao)"
	    set n_layers [[nap "3 <<< s(0)"]]
	    nap "u = reshape(dataType(0), 0 // s{1 2})"
	    nap "scalingSlope = reshape(scalingSlope, n_layers)";         # In case scalar
	    nap "scalingIntercept = reshape(scalingIntercept, n_layers)"; # In case scalar
	    for {set i 0} {$i < $n_layers} {incr i} {
		nap "u = u // dataType((scalingSlope(i) * nao(i,,) + scalingIntercept(i)) 
			>>> scalingFromU <<< scalingToU)"
	    }
	}
	if {$mapping ne ""} {
	    nap "u = dataType(mapping(u))"
	}
	if {$main_palette ne ""  &&  $rank == 2} {
	    nap "rgb_mat = palette3(main_palette)"
	    if {[$rgb_mat nels] == 0} {
		handle_error "error calling NAP function palette3()"
		return
	    }
	    nap "u = (rgb_mat(,0))(u) /// (rgb_mat(,1))(u) // (rgb_mat(,2))(u)"
	}
	if {$allow_overlay} {
	    set_overlay $window_id $nao $latitude $longitude
	    if {$overlay_nao ne ""  &&  $overlay_palette ne ""} {
		nap "ov_rgb_mat = palette3(overlay_palette)"
		nap "ip = isPresent(overlay_nao)"
		if {[$u rank] == 2} {
		    nap "u = (ip ? (ov_rgb_mat(,0))(overlay_nao) : u) ///
			     (ip ? (ov_rgb_mat(,1))(overlay_nao) : u) //
			     (ip ? (ov_rgb_mat(,2))(overlay_nao) : u)"
		} else {
		    nap "n_layers = 3 <<< (shape(u))(0)"
		    nap "u = (ip ? (ov_rgb_mat(,0))(overlay_nao) : u(0,,)) ///
			     (ip ? (ov_rgb_mat(,1))(overlay_nao) : u(n_layers-2,,)) //
			     (ip ? (ov_rgb_mat(,2))(overlay_nao) : u(n_layers-1,,))"
		}
	    }
	}
    }

}
