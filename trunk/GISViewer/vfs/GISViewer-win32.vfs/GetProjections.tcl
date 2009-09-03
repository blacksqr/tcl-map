namespace eval GetProjections_ui {
proc GetProjections_ui {{geoProj4 ""} {projProj4 ""}} {
    variable base
    variable root
    variable geo $geoProj4
    variable proj $projProj4
    # this treats "." as a special case

    set root [toplevel .msg]
    wm withdraw $root
    update
    
    wm title $root "Map Projections"
    wm attributes $root -topmost 1
    wm resizable $root 0 0

    set base [ttk::frame $root.f]
    ttk::label $base.header_lbl \
	    -text {Specify Proj4 Specifications}
    catch {
	    $base.header_lbl configure \
		    -font -*-TkDefaultFont-Bold-R-Normal-*-*-120-*-*-*-*-*-*
    }

    ttk::label $base.geo_lbl \
	    -justify left \
	    -text Geographic

    ttk::entry $base.geo_entry \
	    -textvariable [namespace current]::geo 

    ttk::label $base.proj_lbl \
	    -justify left \
	    -text Projected

    ttk::entry $base.proj_entry \
	    -textvariable [namespace current]::proj 

    ttk::button $base.ok_but \
	    -text OK \
	    -command "destroy $root"


    # Add contents to menus

    # Geometry management

    grid $base -in $root	-row 0 -column 0
    grid $base.header_lbl -in $base	-row 1 -column 1  \
	    -columnspan 2
    grid $base.geo_lbl -in $base	-row 2 -column 1 
    grid $base.geo_entry -in $base	-row 2 -column 2 
    grid $base.proj_lbl -in $base	-row 3 -column 1 
    grid $base.proj_entry -in $base	-row 3 -column 2 
    grid $base.ok_but -in $base	-row 4 -column 1  \
	    -columnspan 2

    # Resize behavior management

    grid rowconfigure $root 0 -weight 1
    grid rowconfigure $base 1 -weight 0 -minsize 30 -pad 0
    grid rowconfigure $base 2 -weight 0 -minsize 30 -pad 0
    grid rowconfigure $base 3 -weight 0 -minsize 30 -pad 0
    grid rowconfigure $base 4 -weight 0 -minsize 30 -pad 0
    grid columnconfigure $base 1 -weight 0 -minsize 52 -pad 0
    grid columnconfigure $base 2 -weight 0 -minsize 229 -pad 0
    grid columnconfigure $root 0 -weight 1
# additional interface code
# end additional interface code

    update
    set x [expr {([winfo screenwidth .]-[winfo width $root])/2}]
    set y [expr {([winfo screenheight .]-[winfo height $root])/2}]
    wm geometry  $root +$x+$y
    wm deiconify $root
    update
    focus $root
    grab $root
    
    tkwait window $root
    return [list $geo $proj]
}
}
