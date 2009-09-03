#!/usr/bin/tclsh

package require Tcl 8.5
package require Tk 8.5
package require Img 1.3

lappend auto_path [file join $VRootDir fsdialog]

### Dependencies and dependency checks

source [file join $VRootDir toe-1.0.tm]
source [file join $VRootDir GIScanvas.tcl]
source [file join $VRootDir toolbar.tcl]

# No Tear-Off menus in Tk
option add *tearOff 0

# Additional global-wide bindings
bind TScrollbar <Button-4> {ttk::scrollbar::Scroll %W -10 units}
bind TScrollbar <Button-5> {ttk::scrollbar::Scroll %W 10 units}

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

set menubar [menu .menubar -relief flat]
. configure -menu $menubar
menu $menubar.file
menu $menubar.help
$menubar add cascade -menu $menubar.file -label File
$menubar add cascade -menu $menubar.help -label Help
$menubar.file add command -label Open -command file_open
#$menubar.file add command -label Info -command XXX
$menubar.file add separator
$menubar.file add command -label Exit -command exit
$menubar.help add command -label About -command \
        [list tk_messageBox -title "About GISVierer" -message \
        "GISVierwer GIS Software\n\nCopyright © 2009 Alexandros Stergiakis. All rights reserved.\n\nTerms of Use: GNU General Public License Version 3"]

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
    
    if {$tcl_platform(os) eq "Linux"} {
        set filepath [ttk_getOpenFile -hidden 0 -sepfolders 0 -filetypes [list [list "All files" "*"] {*}[concat [$map cget -rasterfiletypes] [$map cget -vectorfiletypes]]]]
    } else {
        set filepath [tk_getOpenFile -filetypes [list [list "All files" "*"] {*}[concat [$map cget -rasterfiletypes] [$map cget -vectorfiletypes]]]]
    }
    if {$filepath ne ""} {
        if {[catch {
            $map openMap $filepath
        } errstr errtrace]} {
            return ;# XXX handle errors here instead of inside GIScanvas
        }
        $map zoom best
    }
}



