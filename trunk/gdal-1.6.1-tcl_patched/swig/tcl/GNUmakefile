# This makefile generates 4 Tcl extensions - one each for
# gdal, ogr, osr, and gdalconstants.

include ../../GDALmake.opt

all: build

BINDING = tcl
TCL = tclsh

#XXX Generate these variables by Configure.in.
#XXX Use tcl's tcl.m4 in gdal's configure.
DESTDIR := $(prefix)
TCL_BINDING_VERSION = 1.0
TCL_MODULES = gdal.so ogr.so gdalconst.so osr.so
TCL_INCLUDE_DIR := /home/alsterg/Projects/tcl-osgeo/cross-tools/TCL/kbskit/Linux/include
#TCL_INCLUDE_DIR := /usr/include
TCL_LIB_DIR := /home/alsterg/Projects/tcl-osgeo/cross-tools/TCL/kbskit/Linux/lib
#TCL_LIB_DIR := /usr/lib
INSTALL_DIR := /lib

TCL_INCLUDE = -I$(TCL_INCLUDE_DIR)
LDFLAGS += -pipe -static -L$(TCL_LIB_DIR) -ldl  -lieee -lm
#LDFLAGS += -pipe -shared -L$(TCL_LIB_DIR) -ldl  -lieee -lm
TCL_LIB := -ltclstub8.5

SWIG = swig
SWIGARGS = -pkgversion $(TCL_BINDING_VERSION) -Wall -I../include -I../include/$(BINDING) -I../include/$(BINDING)/docs
SWIGOUTPUTDIR=

WRAPPERS = gdal_wrap.cpp gdalconst_wrap.c ogr_wrap.cpp osr_wrap.cpp

gdal_wrap.cpp: ../include/gdal.i ../include/MajorObject.i ../include/Driver.i ../include/Dataset.i ../include/Band.i ../include/ColorTable.i ../include/cpl.i ../include/$(BINDING)/typemaps_$(BINDING).i
	$(SWIG) -namespace -prefix "gdal" $(SWIGARGS) $(SWIGDEFINES) -I$(GDAL_ROOT) -c++ -$(BINDING) -o $(SWIGOUTPUTDIR)$@ gdal.i

gdalconst_wrap.c: ../include/gdalconst.i
	$(SWIG) -namespace -prefix "gdal" $(SWIGARGS) $(SWIGDEFINES) -I$(GDAL_ROOT) -$(BINDING) -o $(SWIGOUTPUTDIR)$@ gdalconst.i

ogr_wrap.cpp:  ../include/ogr.i ../include/$(BINDING)/typemaps_$(BINDING).i
	$(SWIG) -namespace -prefix "ogr" $(SWIGARGS) $(SWIGDEFINES) -I$(GDAL_ROOT) -c++ -$(BINDING) -o $(SWIGOUTPUTDIR)$@ ogr.i

osr_wrap.cpp:  ../include/osr.i ../include/$(BINDING)/typemaps_$(BINDING).i
	$(SWIG) -namespace -prefix "osr" $(SWIGARGS) $(SWIGDEFINES) -I$(GDAL_ROOT) -c++ -$(BINDING) -o $(SWIGOUTPUTDIR)$@ osr.i

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
