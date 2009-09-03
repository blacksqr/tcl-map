# date.tcl --
#
# Define NAP functions related to dates and times.
# Also define command 'convert_date' as replacement for old command 'convert_date' (which
# was defined by separate package written in C).
#
# Copyright (c) 2004, CSIRO Australia
# Author: Harvey Davies, CSIRO.
# $Id: date.tcl,v 1.15 2006/04/07 05:23:10 dav480 Exp $


namespace eval ::NAP {


    # date2jdn --
    #
    # Return the Julian Day Number that begins at noon of the specified Gregorian calendar
    # date.
    # Works for all dates from 1st January 1 A.D. (Julian day number 1721426).
    # Result is missing for invalid argument.
    #
    # Inverse of function jdn2date below.
    #
    # Partly based on function 'julday' on p10 of
    # W.H. Press, et. al.  "Numerical Recipes in C", Cambridge University Press, 1988.
    #
    # Usage:
    #     date2jdn(ymd)
    #	      ymd is array whose final dimension has size 3.
    #	      Column 0 contains year A.D.
    #	      Column 1 contains month of year. 1 for Jan, 2 for Feb, ...
    #	      Column 2 contains day of month (1 to 31)
    #
    # Examples:
    #     date2jdn{1 1 1} gives 1721426
    #     date2jdn{1858 11 16} gives 2400000
    #     date2jdn{1997 3 21} gives 2450529
    #     date2jdn{{1997 3 21}{1997 3 22}} gives {2450529 2450530}

    proc date2jdn {
	ymd
    } {
	set r [$ymd rank]
	if {$r < 1} {
	    error "date2jdn: Argument is scalar"
	}
	nap "s = shape(ymd)"
	if {[[nap "s(-1)"]] != 3} {
	    error "date2jdn: Size of final dimension of argument is not 3"
	}
	nap "shape_result = s(0 .. (r-2) ... 1)"
	nap "ymd2 = reshape(i32(ymd), nint(prod(shape_result)) // 3)"
	nap "year = ymd2(,0)"
	nap "moy  = ymd2(,1)"
	nap "dom  = ymd2(,2)"
	nap "is_error = year < 1  ||  moy < 1  ||  moy > 12  ||  dom < 0  ||  dom > 31"
	nap "is_jan_feb = moy < 3"
	nap "year = year - is_jan_feb"
	nap "moy = moy + 1 + 12 * is_jan_feb"
	nap "jd = i32(365.25 * year) + i32(30.6001 * moy) + dom + 1720995"
	nap "adj = i32(0.01 * year)"
	nap "jd = jd + 2 - adj + i32(0.25 * adj)"
	nap "jd = reshape(is_error ? _ : jd, shape_result)"
	eval $jd set coo [$ymd coo]
	eval $jd set dim [$ymd dim]
	$jd set unit days
	nap "jd"
    }

    # jdn2date --
    #
    # Convert Julian Day Number to Gregorian calendar date.
    # The shape of the result is "shape(argument) // 3",
    # where the final dimension corresponds to year,month,day.
    # The result is {_ _ _} for any date prior to 1st January 1 A.D. (Julian day number
    # 1721426).
    #
    # Inverse of function date2jdn above.
    #
    # Partly based on function 'caldat' on pp 12-13 of
    # W.H. Press, et. al.  "Numerical Recipes in C", Cambridge University Press, 1988.
    #
    # Usage:
    #     jdn2date(jdn)
    #	      where jdn is Julian day number.
    #
    # Examples:
    #    jdn2date(1721426) gives {   1  1  1}
    #    jdn2date(2400000) gives {1858 11 16}
    #    jdn2date(2450529) gives {1997  3 21}
    #    jdn2date{2450508 2450509} gives {{1997 2 28}{1997 3 1}}

    proc jdn2date {
	jdn
    } {
	nap "ijdn = i32(jdn)"
	nap "is_error = ijdn < 1721426"
        nap "jalpha = floor(((ijdn - 1867216) - 0.25) / 36524.25)"
        nap "ja = ijdn + 1 + i32(jalpha - floor(0.25 * jalpha))"
        nap "jb = ja + 1524"
        nap "jc = i32(6680.0 + ((jb - 2439870) - 122.1) / 365.25)"
        nap "jd = 365 * jc + i32(0.25 * jc)"
        nap "je = i32((jb -jd) / 30.6001)"
        nap "dom  = is_error ? _ : jb - jd - i32(30.6001 * je)"
        nap "moy  = is_error ? _ : je - (je > 13 ? 13 : 1)"
        nap "year = is_error ? _ : jc - 4715 - (moy > 2)"
        nap "ymd = transpose(year /// moy // dom, (1 .. rank(jdn) ... 1) // 0)"
	eval $ymd set coo [$jdn coo]
	eval $ymd set dim [$jdn dim]
        nap "ymd"
    }

    # dateTime2mjd --
    #
    # Return the Modified Julian Date (MJD) corresponding to the specified Gregorian
    # calendar date and time of day.
    #
    # Let JDN be the Julian day number.
    # Let F be the fraction of the day elapsed since the preceding noon.
    # Now the Julian Date (JD) is defined by:
    # JD = JDN + F
    # The Modified Julian Date (MJD) is defined by:
    # MJD = JD - 2400000.5
    # The origin corresponds to time 0000 hours on 17 Nov 1858.
    #
    # The time system used is UT1 in which each day (defined as the time for one rotation
    # of the earth) contains exactly 86,400 seconds of variable length (due to variation
    # in the speed at which the earth rotates). Unlike UTC, there are no leap seconds. 
    #
    # Works for all dates from 1st January 1 A.D.
    #
    # MJD is stored as f64, giving accuracy of about 1 microsecond in the year 2000.
    #
    # Inverse of function mjd2dateTime below.
    #
    # Usage:
    #     dateTime2mjd(ymdhms)
    #	      ymdhms is array whose final dimension has size from 1 to 6.
    #	      Column 0 contains year A.D.
    #	      Column 1 contains month of year. 1 for Jan, 2 for Feb, ... (default: 1)
    #	      Column 2 contains day of month (1 to 31) (default: 1)
    #	      Column 3 contains hour of day (0 to 23) (default: 0)
    #	      Column 4 contains minute of hour (0 to 59) (default: 0)
    #	      Column 5 contains second of minute (0 to 60) (default: 0)
    #
    # Examples:
    #     dateTime2mjd{1858 11 17 0 0 0} gives 0
    #     dateTime2mjd{2004 8 16 14 39 59.5} gives 53233.6111053
    #     dateTime2mjd{{2004 8}{2004 9}} gives {53218 53249}

    proc dateTime2mjd {
	ymdhms
    } {
	set r [$ymdhms rank]
	if {$r < 1} {
	    error "dateTime2mjd: Argument is scalar"
	}
	nap "s = shape(ymdhms)"
	if {[[nap "s(-1)"]] > 6} {
	    error "dateTime2mjd: Size of final dimension of argument > 6"
	}
	nap "shape_result = s(0 .. (r-2) ... 1)"
	nap "ymdhms2 = reshape(ymdhms, nint(prod(shape_result)) // s(-1))"
	nap "year = ymdhms2(,0)"
	nap "moy = s(-1) > 1 ? ymdhms2(,1) : 1"
	nap "dom = s(-1) > 2 ? ymdhms2(,2) : 1"
	nap "hod = s(-1) > 3 ? ymdhms2(,3) : 0"
	nap "moh = s(-1) > 4 ? ymdhms2(,4) : 0"
	nap "som = s(-1) > 5 ? ymdhms2(,5) : 0"
	nap "ymd = transpose(year /// moy // dom)"
        nap "mjd = date2jdn(ymd) - 2400001 + (hod + (moh + som / 60.0) / 60.0) / 24.0"
        nap "mjd = reshape(mjd, shape_result)"
	eval $mjd set coo [$ymdhms coo]
	eval $mjd set dim [$ymdhms dim]
	$mjd set unit "days since 1858-11-17 00:00"
        nap "mjd"
    }

    # mjd2dateTime --
    #
    # Convert Modified Julian Date (MJD) to Gregorian calendar date and time of day.
    # The shape of the result is "shape(argument) // 6",
    # where the final dimension corresponds to year, month, day, hour, minute, second.
    #
    # See dateTime2mjd above for definition of MJD.
    #
    # Works for all dates from 1st January 1 A.D.
    #
    # The calculation is done in double precision (f64), giving accuracy of about
    # 1 microsecond in the year 2000.
    #
    # Inverse of function dateTime2mjd above.
    #
    # Usage:
    #     mjd2dateTime(mjd[,delta])
    #	     where
    #		mjd is Modified Julian date.
    #		delta is rounding increment (seconds) (default: 1)
    #		    The result is rounded to the nearest multiple of delta seconds.
    #		    delta = 1    rounds to the nearest second.
    #		    delta = 60   rounds to the nearest minute.
    #		    delta = 1e-3 rounds to the nearest millisecond.
    #
    # Examples:
    #     mjd2dateTime(0) gives {1858 11 17 0 0 0}
    #     mjd2dateTime(53233.6111053, 0.1) gives {2004 8 16 14 39 59.5} 
    #     mjd2dateTime{53218 53249} gives {{2004 8 1 0 0 0}{2004 9 1 0 0 0}}

    proc mjd2dateTime {
	mjd
	{delta 1.0}
    } {
	if {[[nap "delta <= 0.0"]]} {
	    error "mjd2dateTime: delta <= 0"
	}
	nap "mjd = mjd < -678575 ? _ : mjd";		# Handle B.C. error
	nap "n = nint(mjd * 86400.0 / delta) * delta";	# rounded total seconds
        nap "som = n % 60.0";				# second of minute
        nap "n = floor(n / 60.0)";			# whole minutes
        nap "moh = n % 60.0";				# minute of hour
        nap "n = floor(n / 60.0)";			# whole hours
	nap "hod = n % 24.0";				# hour of day
        nap "n = i32(floor(n / 24.0))";			# whole days
	nap "jdn = n + 2400001";			# Julian Day Number
	nap "ymd = transpose(jdn2date(jdn))";		# year month day
	nap "ymdhms = transpose(ymd // hod // moh // som)"
	eval $ymdhms set coo [$mjd coo]
	eval $ymdhms set dim [$mjd dim]
        nap "ymdhms"
    }

    # dateTime2days --
    #
    # This is similar to the above dateTime2mjd, except that it uses an unconventional calendar
    # defined by the additional argument 'ndim' specifying the number of days in each month.
    # This number does not change from year to year (i.e. there are no leap years).
    # The function returns the time in days since the start of year 0.
    #
    # Inverse of function days2dateTime below.
    #
    # Usage:
    #     dateTime2days(ymdhms, ndim)
    #	      ymdhms is array whose final dimension has size from 1 to 6.
    #		Column 0 contains the (possibly negative) integer year relative to year 0
    #		Column 1 contains month of year. 1 for Jan, 2 for Feb, ... (default: 1)
    #		Column 2 contains day of month (1 to 31) (default: 1)
    #		Column 3 contains hour of day (0 to 23) (default: 0)
    #		Column 4 contains minute of hour (0 to 59) (default: 0)
    #		Column 5 contains second of minute (0 to 60) (default: 0)
    #	      ndim is 12-element vector giving "days in month"
    #
    # Examples:
    #     dateTime2days({0 1 1 0 0 0}, 12 # 30) gives 0

    proc dateTime2days {
	ymdhms
	ndim
    } {
	if {[[nap "shape(ndim)"]] ne "12"} {
	    error "dateTime2days: Shape(ndim) is not {12}"
	}
	set r [$ymdhms rank]
	if {$r < 1} {
	    error "dateTime2days: ymdhms is scalar"
	}
	nap "s = shape(ymdhms)"
	if {[[nap "s(-1)"]] > 6} {
	    error "dateTime2days: Size of final dimension of ymdhms > 6"
	}
	nap "shape_result = s(0 .. (r-2) ... 1)"
	nap "ymdhms2 = reshape(ymdhms, nint(prod(shape_result)) // s(-1))"
	nap "year = ymdhms2(,0)"
	nap "moy = s(-1) > 1 ? ymdhms2(,1) - 1 : 0"
	nap "dom = s(-1) > 2 ? ymdhms2(,2) - 1 : 0"
	nap "hod = s(-1) > 3 ? ymdhms2(,3) : 0"
	nap "moh = s(-1) > 4 ? ymdhms2(,4) : 0"
	nap "som = s(-1) > 5 ? ymdhms2(,5) : 0"
	nap "diy = sum ndim";	# days in year
	nap "dsm = 0 // psum(ndim)";	# days from start of year to start of each month
        nap "days = year * diy + dsm(moy) + dom + (hod + (moh + som / 60.0) / 60.0) / 24.0"
        nap "days = reshape(days, shape_result)"
	eval $days set coo [$ymdhms coo]
	eval $days set dim [$ymdhms dim]
	$days set unit days
        nap "days"
    }

    # days2dateTime --
    #
    # This is similar to the above mjd2dateTime, except that it uses an unconventional calendar
    # defined by the additional argument 'ndim' specifying the number of days in each month.
    # This number does not change from year to year (i.e. there are no leap years).
    #
    # The function converts a time-in-days-since-the-start-of-year-0 to a
    # calendar-date-and-time-of-day.
    # The shape of the result is "shape(argument) // 6",
    # where the final dimension corresponds to year, month, day, hour, minute, second.
    #
    # Inverse of function dateTime2days above.
    #
    # Usage:
    #     days2dateTime(days, ndim [,delta])
    #	     where
    #		days is time in days since start of year 0
    #	        ndim is 12-element vector giving "days in month"
    #		delta is rounding increment (seconds) (default: 1)
    #		    The result is rounded to the nearest multiple of delta seconds.
    #		    delta = 1    rounds to the nearest second.
    #		    delta = 60   rounds to the nearest minute.
    #		    delta = 1e-3 rounds to the nearest millisecond.
    #
    # Examples:
    #     days2dateTime(0, 12#30) gives {0 1 1 0 0 0}

    proc days2dateTime {
	days
	ndim
	{delta 1.0}
    } {
	if {[[nap "shape(ndim)"]] ne "12"} {
	    error "days2dateTime: Shape(ndim) is not {12}"
	}
	if {[[nap "delta <= 0.0"]]} {
	    error "days2dateTime: delta <= 0"
	}
	nap "ndim = i32 ndim"
	nap "diy = sum ndim";				# days in year
	nap "dsm = 0 // psum(ndim)";		# days from start of year to start of month
	nap "n = nint(days * 86400.0 / delta) * delta";	# rounded total seconds
        nap "som = n % 60.0";				# second of minute
        nap "n = floor(n / 60.0)";			# whole minutes
        nap "moh = n % 60.0";				# minute of hour
        nap "n = floor(n / 60.0)";			# whole hours
	nap "hod = n % 24.0";				# hour of day
        nap "n = floor(n / 24.0)";			# whole days
        nap "y = floor(n / diy)";			# year
        nap "doy = n % diy";				# day of year (0 = Jan 1)
        nap "moy = floor(dsm @ doy)";			# month of year (0 = Jan)
        nap "dom = doy - dsm(moy) + 1.0";		# day of month (1, 2, 3, ...)
        nap "moy = moy + 1.0";				# month of year (1 = Jan)
	nap "ymdhms = transpose(y /// moy // dom // hod // moh // som)"
	eval $ymdhms set coo [$days coo]
	eval $ymdhms set dim [$days dim]
        nap "ymdhms"
    }

}


# format_mjd --
#
# Format the Modified Julian Date mjd, one value per line.
#
# mjd can be any NAP expression. This is rounded to the nearest second.
#
# format is that required for 'clock' command.
# The default format produces a standard ISO 8601 date/time in the form "YYYY-MM-DDThh:mm:ss". 
#
# The range of dates which 'clock' can handle depends on the platform.
# The current (8.4.7) Windows version uses a 32-bit signed integer offset (seconds) from
# 1970-01-01, allowing dates from 1901-12-13 to 2038-01-19.
#
# Examples
#   % format_mjd "{0 0.5} + dateTime2mjd{2004 10 22 16 30 59}"
#   2004-10-22T16:30:59
#   2004-10-23T04:30:59
#   % format_mjd "{0 0.5} + dateTime2mjd{2004 10 22 16 30 59}" "%y%m%d %H%M"
#   041022 1630
#   041023 0430

proc format_mjd {
    mjd
    {format "%Y-%m-%dT%H:%M:%S"}
} {
    nap "m = f64([uplevel nap "\"$mjd\""])"
    set seconds [clock scan 2000-01-01 -gmt 1]
    # MJD of 2000-01-01 is 51544.  There are 86400 seconds in a day.
    nap "times = seconds + i32(nint((m - 51544f64) * 86400f64))"
    foreach time [$times value] {
	lappend result [clock format $time -gmt 1 -format $format]
    }
    join $result "\n"
}


# format_jdn --
#
# Format the Julian Day Number jdn, one value per line.
#
# jdn can be any NAP expression.
#
# format is that required for 'clock' command.
# The default format produces a standard ISO 8601 date in the form "YYYY-MM-DD".
#
# Examples
#   % format_jdn "{0 7} + date2jdn{2004 10 22}"
#   2004-10-22
#   2004-10-29
#   % format_jdn "{0 7} + date2jdn{2004 10 22}" "%y %m %d"
#   04 10 22
#   04 10 29

proc format_jdn {
    jdn
    {format "%Y-%m-%d"}
} {
    nap "mjd = f64([uplevel nap "\"$jdn\""]) - 2400001f64"
    format_mjd $mjd $format
}


# is_non_neg_int --
#
# Is string a valid non-negative integer?
# Treat string with leading 0 as decimal, not octal.

proc is_non_neg_int {
    str
} {
    if {$str eq ""} {
	return 0
    }
    set s [string trimleft $str 0]
    if {$s eq ""} {
	return 1
    }
    if {[string is integer $s]} {
	return [expr $s >= 0]
    } else {
	return 0
    }
}

# convert_date --
#
# Define command 'convert_date' as replacement for old command 'convert_date' (which
# was defined by separate package written in C).
# 
# Usage:
#   convert_date <STRING>
#     or
#   convert_date <MJD> ?<D>?
# 
# where <STRING> is Australian/ISO standard date/time
#       <MJD>    is modified Julian Date. See dateTime2mjd above for definition of MJD.
#       <D>      is required number decimal places of seconds (default: 0)
# 
#	If <D> is present or the 1st argument is a legal number with value < 1e6
#	then the 1st argument is assumed to be <MJD> (2nd form above) & the
#	result is the Australian/ISO standard date/time.
#
#	Otherwise the 1st argument is assumed to be <STRING> (1st form above) &
#	the result is the modified Julian Date. Note that <STRING> will
#	typically not be a legal number due to the presence of characters such
#	as 'T' and ':'.  <STRING> must have at least 7 characters & be in one of
#	following forms:
#		[CC]YYMMDDT[hh[mm[ss[[p]f[Z]]]]]
#		[CC]YY-MM-DDT[hh[:mm[:ss[[p]f[Z]]]]]
#		[CC]YY-MM-DD
#		CCYYMMDD
#	where:
#		CC is 2-digit century (Default: 20 if YY < 50, else 19)
#		YY is 2-digit year of century (00 to 99)
#		MM is 2-digit month-of-year (01 to 12)
#		DD is 2-digit day-of-month (01 to 31)
#		T is literal character 'T'
#		hh is 2-digit hour-of-day (00 to 23)
#		mm is 2-digit minute-of-hour (00 to 59)
#		ss is 2-digit second-of-minute (00 to 59)
#		p is decimal-point (either '.' or ',')
#		f is fraction-of-second (any number of digits)
#		Z is literal character 'Z' (ignored)

proc convert_date {
    args
} {
    switch [llength $args] {
	0 {
	    error "no arguments"
	}
	1 {
	    if {[string is double $args]  &&  $args < 1e6} {
		set mjd $args
		set d 0
	    } else {
		set mjd ""
		set str $args
	    }
	}
	2 {
	    set mjd [lindex $args 0]
	    set d   [lindex $args 1]
	    if {![is_non_neg_int $d]} {
		error "<D> is invalid or negative integer"
	    }
	}
	default {
	    error "too many arguments"
	}
    }
    if {$mjd eq ""} {
	if {[string length $str] < 7} {
	    error "argument has < 7 characters"
	}
	set str [string map {, . Z {} ' {}} $str]
	set dt [split $str T]
	set ymd [split [lindex $dt 0] :-]
	switch [llength $ymd] {
	    1 {
		if {![is_non_neg_int $ymd]} {
		    error "<YMD> is invalid or negative integer"
		}
		set year [[nap "ymd / 10000"]]
		set moy  [[nap "ymd / 100 % 100"]]
		set dom  [[nap "ymd % 100"]]
	    }
	    3 {
		set year [lindex $ymd 0]
		set moy  [lindex $ymd 1]
		set dom  [lindex $ymd 2]
	    }
	    default {
		error "illegal <YMD>"
	    }
	}
	if {[[nap "year < 100"]]} {
	    set year [[nap "year < 50 ? 2000 + year : 1900 + year"]]
	}
	set hms [split [lindex $dt 1] :-]
	set hod 0
	set moh 0
	set som 0
	switch [llength $hms] {
	    0 {
	    }
	    1 {
		if {![is_non_neg_int $hms]} {
		    error "<HMS> is invalid or negative integer"
		}
		set hod [string range $hms 0 1]
		if {[string length $hms] > 2} {
		    set moh [string range $hms 2 3]
		}
		if {[string length $hms] > 4} {
		    set som [string range $hms 4 end]
		}
	    }
	    2 {
		set hod [lindex $hms 0]
		set moh [lindex $hms 1]
	    }
	    3 {
		set hod [lindex $hms 0]
		set moh [lindex $hms 1]
		set som [lindex $hms 2]
	    }
	    default {
		error "illegal <HMS>"
	    }
	}
	nap "mjd = dateTime2mjd(year // moy // dom // hod // moh // som)"
	set result "[$mjd -format %.15g]"
    } else {
	nap "ymdhms = mjd2dateTime(mjd, 0.1 ** d)"
	if {$d > 0} {
	    set som_fmt "%0[expr $d + 3].${d}f"
	} else {
	    set som_fmt "%02.0f"
	}
	set result ""
	append result "[[nap "ymdhms(0)"] -format %04.0f]-"
	append result "[[nap "ymdhms(1)"] -format %02.0f]-"
	append result "[[nap "ymdhms(2)"] -format %02.0f]T"
	append result "[[nap "ymdhms(3)"] -format %02.0f]:"
	append result "[[nap "ymdhms(4)"] -format %02.0f]:"
	append result "[[nap "ymdhms(5)"] -format $som_fmt]"
    }
    return $result
}
