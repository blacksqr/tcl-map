all: linux-i386 linux-x86_64 win32 win32_64bits

linux-i386:
	-rm -rf GISViewer
	cp -a GISViewer-linux-i386 GISViewer
	cp -a ../source/* GISViewer/
	./sdx.kit wrap GISViewer.run -runtime ../tclkits/tclkit-linux-i386
	mv GISViewer.run ../InstallTree/linux-i386/GISViewer
	rm -rf GISViewer

linux-x86_64:
	-rm -rf GISViewer
	cp -a GISViewer-linux-x86_64 GISViewer
	cp -a ../source/* GISViewer/
	./sdx.kit wrap GISViewer.run -runtime ../tclkits/tclkit-linux-x86_64
	mv GISViewer.run ../InstallTree/linux-x86_64/GISViewer
	rm -rf GISViewer

win32:
	-rm -rf GISViewer
	cp -a GISViewer-win32 GISViewer
	cp -a ../source/* GISViewer/
	./sdx.kit wrap GISViewer.exe -runtime ../tclkits/tclkit-win32.exe
	mv GISViewer.exe ../InstallTree/win32/GISViewer.exe
	rm -rf GISViewer

win32_64bits:
	-rm -rf GISViewer
	cp -a GISViewer-win32_64bits GISViewer
	cp -a ../source/* GISViewer/
	./sdx.kit wrap GISViewer.exe -runtime ../tclkits/tclkit-win32_64bits.exe
	mv GISViewer.exe ../InstallTree/win32_64bits/GISViewer.exe
