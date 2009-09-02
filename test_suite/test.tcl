#!/usr/bin/tclsh
lappend auto_path /usr/local/lib/
package require ogr 1.0

set IMAGE ../GISViewer/maps/tl_2008_36_cd108.shp

::ogr::RegisterAll
set dataset [::ogr::Open $IMAGE 0] ;# 0 for readonly
puts Dataset:[$dataset GetName]
set layers [$dataset GetLayerCount]

for {set l 0} {$l < $layers} {incr l} {
    set layer [$dataset GetLayerByIndex $l]
    puts Layer$l:[$layer GetName]
    $layer ResetReading
    while {[set feature [$layer GetNextFeature]] ne "NULL"} {
        puts "\nFEATURE: [$feature GetFID]"

        # Dump all attribute fields of the feature
        set fields [$feature GetFieldCount]
        for {set f 0} {$f < $fields} {incr f} {
            if {! [$feature IsFieldSet $f]} { continue }

            set def [$feature GetFieldDefnRef $f]
            set defname [$def GetName]
            set deftype [$feature GetFieldType $f]
            set deftype [$def GetFieldTypeName [$def GetType]]
            switch -exact -- $deftype {
                "String" { set data [$feature GetFieldAsString $f] }
                "Real" { set data [$feature GetFieldAsDouble $f] }
                default { set data [$feature GetFieldAsString $f] }
            }
            
            puts "\tAttr: $defname: $data ($deftype Justify:[$def GetJustify] Width:[$def GetWidth] Precision:[$def GetPrecision])"
        }

        # Extract the geometry of the feature and print it
        set geometry [$feature GetGeometryRef]
        if {$geometry ne ""} {
            set geotype [$geometry GetGeometryName]
            puts "\n\tGeometry: $geotype ([$geometry GetGeometryType])"
        }

        $feature -delete
    }
}

$dataset -delete

