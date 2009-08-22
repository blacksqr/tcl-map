# hdf_netcdf.tcl --
# 
# sourced by hdf.test which sets hdf_nc = "hdf"
# sourced by netcdf.test which sets hdf_nc = "netcdf"
# 
# Copyright (c) 2000, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: hdf_netcdf.tcl,v 1.31 2007/12/10 06:11:47 dav480 Exp $

switch $hdf_nc {
    hdf		{set ext hdf; set ishdf 1}
    netcdf	{set ext nc;  set ishdf 0}
}

proc put_info text {
    # puts "${text}: [llength [list_naos]] NAOs using [lindex [nap_info bytes] 0] bytes"
}

file delete test.$ext

Test $hdf_nc-1.1 "create $hdf_nc file" {
    [nap "a = i16{4 -8}"] $hdf_nc test.$ext abc
    nap_get $hdf_nc -list test.$ext
} {abc
abc:_FillValue}

Test $hdf_nc-1.2 "read $hdf_nc var" {
    [nap_get $hdf_nc test.$ext abc] v
} {4 -8}

Test $hdf_nc-1.3 "$hdf_nc: write another var" {
    $a $hdf_nc test.$ext d
    [nap_get $hdf_nc test.$ext d] v
} {4 -8}

Test $hdf_nc-1.4 "$hdf_nc: re-read 1st var" {
    [nap_get $hdf_nc test.$ext abc] v
} {4 -8}

Test $hdf_nc-1.5 "$hdf_nc: overwrite var" {
    [nap "{1 42}"] $hdf_nc test.$ext abc
    [nap_get $hdf_nc test.$ext abc "0 .. 1"] v
} {1 42}

Test $hdf_nc-1.6 "$hdf_nc: write var with missing values" {
    [nap "{3.6 _ _ -9}"] $hdf_nc test.$ext vec
    [nap_get $hdf_nc test.$ext vec] v
} {3.6 _ _ -9}

Test $hdf_nc-1.7 "$hdf_nc: rewrite var with missing values" {
    [nap "{_ _ 0}"] $hdf_nc test.$ext vec
    [nap_get $hdf_nc test.$ext vec] v
} {_ _ 0 -9}

Test $hdf_nc-1.8 "$hdf_nc: write & read var with non-std missing value" {
    nap "a = {1 0}"
    $a set miss 0
    $a $hdf_nc test.$ext a
    nap "tmp = [nap_get $hdf_nc test.$ext a]"
    subst "[$tmp miss]\n[$tmp]"
} {0
1 _}

unset a tmp
file delete test.$ext
put_info "after $hdf_nc-1.8 12"

file delete geog.$ext

Test $hdf_nc-2.1 "write $hdf_nc variable with coordinate variables" {
    nap "m = {{2s 4s 0s}{-3s 8s 9s}}"
    nap "i = i16({4 6})"
    $i set unit degrees_north
    nap "j = f32({8 9 9.3})"
    $j set unit degrees_east
    $m set dim lat lon
    $m set coo i j
    $m $hdf_nc geog.$ext mat
    lsort [nap_get $hdf_nc -list geog.$ext]
} {lat lat:units lon lon:units mat mat:_FillValue}

Test $hdf_nc-2.2 "read $hdf_nc variable with coordinate variables using subscript" {
    nap in = [nap_get $hdf_nc geog.$ext mat "{1 0},{0 2}"]
    $in v -f %g
} {-3  9
 2  0}

Test $hdf_nc-2.3 "check coordinate variable read from $hdf_nc file" {
    nap "cv = [$in coo lat]"
    list [$cv value] [$cv unit]
} {{6 4} degrees_north}

Test $hdf_nc-2.4 "check coordinate variable read from $hdf_nc file" {
    nap "cv = [$in coo lon]"
    list [$cv value] [$cv unit]
} {{8 9.3} degrees_east}

Test $hdf_nc-2.5 "read $hdf_nc variable with coordinate variables using @@" {
    nap "in = [nap_get $hdf_nc geog.$ext mat "@@{9.3 4}, @@{8.6 9.2}"]"
    $in v -f %g
} {8 9
4 0}

Test $hdf_nc-2.6 "check coordinate variable read from $hdf_nc file" {
    [$in coo lat] v
} {9.3 4}

Test $hdf_nc-2.7 "check coordinate variable read from $hdf_nc file" {
    [$in coo lon] v
} {8.6 9.2}

Test $hdf_nc-2.8 "read $hdf_nc variable with coordinate variables" {
    nap in = [nap_get $hdf_nc geog.$ext mat]
    $in v -f %g
} { 2  4  0
-3  8  9}

Test $hdf_nc-2.9 "check coordinate variable read from $hdf_nc file" {
    [$in coo lon] v
} {8 9 9.3}

Test $hdf_nc-2.10 "check coordinate variable read from $hdf_nc file" {
    [$in coo lat] v
} {4 6}

Test $hdf_nc-2.11 "$hdf_nc scaling" {
    [nap "{{100f 110f}{100.5f 109f}}"] $hdf_nc geog.$ext scaled_mat \
    -datatype i16 -scale 0.1 -offset 5
    [nap_get $hdf_nc geog.$ext scaled_mat]
} {100.0 110.0
100.5 109.0}

Test $hdf_nc-2.12 "get data-type of $hdf_nc variable" {
    nap_get $hdf_nc -datatype geog.$ext scaled_mat
} {i16}

Test $hdf_nc-2.13 "get dim names of $hdf_nc variable" {
    nap_get $hdf_nc -dim geog.$ext mat
} {lat lon}

Test $hdf_nc-2.14 "get rank of $hdf_nc variable" {
    nap_get $hdf_nc -rank geog.$ext mat
} {2}

Test $hdf_nc-2.15 "get shape of $hdf_nc variable" {
    nap_get $hdf_nc -shape geog.$ext mat
} {2 3}

Test $hdf_nc-2.16 "get cv 0 of $hdf_nc variable" {
    [nap_get $hdf_nc -coo geog.$ext mat 0]
} {4 6}

Test $hdf_nc-2.17 "get cv 1 of $hdf_nc variable" {
    [nap_get $hdf_nc -coo geog.$ext mat lon]
} {8 9 9.3}

Test $hdf_nc-2.18 "get raw $hdf_nc data" {
    [nap_get $hdf_nc geog.$ext scaled_mat {} 1]
} [expr $ishdf ? {"1005 1105\n1010 1095" : " 950 1050\n 955 1040"}]

unset cv i in j m
file delete geog.$ext
file delete tmp.$ext
put_info "after $hdf_nc-2.17 12"

Test $hdf_nc-3.1 "text var" {
    nap "s = `line 1
    line 2`"
    $s set label {Two words}
    $s $hdf_nc tmp.$ext s
    [nap_get $hdf_nc tmp.$ext s]
} {line 1
    line 2}

Test $hdf_nc-3.2 "label" {
    [nap_get $hdf_nc tmp.$ext s] label
} {Two words}

Test $hdf_nc-3.3 "global char att" {
    $s $hdf_nc tmp.$ext :s
    [nap_get $hdf_nc tmp.$ext :s]
} {line 1
    line 2}

Test $hdf_nc-3.4 "normal char att" {
    [nap 'hello world'] $hdf_nc tmp.$ext s:a
    [nap_get $hdf_nc tmp.$ext s:a]
} {hello world}

file delete tmp.$ext

file delete ooc.$ext
put_info "after $hdf_nc-3.4 13"

Test $hdf_nc-4.1 "OOC $hdf_nc write" {
    nap "m = {8 # {-1 9 0}}"
    $m set dim y x
    $m set coo "1 .. 8" "{2 5 9}"
    $m $hdf_nc -d f32 -c "1 .. 20, 1 .. 10" ooc.$ext matrix
    catch {nap "in =[nap_get $hdf_nc ooc.$ext matrix]"}
} 0

Test $hdf_nc-4.2 "check input from nap_get $hdf_nc" {
    $in a -c -1
} "$in  f32  MissingValue: NaN  References: 1
Dimension 0   Size: 20     Name: y         Coordinate-variable: [$in coo 0]
Dimension 1   Size: 10     Name: x         Coordinate-variable: [$in coo 1]
Value:
 _ -1  _  _  9  _  _  _  0  _
 _ -1  _  _  9  _  _  _  0  _
 _ -1  _  _  9  _  _  _  0  _
 _ -1  _  _  9  _  _  _  0  _
 _ -1  _  _  9  _  _  _  0  _
 _ -1  _  _  9  _  _  _  0  _
 _ -1  _  _  9  _  _  _  0  _
 _ -1  _  _  9  _  _  _  0  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _
 _  _  _  _  _  _  _  _  _  _"

Test $hdf_nc-4.3 "check cv" {
    [$in coo 0] v
} {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20}

Test $hdf_nc-4.4 "check cv" {
    [$in coo 1] v
} {1 2 3 4 5 6 7 8 9 10}

unset m in s
put_info "after $hdf_nc-4.4 12"

Test $hdf_nc-5.1 "ragged array" {
    file del ragged.$ext
    nap "r = prune{{0 1.5 2 -1}{1n 1 4 1n}{4#1n}{1n 1n 9 -9}}"
    $r set dim i j
    $r $hdf_nc ragged.$ext r -c "{2 4 6 7 9},{1 3 4 8 9}"
    nap "in =[nap_get $hdf_nc ragged.$ext r]"
    $in da
} f64

Test $hdf_nc-5.2 "check in" {
    $in all
} "$in  f64  MissingValue: NaN  References: 1
Dimension 0   Size: 5      Name: i         Coordinate-variable: [$in coo 0]
Dimension 1   Size: 5      Name: j         Coordinate-variable: [$in coo 1]
Value:
 0.0  1.5  2.0 -1.0    _
   _  1.0  4.0    _    _
   _    _    _    _    _
   _    _  9.0 -9.0    _
   _    _    _    _    _"

Test $hdf_nc-5.3 {check cv 0} {[$in coo i]} {2 4 6 7 9}

Test $hdf_nc-5.4 {check cv 1} {[$in coo j]} {1 3 4 8 9}

Test $hdf_nc-5.5 "ragged array with non-std missing value" {
    file del ragged.$ext
    nap "r = {{0 1.5 2 -1}{1n 1 4 1n}{4#1n}{1n 1n 9 -9}}"
    $r set miss -999
    nap "r = prune r"
    $r set dim i j
    $r $hdf_nc ragged.$ext r -c "{2 4 6 7 9},{1 3 4 8 9}"
    nap "in =[nap_get $hdf_nc ragged.$ext r]"
    $in da
} f64

Test $hdf_nc-5.6 "check in" {
    $in all
} "$in  f64  MissingValue: -999  References: 1
Dimension 0   Size: 5      Name: i         Coordinate-variable: [$in coo 0]
Dimension 1   Size: 5      Name: j         Coordinate-variable: [$in coo 1]
Value:
 0.0  1.5  2.0 -1.0    _
   _  1.0  4.0    _    _
   _    _    _    _    _
   _    _  9.0 -9.0    _
   _    _    _    _    _"

Test $hdf_nc-5.7 {check cv 0} {[$in coo i]} {2 4 6 7 9}

Test $hdf_nc-5.8 {check cv 1} {[$in coo j]} {1 3 4 8 9}

unset in
put_info "after $hdf_nc-5.8 18"

Test $hdf_nc-6.1 "OOC $hdf_nc -datatype" {
    nap "v = 3 .. 6"
    $v set dim i
    $v $hdf_nc -datatype f64 ooc.$ext vector
    nap "in = [nap_get $hdf_nc ooc.$ext vector]"
    $in datatype
} f64

Test $hdf_nc-6.2 "check in" {
    $in all
} "$in  f64  MissingValue: NaN  References: 1
Dimension 0   Size: 4      Name: i         Coordinate-variable: (NULL)
Value:
3 4 5 6"

unset v in
put_info "after $hdf_nc-6.2 18"

Test $hdf_nc-7.1 "OOC $hdf_nc -datatype -scale" {
    nap "m = f32 {{3.66e9 1.04e9}{-1.04e9 -8.96e9}}"
    $m set di row col
    $m $hdf_nc -datatype i16 -scale 1e8 ooc.$ext short_matrix
    nap "in = [nap_get $hdf_nc ooc.$ext short_matrix]"
    $in datatype
} f32

Test $hdf_nc-7.2 "check in" {
    $in all
}        "$in  f32  MissingValue: NaN  References: 1
Dimension 0   Size: 2      Name: row       Coordinate-variable: (NULL)
Dimension 1   Size: 2      Name: col       Coordinate-variable: (NULL)
Value:
3.7e+09   1e+09
 -1e+09  -9e+09"

unset in
put_info "after $hdf_nc-7.2 19"

Test $hdf_nc-8.1 "OOC $hdf_nc -datatype -offset" {
    nap "v = 903s .. 906s"
    $v set di ii
    $v $hdf_nc -datatype i8 -offset "ishdf ? -900 : 900" ooc.$ext byte_vector
    nap "in = [nap_get $hdf_nc ooc.$ext byte_vector]"
    $in datatype
} i16

Test $hdf_nc-8.2 "check in" {
    $in all
} "$in  i16  MissingValue: -32768  References: 1
Dimension 0   Size: 4      Name: ii        Coordinate-variable: (NULL)
Value:
903 904 905 906"

unset in v
put_info "after $hdf_nc-8.2 19"

Test $hdf_nc-9.1 "OOC $hdf_nc -coord" {
    $m set di Row Col
    $m $hdf_nc -coordinateVariable "{1 3.5 4 9},{0 -0.1 -0.5 -2}" \
	    ooc.$ext f32_matrix
    nap "in = [nap_get $hdf_nc ooc.$ext f32_matrix]"
    $in datatype
} f32

Test $hdf_nc-9.2 "check cv0" {
    [$in coo 0]
} {1 3.5 4 9}

Test $hdf_nc-9.3 "check cv1" {
    [$in coo 1]
} {0 -0.1 -0.5 -2}

Test $hdf_nc-9.4 "check in" {
    $in all
} "$in  f32  MissingValue: NaN  References: 1
Dimension 0   Size: 4      Name: Row       Coordinate-variable: [$in coo 0]
Dimension 1   Size: 4      Name: Col       Coordinate-variable: [$in coo 1]
Value:
 3.66e+09  1.04e+09         _         _
-1.04e+09 -8.96e+09         _         _
        _         _         _         _
        _         _         _         _"

unset in 
put_info "before $hdf_nc-10.1 19"

Test $hdf_nc-10.1 "OOC $hdf_nc -coord" {
    file delete v.$ext
    [nap 3] $hdf_nc v.$ext v -coo "{2 4 6}" -index -1
    nap "in = [nap_get $hdf_nc v.$ext v]"
    $in
} {_ _ 3}

Test $hdf_nc-10.2 "OOC $hdf_nc check cv" {
    [$in coo]
} {2 4 6}

Test $hdf_nc-10.3 "OOC $hdf_nc -coord" {
    file delete v.$ext
    nap "x = {2 4 6}"
    $x set dim x
    [nap 3] $hdf_nc v.$ext v -coo x -index -1
    nap "in = [nap_get $hdf_nc v.$ext v]"
    $in
} {_ _ 3}

Test $hdf_nc-10.4 "OOC $hdf_nc check cv" {
    [$in coo]
} {2 4 6}

Test $hdf_nc-10.5 "OOC $hdf_nc check dim name" {
    $in dim
} x

unset in x
file delete v.$ext
put_info "after $hdf_nc-10.2 19"

Test $hdf_nc-11.1 "OOC $hdf_nc use cv" {
    $m set coo "{9 1}" "{0 -2}"
    $m $hdf_nc ooc.$ext f32_matrix
    nap "in = [nap_get $hdf_nc ooc.$ext f32_matrix]"
    $in datatype
} f32

Test $hdf_nc-11.2 "check in" {
    $in all
} "$in  f32  MissingValue: NaN  References: 1
Dimension 0   Size: 4      Name: Row       Coordinate-variable: [$in coo 0]
Dimension 1   Size: 4      Name: Col       Coordinate-variable: [$in coo 1]
Value:
-1.04e+09  1.04e+09         _ -8.96e+09
-1.04e+09 -8.96e+09         _         _
        _         _         _         _
 3.66e+09         _         _  1.04e+09"

unset in
put_info "after $hdf_nc-11.2 21"

Test $hdf_nc-12.1 "OOC $hdf_nc -subscript" {
    [nap "{{0 1i}}"] $hdf_nc -subscript "@@4, 1 .. 2" ooc.$ext f32_matrix
    nap "in = [nap_get $hdf_nc ooc.$ext f32_matrix]"
    $in datatype
} f32

Test $hdf_nc-12.2 "check in" {
    $in all
} "$in  f32  MissingValue: NaN  References: 1
Dimension 0   Size: 4      Name: Row       Coordinate-variable: [$in coo 0]
Dimension 1   Size: 4      Name: Col       Coordinate-variable: [$in coo 1]
Value:
-1.04e+09  1.04e+09         _ -8.96e+09
-1.04e+09 -8.96e+09         _         _
        _         0       Inf         _
 3.66e+09         _         _  1.04e+09"

Test $hdf_nc-13.1 "OOC $hdf_nc -subscript. put scalar" {
    [nap "-3.8"] $hdf_nc -subscript "-2,-1" ooc.$ext f32_matrix
    nap "in = [nap_get $hdf_nc ooc.$ext f32_matrix]"
    $in datatype
} f32

Test $hdf_nc-13.2 "check in" {
    $in all
} "$in  f32  MissingValue: NaN  References: 1
Dimension 0   Size: 4      Name: Row       Coordinate-variable: [$in coo 0]
Dimension 1   Size: 4      Name: Col       Coordinate-variable: [$in coo 1]
Value:
-1.04e+09  1.04e+09         _ -8.96e+09
-1.04e+09 -8.96e+09         _         _
        _         0       Inf      -3.8
 3.66e+09         _         _  1.04e+09"

unset in
put_info "after $hdf_nc-13.2 21"

Test $hdf_nc-14.1 "OOC $hdf_nc -subscript. put scalar" {
    [nap "{1.23e9 -0.9e9 2.5e9}"] $hdf_nc -subscript "6,1..3" ooc.$ext f32_matrix
    nap "in = [nap_get $hdf_nc ooc.$ext f32_matrix]"
    $in datatype
} f32

Test $hdf_nc-14.2 "check in" {
    $in all
} "$in  f32  MissingValue: NaN  References: 1
Dimension 0   Size: 4      Name: Row       Coordinate-variable: [$in coo 0]
Dimension 1   Size: 4      Name: Col       Coordinate-variable: [$in coo 1]
Value:
-1.04e+09  1.04e+09         _ -8.96e+09
-1.04e+09 -8.96e+09         _         _
        _  1.23e+09    -9e+08   2.5e+09
 3.66e+09         _         _  1.04e+09"

unset in
put_info "after $hdf_nc-14.2 21"

Test $hdf_nc-15.1 "nap_get $hdf_nc with subscript" {
    nap "in = [nap_get $hdf_nc ooc.$ext f32_matrix "1,{1 0}"]"
    $in datatype
} f32

Test $hdf_nc-15.2 "check in" {
    $in all
} "$in  f32  MissingValue: NaN  References: 1
Dimension 0   Size: 2      Name: Col       Coordinate-variable: [$in coo]
Value:
-8.96e+09 -1.04e+09"

Test $hdf_nc-15.3 "check cv" {
    [$in coo]
} {-0.1 0}

unset in
put_info "after $hdf_nc-15.3 21"

Test $hdf_nc-16.1 "nap_get $hdf_nc with subscript" {
    nap "in = [nap_get $hdf_nc ooc.$ext f32_matrix ",@@{-9 -0.4 9}"]"
    $in datatype
} f32

Test $hdf_nc-16.2 "check in" {
    $in all
} "$in  f32  MissingValue: NaN  References: 1
Dimension 0   Size: 4      Name: Row       Coordinate-variable: [$in coo 0]
Dimension 1   Size: 3      Name: Col       Coordinate-variable: [$in coo 1]
Value:
-8.96e+09         _ -1.04e+09
        _         _ -1.04e+09
  2.5e+09    -9e+08         _
 1.04e+09         _  3.66e+09"

Test $hdf_nc-16.3 "check cv0" {
    [$in coo 0]
} {1 3.5 4 9}

Test $hdf_nc-16.4 "check cv1" {
    [$in coo 1]
} {-9 -0.4 9}

unset in
put_info "after $hdf_nc-16.4 21"

Test $hdf_nc-17.1 "scaled ragged array" {
    file delete ragged.$ext
    $r $hdf_nc ragged.$ext scaled_ragged -c "{2 4 6 7 9},{1 3 4 8 9}" -da i16 \
	    -sc 1e-2 -off "ishdf ? 99 : -0.99" -range "{-800 998}"
    nap "in =[nap_get $hdf_nc ragged.$ext scaled_ragged]"
    $in da
} f64

Test $hdf_nc-17.2 "check in" {
    $in all -format "%0.2f"
} "$in  f64  MissingValue: NaN  References: 1
Dimension 0   Size: 5      Name: i         Coordinate-variable: [$in coo 0]
Dimension 1   Size: 5      Name: j         Coordinate-variable: [$in coo 1]
Value:
 0.00  1.50  2.00 -1.00     _
    _  1.00  4.00     _     _
    _     _     _     _     _
    _     _  8.99 -8.99     _
    _     _     _     _     _"

Test $hdf_nc-17.3 {check cv 0} {[$in coo i]} {2 4 6 7 9}

Test $hdf_nc-17.4 {check cv 1} {[$in coo j]} {1 3 4 8 9}

Test $hdf_nc-17.5 "check range" {
    [nap_get $hdf_nc ragged.$ext scaled_ragged:valid_range]
} {-800 998}

unset in m r
file delete ooc.$ext ragged.$ext
put_info "after $hdf_nc-17.5 12"

Test $hdf_nc-18.1 "create empty unlimited dimension" {
    file delete unlimited.$ext
    nap "time = f32 {}"
    $time set dim time
    $time $hdf_nc -unlimited unlimited.$ext time
    nap "in = [nap_get $hdf_nc unlimited.$ext time]"
    $in da
} f32

Test $hdf_nc-18.2 "write unlimited dimension cv" {
    nap "time = f32{2}"
    $time set dim time
    $time $hdf_nc unlimited.$ext time
    nap "in = [nap_get $hdf_nc unlimited.$ext time]"
    $in
} {2}

Test $hdf_nc-18.3 "write another var with unlimited dimension" {
    nap "mat = {{3 9 5}{0 3 1}}"
    nap "time = f32{2 4}"
    nap "col = 1 .. 3"
    $mat set coo time col
    $mat $hdf_nc unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} {3 9 5
0 3 1}

Test $hdf_nc-18.4 {check cv 0} {[$in coo 0]} {2 4}

Test $hdf_nc-18.5 {check cv 1} {[$in coo 1]} {1 2 3}

Test $hdf_nc-18.6 "write more to var with unlimited dimension" {
    nap "time = f32{5}"
    nap "i = [nap_get $hdf_nc -shape unlimited.$ext time]"
    $time $hdf_nc -index i unlimited.$ext time
    nap "mat = {{9 7 7}}"
    $mat set coo time col
    $mat $hdf_nc unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} {3 9 5
0 3 1
9 7 7}

Test $hdf_nc-18.7 {check cv 0} {[$in coo 0]} {2 4 5}

Test $hdf_nc-18.8 {check cv 1} {[$in coo 1]} {1 2 3}

Test $hdf_nc-18.9 "overwrite var with unlimited dimension" {
    nap "mat = {{-1 4 2}}"
    $mat $hdf_nc -index "@@4," unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} { 3  9  5
-1  4  2
 9  7  7}

Test $hdf_nc-18.10 {check cv 0} {[$in coo 0]} {2 4 5}

Test $hdf_nc-18.11 {check cv 1} {[$in coo 1]} {1 2 3}

Test $hdf_nc-18.12 "overwrite entire var with unlimited dimension" {
    nap "mat = reshape(1 .. 9, 2#3)"
    $mat $hdf_nc unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} {1 2 3
4 5 6
7 8 9}

Test $hdf_nc-18.13 "overwrite a column of matrix with unlimited dimension" {
    nap "vec = 12 .. 14"
    $vec $hdf_nc -index ",1" unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} { 1 12  3
 4 13  6
 7 14  9}

Test $hdf_nc-18.14 "rank different, no index" {
    $vec $hdf_nc unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} {12 13 14
 4 13  6
 7 14  9}

Test $hdf_nc-18.15 "overwrite a row of matrix with unlimited dimension" {
    nap "vec = 22 .. 24"
    $vec $hdf_nc -index "-1," unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} {12 13 14
 4 13  6
22 23 24}

Test $hdf_nc-18.16 "overwrite element of matrix with unlimited dimension" {
    [nap "55"] $hdf_nc -index "1,2" unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} {12 13 14
 4 13 55
22 23 24}

Test $hdf_nc-18.17 "extend unlimited dimension using CV" {
    nap "time = {5.1}"
    nap "mat = {{9 7 7}}"
    $mat set coo time col
    $mat $hdf_nc unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} {12 13 14
 4 13 55
22 23 24
 9  7  7}

Test $hdf_nc-18.18 {check cv 0} {[$in coo 0]} {2 4 5 5.1}

Test $hdf_nc-18.19 "do not extend unlimited dimension using CV" {
    nap "time = {4.9}"
    nap "mat = {{1 0 9}}"
    $mat set coo time col
    $mat $hdf_nc unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} {12 13 14
 4 13 55
 1  0  9
 9  7  7}

Test $hdf_nc-18.20 {check cv 0} {[$in coo 0]} {2 4 5 5.1}

Test $hdf_nc-18.21 "extend unlimited dimension using CV" {
    nap "time = {6 8 5 2}"
    nap "mat = reshape(-9 .. 9, {4 3})"
    $mat set coo time col
    $mat $hdf_nc unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} { 0  1  2
 4 13 55
-3 -2 -1
 9  7  7
-9 -8 -7
-6 -5 -4}

Test $hdf_nc-18.22 {check cv 0} {[$in coo 0]} {2 4 5 5.1 6 8}

Test $hdf_nc-18.23 {overwrite row} {
    $vec set coo col
    $vec $hdf_nc -index -2, unlimited.$ext mat
    nap "in = [nap_get $hdf_nc unlimited.$ext mat]"
    $in
} { 0  1  2
 4 13 55
-3 -2 -1
 9  7  7
22 23 24
-6 -5 -4}

Test $hdf_nc-18.24 {check cv 0} {[$in coo 0]} {2 4 5 5.1 6 8}

Test $hdf_nc-18.25 {check cv 1} {[$in coo 1]} {1 2 3}

Test $hdf_nc-18.26 "New file: create empty vector without CV but with unlimited dimension" {
    file delete unlimited.$ext
    nap "time = f32 {}"
    $time $hdf_nc -unlimited unlimited.$ext time
    nap "in = [nap_get $hdf_nc unlimited.$ext time]"
    $in da
} f32

Test $hdf_nc-18.27 "write using unlimited dimension but no index" {
    nap "time = f32{3}"
    $time $hdf_nc unlimited.$ext time
    [nap_get $hdf_nc unlimited.$ext time]
} {3}

Test $hdf_nc-18.28 "another write using unlimited dimension but no index" {
    nap "time = f32{1 2.5 0}"
    $time $hdf_nc unlimited.$ext time
    [nap_get $hdf_nc unlimited.$ext time]
} {1 2.5 0}

Test $hdf_nc-18.29 "write vector using unlimited dimension with index, but no extend" {
    nap "time = f32{7 6}"
    $time $hdf_nc -index "1 .. 2" unlimited.$ext time
    [nap_get $hdf_nc unlimited.$ext time]
} {1 7 6}

Test $hdf_nc-18.30 "write scalar using unlimited dimension with index, giving extend" {
    nap "time = 9"
    $time $hdf_nc -index 3 unlimited.$ext time
    [nap_get $hdf_nc unlimited.$ext time]
} {1 7 6 9}

unset col i in time mat vec
put_info "before $hdf_nc-19.1 12"
file delete unlimited.$ext

Test $hdf_nc-19.1 "error handling" {
    nap "v = {-1 4 2}"
    file delete e.$ext
    catch {$v $hdf_nc e.$ext v:a}
} {1}

Test $hdf_nc-19.2 "continue after error" {
    $v $hdf_nc e.$ext v
    nap "in = [nap_get $hdf_nc e.$ext v]"
    file delete e.$ext
    $in
} {-1 4 2}

unset in v
put_info "after $hdf_nc-19.2 12"
