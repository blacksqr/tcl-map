/*
 * triangulate.h --
 *
 * Used by triangulate.c
 *
 * Modified for NAP by Harvey Davies, CSIRO Atmospheric Research in July 2004.
 *
 * $Id: triangulate.h,v 1.4 2006/11/15 06:34:17 dav480 Exp $
 */

/*
 *   Author: Geoff Leach, Department of Computer Science, RMIT.
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

/* Edge sides. */
typedef enum {right, left} side;

/* Geometric and topological entities. */
typedef  unsigned int tri_index;
typedef  unsigned int cardinal;
typedef  int integer;
typedef  float  real;
typedef  float  ordinate;
typedef  unsigned char boolean;
typedef  struct   point   point;
typedef  struct  edge  edge;

struct point {
  ordinate x,y;
  edge *entry_pt;
};

struct edge {
  point *org;
  point *dest;
  edge *onext;
  edge *oprev;
  edge *dnext;
  edge *dprev;
};

#define Vector(p1,p2,u,v) (u = p2->x - p1->x, v = p2->y - p1->y)

#define Cross_product_2v(u1,v1,u2,v2) (u1 * v2 - v1 * u2)

#define Cross_product_3p(p1,p2,p3) \
	((p2->x - p1->x) * (p3->y - p1->y) - (p2->y - p1->y) * (p3->x - p1->x))

#define Dot_product_2v(u1,v1,u2,v2) (u1 * u2 + v1 * v2)

#define  Org(e)    ((e)->org)
#define  Dest(e)    ((e)->dest)
#define  Onext(e)  ((e)->onext)
#define  Oprev(e)  ((e)->oprev)
#define  Dnext(e)  ((e)->dnext)
#define  Dprev(e)  ((e)->dprev)

#define  Other_point(e,p)  ((e)->org == p ? (e)->dest : (e)->org)
#define  Next(e,p)  ((e)->org == p ? (e)->onext : (e)->dnext)
#define  Prev(e,p)  ((e)->org == p ? (e)->oprev : (e)->dprev)

#define  Visited(p)  ((p)->f)

#define Identical_refs(e1,e2)  (e1 == e2)
