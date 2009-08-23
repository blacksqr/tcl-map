/*
/*
 * hdf_get_sds.c --
 *
 * Copyright 2000, CSIRO Australia
 * Author: Harvey Davies, CSIRO Atmospheric Research
 */

#ifndef lint
static char *rcsid="@(#) $Id: hdf_get_sds.c,v 1.1 2001/11/16 00:25:57 dav480 Exp $";
#endif /* not lint */

#include <mfhdf.h>

#define CHECK(OK, STATUS) \
    if (!(OK)) { \
        *status = STATUS; \
        return; \
    }

/*
 * hdf_get_sds --
 *
 * Read data from HDF SDS
 *
 * Assume pointer "data" points to area of data-type matching that of SDS
 *
 * *status is set to one of following values
 * 0: success
 * 1: error calling SDstart i.e. opening file
 * 2: error calling SDnametoindex i.e. opening SDS
 * 3: error calling SDselect i.e. opening SDS
 * 4: error calling SDgetinfo i.e. getting info about SDS
 * 5: error calling SDreaddata i.e. reading data from SDS
 * 6: error calling SDend i.e. closing file
 */

void
hdf_get_sds(
    char                *filename,
    char                *sds_name,
    int                 *start,
    int                 *stride,
    int                 *edge,
    void                *data,                  /* area for input data */ 
    int                 *status)                /* see above */
{   
    int32               edge32[MAX_VAR_DIMS];   
    int32               i;
    char                name[MAX_NC_NAME];
    int32               natts;                  /* # attributes */
    int32               number_type;            /* HDF type */
    int32               rank;                   
    int                 s;                      /* error status */
    int32               sd_id;                  /* file handle */
    int32               sds_id;                 /* SDS handle */
    int32               sds_index;              /* SDS index */
    int32               shape32[MAX_VAR_DIMS];
    int32               start32[MAX_VAR_DIMS];
    int32               stride32[MAX_VAR_DIMS];
    
    sd_id = SDstart(filename, DFACC_RDONLY);
    CHECK(sd_id >= 0, 1);
    sds_index = SDnametoindex(sd_id, sds_name);
    CHECK(sds_index >= 0, 2);
    sds_id = SDselect(sd_id, sds_index);
    CHECK(sds_id >= 0, 3);
    s = SDgetinfo(sds_id, name, &rank, shape32, &number_type, &natts);
    CHECK(s == SUCCEED, 4);
    for (i = 0; i < rank; i++) {
        start32[i] = start[i];
        stride32[i] = stride[i];
        edge32[i] = edge[i];
    }
    s = SDreaddata(sds_id, start32, stride32, edge32, data);
    CHECK(s == SUCCEED, 5);
    s = SDend(sd_id);
    CHECK(s == SUCCEED, 6);
    *status = 0;
}
