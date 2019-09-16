#
# Makefile for flexgui (Windows version)
# Final output is in flexgui.zip
#

default: flexgui.zip

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
default: flexgui.zip

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

flexgui.zip: src/version.tcl flexgui.exe $(BINFILES) $(PDFFILES) flexgui_dir
	rm -f flexgui.zip
	zip -r flexgui.zip flexgui

flexgui.exe: src/flexgui.c $(RESOBJ)
	$(WINGCC) $(WINCFLAGS) -o flexgui.exe src/flexgui.c $(WINTK_INC) $(WINTK_LIBS)
	$(SIGN) flexgui
	mv flexgui.signed.exe flexgui.exe
clean:
	rm -rf flexgui
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

flexgui_dir:
	mkdir -p flexgui/bin
	mkdir -p flexgui/doc
	cp -r flexgui.exe README.md License.txt samples src flexgui
ifdef PANDOC_EXISTS
	cp -r $(PDFFILES) flexgui/doc
endif
	cp -r spin2cpp/doc/* flexgui/doc
	cp -r spin2cpp/include flexgui/
	cp -r doc/*.txt flexgui/doc
	cp -r bin/*.exe flexgui/bin
	cp -r flexgui.tcl flexgui/
	touch flexgui_dir

.PHONY: flexgui_dir

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
	$(PANDOC) --toc -f markdown_github -t latex -o $@ $<

$(RESOBJ): $(RES_RC)
	$(WINRC) -o $@ --define STATIC_BUILD --include "$(TCLROOT)/tk/generic" --include "$(TCLROOT)/tcl/generic" --include "$(RESDIR)" "$<"

src/version.tcl: version.inp spin2cpp/version.h
	cpp -DTCL_SRC < version.inp > $@
