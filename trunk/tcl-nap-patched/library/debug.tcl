# debug.tcl --
#
# Debugging procedures
#
# Copyright (c) 2003, CSIRO Australia
# Author: Harvey Davies, CSIRO.
# $Id: debug.tcl,v 1.2 2003/08/21 04:57:06 dav480 Exp $


# echo --
#
# Write arguments to stdout (Like echo in Unix shells)

proc echo args {puts $args}


# trace_command --
#
# Trace specified command
#
# Usage:
#   trace_command <COMMAND> ?<OPS>? ?<COMMAND>?
#	<COMMAND>: Name of command
#	<OPS>: Operations to be traced (Default: enter leave)
#	<COMMAND>: Command to be invoked (Default: echo)

proc trace_command {
    c
    {ops {enter leave}}
    {command echo}
} {
    trace add execution $c $ops $command
}


# trace_proc --
#
# Trace specified procedure
#
# Usage:
#   trace_proc <PROC> ?<OPS>? ?<COMMAND>?
#	<PROC>: Name of procedure
#	<OPS>: Operations to be traced (Default: all i.e. enter leave enterstep leavestep)
#	<COMMAND>: Command to be invoked (Default: echo)

proc trace_proc {
    p
    {ops {enter leave enterstep leavestep}}
    {command echo}
} {
    trace add execution $p $ops $command
}


# trace_script --
#
# Trace specified Tcl script file containing simple single-line commands
#
# Usage:
#   trace_script <SCRIPT_FILE>
#	<SCRIPT_FILE>: Name of file containing script

proc trace_script {
    file_name
} {
    if [catch {set f [open $file_name r]} message] {
        error $message
    }
    while {[gets $f line] >= 0} {
	puts "% $line"
	set code [catch {uplevel 1 $line} result]
	if {$code == 0} {
	    puts $result
	} else {
	    puts "Error! code=$code result=$result"
	}
    }
    close $f
}


# All code below is from following Wiki URL:
# http://mini.net/tcl/6007
# which is under "Category Debugging | Arts and crafts of Tcl-Tk programming"
# Page contributed by Richard Suchenwirth 2002-12-17 & titled "Steppin' out"
# He includes following comments:
#
# This is my first experiment with the command traces introduced in Tcl 8.4: step through certain
# procs, so that every command inside the body is displayed before execution, and its result after,
# while allowing to execute arbitrary Tcl commands at such step positions. This is of course a
# powerful debugging tool.
# The code below requires stdin/out, so under Windows is best run from a tclsh.
# At the stepping prompt, <Return> lets you advance through the code.

proc stepping name {
    trace add exec $name enterstep enterStep
    trace add exec $name leavestep leaveStep
    if {![info exists ::Entered]} {set ::Entered ""} ;# Workaround
}

proc noStepping name {
    trace remove exec $name enterstep enterStep
    trace remove exec $name leavestep leaveStep
}

proc enterStep {cmd _} {
    set ::Entered $cmd ;# Workaround
    uplevel 1 [list bp "before $cmd"]
}

proc leaveStep {cmd code result _} {
     if {$cmd eq $::Entered} { ;# Workaround
	 uplevel 1 [list bp "result ($code):$result<=$cmd"]
     }
}

#-- reusable breakpoint handler from A minimal debugger

proc bp s {
    if {[string length $s]>50} {set s [string range $s 0 49]...}
    while 1 {
	puts -nonewline "$s > "
	flush stdout
	gets stdin line
	if {$line==""} break
	catch {uplevel 1 $line} res
	puts $res
    }
}
