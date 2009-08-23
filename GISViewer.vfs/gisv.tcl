#!/usr/bin/tclsh

package require Tcl 8.5
package require Tk 8.5
package require Img 1.3

### Dependencies and dependency checks

# Get full pathname to this file
set RootDir [file normalize [file dirname [info script]]]

lappend auto_path $RootDir /usr/local/lib/
::tcl::tm::path add $RootDir

source [file join $RootDir GIScanvas.tcl]
source [file join $RootDir toolbar.tcl]

# No Tear-Off menus in Tk
option add *tearOff 0

# Additional global-wide bindings
bind TScrollbar <Button-4> {ttk::scrollbar::Scroll %W -1 units}
bind TScrollbar <Button-5> {ttk::scrollbar::Scroll %W 1 units}

### Setting up User Interface

wm geometry . [winfo screenwidth .]x[winfo screenheight .]
wm title . "GIS Viewer"

grid columnconfigure . 0 -weight 1; grid rowconfigure . 0 -weight 1
grid [ttk::frame .c -borderwidth 0] -sticky nswe

grid [ttk::frame .c.toolbar] -row 0 -column 0 -sticky nswe

grid [ttk::frame .c.map] -row 1 -column 0 -sticky nswe
grid columnconfigure .c 0 -weight 1; grid rowconfigure .c 1 -weight 1
set map [toe::new GIScanvas .c.map]

grid [ttk::scrollbar .c.map.hbar -orient horizontal -command "$map xview"] -row 1 -column 0 -sticky we
grid [ttk::scrollbar .c.map.vbar -orient vertical -command "$map yview"] -row 0 -column 1 -sticky ns
$map configure -yscrollcommand ".c.map.vbar set" -xscrollcommand ".c.map.hbar set"
grid [ttk::sizegrip .c.map.sz] -row 1 -column 1 -sticky se

grid [ttk::frame .c.status] -row 2 -column 0 -sticky nswe
set statusbar [ttk::panedwindow .c.status.bar -height 30 -orient horizontal -style toolbar.TPanedwindow]
grid $statusbar -sticky nswe
set Status ""
grid [ttk::label $statusbar.text -anchor w -wraplength 0 -textvariable Status -padding "5 0 0 0"] -sticky nswe

set toolbar [toe::new Toolbar .c.toolbar horizontal 30]
$toolbar group add maptbar
$toolbar widget add maptbar [ttk::label .zoom_lbl -justify right -text Zoom]
$toolbar widget add maptbar [ttk::entry .zoom_entry -justify right -state readonly -textvariable zoom]
$toolbar widget add maptbar [ttk::label .scale_lbl -justify right -text Scale]
$toolbar widget add maptbar [ttk::entry .scale_entry -justify right -state readonly -textvariable scale]
image create photo ::images::zoom_in -file [file join $RootDir icons zoom-in.png]
image create photo ::images::zoom_out -file [file join $RootDir icons zoom-out.png]
image create photo ::images::zoom_original -file [file join $RootDir icons zoom-original.png]
image create photo ::images::zoom_best -file [file join $RootDir icons zoom-best-fit.png]
$toolbar button add maptbar zoom_in ::images::zoom_in "$map zoom relative [expr {1.0 + [$map zoomfactor]}]"
$toolbar button add maptbar zoom_out ::images::zoom_out "$map zoom relative [expr {1.0 - [$map zoomfactor]}]"
$toolbar button add maptbar zoom_original ::images::zoom_original "$map zoom absolute 1.0"
$toolbar button add maptbar zoom_best ::images::zoom_best "$map zoom best"

array set info1 {x 0 y 0 projx 0 projy 0 lat 0 long 0 altitude 0}
array set info2 {zoom 100 scale 1}
$map monitor -x ::info1(x) -y ::info1(y) -lat ::info1(lat) -long ::info1(long) -altitude ::info1(altitude) -projx ::info1(projx) -projy ::info1(projy)
$map monitor -zoom ::info2(zoom) -scale ::info2(scale)
trace add variable ::info1 write update_status
trace add variable ::info2 write update_toolbar

proc update_status {args} {
    global Status info1
    set Status "X: $::info1(x)px   Y: $::info1(y)px    Northing: $::info1(projy)   Easting: $::info1(projx)    Latitude: $::info1(lat)°   Longitude: $::info1(long)°    Altitude: $::info1(altitude)"
}

proc update_toolbar {args} {
    global zoom scale info2
    set zoom "[expr {int($info2(zoom))}]%"
    set scale "1:$info2(scale)"
}

### Command-line Processing

if {$::argv ne ""} {
    if {[llength $::argv] != 1} {
        puts stderr "Wrong number of arguments."
        puts stderr "Syntax: $argv0 <filepath>"
        exit 1
    }
    $map openMap $::argv
    $map zoom best
}

proc file_open {} {
    global map
    set filepath [tk_getOpenFile -filetypes [list [list "All files" "*"] {*}[concat [$map cget -rasterfiletypes] [$map cget -vectorfiletypes]]]]
    if {$filepath ne ""} {
        if {[catch {
            $map openMap $filepath
        } errstr errtrace]} {
            return ;# XXX handle errors here instead of inside GIScanvas
        }
        $map zoom best
    }
}



