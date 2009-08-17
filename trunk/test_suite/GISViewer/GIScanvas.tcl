package require Tcl 8.5
package require Tk 8.5
package require Tkzinc 3.3
package require gdal 1.0
package require gdalconst 1.0
package require nap 6.4
package require toe 1.0

# Initialize GDAL/OGR
::osgeo::AllRegister

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
    
    public:
#    method xview {args} { $Container xview {*}$args }
#    method yview {args} { puts $args; $Container yview {*}$args }
    method xview {cmd args} {
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
    
    method yview {cmd args} {
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
    
    method configure {args} {
        foreach {var val} $args {
            switch -exact -- $var {
                "-xscrollcommand" -
                "-yscrollcommand" {
                    $Container configure $var $val
                }
            }
        }
    }

    method cget {args} {
        foreach {var val} $args {
            switch -exact -- $var {
                "-filetypes" {
                    set formats [list]
                    for {set i 0} {$i < [::osgeo::GetDriverCount]} {incr i} {
                        set driver [::osgeo::GetDriver $i]
                        set ext [list]
                        foreach a [$driver GetMetadataItem DMD_EXTENSION] {
                            lappend ext "*.$a"
                        }
                        lappend formats [list "All files" "*"] [list [$driver GetMetadataItem DMD_LONGNAME] $ext]
                    }
                    return $formats
                }
            }
        }
    }
    
    method monitor {args} {
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

    method zoom {factor x y} {
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
    
    method openGIS {filepath} {
        set Map(filepath) $filepath
        
        if {! [file exists $filepath]} {
            tk_messageBox -icon error -message "File does not exist"
            return
        }

        if {! [file readable $filepath]} {
            tk_messageBox -icon error -message "Have no permissions to open file for reading"
            return
        }
        
        if {[::osgeo::IdentifyDriver $filepath] eq ""} {
            tk_messageBox -icon error -message "Could not recognize file format"
            return
        }
        
        set Dataset [::osgeo::Open $filepath $::osgeo::GA_ReadOnly]
        if {$Dataset eq ""} {
            tk_messageBox -icon error -message "Could not open file"
            return
        }
        
        set w [$Dataset cget -RasterXSize]
        set h [$Dataset cget -RasterYSize]
        if {$w > [winfo screenwidth .]} {set w [winfo screenwidth .]}
        if {$h > [winfo screenheight .]} { set h [winfo screenheight .]}
        grid $Container
        $Container configure -width $w -height $h -scrollregion [list 0 0 $w $h]
        unset w h
        
        $Container add group 1 -tags map
        
        set bands [$Dataset cget -RasterCount]
        for {set b 1} {$b <= $bands} {incr b} {
            set band [$Dataset GetRasterBand $b]
            set width [$band cget -XSize]
            set height [$band cget -YSize]
            set size [expr {$width*$height}]
            set datatype [$band cget -DataType]
            set block [$band GetBlockSize]
            set colorinterp [$band GetRasterColorInterpretation]
            set noval [$band GetNoDataValue]
    
            if {$colorinterp == $::osgeo::GCI_GrayIndex} { ;# Grayscale
                
            } elseif {$colorinterp == $::osgeo::GCI_AlphaBand} {
                foreach xy [lsearch -exact -all [concat [$u value]] $noval] {
                    set y [expr {int($xy / $new_width)}]
                    set x [expr {int($xy % $new_width)}]
                    $img transparency set $x $y 0
                }
    
                $Container itemconfigure map -alpha ZZZ
            } elseif {$colorinterp == $::osgeo::GCI_RedBand} { ;#RGB
                
            } elseif {$colorinterp == $::osgeo::GCI_GreenBand} { ;#RGB
                
            } elseif {$colorinterp == $::osgeo::GCI_BlueBand} { ;#RGB
            
            } elseif {$colorinterp == $::osgeo::GCI_HueBand} { ;# HSL
                
            } elseif {$colorinterp == $::osgeo::GCI_SaturationBand} { ;# HSL
                
            } elseif {$colorinterp == $::osgeo::GCI_LightnessBand} { ;# HSL
                
            } elseif {$colorinterp == $::osgeo::GCI_PaletteIndex} {
                
            } elseif {$colorinterp == $::osgeo::GCI_CyanBand ||
                      $colorinterp == $::osgeo::GCI_MagentaBand ||
                      $colorinterp == $::osgeo::GCI_YellowBand ||
                      $colorinterp == $::osgeo::GCI_BlackBand} { ;# CMYK
                tk_messageBox -icon error -message "Could not recognize file format. CMYK band type not supported."
                return
            } elseif {$colorinterp == $::osgeo::GCI_YCbCr_YBand} { ;# Y Luminance
                tk_messageBox -icon error -message "Could not recognize file format. YCbCr_Y band type not supported."
                return
            } elseif {$colorinterp == $::osgeo::GCI_YCbCr_CbBand} { ;# Cb Chroma
                tk_messageBox -icon error -message "Could not recognize file format. YCbCr_Cb band type not supported."
                return
            } elseif {$colorinterp == $::osgeo::GCI_YCbCr_CrBand} { ;# Cr Chroma
                tk_messageBox -icon error -message "Could not recognize file format. YCbCr_Cr band type not supported."
                return
            } elseif {$colorinterp == $::osgeo::GCI_Max} { ;# Max current value
                tk_messageBox -icon error -message "Could not recognize file format. Max band type not supported."
                return
            } else {
                tk_messageBox -icon error -message "Could not recognize file format. Unrecognized image band type."
                return
            }
    
            if {$datatype != $::osgeo::GDT_Byte} {
                puts stderr "Warning: Reducing color depth"
            }
            
            set data [$band ReadRasterNAP 0 0 $width $height $width $height $::osgeo::GDT_Byte]
            binary scan $data cu* data
        
            set step $width
            ::NAP::nap "u = u8({})"
            for {set from 0; set to $step} {$from < $size} {incr from $step; incr to $step} {
                set chunk [lrange $data $from $to-1]
                ::NAP::nap "u = u // u8({$chunk})"
            }
            unset data
                
            #::NAP::nap "u = magnify_interp(reshape(u, {$height $width}), $zoom)" ;# XXX zoom
            ::NAP::nap "u = reshape(u, {$height $width})"
            set img [image create photo -format NAO -data $u]
            
            lassign [[::NAP::nap "shape(u)"]] new_height new_width
            set size [[::NAP::nap "nels(u)"]]
            
            if {[string is integer $noval]} {
                foreach xy [lsearch -exact -all [concat [$u value]] $noval] {
                    set y [expr {int($xy / $new_width)}]
                    set x [expr {int($xy % $new_width)}]
                    $img transparency set $x $y 0
                }
            }
            unset u ;# cleans-up memory
            
            $Container add icon 1 -image $img -tags band${b}
            $Container chggroup band${b} map
        }
    }
}
