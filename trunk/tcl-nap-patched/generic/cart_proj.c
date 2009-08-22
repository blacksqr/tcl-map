/* 
 * cart_proj.c --
 *
 * Define NAP functions for cartographic projections.
 *
 * Based on the PROJ.4 Cartographic Projections library originally written by
 * Gerald Evenden then of the USGS.
 * See web page http://www.remotesensing.org/proj
 *
 * Copyright 2005, CSIRO Australia
 * Author: Harvey Davies, CSIRO Marine & Atmospheric Research
 */

#ifndef lint
static char *rcsid="@(#) $Id: cart_proj.c,v 1.13 2006/06/30 04:42:42 dav480 Exp $";
#endif /* not lint */

#include <math.h>

#include <proj_api.h>
#include "nap.h"
#include "nap_check.h"

/*
 *  distance(p1,p2) gives distance between points p1 & p2
 */

#undef  distance
#define distance(p1,p2) hypot(p1.u - p2.u, p1.v - p2.v)

#undef  TEXT0
#define TEXT0 "Nap_cart_proj_fwd: "

/*
 *  Nap_cart_proj_fwd --
 *
 *  NAP function 'cart_proj_fwd(PROJ_SPEC, LAT, LON)'
 *
 *  PROJ_SPEC is a c8 NAO containing PROJ.4 projection specification
 *
 *  LAT is NAO containing latitudes.
 *  LON is NAO containing longitudes.
 *  LON & LAT can have any ranks & these can differ.
 *  The sizes of their trailing dimensions must match.
 *  If LON or LAT has no unit then this defaults to degrees.
 *
 *  The result contains eastings & northings in metres.
 *  It's rank is 1 + (rank(LAT) >>> rank(LON)).
 *  The new least significant dimension has size 2.
 *  Eastings are in column 0.  Northings are in column 1.
 */

#undef  TEXT0
#define TEXT0 "Nap_cart_proj_fwd: "

EXTERN char *
Nap_cart_proj_fwd(
    NapClientData	*nap_cd, 
    Nap_NAO		*box_nao)		/* points to user's arguments */
{
    int			argc;			/* number of elements in PROJ_SPEC */
    char		**argv;			/* PROJ_SPEC */
    int			i;
    int			i1;
    int			i2;
    Nap_NAO		*lat;			/* LATITUDE argument */
    double		lat_factor=DEG_TO_RAD;	/* scale factor for latitude */
    Nap_NAO		*lon;			/* LONGITUDE argument */
    double		lon_factor=DEG_TO_RAD;	/* scale factor for longitude */
    projUV		lon_lat;		/* Point (lon,lat) */
    size_t		n;			/* nels(x) == nels(y) */
    projPJ		pjs;			/* PROJ.4 main structure */
    Nap_NAO		*proj_spec;		/* PROJ_SPEC argument */
    int			rank;			/* of x & y */
    Nap_NAO		*result;		/* result as NAO */
    size_t		*shape;			/* of x & y */
    size_t		shape_result[NAP_MAX_RANK];
    int			status;			/* error code */
    Nap_NAO		*tmp_nao;
    projUV		xy;			/* Point (X,Y) */

    assert(box_nao);
    assert(box_nao->dataType == NAP_BOXED);
    Nap_IncrRefCount(nap_cd, box_nao);
    CHECK2NULL(box_nao->rank == 1, TEXT0 "box_nao rank not 1");
    CHECK2NULL(box_nao->nels == 3,  TEXT0 "Not exactly 3 arguments");

    proj_spec = Nap_GetNaoFromSlot(box_nao->data.Boxed[0]);
    CHECK2NULL(proj_spec, TEXT0 "Error calling Nap_GetNaoFromSlot");
    CHECK2NULL(proj_spec->dataType == NAP_C8, TEXT0 "PROJ_SPEC argument not type c8");
    CHECK2NULL(proj_spec->rank == 1, TEXT0 "PROJ_SPEC argument has rank != 1");
    Nap_IncrRefCount(nap_cd, proj_spec);
    status = Tcl_SplitList(nap_cd->interp, proj_spec->data.c, &argc, (CONST char***) &argv);
    CHECK2NULL(status == TCL_OK, TEXT0 "PROJ_SPEC argument is not legal list");
    CHECK2NULL(argc > 0, TEXT0 "PROJ_SPEC argument is empty");
    pjs = pj_init(argc, argv);
    CHECK3NULL(pjs, TEXT0 "Projection initialization failed because: %s",
	    pj_strerrno(pj_errno));
    Tcl_Free((char *) argv);
    Nap_DecrRefCount(nap_cd, proj_spec);

    tmp_nao = Nap_GetNaoFromSlot(box_nao->data.Boxed[1]);
    CHECK2NULL(tmp_nao, TEXT0 "Error calling Nap_GetNaoFromSlot");
    if (tmp_nao->unit  &&  isPrefixOf("radian", tmp_nao->unit))  lat_factor = 1.0;
    lat = Nap_CastNAO(nap_cd, tmp_nao, NAP_F64);
    CHECK2NULL(lat, TEXT0 "Error calling Nap_CastNAO");
    Nap_IncrRefCount(nap_cd, lat);

    tmp_nao = Nap_GetNaoFromSlot(box_nao->data.Boxed[2]);
    CHECK2NULL(tmp_nao, TEXT0 "Error calling Nap_GetNaoFromSlot");
    if (tmp_nao->unit  &&  isPrefixOf("radian", tmp_nao->unit))  lon_factor = 1.0;
    lon = Nap_CastNAO(nap_cd, tmp_nao, NAP_F64);
    CHECK2NULL(lon, TEXT0 "Error calling Nap_CastNAO");
    Nap_IncrRefCount(nap_cd, lon);

    if (lon->rank > lat->rank) {
	rank = lon->rank;
	shape = lon->shape;
    } else {
	rank = lat->rank;
	shape = lat->shape;
    }

    for (i = 0; i < rank; i++) {
	i1 = lon->rank + i - rank;
	i2 = lat->rank + i - rank;
	CHECK4NULL(i1 < 0  ||  i2 < 0  ||  lon->shape[i1] == lat->shape[i2],
		"m4NAME: Dimension %d of latitude has different size from "
		"dimension %d of longitude", i1, i2);
	shape_result[i] = shape[i];
    }
    shape_result[rank] = 2;
    result = Nap_NewNAO(nap_cd, NAP_F64, rank+1, shape_result);
    CHECK2NULL(result, TEXT0 "Error calling Nap_NewNAO");
    result->unit = Nap_StrDup(nap_cd, "metres");
    n = result->nels / 2;
    for (i = 0; i < n; i++) {
	result->data.F64[2*i  ] = napF64NaN;
	result->data.F64[2*i+1] = napF64NaN;
	i1 = i % lon->nels;
	i2 = i % lat->nels;
	if (! IsMissing(lon, i1)  &&  ! IsMissing(lat, i2)) {
	    lon_lat.u = lon_factor * lon->data.F64[i1];
	    lon_lat.v = lat_factor * lat->data.F64[i2];
	    xy = pj_fwd(lon_lat, pjs);
	    if (xy.u != HUGE_VAL) {
		result->data.F64[2*i  ] = xy.u;
		result->data.F64[2*i+1] = xy.v;
	    }
	}
    }
    pj_free(pjs);
    Nap_DecrRefCount(nap_cd, lat);
    Nap_DecrRefCount(nap_cd, lon);
    Nap_DecrRefCount(nap_cd, box_nao);
    return result->id;
}

/*
 *  Nap_cart_proj_inv --
 *
 *  NAP function 'cart_proj_inv(PROJ_SPEC, X, Y)'
 *
 *  PROJ_SPEC is a c8 NAO containing PROJ.4 projection specification
 *
 *  X is NAO containing eastings (metres).
 *  Y is NAO containing northings (metres).
 *  X & Y can have any ranks & these can differ.
 *  The sizes of their trailing dimensions must match.
 *
 *  The result contains latitudes & longitudes in degrees.
 *  It's rank is 1 + (rank(X) >>> rank(Y)).
 *  The new least significant dimension has size 2.
 *  Latitudes are in column 0.  Longitudes are in column 1.
 */

#undef  TEXT0
#define TEXT0 "Nap_cart_proj_inv: "

EXTERN char *
Nap_cart_proj_inv(
    NapClientData	*nap_cd, 
    Nap_NAO		*box_nao)		/* points to user's arguments */
{
    int			argc;			/* number of elements in PROJ_SPEC */
    char		**argv;			/* PROJ_SPEC */
    double		d;			/* distance between 2 points in x/y space */
    const double	dmax = 0.5;		/* max. allowable value for d (metres) */
    int			i;
    int			i1;
    int			i2;
    Nap_NAO		*lat;			/* latitude */
    Nap_NAO		*lon;			/* longitude */
    projUV		lon_lat;		/* Point (lon,lat) */
    size_t		n;			/* nels(x) == nels(y) */
    projPJ		pjs;			/* PROJ.4 main structure */
    Nap_NAO		*proj_spec;		/* PROJ_SPEC argument */
    int			rank;			/* of x & y */
    Nap_NAO		*result;		/* result as NAO */
    size_t		*shape;			/* of x & y */
    size_t		shape_result[NAP_MAX_RANK];
    int			status;			/* error code */
    Nap_NAO		*tmp_nao;
    Nap_NAO		*x;			/* x (easting) */
    projUV		xy;			/* Point (X,Y) from arguments */
    projUV		xy1;			/* Point (x1,y1) produced from (lon,lat) */
    Nap_NAO		*y;			/* y (northing) */

    assert(box_nao);
    assert(box_nao->dataType == NAP_BOXED);
    Nap_IncrRefCount(nap_cd, box_nao);
    CHECK2NULL(box_nao->rank == 1, TEXT0 "box_nao rank not 1");
    CHECK2NULL(box_nao->nels == 3,  TEXT0 "Not exactly 3 arguments");

    proj_spec = Nap_GetNaoFromSlot(box_nao->data.Boxed[0]);
    CHECK2NULL(proj_spec, TEXT0 "Error calling Nap_GetNaoFromSlot");
    CHECK2NULL(proj_spec->dataType == NAP_C8, TEXT0 "PROJ_SPEC argument not type c8");
    CHECK2NULL(proj_spec->rank == 1, TEXT0 "PROJ_SPEC argument has rank != 1");
    Nap_IncrRefCount(nap_cd, proj_spec);
    status = Tcl_SplitList(nap_cd->interp, proj_spec->data.c, &argc, (CONST char***) &argv);
    CHECK2NULL(status == TCL_OK, TEXT0 "PROJ_SPEC argument is not legal list");
    CHECK2NULL(argc > 0, TEXT0 "PROJ_SPEC argument is empty");
    pjs = pj_init(argc, argv);
    CHECK3NULL(pjs, TEXT0 "Projection initialization failed because: %s",
	    pj_strerrno(pj_errno));
    Tcl_Free((char *) argv);
    Nap_DecrRefCount(nap_cd, proj_spec);

    tmp_nao = Nap_GetNaoFromSlot(box_nao->data.Boxed[1]);
    CHECK2NULL(tmp_nao, TEXT0 "Error calling Nap_GetNaoFromSlot");
    x = Nap_CastNAO(nap_cd, tmp_nao, NAP_F64);
    CHECK2NULL(x, TEXT0 "Error calling Nap_CastNAO");
    Nap_IncrRefCount(nap_cd, x);

    tmp_nao = Nap_GetNaoFromSlot(box_nao->data.Boxed[2]);
    CHECK2NULL(tmp_nao, TEXT0 "Error calling Nap_GetNaoFromSlot");
    y = Nap_CastNAO(nap_cd, tmp_nao, NAP_F64);
    CHECK2NULL(y, TEXT0 "Error calling Nap_CastNAO");
    Nap_IncrRefCount(nap_cd, y);

    if (x->rank > y->rank) {
	rank = x->rank;
	shape = x->shape;
    } else {
	rank = y->rank;
	shape = y->shape;
    }
    for (i = 0; i < rank; i++) {
	i1 = x->rank + i - rank;
	i2 = y->rank + i - rank;
	CHECK4NULL(i1 < 0  ||  i2 < 0  ||  x->shape[i1] == y->shape[i2],
		"m4NAME: Dimension %d of latitude has different size from "
		"dimension %d of longitude", i1, i2);
	shape_result[i] = shape[i];
    }
    shape_result[rank] = 2;
    result = Nap_NewNAO(nap_cd, NAP_F64, rank+1, shape_result);
    CHECK2NULL(result, TEXT0 "Error calling Nap_NewNAO");
    result->unit = Nap_StrDup(nap_cd, "degrees");
    n = result->nels / 2;
    for (i = 0; i < n; i++) {
	result->data.F64[2*i  ] = napF64NaN;
	result->data.F64[2*i+1] = napF64NaN;
	i1 = i % x->nels;
	i2 = i % y->nels;
	if (! IsMissing(x, i1)  &&  ! IsMissing(y, i2)) {
	    xy.u = x->data.F64[i1];
	    xy.v = y->data.F64[i2];
	    lon_lat = pj_inv(xy, pjs);
	    xy1 = pj_fwd(lon_lat, pjs);	/* Check whether result maps back to arg */
	    if (lon_lat.u != HUGE_VAL  &&  distance(xy,xy1) < dmax) {
		result->data.F64[2*i  ] = RAD_TO_DEG * lon_lat.v;
		result->data.F64[2*i+1] = RAD_TO_DEG * lon_lat.u;
	    }
	}
    }
    pj_free(pjs);
    Nap_DecrRefCount(nap_cd, y);
    Nap_DecrRefCount(nap_cd, x);
    Nap_DecrRefCount(nap_cd, box_nao);
    return result->id;
}
