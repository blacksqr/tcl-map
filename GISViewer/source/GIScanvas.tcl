#
# TODO: Search for TODO.
#       Raster: Consider GetMaximum/GetMinimum for each band.
#       Raster: Consider GetNoValue for each band.
#       Raster: Understand and render band types: "Cyan" - "Magenta" - "Yellow" - "Black" - "YCbCr_Y" - "YCbCr_Cb" - "YCbCr_Cr"
#       Raster: Understand and visualize bands that embody information such as height.
#               Units value (e.g. elevation as described in GetDescription in units of GetUnitType and resolution of GetDatatype) = (raw pixel value * GetScale) + GetOffset
#       

package require Tcl 8.5
package require Tk 8.5
package require Tkzinc 3.3
package require nap 6.4
package require toe 1.0
package require gdalconst 1.0
package require gdal 1.0
package require ogr 1.0
package require osr 1.0

namespace import ::toe::class

source [file join $VRootDir GetProjections.tcl]

# Initialize GDAL/OGR
::gdal::AllRegister
::ogr::RegisterAll

class GIScanvas {
    private variable Container
    private variable Dataset
    private variable Win ;# Array with info that pertain the frame given to GIScanvas
    private variable Export ;# Array with names of external variables to export internal information to.
    private variable Map ;# Array with Map info.

    method constructor {frame} {
        array set Export {x "" y "" lat "" long "" altitude "" projx "" projy "" zoom "" scale ""}
        array set Map {loaded false filepath "" type "" zoomfactor 0.05 projection "" geographic "" proj2geo "" geo2proj ""}
        set Win(frame) $frame
        
        grid columnconfigure $frame 0 -weight 1; grid rowconfigure $frame 0 -weight 1
        grid [ttk::frame $frame.f -borderwidth 2] -sticky nwes
        grid columnconfigure $frame.f 0 -weight 1; grid rowconfigure $frame.f 0 -weight 1
        
        image create photo [self namespace]::tile -data \
{R0lGODlhCgAKAIABANnZ2f///yH+EUNyZWF0ZWQgd2l0aCBHSU1QACwAAAAACgAKAAACEYQdmYca
DNxjEspKndVZbc8UADs=}

        set Container [zinc $frame.f.canvas \
                        -backcolor white \
                        -tile [self namespace]::tile \
                        -borderwidth 0 \
                        -cursor cross \
                        -overlapmanager 1 \
                        -confine 1 \
                        -takefocus 0 \
                        -relief flat \
                        -xscrollincrement 0 \
                        -yscrollincrement 0 \
                        -render 1]
        winupdate

        bind $Container <Button-4> "[self namespace]::zoom relative [expr {1.0 + $Map(zoomfactor)}] %x %y"
        bind $Container <Button-5> "[self namespace]::zoom relative [expr {1.0 - $Map(zoomfactor)}] %x %y"
        bind $Container <Motion> "[self namespace]::cursorupdate %x %y"
        bind $Container <Configure> "[self namespace]::winupdate"
    }
    
    public method zoomfactor {{val ""}} { if {$val eq ""} { return $Map(zoomfactor) } else { set $Map(zoomfactor) $val } }

    public method convert_xy2proj {x y} {
        if {$Map(projected) ne ""} {
            if {$Map(type) eq "Raster"} {
                lassign [lindex [$Dataset GetGeoTransform] 0] x_start x_resol x_rot y_start y_rot y_resol
                set projx [expr {$x_start + $x * $x_resol + $y * $x_rot}]
                set projy [expr {$y_start + $x * $y_rot + $y * $y_resol}]
                
                # Shift to the center of the pixel
                set projx [expr {$projx + $x_resol / 2.0}]
                set projy [expr {$projy + $y_resol / 2.0}]
                
                return [list $projx $projy]
            } elseif {$Map(type) eq "Vector"} {
                return [list 0 0] ;# XXX
            }
        }
        
        return [list 0 0]
    }

    public method convert_proj2geo {x y} {
        if {$Map(proj2geo) ne ""} {
            return [lindex [$Map(proj2geo) TransformPoint $x $y] 0]
        }
            
        return [list 0 0]
    }
    
    public method convert_geo2proj {x y} {
        if {$Map(geo2proj) ne ""} {
            return [lindex [$Map(geo2proj) TransformPoint $x $y] 0]
        }
            
        return [list 0 0]
    }
    
    method cursorupdate {x y} {
        lassign [$Container transform root [list $x $y]] x y
        lassign [list $x $y] $Export(x) $Export(y)
        lassign [convert_xy2proj $x $y] projx projy
        lassign [list $projx $projy] $Export(projx) $Export(projy)
        lassign [convert_proj2geo $projx $projy] $Export(long) $Export(lat) $Export(altitude)
    }
    
    method winupdate {} {
        lassign [grid bbox $Win(frame)] _ _ w h
        $Container configure -width $w -height $h
    }
    
    public method zoom {type {factor 1.0} {x ""} {y ""}} {
        $Container configure \
                -xscrollcommand "catch {unset [self namespace]::tempx}; lappend [self namespace]::tempx" \
                -yscrollcommand "catch {unset [self namespace]::tempy}; lappend [self namespace]::tempy"
        
        switch -exact -- $type {
            "relative" {
                $Container scale root $factor $factor
            }
            "absolute" {
                # TODO: Instead of reseting first, extend tkzinc to support an 'absolute' option like "transform"
                $Container itemconfigure root -visible 0
                update
                $Container treset root
                $Container scale root $factor $factor
                $Container itemconfigure root -visible 1
                update
            }
            "best" {
                zoom absolute 1.0
                lassign [$Container bbox all] x1 y1 x2 y2
                set width [expr {$x2 - $x1}]
                set height [expr {$y2 - $y1}]
                lassign [grid bbox $Win(frame)] _ _ w h
                if {[expr {double($width) / $height}] > 1} {
                    set factor [expr {double($w) / $width}]
                } else {
                    set factor [expr {double($h) / $height}]
                }
                
                # TODO: Instead of reseting first, extend tkzinc to support an 'absolute' option like "transform"
                $Container itemconfigure root -visible 0
                update
                $Container treset root
                $Container scale root $factor $factor
                $Container itemconfigure root -visible 1
                update
            }
            default {error}
        }
        
        $Container configure -scrollregion [$Container bbox all]
        set factor [lindex [$Container tget root "scale"] 0]
        set $Export(zoom) [expr {100 * $factor}]
        set $Export(scale) "XXX"
        if {$x ne ""} { cursorupdate $x $y }
        
        update
        .c.map.vbar set {*}[set [self namespace]::tempy]
        .c.map.hbar set {*}[set [self namespace]::tempx]
        $Container configure -yscrollcommand ".c.map.vbar set" -xscrollcommand ".c.map.hbar set"
        
        # Center map
        lassign [$Container tget root "translation"] shiftX shiftY
        lassign [$Container bbox all] x1 y1 x2 y2
        set mapwidth [expr {$x2 - $x1}]
        set mapheight [expr {$y2 - $y1}]
        lassign [grid bbox $Win(frame)] _ _ winwidth winheight
        
        if {$mapwidth < $winwidth} {
            #set shiftX [expr {($winwidth - $mapwidth) / 2.0}]
            set shiftX 0
        }
        if {$mapheight < $winheight} {
            #set shiftY [expr {($winheight - $mapheight) / 2.0}]
            set shiftY 0
        }
        
        $Container translate root $shiftX $shiftY yes
        
        #$Container xview moveto 0
        #$Container yview moveto 0
    }
    
    public method xview {cmd args} {
        lassign [$Container bbox all] x1 y1 x2 y2
        set mapwidth [expr {$x2 - $x1}]
        lassign [grid bbox $Win(frame)] _ _ winwidth winheight
        lassign [$Container tget root "translation"] shiftX shiftY
        
        switch -exact -- $cmd {
            "moveto" {
                set val $args
                set val2 [expr {double($winwidth) / $mapwidth}]
                
                if {$val < 0} {set val 0}
                if {$val > 1 - $val2} {set val [expr {1-$val2}]}
                $Container translate root [expr {$val * $mapwidth * -1}] $shiftY yes
                
                {*}[$Container cget -xscrollcommand] $val [expr {$val + $val2}]
            }
            "scroll" {
                lassign $args val type
                if {$type eq "pages"} {
                    set val [expr {$val * $winwidth}]
                }
                
                set max [expr {$mapwidth - $winwidth}]
                if {$max < 0} {return} ;# Map is small enough to be displayed in whole; no need of scrolling
                
                set val [expr {$shiftX - $val}]
                if {$val > 0} { set val 0} ;# On the left edge; cannot scroll further
                
                if {[expr {abs($val)}] > $max} {
                    set val [expr {$max * -1}] ;# On the right edge; cannot scroll further
                }
                
                # Move map
                $Container translate root $val $shiftY yes
                
                # Update scrollbars
                set val2 [expr {double(abs($val)) / $mapwidth}]
                {*}[$Container cget -xscrollcommand] $val2 [expr {$val2 + $winwidth / $mapwidth}]
            }
            default {error}
        }
    }
    
    public method yview {cmd args} {
        lassign [$Container bbox all] x1 y1 x2 y2
        set mapheight [expr {$y2 - $y1}]
        lassign [grid bbox $Win(frame)] _ _ winwidth winheight
        lassign [$Container tget root "translation"] shiftX shiftY
        
        switch -exact -- $cmd {
            "moveto" {
                set val $args
                set val2 [expr {double($winheight) / $mapheight}]
                
                if {$val < 0} {set val 0}
                if {$val > 1 - $val2} {set val [expr {1-$val2}]}
                $Container translate root $shiftX [expr {$val * $mapheight * -1}] yes
                
                {*}[$Container cget -yscrollcommand] $val [expr {$val + $val2}]
            }
            "scroll" {
                lassign $args val type
                if {$type eq "pages"} {
                    set val [expr {$val * $winheight}]
                }
                
                set max [expr {$mapheight - $winheight}]
                if {$max < 0} {return} ;# Map is small enough to be displayed in whole; no need of scrolling
                
                set val [expr {$shiftY - $val}]
                if {$val > 0} { set val 0} ;# On the top edge; cannot scroll further
                
                if {[expr {abs($val)}] > $max} {
                    set val [expr {$max * -1}] ;# On the bottom edge; cannot scroll further
                }
                
                # Move map
                $Container translate root $shiftX $val yes
                
                # Update scrollbars
                set val2 [expr {double(abs($val)) / $mapheight}]
                {*}[$Container cget -yscrollcommand] $val2 [expr {$val2 + $winheight / $mapheight}]
            }
            default {error}
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
                "-rasterfiletypes" {
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
                            set ext "*"
                        }
                        lappend formats [list [$driver GetMetadataItem DMD_LONGNAME] $ext]
                    }
                    return $formats
                }
                "-vectorfiletypes" {
                    set formats [list]
                    set vector_exts [list]
                    for {set i 0} {$i < [::ogr::GetDriverCount]} {incr i} {
                        set driver [::ogr::GetDriver $i]
                        #XXX
                        lappend formats [list [$driver cget -name] *]
                    }
                    return $formats
                }
                default {error}
            }
        }
    }
    
    public method monitor {args} {
        foreach {var val} $args {
            switch -exact -- $var {
                "-x" { set Export(x) $val }
                "-y" { set Export(y) $val }
                "-projx" { set Export(projx) $val }
                "-projy" { set Export(projy) $val }
                "-lat" { set Export(lat) $val }
                "-long" { set Export(long) $val }
                "-altitude" { set Export(altitude) $val }
                "-zoom" { set Export(zoom) $val }
                "-scale" { set Export(scale) $val }
                default {error}
            }
        }
    }

    public method closeMap {} {
        grid remove $Container
        set Map(loaded) false
        $Dataset -delete
        $Map(projected) -delete
        $Map(geographic) -delete
        $Map(proj2geo) -delete
        $Map(geo2proj) -delete
        $Container remove root
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

        if {$Map(loaded)} {
            closeMap
        }
        
        # Check to see if it's raster..
        if {[::gdal::IdentifyDriver $filepath] ne "NULL"} {
            return [openRaster $filepath]
        }
        
        # Check to see if it's vector..
        set ret [::ogr::Open $filepath 0]
        if {$ret ne "NULL"} {
            $ret -delete
            return [openVector $filepath]
        }
        
        # Neither raster nor vector
        tk_messageBox -icon error -message "Could not recognize file format"
    }
    
    public method openVector {filepath} {
        set Dataset [::ogr::Open $filepath 0] ;# 0 for readonly
        
        # NOTE: We take the projection of the first layer as the projection of the whole dataset XXX
        set proj [[$Dataset GetLayerByIndex 0] GetSpatialRef]
        set projProj4 ""
        set geoProj4 ""
        if {$proj ne "NULL"} {
            if {[$proj IsProjected]} {
                set projProj4 [$proj ExportToProj4]
                set temp [$proj CloneGeogCS]
                set geoProj4 [$temp ExportToProj4]
                $temp -delete
            } elseif {[$proj IsGeographic]} {
                set geoProj4 [$proj ExportToProj4]
                set projProj4 ""
            } else {error}
            $proj -delete
        }

        if {[catch {
            lassign [GetProjectionsUI [lindex $geoProj4 0] [lindex $projProj4 0]] Map(geographic) Map(projected)
        }]} {
            $Dataset -delete
            return
        }
        
        # There are a couple of points at which transformations can fail.
        # First, OGRCreateCoordinateTransformation() may fail, generally
        # because the internals recognise that no transformation between
        # the indicated systems can be established. This might be due to
        # use of a projection not supported by the internal PROJ.4 library,
        # differing datums for which no relationship is known, or one of
        # the coordinate systems being inadequately defined. If
        # OGRCreateCoordinateTransformation() fails it will return a NULL.
        set Map(proj2geo) [::osr::new_CoordinateTransformation $Map(projected) $Map(geographic)]
        set Map(geo2proj) [::osr::new_CoordinateTransformation $Map(geographic) $Map(projected)]
        if {$Map(proj2geo) eq "NULL" || $Map(geo2proj) eq "NULL"} {
            catch {$Map(projected) -delete}
            catch {$Map(geographic) -delete}
            tk_messageBox -icon error -message "Failed to establish a mapping between geographic and map projections"
            return
        }

        set Map(loaded) true
        set Map(type) "Vector"
        set Map(filepath) $filepath

        # XXX
        $Container add group 1 -tags root
        $Container add group root -tags trans1
        $Container add group trans1 -tags trans2
        $Container add group trans2 -tags trans3
        $Container add group trans3 -tags map
        grid $Container
        
        for {set l 0} {$l < [$Dataset GetLayerCount]} {incr l} {
            set layer [$Dataset GetLayerByIndex $l]
            $layer ResetReading
            
            while {[set feature [$layer GetNextFeature]] ne "NULL"} {
                set geometry [$feature GetGeometryRef]
                if {$geometry eq ""} { continue }

                #set sref [$geometry GetSpatialReference]
                #if {! [$sref IsSame $Map(geographic)]} {
                #    puts stderr "XXX"
                #}
                #$sref -delete
                
                if {[catch {
                    $geometry Transform $Map(geo2proj)
                } errstr errtrace]} { ;# Will assign $sref to $geometry
                    # The Transform method itself can also fail. This may be as a delayed
                    # result of one of the above problems, or as a result of an operation
                    # being numerically undefined for one or more of the passed in points.
                    puts "Transformation failed:$errstr"
                    #XXX
                }
                
                set geotype [$geometry GetGeometryType]
                
                if {$geotype eq "$::ogr::wkb25Bit"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbGeometryCollection"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbGeometryCollection25D"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbLineString"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbLineString25D"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbLinearRing"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbPoint"} {
                    
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbPoint25D"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbPolygon"} {
                    set data [$geometry ExportToWkb]
                    binary scan $data cuIuIu byte_order geometry_type ring_count
                    set shift 9
                    for {set r 0} {$r < $ring_count} {incr r} {
                        binary scan $data x${shift}Iu no_of_points
                        incr shift 4
                        binary scan $data x${shift}Q[expr {$no_of_points * 2}] points
                        incr shift [expr {$no_of_points * 16}] ;# 16 = dimention * sizeof(double) = 2 * 8
                        
                        $Container add curve map $points -filled true -linecolor black -fillcolor gray -tags feature
                    }
                } elseif {$geotype eq "$::ogr::wkbPolygon25D"} {
                    # TODO Not tested
                    set data [$geometry ExportToWkb]
                    binary scan $data cuIuIu byte_order geometry_type ring_count
                    set shift 9
                    for {set r 0} {$r < $ring_count} {incr r} {
                        binary scan $data x${shift}Iu no_of_points
                        incr shift 4
                        binary scan $data x${shift}Q[expr {$no_of_points * 3}] points
                        incr shift [expr {$no_of_points * 24}] ;# 16 = dimention * sizeof(double) = 3 * 8
                        
                        set xypoints [list]
                        foreach {x y z} $points {
                            lappend xypoints $x $y
                        }
                        $Container add curve map $xypoints -linecolor blue -linewidth 1 -filled true -fillcolor red -tags feature
                    }
                } elseif {$geotype eq "$::ogr::wkbMultiLineString"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbMultiLineString25D"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbMultiPoint"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbMultiPoint25D"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbMultiPolygon"} {
                    set data [$geometry ExportToWkb]
                    binary scan $data cuIuIu byte_order geometry_type geom_count
                    
                    set shift 9
                    for {set g 0} {$g < $geom_count} {incr g} {
                        binary scan $data x${shift}cuIuIu byte_order geometry_type ring_count
                        incr shift 9
                        for {set r 0} {$r < $ring_count} {incr r} {
                            binary scan $data x${shift}Iu no_of_points
                            incr shift 4
                            binary scan $data x${shift}Q[expr {$no_of_points * 2}] points
                            incr shift [expr {$no_of_points * 16}] ;# 16 = dimention * sizeof(double) = 2 * 8

                            $Container add curve map $points -filled true -fillcolor blue -tags feature
                        }
                    }
                } elseif {$geotype eq "$::ogr::wkbMultiPolygon25D"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbNDR"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbXDR"} {
                    ZZZ
                } elseif {$geotype eq "$::ogr::wkbNone"} {
                    # no visual representation, just for attribute collection
                } elseif {$geotype eq "$::ogr::wkbUnknown"} {
                    puts stderr "Unknown geometry type"                        
                } else {
                    puts stderr "Unexpected geometry type"                        
                }
                $feature -delete
            } ;# while
        } ;# for

        puts orig:[$Container bbox map]

        lassign [$Container bbox map] x1 y1 x2 y2
        set width [expr {$x2 - $x1}]
        set height [expr {$y2 - $y1}]        
        $Container translate trans2 [expr {$x1 * -1}] [expr {$y1 * -1}] yes
        puts shift:[$Container bbox map]
        
        $Container scale trans2 0.001 0.001
        puts zoom:[$Container bbox map]

        $Container scale trans3 1.0 -1.0
        puts mirror:[$Container bbox map]

        lassign [$Container bbox map] x1 y1 x2 y2
        $Container translate trans1 [expr {$x1 * -1}] [expr {$y1 * -1}] yes
        puts shift:[$Container bbox map]
        
        puts [$Container transform map {0 0}]
        
        
    } ;# method
    
    public method GetProjectionsUI {geoProj4 projProj4} {    
        lassign [GetProjections_ui::GetProjections_ui $geoProj4 $projProj4] geoProj4 projProj4
        
        set projected [::osr::new_SpatialReference]
        if {[catch {
            $projected ImportFromProj4 $projProj4
        } errstr errtrace]} {
            $projected -delete
            tk_messageBox -icon error -message "Invalid Proj4 input for map projection"
            error
        }
        if {! [$projected IsProjected]} {
            $projected -delete
            tk_messageBox -icon error -message "Inadequate information for map projection"
            error                
        }
        set geographic [::osr::new_SpatialReference]
        if {[catch {
            $geographic ImportFromProj4 $geoProj4
        } errstr errtrace]} {
            $geographic -delete
            tk_messageBox -icon error -message "Invalid Proj4 input for geographic projection"
            error
        }
        if {! [$geographic IsGeographic]} {
            $geographic -delete
            set geographic [$geographic CloneGeogCS]
        }
        
        return [list $geographic $projected]
    }
            
    public method openRaster {filepath} {       
        set Dataset [::gdal::Open $filepath $::gdal::GA_ReadOnly]
        if {$Dataset eq ""} {
            tk_messageBox -icon error -message "Could not open file"
            return
        }
        
        set OpenGISWKT [$Dataset GetProjectionRef]
        set projProj4 ""
        set geoProj4 ""
        if {$OpenGISWKT ne ""} {
            set proj [::osr::new_SpatialReference]
            $proj ImportFromWkt $OpenGISWKT
            
            if {[$proj IsProjected]} {
                set projProj4 [$proj ExportToProj4]
                set temp [$proj CloneGeogCS]
                set geoProj4 [$temp ExportToProj4]
                $temp -delete
            } elseif {[$proj IsGeographic]} {
                set geoProj4 [$proj ExportToProj4]
                set projProj4 ""
            } else {error}
            $proj -delete
        }
        unset OpenGISWKT
        
        if {[catch {
            lassign [GetProjectionsUI [lindex $geoProj4 0] [lindex $projProj4 0]] Map(geographic) Map(projected)
        }]} {
            $Dataset -delete
            return
        }
        
        # There are a couple of points at which transformations can fail.
        # First, OGRCreateCoordinateTransformation() may fail, generally
        # because the internals recognise that no transformation between
        # the indicated systems can be established. This might be due to
        # use of a projection not supported by the internal PROJ.4 library,
        # differing datums for which no relationship is known, or one of
        # the coordinate systems being inadequately defined. If
        # OGRCreateCoordinateTransformation() fails it will return a NULL.
        set Map(proj2geo) [::osr::new_CoordinateTransformation $Map(projected) $Map(geographic)]
        set Map(geo2proj) [::osr::new_CoordinateTransformation $Map(geographic) $Map(projected)]
        if {$Map(proj2geo) eq "NULL" || $Map(geo2proj) eq "NULL"} {
            catch {$Map(projected) -delete}
            catch {$Map(geographic) -delete}
            tk_messageBox -icon error -message "Failed to establish a mapping between geographic and map projections"
            return
        }
        
        set Map(loaded) true
        set Map(type) "Raster"
        set Map(filepath) $filepath
        
        $Container add group 1 -tags root
        $Container add group root -tags map
        grid $Container
        
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
                    ZZZ 
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

            $Container add icon map -image $img -tags band${layer}
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
    
        # TODO: Create and use ReadRasterNAP to avoid unnecessary memory copying
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
