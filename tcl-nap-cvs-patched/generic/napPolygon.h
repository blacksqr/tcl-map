/*
 * napPolygon.h --
 *
 * Routines to draw and fill polygons
 *
 * Copyright (c) 1998, CSIRO Australia
 *
 * Author: P.J. Turner, CSIRO Atmospheric Research
 *
 * $Id: napPolygon.h,v 1.5 2002/05/14 00:32:03 dav480 Exp $
 */

EXTERN int
Nap_Polyline(
    NapClientData       *nap_cd,
    int *px,           /* x polygon points  */
    int *py,           /* y polygon points  */
    size_t n,           /* number of polygon points */
    float *dataPtr,     /* place to draw line */
    float value,        /* value to write line */
    size_t x_dim,       /* x dimension size     */
    size_t y_dim,       /* y dimension size     */
    int close)          /* Close the polygon? */
;

EXTERN int
Nap_Polyfill(
    NapClientData       *nap_cd,
    int *px,           /* polygon x values */
    int *py,           /* polygon y values */
    size_t n,           /* number of polygon points */
    float *dataPtr,     /* pointer to data start */
    float fill,         /* polygon draw value  */
    size_t x_dim,       /* x dimension of data */
    size_t y_dim)       /* y dimension of data */
;

/*
 * The following is based on file POLYGON.H: Header file for polygon-filling
 * code, in CD accompanying:
 *
 * Michael Abrash:
 * "Michael Abrash's Graphics Programming Black Book, Special Edition"
 * ISBN: 1-57610-174-6
 * Coriolis Group Books, Scottsdale, Arizona (http://www.coriolis.com)
 * 1997
 */

#define CONVEX    0
#define NONCONVEX 1
#define COMPLEX   2

/* Describes a single point (used for a single vertex) */

struct Point {
   int X;   /* X coordinate */
   int Y;   /* Y coordinate */
};

/* Describes a series of points (used to store a list of vertices that
   describe a polygon; each vertex connects to the two adjacent
   vertices; the last vertex is assumed to connect to the first) */

struct PointListHeader {
   int Length;                /* # of points */
   struct Point * PointPtr;   /* pointer to list of points */
};

/* Describes the beginning and ending X coordinates of a single
   horizontal line (used only by fast polygon fill code) */

struct HLine {
   int XStart; /* X coordinate of leftmost pixel in line */
   int XEnd;   /* X coordinate of rightmost pixel in line */
};

/* Describes a Length-long series of horizontal lines, all assumed to
   be on contiguous scan lines starting at YStart and proceeding
   downward (used to describe a scan-converted polygon to the
   low-level hardware-dependent drawing code) (used only by fast
   polygon fill code) */

struct HLineList {
   int Length;                /* # of horizontal lines */
   int YStart;                /* Y coordinate of topmost line */
   struct HLine * HLinePtr;   /* pointer to list of horz lines */
};

