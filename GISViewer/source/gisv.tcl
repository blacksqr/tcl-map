#!/usr/bin/tclsh

package require Tcl 8.5
package require Tk 8.5
package require Img 1.3

lappend auto_path [file join $VRootDir fsdialog]

### Dependencies and dependency checks

source [file join $VRootDir toe-1.0.tm]
source [file join $VRootDir GIScanvas.tcl]
source [file join $VRootDir toolbar.tcl]
source [file join $VRootDir tk_getString.tcl]

# No Tear-Off menus in Tk
option add *tearOff 0

# Additional global-wide bindings
bind TScrollbar <Button-4> {ttk::scrollbar::Scroll %W -10 units}
bind TScrollbar <Button-5> {ttk::scrollbar::Scroll %W 10 units}

### Setting up User Interface

wm geometry . [winfo screenwidth .]x[winfo screenheight .]
wm title . "GIS Viewer"

set menubar [menu .menubar -relief flat]
. configure -menu $menubar
menu $menubar.file
menu $menubar.help
$menubar add cascade -menu $menubar.file -label File
$menubar add cascade -menu $menubar.help -label Help
$menubar.file add command -label Open -command file_open
$menubar.file add separator
$menubar.file add command -label Exit -command exit
$menubar.help add command -label About -command \
        [list tk_messageBox -title "About GISVierer" -message \
        "GISVierwer GIS Software\n\nCopyright © 2009 Alexandros Stergiakis. All rights reserved.\n\nTerms of Use: GNU General Public License Version 3"]

grid columnconfigure . 0 -weight 1; grid rowconfigure . 0 -weight 1
grid [ttk::frame .c -borderwidth 0] -sticky nswe

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

ttk::frame .c.toolbar
set toolbar [toe::new Toolbar .c.toolbar horizontal 30]
$toolbar group add maptbar
#$toolbar widget add maptbar [ttk::label .zoom_lbl -justify right -text Zoom]
#$toolbar widget add maptbar [ttk::entry .zoom_entry -justify right -state readonly -textvariable zoom]
image create photo ::images::zoom_in -file [file join $RootDir icons zoom-in.png]
image create photo ::images::zoom_out -file [file join $RootDir icons zoom-out.png]
#image create photo ::images::zoom_original -file [file join $RootDir icons zoom-original.png]
image create photo ::images::zoom_best -file [file join $RootDir icons zoom-best-fit.png]
$toolbar button add maptbar zoom_in ::images::zoom_in "$map zoomin"
$toolbar button add maptbar zoom_out ::images::zoom_out "$map zoomout"
#$toolbar button add maptbar zoom_original ::images::zoom_original "$map zoom absolute 1.0"
$toolbar button add maptbar zoom_best ::images::zoom_best "$map zoom best"

array set mapinfo {x 0 y 0 projx 0 projy 0 lat 0 long 0 altitude 0}
$map monitor -x ::mapinfo(x) -y ::mapinfo(y) -lat ::mapinfo(lat) -long ::mapinfo(long) -altitude ::mapinfo(altitude) -projx ::mapinfo(projx) -projy ::mapinfo(projy)
trace add variable ::mapinfo write update_status

proc update_status {args} {
    global Status mapinfo
    set Status "X: [expr int($::mapinfo(x))]px   Y: [expr int($::mapinfo(y))]px    Northing: $::mapinfo(projy)   Easting: $::mapinfo(projx)    Latitude: $::mapinfo(lat)°   Longitude: $::mapinfo(long)°    Altitude: $::mapinfo(altitude)"
}

proc file_open {} {
    global toolbar map tcl_platform menubar
    
    set filetypes [lsort -index 0 [concat [$map cget -rasterfiletypes] [$map cget -vectorfiletypes]]]
    
    set filetypes [list [list "All files" "*"] {*}$filetypes]
    if {$tcl_platform(os) eq "Linux"} {
        set filepath [::ttk::getOpenFile -title "Open a GIS data file" -hidden 0 -sepfolders 0 -filetypes $filetypes]
    } else {
        set filepath [tk_getOpenFile -title "Open a GIS data file" -filetypes $filetypes]
    }
    if {$filepath ne ""} {
        if {[catch {
            $map openMap $filepath
        } errstr errtrace]} {
            tk_messageBox -icon error -message $errstr
        }
        grid .c.toolbar -row 0 -column 0 -sticky nswe
        $map zoom best
        $map configure -visible 1
    }
}
