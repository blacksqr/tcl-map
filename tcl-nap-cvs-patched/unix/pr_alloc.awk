# pr_alloc.awk --
# Called by pr_alloc.sh
#
# $Header: /cvsroot/tcl-nap/tcl-nap/unix/pr_alloc.awk,v 1.3 2005/12/02 07:00:25 dav480 Exp $
# author: Harvey Davies, CSIRO Marine and Atmospheric Research, Melbourne

BEGIN {
    old=""
    old1=0
    old3=""
}

$1 ~ /^0/  &&  $0 !~ /++/ {
    if ($3 ~ "Free$") {
	if ($1 == old1  &&  old3 ~ "Alloc") {
	    old1=0
	} else {
	    print old
	    old=$0
	    old1=$1
	    old3=$3
	}
    } else {
	if (old1 > 0) {
	    print old
	}
	old=$0
	old1=$1
	old3=$3
    }
}

END {
    if (old1 > 0) {
	print old
    }
}
