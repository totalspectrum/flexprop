# Introduction

FlexProp is a simple GUI for creating applications on the Parallax Propeller 2 (or 1), using assembler, Spin, BASIC or C. It consists of a very plain front end IDE, the flexspin compiler, and Dave Hein's loadp2 program loader. The default configuration is for the Prop2, but I've also included David Betz's proploader.exe, which allows flexprop to work on Propeller 1 systems as well.

FlexProp is distributed under the MIT license; see the file License.txt for details.

## Features

* Both Prop1 and Prop2 are supported
* Supports PASM, Spin, BASIC, and C
* View output PASM code
* Built in terminal emulator
* GUI checks files for external changes, so you may use any editor and compile in FlexProp
* Options for interacting directly with P2 ROM monitor and ROM TAQOZ


### PASM enhancements

* P1 and P2 assembly languages supported
* Preprocessor supporting `#define`, `#ifdef`, and `#include`
* Absolute address operator `@@@` (only needed for P1)
* Warnings for common mistakes like forgetting `#` in a jump
* Can compile assembly-only files (no Spin methods required)

### Spin enhancements

The original Spin (Spin1) language is supported, with some enhancements from Spin2:

* Generates optimized PASM instead of bytecode
* `case_fast` to force `case` to produce a jump table
* Conditional expressions like `(x < y) ? x : y`
* Multiple return values and assignments, e.g. `x,y := y,x`
* Unsigned operators `+/`, `+//`, `+<`, `+=<`, `+>`, `+=>`
* Spin2 operators `\`, `<=>`
* Pointers to objects
* Inline assembly inside PUB and PRI functions
* `pub file` and `pri file` to include functions from other languages (C, BASIC)
* Default parameter values for functions
* Optional type specifiers for function parameters and return values
* Automatic passing of strings as pointers in some cases

If the file name ends in `.spin2`, then the standard Spin2 language is assumed, with some legacy features from Spin1 supported.

See `doc/spin.md` for more details.

### BASIC Language

flexspin supports a fairly complete version of BASIC, based on traditional Microsoft BASICs. Please see `doc/basic.md` for details. Notable features are:

* Structured programming features
* Line numbers are optional
* Garbage collected memory allocation
* Support for classes, and importing Spin objects as classes
* Function closures and immediate functions
* `try` / `catch`
* Inline assembly
* Generic functions and templates

### C Language

flexspin supports a C dialect called FlexC, which is intended to be C99 compatible with some C++ extensions. It is not yet complete. Notable enhancements are:

* Inline assembly (similar to MSVC)
* Simple classes, including using Spin and BASIC objects as C classes
* Reference parameters using `&`
* GCC style statement expressions
* Header files may specify linking information for libraries
* Several useful builtin functions

# Usage

## Installation on Windows

To install, download the flexprop.zip file from the releases. The latest release is always located at:

   https://github.com/totalspectrum/flexprop/releases/latest
   
Create a directory called "flexprop" (or whatever you'd like) and unpack the .zip file into that directory. Make sure the directory you create is writable, so do not unpack into a system directory like "Program Files". Use your desktop or a folder directly under "C:" instead.

## Installation on Mac OS X

For Mac OS X, it's recommended to run the `flexprop` program from a command line (although it should work from the Finder as well, that just isn't tested as much). Pre-built binaries of the command line tools like `flexspin` and `loadp2` are provided. You may get a Gatekeeper warning about the binaries; if so you'll have to tell Gatekeeper to run them anyway.

## Installation on Linux

At the moment you'll have to build from source on Linux. Instructions are given below.

## Building from source

### Linux

#### Ubuntu (and other Debian based Linuxes, such as Mint)

Here are complete steps for building from scratch on a generic Debian based platform such as Ubuntu. Note that the first few steps (setting up a directory for the source code) may be tweaked to suit your wishes. Also note that the steps involving `texlive-latex-recommended` and `pandoc` are only required for formatting the documentation; if you only want the binaries you may skip these.

IMPORTANT: the installation directory (`~/flexprop` by default) must *not* be the same as the source directory (`~/src/flexprop` in the instructions below). If you forget this, you will get an error about the install directory containing a Makefile. In general do not do the git checkout directly in your home directory, use a subdirectory like `~/src` or `~/projects`.

```
sudo apt-get update
sudo apt-get install build-essential xxd
sudo apt-get install bison git tk8.6-dev
sudo apt-get install texlive-latex-recommended pandoc
cd $HOME
mkdir -p src
cd src
rm -rf flexprop
git clone --recursive https://github.com/totalspectrum/flexprop
cd flexprop
make install INSTALL=~/flexprop
cd ~/flexprop
./flexprop
```
At each step if you are prompted to accept the installation make sure to say yes (`Y`).

Once the build is finished, the final flexprop installation will be in $HOME/flexprop. You can change this to another directory by adding an `INSTALL=<dir>` in the `make install` step, e.g.
```
make install INSTALL=/opt/flexprop
```

To run, go to the flexprop installation directory and run `./flexprop`.

After the first installation, you won't have to do the "sudo" steps any more (the first 4 steps).

#### Fedora 36

See the above Ubuntu/Debian instructions for further details, but the basic steps are:
```
sudo dnf install @development-tools
sudo dnf install gcc-c++
sudo dnf install tk-devel
sudo dnf install texlive-latex
sudo dnf install pandoc vim-common
sudo dnf install libXScrnSaver-devel
cd $HOME
mkdir -p src
cd src
rm -rf flexprop
git clone --recursive https://github.com/totalspectrum/flexprop
cd flexprop
make install INSTALL=~/flexprop
cd ~/flexprop
./flexprop
```

#### Other Linux versions

For other Linux versions you'll have to install appropriate development tools. The lists above for Ubuntu and Fedora should give you a hint for what you'll need to install; unfortunately, package names are not standardized across distributions, so you may need to search on the Internet for appropriate replacements for your distro.

### Mac OS X

You'll need to install tcl-tk development packages. I use homebrew for this, and installed with:
```
brew install tcl-tk
```
Then you can build with something like:
```
cd $HOME
mkdir -p src
cd src
git clone --recursive https://github.com/totalspectrum/flexprop
cd flexprop
make install
```

#### Conflict with SDK 13.3

The latest version of XCode cannot compile the PropLoader tool needed for P1 development. This appears to be an XCode bug. If you only do P2 development that may not matter to you (you can just ignore the error). Otherwise, you may have to drop back to an older version of the SDK by removing (or moving aside) the MacOSX13.3.sdk and replacing the generic `MacOSX.sdk` link to one that points to the older MacOSX12.3.sdk.

### Windows

I use msys to build on Windows. Similar compiler collections with gcc or clang should work as well. There is no Visual Studio project file, so it would be difficult to build with VS.

## Basic Usage

Run flexprop.exe (Windows) or flexprop (other systems). Use the `File` menu to open a Spin or BASIC file. You may open multiple files. The one that is currently selected will be treated as the top level project if you try to compile and/or run. The commands used for compiling or running are settable from the `Commands > Configure Commands...` menu item. Compiling and running on Prop2 is the main focus, but you can configure for virtually any situation where just one file is compiled. So for example it should be feasible to use this GUI for `p2gcc` with a bit of tweaking.

Also under the `File` menu is an option for viewing the listing file. This will only be useful after a program is compiled.

To change between P1 and P2 development use `Configure Commands...` and select the appropriate default.

Your changes to commands, library directories, and other configuration information is saved in a file called .flexprop.config in the directory where flexprop.exe is located.

### Library Directories

Under the `File` menu is an option to set library directories. The compiler will automatically look through these directories for OBJ files (Spin) or `#include` files (C).

### Listing files

Under the `File` menu is an option for viewing the listing file, which shows the PASM and binary generated by flexspin from your high level language. This file may only be opened after the first compilation is done; if you try to open before doing any compile you may get an "Error: could not read" dialog box.


## High level languages

The main advantage of FlexProp over PNut (the "official" development tool for the Prop2) is that PNut supports only Spin 2, whereas FlexProp supports Spin 1, Spin 2, BASIC, and C. You can write ordinary Spin1 code, with Prop2 assembly code in the DAT section (instead of Prop1 assembly code). This makes porting code from P1 easier.

The code is compiled to P2 assembler by flexspin. This is somewhat different from the way Spin traditionally worked on the Prop1, where Spin code is typically compiled to bytecode and interpreted. (Note that flexspin does work for Prop1, and compiles to P1 assembler in that case.) There is now an experimental bytecode compiler, which you may select in the Commands > Configure Commands... menu (click on "P1 bytecode defaults").

Documentation for the various languages supported is in the `doc` folder of the unpacked flexprop. BASIC is the best documented. The Spin documentation assumes familiarity with the original (Propeller1) Spin manual, and outlines the differences in the language flexspin accepts. The C documentation is a placeholder for now and mostly covers the flexspin specific extensions to C.

# Modifying the GUI

The scripts used are in the `src` subdirectory, so you can customize them to your heart's content. The main `flexprop.exe` program is basically just the Tcl/Tk interpreter (from the standard Tk distribution) with a tiny startup script that reads `src/gui.tcl`.

# Supporting FlexProp development

If you find FlexProp useful, please contribute to support its development. Contributions of code, documentation, and other suggestions are welcome. Monetary donations are also very welcome. The generous donations of our supporters on Patreon have enabled us to provide signed binaries for Windows and Mac.

To support FlexProp on Patreon: https://patreon.com/totalspectrum
To support FlexProp on Paypal:  https://paypal.me/totalspectrum
