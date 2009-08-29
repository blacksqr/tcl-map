#!/bin/sh

x86_64:
	rm -rf GISViewer.vfs/lib
	mkdir GISViewer.vfs/lib
	cp -a libs-x86_64/* GISViewer.vfs/lib/
	./sdx.kit wrap GISViewer.kit -runtime tclkits/tclkit-linux-x86_64
	mv GISViewer.kit GISViewer-linux-x86_64.run

#./sdx.kit wrap GISViewer.kit -runtime tclkits/tclkit-linux-x86
#mv GISViewer.kit GISViewer-linux-x86.run

