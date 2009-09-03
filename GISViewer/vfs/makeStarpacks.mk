all: linux-i386 linux-x86_64 win32 win32_64bits

linux-i386:
	./sdx.kit wrap GISViewer-linux-i386.run -runtime ../tclkits/tclkit-linux-i386
	mv GISViewer-linux-i386.run ../InstallTree/linux-i386/GISViewer

linux-x86_64:
	./sdx.kit wrap GISViewer-linux-x86_64.run -runtime ../tclkits/tclkit-linux-x86_64
	mv GISViewer-linux-x86_64.run ../InstallTree/linux-x86_64/GISViewer

win32:
	./sdx.kit wrap GISViewer-win32.exe -runtime ../tclkits/tclkit-win32.exe
	mv GISViewer-win32.exe ../InstallTree/win32/GISViewer.exe

win32_64bits:
	#./sdx.kit wrap GISViewer-win32_64bits.exe -runtime ../tclkits/tclkit-win32_64bits.exe
	#mv GISViewer-win32_64bits.exe ../InstallTree/win32_64bits/GISViewer.exe
