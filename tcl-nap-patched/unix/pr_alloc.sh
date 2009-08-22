#!/bin/sh
# $Header: /cvsroot/tcl-nap/tcl-nap/unix/pr_alloc.sh,v 1.4 2005/12/02 07:00:25 dav480 Exp $
# author: Harvey Davies, CSIRO Marine and Atmospheric Research, Melbourne

# Process stderr from "make test0" or "make test2" with napLib.c,m4 macro PR_MALLOC defined
# Uses pr_alloc.awk

tr -d '\015\032' | awk '{printf("%s %10d %s\n", $11, NR, $0)}' | sort | 
    awk -f pr_alloc.awk | awk '{print $9,"line",$6,$3,$10,"bytes"}' | sort |
    awk -f pr_alloc2.awk
