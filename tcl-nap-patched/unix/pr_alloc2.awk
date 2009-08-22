# pr_alloc2.awk --
# Called by pr_alloc.sh
#
# $Header: /cvsroot/tcl-nap/tcl-nap/unix/pr_alloc2.awk,v 1.1 2005/12/02 07:00:25 dav480 Exp $
# author: Harvey Davies, CSIRO Marine and Atmospheric Research, Melbourne

BEGIN {
    n = 0
    old = ""
}

{
    if ($0==old) {
	++n
    } else {
	if (n>0) {
	    print n, "repeats of: ", old
	}
	old=$0
	n=1
    }
}

END {
    if (n>0) {
	print n, "repeats of: ", old
    }
}
