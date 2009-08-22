/*
 * land_flag.c --
 *
 * Copyright (c) 2001, CSIRO Australia
 *
 * Author: Peter Turner, CSIRO Atmospheric Research
 * Based on code by Chris Mutlow, RAL
 *
 * This module returns a land flag for any latitude and longitude
 * on Earth to an accuracy of 0.01 degrees. 
 * 
 * The directory where the land mask files called:
 *
 * sfa_world.landsea
 * sfa_degrees.landsea
 * sfa_tenths.landsea
 *
 * are located must be defined in the first parameter to the function.
 *
 * nap y = shape(latitude)
 * nap x = shape(longitude)
 * nap mask = reshape(i16(0),{latitude longitude}
 * nap_land_flag y x latitude longitude mask
 */

#ifndef lint
static char *rcsid="@(#) $Id: land_flag.c,v 1.3 2005/11/06 05:45:15 dav480 Exp $";
#endif /* not lint */

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <fcntl.h>
#include <math.h>
#include <errno.h>
#include <tcl.h>

#ifdef _WIN32
    #include <io.h>		/* declares lseek on MS Windows */
#elif HAVE_UNISTD_H
    #include <unistd.h>		/* declares lseek on some systems */
#endif

#ifndef O_BINARY
#  define O_BINARY 0
#endif

#define malloc(N)	ckalloc(N)
#define free(P)		if (P) ckfree((char *) P)

#include "land_flag.h"

void sfa_swap_bytes (void *buf, int btel, int nel);
void emsg(unsigned char *msg, int msz, char *fmt, ...);



/*
 * land_flag --
 *
 * World land flagging algorithm
 * Returns a land sea mask for the given latitude and longitude arrays
 * Land returned as true (1) and Sea as false (0). 
 *
 * modified CTM 13/08/98 
 * modified Peter Turner, CSIRO Atmospheric Research April 2001
 *
 * Changes from the original code supplied by Chris Mutlow RAL:
 *
 * Changed the interface to provide a request for mask values for
 * a number of latitude and longitude values rather than just one.
 * This allows the function to be restructured to dynamically
 * allocate data arrays and removes static declarations.
 * Byte reversal has been added to cope with different endian
 * CPUs and all file handles are closed on completion.
 */

/*
 * Define the top level data base size
 */
#define WXSZ 360
#define WYSZ 180

void
land_flag (
    unsigned char *dir,		/* data directory		*/
    int *max_y,			/* y dimension size		*/
    int *max_x,			/* x dimension size		*/
    float *latitude,		/* latitude array		*/
    float *longitude,           /* longitude array     		*/  
    signed char *surface_flag,	/* output mask          	*/
    int *err,			/* error state			*/
    unsigned char *msg,		/* error message		*/
    int *maxlen)		/* maximum error message size	*/
{
    unsigned char bit_values[] = { 1, 2, 4, 8, 16, 32, 64, 128 };
    char *envname;
    char fileName[120];
    char *filePtr;
    int mxsz = *maxlen;
    int x;		/* counter					*/
    int max_index;	/* size of the latitude and longitude array	*/
    int resolution;	/* resolution of the mask			*/
    float lat;		/* temporary latitude				*/
    float lon;		/* temporary longitude				*/
    long lat100;	/* latitude rounded to degrees			*/
    long lon100;	/* longitude rounded to degrees			*/
    int degree_value;	/* degree value for current position		*/
    int tenth_value;
    int bit; 
    int world_loop;
    int i,j;

    short *sfa_world_map;	/* pointer to world map data		*/
    short *sfa_world_mapPtr;	/* temporary pointer to map data 	*/
    int sfa_degree[10][10];	/* temporary high resolution cell	*/
    unsigned char sfa_tenth[14];
    int swap = 0;		/* Swap byte flag			*/
    int sfa_world;
    int sfa_degrees;
    int sfa_tenths;
    int current_degree;
    int current_tenth;

 
    max_index = *max_x * *max_y;
    resolution = 3;
    current_degree = -1;
    current_tenth  = -1;

/*
 * Initialise data array
 */

    envname = (char *) dir;
    if (envname == NULL) {
        *err = -1;
        emsg(msg,mxsz,"Path to data not set, LANDMASK_LUT undefined\n");
        return;
    }
        
    strcpy(fileName, envname);
    if (envname[strlen(envname)-1] != '/') {
        strcat(fileName,"/");
    }

/*
 * Point at the first character space available
 * after the / in the directory path
 */

    filePtr = fileName + strlen(fileName);

/*
 * Open the three data files
 */

    strcpy(filePtr,"sfa_world.landsea");
    if ((sfa_world = open(fileName, O_RDONLY | O_BINARY, 0)) < 0) {
        emsg(msg,mxsz,"Error %d opening %s\n",errno,fileName);
        *err = errno;
        return;
    }
    
    strcpy(filePtr,"sfa_degrees.landsea");
    if ((sfa_degrees = open(fileName, O_RDONLY | O_BINARY, 0)) < 0) { 
        emsg(msg,mxsz,"Error %d opening %s\n",errno,fileName);
        *err = errno;
        return;
    }
  
    strcpy(filePtr,"sfa_tenths.landsea");
    if ((sfa_tenths = open(fileName, O_RDONLY | O_BINARY, 0)) < 0) {
        emsg(msg,mxsz,"Error %d opening %s\n",errno,fileName);
        *err = errno;
        return;
    }

/*
 * Allocate space for the world map data and
 * read the data into the internal buffer.
 */
  
    sfa_world_map = (short *) malloc(WYSZ*WXSZ*2);
    sfa_world_mapPtr = sfa_world_map;
    for (world_loop = 0; world_loop < WYSZ; world_loop++) {
        if (read(sfa_world, (void *) sfa_world_mapPtr, WXSZ*2) < 0) {
            emsg(msg,mxsz,"Error %d reading sfa_world\n",errno);
            *err = errno;
            free(sfa_world_map);
            return;
        }
        sfa_world_mapPtr = sfa_world_mapPtr + WXSZ; 
    }
    close(sfa_world);

/*
 * Check to see if we need to byte reverse
 */

    if(*sfa_world_map != -2) {
        swap = 1;
        sfa_swap_bytes((void *)sfa_world_map,16,WYSZ*WXSZ); 
    }

/*
 * Work through all latitude and longitude values
 * and return corresponding land flag values
 */

    for (x = 0; x < max_index; x++) {
        lat = latitude[x];
        lon = longitude[x];
        if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) { 
            break;
        }

/* 
 * Convert the latitude and longitude pair passed as parameters
 * (in the range -90 to +90 and -180 to +180 respectively)
 * to the ranges expected by the sfa (0 to 180 and 0 to 360 respectively).
 * Extract the entry for the one degree cell from the world map.
 */

        lat += 90.0; lon += 180.0;
        lat100 = (long) floor(lat * 100.0 + 0.5);
        lon100 = (long) floor(lon * 100.0 + 0.5);

/*
 * Calculate the map index
 */

        sfa_world_mapPtr = sfa_world_map + (int) (lat100/100) * WXSZ;
        degree_value = *(sfa_world_mapPtr + (int) (lon100/100));

/*
 * Return true (land) if the degree is wholly land (-2)
 * or if the resolution is low (1) and the degree is mixed (>0).
 * Return false (sea) if the degree is wholly sea (-1).
 */

        if (degree_value == -2) {
            surface_flag[x]= 1;
        }
        else if (degree_value == -1) {
           surface_flag[x] = 0;
        }
        else {
            if (resolution == 1) {
                surface_flag[x] = 1;
            }

/*
 * If the entry within the tenths file for this degree is not
 * in memory, read it in.
 * Extract the entry for the 6 arcminute cell.
 */

            if (degree_value != current_degree) {
                lseek(sfa_degrees, (degree_value - 1) * 400, SEEK_SET);
                if (read(sfa_degrees, (void *) sfa_degree, 400) < 0) {
                    emsg(msg,mxsz,"Error %d reading sfa_degrees\n",errno);
                    *err = errno;
                    return;
                }
                if (swap) {
                    for(i = 0; i < 10; i++) {
                        for(j = 0; j < 10; j++) {
                            sfa_swap_bytes((void *)&sfa_degree[i][j],32,1);
                        }
                    }
                }
                current_degree = degree_value;
            }

            tenth_value = sfa_degree[(lat100/10) % 10][(lon100/10) % 10];

/*
 * Return true (land) if the tenth is wholly land (-2) or
 * if the resolution is medium (2)
 * and the tenth is mixed (>0).  Return false (sea) if the tenth
 * is wholly sea (-1).
 */

            if (tenth_value == -2) {
                surface_flag[x] = 1;
            }
            else if (tenth_value == -1) {
                surface_flag[x] = 0;
            }
            else {
                if (resolution == 2) {
                    surface_flag[x] = 1;
                }

/*
 * If the entry within the hundredths file for this tenth is not in memory, read it in.
 */

                if (tenth_value != current_tenth) {
                    lseek(sfa_tenths, (tenth_value - 1) * 14, SEEK_SET);
                    if (read(sfa_tenths, (void *) sfa_tenth, 14) < 0) {
                        emsg(msg,mxsz,"Error %d reading sfa_tenth\n",errno);
                        *err = errno;
                        return;
                    }
                    current_tenth = tenth_value;
                }

/*
 * Return true (land) if the correct bit within the hundredth
 * entry is set. Return false (sea) otherwise.
 */

                bit = ((lat100 % 10) * 10) + (lon100 % 10);
                surface_flag[x] = ((sfa_tenth[bit/8] & bit_values[bit % 8]) > 0);
            }
        }
    }

/*
 * Free memory and close open file handles.
 */

    free(sfa_world_map);
    close(sfa_degrees);
    close(sfa_tenths);
}

/*
 * sfa_swap_bytes--
 *
 * Byte swapping function for sfa data. 
 *
 * Peter Turner, CSIRO Atmospheric Research April 2001
 *
 */
void sfa_swap_bytes (
    void *buf,		/* pointer to data buffer		*/
    int btel,		/* bits per element (16 ot 32 bits)	*/
    int nel		/* number of elements to swap		*/
)
{
    unsigned char *ptr1,*ptr2,tmp;

    switch(btel) {
        case 16:
            ptr1 = ptr2 = (unsigned char *)buf;
            do {
                tmp = *ptr1;
                *ptr1 = *(++ptr2);
                *ptr2 = tmp;
                ptr1++; ptr1++;
                ptr2++;
            }
            while(--nel > 0);
            break;
        case 32:
            ptr1 = ptr2 = (unsigned char *)buf;
            do {
                ptr2 = ptr2 + 3;
                tmp = *ptr1;
                *ptr1 = *ptr2;
                *ptr2 = tmp;
                ptr1++; ptr2--;
                tmp = *ptr1;
                *ptr1 = *ptr2;
                *ptr2 = tmp; 
                ptr2 = ptr1 = ptr1 + 3;
            }
            while(--nel > 0);
            break;
    }
}

/*
 * emsg --
 *
 * Manage error messages for external subroutines
 * Checks the size of the error message and the output buffer
 * to avoid problems! However, because the vsprintf subroutine
 * is used it is possible for the error message to exceed the
 * available space. This would result in a core dump!
 *
 * Peter Turner, CSIRO Atmospheric Research April 2001
 */

void emsg (
    unsigned char *msg,	/* Error message output buffer	*/
    int msz,		/* Message buffer size		*/
    char *fmt,
    ...
)
{
    va_list args;
    int esz;
    char *mPtr;
    int tsz;
 /*
  * Define the size of a temporary buffer
  */   

    tsz = 1024;

    if (msz > tsz) {
        tsz = 2*msz;
    }
/*
 * Risk that if the error exceeds tsz characters
 * then we will have a problem
 * 
 * See The C Programming Language (Second Edition)
 * Brian W. Kernighan and Dennis M. Ritchie, page 174
 */
    mPtr = (char *) malloc(tsz);
    va_start(args, fmt);
    vsprintf(mPtr, fmt, args);
    va_end(args);
    esz = strlen(mPtr);

/*
 * Copy what we can
 */

    if (esz < msz) {
        strcpy((char *) msg, mPtr);
    } else {
        strncpy((char *) msg, mPtr, msz);
    }
    free(mPtr);
}
