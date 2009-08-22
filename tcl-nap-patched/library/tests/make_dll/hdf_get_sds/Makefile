CC = cc
CFLAGS = -I$(HOME)/hdf/use/include

OBJ_EXT = o
DLL_EXT = so
DLL_PREFIX = lib

MAKE_DLL = make_dll hdf_get_sds \
	{filename c8 in} \
	{sds_name c8 in} \
	{start i32 in} \
	{stride i32 in} \
	{edge i32 in} \
	{data void inout} \
	{status i32 inout}

test: out.txt
	echo '1 9 0 99 5 5 5 5' | diff - out.txt

out.txt: $(DLL_PREFIX)hdf_get_sds.$DLL_EXT in.tcl
	tclsh < in.tcl

$(DLL_PREFIX)hdf_get_sds.$DLL_EXT: hdf_get_sds.$OBJ_EXT
	echo 'source ../../../make_dll.tcl; $(MAKE_DLL)' | tclsh

hdf_get_sds.$OBJ_EXT: hdf_get_sds.c 
	$(CC) -c $(CFLAGS) hdf_get_sds.c

clean:
	rm -f *.o *.so core hdf_get_sds_i.c out.txt *.obj *.dll *.lib *.exp
