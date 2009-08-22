dnl	configure.m4 --
dnl
dnl	Copyright (c) 1999, CSIRO Australia
dnl	Author: Harvey Davies, CSIRO Atmospheric Research
dnl	$Id: configure.m4,v 1.43 2007/11/15 07:39:03 dav480 Exp $
dnl
dnl	This file is an input file used by the GNU "autoconf" program to
dnl	generate the "configure" files for each package.

#------------------------------------------------------------------------------
# Script 'configure' sources file CUSTOMIZE if it exists.
# User can define this file to override values of variables.
# Note that it is sourced again at end to override changed values.
#------------------------------------------------------------------------------

if test -r CUSTOMIZE; then
    . ./CUSTOMIZE
fi

#------------------------------------------------------------------------------
# Define prefix, exec_prefix using m4 macro 'm4default_prefix' defined in
# configure.in
#------------------------------------------------------------------------------

AC_PREFIX_DEFAULT(m4default_prefix)
test "$prefix" = NONE && prefix='m4default_prefix'
prefix=`cd $prefix; pwd`
test "$exec_prefix" = NONE && exec_prefix=$prefix

#------------------------------------------------------------------------------
# PWD = Current directory
# TOP_DIR = its parent (which is assumed to be root of this package)
# ROOT = grandparent (root of all packages)
#------------------------------------------------------------------------------

PWD=`pwd`
AC_SUBST(PWD)
TOP_DIR=`cd ..; pwd`
AC_SUBST(TOP_DIR)
ROOT=`cd ../..; pwd`
AC_SUBST(ROOT)

#------------------------------------------------------------------------------
# Handle command-line option to force use of gcc
#------------------------------------------------------------------------------

SC_ENABLE_GCC

#------------------------------------------------------------------------------
# Use command-line option --enable-ndebug to define CPP macro NDEBUG
#------------------------------------------------------------------------------

AC_ARG_ENABLE(
    ndebug,
    [  --enable-ndebug         define CPP macro NDEBUG],
    AC_DEFINE(NDEBUG)
)

#------------------------------------------------------------------------------
# Handle --enable-symbols option.
#------------------------------------------------------------------------------

SC_ENABLE_SYMBOLS
if test "x$DBGX" = "x"; then
    CFLAGS_VAR='${CFLAGS_OPTIMIZE}'
    LDFLAGS_VAR='${LDFLAGS_OPTIMIZE}'
    CONFIGURE='./configure'
else
    CFLAGS_VAR='${CFLAGS_DEBUG}'
    LDFLAGS_VAR='${LDFLAGS_DEBUG}'
    CONFIGURE='./configure --enable-symbols'
fi
AC_SUBST(DBGX)
AC_SUBST(CFLAGS_VAR)
AC_SUBST(LDFLAGS_VAR)
AC_SUBST(CONFIGURE)

#------------------------------------------------------------------------------
# Define variable "system" to hold the name and version number of operating
# system of host. "HOST_OS" is this name without the version number.
#
#   LINK: Base command to use to link object files into executable shell.
#
# SC_CONFIG_CFLAGS also substitutes CFLAGS_DEBUG & CFLAGS_OPTIMIZE
#	& defines:
#   SHLIB_LD: Base command to use to link object files into shared library.
#   STLIB_LD: Base command to use to link object files into static library.
#   SHLIB_LD_LIBS: libraries for linker to scan when creating shared libraries.
#   SHLIB_SUFFIX: Suffix for shared library (e.g. '.so', '.dll')
#   STLIB_SUFFIX: Suffix for static library (e.g. '.a', '.lib')
#------------------------------------------------------------------------------

HOST_OS=`uname -s`
HOST_OS_LOWER=`uname -s | tr '[A-Z]' '[a-z]'`
AC_SUBST(HOST_OS)
AC_SUBST(HOST_OS_LOWER)
TAR='tar -cf -'
COMPRESS='gzip'
case "$HOST_OS" in
    *win32* | *WIN32* | *CYGWIN_NT*)
        LINK='link'
    ;;
    *)
        LINK='$(CC)'
    ;;
esac
DEBUGGER="dbx"
XDEBUGGER="xxgdb"
case "$HOST_OS" in
    Linux)
	DEBUGGER="gdb"
	XDEBUGGER="ddd"
    ;;
esac
AC_SUBST(COMPRESS)
AC_SUBST(DEBUGGER)
AC_SUBST(XDEBUGGER)
AC_SUBST(LINK)
SC_CONFIG_CFLAGS
AC_SUBST(system)
AC_SUBST(CFLAGS_WARNING)
AC_SUBST(EXTRA_CFLAGS)
AC_SUBST(SHLIB_LD)
AC_SUBST(SHLIB_LD_LIBS)
AC_SUBST(SHLIB_SUFFIX)
AC_SUBST(STLIB_LD)
AC_SUBST(STLIB_SUFFIX)
AC_SUBST(TAR)

#------------------------------------------------------------------------------
#	Locate the X11 header files and the X11 library archive.
#------------------------------------------------------------------------------

case "$HOST_OS" in
    *win32* | *WIN32* | *CYGWIN_NT*)
	XINCLUDES=''
	XLIBSW=''
    ;;
    *)
	SC_PATH_X
    ;;
esac

AC_SUBST(XINCLUDES)
AC_SUBST(XLIBSW)

#------------------------------------------------------------------------------
# Determine other binary file extensions (.o, .obj, .exe etc.)
#------------------------------------------------------------------------------

AC_OBJEXT
AC_EXEEXT

#--------------------------------------------------------------------
# Find ranlib
#--------------------------------------------------------------------

AC_PROG_RANLIB

#--------------------------------------------------------------------
# System libraries
# Substitute MATH_LIBS
#--------------------------------------------------------------------

case "$HOST_OS" in
    *win32* | *WIN32* | *CYGWIN_NT*)
	LIBS=''
	MATH_LIBS=''
    ;;
    *)
	SC_TCL_LINK_LIBS
    ;;
esac

#------------------------------------------------------------------------------
# Purify is program to test for memory leaks, etc.
# Use option --enable-purify to set variable enable_purify to yes/no
#------------------------------------------------------------------------------

AC_ARG_ENABLE(
    purify,
    [  --enable-purify         produce purify version],
    ,
    [enable_purify=no])
if test "$enable_purify" = yes; then
    PURIFY='purify -best-effort -chain-length="10" '
else
    PURIFY=''
fi
AC_SUBST(PURIFY)

#------------------------------------------------------------------------------
# Header (#include) files
#------------------------------------------------------------------------------

AC_CHECK_HEADERS(ieeefp.h)
AC_CHECK_HEADERS(unistd.h)
AC_EGREP_HEADER(_isnan, float.h, AC_DEFINE(ISNAN64, _isnan),
    AC_EGREP_HEADER(isnan, ieeefp.h, AC_DEFINE(ISNAN64, isnan),
	AC_EGREP_HEADER(isnan, math.h, AC_DEFINE(ISNAN64, isnan))))

#------------------------------------------------------------------------------
# Package name and version numbers.
#
# PACKAGE, MAJOR_VERSION, MINOR_VERSION, PATCHLEVEL defined in file package.m4
# included above.
#
# VERSION is MAJOR_VERSION.MINOR_VERSION
#
# NODOT_VERSION is required for constructing the library name on systems 
# (e.g. Windows) that don't like dots in library names.
#
# USE_VERSION is either VERSION or NODOT_VERSION depending on platform
#
# PATCHLEVEL is:
#        a1, a2, ... for alpha releases
#        b1, b2, ... for beta releases
#        .0, .1, ... for official releases
#
# NODOT_PATCHLEVEL is PATCHLEVEL without '.' if any. Used to define CVS_TAG.
# USE_PATCHLEVEL is either PATCHLEVEL or NODOT_PATCHLEVEL depending on platform
#------------------------------------------------------------------------------

VERSION=${MAJOR_VERSION}.${MINOR_VERSION}
NODOT_VERSION=${MAJOR_VERSION}_${MINOR_VERSION}
NODOT_PATCHLEVEL=`echo ${PATCHLEVEL} | tr -d .`

AC_SUBST(PACKAGE)
AC_SUBST(MAJOR_VERSION)
AC_SUBST(MINOR_VERSION)
AC_SUBST(PATCHLEVEL)
AC_SUBST(NODOT_VERSION)
AC_SUBST(VERSION)
AC_SUBST(NODOT_PATCHLEVEL)

TCL_VERSION=$TCL_MAJOR_VERSION.$TCL_MINOR_VERSION
TK_VERSION=$TK_MAJOR_VERSION.$TK_MINOR_VERSION
TAR_SUFFIX=.tar.gz

case "$HOST_OS" in
    *win32* | *WIN32* | *CYGWIN_NT*)
	TCL_USE_VERSION=${TCL_MAJOR_VERSION}${TCL_MINOR_VERSION}
	TK_USE_VERSION=${TK_MAJOR_VERSION}${TK_MINOR_VERSION}
	USE_PATCHLEVEL=$NODOT_PATCHLEVEL
	USE_VERSION=$NODOT_VERSION
    ;;
    *)
	TCL_USE_VERSION=$TCL_VERSION
	TK_USE_VERSION=$TK_VERSION
	USE_PATCHLEVEL=$PATCHLEVEL
	USE_VERSION=$VERSION
    ;;
esac
AC_SUBST(LAND_FLAG_VERSION)
AC_SUBST(TAR_SUFFIX)
AC_SUBST(TCL_VERSION)
AC_SUBST(TK_VERSION)
AC_SUBST(TCL_USE_VERSION)
AC_SUBST(TK_USE_VERSION)
AC_SUBST(USE_PATCHLEVEL)
AC_SUBST(USE_VERSION)

#------------------------------------------------------------------------------
# We put this here so that you can compile with -DVERSION="1.2" to
# encode the package version directly into the source files.
#------------------------------------------------------------------------------

eval AC_DEFINE_UNQUOTED(VERSION, "${VERSION}")
eval AC_DEFINE_UNQUOTED(PATCHLEVEL, "${PATCHLEVEL}")

#------------------------------------------------------------------------------
# A few miscellaneous platform-specific items:
#
# Define a special symbol for Windows (BUILD_$PACKAGE) so
# that we create the export library with the dll.  See sha1.h on how
# to use this.
#
# Windows creates a few extra files that need to be cleaned up.
# You can add more files to clean if your extension creates any extra
# files.
#
# Define any extra compiler flags in the PACKAGE_CFLAGS variable.
# These will be appended to the current set of compiler flags for
# your system.
#
# NATIVE_PATH is command (echo or 'cygpath -m') to print native file path name.
#------------------------------------------------------------------------------

PLATFORM=windows
PLATFORM_DIR=unix
NATIVE_PATH='cygpath -m'
CP='cp -f'
RM='rm -f'
TOUCH='touch'
case "$HOST_OS" in
    *CYGWIN_NT*)
    ;;
    *win32* | *WIN32*)
	PLATFORM_DIR=win
	CP=copy
	RM=del
    ;;
    Linux)
	NATIVE_PATH='echo'
	PLATFORM="${HOST_OS}_`uname -i`"
    ;;
    *)
	NATIVE_PATH='echo'
	PLATFORM=$HOST_OS
    ;;
esac
case "$PLATFORM" in
    windows)
        AC_DEFINE_UNQUOTED(BUILD_$PACKAGE)
	AC_DEFINE(WIN32)
    ;;
esac
AC_SUBST(CP)
AC_SUBST(NATIVE_PATH)
AC_SUBST(PLATFORM)
AC_SUBST(PLATFORM_DIR)
AC_SUBST(RM)
AC_SUBST(TOUCH)

#------------------------------------------------------------------------------
# Locate directories containing the installed header files & libraries
# Note that the list of possible directories is hard-coded, which is not
# at all elegant.
# Also note that the FINAL directory with a matching filename is the one used.
#------------------------------------------------------------------------------

HDF_DLL_DIR=''
HDF_HEADER_DIR=.
HDF_LIB_DIR=.
NC_DLL_DIR=''
NC_HEADER_DIR=.
NC_LIB_DIR=.
PROJ_DATA_DIR=.
PROJ_HEADER_DIR=.
PROJ_LIB_DIR=.
TCL_HEADER_DIR=.
TCL_LIB_DIR=.

for ROOT_DIR in \
	/usr \
	/usr/local \
	$prefix/../.. \
	$prefix/.. \
	$HOME \
	$prefix
do
    for DIR1 in \
	    $ROOT_DIR/tcl \
	    $ROOT_DIR/tcl_new \
	    $ROOT_DIR \
	    $ROOT_DIR/hdf/use \
	    $ROOT_DIR/nc/use \
	    $ROOT_DIR/proj/use \
	    $ROOT_DIR/hdf \
	    $ROOT_DIR/nc \
	    $ROOT_DIR/proj
    do
	for DIR in $DIR1 $DIR1/include* $DIR1/lib $DIR1/dll $DIR1/dlllib $DIR1/bin $DIR1/share/proj
	do
	    if test -r $DIR/hd${HDF_999_VERSION}m.dll; then
		HDF_DLL_DIR=$DIR
	    fi
	    if test -r $DIR/hdf.h; then
		HDF_HEADER_DIR=$DIR
	    fi
	    if test -r $DIR/libmfhdf$STLIB_SUFFIX; then
		HDF_LIB_DIR=$DIR
	    fi
	    if test -r $DIR/hd${HDF_999_VERSION}m.lib; then
		HDF_LIB_DIR=$DIR
	    fi
	    if test -r $DIR/netcdf.dll; then
		NC_DLL_DIR=$DIR
	    fi
	    if test -r $DIR/netcdf.h; then
		if grep "NC_NAT =" $DIR/netcdf.h >/dev/null 2>&1; then
		    NC_HEADER_DIR=$DIR
		fi
	    fi
	    if test -r $DIR/${LIB_PREFIX}netcdf$STLIB_SUFFIX; then
		NC_LIB_DIR=$DIR
	    fi
	    if test -r $DIR/${LIB_PREFIX}nc-dods$STLIB_SUFFIX; then
		NC_LIB_DIR=$DIR
	    fi
	    if test -r $DIR/proj_def.dat; then
		PROJ_DATA_DIR=$DIR
	    fi
	    if test -r $DIR/proj_api.h; then
		PROJ_HEADER_DIR=$DIR
	    fi
	    if test -r $DIR/${LIB_PREFIX}proj$STLIB_SUFFIX; then
		PROJ_LIB_DIR=$DIR
	    fi
	    if test -r $DIR/tcl.h; then
		TCL_HEADER_DIR=$DIR
	    fi
	    TMP=${LIB_PREFIX}tclstub$TCL_USE_VERSION$STLIB_SUFFIX
	    if test -r $DIR/$TMP; then
		TCL_LIB_DIR=$DIR
	    fi
	    TMP=${LIB_PREFIX}tclstub$TCL_USE_VERSION$DBGX$STLIB_SUFFIX
	    if test -r $DIR/$TMP; then
		TCL_LIB_DIR=$DIR
	    fi
	done
    done
done

PLATFORM_MANIFEST=""
case "$HOST_OS" in
    *win32* | *WIN32* | *CYGWIN_NT*)
	TCL_LIB_PATH="$TCL_LIB_DIR/tcl$TCL_USE_VERSION\$(DBGX).lib"
	TK_LIB_PATH="$TCL_LIB_DIR/tk$TK_USE_VERSION\$(DBGX).lib"
	TCL_STUB_LIB_PATH="$TCL_LIB_DIR/tclstub$TCL_USE_VERSION\$(DBGX).lib"
	TK_STUB_LIB_PATH="$TCL_LIB_DIR/tkstub$TK_USE_VERSION\$(DBGX).lib"
	TCL_LINK_SPEC="'`$NATIVE_PATH $TCL_LIB_PATH`'"
	TCL_LINK_SPEC="$TCL_LINK_SPEC '`$NATIVE_PATH $TK_LIB_PATH`'"
	TCL_SHLIB_SPEC="'`$NATIVE_PATH $TCL_STUB_LIB_PATH`'"
	TCL_SHLIB_SPEC="$TCL_SHLIB_SPEC '`$NATIVE_PATH $TK_STUB_LIB_PATH`'"
	TCL_SHLIB_SPEC="$TCL_SHLIB_SPEC $SHLIB_LD_LIBS"
	TCL_LIBRARY_DIR="'`$NATIVE_PATH $TCL_LIB_DIR/tcl$TCL_VERSION`'"
	HDF_LIB_PATH="$HDF_LIB_DIR/hd${HDF_999_VERSION}m.lib"
	HDF_LIB_PATH="$HDF_LIB_PATH $HDF_LIB_DIR/hm${HDF_999_VERSION}m.lib"
	HDF_LIB_DIR="`$NATIVE_PATH $HDF_LIB_DIR`"
	HDF_LIB_SPEC="'$HDF_LIB_DIR/hd${HDF_999_VERSION}m.lib'"
	HDF_LIB_SPEC="$HDF_LIB_SPEC '$HDF_LIB_DIR/hm${HDF_999_VERSION}m.lib'"
	NC_LIB_PATH="$NC_LIB_DIR/netcdf.lib"
	NC_LIB_DIR="`$NATIVE_PATH $NC_LIB_DIR`"
	NC_LIB_SPEC="'$NC_LIB_DIR/netcdf.lib'"
	PROJ_LIB_PATH="$PROJ_LIB_DIR/proj.lib"
	PROJ_LIB_DIR="`$NATIVE_PATH $PROJ_LIB_DIR`"
	PROJ_LIB_SPEC="'$PROJ_LIB_DIR/proj.lib'"
	SHLIB_DIR="\${bindir}"
	SHLIB_DIR_BASE=bin
	TMP="$TCL_LIB_DIR/nap$USE_VERSION\${DBGX}.lib"
	NAP_LIB_SPEC="'`$NATIVE_PATH $TMP`'"
	PLATFORM_MANIFEST="bin/h*m.dll bin/netcdf.dll lib/\$(PACKAGE_IMPORT_LIB)"
	PLATFORM_MANIFEST="$PLATFORM_MANIFEST lib/ezprint$EZPRINT_VERSION/*"
    ;;
    *)
	TCL_LIB_FLAG="-ltcl$TCL_VERSION\$(DBGX)"
	TK_LIB_FLAG="-ltk$TK_VERSION\$(DBGX)"
	TCL_STUB_LIB_FLAG="-ltclstub$TCL_VERSION\$(DBGX)"
	TK_STUB_LIB_FLAG="-ltkstub$TK_VERSION\$(DBGX)"
	TCL_LINK_SPEC="-L$TCL_LIB_DIR $TCL_LIB_FLAG $TK_LIB_FLAG"
	TCL_SHLIB_SPEC="-L$TCL_LIB_DIR $TCL_STUB_LIB_FLAG $TK_STUB_LIB_FLAG $SHLIB_LD_LIBS"
	HDF_LIB_SPEC="-L$HDF_LIB_DIR -lmfhdf -ldf -ljpeg -lz"
	NAP_LIB_SPEC="-L$TCL_LIB_DIR -lnap$USE_VERSION\${DBGX}"
	TCL_LIBRARY_DIR=$TCL_LIB_DIR/tcl$TCL_VERSION
	TCL_LIB_PATH="$TCL_LIB_DIR/libtcl$TCL_VERSION\$(DBGX)$SHLIB_SUFFIX"
	TMP="libtclstub$TCL_VERSION\$(DBGX)$STLIB_SUFFIX"
	TCL_STUB_LIB_PATH="$TCL_LIB_DIR/$TMP"
	TMP="libtkstub$TK_VERSION\$(DBGX)$STLIB_SUFFIX"
	TK_STUB_LIB_PATH="$TCL_LIB_DIR/$TMP"
	HDF_LIB_PATH="$HDF_LIB_DIR/libdf$STLIB_SUFFIX"
	HDF_LIB_PATH="$HDF_LIB_PATH $HDF_LIB_DIR/libmfhdf$STLIB_SUFFIX"
	NC_LIB_PATH="$NC_LIB_DIR/libnetcdf$STLIB_SUFFIX"
	if test -r $NC_LIB_PATH; then
	    NC_LIB_SPEC="-L$NC_LIB_DIR -lnetcdf"
	else
	    NC_LIB_PATH="$NC_LIB_DIR/libnc-dods$STLIB_SUFFIX"
	    NC_LIB_SPEC="-L$NC_LIB_DIR -lnc-dods -ldap++ -lnc-dods -ldap++ -lcurl -lxml2"
	    NC_LIB_SPEC="$NC_LIB_SPEC -lpthread -lssl -lstdc++"
	fi
	PROJ_LIB_PATH="$PROJ_LIB_DIR/libproj$STLIB_SUFFIX"
	PROJ_LIB_SPEC="-L$PROJ_LIB_DIR -lproj"
	SHLIB_DIR="\${libdir}"
	SHLIB_DIR_BASE=lib
	if test "x$X11_LIB_SWITCHES" = "x"; then
	    X11_LIB_SWITCHES="-lX11"
	fi
    ;;
esac

LD_LIBRARY_PATH=`$NATIVE_PATH $TCL_LIB_DIR`:$LD_LIBRARY_PATH

AC_SUBST(HDF_DLL_DIR)
AC_SUBST(HDF_HEADER_DIR)
AC_SUBST(HDF_LIB_SPEC)
AC_SUBST(LD_LIBRARY_PATH)
AC_SUBST(NAP_LIB_SPEC)
AC_SUBST(NC_DLL_DIR)
AC_SUBST(NC_HEADER_DIR)
AC_SUBST(NC_LIB_SPEC)
AC_SUBST(PROJ_DATA_DIR)
AC_SUBST(PROJ_HEADER_DIR)
AC_SUBST(PROJ_LIB_SPEC)
AC_SUBST(PLATFORM_MANIFEST)
AC_SUBST(TCL_HEADER_DIR)
AC_SUBST(TCL_LIB_DIR)
AC_SUBST(TCL_LIBRARY_DIR)
AC_SUBST(TCL_LINK_SPEC)
AC_SUBST(TCL_SHLIB_SPEC)
AC_SUBST(TCL_LIB_PATH)
AC_SUBST(TCL_STUB_LIB_PATH)
AC_SUBST(TK_STUB_LIB_PATH)
AC_SUBST(HDF_LIB_PATH)
AC_SUBST(NC_LIB_PATH)
AC_SUBST(PROJ_LIB_PATH)
AC_SUBST(SHLIB_DIR)
AC_SUBST(SHLIB_DIR_BASE)
AC_SUBST(X11_LIB_SWITCHES)
AC_SUBST(bindir)
AC_SUBST(libdir)

AC_MSG_RESULT([Using HOST_OS=$HOST_OS])
AC_MSG_RESULT([Using HDF_VERSION=$HDF_VERSION])
AC_MSG_RESULT([Using HDF_DLL_DIR=$HDF_DLL_DIR])
AC_MSG_RESULT([Using HDF_LIB_DIR=$HDF_LIB_DIR])
AC_MSG_RESULT([Using HDF_HEADER_DIR=$HDF_HEADER_DIR])
AC_MSG_RESULT([Using HDF_LIB_SPEC=$HDF_LIB_SPEC])
AC_MSG_RESULT([Using NC_DLL_DIR=$NC_DLL_DIR])
AC_MSG_RESULT([Using NC_LIB_DIR=$NC_LIB_DIR])
AC_MSG_RESULT([Using NC_HEADER_DIR=$NC_HEADER_DIR])
AC_MSG_RESULT([Using NC_LIB_SPEC=$NC_LIB_SPEC])
AC_MSG_RESULT([Using PROJ_DATA_DIR=$PROJ_DATA_DIR])
AC_MSG_RESULT([Using PROJ_LIB_DIR=$PROJ_LIB_DIR])
AC_MSG_RESULT([Using PROJ_HEADER_DIR=$PROJ_HEADER_DIR])
AC_MSG_RESULT([Using PROJ_LIB_SPEC=$PROJ_LIB_SPEC])
AC_MSG_RESULT([Using TCL_HEADER_DIR=$TCL_HEADER_DIR])
AC_MSG_RESULT([Using TCL_LIBRARY_DIR=$TCL_LIBRARY_DIR])
AC_MSG_RESULT([Using TCL_LINK_SPEC=$TCL_LINK_SPEC])
AC_MSG_RESULT([Using TCL_SHLIB_SPEC=$TCL_SHLIB_SPEC])

#------------------------------------------------------------------------------
# Find tclsh & wish
#------------------------------------------------------------------------------

AC_PATH_PROGS(TCLSH_PROG,
	tclsh$TCL_VERSION$EXEEXT tclsh$TCL_USE_VERSION$EXEEXT tclsh$EXEEXT,
	-,
        ${exec_prefix}/bin:${PATH}:${TCL_SRC_DIR}/${PLATFORM_DIR})
if test "${TCLSH_PROG}" = "-" ; then
    AC_MSG_WARN(No tclsh executable found.)
fi
AC_SUBST(TCLSH_PROG)

AC_PATH_PROGS(WISH_PROG,
	wish$TCL_VERSION$EXEEXT wish$TCL_USE_VERSION$EXEEXT wish$EXEEXT,
	-,
        ${exec_prefix}/bin:${PATH}:${TCL_SRC_DIR}/${PLATFORM_DIR})
if test "${WISH_PROG}" = "-" ; then
    AC_MSG_WARN(No wish executable found.)
fi
AC_SUBST(WISH_PROG)

#------------------------------------------------------------------------------
# Define CC_MAKEDEPEND which is command used to make file depend.mk
#------------------------------------------------------------------------------

AC_CHECK_PROG(CC_MAKEDEPEND, gcc, gcc, ${CC})
if test "$CC_MAKEDEPEND" = "gcc"; then
    CC_MAKEDEPEND_FLAGS='-MM'
else
    CC_MAKEDEPEND_FLAGS='-M' 
    case $HOST_OS in
        SunOS)
            case `uname -r` in
                5*)
                    CC_MAKEDEPEND_FLAGS='-xM'
                    ;;
            esac 
            ;;
    esac
fi
CC_MAKEDEPEND="$CC_MAKEDEPEND $CC_MAKEDEPEND_FLAGS"
AC_SUBST(CC_MAKEDEPEND)

#------------------------------------------------------------------------------
# m4
#------------------------------------------------------------------------------

AC_PATH_PROGS(M4PROG, m4, :, ${exec_prefix}/bin:${PATH})
if test "${M4PROG}" = ":" ; then
    AC_MSG_WARN(No m4 executable found.)
fi
M4FLAGS='-s'
AC_SUBST(M4PROG)
AC_SUBST(M4FLAGS)

#------------------------------------------------------------------------------
# Miscellaneous
#------------------------------------------------------------------------------

ECHO="printf '%s\n'"
AC_SUBST(ECHO)

#------------------------------------------------------------------------------
# As mentioned above, we source "CUSTOMIZE" again to override changed values.
#------------------------------------------------------------------------------

if test -r CUSTOMIZE; then
    . ./CUSTOMIZE
fi

#------------------------------------------------------------------------------
# Tell user values of prefix & exec_prefix
#------------------------------------------------------------------------------

AC_MSG_RESULT([Using prefix=$prefix])
AC_MSG_RESULT([Using exec_prefix=$exec_prefix])
