all: linux-i386 linux-x86_64 win32 win32_64bits

linux-i386:
	-rm -rf GISViewer.vfs
	cp -a GISViewer-linux-i386.vfs GISViewer.vfs
	cp -a ../source/* GISViewer.vfs/
	./sdx.kit wrap GISViewer.run -runtime ../tclkits/tclkit-linux-i386
	mv GISViewer.run ../InstallTree/linux-i386/GISViewer
	rm -rf GISViewer.vfs

linux-x86_64:
	-rm -rf GISViewer.vfs
	cp -a GISViewer-linux-x86_64.vfs GISViewer.vfs
	cp -a ../source/* GISViewer.vfs/
	./sdx.kit wrap GISViewer.run -runtime ../tclkits/tclkit-linux-x86_64
	mv GISViewer.run ../InstallTree/linux-x86_64/GISViewer
	rm -rf GISViewer.vfs

win32:
	-rm -rf GISViewer.vfs
	cp -a GISViewer-win32.vfs GISViewer.vfs
	cp -a ../source/* GISViewer.vfs/
	./sdx.kit wrap GISViewer.exe -runtime ../tclkits/tclkit-win32.exe
	mv GISViewer.exe ../InstallTree/win32/GISViewer.exe
	rm -rf GISViewer.vfs

win32_64bits:
	-rm -rf GISViewer.vfs
	cp -a GISViewer-win32_64bits.vfs GISViewer.vfs
	cp -a ../source/* GISViewer.vfs/
	./sdx.kit wrap GISViewer.exe -runtime ../tclkits/tclkit-win32_64bits.exe
	mv GISViewer.exe ../InstallTree/win32_64bits/GISViewer.exe
	rm -rf GISViewer.vfs
