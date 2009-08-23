#!/bin/sh
./sdx.kit wrap GISViewer.kit -runtime tclkits/tclkit-linux-x86_64
mv GISViewer.kit GISViewer-linux-x86_64.run

./sdx.kit wrap GISViewer.kit -runtime tclkits/tclkit-linux-x86
mv GISViewer.kit GISViewer-linux-x86.run

