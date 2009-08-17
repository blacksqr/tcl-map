#!/usr/bin/tclsh

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
ttk::style configure toolbar.TPanedwindow -showHandle 1 -handleSize 0 -sashRelief ridge -sashWidth 2 -sashPad 4
set toolbar [ttk::panedwindow .c.toolbar.bar -height 30 -orient horizontal -style toolbar.TPanedwindow]
grid $toolbar -sticky nswe

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

array set info1 {x 0 y 0 lat 0 long 0}
array set info2 {zoom 1.0 scale 1}
$map monitor -x ::info1(x) -y ::info1(y) -lat ::info1(lat) -long ::info1(long)
$map monitor -zoom ::info2(zoom) -scale ::info2(scale)
trace add variable ::info1 write update_status

proc update_status {args} {
    global Status info1
    set Status "X: $::info1(x)   Y: $::info1(y)    Latitude: $::info1(lat)°   Longitude: $::info1(long)°"
}

set menubar [menu .menubar -relief flat]
. configure -menu $menubar

menu $menubar.file
menu $menubar.help
$menubar add cascade -menu $menubar.file -label File
$menubar add cascade -menu $menubar.help -label Help
$menubar.file add command -label Open -command {open_file [tk_getOpenFile -filetypes [$map cget -filetypes]]}
$menubar.file add command -label Info -command XXX
$menubar.file add separator
$menubar.file add command -label Exit -command exit
$menubar.help add command -label "About GIS Viewer" -command \
        [list tk_messageBox -message "Copyright © 2009 Alexandros Stergiakis. All rights reserved. Terms of Use: GNU General Public License Version 3"]

### Command-line Processing

if {$::argv ne ""} {
    if {[llength $::argv] != 1} {
        puts stderr "Wrong number of arguments."
        puts stderr "Syntax: $argv0 <filepath>"
        exit 1
    }
    $map openGIS $::argv
}

proc open_file {filepath} {
    global map
    if {$filepath ne ""} {
        $map openGIS $::argv
    }
}



