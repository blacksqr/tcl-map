# This makefile generates 4 Tcl extensions - one each for
# gdal, ogr, osr, and gdalconstants.

include ../../GDALmake.opt

all: build

BINDING = tcl
TCL = tclsh
include ../SWIGmake.base

#ZZZ Generate these variables by Configure.in
DESTDIR := $(prefix)
TCL_BINDING_VERSION = 1.0
TCL_MODULES = gdal.so ogr.so gdalconst.so osr.so
TCL_INCLUDE_DIR := /usr/include
TCL_LIB_DIR := /usr/lib
INSTALL_DIR := /lib
SWIGARGS += -namespace -prefix "osgeo" -pkgversion $(TCL_BINDING_VERSION)

TCL_INCLUDE = -I$(TCL_INCLUDE_DIR)
LDFLAGS += -shared -L$(TCL_LIB_DIR)
TCL_LIB := -ltclstub8.5

#ZZZ Make nap optional
TCL_LIB += -lnap6.4

build: $(TCL_MODULES)

clean:
	rm -f *.so
	rm -f *.o
	rm -f *.lo

veryclean: clean
	rm -f $(WRAPPERS)
	rm -frd $(INSTALL_DIR)/osgeo-$(TCL_BINDING_VERSION)

generate: ${WRAPPERS}

$(DESTDIR)$(INSTALL_DIR)/osgeo-$(TCL_BINDING_VERSION):
	mkdir -p $(DESTDIR)$(INSTALL_DIR)/osgeo-$(TCL_BINDING_VERSION)

install: $(DESTDIR)$(INSTALL_DIR)/osgeo-$(TCL_BINDING_VERSION)
	install $(TCL_MODULES) $(DESTDIR)$(INSTALL_DIR)/osgeo-$(TCL_BINDING_VERSION)
	$(TCL) <<< 'pkg_mkIndex $(DESTDIR)$(INSTALL_DIR)/osgeo-$(TCL_BINDING_VERSION) $(TCL_MODULES)'

$(TCL_MODULES): %.so: %_wrap.o
	$(LD) $(LDFLAGS) $(LIBS) $(GDAL_SLIB_LINK) $(TCL_LIB) $< -o $@

%.o: %.cpp
	$(CXX) $(CFLAGS) $(GDAL_INCLUDE) $(TCL_INCLUDE)  -c $<

%.o: %.cxx
	$(CXX) $(CFLAGS) $(GDAL_INCLUDE) $(TCL_INCLUDE) -c $<

%.o: %.c
	$(CC) $(CFLAGS) $(GDAL_INCLUDE)  $(TCL_INCLUDE) -c $<
