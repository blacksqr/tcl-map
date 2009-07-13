#!/usr/local/bin/tclsh8.5
package require tcltest
namespace import tcltest::*
#configure -verbose {body error pass skip}

load ../gdal.so
load ../gdalconst.so

set PNG [file join data gdalicon.png]
set GIF [file join data DTU_logo.gif]
set BMP [file join data warning.bmp]
set TIFF [file join data map.tiff] ;# XXX Segfaults on Open

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
    lassign [intersect3 [read $fd] [info commands osgeo::*]] L C R
    close $fd
    concat $L $R
}

test Variables {Test the existance of all available GDAL Tcl variables/constants} -body {
    set fd [open gdal-variables.txt r]
    lassign [intersect3 [read $fd] [info vars osgeo::*]] L C R
    close $fd
    concat $L $R
}
    
### 

test ::osgeo::VersionInfo {} -body {
    ::osgeo::VersionInfo
} -result 1604

test ::osgeo::ReadDir {} -body {
    ::osgeo::ReadDir data
} -result [list .. . gdalicon.png warning.bmp mysymbol.svg DTU_logo.gif map.tiff]

test ::osgeo::FindFile {} -body {
    ::osgeo::FindFile XXX data/map.tiff ;# pszClass: first arg
} -result {./data/map.tiff}

test ::osgeo::EscapeString {} -body {
    ::osgeo::EscapeString ask\0dj
} -result ask\0dj


### Error/Debug Procedures ###

# XXX Test it
test ::osgeo::DontUseExceptions {} -body {
    ::osgeo::DontUseExceptions
}

# XXX Test it
test ::osgeo::UseExceptions {} -body {
    ::osgeo::UseExceptions
}

# CE_None, CE_Debug, CE_Warning, CE_Failure, CE_Fatal
test ::osgeo::Debug {} -body {
    ::osgeo::Debug $::osgeo::CE_Debug DebugMessage
}

test ::osgeo::Error {} -body {
    ::osgeo::Error $::osgeo::CE_Warning 0 ErrorMessage
    catch {::osgeo::Error $::osgeo::CE_Failure 0 ErrorMessage}
} -result 1

# XXX Test it 
test ::osgeo::GetLastErrorNo {} -body {
    ::osgeo::GetLastErrorNo
} -result 0

# XXX Test it 
test ::osgeo::GetLastErrorMsg {} -body {
    ::osgeo::GetLastErrorMsg
}

# XXX Test it 
test ::osgeo::GetLastErrorType {} -body {
    ::osgeo::GetLastErrorType
} -result 0

test ::osgeo::ErrorReset {} -body {
    ::osgeo::ErrorReset
}

### GDAL Datatypes ###

# GDALGetDataTypeSize
test ::osgeo::GetDataTypeSize {} -body {
    ::osgeo::GetDataTypeSize $::osgeo::GDT_Float64
} -result 64

# GDALGetDataTypeName
test ::osgeo::GetDataTypeName {} -body {
    ::osgeo::GetDataTypeName $::osgeo::GDT_UInt16
} -result UInt16

# GDALGetDataTypeByName
test ::osgeo::GetDataTypeByName {} -body {
    ::osgeo::GetDataTypeByName Byte
} -result $::osgeo::GDT_Byte

# GDALDataTypeIsComplex
test ::osgeo::DataTypeIsComplex {} -body {
    ::osgeo::DataTypeIsComplex $::osgeo::GDT_CInt32
} -result 1

# GDALDataTypeUnion
test ::osgeo::DataTypeUnion {} -body {
    ::osgeo::DataTypeUnion $::osgeo::GDT_CFloat32 $::osgeo::GDT_Int32
} -result $::osgeo::GDT_CFloat32

### GDALDriverManager ###

# GDALDestroyDriverManager
test ::osgeo::GDALDestroyDriverManager {Unloads all} -body {
    ::osgeo::GDALDestroyDriverManager
}

# GDALAllRegister
# GDALDriverManager::AutoLoadDrivers, GDALDriverManager::AutoSkipDrivers
test ::osgeo::AllRegister {Loads all supported} -body {
    ::osgeo::AllRegister
}

# GDALGetDriverCount
# GDALDriverManager::GetDriverCount
test ::osgeo::GetDriverCount {} -body {
    set count [::osgeo::GetDriverCount]
} -result 80

# GDALGetDriver
# GDALDriverManager::GetDriver
test ::osgeo::GetDriver {} -body {
    for {set i 0} {$i < $count} {incr i} {
        lappend all_drivers [::osgeo::GetDriver $i]
    }
    llength $all_drivers
} -result 80

# GDALGetDriverByName
# GDALDriverManager::GetDriverByName
test ::osgeo::GetDriverByName {} -body {
    set driver [::osgeo::GetDriverByName PNG]
    llength $driver
} -result 1

# GDALDriverManager::DeregisterDriver
# GDALDeregisterDriver
test ::osgeo::Driver_Deregister {} -body {
    $driver Deregister
}

# GDALDriverManager::RegisterDriver
# GDALRegisterDriver
test ::osgeo::Driver_Register {} -body {
    # The driver is registered and the new driver index is returned 
    # (it is placed on the end of the registered drivers list).
    # If driver already registered then it returns the existing index
    # is returned.
    $driver Register
} -result 79

### GDALMajorObject ###

# GDALGetMetadata
# GDALMajorObject::GetMetadata
test ::osgeo::MajorObject_GetMetadata_Dict {} -body {
    $driver GetMetadata_Dict
} -result [dict create DMD_LONGNAME {Portable Network Graphics} DMD_HELPTOPIC frmt_various.html#PNG DMD_EXTENSION png DMD_MIMETYPE image/png DMD_CREATIONDATATYPES {Byte UInt16} DMD_CREATIONOPTIONLIST {<CreationOptionList>
   <Option name='WORLDFILE' type='boolean' description='Create world file'/>
</CreationOptionList>
} DCAP_VIRTUALIO YES DCAP_CREATECOPY YES]

# GDALGetMetadata
# GDALMajorObject::GetMetadata
test ::osgeo::MajorObject_GetMetadata_List {} -body {
    $driver GetMetadata_List
} -result [list {DMD_LONGNAME=Portable Network Graphics} DMD_HELPTOPIC=frmt_various.html#PNG DMD_EXTENSION=png DMD_MIMETYPE=image/png {DMD_CREATIONDATATYPES=Byte UInt16} {DMD_CREATIONOPTIONLIST=<CreationOptionList>
   <Option name='WORLDFILE' type='boolean' description='Create world file'/>
</CreationOptionList>
} DCAP_VIRTUALIO=YES DCAP_CREATECOPY=YES]

#ZZZ
#::osgeo::MajorObject_GetMetadataItem
#::osgeo::MajorObject_SetMetadata
#::osgeo::MajorObject_SetMetadataItem

# GDALGetDescription
# GDALMajorObject::GetDescription
test ::osgeo::MajorObject_GetDescription {} -body {
    $driver GetDescription
} -result {PNG}

# GDALSetDescription
# GDALMajorObject::SetDescription
test ::osgeo::MajorObject_SetDescription {} -body {
    $driver SetDescription PNG2
    $driver GetDescription
} -result {PNG2}

### GDALDriver ###

# GDALIdentifyDriver
test ::osgeo::IdentifyDriver {} -body {
    set driver [::osgeo::IdentifyDriver $PNG]
    llength $driver
} -result 1

# GDALGetDriverShortName
test ::osgeo::Driver_ShortName_get {} -body {
    $driver cget -ShortName
} -result {PNG2}

# GDALGetDriverLongName
test ::osgeo::Driver_LongName_get {} -body {
    $driver cget -LongName
} -result {Portable Network Graphics}

# GDALGetDriverHelpTopic
test ::osgeo::Driver_HelpTopic_get {} -body {
    $driver cget -HelpTopic
} -result {frmt_various.html#PNG}

set driver [::osgeo::IdentifyDriver $TIFF]

# GDALCreate
# GDALDriver::Create
test ::osgeo::Driver_Create {} -body {
    set dataset [$driver Create data/test.tiff 32 32 3]
    llength $dataset
} -result 1


# GDALCreateCopy
# GDALDriver::CreateCopy
if 0 { ;# XXX Segfaults
test ::osgeo::Driver_CreateCopy {} -body {
    set dataset2 [$driver CreateCopy data/test2.tiff $dataset 0]
    llength $dataset2
} -result 1
}

file delete data/test.tiff
$dataset -delete
#file delete data/test2.tiff
#$dataset2 -delete

if 0 { ;#XXX
# GDALCopyDatasetFiles
# GDALDriver::CopyFiles
test ::osgeo::Driver_CopyFiles {} -body {
    # Not implemented
}
}

file copy -force $PNG ${PNG}_new

# GDALRenameDataset
# GDALDriver::Rename
test ::osgeo::Driver_Rename {} -body {
    $driver Rename ${PNG}_renamed ${PNG}_new
} -result $::osgeo::CE_None


# GDALDeleteDataset
# GDALDriver::Delete
test ::osgeo::Driver_Delete {} -body {
    $driver Delete ${PNG}_renamed
} -result $::osgeo::CE_None

test DestroyDriver {} -body {
    $driver -delete
    catch { $driver GetDescription }
} -result 1

### Dataset ###

# GDALOpen
test ::osgeo::Open {} -body {
    set dataset [::osgeo::Open $PNG $::osgeo::GA_ReadOnly]
    llength $dataset
} -result 1

# GDALGetDatasetDriver 
# GDALDataset::GetDriver
test ::osgeo::Dataset_GetDriver {} -body {
    set driver [$dataset GetDriver]
    llength $driver
} -result 1

# GDALGetRasterXSize 
# GDALDataset::GetRasterXSize
test ::osgeo::Dataset_RasterXSize_get {} -body {
    $dataset cget -RasterXSize
} -result {32}

# GDALGetRasterYSize 
# GDALDataset::GetRasterYSize
test ::osgeo::Dataset_RasterYSize_get {} -body {
    $dataset cget -RasterYSize
} -result {32}

# GDALGetRasterCount 
# GDALDataset::GetRasterCount
test ::osgeo::Dataset_RasterCount_get {} -body {
    $dataset cget -RasterCount
} -result {4}

test ::osgeo::delete_Dataset {} -body {
    $dataset -delete
    catch { $dataset GetDescription }
} -result 1

# GDALOpenShared
test ::osgeo::OpenShared {} -body {
    set dataset [::osgeo::OpenShared $PNG $::osgeo::GA_ReadOnly]
    llength $dataset
} -result 1

# Note: If you SetDescription GetFileList returns {} then.
# GDALGetFileList 
# GDALDataset::GetFileList
test ::osgeo::Dataset_GetFileList {} -body {
    $dataset GetFileList
} -result {data/gdalicon.png}

# GDALSetProjection
# GDALDataset::SetProjection
test ::osgeo::Dataset_SetProjection {} -body {
    $dataset SetProjection UTM ;# OGC WKT or PROJ.4
} -result $::osgeo::CE_None ;# Indicates non-failure

# GDALGetProjectionRef 
# GDALDataset::GetProjectionRef
test ::osgeo::Dataset_GetProjectionRef {} -body {
    $dataset GetProjectionRef
} -result UTM

# Note: Same as GDALGetProjectionRef
# GDALGetProjection
# GDALDataset::GetProjection
test ::osgeo::Dataset_GetProjection {} -body {
    $dataset GetProjection
} -result UTM

#   1: top left x
#   2: w-e pixel resolution
#   3: rotation, 0 if image is "north up"
#   4: top left y
#   5: rotation, 0 if image is "north up"
#   6: n-s pixel resolution
# GDALGetGeoTransform
# GDALDataset::GetGeoTransform
test ::osgeo::Dataset_GetGeoTransform {} -body {
    $dataset GetGeoTransform
} -result [list [list 0.0 1.0 0.0 0.0 0.0 1.0]]

#     id: Unique identifier, often numeric. 
#     info: Informational message or "". 
#     pixel: Pixel (x) location of GCP on raster. 
#     line: Line (y) location of GCP on raster. 
#     x: X position of GCP in georeferenced space. 
#     y: Y position of GCP in georeferenced space. 
#     z: Elevation of GCP, or zero if not known. 
# ?x? ?y? ?z? ?pixel? ?line? ?info? ?id?
test ::osgeo::GCP {} -body {
    set GCP [::osgeo::GCP XXX 100.0 200.0 10.0 0.0 0.0 "info" "id0"]
    llength $GCP
} -result 1

# GDALSetGCPs
# GDALDataset::SetGCPs
if 0 { ;# XXX wrong ## args, without KKK it segfaults
test ::osgeo::Dataset_SetGCPs {} -body {
    $dataset SetGCPs 1 $GCP ;# OGC WKT
} -result $::osgeo::CE_None ;# Indicates non-failure
}

# GDALGetGCPCount
# GDALDataset::GetGCPCount
test ::osgeo::Dataset_GetGCPCount {} -body {
    $dataset GetGCPCount
} -result 0

# GDALGetGCPs
# GDALDataset::GetGCPs
test ::osgeo::Dataset_GetGCPs {} -body {
    $dataset GetGCPs
}

if 0 { ;# XXX Segfaults
# GDALSetGeoTransform
# GDALDataset::SetGeoTransform
test ::osgeo::Dataset_SetGeoTransform {} -body {
    $dataset SetGeoTransform [list 0.0 1.0 0.0 0.0 0.0 1.0]
}
}

# GDALGetGCPProjection
# GDALDataset::GetGCPProjection
test ::osgeo::Dataset_GetGCPProjection {} -body {
    $dataset GetGCPProjection
}

if 0 { ;# XXX
# xoff yoff xsize ysize ?buf? ?buf_xsize? ?buf_ysize? ?buf_type? ?band_list? ?pband_list?
# GDALDatasetRasterIO
# GDALDataset::RasterIO
test ::osgeo::Dataset_ReadRaster {} -body {
    $dataset ReadRaster 5 5 10 10
}
}

# GDALGetRasterBand
# GDALDataset::GetRasterBand
test ::osgeo::Dataset_GetRasterBand {} -body {
    set band [$dataset GetRasterBand 1]
    llength $band
} -result 1

### Band ###

# xoff, yoff, nxsize, nysize
# GDALChecksumImage
test ::osgeo::Band_Checksum {} -body {
    $band Checksum
} -result 7617

# GDALRasterBand::GetStatistics
# GDALComputeBandStats
test ::osgeo::Band_ComputeBandStats {} -body {
    $band ComputeBandStats
} -result [list [list 64.4072265625 63.11639163552757]]

# GDALComputeRasterMinMax
# GDALRasterBand::ComputeRasterMinMax
test ::osgeo::Band_ComputeRasterMinMax {} -body {
    $band ComputeRasterMinMax
} -result [list [list 0.0 237.0]]

# GDALGetBlockSize
# GDALRasterBand::GetBlockSize
test ::osgeo::Band_GetBlockSize {} -body {
    $band GetBlockSize
} -result [list 32 1]

# GDALGetRasterDataType
# GDALRasterBand::GetRasterDataType
test ::osgeo::Band_DataType_get {} -body {
    $band cget -DataType
} -result $::osgeo::GDT_Byte

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
test ::osgeo::Band_GetRasterColorInterpretation {} -body {
    set cinterp [$band GetRasterColorInterpretation]
} -result 3

# GDALGetColorInterpretationName
test ::osgeo::GetColorInterpretationName {} -body {
    ::osgeo::GetColorInterpretationName $cinterp
} -result Red

# GDALGetRasterMinimum
# GDALRasterBand::GetMinimum
test ::osgeo::Band_GetMinimum {} -body {
    $band GetMinimum
} -result [list [list]] ;# XXX

# GDALGetRasterMaximum
# GDALRasterBand::GetMaximum
test ::osgeo::Band_GetMaximum {} -body {
    $band GetMaximum
} -result [list [list]] ;# XXX

# GDALGetRasterNoDataValue
# GDALRasterBand::GetNoDataValue
test ::osgeo::Band_GetNoDataValue {} -body {
    $band GetNoDataValue
} -result [list [list]] ;# XXX

# GDALGetOverviewCount
# GDALRasterBand::GetOverviewCount
test ::osgeo::Band_GetOverviewCount {} -body {
    $band GetOverviewCount
} -result 0

# GDALGetRasterBandXSize
# GDALRasterBand::GetXSize
test ::osgeo::Band_XSize_get {} -body {
    $band cget -XSize
} -result 32

# GDALGetRasterBandYSize
# GDALRasterBand::GetYSize
test ::osgeo::Band_YSize_get {} -body {
    $band cget -YSize
} -result 32

# Note: Units value (e.g. elevation) = (raw pixel value * GetScale) + GetOffset
# GDALGetRasterOffset
# GDALRasterBand::GetOffset
test ::osgeo::Band_GetOffset {} -body {
    $band GetOffset
} -result 0.0

# GDALGetRasterScale
# GDALRasterBand::GetScale
test ::osgeo::Band_GetScale {} -body {
    $band GetScale
} -result 1.0

#   pdfMin
#   pdfMax
#   pdfMean
#   pdfStdDev
# GDALGetRasterStatistics
# GDALRasterBand::GetStatistics
test ::osgeo::Band_GetStatistics {} -body {
# arg1: bApproxOK   If TRUE statistics may be computed based on overviews or a subset of all tiles.
# arg2: bForce   If FALSE statistics will only be returned if it can be done without rescanning the image
    $band GetStatistics 0 1
} -result [list 0.0 237.0 64.4072265625 63.11639163552757]

# GDALGetRasterCategoryNames
# GDALRasterBand::GetCategoryNames
test ::osgeo::Band_GetRasterCategoryNames {} -body {
    $band GetRasterCategoryNames
}

# xoff yoff xsize ysize ?buf? ?buf_xsize? ?buf_ysize? ?buf_type?
test ::osgeo::Band_ReadRaster {} -body {
    set data [$band ReadRaster 0 0 32 32]
    string length $data
} -result 1024

# Same as ::osgeo::Band_GetColorTable
test ::osgeo::Band_GetRasterColorTable {} -body {
    $band GetRasterColorTable
} -result NULL

#test ::osgeo::ColorTable {} -body {
#    ::osgeo::ColorTable ;# ?palette?
#}

$dataset -delete

cleanupTests
