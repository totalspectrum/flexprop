#
# Makefile for spin2gui (Windows version)
# Final output is in spin2gui.zip
#

default: spin2gui.zip

# where the Tcl and Tk source code are checked out (side by side)
TCLROOT ?= /home/ersmith/src/Tcl

# if pandoc exists we can convert .md files to .pdf, but if it
# doesn't we want the build to still succeeed, just without
# the .pdfs
PANDOC := pandoc
PANDOC_EXISTS := $(shell $(PANDOC) --version 2>/dev/null)

WINGCC = i686-w64-mingw32-gcc
WINRC = i686-w64-mingw32-windres
WINCFLAGS = -Os -DUNICODE -D_UNICODE -D_ATL_XP_TARGETING -DSTATIC_BUILD=1 -DUSE_TCL_STUBS
WINLIBS = -lnetapi32 -lkernel32 -luser32 -ladvapi32 -luserenv -lws2_32 -lgdi32 -lcomdlg32 -limm32 -lcomctl32 -lshell32 -luuid -lole32 -loleaut32

RESDIR=src/rc
RES_RC=$(RESDIR)/wish.rc
RESOBJ=$(RESDIR)/wish.res.o

WINTK_INC = -I$(TCLROOT)/tk/xlib -I$(TCLROOT)/tcl/win -I$(TCLROOT)/tcl/generic -I$(TCLROOT)/tk/win -I$(TCLROOT)/tk/generic
WINTK_LIBS = $(TCLROOT)/tk/win/libtk87.a $(TCLROOT)/tk/win/libtkstub87.a $(TCLROOT)/tcl/win/libtcl90.a $(TCLROOT)/tcl/win/libtclstub90.a $(WINLIBS) $(RESOBJ) -mwindows -pipe -static-libgcc -municode
default: spin2gui.zip

VPATH=.:spin2cpp/doc

ifdef PANDOC_EXISTS
PDFFILES=spin2cpp/Fastspin.pdf spin2cpp/doc/basic.pdf spin2cpp/doc/c.pdf spin2cpp/doc/spin.pdf
endif

BINFILES=bin/fastspin.exe bin/proploader.exe bin/loadp2.exe

# the script used for signing executables:
#    $(SIGN) bin/foo
# produces bin/foo.signed.exe from bin/foo.exe
#
# to just do a regular build, do "make"
# for a signed build, do "make SIGN=my_signing_script"

SIGN ?= ./spin2cpp/sign.dummy.sh

spin2gui.zip: src/version.tcl spin2gui.exe $(BINFILES) $(PDFFILES) spin2gui_dir
	rm -f spin2gui.zip
	zip -r spin2gui.zip spin2gui

spin2gui.exe: src/spin2gui.c $(RESOBJ)
	$(WINGCC) $(WINCFLAGS) -o spin2gui.exe src/spin2gui.c $(WINTK_INC) $(WINTK_LIBS)
	$(SIGN) spin2gui
	mv spin2gui.signed.exe spin2gui.exe
clean:
	rm -rf spin2gui
	rm -rf *.exe *.zip
	rm -rf $(BINFILES) $(PDFFILES)
	rm -rf spin2cpp/build-win32/*
	rm -rf proploader-*-build
	rm -rf loadp2/build-win32/*
	rm -rf samples/*.elf samples/*.binary samples/*~
	rm -rf samples/*.lst samples/*.pasm samples/*.p2asm
	rm -rf samples/*/*.binary samples/*/*.pasm samples/*/*.p2asm
	rm -rf samples/*/*.lst
	rm -rf $(RESOBJ)

spin2gui_dir:
	mkdir -p spin2gui/bin
	mkdir -p spin2gui/doc
	cp -r spin2gui.exe README.md License.txt samples src spin2gui
ifdef PANDOC_EXISTS
	cp -r $(PDFFILES) spin2gui/doc
endif
	cp -r spin2cpp/doc/* spin2gui/doc
	cp -r spin2cpp/include spin2gui/
	cp -r doc/*.txt spin2gui/doc
	cp -r bin/*.exe spin2gui/bin
	cp -r spin2gui.tcl spin2gui/
	touch spin2gui_dir

.PHONY: spin2gui_dir

bin/fastspin.exe: spin2cpp/build-win32/fastspin.exe
	mkdir -p bin
	cp $< $@
	$(SIGN) bin/fastspin
	mv bin/fastspin.signed.exe bin/fastspin.exe

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

%.pdf: %.md
	$(PANDOC) -f markdown_github -t latex -o $@ $<

$(RESOBJ): $(RES_RC)
	$(WINRC) -o $@ --define STATIC_BUILD --include "$(TCLROOT)/tk/generic" --include "$(TCLROOT)/tcl/generic" --include "$(RESDIR)" "$<"

src/version.tcl: version.inp spin2cpp/version.h
	cpp -DTCL_SRC < version.inp > $@
