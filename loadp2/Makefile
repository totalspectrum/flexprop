#
# Makefile for loadp2
# Added by Eric Smith -- ugliness or flaws here are my fault, not Dave Hein's!
#

# if CROSS is defined, we are building a cross compiler
# possible targets are: win32, rpi
# Note that you may have to adjust your compiler names depending on
# which Linux distribution you are using (e.g. ubuntu uses
# "i586-mingw32msvc-gcc" for mingw, whereas Debian uses
# "i686-w64-mingw32-gcc"
#
ifeq ($(CROSS),win32)
#  CC=i586-mingw32msvc-gcc
  CC=i686-w64-mingw32-gcc
  EXT=.exe
  BUILD=./build-win32
  OSFILE=osint_mingw.c
else ifeq ($(CROSS),rpi)
  CC=arm-linux-gnueabihf-gcc
  EXT=
  BUILD=./build-rpi
  OSFILE=osint_linux.c
else ifeq ($(CROSS),linux32)
  CC=gcc -m32
  EXT=
  BUILD=./build-linux32
  OSFILE=osint_linux.c
else
  CC=gcc
  EXT=
  BUILD=./build
  OSFILE=osint_linux.c
endif

default: $(BUILD)/loadp2$(EXT)

$(BUILD)/loadp2$(EXT): $(BUILD) loadp2.c osint_linux.c osint_mingw.c
	$(CC) -Wall -O -o $@ loadp2.c $(OSFILE)

$(BUILD):
	mkdir -p $(BUILD)
