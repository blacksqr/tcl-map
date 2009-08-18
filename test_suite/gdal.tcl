#!/usr/bin/tclsh8.5

package require tcltest
namespace import tcltest::*
#configure -verbose {body error pass skip}

lappend auto_path /usr/local/lib
package require gdal
package require gdalconst

set TIF [file join maps chicago UTM2GTIF.TIF]

proc intersect3 {lista listb} {
    lassign {} L C R

    foreach a $lista {
        if {$a ni $listb} {
            # $a unique in lista
            lappend L $a
        } else {
            # $a is in the intersection
            lappend C $a
        }
    }

    foreach a $listb {
        if {$a ni $lista} {
            # $a unique in listb
            lappend R $a
        } else {
            # $a is in the intersection
            lappend C $a
        }
    }

    return [list $L $C $R]
}

### Checks that there are no more or less commands and variables than expected ###

test Commands {Test the existance of all available GDAL Tcl commands} -body {
    set fd [open gdal-commands.txt r]
    lassign [intersect3 [read $fd] [info commands ::gdal::*]] L C R
    close $fd
    concat $L $R
}

test Variables {Test the existance of all available GDAL Tcl variables/constants} -body {
    set fd [open gdal-variables.txt r]
    lassign [intersect3 [read $fd] [info vars ::gdal::*]] L C R
    close $fd
    concat $L $R
}
    
### 

test ::gdal::VersionInfo {} -body {
    ::gdal::VersionInfo
} -match glob -result 16*

test ::gdal::ReadDir {} -body {
    lsort [::gdal::ReadDir maps]
} -result [list . .. .svn WrldTZA cea  chicago  world]

# Note: First argument is not used anywhere, but it is supposed to be a class id for the file.
test ::gdal::FindFile {} -body {
    ::gdal::FindFile class $TIF
} -result [file join . $TIF]

test ::gdal::EscapeString {} -body {
    ::gdal::EscapeString ask\0dj
} -result ask\0dj

### Error/Debug Procedures ###

# XXX Test it
test ::gdal::DontUseExceptions {} -body {
    ::gdal::DontUseExceptions
}

# XXX Test it
test ::gdal::UseExceptions {} -body {
    ::gdal::UseExceptions
}

# CE_None, CE_Debug, CE_Warning, CE_Failure, CE_Fatal
test ::gdal::Debug {} -body {
    ::gdal::Debug $::gdal::CE_Debug DebugMessage
}

test ::gdal::Error {} -body {
    ::gdal::Error $::gdal::CE_Warning 0 ErrorMessage
    catch {::gdal::Error $::gdal::CE_Failure 0 ErrorMessage}
} -result 1

# XXX Test it 
test ::gdal::GetLastErrorNo {} -body {
    ::gdal::GetLastErrorNo
} -result 0

# XXX Test it 
test ::gdal::GetLastErrorMsg {} -body {
    ::gdal::GetLastErrorMsg
}

# XXX Test it 
test ::gdal::GetLastErrorType {} -body {
    ::gdal::GetLastErrorType
} -result 0

# XXX Test it 
test ::gdal::ErrorReset {} -body {
    ::gdal::ErrorReset
}

### GDAL Datatypes ###

# GDALGetDataTypeSize
test ::gdal::GetDataTypeSize {} -body {
    ::gdal::GetDataTypeSize $::gdal::GDT_Float64
} -result 64

# GDALGetDataTypeName
test ::gdal::GetDataTypeName {} -body {
    ::gdal::GetDataTypeName $::gdal::GDT_UInt16
} -result UInt16

# GDALGetDataTypeByName
test ::gdal::GetDataTypeByName {} -body {
    ::gdal::GetDataTypeByName Byte
} -result $::gdal::GDT_Byte

# GDALDataTypeIsComplex
test ::gdal::DataTypeIsComplex {} -body {
    ::gdal::DataTypeIsComplex $::gdal::GDT_CInt32
} -result 1

# GDALDataTypeUnion
test ::gdal::DataTypeUnion {} -body {
    ::gdal::DataTypeUnion $::gdal::GDT_CFloat32 $::gdal::GDT_Int32
} -result $::gdal::GDT_CFloat32

puts "Data Types:"
foreach dtype [info vars ::gdal::GDT_*] {
    set dtype [set $dtype]
    puts "Name: [::gdal::GetDataTypeName $dtype] ($dtype) \tSize: [::gdal::GetDataTypeSize $dtype] \tComplex: [::gdal::DataTypeIsComplex $dtype]"
}

### GDALDriverManager ###

# GDALDestroyDriverManager
test ::gdal::GDALDestroyDriverManager {Unloads all} -body {
    ::gdal::GDALDestroyDriverManager
}

# GDALAllRegister
# GDALDriverManager::AutoLoadDrivers, GDALDriverManager::AutoSkipDrivers
test ::gdal::AllRegister {Loads all supported} -body {
    ::gdal::AllRegister
}

# GDALGetDriverCount
# GDALDriverManager::GetDriverCount
test ::gdal::GetDriverCount {} -body {
    set count [::gdal::GetDriverCount]
    puts "\nDriver Count: $count"
    string is integer $count
} -result 1

# GDALGetDriver
# GDALDriverManager::GetDriver
test ::gdal::GetDriver {} -body {
    for {set i 0} {$i < $count} {incr i} {
        lappend all_drivers [[::gdal::GetDriver $i] cget -ShortName]
    }
    puts "\nSupported Drivers: $all_drivers"
    expr [llength $all_drivers] > 0
} -result 1

# GDALGetDriverByName
# GDALDriverManager::GetDriverByName
test ::gdal::GetDriverByName {} -body {
    set driver [::gdal::GetDriverByName PNG]
    llength $driver
} -result 1

# GDALDriverManager::DeregisterDriver
# GDALDeregisterDriver
test ::gdal::Driver_Deregister {} -body {
    $driver Deregister
}

# GDALDriverManager::RegisterDriver
# GDALRegisterDriver
test ::gdal::Driver_Register {} -body {
    # The driver is registered and the new driver index is returned 
    # (it is placed on the end of the registered drivers list).
    # If driver already registered then it returns the existing index
    # is returned.
    $driver Register
} -result [expr $count - 1]

### GDALMajorObject ###

# GDALGetMetadata
# GDALMajorObject::GetMetadata
test ::gdal::MajorObject_GetMetadata_Dict {} -body {
    $driver GetMetadata_Dict
} -result [dict create DMD_LONGNAME {Portable Network Graphics} DMD_HELPTOPIC frmt_various.html#PNG DMD_EXTENSION png DMD_MIMETYPE image/png DMD_CREATIONDATATYPES {Byte UInt16} DMD_CREATIONOPTIONLIST {<CreationOptionList>
   <Option name='WORLDFILE' type='boolean' description='Create world file'/>
</CreationOptionList>
} DCAP_VIRTUALIO YES DCAP_CREATECOPY YES]

# GDALGetMetadata
# GDALMajorObject::GetMetadata
test ::gdal::MajorObject_GetMetadata_List {} -body {
    $driver GetMetadata_List
} -result [list {DMD_LONGNAME=Portable Network Graphics} DMD_HELPTOPIC=frmt_various.html#PNG DMD_EXTENSION=png DMD_MIMETYPE=image/png {DMD_CREATIONDATATYPES=Byte UInt16} {DMD_CREATIONOPTIONLIST=<CreationOptionList>
   <Option name='WORLDFILE' type='boolean' description='Create world file'/>
</CreationOptionList>
} DCAP_VIRTUALIO=YES DCAP_CREATECOPY=YES]

# GDALGetMetadataItem
# GDALMajorObject::GetMetadataItem
test ::gdal::MajorObject_GetMetadata_List {} -body {
    $driver GetMetadataItem DMD_LONGNAME
} -result {Portable Network Graphics}

# GDALGetDescription
# GDALMajorObject::GetDescription
test ::gdal::MajorObject_GetDescription {} -body {
    $driver GetDescription
} -result {PNG}

# GDALSetDescription
# GDALMajorObject::SetDescription
test ::gdal::MajorObject_SetDescription {} -body {
    $driver SetDescription PNG2
    $driver GetDescription
} -result {PNG2}

### GDALDriver ###

# GDALIdentifyDriver
test ::gdal::IdentifyDriver {} -body {
    set driver [::gdal::IdentifyDriver $TIF]
    llength $driver
} -result 1

# GDALGetDriverShortName
test ::gdal::Driver_ShortName_get {} -body {
    $driver cget -ShortName
} -result {GTiff}

# GDALGetDriverLongName
test ::gdal::Driver_LongName_get {} -body {
    $driver cget -LongName
} -result {GeoTIFF}

# GDALGetDriverHelpTopic
test ::gdal::Driver_HelpTopic_get {} -body {
    $driver cget -HelpTopic
} -result {frmt_gtiff.html}

# GDALCreate
# GDALDriver::Create
test ::gdal::Driver_Create {} -body {
    set dataset [$driver Create test.tiff 32 32 3]
    llength $dataset
} -result 1

# GDALCreateCopy
# GDALDriver::CreateCopy
test ::gdal::Driver_CreateCopy {} -body {
    set dataset2 [$driver CreateCopy test2.tiff $dataset] ;# strict=0 options callback callback_data
    $dataset2 -delete
    file delete test2.tiff
    llength $dataset2
} -result 1 -constraints SegFaults

file delete test.tiff
$dataset -delete

# GDALCopyDatasetFiles
# GDALDriver::CopyFiles
test ::gdal::Driver_CopyFiles {} -body {
    $driver CopyFiles test.tiff test2.tiff
    file delete test2.tiff
} -constraints NotImplemented

file copy -force $TIF ${TIF}_new

# GDALRenameDataset
# GDALDriver::Rename
test ::gdal::Driver_Rename {} -body {
    $driver Rename ${TIF}_renamed ${TIF}_new
} -result $::gdal::CE_None

# GDALDeleteDataset
# GDALDriver::Delete
test ::gdal::Driver_Delete {} -body {
    $driver Delete ${TIF}_renamed
} -result $::gdal::CE_None

test DestroyDriver {} -body {
    $driver -delete
    catch { $driver GetDescription }
} -result 1

### Dataset ###

# GDALOpen
test ::gdal::Open {} -body {
    set dataset [::gdal::Open $TIF $::gdal::GA_ReadOnly]
    llength $dataset
} -result 1

# GDALGetDatasetDriver 
# GDALDataset::GetDriver
test ::gdal::Dataset_GetDriver {} -body {
    set driver [$dataset GetDriver]
    llength $driver
} -result 1

# GDALGetRasterXSize 
# GDALDataset::GetRasterXSize
test ::gdal::Dataset_RasterXSize_get {} -body {
    $dataset cget -RasterXSize
} -result 699

# GDALGetRasterYSize 
# GDALDataset::GetRasterYSize
test ::gdal::Dataset_RasterYSize_get {} -body {
    $dataset cget -RasterYSize
} -result 929

# GDALGetRasterCount 
# GDALDataset::GetRasterCount
test ::gdal::Dataset_RasterCount_get {} -body {
    $dataset cget -RasterCount
} -result 1

test ::gdal::delete_Dataset {} -body {
    $dataset -delete
    catch { $dataset GetDescription }
} -result 1

# GDALOpenShared
test ::gdal::OpenShared {} -body {
    set dataset [::gdal::OpenShared $TIF $::gdal::GA_ReadOnly]
    llength $dataset
} -result 1

# Note: If you SetDescription GetFileList returns {} then.
# GDALGetFileList 
# GDALDataset::GetFileList
test ::gdal::Dataset_GetFileList {} -body {
    $dataset GetFileList
} -result $TIF

# GDALGetProjection
# GDALDataset::GetProjection
# Note: GDALGetProjectionRef is the same.
test ::gdal::Dataset_GetProjection {} -body {
    $dataset GetProjection
} -result {PROJCS["NAD27 / UTM zone 16N",GEOGCS["NAD27",DATUM["North_American_Datum_1927",SPHEROID["Clarke 1866",6378206.4,294.9786982139006,AUTHORITY["EPSG","7008"]],AUTHORITY["EPSG","6267"]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433],AUTHORITY["EPSG","4267"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",-87],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AUTHORITY["EPSG","26716"]]}

#   1: top left x
#   2: w-e pixel resolution
#   3: rotation, 0 if image is "north up"
#   4: top left y
#   5: rotation, 0 if image is "north up"
#   6: n-s pixel resolution
# GDALGetGeoTransform
# GDALDataset::GetGeoTransform
test ::gdal::Dataset_GetGeoTransform {} -body {
    $dataset GetGeoTransform
} -result {{444650.0 10.0 0.0 4640510.0 0.0 -10.0}}

# GDALGetGCPCount
# GDALDataset::GetGCPCount
# XXX Test it
test ::gdal::Dataset_GetGCPCount {} -body {
    $dataset GetGCPCount
} -result 0

#     id: Unique identifier, often numeric. 
#     info: Informational message or "". 
#     pixel: Pixel (x) location of GCP on raster. 
#     line: Line (y) location of GCP on raster. 
#     x: X position of GCP in georeferenced space. 
#     y: Y position of GCP in georeferenced space. 
#     z: Elevation of GCP, or zero if not known. 
# ?x? ?y? ?z? ?pixel? ?line? ?info? ?id?
# XXX Bug: How to use ::gdal::GCP ?
test ::gdal::new_GCP {} -body {
    set GCP [::gdal::new_GCP 100.0 200.0 10.0 0.0 0.0 "info" "id0"]
    llength $GCP
} -result 1

# GDALSetGCPs
# GDALDataset::SetGCPs
# Parameters:
#        nGCPCount   number of GCPs being assigned.
#        pasGCPList  array of GCP structures being assign (nGCPCount in array).
#        pszGCPProjection    the new OGC WKT coordinate system to assign for the GCP output coordinates. This parameter should be "" if no output coordinate system is known.
test ::gdal::Dataset_SetGCPs {} -body {
    $dataset SetGCPs 1 $GCP
} -constraints SegFaults -result $::gdal::CE_None ;# Indicates non-failure

# GDALGetGCPs
# GDALDataset::GetGCPs
test ::gdal::Dataset_GetGCPs {} -body {
    $dataset GetGCPs
} -result [list]

# GDALSetGeoTransform
# GDALDataset::SetGeoTransform
test ::gdal::Dataset_SetGeoTransform {} -body {
    $dataset SetGeoTransform [list 0.0 1.0 0.0 0.0 0.0 1.0]
} -constraints SegFaults

# GDALGetGCPProjection
# GDALDataset::GetGCPProjection
test ::gdal::Dataset_GetGCPProjection {} -body {
    $dataset GetGCPProjection
}

# GDALDatasetRasterIO
# GDALDataset::RasterIO
# Args: xoff yoff xsize ysize ?buf? ?buf_xsize? ?buf_ysize? ?buf_type? ?band_list? ?pband_list?
# XXX Test it with optional arguments
test ::gdal::Dataset_ReadRaster {} -body {
    $dataset ReadRaster 5 5 10 10
} -constraints Bug

# GDALGetRasterBand
# GDALDataset::GetRasterBand
test ::gdal::Dataset_GetRasterBand {} -body {
    set band [$dataset GetRasterBand 1]
    llength $band
} -result 1

### Band ###

# GDALGetRasterDataType
# GDALRasterBand::GetRasterDataType
test ::gdal::Band_DataType_get {} -body {
    $band cget -DataType
} -result $::gdal::GDT_Byte

# xoff, yoff, nxsize, nysize
# GDALChecksumImage
test ::gdal::Band_Checksum {} -body {
    $band Checksum
} -result 4857

# GDALRasterBand::GetStatistics
# GDALComputeBandStats
test ::gdal::Band_ComputeBandStats {} -body {
    $band ComputeBandStats
} -result [list [list 115.04442760763878 50.70849521224453]]

# GDALComputeRasterMinMax
# GDALRasterBand::ComputeRasterMinMax
test ::gdal::Band_ComputeRasterMinMax {} -body {
    $band ComputeRasterMinMax
} -result [list [list 6.0 255.0]]

# GDALGetBlockSize
# GDALRasterBand::GetBlockSize
test ::gdal::Band_GetBlockSize {} -body {
    $band GetBlockSize
} -result [list 699 11]

# GDALGetRasterDataType
# GDALRasterBand::GetRasterDataType
test ::gdal::Band_DataType_get {} -body {
    $band cget -DataType
} -result $::gdal::GDT_Byte

#  GCI_GrayIndex    Greyscale 
#  GCI_PaletteIndex    Paletted (see associated color table) 
#  GCI_RedBand    Red band of RGBA image 
#  GCI_GreenBand    Green band of RGBA image 
#  GCI_BlueBand    Blue band of RGBA image 
#  GCI_AlphaBand    Alpha (0=transparent, 255=opaque) 
#  GCI_HueBand    Hue band of HLS image 
#  GCI_SaturationBand    Saturation band of HLS image 
#  GCI_LightnessBand    Lightness band of HLS image 
#  GCI_CyanBand    Cyan band of CMYK image 
#  GCI_MagentaBand    Magenta band of CMYK image 
#  GCI_YellowBand    Yellow band of CMYK image 
#  GCI_BlackBand    Black band of CMLY image 
#  GCI_YCbCr_YBand    Y Luminance 
#  GCI_YCbCr_CbBand    Cb Chroma 
#  GCI_YCbCr_CrBand    Cr Chroma 
#  GCI_Max    Max current value
# GDALGetRasterColorInterpretation
# GDALRasterBand::GetColorInterpretation
test ::gdal::Band_GetRasterColorInterpretation {} -body {
    set cinterp [$band GetRasterColorInterpretation]
} -result $::gdal::GCI_GrayIndex

# GDALGetColorInterpretationName
test ::gdal::GetColorInterpretationName {} -body {
    ::gdal::GetColorInterpretationName $cinterp
} -result Gray

# GDALGetRasterMinimum
# GDALRasterBand::GetMinimum
# XXX Test it
test ::gdal::Band_GetMinimum {} -body {
    $band GetMinimum
} -result [list [list]]

# GDALGetRasterMaximum
# GDALRasterBand::GetMaximum
# XXX Test it
test ::gdal::Band_GetMaximum {} -body {
    $band GetMaximum
} -result [list [list]]

# GDALGetRasterNoDataValue
# GDALRasterBand::GetNoDataValue
# XXX Test it
test ::gdal::Band_GetNoDataValue {} -body {
    $band GetNoDataValue
} -result [list [list]]

# GDALGetOverviewCount
# GDALRasterBand::GetOverviewCount
test ::gdal::Band_GetOverviewCount {} -body {
    $band GetOverviewCount
} -result 0

# GDALGetRasterBandXSize
# GDALRasterBand::GetXSize
test ::gdal::Band_XSize_get {} -body {
    $band cget -XSize
} -result 699

# GDALGetRasterBandYSize
# GDALRasterBand::GetYSize
test ::gdal::Band_YSize_get {} -body {
    $band cget -YSize
} -result 929

# GDALGetRasterOffset
# GDALRasterBand::GetOffset
# Note: Units value (e.g. elevation) = (raw pixel value * GetScale) + GetOffset
# XXX Test it
test ::gdal::Band_GetOffset {} -body {
    $band GetOffset
} -result [list [list]]

# GDALGetRasterScale
# GDALRasterBand::GetScale
# XXX Test it
test ::gdal::Band_GetScale {} -body {
    $band GetScale
} -result [list [list]]

# GDALGetRasterStatistics
# GDALRasterBand::GetStatistics
# Args: 
#   bApproxOK   If TRUE statistics may be computed based on overviews or a subset of all tiles.
#   bForce   If FALSE statistics will only be returned if it can be done without rescanning the image
# Return: pdfMin pdfMax pdfMean pdfStdDev
test ::gdal::Band_GetStatistics {} -body {
    $band GetStatistics 0 1
} -result [list 6.0 255.0 115.04442760763878 50.70849521224453]

# GDALGetRasterCategoryNames
# GDALRasterBand::GetCategoryNames
# XXX Test it
test ::gdal::Band_GetRasterCategoryNames {} -body {
    $band GetRasterCategoryNames
}

# xoff yoff xsize ysize ?buf_xsize? ?buf_ysize? ?buf_type?
test ::gdal::Band_ReadRaster {} -body {
    set data [$band ReadRaster 0 0 32 32]
    string length $data
} -result 1024

# Same as ::gdal::Band_GetColorTable
test ::gdal::Band_GetRasterColorTable {} -body {
    $band GetRasterColorTable
} -result NULL

# GDALColorTable (GDALPaletteInterp=GPI_RGB)
test ::gdal::ColorTable {} -body {
#   GPI_Gray    Grayscale (in GDALColorEntry.c1)
#   GPI_RGB     Red, Green, Blue and Alpha in (in c1, c2, c3 and c4)
#   GPI_CMYK    Cyan, Magenta, Yellow and Black (in c1, c2, c3 and c4)
#   GPI_HLS     Hue, Lightness and Saturation (in c1, c2, and c3) 
    set ctable [::gdal::ColorTable $::gdal::GPI_Gray]
    llength $ctable
} -result 1

test ::gdal::ColorEntry {} -body {
    set centry [::gdal::new_ColorEntry]
} -result [list 0 0 0 0]

test ::gdal::ColorTable_SetColorEntry {} -body {
#    $ctable SetColorEntry 0 $centry
}

test ::gdal::ColorTable_GetCount {} -body {
    $ctable GetCount
} -result 0

if 0 {
#XXX TODO:
    Command: ::gdal::Band_GetDefaultHistogram
    Command: ::gdal::Band_GetDefaultRAT
    Command: ::gdal::Band_GetHistogram
    Command: ::gdal::Band_GetMaskBand
    Command: ::gdal::Band_GetMaskFlags
::gdal::Band_CreateMaskBand

    GDALColorTableH table = GDALGetRasterColorTable(band);
    GDALGetPaletteInterpretationName(GDALGetPaletteInterpretation(table))
GDALGetColorEntryCount(table)

    GDALColorEntry *entry = GDALGetColorEntry(table, i);
}

$dataset -delete

puts "\n"
cleanupTests; exit
