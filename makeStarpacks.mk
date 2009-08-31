#!/bin/sh

x86_64:
	# libs
	cp -a GISViewer.vfs starpacks/GISViewer.vfs
	cp -a libs-x86_64/* starpacks/GISViewer.vfs/lib/
	-cd starpacks/GISViewer.vfs && find . -mount -type f -name *.so* -exec strip '{}' \;
	-cd starpacks/GISViewer.vfs && find . -mount -type d -name .svn -exec rm -rf '{}' \;
	# tclkit
	cp tclkits/tclkit-linux-x86_64 starpacks/
	cd starpacks && ../sdx.kit wrap GISViewer.kit -runtime ./tclkit-linux-x86_64
	mv starpacks/GISViewer.kit starpacks/GISViewer-linux-x86_64.run
	rm ./starpacks/tclkit-linux-x86_64
	rm -rf starpacks/GISViewer.vfs

#./sdx.kit wrap GISViewer.kit -runtime tclkits/tclkit-linux-x86
#mv GISViewer.kit GISViewer-linux-x86.run

