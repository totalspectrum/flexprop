

default: spin2gui.zip

spin2gui.zip: spin2gui.exe spin2gui_dir
	rm -f spin2gui.zip
	zip -r spin2gui.zip spin2gui

spin2gui.exe: spin2gui.tcl
	/opt/freewrap/linux64/freewrap spin2gui.tcl -w /opt/freewrap/win32/freewrap.exe

clean:
	rm -rf spin2gui
	rm -rf *.exe *.zip
	rm -rf samples/*.elf samples/*.binary
	rm -rf samples/*.lst samples/*.pasm samples/*.p2asm
	rm -rf samples/*.c samples/*.h samples/*.cpp

spin2gui_dir:
	mkdir -p spin2gui/bin
	cp -r spin2gui.exe README.md License.txt doc lib samples src spin2gui
	cp -r bin/*.exe spin2gui/bin
	touch spin2gui_dir
