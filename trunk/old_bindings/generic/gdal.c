/*
    gdal - A translator library for raster geospatial data formats.
    A Tcl interface to the GDAL library.

    Copyright (C) 2009  Alexandros Stergiakis

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
 * gdal.c
 *
 */

#include <stdio.h>          // snprintf

#include <gdal.h>

#include <tcl.h>

#include "gdal.h"

/*
 * Function Prototypes
 */

static int dataset_info(GDALDatasetH dataset, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);

static int dataset_band(GDALDatasetH dataset, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);

static int dataset_meta(GDALDatasetH dataset, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);

static int GdalCmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);

static int DatasetCmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);

static void DatasetCmd_CleanUp(ClientData clientData);

static void itoa(int n, char *s);

/*
 * Function Bodies
 */

int Gdal_Init(Tcl_Interp *interp) {
    if (Tcl_InitStubs(interp, "8.5", 0) == NULL) {
        return TCL_ERROR;
    }

    /* Register drivers for all supported raster formats. */
    GDALAllRegister();

    Tcl_CreateObjCommand(interp, "gdal", GdalCmd, (ClientData) NULL, NULL);

    Tcl_PkgProvide(interp, "gdal", "1.0");
    return TCL_OK;
}

static int GdalCmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
    if (objc < 3) {
        Tcl_WrongNumArgs(interp, 1, objv, "name location");
        return TCL_ERROR;
    }

    char *name;
    name = Tcl_GetString(objv[1]);

    char *location;
    location = Tcl_GetString(objv[2]);

    GDALDatasetH *dataset;
    dataset = (GDALDatasetH *) GDALOpen(location, GA_ReadOnly );
    if(dataset == NULL ) {
        Tcl_SetResult(interp, "Failed to open requested resource", TCL_STATIC);
        return TCL_ERROR;
    }

    Tcl_CreateObjCommand(interp, name, DatasetCmd, (ClientData) dataset, DatasetCmd_CleanUp);
    return TCL_OK;
}

static int DatasetCmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
    static char* cmds[] = { "info", "band", "meta", NULL };
    int index;

    if (objc < 2) {
        Tcl_WrongNumArgs(interp, 1, objv, "option ?arg? ...");
        return TCL_ERROR;
    }

    if (Tcl_GetIndexFromObj(interp, objv[1], cmds, "option", 0, &index) != TCL_OK)
        return TCL_ERROR;

    GDALDatasetH *dataset = (GDALDatasetH *) clientData;

    switch (index) {
        case 0: /* info */
        {
            return dataset_info(dataset, interp, objc, objv);
            break;
        }

        case 1: /* band */
        {
            return dataset_band(dataset, interp, objc, objv);
            break;
        }

        case 2: /* meta */
        {
            return dataset_meta(dataset, interp, objc, objv);
            break;
        }

    } /* switch */

    return TCL_OK;
}

static int dataset_info(GDALDatasetH dataset, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
    if (objc != 2) {
        Tcl_WrongNumArgs(interp, 2, objv, NULL);
        return TCL_ERROR;
    }

    char intStr[INT_LEN];
    Tcl_Obj *keyPtr, *valPtr, *dictPtr, *listPtr, *dict2Ptr;
    dictPtr = Tcl_NewDictObj();

    GDALDriverH driver;
    driver = GDALGetDatasetDriver(dataset);

    /* Return the long name of a driver.  For the GeoTIFF driver, this is "GeoTIFF" */
    keyPtr = Tcl_NewStringObj("driver", -1);
    valPtr = Tcl_NewStringObj(GDALGetDriverLongName(driver), -1);            
    if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
        Tcl_DecrRefCount(keyPtr);
        Tcl_DecrRefCount(valPtr);
        Tcl_DecrRefCount(dictPtr);
        return TCL_ERROR;
    }

    /* Get description */
    keyPtr = Tcl_NewStringObj("description", -1);
    valPtr = Tcl_NewStringObj(GDALGetDescription(dataset), -1);
    if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
        Tcl_DecrRefCount(keyPtr);
        Tcl_DecrRefCount(valPtr);
        Tcl_DecrRefCount(dictPtr);
        return TCL_ERROR;
    }

    /* Fetch raster width and height in pixels. */
    keyPtr = Tcl_NewStringObj("width", -1);
    itoa(GDALGetRasterXSize(dataset), intStr);
    valPtr = Tcl_NewStringObj(intStr, -1);            
    if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
        Tcl_DecrRefCount(keyPtr);
        Tcl_DecrRefCount(valPtr);
        Tcl_DecrRefCount(dictPtr);
        return TCL_ERROR;
    }

    keyPtr = Tcl_NewStringObj("height", -1);
    itoa(GDALGetRasterYSize(dataset), intStr);
    valPtr = Tcl_NewStringObj(intStr, -1);            
    if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
        Tcl_DecrRefCount(keyPtr);
        Tcl_DecrRefCount(valPtr);
        Tcl_DecrRefCount(dictPtr);
        return TCL_ERROR;
    }

    /* Fetch the number of raster bands on this dataset. */
    keyPtr = Tcl_NewStringObj("raster_bands_count", -1);
    itoa(GDALGetRasterCount(dataset), intStr);
    valPtr = Tcl_NewStringObj(intStr, -1);            
    if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
        Tcl_DecrRefCount(keyPtr);
        Tcl_DecrRefCount(valPtr);
        Tcl_DecrRefCount(dictPtr);
        return TCL_ERROR;
    }

    /* Fetch the projection definition string for this dataset. */
    keyPtr = Tcl_NewStringObj("projection", -1);
    valPtr = Tcl_NewStringObj(GDALGetProjectionRef(dataset), -1);            
    if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
        Tcl_DecrRefCount(keyPtr);
        Tcl_DecrRefCount(valPtr);
        Tcl_DecrRefCount(dictPtr);
        return TCL_ERROR;
    }

    /* Fetch the affine transformation coefficient */
    double adfGeoTransform[6];
    //    adfGeoTransform[0] /* top left x */
    //    adfGeoTransform[1] /* w-e pixel resolution */
    //    adfGeoTransform[2] /* rotation, 0 if image is "north up" */
    //    adfGeoTransform[3] /* top left y */
    //    adfGeoTransform[4] /* rotation, 0 if image is "north up" */
    //    adfGeoTransform[5] /* n-s pixel resolution */
    listPtr = Tcl_NewListObj(0, NULL);
    if(GDALGetGeoTransform(dataset, adfGeoTransform) == CE_None ) {
        valPtr = Tcl_NewDoubleObj((double) adfGeoTransform[0]);
        Tcl_ListObjAppendElement(interp, listPtr, valPtr);
        valPtr = Tcl_NewDoubleObj((double) adfGeoTransform[3]);
        Tcl_ListObjAppendElement(interp, listPtr, valPtr);
        valPtr = Tcl_NewDoubleObj((double) adfGeoTransform[1]);
        Tcl_ListObjAppendElement(interp, listPtr, valPtr);
        valPtr = Tcl_NewDoubleObj((double) adfGeoTransform[5]);
        Tcl_ListObjAppendElement(interp, listPtr, valPtr);
        valPtr = Tcl_NewDoubleObj((double) adfGeoTransform[2]);
        Tcl_ListObjAppendElement(interp, listPtr, valPtr);
        valPtr = Tcl_NewDoubleObj((double) adfGeoTransform[4]);
        Tcl_ListObjAppendElement(interp, listPtr, valPtr);
    }

    keyPtr = Tcl_NewStringObj("affine_transformation_coefficients", -1);
    if (Tcl_DictObjPut(interp, dictPtr, keyPtr, listPtr) != TCL_OK) {
        Tcl_DecrRefCount(keyPtr);
        Tcl_DecrRefCount(valPtr);
        Tcl_DecrRefCount(listPtr);
        Tcl_DecrRefCount(dictPtr);
        return TCL_ERROR;
    }

    /* Get output projection for GCPs. */
    keyPtr = Tcl_NewStringObj("gcp_projection", -1);
    valPtr = Tcl_NewStringObj(GDALGetProjectionRef(dataset), -1);            
    if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
        Tcl_DecrRefCount(keyPtr);
        Tcl_DecrRefCount(valPtr);
        Tcl_DecrRefCount(dictPtr);
        return TCL_ERROR;
    }

    /* Fetch GCPs. */
    const GDAL_GCP *gcp = GDALGetGCPs(dataset);

    listPtr = Tcl_NewListObj(0, NULL);
    dict2Ptr = Tcl_NewDictObj();
    if (gcp != NULL) {

        /* Unique identifier, often numeric. */
        keyPtr = Tcl_NewStringObj("id", -1);
        valPtr = Tcl_NewStringObj(gcp->pszId, -1);
        if (Tcl_DictObjPut(interp, dict2Ptr, keyPtr, valPtr) != TCL_OK) {
            Tcl_DecrRefCount(keyPtr);
            Tcl_DecrRefCount(valPtr);
            Tcl_DecrRefCount(dict2Ptr);
            Tcl_DecrRefCount(dictPtr);
            return TCL_ERROR;
        }
        
        /* Informational message or "". */
        keyPtr = Tcl_NewStringObj("info", -1);
        valPtr = Tcl_NewStringObj(gcp->pszInfo, -1);
        if (Tcl_DictObjPut(interp, dict2Ptr, keyPtr, valPtr) != TCL_OK) {
            Tcl_DecrRefCount(keyPtr);
            Tcl_DecrRefCount(valPtr);
            Tcl_DecrRefCount(dict2Ptr);
            Tcl_DecrRefCount(dictPtr);
            return TCL_ERROR;
        }

        /* Pixel (x) location of GCP on raster. */
        keyPtr = Tcl_NewStringObj("pixel", -1);
        valPtr = Tcl_NewDoubleObj((double) gcp->dfGCPPixel);
        if (Tcl_DictObjPut(interp, dict2Ptr, keyPtr, valPtr) != TCL_OK) {
            Tcl_DecrRefCount(keyPtr);
            Tcl_DecrRefCount(valPtr);
            Tcl_DecrRefCount(dict2Ptr);
            Tcl_DecrRefCount(dictPtr);
            return TCL_ERROR;
        }

        /* Pixel (y) location of GCP on raster. */
        keyPtr = Tcl_NewStringObj("line", -1);
        valPtr = Tcl_NewDoubleObj((double) gcp->dfGCPLine);
        if (Tcl_DictObjPut(interp, dict2Ptr, keyPtr, valPtr) != TCL_OK) {
            Tcl_DecrRefCount(keyPtr);
            Tcl_DecrRefCount(valPtr);
            Tcl_DecrRefCount(dict2Ptr);
            Tcl_DecrRefCount(dictPtr);
            return TCL_ERROR;
        }

        /* X position of GCP in georeferenced space. */
        keyPtr = Tcl_NewStringObj("X", -1);
        valPtr = Tcl_NewDoubleObj((double) gcp->dfGCPX);
        if (Tcl_DictObjPut(interp, dict2Ptr, keyPtr, valPtr) != TCL_OK) {
            Tcl_DecrRefCount(keyPtr);
            Tcl_DecrRefCount(valPtr);
            Tcl_DecrRefCount(dict2Ptr);
            Tcl_DecrRefCount(dictPtr);
            return TCL_ERROR;
        }

        /* Y position of GCP in georeferenced space. */
        keyPtr = Tcl_NewStringObj("Y", -1);
        valPtr = Tcl_NewDoubleObj((double) gcp->dfGCPY);
        if (Tcl_DictObjPut(interp, dict2Ptr, keyPtr, valPtr) != TCL_OK) {
            Tcl_DecrRefCount(keyPtr);
            Tcl_DecrRefCount(valPtr);
            Tcl_DecrRefCount(dict2Ptr);
            Tcl_DecrRefCount(dictPtr);
            return TCL_ERROR;
        }

        /* Elevation of GCP, or zero if not known. */
        keyPtr = Tcl_NewStringObj("Z", -1);
        valPtr = Tcl_NewDoubleObj((double) gcp->dfGCPZ);
        if (Tcl_DictObjPut(interp, dict2Ptr, keyPtr, valPtr) != TCL_OK) {
            Tcl_DecrRefCount(keyPtr);
            Tcl_DecrRefCount(valPtr);
            Tcl_DecrRefCount(dict2Ptr);
            Tcl_DecrRefCount(dictPtr);
            return TCL_ERROR;
        }
    }

    keyPtr = Tcl_NewStringObj("gcp", -1);
    if (Tcl_DictObjPut(interp, dictPtr, keyPtr, dict2Ptr) != TCL_OK) {
        Tcl_DecrRefCount(keyPtr);
        Tcl_DecrRefCount(valPtr);
        Tcl_DecrRefCount(listPtr);
        Tcl_DecrRefCount(dictPtr);
        return TCL_ERROR;
    }

    Tcl_SetObjResult(interp, dictPtr);

    return TCL_OK;
}

static int dataset_band(GDALDatasetH dataset, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
    static char* cmds[] = { "info", "read", "ctable", NULL };
    int index;

    GDALRasterBandH band;
    int bandid;

    if (objc < 4) {
        Tcl_WrongNumArgs(interp, 2, objv, "band option ?...?");
        return TCL_ERROR;
    }

    if (Tcl_GetIntFromObj(interp, objv[2], &bandid) != TCL_OK) return TCL_ERROR;
    // NOTE: The library will check for valid integer range for bandid.

    band = GDALGetRasterBand(dataset, bandid);

    if (Tcl_GetIndexFromObj(interp, objv[3], cmds, "option", 0, &index) != TCL_OK)
        return TCL_ERROR;

    switch (index) {
        case 0: /* info */
        {
            if (objc != 4) {
                Tcl_WrongNumArgs(interp, 4, objv, NULL);
                return TCL_ERROR;
            }

            int nBlockXSize, nBlockYSize;
            int bGotMin, bGotMax;
            double adfMinMax[2];

            Tcl_Obj *keyPtr, *valPtr, *dictPtr, *listPtr;
            dictPtr = Tcl_NewDictObj();
            listPtr = Tcl_NewListObj(0, NULL);

            GDALGetBlockSize(band, &nBlockXSize, &nBlockYSize);

            /* Fetch the "natural" block size of this band. */
            keyPtr = Tcl_NewStringObj("block_size", -1);
            valPtr = Tcl_NewIntObj(nBlockXSize);
            Tcl_ListObjAppendElement(interp, listPtr, valPtr);
            valPtr = Tcl_NewIntObj(nBlockYSize);
            Tcl_ListObjAppendElement(interp, listPtr, valPtr);
            if (Tcl_DictObjPut(interp, dictPtr, keyPtr, listPtr) != TCL_OK) {
                Tcl_DecrRefCount(keyPtr);
                Tcl_DecrRefCount(valPtr);
                Tcl_DecrRefCount(listPtr);
                Tcl_DecrRefCount(dictPtr);
                return TCL_ERROR;
            }

            /* Fetch the pixel data type for this band. */
            keyPtr = Tcl_NewStringObj("data_type", -1);
            valPtr = Tcl_NewStringObj(
                        GDALGetDataTypeName(GDALGetRasterDataType(band)), -1);
            if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
                Tcl_DecrRefCount(keyPtr);
                Tcl_DecrRefCount(valPtr);
                Tcl_DecrRefCount(dictPtr);
                return TCL_ERROR;
            }

            /* Get name of color interpretation. */
            keyPtr = Tcl_NewStringObj("raster_color_interpretation", -1);
            valPtr = Tcl_NewStringObj(
                        GDALGetColorInterpretationName(GDALGetRasterColorInterpretation(band)), -1);
            if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
                Tcl_DecrRefCount(keyPtr);
                Tcl_DecrRefCount(valPtr);
                Tcl_DecrRefCount(dictPtr);
                return TCL_ERROR;
            }

            /* Fetch the minimum/maximum value for this band. */
            adfMinMax[0] = GDALGetRasterMinimum(band, &bGotMin);
            adfMinMax[1] = GDALGetRasterMaximum(band, &bGotMax);
            if( ! (bGotMin && bGotMax) )
                GDALComputeRasterMinMax(band, TRUE, adfMinMax);

            keyPtr = Tcl_NewStringObj("min", -1);
            valPtr = Tcl_NewDoubleObj((double) adfMinMax[0]);
            if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
                Tcl_DecrRefCount(keyPtr);
                Tcl_DecrRefCount(valPtr);
                Tcl_DecrRefCount(dictPtr);
                return TCL_ERROR;
            }

            keyPtr = Tcl_NewStringObj("max", -1);
            valPtr = Tcl_NewDoubleObj((double) adfMinMax[1]);
            if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
                Tcl_DecrRefCount(keyPtr);
                Tcl_DecrRefCount(valPtr);
                Tcl_DecrRefCount(dictPtr);
                return TCL_ERROR;
            }

            /* Get description */
            keyPtr = Tcl_NewStringObj("description", -1);
            valPtr = Tcl_NewStringObj(GDALGetDescription(band), -1);
            if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
                Tcl_DecrRefCount(keyPtr);
                Tcl_DecrRefCount(valPtr);
                Tcl_DecrRefCount(dictPtr);
                return TCL_ERROR;
            }

            /* No data value */
            int has_nodata = 0;
            double nodata = GDALGetRasterNoDataValue(band, &has_nodata);
            if (has_nodata) {
                valPtr = Tcl_NewDoubleObj(nodata);
            } else {
                valPtr = Tcl_NewListObj(0, NULL);
            }
            keyPtr = Tcl_NewStringObj("nodata", -1);
            if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
                Tcl_DecrRefCount(keyPtr);
                Tcl_DecrRefCount(valPtr);
                Tcl_DecrRefCount(dictPtr);
                return TCL_ERROR;
            }

            /* Return the number of overview layers available. */
            keyPtr = Tcl_NewStringObj("overview_count", -1);
            valPtr = Tcl_NewIntObj(GDALGetOverviewCount(band));
            if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
                Tcl_DecrRefCount(keyPtr);
                Tcl_DecrRefCount(valPtr);
                Tcl_DecrRefCount(dictPtr);
                return TCL_ERROR;
            }

            /* Return the number of color entries in the color table for the band. */
            if(GDALGetRasterColorTable(band) != NULL) {
                keyPtr = Tcl_NewStringObj("color_entry_count", -1);
                valPtr = Tcl_NewIntObj(GDALGetColorEntryCount(GDALGetRasterColorTable(band)));
                if (Tcl_DictObjPut(interp, dictPtr, keyPtr, valPtr) != TCL_OK) {
                    Tcl_DecrRefCount(keyPtr);
                    Tcl_DecrRefCount(valPtr);
                    Tcl_DecrRefCount(dictPtr);
                    return TCL_ERROR;
                }
            }

            Tcl_SetObjResult(interp, dictPtr);
            break;
        } /* info */

        case 1: /* read */
        {
            if (objc != 4 && objc != 6) {
                Tcl_WrongNumArgs(interp, 4, objv, "?width height?");
                return TCL_ERROR;
            }

            int nXSize = GDALGetRasterBandXSize(band);
            int nYSize = GDALGetRasterBandYSize(band);

            int nBufXSize = nXSize;
            int nBufYSize = nYSize;
            if (objc == 6) {
                if (Tcl_GetIntFromObj(interp, objv[4], &nBufXSize) != TCL_OK) return TCL_ERROR;
                if (Tcl_GetIntFromObj(interp, objv[5], &nBufYSize) != TCL_OK) return TCL_ERROR;
            }

            // NOTE: It is more effective to access the image in image block size chunks.
            unsigned char *buffer = 
                    (unsigned char *) ckalloc(sizeof(GDALGetRasterDataType(band)) * nBufXSize* nBufYSize);
            GDALRasterIO(band, GF_Read, 0, 0, nXSize, nYSize, buffer, nBufXSize, nBufYSize, 
                    GDALGetRasterDataType(band), 0, 0);
            Tcl_Obj *result = Tcl_NewByteArrayObj(buffer, nBufXSize * nBufYSize);
            ckfree((char *) buffer);

            Tcl_SetObjResult(interp, result);
            break;
        } /* read */

        case 1: /* ctable */
        {
            GDALColorTableH GDALGetRasterColorTable   (  GDALRasterBandH   hBand    ) 
        } /* ctable */

    } /* switch */

    return TCL_OK;
}

static int dataset_meta(GDALDatasetH dataset, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
    static char* types[] = { "dataset", "driver", "band", NULL };
    int index;

    if (objc < 3) {
        Tcl_WrongNumArgs(interp, 2, objv, "type ...");
        return TCL_ERROR;
    }

    if (Tcl_GetIndexFromObj(interp, objv[2], types, "type", 0, &index) != TCL_OK)
        return TCL_ERROR;

    char *domain = NULL;
    char *key = NULL;
    Tcl_Obj *result = NULL;
    GDALMajorObjectH majorObj = NULL;

    switch (index) {
        case 0: /* dataset */
        {
            if (objc < 4 || objc > 5) {
                Tcl_WrongNumArgs(interp, 3, objv, "domain ?key?");
                return TCL_ERROR;
            }

            domain = Tcl_GetString(objv[3]);
            if (objc == 5) key = Tcl_GetString(objv[4]);
            majorObj = (GDALMajorObjectH) dataset;
            break;
        } /* dataset */

        case 1: /* driver */
        {
            if (objc < 4 || objc > 5) {
                Tcl_WrongNumArgs(interp, 3, objv, "domain ?key?");
                return TCL_ERROR;
            }

            domain = Tcl_GetString(objv[3]);
            if (objc == 5) key = Tcl_GetString(objv[4]);

            GDALDriverH driver;
            driver = GDALGetDatasetDriver(dataset);
            majorObj = (GDALMajorObjectH) driver;
            break;
        } /* driver */

        case 2: /* band */
        {
            if (objc < 5 || objc > 6) {
                Tcl_WrongNumArgs(interp, 3, objv, "id domain ?key?");
                return TCL_ERROR;
            }

            domain = Tcl_GetString(objv[4]);
            if (objc == 6) key = Tcl_GetString(objv[5]);

            int bandid;
            if (Tcl_GetIntFromObj(interp, objv[3], &bandid) != TCL_OK) return TCL_ERROR;
            if (bandid > GDALGetRasterCount(dataset)) {
                Tcl_SetResult(interp, "The specified band layer does not exist", TCL_STATIC);
                return TCL_ERROR;
            }

            GDALRasterBandH band;
            band = GDALGetRasterBand(dataset, bandid);
            majorObj = (GDALMajorObjectH) band;
            break;
        } /* band */

    } /* switch */

    if (key == NULL) {
        result = Tcl_NewListObj(0, NULL);
        
        char **metadata = GDALGetMetadata(majorObj, domain);
        while (metadata != NULL && *metadata != NULL) {
            Tcl_ListObjAppendElement(interp, result, Tcl_NewStringObj(*metadata, -1));
            metadata++;
        }
    } else {
        const char *metadata = GDALGetMetadataItem(majorObj, key, domain);
        if (metadata == NULL) {
            result = Tcl_NewStringObj("", -1);
        } else {
            result = Tcl_NewStringObj(metadata, -1);
        }
    }

    Tcl_SetObjResult(interp, result);
    return TCL_OK;
}

static void DatasetCmd_CleanUp(ClientData clientData) {
    GDALDatasetH *dataset = (GDALDatasetH *) clientData;
    GDALClose(dataset); 
}

/* itoa:  convert integer n to characters in s */
static void itoa(int n, char *s)
{
    snprintf(s, INT_LEN, "%d", n);
}
