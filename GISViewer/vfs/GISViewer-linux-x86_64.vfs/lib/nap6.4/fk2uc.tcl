# fk2uc.tcl --
#
# Copyright (c) 2000, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: fk2uc.tcl,v 1.1 2001/05/07 04:16:53 dav480 Exp $
#
# fortran keywords to upper case


# words2uc --
#
# words to upper case

proc words2uc {
    str
    words
} {
    set re "\\m([join $words |])\\M|$"
    set new ""
    set indices [regexp -all -inline -indices -nocase $re $str]
    foreach index $indices {
	set i [string length $new]
	set j [lindex $index 0]
	set k [lindex $index 1]
	append new [string range $str $i [expr $j - 1]]
	if {$j >= $i} {
	    append new [string toupper [string range $str $j $k]]
	}
    }
    return $new
}


# fk2uc --
#
# fortran keywords to upper case

proc fk2uc {
    filename
} {
    set words \
	"ABS ACCESS ACOS AIMAG AINT ALOG ALOG10 AMAX0 AMAX1 AMIN0 AMIN1
	AMOD AND ANINT APPEND ASIN ASSIGN ATAN ATAN2 BACKSPACE BLANK BLOCK
	BLOCKDATA BLOCKSIZE CALL CCOS CDABS CDCOS CDEXP CDLOG CDSIN CDSQRT
	CEXP CHAR CHARACTER CLOG CLOSE CMPLX COMMON COMPLEX CONJG CONTINUE
	COS COSH CSIN CSQRT DABS DACOS DASIN DATA DATAN DATAN2
	DBLE DCMPLX DCONJG DCOS DCOSH DELETE DEXP DIMAG DINT DIRECT
	DLOG DLOG10 DMAX1 DIMENSION DMIN1 DMOD DNINT DO DOUBLE DSIGN
	DSIN DSINH DSQRT DTAN DTANH ELSE ELSEIF END ENDFILE ENDIF
	ENTRY EQ EQUIVALENCE EQV ERR EXIST EXIT EXP EXTERNAL FILE
	FLOAT FMT FORM FORMAT FORMATTED FUNCTION GE GOTO GO GT
	IABS IAND ICHAR IDINT IDNINT IEOR IF IFIX IMPLICIT INCLUDE
	INDEX INPUT INQUIRE INT INTEGER INTRINSIC IOSTAT ISIGN KEEP LE
	LEN LGE LGT LLE LLT LOG LOG10 LOGICAL LT MAX
	MAX0 MAX1 MIN MIN0 MIN1 MOD NAME NAMELIST NAMED NE
	NEQV NEW NEXTREC NONE NOT NUMBER OLD OPEN OPENED OR
	PARAMETER PAUSE POSITION PRECISION PRINT PROGRAM READ REAL REC RECL
	RETURN REWIND SAVE SCRATCH SEQUENTIAL SIGN SIN SINH SNGL SPACE
	SQRT STATUS STOP SUBROUTINE TAN TANH THEN TO TYPE UNFORMATTED
	UNIT UNKNOWN WHILE WRITE
	ANY ALL CONTAINS IN INOUT INTENT MODULE OUT USE WHERE ELSEWHERE ENDDO"
    set result ""
    if [catch {set f [open $filename r]} message] {
        error $message
    }
    while {[gets $f line] >= 0} {
	set i [string first ! $line]
	if {$i < 0} {
	    set i [string length $line]
	}
	set i1 [expr $i - 1]
	append result [words2uc [string range $line 0 $i1] $words] \
		[string range $line $i end] \n
    }
    close $f
    return [string range $result 0 end-1]
}
