package require toe 1.0

::toe::class ProgressDialog {
    private variable Toplevel
    
    method constructor {{mode indeterminate} {max 100}} {
        . configure -cursor watch
        set Toplevel [toplevel .progressDialog]
        wm withdraw $Toplevel
        update
        
        wm title $Toplevel "Opening GIS Dataset"
        wm attributes $Toplevel -topmost 1
        wm resizable $Toplevel 0 0
        wm overrideredirect $Toplevel 1
        
        grid [ttk::frame $Toplevel.f -padding 10] -sticky snwe
        grid [ttk::label $Toplevel.f.l -text "Loading GIS data. Please wait.." -anchor center -padding {0 0 0 8} ] -row 0 -column 0 -sticky s
        grid [ttk::progressbar $Toplevel.f.p -length 200 -orient horizontal -mode $mode -maximum $max] -row 1 -column 0 -sticky swe
        grid columnconfigure $Toplevel 0 -weight 1
        grid rowconfigure $Toplevel 0 -weight 1
        grid columnconfigure $Toplevel.f 0 -weight 1
        grid rowconfigure $Toplevel.f 0 -weight 1
        
        update
        set x [expr {([winfo screenwidth .]-[winfo width $Toplevel])/2}]
        set y [expr {([winfo screenheight .]-[winfo height $Toplevel])/2}]
        wm geometry  $Toplevel +$x+$y
        wm deiconify $Toplevel
        update
        focus $Toplevel
        grab $Toplevel
        
    }
    
    method destructor {} {
        destroy $Toplevel
        . configure -cursor {}
    }
    
    public method pbar {args} {
        $Toplevel.f.p {*}$args
    }
    
    public method wait {} {
        tkwait window $Toplevel
    }
    
    public method wait {} {
        tkwait window $Toplevel
    }
}

# set progDialog [toe::new ProgressDialog indeterminate 10]
# ::toe::delete $progDialog