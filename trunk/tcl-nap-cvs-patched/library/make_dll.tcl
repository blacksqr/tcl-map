# make_dll.tcl --
# 
# Copyright (c) 2000, CSIRO Australia
# Author: Harvey Davies, CSIRO Atmospheric Research
# $Id: make_dll.tcl,v 1.35 2005/07/20 07:37:06 dav480 Exp $


# make_dll --

# Make DLL ('dynamic-link library' or 'shared library') defining new tcl
# command based on User's C function or Fortran subroutine.
#
# Usage
#    make_dll ?OPTIONS? <COMMAND> <ARG_DEC> <ARG_DEC> <ARG_DEC> ...
#       where <COMMAND> is name of new command 
#       and each argument-declaration <ARG_DEC> has the form:
#	   {<NAME> <TYPE> <INTENT>}
#          where <NAME> is any string (used only in error messages)
#                <TYPE> can be:
#                    c8 i8 u8 i16 u16 i32 u32 f32 f64 void
#                <INTENT> can be: in (default) or inout. Actual "in" arguments
#                 can be expressions of any type (including ragged) and will be
#                 converted to the specified type (unless this is void).
#       Options are:
#	   -quiet: Do not echo commands.
#          -compile <command>: C compile command with options
#          -dll <filename>: output DLL (default: <COMMAND>.dll for windows,
#		<COMMAND>.sl for HP-UX, <COMMAND>.so for other unix)
#          -entry <string>: User-routine entry-point (default: <COMMAND>)
#		Note that fortran entry points often include suffix '_'.
#          -header <filename>: header (*.h) filename (default: none)
#          -libs <filenames>: filenames of extra binary libraries (default: none)
#          -link <command>: Link command with options
#          -object <filename>: User-routine object-file (default: <COMMAND>.obj
#		for windows, <COMMAND>.o for unix)
#          -source <filename>: C source of interface (default: <COMMAND>_i.c)
#          -version <n.m>: Version number (default: 1.0)
#
# Example
#    make_dll pprod {n i32} {x f32} {y f32 inout}
#
# This could be used to define a tcl command 'pprod' (analogous to the standard
# nap function 'psum') using the following C file 'pprod.c' defining the
# function 'pprod' which calculates partial-products.
#
#   void pprod(int *n, float *x, float *result) {
#       int         i;
#       float       prod = 1;
#   
#       for (i = 0; i < *n; i++) {
#           result[i] = prod = prod * x[i];
#       }
#   }
#
# make_dll creates a DLL (shared-library) file named:
# pprod.dll (windows), libpprod.sl (HP-UX) or libpprod.so (other unix).
#
# You can use this directly within tcl as follows:
#
#   load ./libpprod.so
#   nap "a = {2f 1.5f 3f 0.5f}"
#   nap "result = +a"; # create result array with same shape as a
#   pprod "nels(a)" a result
#   $result
#
# The result is "2 3 9 4.5"
#
# However it would normally be better to provide a tcl proc interface
# defining a nap function.  For example to define a function 'partialProd':
#
#   proc partialProd x {
#       # create f32 result array with same shape as x
#       set result [nap "reshape(0f, shape(x))"]
#       pprod "nels(x)" x result
#       return $result
#   }
#   [nap "partialProd({2 1.5 3 0.5})"]
#
# The result is again "2 3 9 4.5"
#
#
# You can do the same thing in fortran 90 using the following source code:
#
#   subroutine pprod(n, x, result)
#       integer, intent(in) :: n
#       real, intent(in) :: x(n)
#       real, intent(out) :: result(n)
#       integer :: i
#       real :: prod
#       prod = 1.0
#       do i = 1, n
#           prod = prod * x(i)
#           result(i) = prod
#       end do
#   end subroutine pprod
#
#   The entry point is 'pprod_' so the make_dll command is:
#   make_dll -entry pprod_ pprod {n i32 in} {x f32} {y f32 inout}

proc make_dll args {
    set tcl_lib     "[file nativename [file dirname $::tcl_library]]"
    set tcl_root    "[file dirname [file dirname $::tcl_library]]"
    set tcl_include "[file nativename [lindex [glob $tcl_root/include*] end]]"
    switch $::tcl_platform(platform) {
	unix {
	    set compile "cc -I$tcl_include -c"
	    set lib_prefix lib
	    set std_libs ""
	    set obj_ext o
	}
	windows {
	    set compile \
		    "cl {-I$tcl_include} -c -DWIN32=1 -nologo -MD -Ox -W1"
	    set lib_prefix ""
	    set vclib {c:\Program Files\Microsoft Visual Studio\VC98\lib}
	    set std_libs "\
		    {$tcl_lib\\nap[string     map {.  _} $::nap_version].lib}\
		    {$tcl_lib\\tclstub[string map {. {}} $::tcl_version].lib}\
		    {$vclib\\msvcrt.lib}\
		    {$vclib\\oldnames.lib}\
		    {$vclib\\kernel32.lib}\
		    "
	    set obj_ext obj
	}
    }
    switch -glob $::tcl_platform(os) {
	Darwin   {
	    set compile "cc -no-cpp-precomp -fno-common -I$tcl_include -c"
	    set link "cc -dynamiclib -single_module -flat_namespace -undefined suppress -o "
	}
	HP-UX	 {
	    set compile "cc +z -I$tcl_include -c"
	    set link "ld -b -o "
	}
	IRIX64	 {set link "ld -shared -n32 -rdata_shared -o "}
	Linux    {set link "ld -shared -o "}
	SunOS    {set link "ld -G -o "}
	Windows* {
	    set link "link -dll -nologo -implib:tmp.lib -nodefaultlib \
		    -release -out:"
	}
    }
    set quiet 0
    set dll ""
    set entry ""
    set extra_libs ""
    set header ""
    set object ""
    set source ""
    set version "1.0"
    set i [process_options {
	    {-quiet   {set quiet   1}}
	    {-compile {set compile $option_value}}
	    {-dll     {set dll     $option_value}}
	    {-entry   {set entry   $option_value}}
	    {-header  {set header  $option_value}}
	    {-libs    {set extra_libs $option_value}}
	    {-link    {set link    $option_value}}
	    {-object  {set object  $option_value}}
	    {-source  {set source  $option_value}}
	    {-version {set version $option_value}}
	} $args]
    set command [lindex $args $i]
    default entry $command
    default dll $lib_prefix$command[info sharedlibextension]
    default object $command.$obj_ext
    default source ${command}_i.c
    incr i
    set arg_decs [lrange $args $i end]
    regsub {c$} $source $obj_ext source_obj
    puts_file $source [eval make_dll_i -entry $entry -header {$header} -version $version \
	    $command $arg_decs]
    eval_exec $quiet "$compile $source"
    eval_exec $quiet "$link$dll $source_obj $object $extra_libs $std_libs"
    return
}


proc eval_exec {quiet command} {
    if {!$quiet} {
	puts $command
    }
    set status [catch "exec $command" msg]
    if {$status && !$quiet} {
	puts "eval_exec: Error in above command. Status = $status\n$msg"
    }
    return
}


# make_dll_i --
#
# Make NAP C interface to User's C function or Fortran subroutine.
# Normally used via make_dll, but may be used directly if you prefer to
# do your own compiling and linking.  The result of make_dll_i is the C code.
#
# Usage
#    make_dll_i ?OPTIONS? <COMMAND> <ARG_DEC> <ARG_DEC> <ARG_DEC> ...
#       where <COMMAND> is name of new command 
#       and each <ARG_DEC> has the form: {<NAME> <TYPE> <INTENT>}
#          where <NAME> is any string (used only in error messages)
#                <TYPE> can be:
#                    c8 i8 u8 i16 u16 i32 u32 f32 f64 void
#                <INTENT> can be: in (default) or inout. Actual "in" arguments
#                 can be expressions of any type (including ragged) and will be
#                 converted to the specified type (unless this is void).
#       Options are:
#          -entry <string>: User-routine entry-point (default: <COMMAND>)
#          -header <filename>: header (*.h) filename (default: none)
#          -version <n.m>: Version number (default:  1.0)
#
# Example
#    puts_file pprod_i.c [make_dll_i pprod {n i32} {x f32} {y f32 inout}]

proc make_dll_i args {
    set entry ""
    set header ""
    set version "1.0"
    set i [process_options {
	    {-entry   {set entry   $option_value}}
	    {-header  {set header  $option_value}}
	    {-version {set version $option_value}}
	} $args]
    set command [lindex $args $i]
    default entry $command
    incr i
    set arg_decs [lrange $args $i end]
    set valid_types {c8 i8 u8 i16 u16 i32 u32 f32 f64 void}
    set valid_intents {in inout}
    set num_args [llength $arg_decs]
    for {set i 0} {$i < $num_args} {incr i} {
	set arg_dec [lindex $arg_decs $i]
	switch [llength $arg_dec] { 
	    2		{lappend arg_dec in}
	    3		{}
	    default	{error "Bad declaration for argument $i ($arg_dec)"}
	}
	lappend names [lindex $arg_dec 0]
	set type [lindex $arg_dec 1]
	if {[lsearch $valid_types $type] < 0} {
	    error "Bad type in declaration for argument $i ($arg_dec)"
	}
	lappend types [Make_dll::capitalise1 $type]
	set intent [lindex $arg_dec 2]
	if {[lsearch $valid_intents $intent] < 0} {
	    error "Bad intent in declaration for argument $i ($arg_dec)"
	}
	lappend intents $intent
    }
    set str "[Make_dll::head $entry $header $command $num_args]"
    for {set i 0} {$i < $num_args} {incr i} {
	set name [lindex $names $i]
	set type [lindex $types $i]
	set intent [lindex $intents $i]
	if {$intent == "in"} {
	    set str "$str[Make_dll::get_in    $command $i $name $type]"
	} else {
	    set str "$str[Make_dll::get_inout $command $i $name $type]"
	}
    }
    set str "${str}\n        (void) ${entry}("
    for {set i 0} {$i < $num_args} {incr i} {
	set is_final [expr "$i == $num_args-1"]
	set str "$str[Make_dll::call_arg $entry $types $i $is_final]"
    }
    for {set i 0} {$i < $num_args} {incr i} {
	switch [lindex $intents $i] {
	    in {set str "${str}\n        Nap_DecrRefCount(nap_cd, naoPtr\[$i\]);"}
	}
    }
    set str "$str[Make_dll::tail $command $version $names]"
    regsub -all { *\n} $str "\n" result
    return $result
}


namespace eval Make_dll {


    # capitalise1 --
    #
    # Capitalise 1st character of string

    proc capitalise1 str {
	set first_letter [string index $str 0]
	set rest [string range $str 1 end]
	return "[string toupper $first_letter]$rest"
    }


    # head --

    proc head {
	entry
	header
	command
	num_args
    } {
	set date [clock format [clock seconds] -format %Y-%m-%d]
	set tod  [clock format [clock seconds] -format %H:%M]
	if {$header != ""} {
	    set header "\n#include \"$header\""
	}
	return \
	 "/*\
	\n *  This file was generated by tcl procedure 'make_dll_i'\
	\n *  on $date at $tod.\
	\n *  It defines interface between tcl command '$command' and\
	\n *  C/Fortran function/subroutine '$entry'.\
	\n */\
	\n\
	\n#define USE_TCL_STUBS 1\
	\n#include <nap.h>\
	$header\
	\n\
	\n#undef  TCL_STORAGE_CLASS\
	\n#define TCL_STORAGE_CLASS DLLEXPORT\
	\n\
	\n#define NUM_ARGS $num_args\
	\n\
	\nint\
	\n[capitalise1 $command]Int(\
	\n    ClientData          clientData,\
	\n    Tcl_Interp          *interp,\
	\n    int                 objc,\
	\n    Tcl_Obj *CONST      objv\[\])\
	\n\{\
	\n    NapClientData       *nap_cd = Nap_GetClientData(interp);\
	\n    Nap_NAO             *naoArgPtr;\
	\n    Nap_NAO             *naoPtr\[NUM_ARGS\];\
	\n    char                *arg;\
	\n\
	\n    if (objc == NUM_ARGS + 1) \{\
	"
    }


    # get_in --

    proc get_in {
	command
	i
	name
	type
    } {
	set i1 [expr "$i+1"]
	set str "\
		\n        arg = Tcl_GetStringFromObj(objv\[$i1\], NULL);\
		"
	if {$type == "Void"} {
	    set str "$str\
		\n        naoArgPtr = Nap_GetNaoFromId(nap_cd, arg);\
		\n        if (naoArgPtr) \{\
		\n            Nap_IncrRefCount(nap_cd, naoArgPtr);\
		"
	} else {
	    set TYPE "NAP_[string toupper $type]"
	    set str "$str\
		\n        naoArgPtr = Nap_GetNumericNaoFromId(nap_cd, arg);\
		\n        if (naoArgPtr) \{\
		\n            naoPtr\[$i\] = Nap_CastNAO(nap_cd, naoArgPtr, $TYPE);\
		\n            Nap_IncrRefCount(nap_cd, naoPtr\[$i\]);\
		\n            Nap_IncrRefCount(nap_cd, naoArgPtr);\
		\n            Nap_DecrRefCount(nap_cd, naoArgPtr);\
		"
	}
	set str "$str\
	    \n        \} else \{\
	    \n            Tcl_SetResult(interp,\
	    \n                \"$command: Argument $i1 ($name) is not\
			      NAO\\n\", NULL);\
	    \n            return TCL_ERROR;\
	    \n        \}\
	    "
	return $str
    }


    # get_inout --

    proc get_inout {
	command
	i
	name
	type
    } {
	set i1 [expr "$i+1"]
	set str "\
	    \n        arg = Tcl_GetStringFromObj(objv\[$i1\], NULL);\
	    \n        naoPtr\[$i\] = Nap_GetNaoFromId(nap_cd, arg);\
	    \n        if (naoPtr\[$i\]) \{\
	    "
	if {$type != "Void"} {
	    set TYPE "NAP_[string toupper $type]"
	    set str "$str\
		\n            if (naoPtr\[$i\]->dataType != $TYPE) \{\
		\n                Tcl_SetResult(interp,\
		\n                    \"$command: Argument $i1 ($name)\
			      is not $type\\n\", NULL);\
		\n                return TCL_ERROR;\
		\n            \}\
		"
	}
	set str "$str\
	    \n        \} else \{\
	    \n            Tcl_SetResult(interp,\
	    \n                \"$command: Argument $i1 ($name) is not\
			      NAO\\n\", NULL);\
	    \n            return TCL_ERROR;\
	    \n        \}\
	    "
	return $str
    }


    # call_arg --

    proc call_arg {
	entry
	types
	i
	is_final
    } {
	set s(0) ","
	set s(1) ");"
	set suffix $s($is_final)
	set type [lindex $types $i]
	if {$type == "Void"} {
	    set str "\
		\n                (void *) naoPtr\[$i\]->data.C8$suffix\
		"
	} else {
	    set str "\
		\n                naoPtr\[$i\]->data.$type$suffix\
		"
	}
	return $str
    }


    # tail --

    proc tail {
	command
	version
	names
    } {
	return "\
	\n    \} else \{\
	\n        Tcl_WrongNumArgs(interp, 1, objv, \"$names\");\
	\n        return TCL_ERROR;\
	\n    \}\
	\n    Tcl_ResetResult(interp);\
	\n    return TCL_OK;\
	\n\}\
	\n\
	\nEXTERN int\
	\n[capitalise1 $command]_Init(\
	\n    Tcl_Interp          *interp)\
	\n\{\
	\n    int                 status;\
	\n\
	\n    if (Tcl_InitStubs(interp, \"8.0\", 0) == NULL) \{\
	\n        status = TCL_ERROR;\
	\n    \} else \{\
	\n        Tcl_CreateObjCommand(interp, \"$command\", \
		[capitalise1 $command]Int, NULL, NULL);\
	\n        Tcl_PkgProvide(interp, \"$command\", \"$version\");\
	\n        Tcl_SetVar(interp, \"${command}_version\", \"$version\", TCL_GLOBAL_ONLY);\
	\n        status = TCL_OK;\
	\n    \}\
	\n    return status;\
	\n\}\
	\n"
    }


}
