#
# Makefile for flexprop
#
# Options:
# make install INSTALL=dir
#    Makes for Linux or Mac; requires Tcl/Tk to already be installed
# make zip SIGN=sign_script
#    Makes for Windows, linking against prebuild Tcl/Tk libraries in $(TCLROOT)
#    Final output is in flexprop.zip
#

default: errmessage
zip: flexprop.zip

# where to install: default is $(HOME)/flexgui
INSTALL ?= $(HOME)/flexprop

# detect OS
ifndef OS
	UNAME := $(shell uname)
	ifeq ($(UNAME),Darwin)
		OS := macosx
	endif
	ifeq ($(UNAME),Linux)
		OS := linux
	endif
	ifndef OS
		OS := unix
	endif
endif

errmessage:
	@echo
	@echo "Usage:"
	@echo "  make install"
	@echo "  make zip SIGNPC=signscript SIGNMAC=signscript"
	@echo
	@echo "make install copies flexprop to the INSTALL directory (default is $(HOME)/flexprop)"
	@echo "for example to install in /opt/flexprop do:"
	@echo "    make install INSTALL=/opt/flexprop"
	@echo
	@echo "make zip creates a flexprop.zip for Windows"
	@echo "    This requires cross tools and is probably not what you want"
	@echo

#
# binaries to make
#

EXEBINFILES=bin/flexspin.exe bin/flexcc.exe bin/loadp2.exe bin/flexspin.mac bin/flexcc.mac bin/loadp2.mac bin/mac_terminal.sh 
#EXEBINFILES=bin/flexspin.exe bin/flexcc.exe bin/loadp2.exe
EXEFILES=flexprop.exe $(EXEBINFILES)

WIN_BINARIES=$(EXEBINFILES) bin/proploader.exe bin/proploader.mac
#WIN_BINARIES=$(EXEBINFILES) bin/proploader.exe
NATIVE_BINARIES=bin/flexspin bin/flexcc bin/loadp2 bin/proploader

build: flexprop_base flexprop.bin $(NATIVE_BINARIES)

install: check_dir flexprop_base flexprop.bin $(NATIVE_BINARIES)
	mkdir -p $(INSTALL)
	mkdir -p flexprop/bin
	cp -r $(NATIVE_BINARIES) flexprop/bin
	cp -r mac_scripts/* flexprop/bin
	cp -r flexprop/* $(INSTALL)
	cp -rp flexprop.bin $(INSTALL)/flexprop
	cp -rp tcl_library $(INSTALL)/

list_install: build
	find $(NATIVE_BINARIES) -print
	find flexprop/ -print
	find flexprop.bin -print
	find tcl_library -print

check_dir:
	if test -f $(INSTALL)/Makefile; then echo "ERROR: Install directory contains a Makefile (possibly installing to original source)"; exit 1; fi

# where the Tcl and Tk source code are checked out (side by side)
TCLROOT ?= /home/ersmith/src/Tcl

# if pandoc exists we can convert .md files to .pdf, but if it
# doesn't we want the build to still succeeed, just without
# the .pdfs
PANDOC := pandoc
PANDOC_EXISTS := $(shell $(PANDOC) --version 2>/dev/null)
TCLSH := tclsh8.6

WINGCC = i686-w64-mingw32-gcc
WINRC = i686-w64-mingw32-windres
WINCFLAGS = -Os -DUNICODE -D_UNICODE -D_ATL_XP_TARGETING -DSTATIC_BUILD=1 -DUSE_TCL_STUBS
WINLIBS = -lnetapi32 -lkernel32 -luser32 -ladvapi32 -luserenv -lws2_32 -lgdi32 -lcomdlg32 -limm32 -lcomctl32 -lshell32 -luuid -lole32 -loleaut32

RESDIR=src/rc
RES_RC=$(RESDIR)/wish.rc
RESOBJ=$(RESDIR)/wish.res.o

WINTK_INC = -I$(TCLROOT)/tk/xlib -I$(TCLROOT)/tcl/win -I$(TCLROOT)/tcl/generic -I$(TCLROOT)/tk/win -I$(TCLROOT)/tk/generic
WINTK_LIBS = $(TCLROOT)/tk/win/libtk86.a $(TCLROOT)/tk/win/libtkstub86.a $(TCLROOT)/tcl/win/libtcl86.a $(TCLROOT)/tcl/win/libtclstub86.a $(WINLIBS) $(RESOBJ) -mwindows -pipe -static-libgcc -municode

ifeq ($(OS),linux)
NATIVETK_INC=-I/usr/include/tcl8.6
XLIBS=-lfontconfig -lXft -lXss -lXext -lX11
NATIVETK_LIBS=-ltk8.6 -ltcl8.6 $(XLIBS) -lz -ldl -lpthread -lm
endif
ifeq ($(OS),macosx)
# These are locations as specified by Homebrew
BREW_TK_PREFIX := $(shell brew --prefix tcl-tk)
NATIVETK_INC =-I$(BREW_TK_PREFIX)/include -I$(BREW_TK_PREFIX)/include/tcl-tk
NATIVETK_LIBS=-L$(BREW_TK_PREFIX)/lib -ltk8.6 -ltcl8.6 -lz -lpthread -lm
endif

VPATH=.:spin2cpp/doc

ifdef PANDOC_EXISTS
PDFFILES=spin2cpp/Flexspin.pdf spin2cpp/doc/general.pdf spin2cpp/doc/basic.pdf spin2cpp/doc/c.pdf spin2cpp/doc/spin.pdf
HTMLFILES=spin2cpp/Flexspin.html spin2cpp/doc/general.html spin2cpp/doc/basic.html spin2cpp/doc/c.html spin2cpp/doc/spin.html
endif

#
# board support files (e.g. for flash programming)
#
BOARDFILES=board/P2ES_flashloader.bin board/P2ES_flashloader.spin2 board/P2ES_sdcard.bin

# the script used for signing Windows executables:
#    $(SIGNPC) bin/foo
# produces bin/foo.signed.exe from bin/foo.exe
#
# to just do a regular build, do "make"
# for a signed build, do "make SIGNPC=my_signing_script"

SIGNPC ?= ./spin2cpp/sign.dummy.sh
SIGNMAC ?= /bin/echo

flexprop.zip: flexprop_base flexprop.exe flexprop.bin $(WIN_BINARIES)
	cp -r flexprop.exe flexprop/
	cp -r tcl_library flexprop/
	cp -rf MACOSX/flexprop.mac flexprop/flexprop
	cp -rf MACOSX/*.dylib flexprop/tcl_library/
	cp -r $(WIN_BINARIES) flexprop/bin
	rm -f flexprop.zip
	zip -r flexprop.zip flexprop

flexprop.bin: src/flexprop_native.c src/p2debug.c
	$(CC) $(CFLAGS) -o flexprop.bin src/flexprop_native.c src/p2debug.c $(NATIVETK_INC) $(NATIVETK_LIBS)

flexprop.exe: src/flexprop_win.c src/p2debug.c $(RESOBJ)
	$(WINGCC) $(WINCFLAGS) -o flexprop.exe src/flexprop_win.c src/p2debug.c $(WINTK_INC) $(WINTK_LIBS)
	$(SIGNPC) flexprop
	mv flexprop.signed.exe flexprop.exe

#
# be careful to leave samples/upython/upython.binary during make clean
# Also samples/proplisp/lisp.binary
#

SUBSAMPLES={LED_Matrix}

clean:
	rm -rf flexprop
	rm -rf *.exe *.zip
	rm -rf bin
	rm -rf board
	rm -rf $(BINFILES) $(PDFFILES) $(HTMLFILES)
	rm -rf spin2cpp/build*
	rm -rf proploader-*-build
	rm -rf loadp2/build*
	rm -rf loadp2/board/*.bin
	rm -rf samples/*.elf samples/*.binary samples/*~
	rm -rf samples/*.lst samples/*.pasm samples/*.p2asm
# NOTE: we cannot delete samples/*/*.binary because we need
# some of them
	rm -rf samples/*/*.elf samples/*/*~
	rm -rf samples/*/*.lst samples/*/*.pasm samples/*/*.p2asm
	rm -rf samples/$(SUBSAMPLES)/*.binary
	rm -rf $(RESOBJ)
	rm -rf pandoc.yml
	rm -rf src/version.tcl

flexprop_base: src/version.tcl src/makepandoc.tcl $(BOARDFILES) $(PDFFILES) $(HTMLFILES)
	mkdir -p flexprop/bin
	mkdir -p flexprop/doc
	mkdir -p flexprop/board
	cp -r README.md License.txt samples src flexprop
ifdef PANDOC_EXISTS
	-cp -r $(PDFFILES) flexprop/doc
	-cp -r $(HTMLFILES) flexprop/doc
endif
	cp -r spin2cpp/doc/* flexprop/doc
	cp -r spin2cpp/Changelog.txt flexprop/doc/Changelog-compiler.txt
	cp -r Changelog.txt flexprop/doc/Changelog-gui.txt
	cp -r loadp2/README.md flexprop/doc/loadp2.md
	cp -r loadp2/LICENSE flexprop/doc/loadp2.LICENSE.txt
	cp -r spin2cpp/COPYING.LIB flexprop/doc/COPYING.LIB
	cp -r spin2cpp/include flexprop/
	cp -r doc/*.txt flexprop/doc
	cp -r board/* flexprop/board

.PHONY: flexprop_base

# rules for building PDF files

%.pdf: %.md
	$(TCLSH) src/makepandoc.tcl $< > pandoc.yml
	-$(PANDOC) --metadata-file=pandoc.yml -s --toc -f gfm -t latex -o $@ $<

# rules for building PDF files

%.html: %.md
	$(TCLSH) src/makepandoc.tcl $< > pandoc.yml
	-$(PANDOC) --metadata-file=pandoc.yml -s --toc -f gfm -o $@ $<

# rules for native binaries

bin/flexspin: spin2cpp/build/flexspin
	mkdir -p bin
	cp $< $@
bin/flexcc: spin2cpp/build/flexcc
	mkdir -p bin
	cp $< $@

bin/proploader: proploader-$(OS)-build/bin/proploader
	mkdir -p bin
	cp $< $@

bin/loadp2: loadp2/build/loadp2
	mkdir -p bin
	cp $< $@

spin2cpp/build/flexspin:
	make -C spin2cpp OPT=-O1
spin2cpp/build/flexcc:
	make -C spin2cpp OPT=-O1

proploader-$(OS)-build/bin/proploader: bin/flexspin
	make -C PropLoader OS=$(OS) SPINCMP="`pwd`/bin/flexspin"

loadp2/build/loadp2: bin/flexspin
	make -C loadp2 P2ASM="`pwd`/bin/flexspin -2 -I`pwd`/spin2cpp/include"

# rules for Win32 binaries

bin/flexspin.exe: spin2cpp/build-win32/flexspin.exe
	mkdir -p bin
	cp $< $@
	$(SIGNPC) bin/flexspin
	mv bin/flexspin.signed.exe bin/flexspin.exe
bin/flexcc.exe: spin2cpp/build-win32/flexcc.exe
	mkdir -p bin
	cp $< $@
	$(SIGNPC) bin/flexcc
	mv bin/flexcc.signed.exe bin/flexcc.exe

bin/proploader.exe: proploader-msys-build/bin/proploader.exe
	mkdir -p bin
	cp $< $@

bin/proploader.mac: proploader-macosx-build/bin/proploader
	mkdir -p bin
	cp $< $@
	$(SIGNMAC) $@

bin/loadp2.exe: loadp2/build-win32/loadp2.exe
	mkdir -p bin
	cp $< $@
	$(SIGNPC) bin/loadp2
	mv bin/loadp2.signed.exe bin/loadp2.exe

spin2cpp/build-win32/flexspin.exe:
	make -C spin2cpp CROSS=win32
spin2cpp/build-win32/flexcc.exe:
	make -C spin2cpp CROSS=win32

ifneq ($(OS),msys)
proploader-msys-build/bin/proploader.exe:
	make -C PropLoader CROSS=win32 SPINCMP="`pwd`/bin/flexspin"
endif

ifneq ($(OS),macosx)
proploader-macosx-build/bin/proploader:
	make -C PropLoader CROSS=macosx SPINCMP="`pwd`/bin/flexspin"
endif

ifneq ($(OS),msys)
loadp2/build-win32/loadp2.exe:
	make -C loadp2 CROSS=win32 P2ASM="`pwd`/bin/flexspin -2 -I`pwd`/spin2cpp/include"
endif

$(RESOBJ): $(RES_RC)
	$(WINRC) -o $@ --define STATIC_BUILD --include "$(TCLROOT)/tk/generic" --include "$(TCLROOT)/tcl/generic" --include "$(RESDIR)" "$<"


## Rules for Mac binaries
bin/mac_terminal.sh: mac_scripts/mac_terminal.sh
	cp $< $@

bin/loadp2.mac: loadp2/build-macosx/loadp2
	mkdir -p bin
	cp $< $@
	$(SIGNMAC) $@

bin/flexspin.mac: spin2cpp/build-macosx/flexspin
	mkdir -p bin
	cp $< $@
	$(SIGNMAC) $@

bin/flexcc.mac: spin2cpp/build-macosx/flexcc
	mkdir -p bin
	cp $< $@
	$(SIGNMAC) $@

spin2cpp/build-macosx/flexspin:
	make -C spin2cpp CROSS=macosx
spin2cpp/build-macosx/flexcc:
	make -C spin2cpp CROSS=macosx

loadp2/build-macosx/loadp2:
	make -C loadp2 CROSS=macosx

## Other rules

src/version.tcl: version.inp spin2cpp/version.h
	cpp -xc++ -DTCL_SRC < version.inp > $@

docs: $(PDFFILES) $(HTMLFILES)

docker:
	docker build -t flexpropbuilder .

board/P2ES_flashloader.bin: bin/flexspin board/P2ES_flashloader.spin2
	bin/flexspin -2 -o $@ board/P2ES_flashloader.spin2

board/P2ES_sdcard.bin: board/sdcard/sdboot.binary
	mv board/sdcard/sdboot.binary board/P2ES_sdcard.bin

board/sdcard/sdboot.binary: bin/flexspin board/sdcard
	(make -C board/sdcard P2CC="`pwd`/bin/flexspin -2 -I`pwd`/spin2cpp/include")
	rm -f board/sdcard/*.p2asm

board/P2ES_flashloader.spin2: loadp2/board/P2ES_flashloader.spin2
	mkdir -p board
	cp loadp2/board/P2ES_flashloader.spin2 $@

board/sdcard: loadp2/board/sdcard
	mkdir -p board
	cp -r loadp2/board/sdcard board
