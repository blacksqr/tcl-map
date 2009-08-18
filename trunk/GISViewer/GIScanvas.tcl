#
# TODO: Consider GetMaximum/GetMinimum for each band.
#       Consider GetNoValue for each band.
#       Understand and render band types: "Cyan" - "Magenta" - "Yellow" - "Black" - "YCbCr_Y" - "YCbCr_Cb" - "YCbCr_Cr"
#       
#
package require Tcl 8.5
package require Tk 8.5
package require Tkzinc 3.3
package require gdal 1.0
package require gdalconst 1.0
package require ogr 1.0
package require osr 1.0
package require nap 6.4
package require toe 1.0

# Initialize GDAL/OGR
::gdal::AllRegister
::ogr::RegisterAll

toe::class GIScanvas {
    private variable Container
    private variable Export
    private variable Map
    private variable Dataset

    method constructor {frame} {
        array set Export {x "" y "" lat "" long "" zoom "" scale ""}
        array set Map {filepath ""}
        set Map(frame) $frame
        
        grid columnconfigure $frame 0 -weight 1; grid rowconfigure $frame 0 -weight 1
        grid $frame -sticky nwse
        grid [ttk::frame $frame.f -borderwidth 2]
        
        set Container [zinc $frame.f.canvas -backcolor white -borderwidth 0 -width 1 -height 1 -cursor cross -relief flat -takefocus 0 -xscrollincrement 0 -yscrollincrement 0 -render 0]

        bind $Container <Button-4> "[self namespace]::zoom 1.05 %x %y"
        bind $Container <Button-5> "[self namespace]::zoom 0.95 %x %y"
        bind $Container <Motion> "[self namespace]::cursorupdate %x %y"
    }

    method cursorupdate {x y} {
        lassign [$Container transform 1 [list $x $y]] x y
        lassign [list $x $y] $Export(x) $Export(y)
        
        lassign [lindex [$Dataset GetGeoTransform] 0] x_start x_resol x_rot y_start y_rot y_resol
        set $Export(long) [expr {$x_start + $x * $x_resol + $y * $x_rot}]
        set $Export(lat) [expr {$y_start + $x * $y_rot + $y * $y_resol}]
    }
    
#    method xview {args} { $Container xview {*}$args }
#    method yview {args} { puts $args; $Container yview {*}$args }
    public method xview {cmd args} {
        switch -exact -- $cmd {
            "moveto" {
                set val $args

                lassign [$Container bbox all] x1 y1 x2 y2
                set width [expr {$x2 - $x1}]
                lassign [grid bbox $Map(frame)] _ _ w h
                set val2 [expr {double($w) / $width}]
                
                if {$val < 0} {set val 0}
                if {$val > 1 - $val2} {set val [expr {1-$val2}]}
                $Container translate 1 [expr {$val * $width * -1}] 0 yes
                
                {*}[$Container cget -xscrollcommand] $val [expr {$val + $val2}]
            }
            "scroll" {
                lassign val units
            }
        }
    }
    
    public method yview {cmd args} {
        switch -exact -- $cmd {
            "moveto" {
                set val $args

                lassign [$Container bbox all] x1 y1 x2 y2
                set width [expr {$x2 - $x1}]
                set height [expr {$y2 - $y1}]
                lassign [grid bbox $Map(frame)] _ _ w h
                set val2 [expr {double($h) / $height}]
                
                if {$val < 0} {set val 0}
                if {$val > 1 - $val2} {set val [expr {1-$val2}]}
                $Container translate 1 0 [expr {$val * $height * -1}] yes
                
                {*}[$Container cget -yscrollcommand] $val [expr {$val + $val2}]
            }
            "scroll" {
                lassign val units
            }
        }
    }
    
    public method configure {args} {
        foreach {var val} $args {
            switch -exact -- $var {
                "-xscrollcommand" -
                "-yscrollcommand" {
                    $Container configure $var $val
                }
            }
        }
    }

    public method cget {args} {
        foreach {var val} $args {
            switch -exact -- $var {
                "-filetypes" {
                    set formats [list]
                    set vector_exts [list]
                    for {set i 0} {$i < [::gdal::GetDriverCount]} {incr i} {
                        set driver [::gdal::GetDriver $i]
                        set ext [list]
                        foreach a [$driver GetMetadataItem DMD_EXTENSION] {
                            lappend ext "*.$a"
                        }
                        lappend vector_exts {*}$ext
                        if {$ext eq ""} {
                            puts stderr "No specific file extension specified by GDAL for [$driver cget -LongName]"
                            set ext "*"}
                        lappend formats [list "All files" "*"] [list "All vector files" $vector_exts] [list [$driver GetMetadataItem DMD_LONGNAME] $ext]
                    }
                    return $formats
                }
            }
        }
    }
    
    public method monitor {args} {
        foreach {var val} $args {
            switch -exact -- $var {
                "-x" { set Export(x) $val }
                "-y" { set Export(y) $val }
                "-lat" { set Export(lat) $val }
                "-long" { set Export(long) $val }
                "-zoom" { set Export(zoom) $val }
                "-scale" { set Export(scale) $val }
            }
        }
    }

    public method zoom {factor x y} {
        $Container configure -xscrollcommand "catch {unset [self namespace]::x}; lappend [self namespace]::x" -yscrollcommand "catch {unset [self namespace]::y}; lappend [self namespace]::y"
        
        $Container scale 1 $factor $factor
        $Container configure -scrollregion [$Container bbox all]
        set $Export(zoom) [$Container tget 1 "scale"]
        cursorupdate $x $y
        update

        lassign [$Container bbox all] x1 y1 x2 y2
        set width [expr {$x2 - $x1}]
        set height [expr {$y2 - $y1}]
        lassign [grid bbox $Map(frame)] _ _ w h
        if {$width > $w} { set width $w}
        if {$height > $h} { set height $h}
        $Container configure -width $width -height $height
        
        update
        puts [set [self namespace]::y]
        .c.map.vbar set {*}[set [self namespace]::y]
        .c.map.hbar set {*}[set [self namespace]::x]
        $Container configure -yscrollcommand ".c.map.vbar set" -xscrollcommand ".c.map.hbar set"
    }

    public method closeMap {} {
        set Map(filepath) ""
        $Dataset Delete
        set Dataset ""
        grid remove $Container
        $Container remove map ;# XXX map should not be hardcoded
    }
    
    public method openMap {filepath} {       
        if {! [file exists $filepath]} {
            tk_messageBox -icon error -message "File does not exist"
            return
        }

        if {! [file readable $filepath]} {
            tk_messageBox -icon error -message "Have no permissions to open file for reading"
            return
        }
        
        if {[::gdal::IdentifyDriver $filepath] eq ""} {
            tk_messageBox -icon error -message "Could not recognize file format"
            return
        }

        if {$Map(filepath) ne ""} { ;# An image is already open, close first
            closeMap
        }
        
        set Dataset [::gdal::Open $filepath $::gdal::GA_ReadOnly]
        if {$Dataset eq ""} {
            tk_messageBox -icon error -message "Could not open file"
            return
        }
        
        set Map(filepath) $filepath
        
        set w [$Dataset cget -RasterXSize]
        set h [$Dataset cget -RasterYSize]
        if {$w > [winfo screenwidth .]} {set w [winfo screenwidth .]}
        if {$h > [winfo screenheight .]} { set h [winfo screenheight .]}
        grid $Container
        $Container configure -width $w -height $h -scrollregion [list 0 0 $w $h]
        unset w h
        
        $Container add group 1 -tags map
        
        set layer 0
        set images [list]
        set bands [$Dataset cget -RasterCount]
        for {set bandNo 1} {$bandNo <= $bands} {incr bandNo} {
            set band [$Dataset GetRasterBand $bandNo]
            set colorinterp [::gdal::GetColorInterpretationName [$band GetRasterColorInterpretation]]
    
            switch -exact -- $colorinterp {
                "Gray" {
                    # Note: If the next band type is "Alpha", then alpha channel is used.
                    set img [renderGray]
                    incr layer
                }
                "Red" {
                    # Note: We assume that the next band types are "Green" and "Blue" and optionally "Alpha"
                    set img [renderRGB]
                    incr layer
                }
                "Alpha" {
                    puts stderr "Unexpected alpha channel."
                }
                "Hue" {
                    # Note: We assume that the next band types are "Saturation" and "Lightness" and optionally "Alpha"
                    set img [renderHSV]
                    incr layer
                }
                "Palette" {
                    #XXX
                }
                "Cyan" - "Magenta" - "Yellow" - "Black" -
                "YCbCr_Y" - "YCbCr_Cb" - "YCbCr_Cr" {
                    tk_messageBox -icon error -message "Could not recognize file format. \"$colorinterp\" band type not supported."
                    closeMap
                    break
                }
                default {
                    puts stderr "Could not recognize file format. Unrecognized image band type \"$colorinterp\"."
                }
            }

            $Container add icon 1 -image $img -tags band${layer}
            $Container chggroup band${layer} map
        } ;# for
    } ;# method
    
    public method renderGray {} {
        upvar bandNo bandno
        set band [$Dataset GetRasterBand $bandno]
        set gray [readColorBand $band]
        incr bandno
        
        ::NAP::nap "data = gray"
        
        if {[$Dataset cget -RasterCount] > $bandno} {
            set band [$Dataset GetRasterBand $bandno]
            if {[::gdal::GetColorInterpretationName [$band GetRasterColorInterpretation]] eq "Alpha"} {
                set alpha [readColorBand $band]
                ::NAP::nap "data = gray /// alpha"
                $alpha set count -1
                incr bandno
            }
        }
        $gray set count -1
        
        set img [image create photo -format NAO -data $data]

        return $img
    }
    
    public method renderRGB {} {
        upvar bandNo bandno
        set red [readColorBand [$Dataset GetRasterBand $bandno]]
        set green [readColorBand [$Dataset GetRasterBand [incr bandno]]]
        set blue [readColorBand [$Dataset GetRasterBand [incr bandno]]]
        incr bandno

        ::NAP::nap "data = red /// green // blue"
        
        if {[$Dataset cget -RasterCount] > $bandno} {
            set band [$Dataset GetRasterBand $bandno]
            if {[::gdal::GetColorInterpretationName [$band GetRasterColorInterpretation]] eq "Alpha"} {
                set alpha [readColorBand $band]
                ::NAP::nap "data = data // alpha"
                $alpha set count -1
                incr bandno
            }
        }
        $red set count -1
        $green set count -1
        $blue set count -1

        set img [image create photo -format NAO -data $data]
        
        return $img
    }

    public method renderHSV {} {
        upvar bandNo bandno
        set hue [readColorBand [$Dataset GetRasterBand $bandno]]
        set saturation [readColorBand [$Dataset GetRasterBand [incr bandno]]]
        set value [readColorBand [$Dataset GetRasterBand [incr bandno]]]
        incr bandno

        ::NAP::nap "data = hsv2rgb(hue /// saturation // value)"
        
        if {[$Dataset cget -RasterCount] > $bandno} {
            set band [$Dataset GetRasterBand $bandno]
            if {[::gdal::GetColorInterpretationName [$band GetRasterColorInterpretation]] eq "Alpha"} {
                set alpha [readColorBand $band]
                ::NAP::nap "data = data // alpha"
                $alpha set count -1
                incr bandno
            }
        }
        $hue set count -1
        $saturation set count -1
        $value set count -1

        set img [image create photo -format NAO -data $data]
        
        return $img
    }
    
    public method readColorBand {band} {
        set datatype [$band cget -DataType]
        set width [$band cget -XSize]
        set height [$band cget -YSize]
        set size [expr {$width*$height}]
            
        if {$datatype != $::gdal::GDT_Byte} {
            puts stderr "Warning: Reducing color depth"
        }
        
        set data [$band ReadRaster 0 0 $width $height $width $height $::gdal::GDT_Byte]
        binary scan $data cu* data
    
        # XXX use ReadRasterNAP
        set step $width
        ::NAP::nap "u = u8({})"
        for {set from 0; set to $step} {$from < $size} {incr from $step; incr to $step} {
            set chunk [lrange $data $from $to-1]
            ::NAP::nap "u = u // u8({$chunk})"
        }
            
        #::NAP::nap "u = magnify_interp(reshape(u, {$height $width}), $zoom)" ;# XXX zoom
        ::NAP::nap "u = reshape(u, {$height $width})"
        
        $u set count +1
        return $u
    }
} ;# class
