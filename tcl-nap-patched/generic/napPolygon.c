/* 
 * napPolygon.c --
 *
 * Routines to draw and fill polygons
 *
 * Copyright (c) 1998, CSIRO Australia
 *
 * Author: P.J. Turner, CSIRO Atmospheric Research
 */

#ifndef lint
static char *rcsid="@(#) $Id: napPolygon.c,v 1.29 2006/09/29 12:38:29 dav480 Exp $";
#endif /* not lint */

/*
 * The polygon fill method is based on code in:
 *
 * Michael Abrash:
 * "Michael Abrash's Graphics Programming Black Book, Special Edition"
 * ISBN: 1-57610-174-6
 * Coriolis Group Books, Scottsdale, Arizona (http://www.coriolis.com)
 * 1997
 */

#include <math.h>
#include <sys/types.h>
#include "nap.h"
#include "nap_check.h"
#include "napPolygon.h"

struct EdgeState {
   struct EdgeState *NextEdge;
   int X;
   int StartY;
   int WholePixelXMove;
   int XDirection;
   int ErrorTerm;
   int ErrorTermAdjUp;
   int ErrorTermAdjDown;
   int Count;
};

/*
 * Local prototypes
 */

static int napDrawHorizontalLineSeg(NapClientData *nap_cd, int, int, int);
static void napBuildGET(struct PointListHeader *, struct EdgeState *,
       int, int);
static void napMoveXSortedToAET(int);
static void napScanOutAET(NapClientData *nap_cd, int YToScan);
static void napAdvanceAET(void);
static void napXSortAET(void);
static int napFillPolygon(NapClientData *nap_cd, struct PointListHeader *VertexList, int XOffset,
	int YOffset);

/*
 * Local data for both the line drawing and polygon fill.
 * More local data for the polygon fill is defined before
 * the start of the polygon fill subroutines.
 */


static size_t x_dim;	/* x dimension of the data array	*/
static size_t y_dim;	/* y dimension of the data array	*/
static float *dataPtr;  /* pointer to the start of data		*/
static float pixelFill;         /* polygon fill value   */



/*
 * Nap_DrawLine --
 *
 * Use Bresenham's line drawing algorithm
 * Bresenham, J.E., IBM systems Journal 4(1) 1965, 25-30.
 * Algorithm has been derived independently by heaps
 * of other people including the author.
 *
 * The algorithm increments the fastest varying 
 * out of x and y and works out the corresponding y and
 * x value respectively.  This results in two almost
 * identical pieces of code, one which increments x and
 * calcuates a corresponding y value and a similar piece of
 * code which increments y. The important result is that
 * every pixel in the line is filled.
 *
 */ 

static int
Nap_DrawLine(
    NapClientData       *nap_cd,
    int x1,	/* first x coordinate  */
    int y1,	/* first y coordinate  */
    int x2,	/* second x coordinate */
    int y2,	/* second y coordinate */
    float *dataPtr,	/* place to draw line */
    float value,	/* value to write line */
    size_t x_dim,	/* x dimension size	*/
    size_t y_dim)	/* y dimension size	*/
{
    int xt;	/* temporary x value */
    int yt;	/* temporary y value */
    int dx;	/* x difference (x2 - x1) */
    int dy;	/* y difference (y2 - y1) */
    int x;	/* x position	*/
    int y;	/* y position	*/
    int yincr;	/* increment in y direction */
    int xincr;	/* increment in x direction */
    int aincr;	/* increment in y direction */
    int bincr;	/* increment in y direction */
    int d;	/* variable       */
    float *pixelPtr;	/* place to write value */
    float *maxPtr;	/* upper limit on the pointer address */

    maxPtr = dataPtr + x_dim * y_dim;

/*
 * First decide if we should increment x or y!
 */

    if (abs(x2 - x1) >= abs(y2 - y1)) { 

/*
 * Force x1 < x2
 */

        if (x1 > x2) {
            xt = x1; x1 = x2; x2 = xt;
            yt = y1; y1 = y2; y2 = yt;
        }
    
        if (y2 > y1) { 
            yincr = 1; 
        } else {
            yincr = -1;
        }
            
    
        dx = x2 - x1;
        dy = abs(y2 - y1);
        d = 2 * dy - dx;
    
        aincr = 2 * (dy - dx);
        bincr = 2 * dy;
        
        x = x1;
        y = y1;
    
/*
 * Locate and set the value of the first pixel in the line
 */
    
        pixelPtr = dataPtr + x_dim * y + x;
        CHECK4((pixelPtr >= dataPtr) && (pixelPtr <= maxPtr),
                  "attempt to draw a pixel outside the data area %d,%d",x,y);

/*
 * Setting a float pixel value
 */

        *pixelPtr = value; 
    
        for(x = x1+1; x <= x2; x++) {
            if(d >= 0) {
                y = y + yincr;
                d = d + aincr;
            } else {
                d = d + bincr;
            }
    
/*
 * Setting a float pixel value
 */
    
            pixelPtr = dataPtr + x_dim * y + x;
            CHECK2((pixelPtr >= dataPtr) && (pixelPtr <= maxPtr),
                  "attempt to draw a pixel outside the data area");
            *pixelPtr = value; 
        }
    } else {

/*
 * Force y1 < y2
 */

        if (y1 > y2) {
            xt = x1; x1 = x2; x2 = xt;
            yt = y1; y1 = y2; y2 = yt;
        }
    
        if (x2 > x1) { 
            xincr = 1; 
        } else {
            xincr = -1;
        }
            
    
        dy = y2 - y1;
        dx = abs(x2 - x1);
        d = 2 * dx - dy;
    
        aincr = 2 * (dx - dy);
        bincr = 2 * dx;
        
        x = x1;
        y = y1;
    
    /*   draw the first pixel  */
    
        pixelPtr = dataPtr + x_dim * y + x;
        CHECK2((pixelPtr >= dataPtr) && (pixelPtr <= maxPtr),
              "attempt to draw a pixel outside the data area");
        *pixelPtr = value; 
    
        for(y = y1+1; y <= y2; y++) {
            if(d >= 0) {
                x = x + xincr;
                d = d + aincr;
            } else {
                d = d + bincr;
            }
    
    /*  draw a pixel  */
    
            pixelPtr = dataPtr + x_dim * y + x;
            CHECK2((pixelPtr >= dataPtr) && (pixelPtr <= maxPtr),
                  "attempt to draw a pixel outside the data area");
            *pixelPtr = value; 
        }
    }

    return TCL_OK;
}


/*
 * Nap_Polyline --
 *
 * Draw a polyline by calling Nap_DrawLine for coordinate pairs
 * in the input polygon.
 * Argument "close" specifies whether to close the polygon between
 * the last and first points.
 */

EXTERN int
Nap_Polyline(
    NapClientData       *nap_cd,
    int *px,		/* x polygon points  */
    int *py,		/* y polygon points  */
    size_t n,		/* number of polygon points */
    float *dataPtr,	/* place to draw line */
    float value,	/* value to write line */
    size_t x_dim,	/* x dimension size	*/
    size_t y_dim,	/* y dimension size	*/
    int close)		/* Close the polygon? */
{
    size_t i;	/* counter	*/
    int	status;	/* error code */



    for(i = 1; i < n; i++) {
        status = Nap_DrawLine(nap_cd, px[i-1], py[i-1], px[i], py[i], dataPtr,
		value, x_dim, y_dim);
	CHECK2(status == TCL_OK, "Nap_Polyline: error calling Nap_DrawLine");
    }
    if(close) {
        status = Nap_DrawLine(nap_cd, px[n-1], py[n-1], px[0], py[0], dataPtr,
		value, x_dim, y_dim);
	CHECK2(status == TCL_OK, "Nap_Polyline: error calling Nap_DrawLine");
    }
    return TCL_OK;
}

/*
 * Nap_InitFill --
 *
 * Initialise data space and border and fill values.
 */

static int
Nap_InitFill(
    float fill,         /* fill value   */
    float border,       /* border value */
    float *data,        /* pointer to start of data array       */
    size_t x,           /* data x dimension     */
    size_t y)           /* data y dimension     */
{
    dataPtr = data;
    x_dim = x;
    y_dim = y;
    pixelFill = fill;
    return TCL_OK;
}


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

{
    typedef struct Point point;
    typedef struct PointListHeader polygon;
    point *xyPtr;
    polygon *Polygon;

    int status;
    int i;

    status = Nap_Polyline(nap_cd, px,py,n,dataPtr,fill, x_dim, y_dim, 1);
    CHECK(status == TCL_OK);

    status = Nap_InitFill(fill,fill,dataPtr,x_dim,y_dim);
    CHECK2(status == TCL_OK, "Nap_Polyfill: error calling Nap_InitFill");

    xyPtr = (point *)NAP_ALLOC(nap_cd, sizeof(point)*n);
    Polygon = (polygon *)NAP_ALLOC(nap_cd, sizeof(polygon));

    for(i=0; i < n; i++) {
        xyPtr[i].X = px[i];
        xyPtr[i].Y = py[i];
    }
    Polygon->Length = n; 
    Polygon->PointPtr = xyPtr;

    status = napFillPolygon(nap_cd, Polygon,0,0);
    CHECK(status == TCL_OK);

    NAP_FREE(nap_cd, xyPtr);
    NAP_FREE(nap_cd, Polygon);

    return(TCL_OK);
}


/*
 * Fills an arbitrarily-shaped polygon described by VertexList.
 * If the first and last points in VertexList are not the same, the path
 * around the polygon is automatically closed. All vertices are offset
 * by (XOffset, YOffset). 
 * The code will handle complex polygons.
 *
 */


#define SWAP(a,b) {temp = a; a = b; b = temp;}

/* Pointers to global edge table (GET) and active edge table (AET) */

static struct EdgeState *GETPtr, *AETPtr;

static int napFillPolygon(
    NapClientData       	*nap_cd,
    struct PointListHeader	*VertexList,	/* Polygon points */
    int				XOffset,	/* offsets to x values */
    int				YOffset)	/* ofset to y values */
{
    struct EdgeState *EdgeTableBuffer;
    int CurrentY;

/*
 * It takes a minimum of 3 vertices to cause any pixels to be
 * drawn; reject polygons that are guaranteed to be invisible
 * In this case nap_PolyLine will draw, nothing, a point or a line. 
 */

    if(VertexList->Length < 3) {
        return TCL_OK;
    }

/*
 *  Get enough memory to store the entire edge table
 */

    if((EdgeTableBuffer =
        (struct EdgeState *) (NAP_ALLOC(nap_cd, sizeof(struct EdgeState) *
        VertexList->Length))) == NULL) {
        CHECK2(0, "napFillPolygon: Couldn't get memory for the edge table");
    }

/*
 * Build the global edge table
 */

    napBuildGET(VertexList, EdgeTableBuffer, XOffset, YOffset);

/*
 * Scan down through the polygon edges, one scan line at a time,
 * so long as at least one edge remains in either the GET or AET
 */

    AETPtr = NULL;    /* initialize the active edge table to empty */
    CurrentY = GETPtr->StartY; /* start at the top polygon vertex */

    while ((GETPtr != NULL) || (AETPtr != NULL)) {
       napMoveXSortedToAET(CurrentY);  /* update AET for this scan line */
       napScanOutAET(nap_cd, CurrentY);        /* draw this scan line from AET */
       napAdvanceAET();                /* advance AET edges 1 scan line */
       napXSortAET();                  /* resort on X */
       CurrentY++;                     /* advance to the next scan line */
    }

/*
 * Release the memory we've allocated and we're done
 */

    NAP_FREE(nap_cd, EdgeTableBuffer);
    return TCL_OK;
}

/* napBuildGet--
 *
 * Creates a GET in the buffer pointed to by NextFreeEdgeStruc from
 * the vertex list. Edge endpoints are flipped, if necessary, to
 * guarantee all edges go top to bottom. The GET is sorted primarily
 * by ascending Y start coordinate, and secondarily by ascending X
 * start coordinate within edges with common Y coordinates
 */

static void
napBuildGET(
    struct PointListHeader * VertexList,
    struct EdgeState * NextFreeEdgeStruc,
    int XOffset,
    int YOffset
)

{
    int i, StartX, StartY, EndX, EndY, DeltaY, DeltaX, Width, temp;
    struct EdgeState *NewEdgePtr;
    struct EdgeState *FollowingEdge, **FollowingEdgeLink;
    struct Point *VertexPtr;

/*
 * Scan through the vertex list and put all non-0-height edges into
 * the GET, sorted by increasing Y start coordinate
 */

    VertexPtr = VertexList->PointPtr;   /* point to the vertex list */
    GETPtr = NULL;                      /* initialize the global edge table to empty */

    for(i = 0; i < VertexList->Length; i++) {
        /* Calculate the edge height and width */
        StartX = VertexPtr[i].X + XOffset;
        StartY = VertexPtr[i].Y + YOffset;

        /* The edge runs from the current point to the previous one */

        if (i == 0) {
            /* Wrap back around to the end of the list */
            EndX = VertexPtr[VertexList->Length-1].X + XOffset;
            EndY = VertexPtr[VertexList->Length-1].Y + YOffset;
        } else {
            EndX = VertexPtr[i-1].X + XOffset;
            EndY = VertexPtr[i-1].Y + YOffset;
        }

        /* Make sure the edge runs top to bottom */

        if (StartY > EndY) {
            SWAP(StartX, EndX);
            SWAP(StartY, EndY);
        }

        /* Skip if this can't ever be an active edge (has 0 height) */
 
        if ((DeltaY = EndY - StartY) != 0) {
/*
 * Allocate space for this edge's info, and fill in the
 * structure
 */
            NewEdgePtr = NextFreeEdgeStruc++;
            /* direction in which X moves */
            NewEdgePtr->XDirection = ((DeltaX = EndX - StartX) > 0) ? 1 : -1;
            Width = abs(DeltaX);
            NewEdgePtr->X = StartX;
            NewEdgePtr->StartY = StartY;
            NewEdgePtr->Count = DeltaY;
            NewEdgePtr->ErrorTermAdjDown = DeltaY;

            if (DeltaX >= 0) {  /* initial error term going L->R */
                NewEdgePtr->ErrorTerm = 0;
            } else {              /* initial error term going R->L */
                NewEdgePtr->ErrorTerm = -DeltaY + 1;
            }

            if (DeltaY >= Width) {     /* Y-major edge */
                NewEdgePtr->WholePixelXMove = 0;
                NewEdgePtr->ErrorTermAdjUp = Width;
            } else {                   /* X-major edge */
                NewEdgePtr->WholePixelXMove = (Width / DeltaY) * NewEdgePtr->XDirection;
                NewEdgePtr->ErrorTermAdjUp = Width % DeltaY;
            }
/*
 * Link the new edge into the GET so that the edge list is
 * still sorted by Y coordinate, and by X coordinate for all
 * edges with the same Y coordinate
 */

            FollowingEdgeLink = &GETPtr;
            for (;;) {
               FollowingEdge = *FollowingEdgeLink;
               if ((FollowingEdge == NULL) ||
                     (FollowingEdge->StartY > StartY) ||
                     ((FollowingEdge->StartY == StartY) &&
                     (FollowingEdge->X >= StartX))) {
                  NewEdgePtr->NextEdge = FollowingEdge;
                  *FollowingEdgeLink = NewEdgePtr;
                  break;
               }
               FollowingEdgeLink = &FollowingEdge->NextEdge;
            }
        }
    }
}

/*
 * napXSortAET--
 * Sorts all edges currently in the active edge table into ascending
 * order of current X coordinates
 */

static void
napXSortAET() {
    struct EdgeState *CurrentEdge, **CurrentEdgePtr, *TempEdge;
    int SwapOccurred;

/*
 *  Scan through the AET and swap any adjacent edges for which the
 *  second edge is at a lower current X coord than the first edge.
 * Repeat until no further swapping is needed
 */

    if (AETPtr != NULL) {
        do {
            SwapOccurred = 0;
            CurrentEdgePtr = &AETPtr;
            while ((CurrentEdge = *CurrentEdgePtr)->NextEdge != NULL) {
               if (CurrentEdge->X > CurrentEdge->NextEdge->X) {
                /* The second edge has a lower X than the first;
                   swap them in the AET */
                   TempEdge = CurrentEdge->NextEdge->NextEdge;
                   *CurrentEdgePtr = CurrentEdge->NextEdge;
                   CurrentEdge->NextEdge->NextEdge = CurrentEdge;
                   CurrentEdge->NextEdge = TempEdge;
                   SwapOccurred = 1;
               }
               CurrentEdgePtr = &(*CurrentEdgePtr)->NextEdge;
            }
        } while (SwapOccurred != 0);
    }
}

/*
 * napAdvanceAet--
 *
 * Advances each edge in the AET by one scan line.
 * Removes edges that have been fully scanned.
 */

static void
napAdvanceAET() {
    struct EdgeState *CurrentEdge, **CurrentEdgePtr;

   /* Count down and remove or advance each edge in the AET */
    CurrentEdgePtr = &AETPtr;
    while ((CurrentEdge = *CurrentEdgePtr) != NULL) {
       /* Count off one scan line for this edge */
        if ((--(CurrentEdge->Count)) == 0) {
           /* This edge is finished, so remove it from the AET */
            *CurrentEdgePtr = CurrentEdge->NextEdge;
        } else {
           /* Advance the edge's X coordinate by minimum move */
            CurrentEdge->X += CurrentEdge->WholePixelXMove;
           /* Determine whether it's time for X to advance one extra */
            if ((CurrentEdge->ErrorTerm += CurrentEdge->ErrorTermAdjUp) > 0) {
                CurrentEdge->X += CurrentEdge->XDirection;
                CurrentEdge->ErrorTerm -= CurrentEdge->ErrorTermAdjDown;
            }
            CurrentEdgePtr = &CurrentEdge->NextEdge;
        }
    }
}

/*
 * napMoveXSortedToAET--
 * Moves all edges that start at the specified Y coordinate from the
 * GET to the AET, maintaining the X sorting of the AET.
 */

static void
napMoveXSortedToAET(int YToMove) {
    struct EdgeState *AETEdge, **AETEdgePtr, *TempEdge;
    int CurrentX;

/*
 * The GET is Y sorted. Any edges that start at the desired Y
 * coordinate will be first in the GET, so we'll move edges from
 * the GET to AET until the first edge left in the GET is no longer
 * at the desired Y coordinate. Also, the GET is X sorted within
 * each Y coordinate, so each successive edge we add to the AET is
 * guaranteed to belong later in the AET than the one just added
 */

    AETEdgePtr = &AETPtr;
    while ((GETPtr != NULL) && (GETPtr->StartY == YToMove)) {
        CurrentX = GETPtr->X;
       /* Link the new edge into the AET so that the AET is still
          sorted by X coordinate */
        for (;;) {
            AETEdge = *AETEdgePtr;
            if ((AETEdge == NULL) || (AETEdge->X >= CurrentX)) {
                TempEdge = GETPtr->NextEdge;
                *AETEdgePtr = GETPtr;  /* link the edge into the AET */
                GETPtr->NextEdge = AETEdge;
                AETEdgePtr = &GETPtr->NextEdge;
                GETPtr = TempEdge;   /* unlink the edge from the GET */
                break;
            } else {
                AETEdgePtr = &AETEdge->NextEdge;
            }
        }
    }
}

/*
 * napScanOutAET --
 * Fills the scan line described by the current AET at the specified Y
 * coordinate in the specified color, using the odd/even fill rule
 */

static void
napScanOutAET(
    NapClientData       *nap_cd,
    int			YToScan)
{
    int LeftX;
    struct EdgeState *CurrentEdge;

/* Scan through the AET, drawing line segments as each pair of edge
 * crossings is encountered. The nearest pixel on or to the right
 * of left edges is drawn, and the nearest pixel to the left of but
 * not on right edges is drawn
 */

    CurrentEdge = AETPtr;
    while (CurrentEdge != NULL) {
        LeftX = CurrentEdge->X;
        CurrentEdge = CurrentEdge->NextEdge;
        napDrawHorizontalLineSeg(nap_cd, YToScan, LeftX, CurrentEdge->X-1);
        CurrentEdge = CurrentEdge->NextEdge;
    }
}

/*
 * napDrawHorizontalLineSeg--
 *
 * Draws all pixels in the horizontal line segment passed in, from
 * (leftX,y) to (rightX,y). Both leftX and rightX are drawn. No
 * drawing will take place if leftX > rightX.
 *
 * P.J. Turner CSIRO Atmospheric Research April 2000 
 */


static int
napDrawHorizontalLineSeg(
    NapClientData       *nap_cd,
    int y,
    int leftX,
    int rightX
)
{

/*
 * Draw each pixel in the horizontal line segment, starting with
 * the leftmost one
 */
    int status;
    
    if(leftX <= rightX) { 
        status = Nap_DrawLine(nap_cd, leftX, y, rightX, y,dataPtr,pixelFill,x_dim,y_dim);
        CHECK(status == TCL_OK);
    }
    return TCL_OK;

}


