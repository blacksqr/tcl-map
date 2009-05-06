#!/bin/sh
make clean
rm -rf pkgIndex.tcl config.status config.log autom4te.cache configure Makefile
rm -rf lib share bin include
autoconf

./configure --prefix=/usr/local --enable-gcc --enable-threads --enable-symbols --with-tcl=/usr/lib
#./configure --enable-gcc --enable-threads --enable-symbols --with-tcl=/usr/lib
make
sudo make install
man tcl-gdal -Hcat > index.html
scp ./index.html alsterg@shell.sourceforge.net:/home/groups/t/tc/tcl-gdal/htdocs/
