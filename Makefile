

default: spin2gui.zip

spin2gui.zip: spin2gui.exe bin/fastspin.exe bin/proploader.exe bin/loadp2.exe spin2gui_dir
	rm -f spin2gui.zip
	zip -r spin2gui.zip spin2gui

spin2gui.exe: spin2gui.tcl
	/opt/freewrap/linux64/freewrap spin2gui.tcl -w /opt/freewrap/win32/freewrap.exe

clean:
	rm -rf spin2gui
	rm -rf *.exe *.zip
	rm -rf spin2cpp/build-win32/*
	rm -rf proploader-*-build
	rm -rf loadp2/build-win32/*
	rm -rf samples/*.elf samples/*.binary samples/*~
	rm -rf samples/*.lst samples/*.pasm samples/*.p2asm

spin2gui_dir:
	mkdir -p spin2gui/bin
	mkdir -p spin2gui/doc
	cp -r spin2gui.exe README.md License.txt lib samples src spin2gui
	cp -r spin2cpp/docs/* spin2gui/doc
	cp -r spin2cpp/include spin2gui/
	cp -r doc/*.txt spin2gui/doc
	cp -r bin/*.exe spin2gui/bin
	touch spin2gui_dir

.PHONY: spin2gui_dir

bin/fastspin.exe: spin2cpp/build-win32/fastspin.exe
	mkdir -p bin
	cp $< $@

bin/proploader.exe: proploader-msys-build/bin/proploader.exe
	mkdir -p bin
	cp $< $@

bin/loadp2.exe: loadp2/build-win32/loadp2.exe
	mkdir -p bin
	cp $< $@

spin2cpp/build-win32/fastspin.exe:
	make -C spin2cpp CROSS=win32

proploader-msys-build/bin/proploader.exe:
	make -C PropLoader CROSS=win32

loadp2/build-win32/loadp2.exe:
	make -C loadp2 CROSS=win32
