#!/usr/bin/tclsh
set Copied [list]

set Blacklist [list \
libstdc++.so \
libm.so \
libc.so \
libgcc_s.so \
libpthread.so \
libz.so \
libresolv.so \
librt.so \
libxcb*.so \
libX*.so \
libdrm.so \
libGL.so \
libGLU.so \
libuuid.so \
libdl.so \
libnsl.so \
]

proc addlibs {name copyto {depth 0}} {
    global Copied

    set deps [exec ldd $name]

    foreach line [split $deps "\n"] {
        if {"=>" ni $line} { continue }

        lassign [split $line "=>"] name _ rest
        lassign [split $rest "("] lib
        set name [string trim $name]
        set lib [string trim $lib]

        if {$lib eq ""} { continue }
        if {$name in $Copied} { continue }

        if {! [file exists $lib]} { 
        	puts "[string repeat \t $depth]Non-existing.. $name from $lib"
		continue
	}
        if {[inblist $name]} { 
        	puts "[string repeat \t $depth]Blacklisted.. $name from $lib"
		continue
	}

        puts "[string repeat \t $depth]Adding.. $name from $lib"
        file copy -force -- {*}[glob ${lib}*] $copyto
        lappend Copied $name
        addlibs $lib $copyto [expr {$depth+1}]
    }
}

proc inblist {name} {
    global Blacklist

    foreach lib $Blacklist {
        if {[string match ${lib}* $name]} {
            return 1
        }
    }
    return 0
}

if {[llength $::argv] != 2} { error "$::argv0 library destination"}

lassign $::argv library destination
addlibs $library $destination
