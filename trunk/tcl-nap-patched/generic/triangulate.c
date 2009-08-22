/* 
 * triangulate.c --
 *
 * Define two NAP functions for Delaunay triangulation.
 * Function 'triangulate' returns triangles.
 * Function 'triangulate_edges' returns edges.
 *
 * Usage:
 *   triangulate(SITES)
 *   triangulate_edges(SITES)
 *     where SITES is a matrix defining the points (x,y).
 *     Column 0 contains x.
 *     Column 1 contains y.
 *     Any other columns are ignored.
 *
 * The result is an i32 matrix of site indices.
 * For 'triangulate' each row of the result contains 3 values defining a triangle.
 * For 'triangulate_edges' each row of the result contains 2 values defining an edge.
 */

/*   Author: Geoff Leach, Department of Computer Science, RMIT.
 *   email: gl@cs.rmit.edu.au
 *
 *   Date: 6/10/93
 *
 *   Version 1.0
 *   
 *   Copyright (c) RMIT 1993. All rights reserved.
 *
 *   License to copy and use this software purposes is granted provided 
 *   that appropriate credit is given to both RMIT and the author.
 *
 *   License is also granted to make and use derivative works provided
 *   that appropriate credit is given to both RMIT and the author.
 *
 *   RMIT makes no representations concerning either the merchantability 
 *   of this software or the suitability of this software for any particular 
 *   purpose.  It is provided "as is" without express or implied warranty 
 *   of any kind.
 *
 *   These notices must be retained in any copies of any part of this software.
 */

/* 
 * Modified for NAP by Harvey Davies, CSIRO Atmospheric Research in July 2004.
 */

/* 
 * Following is start of Leach's README file:
 *
 * The program implements the worst-case optimal divide-and-conquer Delaunay
 * triangulation algorithm as described in:
 *
 *       Guibas, L. and Stolfi, J., "Primitives for the Manipulation
 *       of General Subdivisions and the Computation of Voronoi Diagrams, ",
 *       ACT TOG, 4(2), April, 1985.
 *
 * The algorithm is O(nlogn) time and O(n) space.
 *
 * Some changes have been made (for speed).  The InCircle test is different
 * to the one described in the paper and the winged-edge structure is used
 * instead of the quad-edge data structure.
 */

#ifndef lint
static char *rcsid="@(#) $Id: triangulate.c,v 1.6 2006/10/09 02:30:39 dav480 Exp $";
#endif /* not lint */

#include  <stddef.h>
#include  <stdio.h>
#include  <stdlib.h>

#include "nap.h"
#include "nap_check.h"
#include  "triangulate.h"

/* global data */

static point *p_array;
static edge *e_array;
static edge **free_list_e;
static cardinal n_free_e;

/* Declarations */

void divide(point *p_sorted[], tri_index l, tri_index r, edge **l_ccw, edge **r_cw);

edge *join(edge *a, point *u, edge *b, point *v, side s);

void delete_edge(edge *e);

void splice(edge *a, edge *b, point *v);

edge *make_edge(point *u, point *v);

static void lower_tangent(edge *r_cw_l, point *s, edge *l_ccw_r, point *u,
			  edge **l_lower, point **org_l_lower,
			  edge **r_lower, point **org_r_lower);

static void merge(edge *r_cw_l, point *s, edge *l_ccw_r, point *u, edge **l_tangent);

/*
 * Allocate memory. Return 0 if OK
 */

static int
alloc_memory(
    NapClientData	*nap_cd, 
    cardinal		n)
{
    edge *e;
    tri_index i;

    /* Point storage. */
    p_array = (point *) NAP_ALLOC(nap_cd, n * sizeof(point));
    if (! p_array) {
        return 1;
    }
    /* Edges. */
    n_free_e = 3 * n;   /* Eulers relation */
    e_array = e = (edge *) NAP_ALLOC(nap_cd, n_free_e * sizeof(edge));
    if (p_array) {
	for (i = 0; i < n_free_e; i++) {
	    e_array[i].org   = NULL;
	    e_array[i].dest  = NULL;
	    e_array[i].onext = NULL;
	    e_array[i].oprev = NULL;
	    e_array[i].dnext = NULL;
	    e_array[i].dprev = NULL;
	}
    } else {
        return 1;
    }
    free_list_e = (edge **) NAP_ALLOC(nap_cd, n_free_e * sizeof(edge *));
    if (free_list_e) {
	for (i = 0; i < n_free_e; i++, e++) {
	    free_list_e[i] = e;
	}
    } else {
        return 1;
    }
    return 0;
}

void free_memory(
    NapClientData	*nap_cd) 
{
  NAP_FREE(nap_cd, p_array);  
  NAP_FREE(nap_cd, e_array);  
  NAP_FREE(nap_cd, free_list_e);  
}

edge *get_edge()
{
    assert(n_free_e > 0);	/* malloc error */
    return (free_list_e[--n_free_e]);
}

void free_edge(edge *e)
{
   free_list_e[n_free_e++] = e;
}

void merge_sort(point *p[], point *p_temp[], tri_index l, tri_index r)
{
  tri_index i, j, k, m;

  if (r - l > 0)
  {
    m = (r + l) / 2;
    merge_sort(p, p_temp, l, m);
    merge_sort(p, p_temp, m+1, r);

    for (i = m+1; i > l; i--)
      p_temp[i-1] = p[i-1];
    for (j = m; j < r; j++)
      p_temp[r+m-j] = p[j+1];
    for (k = l; k <= r; k++)
      if (p_temp[i]->x < p_temp[j]->x) {
        p[k] = p_temp[i];
        i = i + 1;
      } else if (p_temp[i]->x == p_temp[j]->x && p_temp[i]->y < p_temp[j]->y) {
        p[k] = p_temp[i];
        i = i + 1;
      } else {
        p[k] = p_temp[j];
        j = j - 1;
      }
  }
}

/* 
 *  Define the ring of edges about each vertex.
 *  Return no. rows (edges) in result (-1 for error)
 */

static int 
define_edges(
    cardinal		n,		/* no. sites */
    int			nr_result_max,	/* max. no. rows in 'result' */
    int			nc_result,	/* no. columns in 'result' (2 for edges, 3 for triangles) */
    int			*result)	/* matrix result (out) */
{
    edge		*e;
    edge		*e_start;
    tri_index		i;
    tri_index		nrows = 0;		/* no. rows defined so far */
    point		*u;
    point		*v;

    for (i = 0; i < n; i++) {
        u = &p_array[i];
        e_start = e = u->entry_pt;
        do {
            v = Other_point(e, u);
            if (u < v)
		if (nrows < nr_result_max) {
		    result[nc_result * nrows    ] = u - p_array;
		    result[nc_result * nrows + 1] = v - p_array;
		    ++nrows;
		} else {
		    return -1;
		}
            e = Next(e, u);
        } while (!Identical_refs(e, e_start));
    }
    return nrows;
}

/* 
 *  Define the ring of triangles about each vertex.
 *  Return no. rows (triangles) in result (-1 for error)
 */

static int 
define_triangles(
    cardinal		n,		/* no. sites */
    int			nr_result_max,	/* max. no. rows in 'result' */
    int			nc_result,	/* no. columns in 'result' (2 for edges, 3 for triangles) */
    int			*result)	/* matrix result (out) */
{
    edge		*e;
    edge		*e_start;
    edge		*next;
    tri_index		i;
    tri_index		nrows = 0;		/* no. rows defined so far */
    point		*t;
    point		*u;
    point		*v;
    point		*w;

    for (i = 0; i < n; i++) {
	u = &p_array[i];
	e_start = e = u->entry_pt;
	do {
	    v = Other_point(e, u);
	    if (u < v) {
	        next = Next(e, u);
	        w = Other_point(next, u);
	        if (u < w) {
		    if (Identical_refs(Next(next, w), Prev(e, v))) {  
		        /* Triangle. */
		        if (v > w) {
			    t = v;
			    v = w;
			    w = t;
			}
			if (nrows < nr_result_max) {
			    result[nc_result * nrows    ] = u - p_array;
			    result[nc_result * nrows + 1] = v - p_array;
			    result[nc_result * nrows + 2] = w - p_array;
			    ++nrows;
			} else {
			    return -1;
			}
		    }
		}
	    }
	    /* Next edge around u. */
	    e = Next(e, u);
	} while (!Identical_refs(e, e_start));
    }
    return nrows;
}

/* 
 *  Creates a new edge and adds it to two rings of edges.
 */
edge *join(edge *a, point *u, edge *b, point *v, side s)
{
  edge *e;

  /* u and v are the two vertices which are being joined.
     a and b are the two edges associated with u and v res.  */

  e = make_edge(u, v);
  
  if (s == left) {
    if (Org(a) == u)
      splice(Oprev(a), e, u);
    else
      splice(Dprev(a), e, u);
    splice(b, e, v);
  } else {
    splice(a, e, u);
    if (Org(b) == v)
      splice(Oprev(b), e, v);
    else
      splice(Dprev(b), e, v);
  }

  return e;
}

/* 
 *  Remove an edge.
 */
void delete_edge(edge *e)
{
  point *u, *v;

  /* Cache origin and destination. */
  u = Org(e);
  v = Dest(e);

  /* Adjust entry points. */
  if (u->entry_pt == e)
    u->entry_pt = e->onext;
  if (v->entry_pt == e)
    v->entry_pt = e->dnext;

   /* Four edge links to change */
  if (Org(e->onext) == u)
    e->onext->oprev = e->oprev;
  else
    e->onext->dprev = e->oprev;

  if (Org(e->oprev) == u)
    e->oprev->onext = e->onext;
  else
    e->oprev->dnext = e->onext;

  if (Org(e->dnext) == v)
    e->dnext->oprev = e->dprev;
  else
    e->dnext->dprev = e->dprev;

  if (Org(e->dprev) == v)
    e->dprev->onext = e->dnext;
  else
    e->dprev->dnext = e->dnext;

  free_edge(e);
}

/* 
 *  Add an edge to a ring of edges. 
 */
void splice(edge *a, edge *b, point *v)
{
  edge *next;

  
  /* b must be the unnattached edge and a must be the previous 
     ccw edge to b. */

  if (Org(a) == v) { 
    next = Onext(a);
    Onext(a) = b;
  } else {
    next = Dnext(a);
    Dnext(a) = b;
  }

  if (Org(next) == v)
    Oprev(next) = b;
  else
    Dprev(next) = b;

  if (Org(b) == v) {
    Onext(b) = next;
    Oprev(b) = a;
  } else {
    Dnext(b) = next;
    Dprev(b) = a;
  }
}

/*
 *  Initialise a new edge.
 */
edge *make_edge(point *u, point *v)
{
  edge *e;

  e = get_edge();

  e->onext = e->oprev = e->dnext = e->dprev = e;
  e->org = u;
  e->dest = v;
  if (u->entry_pt == NULL)
    u->entry_pt = e;
  if (v->entry_pt == NULL)
    v->entry_pt = e;
  

  return e;
}

void divide(point *p_sorted[], tri_index l, tri_index r, edge **l_ccw, edge **r_cw)
{
  cardinal n;
  tri_index split;
  edge *l_ccw_l, *r_cw_l, *l_ccw_r, *r_cw_r, *l_tangent;
  edge *a, *b, *c;
  real c_p;
  
  n = r - l + 1;
  if (n == 2) {
    /* Bottom of the recursion. Make an edge */
    *l_ccw = *r_cw = make_edge(p_sorted[l], p_sorted[r]);
  } else if (n == 3) {
    /* Bottom of the recursion. Make a triangle or two edges */
    a = make_edge(p_sorted[l], p_sorted[l+1]);
    b = make_edge(p_sorted[l+1], p_sorted[r]);
    splice(a, b, p_sorted[l+1]);
    c_p = Cross_product_3p(p_sorted[l], p_sorted[l+1], p_sorted[r]);
    
    if (c_p > 0.0)
    {
      /* Make a triangle */
      c = join(a, p_sorted[l], b, p_sorted[r], right);
      *l_ccw = a;
      *r_cw = b;
    } else if (c_p < 0.0) {
      /* Make a triangle */
      c = join(a, p_sorted[l], b, p_sorted[r], left);
      *l_ccw = c;
      *r_cw = c;
    } else {
      /* Points are collinear,  no triangle */ 
      *l_ccw = a;
      *r_cw = b;
    }
  } else if (n  > 3) {
    /* Continue to divide */

    /* Calculate the split point */
    split = (l + r) / 2;
  
    /* Divide */
    divide(p_sorted, l, split, &l_ccw_l, &r_cw_l);
    divide(p_sorted, split+1, r, &l_ccw_r, &r_cw_r);

    /* Merge */
    merge(r_cw_l, p_sorted[split], l_ccw_r, p_sorted[split+1], &l_tangent);

    /* The lower tangent added by merge may have invalidated 
       l_ccw_l or r_cw_r. Update them if necessary. */
    if (Org(l_tangent) == p_sorted[l])
      l_ccw_l = l_tangent;
    if (Dest(l_tangent) == p_sorted[r])
      r_cw_r = l_tangent;

    /* Update edge refs to be passed back */ 
    *l_ccw = l_ccw_l;
    *r_cw = r_cw_r;
  }
}

/*
 *  Determines the lower tangent of two triangulations. 
 */
static void lower_tangent(edge *r_cw_l, point *s, edge *l_ccw_r, point *u,
			  edge **l_lower, point **org_l_lower,
			  edge **r_lower, point **org_r_lower)
{
  edge *l, *r;
  point *o_l, *o_r, *d_l, *d_r;
  boolean finished;

  l = r_cw_l;
  r = l_ccw_r;
  o_l = s;
  d_l = Other_point(l, s);
  o_r = u;
  d_r = Other_point(r, u);
  finished = FALSE;

  while (!finished)
    if (Cross_product_3p(o_l, d_l, o_r) > 0.0) {
      l = Prev(l, d_l);
      o_l = d_l;
      d_l = Other_point(l, o_l);
    } else if (Cross_product_3p(o_r, d_r, o_l) < 0.0) {
      r = Next(r, d_r);
      o_r = d_r;
      d_r = Other_point(r, o_r);
    } else
      finished = TRUE;

  *l_lower = l;
  *r_lower = r;
  *org_l_lower = o_l;
  *org_r_lower = o_r;
}

/* 
 *  The merge function is where most of the work actually gets done.  It is
 *  written as one (longish) function for speed.
 */ 
static void merge(edge *r_cw_l, point *s, edge *l_ccw_r, point *u, edge **l_tangent)
{
  edge *base, *l_cand, *r_cand;
  point *org_base, *dest_base;
  real u_l_c_o_b, v_l_c_o_b, u_l_c_d_b, v_l_c_d_b;
  real u_r_c_o_b, v_r_c_o_b, u_r_c_d_b, v_r_c_d_b;
  real c_p_l_cand, c_p_r_cand;
  real d_p_l_cand, d_p_r_cand;
  boolean above_l_cand, above_r_cand, above_next, above_prev;
  point *dest_l_cand, *dest_r_cand;
  real cot_l_cand, cot_r_cand;
  edge *l_lower, *r_lower;
  point *org_r_lower, *org_l_lower;

  /* Create first cross edge by joining lower common tangent */
  lower_tangent(r_cw_l, s, l_ccw_r, u, &l_lower, &org_l_lower, &r_lower, &org_r_lower);
  base = join(l_lower, org_l_lower, r_lower, org_r_lower, right);
  org_base = org_l_lower;
  dest_base = org_r_lower;
  
  /* Need to return lower tangent. */
  *l_tangent = base;

  /* Main merge loop */
  do 
  {
    /* Initialise l_cand and r_cand */
    l_cand = Next(base, org_base);
    r_cand = Prev(base, dest_base);
    dest_l_cand = Other_point(l_cand, org_base);
    dest_r_cand = Other_point(r_cand, dest_base);

    /* Vectors for above and "in_circle" tests. */
    Vector(dest_l_cand, org_base, u_l_c_o_b, v_l_c_o_b);
    Vector(dest_l_cand, dest_base, u_l_c_d_b, v_l_c_d_b);
    Vector(dest_r_cand, org_base, u_r_c_o_b, v_r_c_o_b);
    Vector(dest_r_cand, dest_base, u_r_c_d_b, v_r_c_d_b);

    /* Above tests. */
    c_p_l_cand = Cross_product_2v(u_l_c_o_b, v_l_c_o_b, u_l_c_d_b, v_l_c_d_b);
    c_p_r_cand = Cross_product_2v(u_r_c_o_b, v_r_c_o_b, u_r_c_d_b, v_r_c_d_b);
    above_l_cand = c_p_l_cand > 0.0;
    above_r_cand = c_p_r_cand > 0.0;
    if (!above_l_cand && !above_r_cand)
      break;        /* Finished. */

    /* Advance l_cand ccw,  deleting the old l_cand edge,  until the 
       "in_circle" test fails. */
    if (above_l_cand)
    {
      real u_n_o_b, v_n_o_b, u_n_d_b, v_n_d_b;
      real c_p_next, d_p_next, cot_next;
      edge *next;
      point *dest_next;

      d_p_l_cand = Dot_product_2v(u_l_c_o_b, v_l_c_o_b, u_l_c_d_b, v_l_c_d_b);
      cot_l_cand = d_p_l_cand / c_p_l_cand;

      do 
      {
        next = Next(l_cand, org_base);
        dest_next = Other_point(next, org_base);
        Vector(dest_next, org_base, u_n_o_b, v_n_o_b);
        Vector(dest_next, dest_base, u_n_d_b, v_n_d_b);
        c_p_next = Cross_product_2v(u_n_o_b, v_n_o_b, u_n_d_b, v_n_d_b);
        above_next = c_p_next > 0.0;

        if (!above_next) 
          break;    /* Finished. */

        d_p_next = Dot_product_2v(u_n_o_b, v_n_o_b, u_n_d_b, v_n_d_b);
        cot_next = d_p_next / c_p_next;

        if (cot_next > cot_l_cand)
          break;    /* Finished. */

        delete_edge(l_cand);
        l_cand = next;
        cot_l_cand = cot_next;
  
      } while (TRUE);
    }

    /* Now do the symmetrical for r_cand */
    if (above_r_cand)
    {
      real u_p_o_b, v_p_o_b, u_p_d_b, v_p_d_b;
      real c_p_prev, d_p_prev, cot_prev;
      edge *prev;
      point *dest_prev;

      d_p_r_cand = Dot_product_2v(u_r_c_o_b, v_r_c_o_b, u_r_c_d_b, v_r_c_d_b);
      cot_r_cand = d_p_r_cand / c_p_r_cand;

      do
      {
        prev = Prev(r_cand, dest_base);
        dest_prev = Other_point(prev, dest_base);
        Vector(dest_prev, org_base, u_p_o_b, v_p_o_b);
        Vector(dest_prev, dest_base, u_p_d_b, v_p_d_b);
        c_p_prev = Cross_product_2v(u_p_o_b, v_p_o_b, u_p_d_b, v_p_d_b);
        above_prev = c_p_prev > 0.0;

        if (!above_prev) 
          break;    /* Finished. */

        d_p_prev = Dot_product_2v(u_p_o_b, v_p_o_b, u_p_d_b, v_p_d_b);
        cot_prev = d_p_prev / c_p_prev;

        if (cot_prev > cot_r_cand)
          break;    /* Finished. */

        delete_edge(r_cand);
        r_cand = prev;
        cot_r_cand = cot_prev;

      } while (TRUE);
    }

    /*
     *  Now add a cross edge from base to either l_cand or r_cand. 
     *  If both are valid choose on the basis of the in_circle test . 
     *  Advance base and  whichever candidate was chosen.
     */
    dest_l_cand = Other_point(l_cand, org_base);
    dest_r_cand = Other_point(r_cand, dest_base);
    if (!above_l_cand || (above_l_cand && above_r_cand && cot_r_cand < cot_l_cand))
    {
      /* Connect to the right */
      base = join(base, org_base, r_cand, dest_r_cand, right);
      dest_base = dest_r_cand;
    } else {
      /* Connect to the left */
      base = join(l_cand, dest_l_cand, base, dest_base, right);
      org_base = dest_l_cand;
    }

  } while (TRUE);
}

/*
 * Function dct replaces Leach's main i.e. it is interface between his code & NAP
 * Return 0 if OK
 */

#undef  TEXT0
#define TEXT0 "dct: "

int
dct(
    NapClientData	*nap_cd, 
    int			nr_xy,		/* no. rows in 'xy' i.e. no. sites */
    int			nc_xy,		/* no. columns in 'xy' */
    float		*xy,		/* input matrix containing (x,y) sites */
    int			nr_result_max,	/* max. no. rows in 'result' */
    int			nc_result,	/* no. columns in 'result' (2 for edges, 3 for triangles) */
    int			*nr_result,	/* no. rows in 'result' (out) */
    int			*result)	/* matrix result (out) */
{
    tri_index		i;
    edge		*l_cw;
    cardinal		n;		/* no. sites */
    edge		*r_ccw;
    point		**p_sorted;
    point		**p_temp;
    int			status;		/* error code */

    n = nr_xy;
    assert(n > 1);
    status = alloc_memory(nap_cd, n);
    CHECK2(status == 0, TEXT0 "not enough memory");
    for (i = 0; i < n; i++) {
	p_array[i].x = xy[nc_xy * i];
	p_array[i].y = xy[nc_xy * i + 1];
    }
    /* Initialise entry edge pointers. */
    for (i = 0; i < n; i++)
	p_array[i].entry_pt = NULL;
    /* Sort. */
    p_sorted = (point **) NAP_ALLOC(nap_cd, (unsigned)n*sizeof(point *));
    CHECK2(p_sorted, TEXT0 "not enough memory");
    p_temp = (point **) NAP_ALLOC(nap_cd, (unsigned)n*sizeof(point *));
    CHECK2(p_temp, TEXT0 "not enough memory");
    for (i = 0; i < n; i++)
	p_sorted[i] = p_array + i;
    merge_sort(p_sorted, p_temp, 0, n-1);
    NAP_FREE(nap_cd, (char *)p_temp);
    /* Triangulate. */
    divide(p_sorted, 0, n-1, &l_cw, &r_ccw);
    NAP_FREE(nap_cd, (char *)p_sorted);
    /* Output edges or triangles. */
    if (nc_result == 3) {
	*nr_result = define_triangles(n, nr_result_max, nc_result, result);
	CHECK2(*nr_result > 0, TEXT0 "Error calling define_triangles");
    } else {
	*nr_result = define_edges(    n, nr_result_max, nc_result, result);
	CHECK2(*nr_result > 0, TEXT0 "Error calling define_edges");
    }
    free_memory(nap_cd);
    return 0;
}

/*
 *  Nap_TriangulateGeneric --
 *
 *  Called by both Nap_Triangulate & Nap_TriangulateEdges.
 */

#undef  TEXT0
#define TEXT0 "Nap_TriangulateGeneric: "

int
Nap_TriangulateGeneric(
    int			want_edges,		/* 0 for triangles, 1 for edges */
    NapClientData	*nap_cd, 
    Nap_NAO		*box_nao,		/* points to user's arguments */
    char		**id)			/* id of NAO result */
{
    Nap_NAO		*arg;			/* argument (sites) */
    int			*dct_result;		/* matrix result defined by dct */
    int			i;			/* index */
    int			nr_arg;			/* no. rows (sites) in arg */
    int			nr_result;		/* no. rows in 'dct_result' */
    int			nr_result_max;		/* max. no. rows in 'dct_result' */
    int			nc_arg;			/* no. columns in arg */
    int			nc_result;		/* no. columns in 'dct_result' */
    int			ne_result;		/* no. elements in 'dct_result' */
    Nap_NAO		*result;		/* result as NAO */
    size_t		shape[2];
    Nap_NAO		*sites;			/* f32(arg) */
    int			status;			/* error code */

    assert(box_nao);
    assert(box_nao->dataType == NAP_BOXED);
    Nap_IncrRefCount(nap_cd, box_nao);
    CHECK2(box_nao->rank == 1, TEXT0 "box_nao rank not 1");
    CHECK2(box_nao->nels > 0,  TEXT0 "No arguments");
    CHECK2(box_nao->nels < 2,  TEXT0 "Too many arguments");
    arg = Nap_GetNaoFromSlot(box_nao->data.Boxed[0]);
    CHECK2(arg, TEXT0 "Error calling Nap_GetNaoFromSlot");
    CHECK2(arg->rank == 2, TEXT0 "argument rank not 2");
    sites = Nap_CastNAO(nap_cd, arg, NAP_F32);
    CHECK2(sites, TEXT0 "Error calling Nap_CastNAO");
    Nap_IncrRefCount(nap_cd, sites);
    CHECK2(sites->shape[0] > 1, TEXT0 "Argument has < 2 rows");
    CHECK2(sites->shape[1] > 1, TEXT0 "Argument has < 2 columns");
    nr_arg = sites->shape[0];
    nc_arg = sites->shape[1];
    if (want_edges) {
	nr_result_max = 3 * nr_arg - 6;		/* upper bound. See Aurenhammer p357 */
	nc_result = 2;
    } else {
	nr_result_max = 2 * nr_arg - 4;		/* upper bound. See Aurenhammer p357 */
	nc_result = 3;
    }
    dct_result = (int *) NAP_ALLOC(nap_cd, nr_result_max * nc_result * sizeof(int));
    CHECK2(dct_result, TEXT0 "Error calling NAP_ALLOC");
    status = dct(nap_cd, nr_arg, nc_arg, sites->data.F32, nr_result_max, nc_result,
	    &nr_result, dct_result);
    CHECK2(status == 0, TEXT0 "Error calling dct");
    shape[0] = nr_result;
    shape[1] = nc_result;
    result = Nap_NewNAO(nap_cd, NAP_I32, 2, shape);
    CHECK2(result, TEXT0 "Error calling Nap_NewNAO");
    *id = result->id;
    ne_result = nc_result * nr_result;
    for (i = 0; i < ne_result; i++) {
	result->data.I32[i] = dct_result[i];
    }
    NAP_FREE(nap_cd, dct_result);
    Nap_DecrRefCount(nap_cd, sites);
    Nap_DecrRefCount(nap_cd, box_nao);
    return 0;
}

/*
 *  Nap_Triangulate --
 *
 *  Nap function 'triangulate(SITES)'
 */

#undef  TEXT0
#define TEXT0 "Nap_Triangulate: "

EXTERN char *
Nap_Triangulate(
    NapClientData	*nap_cd, 
    Nap_NAO		*box_nao)		/* points to user's arguments */
{
    char		*result;		/* id of nao */
    int			status;			/* error code */

    assert(box_nao);
    status = Nap_TriangulateGeneric(0, nap_cd, box_nao, &result);
    CHECK2NULL(status == 0, TEXT0 "Error calling Nap_TriangulateGeneric");
    return result;
}

/*
 *  Nap_TriangulateEdges --
 *
 *  Nap function 'triangulate_edges(SITES)'
 */

#undef  TEXT0
#define TEXT0 "Nap_TriangulateEdges: "

EXTERN char *
Nap_TriangulateEdges(
    NapClientData	*nap_cd, 
    Nap_NAO		*box_nao)		/* points to user's arguments */
{
    char		*result;		/* id of nao */
    int			status;			/* error code */

    assert(box_nao);
    status = Nap_TriangulateGeneric(1, nap_cd, box_nao, &result);
    CHECK2NULL(status == 0, TEXT0 "Error calling Nap_TriangulateGeneric");
    return result;
}
