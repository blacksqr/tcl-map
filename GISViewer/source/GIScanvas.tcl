#
# TODO: Search for TODO.
#       Raster: Consider GetMaximum/GetMinimum for each band.
#       Raster: Consider GetNoValue for each band.
#       Raster: Understand and render band types: "Cyan" - "Magenta" - "Yellow" - "Black" - "YCbCr_Y" - "YCbCr_Cb" - "YCbCr_Cr"
#       Raster: Understand and visualize bands that embody information such as height.
#               Units value (e.g. elevation as described in GetDescription in units of GetUnitType and resolution of GetDatatype) = (raw pixel value * GetScale) + GetOffset
#       Keep map centered on the dimentions that fit in the screen.

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
#source [file join $VRootDir progress.tcl]

# Initialize GDAL/OGR
::gdal::AllRegister
::ogr::RegisterAll

class GIScanvas {
    private variable Container ;# The zinc canvas.
    private variable Dataset   ;# The GDAL/OGR dataset.
    private variable Win       ;# Array with info that pertain the GIScanvas as a whole, as well as the frames and other widgets sourounding it..
    private variable Export    ;# Array with names of external variables to export internal information to.
    private variable Map       ;# Array with Map info.
    private variable Cursor    ;# Array with info about the position of the cursor.

    method constructor {frame} {
        array set Export {x "" y "" lat "" long "" altitude "" projx "" projy "" zoom "" scale ""}
        array set Cursor {x "" y "" lat "" long "" altitude "" projx "" projy ""}
        array set Map {loaded false filepath "" type "" zoomfactor 0.05 zoom "" scale "" projection "" geographic "" proj2geo "" geo2proj "" width 0 height 0}
        array set Win {frame "" width 0 height 0}
        set Win(frame) $frame
        
        grid columnconfigure $frame 0 -weight 1; grid rowconfigure $frame 0 -weight 1
        grid [ttk::frame $frame.f -borderwidth 2] -sticky nwes
        grid columnconfigure $frame.f 0 -weight 1; grid rowconfigure $frame.f 0 -weight 1
        update ;# To be able to read width & height
        
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
                        -width 1 -height 1 \
                        -render 1]
        
        $Container add group 1 -tags root
        $Container add group root -tags scaleLayer
        $Container add group scaleLayer -tags shiftLayer
        $Container add group shiftLayer -tags map
        
        winupdate
        bind $Win(frame) <Configure> "[self namespace]::winupdate"

        # NOTE: The following bindings will take effect only when Container is mapped by grid.
        bind $Container <Button-4> "[self namespace]::zoomin %x %y"
        bind $Container <Button-5> "[self namespace]::zoomout %x %y"
        bind $Container <Motion> "[self namespace]::motion %x %y"
    }
    
    private method motion {x y} {
        if {$Map(type) eq "Raster"} {
            lassign [$Container transform map [list $x $y]] Cursor(x) Cursor(y)
            lassign [convert_xy2proj $Cursor(x) $Cursor(y)] Cursor(projx) Cursor(projy)
        } else {
            # XXX y coord need to * -1
            lassign [$Container transform root [list $x $y]] Cursor(x) Cursor(y)
            lassign [convert_xy2proj $x $y] Cursor(projx) Cursor(projy)
        }
        
        lassign [convert_proj2geo $Cursor(projx) $Cursor(projy)] Cursor(long) Cursor(lat) Cursor(altitude)
    }
    
    private method winupdate {} {
        lassign [grid bbox $Win(frame)] _ _ Win(width) Win(height)
        $Container configure -width $Win(width) -height $Win(height)
        update
    }

    public method xview {args} {
        $Container xview {*}$args
    }

    public method yview {args} {
        $Container yview {*}$args
    }
    
    public method configure {args} {
        foreach {var val} $args {
            switch -exact -- $var {
                "-xscrollcommand" -
                "-yscrollcommand" {
                    $Container configure $var $val
                }
                "-visible" {
                    if {$val} {
                        grid $Container
                    } else {
                        grid remove $Container
                    }
                }
            }
        }
        update
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
                        puts stderr "No specific file extension specified by OGR for [$driver cget -name]"
                        # TODO: OGR Doesn't provide a long name for the dirver, neither a file extension. Find a workaround.
                        lappend formats [list [$driver cget -name] *]
                    }
                    return $formats
                }
                default {error "Internal error"}
            }
        }
    }
    
    ### Exportation of internal info ###
    
    public method monitor {args} {
        foreach {var val} $args {
            switch -exact -- $var {
                "-x" -
                "-y" -
                "-projx" -
                "-projy" -
                "-lat" -
                "-long" -
                "-altitude" {
                    set el [string range $var 1 end]
                    set Export($el) $val
                    trace var Cursor($el) wu "[self namespace]::export"
                }
                "-zoom" -
                "-scale" {
                    set el [string range $var 1 end]
                    set Export($el) $val
                    trace var Map($el) wu "[self namespace]::export"
                }
                default {error "Internal error"}
            }
        }
    }
    
    private method export {arr el op} {
        set $Export($el) [set ${arr}($el)]
    }
    
    ### Zoom functions ###
    
    public method zoomfactor {{val ""}} {
        if {$val eq ""} { return $Map(zoomfactor) } else { set $Map(zoomfactor) $val }
    }
    
    public method zoomin {{x ""} {y ""}} {
        zoom relative [expr {1.0 + $Map(zoomfactor)}] $x $y
    }
    
    public method zoomout {{x ""} {y ""}} {
        zoom relative [expr {1.0 - $Map(zoomfactor)}] $x $y
    }
    
    public method zoom {type {factor 1.0} {x ""} {y ""}} {
        # Hard-absolute constraints.
        if {$factor <= 0.0 || $factor >= 100.0} { return }
        
        # The real display size.
        lassign [$Container bbox all] x1 y1 x2 y2
        set width [expr {$x2 - $x1}]
        set height [expr {$y2 - $y1}]
        
        # Soft-Relative constraints.
        if {$width <= 10 && $factor < 1.0} { return }
        if {$Map(zoom) > 100 && $factor > 1.0} { return }
        
        switch -exact -- $type {
            "relative" {
                $Container scale scaleLayer $factor $factor
            }
            "absolute" {
                # Compute correction factor in order to bring it to the original size, combined with provided factor.
                set factor [expr {$Map(width) / double($width) * $factor}]
                
                $Container scale scaleLayer $factor $factor
            }
            "best" {
                # Compute correction factor in order to bring it to the original size.
                set factor [expr {$Map(width) / double($width)}]

                # Now combine the zoom factor needed to fill in the screen.
                if {$Win(width) / $Map(width) < $Win(height) / $Map(height)} {
                    set factor [expr {$factor * $Win(width) / $Map(width)}] ;# fill in screen width-wise
                } else { ;# fill in screen height-wise
                    set factor [expr {$factor * $Win(height) / $Map(height)}] ;# fill in screen height-wise
                }
                
                $Container scale scaleLayer $factor $factor
            }
            default {error "Internal error"}
        }

        $Container configure -scrollregion [$Container bbox all]
        set factor [lindex [$Container tget scaleLayer "scale"] 0]
        set Map(zoom) $factor
        
        # if zooming is with the mouse wheel, then relative cursor position has changed. Update..
        if {$x ne ""} { motion $x $y }
    }
    
    ### Geo coordinate transformations ###
    
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
                return [$Container transform "map" [list $x $y]]
            }
        }
        
        return [list "" ""]
    }

    public method convert_proj2geo {x y} {
        if {$Map(proj2geo) ne ""} {
            return [lindex [$Map(proj2geo) TransformPoint $x $y] 0]
        }
        
        return [list "" ""]
    }
    
    public method convert_geo2proj {x y} {
        if {$Map(geo2proj) ne ""} {
            return [lindex [$Map(geo2proj) TransformPoint $x $y] 0]
        }
        
        return [list "" ""]
    }

    method destructor {} {
        grid remove $Container
        set Map(loaded) false
        $Dataset -delete
        $Map(projected) -delete
        $Map(geographic) -delete
        $Map(proj2geo) -delete
        $Map(geo2proj) -delete
    }
    
    public method closeMap {} {
        grid remove $Container
        set Map(loaded) false
        $Dataset -delete
        $Map(projected) -delete
        $Map(geographic) -delete
        $Map(proj2geo) -delete
        $Map(geo2proj) -delete
        
        # XXX Proper clean-up code.
    }
    
    public method openMap {filepath} {       
        if {! [file exists $filepath]} {
            error "File does not exist"
        }

        if {! [file readable $filepath]} {
            error "Have no permissions to open file for reading"
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
        error "Unrecognized file format"
    }
    
    ###########################
    ### Vector GIS Handling ###
    ###########################
    
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
            } else {error "Internal error"}
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
            error "Failed to establish a mapping between geographic and map projections"
        }

        set Map(loaded) true
        set Map(type) "Vector"
        set Map(filepath) $filepath
        
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
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbGeometryCollection"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbGeometryCollection25D"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbLineString"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbLineString25D"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbLinearRing"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbPoint"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbPoint25D"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbPolygon"} {
                    set data [$geometry ExportToWkb]
                    binary scan $data cuIuIu byte_order geometry_type ring_count
                    set shift 9
                    for {set r 0} {$r < $ring_count} {incr r} {
                        binary scan $data x${shift}Iu no_of_points
                        incr shift 4
                        binary scan $data x${shift}Q[expr {$no_of_points * 2}] points
                        incr shift [expr {$no_of_points * 16}] ;# 16 = dimention * sizeof(double) = 2 * 8
                        
                        # XXX y coord need to * -1
                        
                        $Container add curve map $points -filled true -linecolor black -fillcolor gray -linewidth 1 -tags feature
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
                        
                        # XXX y coord need to * -1
                        
                        $Container add curve map $xypoints -linecolor black -fillcolor gray -linewidth 1 -filled true -tags feature
                    }
                } elseif {$geotype eq "$::ogr::wkbMultiLineString"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbMultiLineString25D"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbMultiPoint"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbMultiPoint25D"} {
                    # XXX
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

                            # XXX y coord need to * -1
                            
                            $Container add curve map $points -filled true -linecolor black -fillcolor gray -linewidth 1 -tags feature
                        }
                    }
                } elseif {$geotype eq "$::ogr::wkbMultiPolygon25D"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbNDR"} {
                    # XXX
                } elseif {$geotype eq "$::ogr::wkbXDR"} {
                    # XXX
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

        lassign [$Container bbox map] x1 y1 x2 y2
        set Map(width) [expr {$x2 - $x1}]
        set Map(height) [expr {$y2 - $y1}]
        $Container translate shift [expr {$x1 * -1}] [expr {$y1 * -1}] yes
        
    } ;# method
    
    ###########################
    ### Raster GIS Handling ###
    ###########################
    
    public method openRaster {filepath} {
        set Dataset [::gdal::Open $filepath $::gdal::GA_ReadOnly]
        
        if {$Dataset eq ""} {
            error "Could not open file"
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
            } else {error "Internal error"}
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
            error "Failed to establish a mapping between geographic and map projections"
        }
        
        set Map(loaded) true
        set Map(type) "Raster"
        set Map(filepath) $filepath
        set Map(width) [$Dataset cget -RasterXSize]
        set Map(height) [$Dataset cget -RasterYSize]
        
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
                    # XXX 
                }
                "Cyan" - "Magenta" - "Yellow" - "Black" -
                "YCbCr_Y" - "YCbCr_Cb" - "YCbCr_Cr" {
                    puts stderr "Could not recognize file format. \"$colorinterp\" band type not supported."
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
            
        ::NAP::nap "u = reshape(u, {$height $width})"
        
        $u set count +1
        return $u
    }
} ;# class
