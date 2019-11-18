#
# Makefile for flexgui (Windows version)
# Final output is in flexgui.zip
#

default: flexgui.zip

CROSS ?= win32
EXE ?= .exe

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

#
# board support files (e.g. for flash programming)
#
BOARDFILES=board/P2ES_flashloader.bin

#
# binaries to make
#

BINFILES=bin/fastspin$(EXE) bin/proploader$(EXE) bin/loadp2$(EXE) $(BOARDFILES)

# the script used for signing executables:
#    $(SIGN) bin/foo
# produces bin/foo.signed.exe from bin/foo.exe
#
# to just do a regular build, do "make"
# for a signed build, do "make SIGN=my_signing_script"

SIGN ?= ./spin2cpp/sign.dummy.sh

flexgui.zip: src/version.tcl src/makepandoc.tcl flexgui$(EXE) $(BINFILES) $(PDFFILES) flexgui_dir
	rm -f flexgui.zip
	zip -r flexgui.zip flexgui

flexgui.exe: src/flexgui.c $(RESOBJ)
	$(WINGCC) $(WINCFLAGS) -o flexgui.exe src/flexgui.c $(WINTK_INC) $(WINTK_LIBS)
	$(SIGN) flexgui
	mv flexgui.signed.exe flexgui.exe

#
# be careful to leave samples/upython/upython.binary during make clean
#
SUBSAMPLES={LED_Matrix, proplisp}

clean:
	rm -rf flexgui
	rm -rf *.exe *.zip
	rm -rf board/*.bin
	rm -rf $(BINFILES) $(PDFFILES)
	rm -rf spin2cpp/build-$(CROSS)/*
	rm -rf proploader-*-build
	rm -rf loadp2/build-$(CROSS)/*
	rm -rf samples/*.elf samples/*.binary samples/*~
	rm -rf samples/*.lst samples/*.pasm samples/*.p2asm
	rm -rf samples/*/*.lst samples/*/*.pasm samples/*/*.p2asm
	rm -rf samples/$(SUBSAMPLES)/*.binary
	rm -rf $(RESOBJ)
	rm -rf pandoc.yml

flexgui_dir:
	mkdir -p flexgui/bin
	mkdir -p flexgui/doc
	mkdir -p flexgui/board
	cp -r flexgui.exe README.md License.txt samples src flexgui
ifdef PANDOC_EXISTS
	cp -r $(PDFFILES) flexgui/doc
endif
	cp -r spin2cpp/doc/* flexgui/doc
	cp -r spin2cpp/include flexgui/
	cp -r doc/*.txt flexgui/doc
	cp -r bin/*.exe flexgui/bin
	cp -r board/*.bin flexgui/board
	cp -r flexgui.tcl flexgui/
	touch flexgui_dir

.PHONY: flexgui_dir

bin/fastspin$(EXE): spin2cpp/build-$(CROSS)/fastspin$(EXE)
	mkdir -p bin
	cp $< $@
	$(SIGN) bin/fastspin
	mv bin/fastspin.signed$(EXE) bin/fastspin$(EXE)

bin/proploader$(EXE): proploader-msys-build/bin/proploader$(EXE)
	mkdir -p bin
	cp $< $@

bin/loadp2$(EXE): loadp2/build-$(CROSS)/loadp2$(EXE)
	mkdir -p bin
	cp $< $@

spin2cpp/build-$(CROSS)/fastspin$(EXE):
	make -C spin2cpp CROSS=$(CROSS)

proploader-msys-build/bin/proploader$(EXE):
	make -C PropLoader CROSS=$(CROSS)

loadp2/build-win32/loadp2$(EXE):
	make -C loadp2 CROSS=$(CROSS)

%.pdf: %.md
	tclsh src/makepandoc.tcl $< > pandoc.yml
	$(PANDOC) --metadata-file=pandoc.yml -s --toc -f gfm -t latex -o $@ $<

$(RESOBJ): $(RES_RC)
	$(WINRC) -o $@ --define STATIC_BUILD --include "$(TCLROOT)/tk/generic" --include "$(TCLROOT)/tcl/generic" --include "$(RESDIR)" "$<"

src/version.tcl: version.inp spin2cpp/version.h
	cpp -DTCL_SRC < version.inp > $@

board/P2ES_flashloader.bin: loadp2/build-$(CROSS)/loadp2$(EXE)
	mkdir -p board
	cp loadp2/board/P2ES_flashloader.bin $@
