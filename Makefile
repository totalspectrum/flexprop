

default: spin2gui.zip

spin2gui.zip: spin2gui.exe
	rm -f spin2gui.zip
	zip -r spin2gui.zip spin2gui.exe README.md License.txt bin/*.exe doc lib samples src

spin2gui.exe: spin2gui.tcl
	/opt/freewrap/linux64/freewrap spin2gui.tcl -w /opt/freewrap/win32/freewrap.exe

clean:
	rm -rf *.exe *.zip samples/*.binary samples/*.p2asm
